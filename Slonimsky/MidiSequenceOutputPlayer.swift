//
//  MidiSequenceOutputPlayer.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 25/07/2025.
//

import Foundation
import CoreMIDI
import AudioToolbox

class MIDISequenceOutputPlayer {
    private var sequence: MusicSequence?
    private var musicPlayer: MusicPlayer?

    private var midiClient = MIDIClientRef()
    private var outputPort = MIDIPortRef()
    private var destination: MIDIEndpointRef?

    init() {
        MIDIClientCreate("MIDI Seq Output Client" as CFString, nil, nil, &midiClient)
        MIDIOutputPortCreate(midiClient, "Seq Output Port" as CFString, &outputPort)

        let destCount = MIDIGetNumberOfDestinations()
        if destCount > 0 {
            destination = MIDIGetDestination(0)
        }

        NewMusicSequence(&sequence)
        NewMusicPlayer(&musicPlayer)

        if let seq = sequence, let player = musicPlayer {
            MusicPlayerSetSequence(player, seq)
        }
    }

    var hasAvailableDestination: Bool {
        let destCount = MIDIGetNumberOfDestinations()
        return destCount > 0
    }

    func play(melody: [[MIDIInfo]], chords: [ChordEvent], noteDuration: TimeInterval, bpm: Double) {
        guard let sequence else { return }

        var trackCount: UInt32 = 0
        MusicSequenceGetTrackCount(sequence, &trackCount)

        for i in 0..<trackCount {
            var track: MusicTrack?
            MusicSequenceGetIndTrack(sequence, i, &track)
            if let track = track {
                MusicSequenceDisposeTrack(sequence, track)
            }
        }


        // Melody Track
        var melodyTrack: MusicTrack?
        MusicSequenceNewTrack(sequence, &melodyTrack)

        // Chords Track
        var chordTrack: MusicTrack?
        MusicSequenceNewTrack(sequence, &chordTrack)

        // Set destination endpoint
        if let melodyTrack, let dest = destination {
            MusicTrackSetDestMIDIEndpoint(melodyTrack, dest)
        }
        if let chordTrack, let dest = destination {
            MusicTrackSetDestMIDIEndpoint(chordTrack, dest)
        }

        // Tempo
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        if let tempoTrack {
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, bpm)
        }

        // Melody events
        let beatDuration = noteDuration * (bpm / 60.0)
        var currentBeat: MusicTimeStamp = 0

        for subSeq in melody {
            for note in subSeq {
                var msg = MIDINoteMessage(
                    channel: 0,
                    note: UInt8(clamping: note.note),
                    velocity: note.velocity,
                    releaseVelocity: 0,
                    duration: Float32(beatDuration)
                )
                MusicTrackNewMIDINoteEvent(melodyTrack!, currentBeat, &msg)
                currentBeat += MusicTimeStamp(beatDuration)
            }
            currentBeat += MusicTimeStamp(beatDuration * 0.5)
        }

        // Chord events
        for chord in chords {
            for note in chord.notes {
                var chordMsg = MIDINoteMessage(
                    channel: chord.channel,
                    note: UInt8(clamping: note),
                    velocity: chord.velocity,
                    releaseVelocity: 0,
                    duration: Float32(chord.durationBeats)
                )
                MusicTrackNewMIDINoteEvent(chordTrack!, chord.startBeat, &chordMsg)
            }
        }

        // Start
        if let musicPlayer {
            MusicPlayerPreroll(musicPlayer)
            MusicPlayerStart(musicPlayer)
        }
    }

    func stop() {
        if let musicPlayer {
            MusicPlayerStop(musicPlayer)
        }

        // Send "All Notes Off"
        guard let dest = destination else { return }

        for channel: UInt8 in 0..<16 {
            let msg: [UInt8] = [0xB0 | channel, 123, 0] // CC 123 = All Notes Off
            var packetList = MIDIPacketList()
            var packet = MIDIPacketListInit(&packetList)
            packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, msg.count, msg)
            MIDISend(outputPort, dest, &packetList)
        }
    }

    func isPlaying() -> Bool {
        guard let player = musicPlayer else { return false }
        var isPlaying: DarwinBoolean = false
        MusicPlayerIsPlaying(player, &isPlaying)
        return isPlaying.boolValue
    }
}
