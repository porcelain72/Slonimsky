//
//  MidiExporter.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 24/07/2025.
//

import Foundation
import AudioToolbox

import AVFoundation



import Foundation
import AVFoundation
import AudioToolbox

enum MIDIExporter {
    static func exportMIDI(
        melodyTracks: [[MIDIInfo]],
        chordEvents: [ChordEvent],
        noteDuration: TimeInterval,
        bpm: Double,
        fileURL: URL
    ) throws {
        var musicSequence: MusicSequence? = nil
        NewMusicSequence(&musicSequence)
        guard let sequence = musicSequence else { throw NSError(domain: "MIDIExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create MusicSequence"]) }

        // Set tempo
        var tempoTrack: MusicTrack? = nil
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        let tempoEvent = ExtendedTempoEvent(bpm: bpm)
        MusicTrackNewExtendedTempoEvent(tempoTrack!, 0, tempoEvent.bpm)

        // Create melody track
        var melodyTrack: MusicTrack? = nil
        MusicSequenceNewTrack(sequence, &melodyTrack)

        // Flatten melody into single track
        var currentTime: MusicTimeStamp = 0
        for subsequence in melodyTracks {
            for note in subsequence {
                var msg = MIDINoteMessage(
                    channel: 0,
                    note: UInt8(clamping: note.note),
                    velocity: note.velocity,
                    releaseVelocity: 0,
                    duration: Float32(noteDuration)
                )
                MusicTrackNewMIDINoteEvent(melodyTrack!, currentTime, &msg)
                currentTime += MusicTimeStamp(noteDuration)
            }
        }

        // Chord track
        var chordTrack: MusicTrack? = nil
        MusicSequenceNewTrack(sequence, &chordTrack)

        for chord in chordEvents {
            let chordStart = MusicTimeStamp(chord.startBeat)
            let chordDuration = Float32(chord.durationBeats)
            for note in chord.notes {
                var msg = MIDINoteMessage(
                    channel: chord.channel,
                    note: UInt8(clamping: note),
                    velocity: chord.velocity,
                    releaseVelocity: 0,
                    duration: chordDuration
                )
                MusicTrackNewMIDINoteEvent(chordTrack!, chordStart, &msg)
            }
        }

        // Export to data
        var data: Unmanaged<CFData>? = nil
        let status = MusicSequenceFileCreateData(
            sequence,
            .midiType,
            .eraseFile,
            480, // resolution
            &data
        )

        guard status == noErr, let cfData = data?.takeRetainedValue() else {
            throw NSError(domain: "MIDIExport", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create MIDI data"])
        }

        let midiData = cfData as Data
        try midiData.write(to: fileURL)
    }
}
