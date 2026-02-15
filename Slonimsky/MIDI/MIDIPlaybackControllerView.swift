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
    @State private var sendToExternalMIDI: Bool = false
    @State private var externalMIDIPlaybackStatus: PlaybackStatus = PlaybackStatus(isPlaying: false, currentTime: 0.0, totalDuration: 0.0)
    @State private var externalMIDITimer: Timer?
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Playback Controls - Proper Playback Button Style
            HStack(spacing: 8) {
                // Play/Pause Button - Proper Playback Style
                Button(action: togglePlayback) {
                    Image(systemName: playbackStatus.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(playbackStatus.isPlaying ? .orange : .green)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(playbackStatus.isPlaying ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                        )
                }
                .disabled(midiService.currentPattern == nil)
                .buttonStyle(.plain)
                
                // Stop Button - Proper Playback Style
                Button(action: stopPlayback) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.15))
                        )
                }
                .disabled(midiService.currentPattern == nil || !playbackStatus.isPlaying)
                .buttonStyle(.plain)
                
                Spacer()
                
                // Export Button
                Button(action: exportMIDI) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(midiService.currentPattern == nil ? .secondary : .blue)
                }
                .disabled(midiService.currentPattern == nil)
                .buttonStyle(.plain)
                .help("Export MIDI")
            }
            
            // Progress Section
            VStack(spacing: 8) {
                // External MIDI Mode Indicator
                if sendToExternalMIDI {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.system(size: 12))
                            .foregroundColor(.purple)
                        Text("External MIDI Mode")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple.opacity(0.1))
                    )
                }
                
                // Progress Bar - Show for both internal and external MIDI
                ProgressView(value: sendToExternalMIDI ? externalMIDIPlaybackStatus.progress : playbackStatus.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: sendToExternalMIDI ? .purple : .accentColor))
                    .scaleEffect(y: 1.5)
                    .opacity(midiService.currentPattern == nil ? 0.3 : 1.0)
                
                // Time Display - Show for both internal and external MIDI
                HStack {
                    Text(formatTime(sendToExternalMIDI ? externalMIDIPlaybackStatus.currentTime : playbackStatus.currentTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(midiService.currentPattern == nil ? Color(red: 0.7, green: 0.7, blue: 0.7) : Color(red: 0.9, green: 0.9, blue: 0.9))
                    
                    Spacer()
                    
                    Text(formatTime(sendToExternalMIDI ? externalMIDIPlaybackStatus.totalDuration : playbackStatus.totalDuration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(midiService.currentPattern == nil ? Color(red: 0.7, green: 0.7, blue: 0.7) : Color(red: 0.9, green: 0.9, blue: 0.9))
                }
            }
            
            // Pattern Information
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Pattern")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    Spacer()
                    Text(midiService.currentPattern?.metadata.generatorName ?? "No Pattern")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(midiService.currentPattern == nil ? Color(red: 0.7, green: 0.7, blue: 0.7) : Color(red: 0.9, green: 0.9, blue: 0.9))
                }
                
                HStack {
                    Text("Notes")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    Spacer()
                    Text("\(midiService.currentPattern?.notes.count ?? 0)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(midiService.currentPattern == nil ? Color(red: 0.7, green: 0.7, blue: 0.7) : Color(red: 0.9, green: 0.9, blue: 0.9))
                }
                
                if midiService.lastGenerationTime > 0 {
                    HStack {
                        Text("Generated")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                        Spacer()
                        Text("\(String(format: "%.2f", midiService.lastGenerationTime))s")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
            )
            
            // Error Display
            if let errorMessage = midiService.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.1))
                )
            }
            
            // Loop, External MIDI, and Autosave Checkboxes
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Loop Playback", isOn: Binding(
                    get: { midiService.isLooping },
                    set: { _ in midiService.toggleLooping() }
                ))
                .toggleStyle(CheckboxToggleStyle())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                .disabled(midiService.currentPattern == nil)
                
                Toggle("Send to External MIDI", isOn: $sendToExternalMIDI)
                .toggleStyle(CheckboxToggleStyle())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                .disabled(midiService.currentPattern == nil || midiService.getAvailableDestinations().isEmpty)
                
                Toggle("Autosave Sequences", isOn: Binding(
                    get: { midiService.autosaveEnabled },
                    set: { _ in midiService.toggleAutosave() }
                ))
                .toggleStyle(CheckboxToggleStyle())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                .help("Automatically save new sequences to ~/Documents/Slonimsky/Sequences/")
            }
            
            // MIDI Destination
            if !midiService.getAvailableDestinations().isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MIDI Destination")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    
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
                    .font(.system(size: 12))
                    .opacity(midiService.currentPattern == nil ? 0.5 : 1.0)
                }
            }
            
            // Spacer to push everything to the top
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        .cornerRadius(8)
        .onAppear {
            startAllTimers()
        }
        .onDisappear {
            stopAllTimers()
        }
    }
    
    // MARK: - Actions
    
    private func togglePlayback() {
        if sendToExternalMIDI {
            // External MIDI playback
            if externalMIDIPlaybackStatus.isPlaying {
                stopExternalMIDIPlayback()
            } else {
                startExternalMIDIPlayback()
            }
        } else {
            // Internal playback
            if playbackStatus.isPlaying {
                midiService.pausePlayback()
            } else {
                midiService.playCurrentPattern()
            }
        }
    }
    
    private func stopPlayback() {
        if sendToExternalMIDI {
            stopExternalMIDIPlayback()
        } else {
            midiService.stopPlayback()
        }
    }
    
    
    private func startExternalMIDIPlayback() {
        guard let pattern = midiService.currentPattern else { return }
        
        // Calculate total duration based on pattern
        let bpm = midiService.currentTempo
        let beatDuration = 60.0 / bpm
        let totalDuration = pattern.notes.reduce(0.0) { total, note in
            total + note.beatLength * beatDuration
        }
        
        // Set up external MIDI playback status
        externalMIDIPlaybackStatus = PlaybackStatus(
            isPlaying: true,
            currentTime: 0.0,
            totalDuration: totalDuration
        )
        
        // Start the external MIDI playback
        midiService.sendToExternalMIDI(bpm: bpm)
        
        // Start timer for external MIDI playback
        startExternalMIDITimer()
        
        print("🎵 Started external MIDI playback")
    }
    
    private func stopExternalMIDIPlayback() {
        midiService.stopExternalMIDI()
        
        externalMIDIPlaybackStatus = PlaybackStatus(
            isPlaying: false,
            currentTime: 0.0,
            totalDuration: externalMIDIPlaybackStatus.totalDuration
        )
        
        stopExternalMIDITimer()
        
        print("⏹️ Stopped external MIDI playback")
    }
    
    private func startExternalMIDITimer() {
        externalMIDITimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.externalMIDIPlaybackStatus.isPlaying {
                let newCurrentTime = self.externalMIDIPlaybackStatus.currentTime + 0.1
                
                // Update the playback status with new time
                self.externalMIDIPlaybackStatus = PlaybackStatus(
                    isPlaying: self.externalMIDIPlaybackStatus.isPlaying,
                    currentTime: newCurrentTime,
                    totalDuration: self.externalMIDIPlaybackStatus.totalDuration
                )
                
                // Check if we've reached the end
                if newCurrentTime >= self.externalMIDIPlaybackStatus.totalDuration {
                    if self.midiService.isLooping {
                        // Restart for looping
                        self.externalMIDIPlaybackStatus = PlaybackStatus(
                            isPlaying: self.externalMIDIPlaybackStatus.isPlaying,
                            currentTime: 0.0,
                            totalDuration: self.externalMIDIPlaybackStatus.totalDuration
                        )
                        self.midiService.sendToExternalMIDI()
                        print("🔄 External MIDI looping - restarted")
                    } else {
                        // Stop playback
                        self.stopExternalMIDIPlayback()
                    }
                }
            }
        }
    }
    
    private func stopExternalMIDITimer() {
        externalMIDITimer?.invalidate()
        externalMIDITimer = nil
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
    
    private func startAllTimers() {
        startUpdateTimer()
        if sendToExternalMIDI && externalMIDIPlaybackStatus.isPlaying {
            startExternalMIDITimer()
        }
    }
    
    private func stopAllTimers() {
        stopUpdateTimer()
        stopExternalMIDITimer()
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
