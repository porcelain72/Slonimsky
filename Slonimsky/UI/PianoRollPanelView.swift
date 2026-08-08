//
//  PianoRollPanelView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Piano roll panel view for displaying and editing patterns
struct PianoRollPanelView: View {
    
    // MARK: - Properties
    @ObservedObject var midiService: MIDIIntegrationService
    @ObservedObject var parameterManager: ParameterManager
    
    // MARK: - State
    @State private var zoomLevel: Double = 1.0
    @State private var selectedNotes: Set<Int> = []
    @State private var showNoteDetails = false
    @State private var hoveredNote: Int? = nil
    @State private var autoScaleEnabled: Bool = true
    @State private var dynamicNoteHeight: CGFloat = 20
    @State private var tonalRange: ClosedRange<Int> = 21...108
    /// Content X that should sit at the leading edge of the viewport (GarageBand follow).
    @State private var scrollLeadX: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0
    
    // MARK: - Constants
    private let timeDivision: CGFloat = 50
    private let pianoKeysWidth: CGFloat = 60
    private let minTimeDivision: CGFloat = 12
    private let maxTimeDivision: CGFloat = 200
    private let minNoteHeight: CGFloat = 2
    private let scrollAnchorID = "pianoRollScrollLead"
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            pianoRollHeader
            
            GeometryReader { geometry in
                let availableHeight = max(geometry.size.height, 1)
                let rowHeight = pitchRowHeight(for: availableHeight)
                let gridWidth = max(geometry.size.width - pianoKeysWidth, 1)
                
                HStack(spacing: 0) {
                    pianoKeysView(rowHeight: rowHeight, height: availableHeight)
                    noteGridView(
                        rowHeight: rowHeight,
                        height: availableHeight,
                        viewportWidth: gridWidth
                    )
                }
                .onAppear {
                    dynamicNoteHeight = rowHeight
                    viewportWidth = gridWidth
                    if let pattern = midiService.currentPattern {
                        updateViewForNewPattern(pattern)
                        dynamicNoteHeight = pitchRowHeight(for: availableHeight)
                    }
                }
                .onChange(of: geometry.size.height) { newHeight in
                    dynamicNoteHeight = pitchRowHeight(for: max(newHeight, 1))
                }
                .onChange(of: geometry.size.width) { newWidth in
                    viewportWidth = max(newWidth - pianoKeysWidth, 1)
                }
                .onChange(of: tonalRange) { _ in
                    dynamicNoteHeight = pitchRowHeight(for: availableHeight)
                }
            }
            
