//
//  SheetMusicPanelView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Sheet music panel view - placeholder for future implementation
struct SheetMusicPanelView: View {
    
    // MARK: - Properties
    @ObservedObject var midiService: MIDIIntegrationService
    
    // MARK: - State
    @State private var zoomLevel: Double = 1.0
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetMusicHeader
            
            // Placeholder Content
            placeholderContent
            
            // Footer Controls
            placeholderFooter
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var sheetMusicHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "music.note.list")
                    .font(.title2)
                Text("Sheet Music")
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
    
    // MARK: - Placeholder Content
    
    private var placeholderContent: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(spacing: 24) {
                // Main placeholder
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("Sheet Music View")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Sheet music notation will be implemented in a future update")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
                // Feature preview
                if let pattern = midiService.currentPattern {
                    VStack(spacing: 12) {
                        Text("Pattern Preview")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Generator:")
                                Spacer()
                                Text(pattern.metadata.generatorName)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Notes:")
                                Spacer()
                                Text("\(pattern.notes.count)")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Duration:")
                                Spacer()
                                Text(formatTime(pattern.metadata.duration))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Range:")
                                Spacer()
                                Text("\(pattern.metadata.pitchRange.lowerBound)-\(pattern.metadata.pitchRange.upperBound)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Placeholder Footer
    
    private var placeholderFooter: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                // Placeholder buttons
                Button("Export") {
                    // TODO: Implement export functionality
                }
                .buttonStyle(.bordered)
                .disabled(midiService.currentPattern == nil)
                
                Button("Print") {
                    // TODO: Implement print functionality
                }
                .buttonStyle(.bordered)
                .disabled(midiService.currentPattern == nil)
                
                Spacer()
                
                // Status
                Text("Placeholder View")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

struct SheetMusicPanelView_Previews: PreviewProvider {
    static var previews: some View {
        SheetMusicPanelView(
            midiService: MIDIIntegrationService()
        )
        .frame(width: 600, height: 800)
    }
} 