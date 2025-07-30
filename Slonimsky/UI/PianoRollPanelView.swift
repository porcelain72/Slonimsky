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
    
    // MARK: - Constants
    private let noteHeight: CGFloat = 20
    private let timeDivision: CGFloat = 50
    private let pianoKeysWidth: CGFloat = 60
    
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
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showNoteDetails) {
            NoteDetailsView(
                midiService: midiService,
                selectedNotes: selectedNotes
            )
        }
    }
    
    // MARK: - Header
    
    private var pianoRollHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "pianokeys")
                    .font(.title2)
                Text("Piano Roll")
                    .font(.headline)
                Spacer()
                
                // Zoom Controls
                HStack(spacing: 8) {
                    Button(action: zoomOut) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .disabled(zoomLevel <= 0.5)
                    
                    Text("\(Int(zoomLevel * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 50)
                    
                    Button(action: zoomIn) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .disabled(zoomLevel >= 3.0)
                }
            }
            
            // Pattern Info
            if let pattern = midiService.currentPattern {
                HStack {
                    Text("Pattern: \(pattern.metadata.generatorName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(pattern.notes.count) notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Duration: \(formatTime(pattern.metadata.duration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Text("No pattern generated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            Divider()
        }
        .padding()
    }
    
    // MARK: - Piano Keys
    
    private var pianoKeysView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach((21...108).reversed(), id: \.self) { noteNumber in
                    PianoKeyView(
                        noteNumber: noteNumber,
                        isSelected: selectedNotes.contains(noteNumber),
                        isHovered: hoveredNote == noteNumber
                    )
                    .frame(height: noteHeight * zoomLevel)
                    .onTapGesture {
                        toggleNoteSelection(noteNumber)
                    }
                    .onHover { isHovered in
                        hoveredNote = isHovered ? noteNumber : nil
                    }
                }
            }
        }
        .frame(width: pianoKeysWidth)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Note Grid
    
    private var noteGridView: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack {
                // Grid Background
                gridBackground
                
                // Notes
                if let pattern = midiService.currentPattern {
                    ForEach(Array(pattern.notes.enumerated()), id: \.offset) { index, note in
                        NoteView(
                            note: note,
                            index: index,
                            isSelected: selectedNotes.contains(note.note),
                            zoomLevel: zoomLevel,
                            timeDivision: timeDivision
                        )
                        .onTapGesture {
                            toggleNoteSelection(note.note)
                        }
                        .onHover { isHovered in
                            hoveredNote = isHovered ? note.note : nil
                        }
                    }
                }
                
                // Playback Position Indicator
                if midiService.getPlaybackStatus().isPlaying {
                    playbackPositionIndicator
                }
            }
            .frame(
                width: max(CGFloat(midiService.currentPattern?.metadata.duration ?? 0) * timeDivision * zoomLevel, 800 - pianoKeysWidth),
                height: CGFloat(88) * noteHeight * zoomLevel
            )
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Grid Background
    
    private var gridBackground: some View {
        Canvas { context, size in
            let gridColor = Color(NSColor.controlBackgroundColor)
            let gridWidth: CGFloat = 1.0
            
            // Vertical lines (time divisions)
            for x in stride(from: 0, through: size.width, by: timeDivision * zoomLevel) {
                let path = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(gridColor), lineWidth: gridWidth)
            }
            
            // Horizontal lines (note divisions)
            for y in stride(from: 0, through: size.height, by: noteHeight * zoomLevel) {
                let path = Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(gridColor), lineWidth: gridWidth)
            }
        }
    }
    
    // MARK: - Playback Position Indicator
    
    private var playbackPositionIndicator: some View {
        GeometryReader { geometry in
            let position = CGFloat(midiService.getPlaybackStatus().currentTime) * timeDivision * zoomLevel
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 2)
                .position(x: position, y: geometry.size.height / 2)
                .animation(.linear(duration: 0.1), value: midiService.getPlaybackStatus().currentTime)
        }
    }
    
    // MARK: - Footer
    
    private var pianoRollFooter: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                // MIDI Playback Controls
                MIDIPlaybackControllerView(midiService: midiService)
                    .frame(minHeight: 120)
                
                Spacer()
                
                // Selection Controls
                if !selectedNotes.isEmpty {
                    HStack(spacing: 8) {
                        Text("\(selectedNotes.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Details") {
                            showNoteDetails = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Delete") {
                            deleteSelectedNotes()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
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
            return .accentColor.opacity(0.3)
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor)
        } else {
            return isBlackKey ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .accentColor
        } else {
            return isBlackKey ? .white : .primary
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .accentColor
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
}

struct NoteView: View {
    let note: MIDIInfo
    let index: Int
    let isSelected: Bool
    let zoomLevel: Double
    let timeDivision: CGFloat
    
    private var noteColor: Color {
        if isSelected {
            return .accentColor
        } else {
            return Color(hue: Double(note.note % 12) / 12.0, saturation: 0.7, brightness: 0.8)
        }
    }
    
    var body: some View {
        let x = CGFloat(index) * timeDivision * zoomLevel
        let notePosition = 108 - note.note
        let y = CGFloat(20.0 * Double(notePosition) * zoomLevel)
        let width = CGFloat(note.beatLength) * timeDivision * zoomLevel
        let height = 18 * zoomLevel
        
        RoundedRectangle(cornerRadius: 4)
            .fill(noteColor)
            .frame(width: width, height: height)
            .position(x: x + width / 2, y: y + 10 * zoomLevel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
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
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("Pitch: \(noteName(for: note.note))")
                                        Spacer()
                                        Text("Velocity: \(note.velocity)")
                                    }
                                    .font(.caption)
                                    
                                    HStack {
                                        Text("Duration: \(String(format: "%.3f", note.beatLength))s")
                                        Spacer()
                                        Text("Start: \(String(format: "%.3f", startTime(for: index, pattern: pattern)))s")
                                    }
                                    .font(.caption)
                                }
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
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
    
    private func startTime(for index: Int, pattern: PatternGenerationResult) -> Double {
        var time: Double = 0
        for i in 0..<index {
            time += pattern.notes[i].beatLength
        }
        return time
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