            pianoRollFooter
        }
        .background(Color.garageBandBackground)
        .sheet(isPresented: $showNoteDetails) {
            NoteDetailsView(
                midiService: midiService,
                selectedNotes: selectedNotes
            )
        }
        .onReceive(midiService.$currentPattern) { pattern in
            if let pattern = pattern {
                updateViewForNewPattern(pattern)
                scrollLeadX = 0
            }
        }
    }
    
    // MARK: - Header (Simplified for smaller space)
    
    private var pianoRollHeader: some View {
        VStack(spacing: 4) {
            HStack {
                // Zoom Controls (Compact)
                HStack(spacing: 4) {
                    Button(action: zoomOut) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .disabled(zoomLevel <= 0.5)
                    .font(.caption)
                    
                    Text("\(Int(zoomLevel * 100))%")
                        .font(.caption2)
                        .foregroundColor(Color.garageBandSecondary)
                        .frame(minWidth: 40)
                    
                    Button(action: zoomIn) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .disabled(zoomLevel >= 3.0)
                    .font(.caption)
                    
                    // Auto-scale Toggle
                    Toggle("Auto", isOn: $autoScaleEnabled)
                        .toggleStyle(SwitchToggleStyle())
                        .font(.caption2)
                }
                
                Spacer()
                
                // Tonal Range (Compact)
                if let pattern = midiService.currentPattern {
                    Text("\(noteName(for: tonalRange.lowerBound))-\(noteName(for: tonalRange.upperBound))")
                        .font(.caption2)
                        .foregroundColor(Color.garageBandSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
    
    // MARK: - Piano Keys
    
    private func pianoKeysView(rowHeight: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(tonalRange).reversed(), id: \.self) { noteNumber in
                PianoKeyView(
                    noteNumber: noteNumber,
                    isSelected: selectedNotes.contains(noteNumber),
                    isHovered: hoveredNote == noteNumber
                )
                .frame(height: rowHeight)
                .onTapGesture {
                    toggleNoteSelection(noteNumber)
                }
                .onHover { isHovered in
                    hoveredNote = isHovered ? noteNumber : nil
                }
            }
        }
        .frame(width: pianoKeysWidth, height: height, alignment: .top)
        .background(Color.garageBandPanel)
    }
    
    // MARK: - Note Grid
    
    private func noteGridView(rowHeight: CGFloat, height: CGFloat, viewportWidth: CGFloat) -> some View {
        let contentWidth = patternContentWidth(viewportWidth: viewportWidth)
        let playback = midiService.getPlaybackStatus()
        let playheadX = CGFloat(playback.currentTime) * currentTimeDivision
        
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    gridBackground(height: height)
                    
                    if let pattern = midiService.currentPattern {
                        ForEach(Array(pattern.notes.enumerated()), id: \.offset) { index, note in
                            if note.isRest {
                                RestColumnView(
                                    rest: note,
                                    timeDivision: currentTimeDivision
                                )
                            } else {
                                NoteView(
                                    note: note,
                                    startTime: note.onset,
                                    isSelected: selectedNotes.contains(note.note),
                                    isAccented: parameterManager.meterCycle.isGroupingStart(note.onset),
                                    timeDivision: currentTimeDivision,
                                    tonalRange: tonalRange,
                                    noteHeight: rowHeight
                                )
                                .onTapGesture {
                                    toggleNoteSelection(note.note)
                                }
                                .onHover { isHovered in
                                    hoveredNote = isHovered ? note.note : nil
                                }
                            }
                        }
                    }
                    
                    // Leading-edge scroll target for GarageBand-style follow
                    HStack(spacing: 0) {
                        Color.clear.frame(width: max(0, scrollLeadX), height: 1)
                        Color.clear
                            .frame(width: 1, height: 1)
                            .id(scrollAnchorID)
                        Spacer(minLength: 0)
                    }
                    .frame(width: contentWidth, height: 1, alignment: .leading)
                    .allowsHitTesting(false)
                    
                    if playback.isPlaying || playback.currentTime > 0 {
                        playbackPlayhead(playheadX: playheadX, height: height)
                    }
                }
                .frame(width: contentWidth, height: height, alignment: .topLeading)
            }
            .background(Color.garageBandBackground)
            .onChange(of: playback.currentTime) { newTime in
                followPlayhead(
                    proxy: proxy,
                    playheadX: CGFloat(newTime) * currentTimeDivision,
                    viewportWidth: viewportWidth,
                    contentWidth: contentWidth,
                    isPlaying: playback.isPlaying
                )
            }
            .onChange(of: playback.isPlaying) { isPlaying in
                if isPlaying {
                    followPlayhead(
                        proxy: proxy,
                        playheadX: playheadX,
                        viewportWidth: viewportWidth,
                        contentWidth: contentWidth,
                        isPlaying: true
                    )
                }
            }
            .onChange(of: scrollLeadX) { _ in
                // Keep ScrollView in sync when lead X is updated from follow logic
                proxy.scrollTo(scrollAnchorID, anchor: .leading)
            }
            .onAppear {
                scrollLeadX = 0
                proxy.scrollTo(scrollAnchorID, anchor: .leading)
            }
        }
    }
    
    private func playbackPlayhead(playheadX: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.red)
            .frame(width: 2, height: height)
            .position(x: playheadX, y: height / 2)
            .allowsHitTesting(false)
    }
    
    /// GarageBand-style follow: playhead travels to viewport center, then content scrolls
    /// with the playhead locked at center until the end of the roll.
    private func followPlayhead(
        proxy: ScrollViewProxy,
        playheadX: CGFloat,
        viewportWidth: CGFloat,
        contentWidth: CGFloat,
        isPlaying: Bool
    ) {
        guard isPlaying, viewportWidth > 0 else { return }
        
        let halfView = viewportWidth / 2
        let maxScroll = max(0, contentWidth - viewportWidth)
        let targetLead: CGFloat
        if playheadX <= halfView {
            targetLead = 0
        } else if playheadX >= contentWidth - halfView {
            targetLead = maxScroll
        } else {
            targetLead = playheadX - halfView
        }
        
        if abs(targetLead - scrollLeadX) > 0.5 {
            scrollLeadX = targetLead
            // scrollTo also runs via onChange(of: scrollLeadX); call here for immediacy
            DispatchQueue.main.async {
                proxy.scrollTo(scrollAnchorID, anchor: .leading)
            }
        }
    }
    
    private func patternContentWidth(viewportWidth: CGFloat) -> CGFloat {
        let duration = midiService.currentPattern?.notes.totalLength
            ?? midiService.currentPattern?.metadata.duration
            ?? 0
        return max(CGFloat(duration) * currentTimeDivision, viewportWidth)
    }
    
    // MARK: - Grid Background
    
    private func gridBackground(height: CGFloat) -> some View {
        Canvas { context, size in
            let meterCycle = parameterManager.meterCycle
            let beatWidth = currentTimeDivision
            let visibleBeats = Double(size.width) / Double(beatWidth)
            let beatColor = Color.garageBandPanel
            let rowHeight = dynamicNoteHeight
            
            for (barStart, meter) in meterCycle.barStarts(upTo: visibleBeats) {
                let barBeats = max(meter.beatsPerBar, 0.25)
                let groupingOnsets = meter.groupingOnsets
                
                let groupSpans: [(start: Double, end: Double)] = groupingOnsets.enumerated().map { index, onset in
                    let end = index + 1 < groupingOnsets.count ? groupingOnsets[index + 1] : barBeats
                    return (onset, end)
                }
                for (index, span) in groupSpans.enumerated() where index % 2 == 1 {
                    let x0 = (barStart + span.start) * beatWidth
                    let x1 = (barStart + span.end) * beatWidth
                    let rect = CGRect(x: x0, y: 0, width: x1 - x0, height: size.height)
                    context.fill(Path(rect), with: .color(Color.garageBandAccent.opacity(0.06)))
                }
                
                for onset in groupingOnsets.dropFirst() {
                    let x = (barStart + onset) * beatWidth
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(Color.garageBandAccent.opacity(0.35)), lineWidth: 1.0)
                }
                
                let x = barStart * beatWidth
                var barlinePath = Path()
                barlinePath.move(to: CGPoint(x: x, y: 0))
                barlinePath.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(barlinePath, with: .color(Color.garageBandText.opacity(0.4)), lineWidth: 2.0)
            }
            
            for beat in stride(from: 0.0, through: visibleBeats, by: 1.0) {
                let x = beat * beatWidth
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(beatColor), lineWidth: 1.0)
            }
            
            for y in stride(from: 0.0, through: Double(size.height), by: Double(max(rowHeight, 1))) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(beatColor), lineWidth: 1.0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Footer (Simplified for smaller space)
    
    private var pianoRollFooter: some View {
        HStack {
            if !selectedNotes.isEmpty {
                HStack(spacing: 4) {
                    Text("\(selectedNotes.count)")
                        .font(.caption2)
                        .foregroundColor(Color.garageBandSecondary)
                    
                    Button("Details") {
                        showNoteDetails = true
                    }
                    .buttonStyle(.bordered)
                    .font(.caption2)
                }
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Button("Fit") {
                    autoScaleEnabled = true
                    zoomLevel = 1.0
                    scrollLeadX = 0
                }
                .buttonStyle(.bordered)
                .font(.caption2)
                
                Button("Reset") {
                    zoomLevel = 1.0
                    autoScaleEnabled = false
                    scrollLeadX = 0
                }
                .buttonStyle(.bordered)
                .font(.caption2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomLevel = min(zoomLevel * 1.2, 3.0)
            autoScaleEnabled = false
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomLevel = max(zoomLevel / 1.2, 0.5)
            autoScaleEnabled = false
        }
    }
    
    private func toggleNoteSelection(_ noteNumber: Int) {
        if selectedNotes.contains(noteNumber) {
            selectedNotes.remove(noteNumber)
        } else {
            selectedNotes.insert(noteNumber)
        }
    }
    
    // MARK: - Scaling
    
    /// Row height that fits the full tonal range into the available viewport height.
    private func pitchRowHeight(for availableHeight: CGFloat) -> CGFloat {
        let rangeSize = max(tonalRange.count, 1)
        return max(minNoteHeight, availableHeight / CGFloat(rangeSize))
    }
    
    /// Calculate the tonal range of the pattern
    private func calculateTonalRange(from pattern: PatternGenerationResult) -> ClosedRange<Int> {
        let notes = pattern.notes.soundingNotes.map(\.note)
        guard let minNote = notes.min(), let maxNote = notes.max() else {
            return 48...72
        }
        
        let padding = 1
        let lowerBound = max(0, minNote - padding)
        let upperBound = min(127, maxNote + padding)
        return lowerBound...upperBound
    }
    
    /// Update the view when a new pattern is generated
    private func updateViewForNewPattern(_ pattern: PatternGenerationResult) {
        tonalRange = calculateTonalRange(from: pattern)
        print("🎹 Piano roll tonal range: \(tonalRange.lowerBound)-\(tonalRange.upperBound) (\(noteName(for: tonalRange.lowerBound)) to \(noteName(for: tonalRange.upperBound)))")
    }
    
    private func noteName(for midiNote: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteInOctave = midiNote % 12
        let octave = midiNote / 12 - 1
        return "\(noteNames[noteInOctave])\(octave)"
    }
    
    /// Horizontal pixels per beat. Zoom affects time scale only; pitch always fills height.
    private var currentTimeDivision: CGFloat {
        guard let pattern = midiService.currentPattern else { return timeDivision * zoomLevel }
        
        if autoScaleEnabled {
            let duration = max(pattern.notes.totalLength, pattern.metadata.duration, 0.25)
            let available = max(viewportWidth, 200)
            let fitted = available / CGFloat(duration)
            return max(minTimeDivision, min(maxTimeDivision, fitted)) * zoomLevel
        } else {
            return timeDivision * zoomLevel
        }
    }
}

// MARK: - Supporting Views

struct PianoKeyView: View {
    let noteNumber: Int
    let isSelected: Bool
    let isHovered: Bool
    
    private var isBlackKey: Bool {
        let noteInOctave = noteNumber % 12
        return [1, 3, 6, 8, 10].contains(noteInOctave)
    }
    
    private var noteName: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteInOctave = noteNumber % 12
        let octave = noteNumber / 12 - 1
        return "\(noteNames[noteInOctave])\(octave)"
    }
    
    var body: some View {
        Rectangle()
            .fill(backgroundColor)
            .overlay(
                Text(noteName)
                    .font(.caption2)
                    .foregroundColor(textColor)
                    .padding(.leading, 4)
                , alignment: .leading
            )
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.garageBandAccent.opacity(0.3)
        } else if isHovered {
            return Color.garageBandPanel
        } else {
            return isBlackKey ? Color.garageBandPanel : Color.garageBandBackground
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return Color.garageBandAccent
        } else {
            return isBlackKey ? .white : Color.garageBandText
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.garageBandAccent
        } else {
            return Color.garageBandPanel
        }
    }
}

