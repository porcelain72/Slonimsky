//
//  MIDIEngine.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation
import AudioToolbox
import CoreMIDI
import AVFoundation

/// Comprehensive MIDI engine for Slonimsky pattern generation
class MIDIEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0.0
    @Published var totalDuration: TimeInterval = 0.0
    @Published var availableDestinations: [MIDIDestination] = []
    @Published var selectedDestination: MIDIDestination?
    @Published var isLooping = false
    
    // MARK: - Parameter Manager Reference
    private weak var parameterManager: ParameterManager?
    
    // MARK: - Private Properties
    private var musicSequence: MusicSequence?
    private var musicPlayer: MusicPlayer?
    private var midiClient = MIDIClientRef()
    private var outputPort = MIDIPortRef()
    private var audioEngine: AVAudioEngine?
    private var sampler: AVAudioUnitSampler?
    
    private var playbackTimer: Timer?
    private var stopRequested = false
    
    // MARK: - Initialization
    init() {
        setupMIDI()
        setupAudioEngine()
        createEmptySequence()
        updateAvailableDestinations()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Set the parameter manager reference
    /// - Parameter manager: The parameter manager instance
    func setParameterManager(_ manager: ParameterManager) {
        self.parameterManager = manager
    }
    
    /// Get the parameter manager reference
    /// - Returns: The parameter manager or nil if not set
    private func getParameterManager() -> ParameterManager? {
        return parameterManager
    }
    
    /// Generate a MusicSequence from pattern generation result
    /// - Parameter result: The pattern generation result
    /// - Returns: Generated MusicSequence or nil if failed
    func generateMusicSequence(from result: PatternGenerationResult) -> MusicSequence? {
        guard let sequence = createNewSequence() else { return nil }
        
        // Set tempo
        setTempo(sequence: sequence, bpm: 120.0)
        
        // Create tracks for different voices
        let melodyTrack = createMelodyTrack(sequence: sequence, notes: result.notes)
        let harmonyTrack = createHarmonyTrack(sequence: sequence, notes: result.notes)
        let rhythmTrack = createRhythmTrack(sequence: sequence, notes: result.notes)
        
        // Calculate total duration from the notes
        var currentTime: TimeInterval = 0.0
        for note in result.notes {
            currentTime += note.beatLength
        }
        self.totalDuration = currentTime
        
        // Store the sequence
        self.musicSequence = sequence
        
        return sequence
    }
    
    /// Play the current MusicSequence
    func play() {
        guard let sequence = musicSequence, let player = musicPlayer else {
            print("❌ No sequence or player available")
            return
        }
        
        stopRequested = false
        isPlaying = true
        
        // Set the sequence and start playback
        MusicPlayerSetSequence(player, sequence)
        MusicPlayerStart(player)
        
        // Start timer for progress tracking
        startPlaybackTimer()
        
        print("🎵 Started playback")
    }
    
    /// Stop playback
    func stop() {
        stopRequested = true
        isPlaying = false
        
        if let player = musicPlayer {
            MusicPlayerStop(player)
        }
        
        stopPlaybackTimer()
        currentTime = 0.0
        
        print("⏹️ Stopped playback")
    }
    
    /// Pause playback
    func pause() {
        guard let player = musicPlayer else { return }
        
        MusicPlayerStop(player)
        isPlaying = false
        stopPlaybackTimer()
        
        print("⏸️ Paused playback")
    }
    
    /// Resume playback
    func resume() {
        guard let player = musicPlayer else { return }
        
        MusicPlayerStart(player)
        isPlaying = true
        startPlaybackTimer()
        
        print("▶️ Resumed playback")
    }
    
    /// Set looping behavior
    /// - Parameter looping: Whether to loop the playback
    func setLooping(_ looping: Bool) {
        isLooping = looping
        print("🔄 Looping \(looping ? "enabled" : "disabled")")
    }
    
    /// Update the current sequence with a new one
    /// - Parameter result: The new pattern generation result
    /// - Returns: True if successful
    func updateSequence(with result: PatternGenerationResult) -> Bool {
        guard let newSequence = generateMusicSequence(from: result) else {
            print("❌ Failed to generate new sequence")
            return false
        }
        
        // Store the new sequence
        self.musicSequence = newSequence
        
        // If currently playing, update the player with the new sequence
        if isPlaying, let player = musicPlayer {
            // Stop the current playback first
            MusicPlayerStop(player)
            
            // Set the new sequence
            MusicPlayerSetSequence(player, newSequence)
            
            // If looping is enabled, restart playback to ensure the new sequence plays correctly
            if isLooping {
                MusicPlayerSetTime(player, 0.0)
                MusicPlayerStart(player)
                currentTime = 0.0
                print("🔄 Updated sequence during looping playback - restarted")
            } else {
                // Resume playback with the new sequence
                MusicPlayerStart(player)
                print("🔄 Updated sequence during playback")
            }
        }
        
        return true
    }
    
    /// Export MusicSequence to MIDI file
    /// - Parameter url: The URL to save the MIDI file
    /// - Returns: True if successful
    func exportToMIDI(url: URL) -> Bool {
        guard let sequence = musicSequence else {
            print("❌ No sequence to export")
            return false
        }
        
        let status = MusicSequenceFileCreate(sequence, url as CFURL, .midiType, .eraseFile, 0)
        
        if status == noErr {
            print("✅ MIDI file exported to: \(url.path)")
            return true
        } else {
            print("❌ Failed to export MIDI file: \(status)")
            return false
        }
    }
    
    /// Send MIDI data to external destination
    /// - Parameter notes: Array of MIDI notes to send
    /// - Parameter bpm: Tempo in beats per minute
    func sendToExternalMIDI(notes: [MIDIInfo], bpm: Double = 120.0) {
        guard let destination = selectedDestination?.endpoint else {
            print("⚠️ No MIDI destination selected")
            return
        }
        
        let beatDuration = 60.0 / bpm
        let queue = DispatchQueue(label: "MIDIOutputQueue", qos: .userInitiated)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            var currentTime: TimeInterval = 0.0
            
            for note in notes {
                let delay = currentTime
                
                // Schedule note on
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.sendMIDIMessage(
                        status: 0x90,
                        data1: UInt8(clamping: note.note),
                        data2: note.velocity,
                        destination: destination
                    )
                }
                
                // Schedule note off
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + note.beatLength * beatDuration) {
                    self.sendMIDIMessage(
                        status: 0x80,
                        data1: UInt8(clamping: note.note),
                        data2: 0,
                        destination: destination
                    )
                }
                
                currentTime += note.beatLength * beatDuration
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMIDI() {
        let status = MIDIClientCreate("Slonimsky MIDI Client" as CFString, nil, nil, &midiClient)
        if status != noErr {
            print("❌ Failed to create MIDI client: \(status)")
            return
        }
        
        let portStatus = MIDIOutputPortCreate(midiClient, "Slonimsky Output Port" as CFString, &outputPort)
        if portStatus != noErr {
            print("❌ Failed to create MIDI output port: \(portStatus)")
            return
        }
        
        print("✅ MIDI setup complete")
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        
        guard let engine = audioEngine, let sampler = sampler else { return }
        
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
            loadPianoSound()
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    private func loadPianoSound() {
        guard let sampler = sampler else { return }
        
        let soundBank = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        
        do {
            try sampler.loadSoundBankInstrument(
                at: soundBank,
                program: 0, // Piano
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            print("✅ Piano sound loaded")
        } catch {
            print("❌ Failed to load piano sound: \(error)")
        }
    }
    
    private func createEmptySequence() {
        NewMusicSequence(&musicSequence)
        NewMusicPlayer(&musicPlayer)
        
        if let sequence = musicSequence, let player = musicPlayer {
            MusicPlayerSetSequence(player, sequence)
            print("✅ Empty sequence created")
        }
    }
    
    private func createNewSequence() -> MusicSequence? {
        var sequence: MusicSequence?
        NewMusicSequence(&sequence)
        return sequence
    }
    
    private func setTempo(sequence: MusicSequence, bpm: Double) {
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        
        if let tempoTrack = tempoTrack {
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, bpm)
        }
    }
    
    private func createMelodyTrack(sequence: MusicSequence, notes: [MIDIInfo]) -> MusicTrack? {
        var track: MusicTrack?
        MusicSequenceNewTrack(sequence, &track)
        
        guard let track = track else { return nil }
        
        var currentTime: MusicTimeStamp = 0.0
        
        for note in notes {
            var midiMessage = MIDINoteMessage(
                channel: 0,
                note: UInt8(clamping: note.note),
                velocity: note.velocity,
                releaseVelocity: 0,
                duration: Float32(note.beatLength)
            )
            
            MusicTrackNewMIDINoteEvent(track, currentTime, &midiMessage)
            currentTime += MusicTimeStamp(note.beatLength)
        }
        
        return track
    }
    
    private func createHarmonyTrack(sequence: MusicSequence, notes: [MIDIInfo]) -> MusicTrack? {
        var track: MusicTrack?
        MusicSequenceNewTrack(sequence, &track)
        
        guard let track = track else { return nil }
        
        // Create harmonic accompaniment based on the melody
        let harmonicNotes = generateHarmonicAccompaniment(from: notes)
        var currentTime: MusicTimeStamp = 0.0
        
        for chord in harmonicNotes {
            for note in chord {
                var midiMessage = MIDINoteMessage(
                    channel: 1,
                    note: UInt8(clamping: note.note),
                    velocity: UInt8(clamping: Int(note.velocity) - 20), // Softer
                    releaseVelocity: 0,
                    duration: Float32(note.beatLength)
                )
                
                MusicTrackNewMIDINoteEvent(track, currentTime, &midiMessage)
            }
            currentTime += MusicTimeStamp(chord.first?.beatLength ?? 1.0)
        }
        
        return track
    }
    
    private func createRhythmTrack(sequence: MusicSequence, notes: [MIDIInfo]) -> MusicTrack? {
        var track: MusicTrack?
        MusicSequenceNewTrack(sequence, &track)
        
        guard let track = track else { return nil }
        
        // Create rhythmic accompaniment
        let rhythmNotes = generateRhythmicAccompaniment(from: notes)
        var currentTime: MusicTimeStamp = 0.0
        
        for note in rhythmNotes {
            var midiMessage = MIDINoteMessage(
                channel: 9, // Drum channel
                note: UInt8(clamping: note.note),
                velocity: note.velocity,
                releaseVelocity: 0,
                duration: Float32(note.beatLength)
            )
            
            MusicTrackNewMIDINoteEvent(track, currentTime, &midiMessage)
            currentTime += MusicTimeStamp(note.beatLength)
        }
        
        return track
    }
    
    private func generateHarmonicAccompaniment(from notes: [MIDIInfo]) -> [[MIDIInfo]] {
        var chords: [[MIDIInfo]] = []
        
        // Group notes into chords based on timing
        var currentChord: [MIDIInfo] = []
        var lastTime: TimeInterval = 0.0
        
        for note in notes {
            if abs(note.beatLength - lastTime) < 0.1 {
                // Same time, add to current chord
                currentChord.append(note)
            } else {
                // New time, start new chord
                if !currentChord.isEmpty {
                    chords.append(currentChord)
                }
                currentChord = [note]
                lastTime = note.beatLength
            }
        }
        
        if !currentChord.isEmpty {
            chords.append(currentChord)
        }
        
        return chords
    }
    
    private func generateRhythmicAccompaniment(from notes: [MIDIInfo]) -> [MIDIInfo] {
        var rhythmNotes: [MIDIInfo] = []
        
        // Get rhythmic accompaniment settings from parameter manager
        guard let parameterManager = getParameterManager() else {
            return rhythmNotes
        }
        
        guard parameterManager.rhythmicAccompanimentEnabled else {
            return rhythmNotes
        }
        
        let style = parameterManager.rhythmicAccompanimentStyle
        let density = parameterManager.rhythmicAccompanimentDensity
        let velocity = parameterManager.rhythmicAccompanimentVelocity
        
        // Calculate base velocity (0-127)
        let baseVelocity = UInt8(clamping: Int(velocity * 127))
        
        // Create rhythmic pattern based on style
        for (index, note) in notes.enumerated() {
            let densityMultiplier = Int(density * 4)
            
            switch style {
            case .basic:
                if index % densityMultiplier == 0 {
                    // Bass drum
                    rhythmNotes.append(MIDIInfo(note: 36, velocity: baseVelocity, beatLength: 0.25, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Hi-hat
                    rhythmNotes.append(MIDIInfo(note: 42, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.7)), beatLength: 0.25, cycleIndex: 0))
                }
                
            case .jazz:
                if index % densityMultiplier == 0 {
                    // Bass drum
                    rhythmNotes.append(MIDIInfo(note: 36, velocity: baseVelocity, beatLength: 0.25, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Ride cymbal
                    rhythmNotes.append(MIDIInfo(note: 51, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.8)), beatLength: 0.25, cycleIndex: 0))
                }
                if index % densityMultiplier == 2 {
                    // Snare drum
                    rhythmNotes.append(MIDIInfo(note: 38, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.9)), beatLength: 0.25, cycleIndex: 0))
                }
                
            case .latin:
                if index % densityMultiplier == 0 {
                    // Conga
                    rhythmNotes.append(MIDIInfo(note: 60, velocity: baseVelocity, beatLength: 0.25, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Claves
                    rhythmNotes.append(MIDIInfo(note: 75, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.8)), beatLength: 0.25, cycleIndex: 0))
                }
                if index % densityMultiplier == 2 {
                    // Bongo
                    rhythmNotes.append(MIDIInfo(note: 61, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.7)), beatLength: 0.25, cycleIndex: 0))
                }
                
            case .electronic:
                if index % densityMultiplier == 0 {
                    // Kick drum
                    rhythmNotes.append(MIDIInfo(note: 36, velocity: baseVelocity, beatLength: 0.25, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Closed hi-hat
                    rhythmNotes.append(MIDIInfo(note: 42, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.6)), beatLength: 0.25, cycleIndex: 0))
                }
                if index % densityMultiplier == 2 {
                    // Snare drum
                    rhythmNotes.append(MIDIInfo(note: 38, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.8)), beatLength: 0.25, cycleIndex: 0))
                }
                
            case .orchestral:
                if index % densityMultiplier == 0 {
                    // Timpani
                    rhythmNotes.append(MIDIInfo(note: 47, velocity: baseVelocity, beatLength: 0.5, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Bass drum
                    rhythmNotes.append(MIDIInfo(note: 35, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.7)), beatLength: 0.25, cycleIndex: 0))
                }
            }
        }
        
        return rhythmNotes
    }
    
    private func updateAvailableDestinations() {
        let count = MIDIGetNumberOfDestinations()
        availableDestinations = []
        
        for i in 0..<count {
            let endpoint = MIDIGetDestination(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
            
            if let name = name?.takeRetainedValue() {
                let destination = MIDIDestination(
                    name: name as String,
                    endpoint: endpoint
                )
                availableDestinations.append(destination)
            }
        }
        
        // Select first destination by default
        if selectedDestination == nil && !availableDestinations.isEmpty {
            selectedDestination = availableDestinations.first
        }
    }
    
    private func sendMIDIMessage(status: UInt8, data1: UInt8, data2: UInt8, destination: MIDIEndpointRef) {
        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length = 3
        packet.data.0 = status
        packet.data.1 = data1
        packet.data.2 = data2
        
        var list = MIDIPacketList(numPackets: 1, packet: packet)
        MIDISend(outputPort, destination, &list)
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.musicPlayer else { return }
            
            var currentTime: MusicTimeStamp = 0.0
            MusicPlayerGetTime(player, &currentTime)
            self.currentTime = TimeInterval(currentTime)
            
            // Check if we've reached the end of the sequence
            if self.currentTime >= self.totalDuration && self.isPlaying {
                if self.isLooping {
                    // Restart playback for looping
                    MusicPlayerSetTime(player, 0.0)
                    MusicPlayerStart(player)
                    self.currentTime = 0.0
                    print("🔄 Looping playback - restarted at time 0")
                } else {
                    self.stop()
                }
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func cleanup() {
        stop()
        
        if let player = musicPlayer {
            DisposeMusicPlayer(player)
        }
        
        if let sequence = musicSequence {
            DisposeMusicSequence(sequence)
        }
        
        MIDIPortDispose(outputPort)
        MIDIClientDispose(midiClient)
    }
}

// MARK: - Supporting Types

/// Represents a MIDI destination
struct MIDIDestination: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let endpoint: MIDIEndpointRef
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(endpoint)
    }
    
    static func == (lhs: MIDIDestination, rhs: MIDIDestination) -> Bool {
        return lhs.endpoint == rhs.endpoint
    }
} 