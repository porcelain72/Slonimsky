//
//  SheetMusicPopupView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Sheet music popup view displayed in a modal window
struct SheetMusicPopupView: View {
    
    // MARK: - Properties
    @ObservedObject var midiService: MIDIIntegrationService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var zoomLevel: Double = 1.0
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with pattern info
                sheetMusicHeader
                
                // Main content
                sheetMusicContent
                
                // Footer controls
                sheetMusicFooter
            }
            .background(Color.garageBandBackground)
            .navigationTitle("Sheet Music")
           // .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    // Zoom Controls
                    HStack(spacing: 8) {
                        Button(action: zoomOut) {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .disabled(zoomLevel <= 0.5)
                        
                        Text("\(Int(zoomLevel * 100))%")
                            .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                            .frame(minWidth: 50)
                        
                        Button(action: zoomIn) {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .disabled(zoomLevel >= 3.0)
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Header
    
    private var sheetMusicHeader: some View {
        VStack(spacing: 12) {
            // Pattern Info
            if let pattern = midiService.currentPattern {
                VStack(spacing: 8) {
                    HStack {
                        Text("Pattern: \(pattern.metadata.generatorName)")
                            .font(.headline)
                            .foregroundColor(Color.garageBandText)
                        
                        Spacer()
                        
                        Text("Generated in \(String(format: "%.3f", pattern.performance.generationTime))s")
                            .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                    }
                    
                    HStack {
                        Label("\(pattern.notes.count) notes", systemImage: "music.note")
                            .font(.subheadline)
                            .foregroundColor(Color.garageBandSecondary)
                        
                        Spacer()
                        
                        Label("Duration: \(formatTime(pattern.metadata.duration))", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(Color.garageBandSecondary)
                        
                        Spacer()
                        
                        Label("Range: \(pattern.metadata.pitchRange.lowerBound)-\(pattern.metadata.pitchRange.upperBound)", systemImage: "arrow.up.and.down")
                            .font(.subheadline)
                            .foregroundColor(Color.garageBandSecondary)
                    }
                }
                .padding()
                .background(Color.garageBandPanel)
                .cornerRadius(8)
            } else {
                HStack {
                    Text("No pattern available")
                        .font(.subheadline)
                        .foregroundColor(Color.garageBandSecondary)
                    Spacer()
                }
                .padding()
                .background(Color.garageBandPanel)
                .cornerRadius(8)
            }
            
            Divider()
        }
        .padding()
    }
    
    // MARK: - Content
    
    private var sheetMusicContent: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(spacing: 24) {
                // Main placeholder content
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64))
                        .foregroundColor(Color.garageBandSecondary)
                    
                    Text("Sheet Music Notation")
                        .font(.title2)
                        .foregroundColor(Color.garageBandSecondary)
                    
                    Text("Sheet music notation will be implemented in a future update")
                        .font(.body)
                        .foregroundColor(Color.garageBandSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
                // Pattern preview
                if let pattern = midiService.currentPattern {
                    VStack(spacing: 16) {
                        Text("Pattern Details")
                            .font(.headline)
                            .foregroundColor(Color.garageBandText)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(title: "Generator", value: pattern.metadata.generatorName)
                            DetailRow(title: "Notes", value: "\(pattern.notes.count)")
                            DetailRow(title: "Duration", value: formatTime(pattern.metadata.duration))
                            DetailRow(title: "Pitch Range", value: "\(pattern.metadata.pitchRange.lowerBound)-\(pattern.metadata.pitchRange.upperBound)")
                            DetailRow(title: "Generation Time", value: "\(String(format: "%.3f", pattern.performance.generationTime))s")
                            DetailRow(title: "Memory Usage", value: "\(pattern.performance.memoryUsage / 1024) KB")
                            DetailRow(title: "Complexity", value: "\(String(format: "%.2f", pattern.performance.complexity))")
                        }
                        .padding()
                        .background(Color.garageBandPanel)
                        .cornerRadius(8)
                        
                        // Note preview
                        VStack(spacing: 12) {
                            Text("Note Preview")
                                .font(.headline)
                                .foregroundColor(Color.garageBandText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(Array(pattern.notes.prefix(20).enumerated()), id: \.offset) { index, note in
                                    VStack(spacing: 4) {
                                        Text("\(note.note)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text("v\(note.velocity)")
                                            .font(.caption2)
                                            .foregroundColor(Color.garageBandSecondary)
                                        Text("\(String(format: "%.2f", note.duration))")
                                            .font(.caption2)
                                            .foregroundColor(Color.garageBandSecondary)
                                    }
                                    .padding(8)
                                    .background(Color.garageBandBackground)
                                    .cornerRadius(6)
                                }
                            }
                            
                            if pattern.notes.count > 20 {
                                Text("... and \(pattern.notes.count - 20) more notes")
                                    .font(.caption)
                                    .foregroundColor(Color.garageBandSecondary)
                            }
                        }
                        .padding()
                        .background(Color.garageBandPanel)
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Footer
    
    private var sheetMusicFooter: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                // Action buttons
                Button("Export MIDI") {
                    exportMIDI()
                }
                .buttonStyle(.bordered)
                .disabled(midiService.currentPattern == nil)
                
                Button("Print") {
                    printSheetMusic()
                }
                .buttonStyle(.bordered)
                .disabled(midiService.currentPattern == nil)
                
                Spacer()
                
                // Status
                Text("Sheet Music View")
                    .font(.caption)
                    .foregroundColor(Color.garageBandSecondary)
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
    
    private func exportMIDI() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.midi]
        panel.nameFieldStringValue = "slonimsky_sheet_music.mid"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let success = midiService.exportToMIDI(url: url)
                if success {
                    print("✅ MIDI file exported successfully")
                } else {
                    print("❌ Failed to export MIDI file")
                }
            }
        }
    }
    
    private func printSheetMusic() {
        // TODO: Implement print functionality
        print("🖨️ Print sheet music functionality to be implemented")
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.garageBandText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color.garageBandSecondary)
        }
    }
}

// MARK: - Preview

struct SheetMusicPopupView_Previews: PreviewProvider {
    static var previews: some View {
        SheetMusicPopupView(
            midiService: MIDIIntegrationService()
        )
        .frame(width: 800, height: 600)
    }
} 
