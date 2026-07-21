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
    private var externalMIDIThread: Thread?
    
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
    /// - Parameters:
    ///   - result: The pattern generation result
    ///   - parameters: The pattern generation parameters
    /// - Returns: Generated MusicSequence or nil if failed
    func generateMusicSequence(
        from result: PatternGenerationResult,
        parameters: PatternParameters,
        tempoMarkers: [TempoChangeMarker] = []
    ) -> MusicSequence? {
        guard let sequence = createNewSequence() else { return nil }
        
        // Set tempo (multi-marker for compositions) and time signature from parameters
        if tempoMarkers.isEmpty {
            setTempo(sequence: sequence, bpm: parameters.tempo)
        } else {
            setTempos(sequence: sequence, markers: tempoMarkers)
        }
        setTimeSignatures(sequence: sequence, meterCycle: parameters.meterCycle, duration: result.notes.totalLength)
        
        // Create melody track (always needed)
        let melodyTrack = createMelodyTrack(sequence: sequence, notes: result.notes)
        print("🎵 Created melody track with \(result.notes.count) notes")
        
        // Check parameter settings to determine which tracks to create
        let shouldCreateHarmony = parameters.chordGeneration.enabled
        let shouldCreateRhythm = shouldCreateRhythmTrack(for: result.notes)
        
        let harmonyTrack = shouldCreateHarmony ? createHarmonyTrack(sequence: sequence, notes: result.notes) : nil
        let rhythmTrack = shouldCreateRhythm ? createRhythmTrack(sequence: sequence, notes: result.notes) : nil
        
        print("🎵 Track creation: Melody=✅, Harmony=\(shouldCreateHarmony ? "✅" : "❌"), Rhythm=\(shouldCreateRhythm ? "✅" : "❌")")
        print("🎵 Chord generation enabled: \(parameters.chordGeneration.enabled)")
        
        // Total duration in beats: latest event end (rests included)
        self.totalDuration = result.notes.totalLength
        
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
    /// - Parameters:
    ///   - result: The new pattern generation result
    ///   - parameters: The pattern generation parameters
    ///   - tempoMarkers: Optional composition tempo changes; empty uses `parameters.tempo`
    /// - Returns: True if successful
    func updateSequence(
        with result: PatternGenerationResult,
        parameters: PatternParameters,
        tempoMarkers: [TempoChangeMarker] = []
    ) -> Bool {
        guard let newSequence = generateMusicSequence(
            from: result,
            parameters: parameters,
            tempoMarkers: tempoMarkers
        ) else {
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
    /// Uses a dedicated high-priority thread with precise sleep-based timing
    /// to avoid main-thread jitter from DispatchQueue.main.asyncAfter.
    /// - Parameter notes: Array of MIDI notes to send
    /// - Parameter bpm: Tempo in beats per minute
    func sendToExternalMIDI(notes: [MIDIInfo], bpm: Double = 120.0) {
        guard let destination = selectedDestination?.endpoint else {
            print("⚠️ No MIDI destination selected")
            return
        }
        
        // Cancel any in-progress external playback
        externalMIDIThread?.cancel()

        let beatDuration = 60.0 / bpm

        // Build an onset-sorted event queue (note-offs before note-ons at equal
        // times) so overlapping and simultaneous notes are sent correctly.
        struct MIDIEvent {
            let timeBeats: Double
            let isNoteOn: Bool
            let note: UInt8
            let velocity: UInt8
            let channel: UInt8
        }

        var events: [MIDIEvent] = []
        let dedupedNotes = notes.soundingNotes.dedupedExactUnisons()
        let voices = Set(dedupedNotes.map { $0.voice })
        for voice in voices {
            let channel = MIDIEngine.channel(forVoice: voice)
            let voiceNotes = dedupedNotes.filter { $0.voice == voice }.gatedSamePitch()
            for note in voiceNotes {
                events.append(MIDIEvent(timeBeats: note.onset, isNoteOn: true, note: UInt8(clamping: note.note), velocity: note.velocity, channel: channel))
                events.append(MIDIEvent(timeBeats: note.end, isNoteOn: false, note: UInt8(clamping: note.note), velocity: 0, channel: channel))
            }
        }
        events.sort { lhs, rhs in
            if abs(lhs.timeBeats - rhs.timeBeats) > 1e-9 {
                return lhs.timeBeats < rhs.timeBeats
            }
            // Offs first at equal times to avoid stuck notes on repeated pitches
            return !lhs.isNoteOn && rhs.isNoteOn
        }

        let thread = Thread { [weak self] in
            guard let self = self else { return }

            // Raise thread priority for tighter timing
            Thread.current.qualityOfService = .userInteractive

            var elapsedBeats = 0.0
            for event in events {
                if Thread.current.isCancelled { break }

                let waitBeats = event.timeBeats - elapsedBeats
                if waitBeats > 0 {
                    Thread.sleep(forTimeInterval: waitBeats * beatDuration)
                    elapsedBeats = event.timeBeats
                }

                self.sendMIDIMessage(
                    status: (event.isNoteOn ? 0x90 : 0x80) | event.channel,
                    data1: event.note,
                    data2: event.velocity,
                    destination: destination
                )
            }
        }
        
        thread.qualityOfService = .userInteractive
        thread.name = "SlonimskyMIDIOutput"
        externalMIDIThread = thread
        thread.start()
    }
    
    /// Cancel any in-progress external MIDI playback
    func stopExternalMIDI() {
        externalMIDIThread?.cancel()
        externalMIDIThread = nil
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
        setTempos(sequence: sequence, markers: [TempoChangeMarker(beat: 0, bpm: bpm)])
    }

    /// Write tempo change events at the given beat positions (composition slot boundaries).
    private func setTempos(sequence: MusicSequence, markers: [TempoChangeMarker]) {
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        guard let tempoTrack = tempoTrack else { return }

        let sorted = markers.sorted { $0.beat < $1.beat }
        for marker in sorted {
            MusicTrackNewExtendedTempoEvent(tempoTrack, MusicTimeStamp(marker.beat), marker.bpm)
        }
    }

    /// Write MIDI time-signature meta events (FF 58) to the tempo track so
    /// exported files carry the meter cycle into DAWs. One event at time 0,
    /// plus one at every bar start whose meter differs from the previous bar.
    private func setTimeSignatures(sequence: MusicSequence, meterCycle: MeterCycle, duration: Double) {
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        guard let track = tempoTrack else { return }

        var previousMeter: Meter?
        for (onset, meter) in meterCycle.barStarts(upTo: max(0, duration)) {
            if let previous = previousMeter,
               previous.numerator == meter.numerator && previous.denominator == meter.denominator {
                previousMeter = meter
                continue
            }
            writeTimeSignatureEvent(track: track, meter: meter, at: MusicTimeStamp(onset))
            previousMeter = meter
        }
    }

    private func writeTimeSignatureEvent(track: MusicTrack, meter: Meter, at timestamp: MusicTimeStamp) {
        // Data: [numerator, log2(denominator), MIDI clocks per click, 32nds per quarter]
        let dataSize = 4
        // MIDIMetaEvent is a variable-length C struct (data[1] tail); allocate
        // enough raw storage for the extra data bytes.
        let eventSize = MemoryLayout<MIDIMetaEvent>.size + dataSize - 1
        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: eventSize,
            alignment: MemoryLayout<MIDIMetaEvent>.alignment
        )
        defer { rawPointer.deallocate() }

        let eventPointer = rawPointer.bindMemory(to: MIDIMetaEvent.self, capacity: 1)
        eventPointer.pointee.metaEventType = 0x58
        eventPointer.pointee.dataLength = UInt32(dataSize)
        withUnsafeMutablePointer(to: &eventPointer.pointee.data) { dataPointer in
            dataPointer.withMemoryRebound(to: UInt8.self, capacity: dataSize) { bytes in
                bytes[0] = UInt8(clamping: meter.numerator)
                bytes[1] = UInt8(clamping: Int(log2(Double(meter.denominator)).rounded()))
                bytes[2] = 24 // MIDI clocks per metronome click
                bytes[3] = 8  // 32nd notes per quarter note
            }
        }

        let status = MusicTrackNewMetaEvent(track, timestamp, eventPointer)
        if status != noErr {
            print("⚠️ Failed to write time-signature meta event: \(status)")
        }
    }
    
    /// MIDI channel for a melody voice. Channel 1 is reserved for the harmony
    /// track and channel 9 for drums, so the phasing voice lands on channel 2.
    static func channel(forVoice voice: Int) -> UInt8 {
        voice == 0 ? 0 : UInt8(clamping: voice + 1)
    }

    private func createMelodyTrack(sequence: MusicSequence, notes: [MIDIInfo]) -> MusicTrack? {
        // Cross-voice unison de-dup first: phasing lock points would otherwise
        // double every note sample-identically on two channels
        let soundingNotes = notes.soundingNotes.dedupedExactUnisons()
        let voices = Set(soundingNotes.map { $0.voice }).sorted()
        print("🎵 Creating melody track(s) for \(voices.count) voice(s), \(soundingNotes.count) sounding notes (\(notes.count - soundingNotes.count) rests skipped)")

        var firstTrack: MusicTrack?
        for voice in voices {
            var track: MusicTrack?
            MusicSequenceNewTrack(sequence, &track)
            guard let track = track else { continue }
            if firstTrack == nil { firstTrack = track }

            let channel = MIDIEngine.channel(forVoice: voice)
            let voiceNotes = soundingNotes.filter { $0.voice == voice }.gatedSamePitch()
            for note in voiceNotes {
                var midiMessage = MIDINoteMessage(
                    channel: channel,
                    note: UInt8(clamping: note.note),
                    velocity: note.velocity,
                    releaseVelocity: 0,
                    duration: Float32(note.duration)
                )
                MusicTrackNewMIDINoteEvent(track, MusicTimeStamp(note.onset), &midiMessage)
            }
        }

        return firstTrack
    }
    
    private func createHarmonyTrack(sequence: MusicSequence, notes: [MIDIInfo]) -> MusicTrack? {
        var track: MusicTrack?
        MusicSequenceNewTrack(sequence, &track)
        
        guard let track = track else { return nil }
        
        // Create harmonic accompaniment based on the melody. Flatten chord tones
        // to their chord onsets and gate same-pitch collisions before emitting.
        let harmonicNotes = generateHarmonicAccompaniment(from: notes)
        var flattened: [MIDIInfo] = []
        for chord in harmonicNotes {
            guard let chordOnset = chord.first?.onset else { continue }
            for note in chord {
                var tone = note
                tone.onset = chordOnset
                flattened.append(tone)
            }
        }

        for note in flattened.gatedSamePitch() {
            var midiMessage = MIDINoteMessage(
                channel: 1,
                note: UInt8(clamping: note.note),
                velocity: UInt8(clamping: Int(note.velocity) - 20), // Softer
                releaseVelocity: 0,
                duration: Float32(note.duration)
            )

            MusicTrackNewMIDINoteEvent(track, MusicTimeStamp(note.onset), &midiMessage)
        }

        return track
    }
    
    private func createRhythmTrack(sequence: MusicSequence, notes: [MIDIInfo]) -> MusicTrack? {
        var track: MusicTrack?
        MusicSequenceNewTrack(sequence, &track)
        
        guard let track = track else { return nil }
        
        // Create rhythmic accompaniment (hits carry their own onsets from the melody)
        let rhythmNotes = generateRhythmicAccompaniment(from: notes)

        for note in rhythmNotes {
            var midiMessage = MIDINoteMessage(
                channel: 9, // Drum channel
                note: UInt8(clamping: note.note),
                velocity: note.velocity,
                releaseVelocity: 0,
                duration: Float32(note.duration)
            )

            MusicTrackNewMIDINoteEvent(track, MusicTimeStamp(note.onset), &midiMessage)
        }

        return track
    }
    
    private func shouldCreateRhythmTrack(for notes: [MIDIInfo]) -> Bool {
        // Only create rhythm for complex patterns with many notes
        // This could also be controlled by a parameter setting in the future
        return notes.count > 20
    }
    
    private func generateHarmonicAccompaniment(from notes: [MIDIInfo]) -> [[MIDIInfo]] {
        var chords: [[MIDIInfo]] = []

        // Group sounding notes that share the same onset into chords
        var currentChord: [MIDIInfo] = []

        for note in notes.soundingNotes.sorted(by: { $0.onset < $1.onset }) {
            if let chordOnset = currentChord.first?.onset, abs(note.onset - chordOnset) < 1e-6 {
                // Same onset, add to current chord
                currentChord.append(note)
            } else {
                // New onset, start new chord
                if !currentChord.isEmpty {
                    chords.append(currentChord)
                }
                currentChord = [note]
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
        for (index, note) in notes.soundingNotes.enumerated() {
            let densityMultiplier = Int(density * 4)
            
            switch style {
            case .basic:
                if index % densityMultiplier == 0 {
                    // Bass drum
                    rhythmNotes.append(MIDIInfo(note: 36, velocity: baseVelocity, onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Hi-hat
                    rhythmNotes.append(MIDIInfo(note: 42, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.7)), onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                
            case .jazz:
                if index % densityMultiplier == 0 {
                    // Bass drum
                    rhythmNotes.append(MIDIInfo(note: 36, velocity: baseVelocity, onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Ride cymbal
                    rhythmNotes.append(MIDIInfo(note: 51, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.8)), onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                if index % densityMultiplier == 2 {
                    // Snare drum
                    rhythmNotes.append(MIDIInfo(note: 38, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.9)), onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                
            case .latin:
                if index % densityMultiplier == 0 {
                    // Conga
                    rhythmNotes.append(MIDIInfo(note: 60, velocity: baseVelocity, onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Claves
                    rhythmNotes.append(MIDIInfo(note: 75, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.8)), onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                if index % densityMultiplier == 2 {
                    // Bongo
                    rhythmNotes.append(MIDIInfo(note: 61, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.7)), onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                
            case .electronic:
                if index % densityMultiplier == 0 {
                    // Kick drum
                    rhythmNotes.append(MIDIInfo(note: 36, velocity: baseVelocity, onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Closed hi-hat
                    rhythmNotes.append(MIDIInfo(note: 42, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.6)), onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                if index % densityMultiplier == 2 {
                    // Snare drum
                    rhythmNotes.append(MIDIInfo(note: 38, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.8)), onset: note.onset, duration: 0.25, cycleIndex: 0))
                }
                
            case .orchestral:
                if index % densityMultiplier == 0 {
                    // Timpani
                    rhythmNotes.append(MIDIInfo(note: 47, velocity: baseVelocity, onset: note.onset, duration: 0.5, cycleIndex: 0))
                }
                if index % (densityMultiplier / 2) == 1 {
                    // Bass drum
                    rhythmNotes.append(MIDIInfo(note: 35, velocity: UInt8(clamping: Int(Double(baseVelocity) * 0.7)), onset: note.onset, duration: 0.25, cycleIndex: 0))
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