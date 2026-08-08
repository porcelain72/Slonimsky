//
//  MelodyEditorView.swift
//  Slonimsky
//
//  Step-entry editor for the custom melody: pick a duration (or rest), click
//  keys on an on-screen keyboard to append, and manage the result in a
//  mini piano-roll preview with barlines from the meter cycle.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MelodyEditorView: View {
    @ObservedObject var parameterManager: ParameterManager

    @State private var selectedDuration: DurationValue = .quarter
    @State private var baseOctave: Int = 4   // keyboard spans two octaves from C(baseOctave)
    @State private var importErrorMessage: String?
    @State private var showReplaceConfirm = false
    @State private var pendingImportURL: URL?

    private let pointsPerBeat: CGFloat = 32
    private let previewHeight: CGFloat = 140

    // MARK: - Derived

    private var melody: CustomMelody { parameterManager.customMelody }

    private var maxBeats: Double {
        melody.maxBeats(for: parameterManager.meterCycle)
    }

    private var capacityRemaining: Double {
        maxBeats - melody.totalBeats
    }

    private var isFull: Bool {
        capacityRemaining < selectedDuration.beats - 1e-9
    }

    /// Onset (in beats) of each entered event, by prefix sum.
    private var eventOnsets: [Double] {
        var onsets: [Double] = []
        var position = 0.0
        for note in melody.notes {
            onsets.append(position)
            position += note.beats
        }
        return onsets
    }

    private var currentBar: Int {
        let barBeats = parameterManager.meterCycle.totalBeats / Double(parameterManager.meterCycle.bars.count)
        guard barBeats > 0 else { return 1 }
        return min(CustomMelody.maxBars, Int(melody.totalBeats / barBeats) + 1)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            enableSection
            Divider()
            meterSection
            Divider()
            paletteSection
            keyboardSection
            Divider()
            previewSection
            contractCaption
        }
        .alert("Import MIDI", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
        .confirmationDialog(
            "Replace the current melody with the imported MIDI?",
            isPresented: $showReplaceConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                if let url = pendingImportURL {
                    performImport(from: url)
                }
                pendingImportURL = nil
            }
            Button("Cancel", role: .cancel) {
                pendingImportURL = nil
            }
        }
    }

    // MARK: - Enable

    private var enableSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Use custom melody as pattern source", isOn: Binding(
                get: { parameterManager.customMelody.isEnabled },
                set: { enabled in
                    parameterManager.customMelody.isEnabled = enabled
                    // Mirror defaults to on (a scale-arpeggio default); left on,
                    // it doubles the melody's pitch stream and the entered rhythm
                    // then cycles against it — surprising on first Generate.
                    // Turn it off when the melody is enabled; it stays available
                    // in Directional for deliberate use.
                    if enabled {
                        parameterManager.mirror = false
                    }
                }
            ))
            .foregroundColor(Color.garageBandText)

            if melody.isEnabled && melody.pitches.isEmpty {
                Text("Enter at least one note below — an empty melody cannot generate")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if melody.isEnabled {
                Text("The melody replaces the scale generator; every other panel transforms it")
                    .font(.caption)
                    .foregroundColor(Color.garageBandText.opacity(0.7))
            }

            if melody.isEnabled, !activeTransformNames.isEmpty {
                Text("Active transforms will alter playback: \(activeTransformNames.joined(separator: ", ")). Turn them off to hear the melody exactly as entered.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Transformations currently switched on that change the melody's verbatim
    /// playback — surfaced so "repeated with variations" is never a mystery.
    private var activeTransformNames: [String] {
        var names: [String] = []
        if parameterManager.mirror { names.append("Mirror") }
        if parameterManager.interpolation.enabled { names.append("Interpolation") }
        if parameterManager.infrapolation.enabled { names.append("Infrapolation") }
        if parameterManager.ultrapolation.enabled { names.append("Ultrapolation") }
        if parameterManager.iterations > 1 { names.append("Iterations ×\(parameterManager.iterations)") }
        if parameterManager.randomiseOrder { names.append("Randomise Order") }
        if parameterManager.registerShifts != .none { names.append("Register Shifts") }
        if parameterManager.processSettings.mode != .none { names.append("Process: \(parameterManager.processSettings.mode.rawValue)") }
        if parameterManager.phasingSettings.mode != .off { names.append("Phasing") }
        if parameterManager.rhythmSettings.mode != .uniform { names.append("Rhythm: \(parameterManager.rhythmSettings.mode.rawValue)") }
        return names
    }

    // MARK: - Meter

    private var meterSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Time Signature:")
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Picker("Time Signature", selection: $parameterManager.meter) {
                    ForEach(Meter.presets, id: \.self) { meter in
                        Text(meter.displayName).tag(meter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 180)
            }
            Text("Groupings and multi-bar meter cycles are edited in Rhythm & Meter; the preview follows them")
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.6))
        }
    }

    // MARK: - Duration palette

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note Value")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(Color.garageBandText)

            HStack(spacing: 6) {
                ForEach(DurationValue.allCases, id: \.self) { value in
                    Button(action: { selectedDuration = value }) {
                        VStack(spacing: 2) {
                            Text(value.symbol)
                                .font(.system(size: 16))
                            Text(shortLabel(for: value))
                                .font(.caption2)
                        }
                        .frame(minWidth: 44)
                        .padding(.vertical, 4)
                        .background(selectedDuration == value
                                    ? Color.garageBandAccent.opacity(0.35)
                                    : Color.garageBandPanel)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(Color.garageBandText)
                }

                Button(action: appendRest) {
                    VStack(spacing: 2) {
                        Image(systemName: "pause.rectangle")
                            .font(.system(size: 14))
                        Text("Rest")
                            .font(.caption2)
                    }
                    .frame(minWidth: 44)
                    .padding(.vertical, 4)
                    .background(Color.garageBandPanel)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(Color.garageBandText)
                .disabled(isFull)

                Spacer()
            }
        }
    }

    private func shortLabel(for value: DurationValue) -> String {
        switch value {
        case .sixteenth: return "16th"
        case .eighth: return "8th"
        case .dottedEighth: return "8th."
        case .quarter: return "4th"
        case .dottedQuarter: return "4th."
        case .half: return "Half"
        case .dottedHalf: return "Half."
        }
    }

    // MARK: - Keyboard

    private static let whiteOffsets = [0, 2, 4, 5, 7, 9, 11]      // C D E F G A B
    private static let blackOffsets: [Int?] = [1, 3, nil, 6, 8, 10, nil] // C# D# – F# G# A# –

    private var keyboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Keyboard")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Stepper(value: $baseOctave, in: 1...6) {
                    Text("Octave: C\(baseOctave)")
                        .foregroundColor(Color.garageBandText)
                }
                .fixedSize()
            }

            VStack(spacing: 3) {
                // Black keys (offset row)
                HStack(spacing: 4) {
                    Spacer().frame(width: 18)
                    ForEach(0..<2, id: \.self) { octave in
                        ForEach(Array(MelodyEditorView.blackOffsets.enumerated()), id: \.offset) { _, offset in
                            if let offset = offset {
                                keyButton(pitch: (baseOctave + 1 + octave) * 12 + offset, isBlack: true)
                            } else {
                                Spacer().frame(width: 34)
                            }
                        }
                    }
                    Spacer()
                }
                // White keys
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { octave in
                        ForEach(MelodyEditorView.whiteOffsets, id: \.self) { offset in
                            keyButton(pitch: (baseOctave + 1 + octave) * 12 + offset, isBlack: false)
                        }
                    }
                    Spacer()
                }
            }

            if isFull {
                Text("Melody is full (\(CustomMelody.maxBars) bars max) — delete notes or shorten durations to continue")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private func keyButton(pitch: Int, isBlack: Bool) -> some View {
        Button(action: { appendNote(pitch: pitch) }) {
            Text(noteName(for: pitch))
                .font(.caption2)
                .frame(width: 34, height: isBlack ? 26 : 34)
                .background(isBlack ? Color.black.opacity(0.75) : Color.white.opacity(0.85))
                .foregroundColor(isBlack ? .white : .black)
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFull || pitch > 127)
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Melody")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Button("Import MIDI…") { requestImport() }
                Button("Undo") { removeLast() }
                    .disabled(melody.notes.isEmpty)
                Button("Clear") { clear() }
                    .disabled(melody.notes.isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    previewGrid
                    previewEvents
                }
                .frame(width: max(CGFloat(maxBeats) * pointsPerBeat, 300), height: previewHeight)
            }
            .background(Color.garageBandBackground)
            .cornerRadius(6)

            Text("\(melody.notes.count) events · \(String(format: "%.2f", melody.totalBeats)) / \(String(format: "%.0f", maxBeats)) beats · bar \(currentBar) of \(CustomMelody.maxBars) · click a note to delete it")
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.7))
        }
    }

    private var previewGrid: some View {
        Canvas { context, size in
            // Beat lines
            let beatColor = Color.garageBandPanel
            for beat in stride(from: 0.0, through: maxBeats, by: 1.0) {
                let x = CGFloat(beat) * pointsPerBeat
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(beatColor), lineWidth: 1)
            }
            // Barlines + grouping shading from the meter cycle
            for (barStart, meter) in parameterManager.meterCycle.barStarts(upTo: maxBeats) {
                let groupingOnsets = meter.groupingOnsets
                let barBeats = meter.beatsPerBar
                let spans: [(Double, Double)] = groupingOnsets.enumerated().map { index, onset in
                    let end = index + 1 < groupingOnsets.count ? groupingOnsets[index + 1] : barBeats
                    return (onset, end)
                }
                for (index, span) in spans.enumerated() where index % 2 == 1 {
                    let rect = CGRect(x: CGFloat(barStart + span.0) * pointsPerBeat, y: 0,
                                      width: CGFloat(span.1 - span.0) * pointsPerBeat, height: size.height)
                    context.fill(Path(rect), with: .color(Color.garageBandAccent.opacity(0.06)))
                }
                let x = CGFloat(barStart) * pointsPerBeat
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Color.garageBandText.opacity(0.4)), lineWidth: 2)
            }
        }
    }

    private var previewEvents: some View {
        let pitchRange = previewPitchRange
        let rowHeight = previewHeight / CGFloat(max(1, pitchRange.count))
        let onsets = eventOnsets

        return ForEach(Array(melody.notes.enumerated()), id: \.offset) { index, note in
            let x = CGFloat(onsets[index]) * pointsPerBeat
            let width = max(4, CGFloat(note.beats) * pointsPerBeat - 2)

            if note.isRest {
                Rectangle()
                    .fill(Color.garageBandText.opacity(0.07))
                    .overlay(Rectangle().stroke(Color.garageBandText.opacity(0.2),
                                                style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                    .frame(width: width, height: previewHeight)
                    .offset(x: x)
                    .onTapGesture { remove(at: index) }
            } else {
                let row = CGFloat(pitchRange.upperBound - note.pitch)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hue: Double(note.pitch % 12) / 12.0, saturation: 0.7, brightness: 0.8))
                    .frame(width: width, height: max(6, rowHeight - 2))
                    .offset(x: x, y: row * rowHeight)
                    .onTapGesture { remove(at: index) }
            }
        }
    }

    private var previewPitchRange: ClosedRange<Int> {
        let pitches = melody.pitches
        guard let low = pitches.min(), let high = pitches.max() else { return 57...72 }
        return max(0, low - 2)...min(127, high + 2)
    }

    private var contractCaption: some View {
        Text("Rhythm mode Uniform plays the melody as entered (durations and rests preserved). Isorhythm and Euclidean modes re-rhythm its pitches. Mirror, modulations, curves, processes, and phasing all transform the melody.")
            .font(.caption)
            .foregroundColor(Color.garageBandText.opacity(0.6))
    }

    // MARK: - Editing actions

    private func appendNote(pitch: Int) {
        guard !isFull else { return }
        parameterManager.customMelody.notes.append(
            MelodyNote(pitch: pitch, value: selectedDuration)
        )
    }

    private func appendRest() {
        guard !isFull else { return }
        parameterManager.customMelody.notes.append(
            MelodyNote(pitch: 0, value: selectedDuration, isRest: true)
        )
    }

    private func removeLast() {
        guard !parameterManager.customMelody.notes.isEmpty else { return }
        parameterManager.customMelody.notes.removeLast()
    }

    private func remove(at index: Int) {
        guard index < parameterManager.customMelody.notes.count else { return }
        parameterManager.customMelody.notes.remove(at: index)
    }

    private func clear() {
        parameterManager.customMelody.notes.removeAll()
    }

    private func requestImport() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.midi]
        panel.title = "Import MIDI Melody"
        panel.message = "Choose a MIDI file. Polyphonic parts are reduced to a single upper voice; durations are quantized to the note-value palette."

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                if !parameterManager.customMelody.notes.isEmpty {
                    pendingImportURL = url
                    showReplaceConfirm = true
                } else {
                    performImport(from: url)
                }
            }
        }
    }

    private func performImport(from url: URL) {
        do {
            let imported = try MIDIMelodyImporter.importMelody(
                from: url,
                maxBeats: maxBeats
            )
            parameterManager.customMelody = imported
            // Same as enabling the toggle: avoid surprise mirror-doubling
            parameterManager.mirror = false
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func noteName(for midiNote: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return "\(names[midiNote % 12])\(midiNote / 12 - 1)"
    }
}
