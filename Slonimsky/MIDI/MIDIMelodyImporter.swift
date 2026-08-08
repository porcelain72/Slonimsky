//
//  MIDIMelodyImporter.swift
//  Slonimsky
//
//  Imports a Standard MIDI File into a CustomMelody for the step editor.
//  Polyphonic files are reduced to a single voice (upper note at each onset;
//  overlapping later notes are skipped). Durations and gaps are quantized to
//  the DurationValue palette and truncated to the melody capacity.
//

import Foundation
import AudioToolbox

/// Absolute-timed MIDI note used as the importer's intermediate representation.
struct MIDINoteEvent: Equatable {
    let pitch: Int
    let onset: Double
    let duration: Double

    var end: Double { onset + duration }
}

enum MIDIMelodyImportError: Error, LocalizedError {
    case cannotCreateSequence
    case cannotLoadFile(OSStatus)
    case noNotesFound

    var errorDescription: String? {
        switch self {
        case .cannotCreateSequence:
            return "Could not create a MIDI sequence"
        case .cannotLoadFile(let status):
            return "Could not load MIDI file (status \(status))"
        case .noNotesFound:
            return "No notes found in the MIDI file"
        }
    }
}

/// Loads MIDI files and converts them into `CustomMelody` step-entry notes.
enum MIDIMelodyImporter {

    /// Import a `.mid` / `.midi` file into a custom melody capped at `maxBeats`.
    static func importMelody(from url: URL, maxBeats: Double) throws -> CustomMelody {
        let events = try loadNoteEvents(from: url)
        let melody = melody(from: events, maxBeats: maxBeats)
        guard !melody.pitches.isEmpty else {
            throw MIDIMelodyImportError.noNotesFound
        }
        return melody
    }

    /// Pure conversion path (testable without files).
    static func melody(from events: [MIDINoteEvent], maxBeats: Double) -> CustomMelody {
        let monophonic = extractMonophonic(from: events)
        let notes = sequentialNotes(from: monophonic, maxBeats: maxBeats)

        var melody = CustomMelody()
        melody.isEnabled = !notes.isEmpty
        melody.notes = notes
        return melody
    }

    // MARK: - File loading

    private static func loadNoteEvents(from url: URL) throws -> [MIDINoteEvent] {
        var sequence: MusicSequence?
        guard NewMusicSequence(&sequence) == noErr, let sequence = sequence else {
            throw MIDIMelodyImportError.cannotCreateSequence
        }
        defer { DisposeMusicSequence(sequence) }

        let loadStatus = MusicSequenceFileLoad(
            sequence,
            url as CFURL,
            .midiType,
            MusicSequenceLoadFlags()
        )
        guard loadStatus == noErr else {
            throw MIDIMelodyImportError.cannotLoadFile(loadStatus)
        }

        var trackCount: UInt32 = 0
        MusicSequenceGetTrackCount(sequence, &trackCount)

        var events: [MIDINoteEvent] = []
        for trackIndex in 0..<trackCount {
            var track: MusicTrack?
            guard MusicSequenceGetIndTrack(sequence, trackIndex, &track) == noErr,
                  let track = track else { continue }
            events.append(contentsOf: noteEvents(in: track))
        }

        guard !events.isEmpty else {
            throw MIDIMelodyImportError.noNotesFound
        }
        return events
    }

    private static func noteEvents(in track: MusicTrack) -> [MIDINoteEvent] {
        var iterator: MusicEventIterator?
        guard NewMusicEventIterator(track, &iterator) == noErr,
              let iterator = iterator else { return [] }
        defer { DisposeMusicEventIterator(iterator) }

        var events: [MIDINoteEvent] = []
        var hasEvent: DarwinBoolean = false
        MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)

        while hasEvent.boolValue {
            var timeStamp: MusicTimeStamp = 0
            var eventType: MusicEventType = 0
            var eventData: UnsafeRawPointer?
            var eventDataSize: UInt32 = 0

            let status = MusicEventIteratorGetEventInfo(
                iterator,
                &timeStamp,
                &eventType,
                &eventData,
                &eventDataSize
            )

            if status == noErr,
               eventType == kMusicEventType_MIDINoteMessage,
               let eventData = eventData {
                let message = eventData.assumingMemoryBound(to: MIDINoteMessage.self).pointee
                let duration = Double(message.duration)
                if message.velocity > 0, duration > 1e-6 {
                    events.append(MIDINoteEvent(
                        pitch: Int(message.note),
                        onset: Double(timeStamp),
                        duration: duration
                    ))
                }
            }

            MusicEventIteratorNextEvent(iterator)
            MusicEventIteratorHasCurrentEvent(iterator, &hasEvent)
        }

        return events
    }

    // MARK: - Monophonic reduction

    /// Prefer the highest pitch at a shared onset; skip notes that start while a
    /// previously chosen note is still sounding.
    static func extractMonophonic(from events: [MIDINoteEvent]) -> [MIDINoteEvent] {
        let sorted = events.sorted {
            if abs($0.onset - $1.onset) < 1e-6 {
                return $0.pitch > $1.pitch
            }
            return $0.onset < $1.onset
        }

        var selected: [MIDINoteEvent] = []
        for event in sorted {
            if let last = selected.last {
                if abs(event.onset - last.onset) < 1e-6 {
                    continue // lower chord tone at same onset
                }
                if event.onset < last.end - 1e-6 {
                    continue // overlaps previous choice
                }
            }
            selected.append(event)
        }
        return selected
    }

    // MARK: - Sequential step notes

    static func sequentialNotes(from events: [MIDINoteEvent], maxBeats: Double) -> [MelodyNote] {
        guard maxBeats > 1e-6 else { return [] }

        var notes: [MelodyNote] = []
        var cursor = 0.0
        let capacity = maxBeats

        for event in events {
            if cursor >= capacity - 1e-6 { break }

            // Rest covering the gap before this note
            if event.onset > cursor + 1e-6 {
                let gap = min(event.onset - cursor, capacity - cursor)
                appendRestCovering(beats: gap, into: &notes, cursor: &cursor, capacity: capacity)
            }
            if cursor >= capacity - 1e-6 { break }

            let remaining = capacity - cursor
            var value = DurationValue.nearest(to: max(event.duration, 0.25))
            if value.beats > remaining + 1e-6 {
                guard let shorter = DurationValue.allCases
                    .sorted(by: { $0.beats > $1.beats })
                    .first(where: { $0.beats <= remaining + 1e-6 }) else { break }
                value = shorter
            }

            notes.append(MelodyNote(
                pitch: max(0, min(127, event.pitch)),
                value: value,
                isRest: false
            ))
            cursor += value.beats
        }

        return notes
    }

    private static func appendRestCovering(
        beats: Double,
        into notes: inout [MelodyNote],
        cursor: inout Double,
        capacity: Double
    ) {
        let values = DurationValue.covering(beats: beats)
        for value in values {
            if cursor + value.beats > capacity + 1e-6 {
                if let shorter = DurationValue.allCases
                    .sorted(by: { $0.beats > $1.beats })
                    .first(where: { cursor + $0.beats <= capacity + 1e-6 }) {
                    notes.append(MelodyNote(pitch: 0, value: shorter, isRest: true))
                    cursor += shorter.beats
                }
                break
            }
            notes.append(MelodyNote(pitch: 0, value: value, isRest: true))
            cursor += value.beats
        }
    }
}
