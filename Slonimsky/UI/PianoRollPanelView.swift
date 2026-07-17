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
    @State private var scrollOffset: CGPoint = .zero
    @State private var selectedNotes: Set<Int> = []
    @State private var showNoteDetails = false
    @State private var hoveredNote: Int? = nil
    @State private var autoScaleEnabled: Bool = true
    @State private var verticalCenterOffset: CGFloat = 0
    @State private var dynamicNoteHeight: CGFloat = 20
    @State private var tonalRange: ClosedRange<Int> = 21...108
    
    // MARK: - Constants
    private let noteHeight: CGFloat = 20
    private let timeDivision: CGFloat = 50
    private let pianoKeysWidth: CGFloat = 60
    private let minTimeDivision: CGFloat = 20
    private let maxTimeDivision: CGFloat = 100
    private let minNoteHeight: CGFloat = 8
    private let maxNoteHeight: CGFloat = 40
    private let maxPianoRollHeight: CGFloat = 600
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            pianoRollHeader
            
            // Piano Roll Content
            HStack(spacing: 0) {
                // Piano Keys
                pianoKeysView
                // Note Grid
                noteGridView
            }
            
            // Footer Controls
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
    
    private var pianoKeysView: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(tonalRange).reversed(), id: \.self) { noteNumber in
                        PianoKeyView(
                            noteNumber: noteNumber,
                            isSelected: selectedNotes.contains(noteNumber),
                            isHovered: hoveredNote == noteNumber
                        )
                        .frame(height: dynamicNoteHeight * zoomLevel)
                        .onTapGesture {
                            toggleNoteSelection(noteNumber)
                        }
                        .onHover { isHovered in
                            hoveredNote = isHovered ? noteNumber : nil
                        }
                    }
                }
            }
            .background(Color.garageBandPanel)
        }
        .frame(width: pianoKeysWidth, height: sharedHeight)
        .background(Color.garageBandPanel)
        .onChange(of: tonalRange) { _ in
            print("🎹 Piano keys updated for new tonal range: \(tonalRange.lowerBound)-\(tonalRange.upperBound)")
        }
    }
    
    // MARK: - Note Grid
    
    private var noteGridView: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    // Grid Background
                    gridBackground
                    
                    // Notes and rests
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
                                    zoomLevel: zoomLevel,
                                    timeDivision: currentTimeDivision,
                                    tonalRange: tonalRange,
                                    noteHeight: dynamicNoteHeight
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
                    
                    // Playback Position Indicator
                    if midiService.getPlaybackStatus().isPlaying {
                        playbackPositionIndicator
                    }
                }
                .frame(
                    width: max(CGFloat(midiService.currentPattern?.metadata.duration ?? 0) * currentTimeDivision, geometry.size.width - pianoKeysWidth),
                    height: calculateConstrainedHeight(availableHeight: geometry.size.height)
                )
            }
            .background(Color.garageBandBackground)
            .onAppear {
                if let pattern = midiService.currentPattern {
                    updateViewForNewPattern(pattern)
                }
                updateNoteHeight(for: geometry.size.height)
            }
            .onChange(of: geometry.size.height) { newHeight in
                updateNoteHeight(for: newHeight)
            }
            .onChange(of: verticalCenterOffset) { newOffset in
                // Scroll to center on the median tone when a new pattern is loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This would require a ScrollViewReader to implement proper scrolling
                    // For now, we'll just log the offset
                    print("🎹 Should scroll to vertical offset: \(newOffset)")
                }
            }
        }
    }
    
    // MARK: - Grid Background
    
    private var gridBackground: some View {
        Canvas { context, size in
            let meterCycle = parameterManager.meterCycle
            let beatWidth = currentTimeDivision  // 1.0 beat (quarter note) in points
            let visibleBeats = Double(size.width) / beatWidth
            let beatColor = Color.garageBandPanel
            
            // Per-bar rendering: bars may have different meters
            for (barStart, meter) in meterCycle.barStarts(upTo: visibleBeats) {
                let barBeats = max(meter.beatsPerBar, 0.25)
                let groupingOnsets = meter.groupingOnsets
                
                // Grouping-span shading: alternate groups get a faint accent tint so
                // 2+2+3 reads differently from 3+2+2
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
                
                // Grouping-start lines (medium) within the bar
                for onset in groupingOnsets.dropFirst() {
                    let x = (barStart + onset) * beatWidth
                    let path = Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(path, with: .color(Color.garageBandAccent.opacity(0.35)), lineWidth: 1.0)
                }
                
                // Barline (thick, bright) at the bar start
                let x = barStart * beatWidth
                let barlinePath = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(barlinePath, with: .color(Color.garageBandText.opacity(0.4)), lineWidth: 2.0)
            }
            
            // Beat lines (thin) every 1.0 beat
            for beat in stride(from: 0.0, through: visibleBeats, by: 1.0) {
                let x = beat * beatWidth
                let path = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(beatColor), lineWidth: 1.0)
            }
            
            // Horizontal lines (note divisions)
            for y in stride(from: 0, through: size.height, by: dynamicNoteHeight * zoomLevel) {
                let path = Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(beatColor), lineWidth: 1.0)
            }
        }
    }
    
    // MARK: - Playback Position Indicator
    
    private var playbackPositionIndicator: some View {
        GeometryReader { geometry in
            let position = CGFloat(midiService.getPlaybackStatus().currentTime) * currentTimeDivision
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 2)
                .position(x: position, y: geometry.size.height / 2)
                .animation(.linear(duration: 0.1), value: midiService.getPlaybackStatus().currentTime)
        }
    }
    
    // MARK: - Footer (Simplified for smaller space)
    
    private var pianoRollFooter: some View {
        HStack {
            // Selection Controls (Compact)
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
            
            // Quick controls (Compact)
            HStack(spacing: 4) {
                Button("Fit") {
                    autoScaleEnabled = true
                }
                .buttonStyle(.bordered)
                .font(.caption2)
                
                Button("Reset") {
                    zoomLevel = 1.0
                    scrollOffset = .zero
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
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomLevel = max(zoomLevel / 1.2, 0.5)
        }
    }
    
    private func toggleNoteSelection(_ noteNumber: Int) {
        if selectedNotes.contains(noteNumber) {
            selectedNotes.remove(noteNumber)
        } else {
            selectedNotes.insert(noteNumber)
        }
    }
    
    private func deleteSelectedNotes() {
        // This would be implemented when we add note editing capabilities
        selectedNotes.removeAll()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Auto-scaling and Centering Methods
    
    /// Calculate the median tone from the current pattern
    private func calculateMedianTone(from pattern: PatternGenerationResult) -> Int {
        let sortedNotes = pattern.notes.soundingNotes.map(\.note).sorted()
        let count = sortedNotes.count
        
        if count == 0 {
            return 60 // Default to middle C
        } else if count % 2 == 0 {
            // Even number of notes - average of two middle values
            let mid1 = sortedNotes[count / 2 - 1]
            let mid2 = sortedNotes[count / 2]
            return (mid1 + mid2) / 2
        } else {
            // Odd number of notes - middle value
            return sortedNotes[count / 2]
        }
    }
    
    /// Calculate the optimal time division to fit the pattern width
    private func calculateOptimalTimeDivision(for pattern: PatternGenerationResult, viewWidth: CGFloat) -> CGFloat {
        let availableWidth = viewWidth - pianoKeysWidth
        let patternDuration = pattern.metadata.duration
        let optimalDivision = availableWidth / patternDuration
        
        // Clamp to reasonable bounds
        return max(minTimeDivision, min(maxTimeDivision, optimalDivision))
    }
    
    /// Calculate the tonal range of the pattern
    private func calculateTonalRange(from pattern: PatternGenerationResult) -> ClosedRange<Int> {
        let notes = pattern.notes.soundingNotes.map(\.note)
        guard let minNote = notes.min(), let maxNote = notes.max() else {
            return 21...108 // Default full piano range
        }
        
        // Add some padding around the tonal range
        let padding = 2
        let lowerBound = max(21, minNote - padding)
        let upperBound = min(108, maxNote + padding)
        
        return lowerBound...upperBound
    }
    
    /// Calculate the optimal note height based on tonal range and available height
    private func calculateOptimalNoteHeight(tonalRange: ClosedRange<Int>, availableHeight: CGFloat) -> CGFloat {
        let rangeSize = tonalRange.upperBound - tonalRange.lowerBound + 1
        let optimalHeight = availableHeight / CGFloat(rangeSize)
        
        // Clamp to reasonable bounds
        return max(minNoteHeight, min(maxNoteHeight, optimalHeight))
    }
    
    /// Calculate the constrained height for the piano roll
    private func calculateConstrainedHeight(availableHeight: CGFloat) -> CGFloat {
        // Use the maximum piano roll height constant
        let maxHeight = min(availableHeight * 0.8, maxPianoRollHeight)
        let calculatedHeight = CGFloat(tonalRange.count) * dynamicNoteHeight * zoomLevel
        
        return min(calculatedHeight, maxHeight)
    }
    
    /// Update the note height based on available space
    private func updateNoteHeight(for availableHeight: CGFloat) {
        // Consider the maximum height constraint when calculating note height
        let constrainedHeight = min(availableHeight, maxPianoRollHeight)
        let optimalHeight = calculateOptimalNoteHeight(tonalRange: tonalRange, availableHeight: constrainedHeight)
        dynamicNoteHeight = optimalHeight
        print("🎹 Updated note height to: \(optimalHeight) for tonal range \(tonalRange.lowerBound)-\(tonalRange.upperBound)")
        print("🎹 Constrained height: \(constrainedHeight), Max height: \(maxPianoRollHeight)")
    }
    
    /// Update the view when a new pattern is generated
    private func updateViewForNewPattern(_ pattern: PatternGenerationResult) {
        // Calculate tonal range
        let newTonalRange = calculateTonalRange(from: pattern)
        tonalRange = newTonalRange
        
        // Calculate median tone
        let medianTone = calculateMedianTone(from: pattern)
        
        // Update note height based on tonal range (will be refined when view appears)
        let estimatedHeight = CGFloat(tonalRange.count) * 20 // Estimate for initial calculation
        dynamicNoteHeight = calculateOptimalNoteHeight(tonalRange: tonalRange, availableHeight: estimatedHeight)
        
        // Auto-scale if enabled
        if autoScaleEnabled {
            // The auto-scaling is handled by the currentTimeDivision computed property
            print("🎹 Auto-scaling enabled for pattern duration: \(pattern.metadata.duration)s")
        }
        
        print("🎹 Piano roll tonal range: \(tonalRange.lowerBound)-\(tonalRange.upperBound) (\(noteName(for: tonalRange.lowerBound)) to \(noteName(for: tonalRange.upperBound)))")
        print("🎹 Piano roll centered on median tone: \(medianTone) (\(noteName(for: medianTone)))")
        print("🎹 Initial note height: \(dynamicNoteHeight)")
        print("🎹 Piano keys and note grid height: \(CGFloat(tonalRange.count) * dynamicNoteHeight * zoomLevel)")
    }
    
    /// Get the note name for a MIDI note number
    private func noteName(for midiNote: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteInOctave = midiNote % 12
        let octave = midiNote / 12 - 1
        return "\(noteNames[noteInOctave])\(octave)"
    }
    
    /// Get the current time division (scaled for auto-fit)
    private var currentTimeDivision: CGFloat {
        guard let pattern = midiService.currentPattern else { return timeDivision * zoomLevel }
        
        if autoScaleEnabled {
            // Calculate optimal time division based on pattern duration and available width
            // For now, we'll use a simple scaling approach
            let baseDivision = timeDivision
            let patternDuration = pattern.metadata.duration
            let scaleFactor = max(0.5, min(2.0, 10.0 / patternDuration)) // Scale based on duration
            return baseDivision * scaleFactor * zoomLevel
        } else {
            return timeDivision * zoomLevel
        }
    }
    
    /// Get the shared height for both piano keys and note grid
    private var sharedHeight: CGFloat {
        // Use the maximum piano roll height constant
        let calculatedHeight = CGFloat(tonalRange.count) * dynamicNoteHeight * zoomLevel
        
        return min(calculatedHeight, maxPianoRollHeight)
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
    let zoomLevel: Double
    let timeDivision: CGFloat
    let tonalRange: ClosedRange<Int>
    let noteHeight: CGFloat
    
    private var noteColor: Color {
        if isSelected {
            return Color.garageBandAccent
        }
        let base = Color(hue: Double(note.note % 12) / 12.0,
                         saturation: 0.7,
                         brightness: isAccented ? 0.95 : 0.8)
        return base
    }
    
    var body: some View {
        let x = CGFloat(startTime) * timeDivision
        let notePosition = tonalRange.upperBound - note.note
        let y = CGFloat(Double(notePosition) * noteHeight * zoomLevel)
        let width = CGFloat(note.duration) * timeDivision
        let height = max(4, noteHeight * 0.9) * zoomLevel
        
        RoundedRectangle(cornerRadius: 4)
            .fill(noteColor)
            .frame(width: width, height: height)
            .position(x: x + width / 2, y: y + 10 * zoomLevel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
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