struct NoteView: View {
    let note: MIDIInfo
    let startTime: TimeInterval
    let isSelected: Bool
    var isAccented: Bool = false
    let timeDivision: CGFloat
    let tonalRange: ClosedRange<Int>
    let noteHeight: CGFloat
    
    private var noteColor: Color {
        if isSelected {
            return Color.garageBandAccent
        }
        // Percussion reads as a neutral grey lane so a layered kit never looks
        // like melodic material.
        if note.isPercussion {
            return Color(hue: 0.08, saturation: 0.18, brightness: isAccented ? 0.85 : 0.62)
        }
        // Voice 0: hue follows pitch class. Phasing voice: fixed cool tint so the
        // two patterns stay separable as they slide apart.
        if note.voice > 0 {
            return Color(hue: 0.55, saturation: 0.65, brightness: isAccented ? 0.95 : 0.75)
        }
        return Color(hue: Double(note.note % 12) / 12.0,
                     saturation: 0.7,
                     brightness: isAccented ? 0.95 : 0.8)
    }
    
    var body: some View {
        let x = CGFloat(startTime) * timeDivision
        let notePosition = tonalRange.upperBound - note.note
        let rowTop = CGFloat(notePosition) * noteHeight
        let width = max(1, CGFloat(note.duration) * timeDivision)
        let height = max(2, noteHeight * 0.85)
        
        RoundedRectangle(cornerRadius: 3)
            .fill(noteColor)
            .frame(width: width, height: height)
            .position(x: x + width / 2, y: rowTop + noteHeight / 2)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isSelected ? Color.garageBandAccent
                            : (isAccented ? Color.white.opacity(0.7) : Color.clear),
                            lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

/// A rest rendered as a faint full-height column spanning its duration.
struct RestColumnView: View {
    let rest: MIDIInfo
    let timeDivision: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let x = CGFloat(rest.onset) * timeDivision
            let width = max(1, CGFloat(rest.duration) * timeDivision)
            
            Rectangle()
                .fill(Color.garageBandText.opacity(0.05))
                .overlay(
                    Rectangle()
                        .stroke(Color.garageBandText.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                )
                .frame(width: width, height: geometry.size.height)
                .position(x: x + width / 2, y: geometry.size.height / 2)
        }
        .allowsHitTesting(false)
    }
}

struct NoteDetailsView: View {
    @ObservedObject var midiService: MIDIIntegrationService
    let selectedNotes: Set<Int>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Selected Notes: \(selectedNotes.count)")
                    .font(.headline)
                
