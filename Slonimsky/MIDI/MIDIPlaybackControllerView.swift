//
//  MIDIPlaybackControllerView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// SwiftUI view for MIDI playback control
struct MIDIPlaybackControllerView: View {
    
    // MARK: - Properties
    @ObservedObject var midiService: MIDIIntegrationService
    @State private var playbackStatus: PlaybackStatus = PlaybackStatus(isPlaying: false, currentTime: 0.0, totalDuration: 0.0)
    @State private var updateTimer: Timer?
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Playback Controls
            HStack(spacing: 20) {
                // Play/Pause Button
                Button(action: togglePlayback) {
                    Image(systemName: playbackStatus.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(playbackStatus.isPlaying ? .orange : .green)
                }
                .disabled(midiService.currentPattern == nil)
                
                // Stop Button
                Button(action: stopPlayback) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                }
                .disabled(midiService.currentPattern == nil || !playbackStatus.isPlaying)
                
                // Export Button
                Button(action: exportMIDI) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .disabled(midiService.currentPattern == nil)
                
                // External MIDI Button
                Button(action: sendToExternalMIDI) {
                    Image(systemName: "music.note.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
                }
                .disabled(midiService.currentPattern == nil || midiService.getAvailableDestinations().isEmpty)
            }
            
            // Progress Bar
            if midiService.currentPattern != nil {
                VStack(spacing: 8) {
                    ProgressView(value: playbackStatus.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 2)
                    
                    HStack {
                        Text(formatTime(playbackStatus.currentTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(playbackStatus.totalDuration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Status Information
            VStack(spacing: 8) {
                if let pattern = midiService.currentPattern {
                    HStack {
                        Text("Pattern: \(pattern.metadata.generatorName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(pattern.notes.count) notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Generation: \(String(format: "%.3f", midiService.lastGenerationTime))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Duration: \(formatTime(playbackStatus.totalDuration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = midiService.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            
            // MIDI Destination Picker
            if !midiService.getAvailableDestinations().isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MIDI Destination:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("MIDI Destination", selection: Binding(
                        get: { midiService.getAvailableDestinations().first { $0.id == midiService.getAvailableDestinations().first?.id } },
                        set: { destination in
                            if let destination = destination {
                                midiService.setSelectedDestination(destination)
                            }
                        }
                    )) {
                        ForEach(midiService.getAvailableDestinations()) { destination in
                            Text(destination.name).tag(destination)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .onAppear {
            startUpdateTimer()
        }
        .onDisappear {
            stopUpdateTimer()
        }
    }
    
    // MARK: - Actions
    
    private func togglePlayback() {
        if playbackStatus.isPlaying {
            midiService.pausePlayback()
        } else {
            midiService.playCurrentPattern()
        }
    }
    
    private func stopPlayback() {
        midiService.stopPlayback()
    }
    
    private func exportMIDI() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.midi]
        panel.nameFieldStringValue = "slonimsky_pattern.mid"
        
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
    
    private func sendToExternalMIDI() {
        midiService.sendToExternalMIDI(bpm: 120.0)
    }
    
    // MARK: - Helper Methods
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            playbackStatus = midiService.getPlaybackStatus()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

struct MIDIPlaybackControllerView_Previews: PreviewProvider {
    static var previews: some View {
        MIDIPlaybackControllerView(midiService: MIDIIntegrationService())
            .frame(width: 400)
            .padding()
    }
} 