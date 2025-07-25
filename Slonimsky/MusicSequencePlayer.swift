//
//  MusicSequencePlayer.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 24/07/2025.
//

import Foundation
import AVFoundation
import AudioToolbox

class MusicSequencePlayer {
    private var sequence: MusicSequence?
    private var musicPlayer: MusicPlayer?
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()

    init() {
        setupAudioEngine()
        createEmptySequence()
    }

    private func setupAudioEngine() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
        } catch {
            print("❌ Failed to start engine: \(error)")
        }

        // Load piano
        let soundBank = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        do {
            try sampler.loadSoundBankInstrument(
                at: soundBank,
                program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
        } catch {
            print("❌ Failed to load sound: \(error)")
        }
    }

    private func createEmptySequence() {
        NewMusicSequence(&sequence)
        NewMusicPlayer(&musicPlayer)

        if let seq = sequence, let player = musicPlayer {
            MusicPlayerSetSequence(player, seq)
           // MusicSequenceSetAUGraph(seq, engine.auGraph)
        }
    }
    
    func load(melodySequences: [[MIDIInfo]],
              chords: [ChordEvent],
              noteDuration: TimeInterval,
              bpm: Double = 120) {
        
        guard let sequence = sequence else { return }

        // 1. Create melody track
        var melodyTrack: MusicTrack?
        MusicSequenceNewTrack(sequence, &melodyTrack)

        // 2. Create chord track
        var chordTrack: MusicTrack?
        MusicSequenceNewTrack(sequence, &chordTrack)

        guard let melodyTrack = melodyTrack, let chordTrack = chordTrack else { return }

        // 3. Set tempo
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        if let tempoTrack = tempoTrack {
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, bpm)
        }

        let beatDuration = noteDuration * (bpm / 60.0)
        var currentMelodyBeat: Double = 0.0

        // 4. Add melody notes
        for subSeq in melodySequences {
            for note in subSeq {
                var msg = MIDINoteMessage(
                    channel: 0,
                    note: UInt8(clamping: note.note),
                    velocity: note.velocity,
                    releaseVelocity: 0,
                    duration: Float32(beatDuration)
                )
                MusicTrackNewMIDINoteEvent(melodyTrack, MusicTimeStamp(currentMelodyBeat), &msg)
                currentMelodyBeat += beatDuration
            }

            // Optional spacing between subsequences
            currentMelodyBeat += beatDuration * 0.5
        }

        // 5. Add chords
        for chord in chords {
            for note in chord.notes {
                var chordMsg = MIDINoteMessage(
                    channel: chord.channel,
                    note: UInt8(clamping: note),
                    velocity: chord.velocity,
                    releaseVelocity: 0,
                    duration: Float32(chord.durationBeats)
                )
                MusicTrackNewMIDINoteEvent(chordTrack, MusicTimeStamp(chord.startBeat), &chordMsg)
            }
        }

        // 6. Preroll
        MusicPlayerPreroll(musicPlayer!)
    }

    func load(sequences: [[MIDIInfo]], noteDuration: TimeInterval, bpm: Double = 120) {
        guard let sequence = sequence else { return }

        var track: MusicTrack?
        MusicSequenceNewTrack(sequence, &track)
        guard let musicTrack = track else { return }

        // Tempo
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        if let tempoTrack = tempoTrack {
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, bpm)
        }

        let beatDuration = noteDuration * (bpm / 60.0)
        var currentBeat: Double = 0.0

        for subSequence in sequences {
            for note in subSequence {
                var msg = MIDINoteMessage(
                    channel: 0,
                    note: UInt8(clamping: note.note),
                    velocity: note.velocity,
                    releaseVelocity: 0,
                    duration: Float32(beatDuration)
                )

                let beatPosition = MusicTimeStamp(currentBeat)
                MusicTrackNewMIDINoteEvent(musicTrack, beatPosition, &msg)

                currentBeat += beatDuration
            }

            // Optional: add a short gap between subsequences
           // currentBeat += beatDuration * 0.5
        }

        MusicPlayerPreroll(musicPlayer!)
    }

    func load(notes: [MIDIInfo], noteDuration: TimeInterval, bpm: Double = 120) {
        guard let sequence = sequence else { return }

        var track: MusicTrack?
        MusicSequenceNewTrack(sequence, &track)
        guard let musicTrack = track else { return }

        let tempoTrack: MusicTrack? = {
            var temp: MusicTrack?
            MusicSequenceGetTempoTrack(sequence, &temp)
            return temp
        }()

        if let tempoTrack = tempoTrack {
            let tempoEvent = 60.0 / bpm
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, bpm)
        }

        let beatDuration = noteDuration * (bpm / 60.0)

        for (i, note) in notes.enumerated() {
            var msg = MIDINoteMessage(
                channel: 0,
                note: UInt8(clamping: note.note),
                velocity: note.velocity,
                releaseVelocity: 0,
                duration: Float32(beatDuration)
            )

            let beatPosition = MusicTimeStamp(Double(i) * beatDuration)
            MusicTrackNewMIDINoteEvent(musicTrack, beatPosition, &msg)
        }

        MusicPlayerPreroll(musicPlayer!)
    }

    func play() {
        stop()
        MusicPlayerStart(musicPlayer!)
    }

    func stop() {
        MusicPlayerStop(musicPlayer!)
    }

    func isPlaying() -> Bool {
        var isPlaying: DarwinBoolean = false
        MusicPlayerIsPlaying(musicPlayer!, &isPlaying)
        return isPlaying.boolValue
    }
}