                if let pattern = midiService.currentPattern {
                    let selectedNoteData = pattern.notes.enumerated().filter { selectedNotes.contains($0.element.note) }
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(selectedNoteData, id: \.offset) { index, note in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Note \(index + 1)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("MIDI \(note.note)")
                                            .font(.caption)
                                            .foregroundColor(Color.garageBandSecondary)
                                    }
                                    
                                    HStack {
                                        Text("Pitch: \(noteName(for: note.note))")
                                        Spacer()
                                        Text("Velocity: \(note.velocity)")
                                    }
                                    .font(.caption)
                                    
                                    HStack {
                                        Text("Duration: \(String(format: "%.3f", note.duration)) beats")
                                        Spacer()
                                        Text("Start: \(String(format: "%.3f", note.onset)) beats")
                                    }
                                    .font(.caption)
                                }
                                .padding()
                                .background(Color.garageBandPanel)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Note Details")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func noteName(for midiNote: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteInOctave = midiNote % 12
        let octave = midiNote / 12 - 1
        return "\(noteNames[noteInOctave])\(octave)"
    }
    
}

// MARK: - Preview

struct PianoRollPanelView_Previews: PreviewProvider {
    static var previews: some View {
        PianoRollPanelView(
            midiService: MIDIIntegrationService(),
            parameterManager: ParameterManager()
        )
        .frame(width: 600, height: 400)
    }
} 
