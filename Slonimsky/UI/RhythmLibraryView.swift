//
//  RhythmLibraryView.swift
//  Slonimsky
//
//  Browse and configure the built-in rhythm library: filter by time signature
//  and family, audition a pattern as GM drums or as pitched material, and mute
//  or rotate individual lanes.
//

import SwiftUI

struct RhythmLibraryView: View {
    @ObservedObject var parameterManager: ParameterManager

    @State private var meterFilter: Meter?      // nil = all meters
    @State private var familyFilter: String?    // nil = all families

    // MARK: - Derived

    private var settings: RhythmLibrarySettings { parameterManager.rhythmLibrary }
    private var selectedPattern: RhythmPattern? { settings.pattern }

    private var filteredPatterns: [RhythmPattern] {
        RhythmLibrary.patterns.filter { pattern in
            (meterFilter == nil || pattern.meter == meterFilter)
                && (familyFilter == nil || pattern.family == familyFilter)
        }
    }

    /// Transformations currently switched on that will alter the rhythm.
    private var activeTransformNames: [String] {
        var names: [String] = []
        if parameterManager.mirror { names.append("Mirror") }
        if parameterManager.iterations > 1 { names.append("Iterations ×\(parameterManager.iterations)") }
        if parameterManager.randomiseOrder { names.append("Randomise Order") }
        if parameterManager.processSettings.mode != .none {
            names.append("Process: \(parameterManager.processSettings.mode.rawValue)")
        }
        if parameterManager.phasingSettings.mode != .off { names.append("Phasing") }
        return names
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            enableSection
            Divider()
            roleSection
            Divider()
            filterSection
            browserSection
            if settings.isEnabled, let pattern = selectedPattern {
                Divider()
                selectedPatternSection(pattern)
            }
        }
    }

    // MARK: - Enable

    private var enableSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Use a built-in rhythm", isOn: Binding(
                get: { parameterManager.rhythmLibrary.isEnabled },
                set: { enabled in
                    parameterManager.rhythmLibrary.isEnabled = enabled
                    // Mirror doubles and inverts the pattern — nonsense for a
                    // fixed drum map, and surprising on a first Generate.
                    if enabled { parameterManager.mirror = false }
                }
            ))
            .foregroundColor(Color.garageBandText)

            if settings.isEnabled, settings.audibleVoices.isEmpty {
                Text("Every lane is muted — unmute at least one to generate")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            if settings.isEnabled, !activeTransformNames.isEmpty {
                Text("Active transforms will alter the groove: \(activeTransformNames.joined(separator: ", ")).")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Role and output

    private var roleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Role")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(Color.garageBandText)

            Picker("Role", selection: $parameterManager.rhythmLibrary.role) {
                ForEach(RhythmLibraryRole.allCases, id: \.self) { role in
                    Text(role.rawValue).tag(role)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Text(settings.role.explanation)
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.7))

            Text("Output")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(Color.garageBandText)
                .padding(.top, 4)

            Picker("Output", selection: $parameterManager.rhythmLibrary.output) {
                ForEach(RhythmLibraryOutput.allCases, id: \.self) { output in
                    Text(output.rawValue).tag(output)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Text(settings.output.explanation)
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.7))
        }
    }

    // MARK: - Filters

    private var filterSection: some View {
        HStack(spacing: 12) {
            Picker("Time Signature", selection: Binding(
                get: { meterFilter },
                set: { meterFilter = $0 }
            )) {
                Text("All meters").tag(Meter?.none)
                ForEach(RhythmLibrary.meters, id: \.self) { meter in
                    Text(meter.displayName).tag(Meter?.some(meter))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 190)

            Picker("Family", selection: Binding(
                get: { familyFilter },
                set: { familyFilter = $0 }
            )) {
                Text("All families").tag(String?.none)
                ForEach(RhythmLibrary.families, id: \.self) { family in
                    Text(family).tag(String?.some(family))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 190)

            Spacer()

            Text("\(filteredPatterns.count) rhythms")
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.7))
        }
    }

    // MARK: - Browser

    private var browserSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(filteredPatterns, id: \.name) { pattern in
                    patternRow(pattern)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(minHeight: 220, maxHeight: 320)
        .background(Color.garageBandBackground)
        .cornerRadius(6)
    }

    private func patternRow(_ pattern: RhythmPattern) -> some View {
        let isSelected = pattern.name == settings.patternName

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(pattern.name)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(Color.garageBandText)
                Text(pattern.meter.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Color.garageBandAccent.opacity(0.18))
                    .cornerRadius(3)
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Text(pattern.family)
                    .font(.caption2)
                    .foregroundColor(Color.garageBandText.opacity(0.6))
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.garageBandAccent)
                }
            }

            RhythmGridPreview(pattern: pattern, mutedVoices: isSelected ? settings.mutedVoices : [])
                .frame(height: CGFloat(max(1, pattern.voicesUsed.count)) * 9 + 4)

            Text(pattern.note)
                .font(.caption2)
                .foregroundColor(Color.garageBandText.opacity(0.6))
        }
        .padding(8)
        .background(isSelected ? Color.garageBandAccent.opacity(0.12) : Color.garageBandPanel)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture { select(pattern) }
    }

    /// Selecting a pattern also adopts its native meter, so the groove is
    /// always heard in the time signature it was written for.
    private func select(_ pattern: RhythmPattern) {
        parameterManager.rhythmLibrary.patternName = pattern.name
        parameterManager.rhythmLibrary.mutedVoices = []
        parameterManager.rhythmLibrary.rotationSteps = 0
        parameterManager.meter = pattern.meter
    }

    // MARK: - Selected pattern controls

    private func selectedPatternSection(_ pattern: RhythmPattern) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(pattern.name) — lanes")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(Color.garageBandText)

            ForEach(pattern.voicesUsed, id: \.self) { voice in
                Toggle(isOn: Binding(
                    get: { !parameterManager.rhythmLibrary.mutedVoices.contains(voice) },
                    set: { audible in
                        if audible {
                            parameterManager.rhythmLibrary.mutedVoices.remove(voice)
                        } else {
                            parameterManager.rhythmLibrary.mutedVoices.insert(voice)
                        }
                    }
                )) {
                    Text("\(voice.displayName)  ·  note \(voice.midiNote)")
                        .font(.caption)
                        .foregroundColor(Color.garageBandText)
                }
                .toggleStyle(CheckboxToggleStyle())
            }

            Stepper(value: Binding(
                get: { parameterManager.rhythmLibrary.rotationSteps },
                set: { parameterManager.rhythmLibrary.rotationSteps = $0 }
            ), in: 0...max(0, pattern.totalSteps - 1)) {
                Text("Rotation: \(settings.rotationSteps) of \(pattern.totalSteps) steps")
                    .foregroundColor(Color.garageBandText)
            }

            HStack {
                Text("Accent Boost:")
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Text("+\(settings.accentBoost)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color.garageBandText)
            }
            Slider(value: Binding(
                get: { Double(parameterManager.rhythmLibrary.accentBoost) },
                set: { parameterManager.rhythmLibrary.accentBoost = Int($0) }
            ), in: 0...32, step: 1)

            gmCaption(pattern)
        }
    }

    private func gmCaption(_ pattern: RhythmPattern) -> some View {
        let mapping = settings.audibleVoices
            .map { "\($0.displayName) \($0.midiNote)" }
            .joined(separator: " · ")
        let channelNote = settings.output == .drumKit
            ? "General MIDI percussion on channel 10: "
            : "Pitched output — these lanes only supply the rhythm: "
        return Text(mapping.isEmpty ? "No audible lanes" : channelNote + mapping)
            .font(.caption)
            .foregroundColor(Color.garageBandText.opacity(0.7))
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Grid preview

/// Compact lanes × steps dot grid for one pattern.
struct RhythmGridPreview: View {
    let pattern: RhythmPattern
    var mutedVoices: Set<DrumVoice> = []

    var body: some View {
        Canvas { context, size in
            let voices = pattern.voicesUsed
            guard !voices.isEmpty, pattern.totalSteps > 0 else { return }

            let columnWidth = size.width / CGFloat(pattern.totalSteps)
            let rowHeight = size.height / CGFloat(voices.count)
            let dot = min(columnWidth, rowHeight) * 0.68

            // Faint tint on grouping starts so the metric shape is visible
            let stepsPerGroupStart = pattern.meter.groupingOnsets.map { $0 / pattern.stepBeats }
            for bar in 0..<max(1, pattern.bars) {
                let barOffset = Double(bar * pattern.stepsPerBar)
                for onset in stepsPerGroupStart {
                    let column = CGFloat(barOffset + onset)
                    let rect = CGRect(x: column * columnWidth, y: 0, width: columnWidth, height: size.height)
                    context.fill(Path(rect), with: .color(Color.garageBandAccent.opacity(0.10)))
                }
            }

            for (row, voice) in voices.enumerated() {
                let muted = mutedVoices.contains(voice)
                let centreY = rowHeight * (CGFloat(row) + 0.5)

                for step in 0..<pattern.totalSteps {
                    let centreX = columnWidth * (CGFloat(step) + 0.5)
                    guard let hit = pattern.hits.first(where: { $0.voice == voice && $0.step == step }) else {
                        // Empty step: a faint tick keeps the grid readable
                        let tick = CGRect(x: centreX - 0.5, y: centreY - 0.5, width: 1, height: 1)
                        context.fill(Path(tick), with: .color(Color.garageBandText.opacity(0.18)))
                        continue
                    }

                    let diameter = hit.accent ? dot : dot * 0.72
                    let rect = CGRect(x: centreX - diameter / 2, y: centreY - diameter / 2,
                                      width: diameter, height: diameter)
                    let colour: Color = muted
                        ? Color.garageBandText.opacity(0.2)
                        : (hit.accent ? Color.garageBandAccent : Color.garageBandAccent.opacity(0.6))
                    context.fill(Path(ellipseIn: rect), with: .color(colour))
                }
            }
        }
    }
}
