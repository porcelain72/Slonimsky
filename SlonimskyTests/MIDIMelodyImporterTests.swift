//
//  MIDIMelodyImporterTests.swift
//  SlonimskyTests
//

import XCTest
import AudioToolbox
@testable import Slonimsky

final class MIDIMelodyImporterTests: XCTestCase {

    func testNearestDuration() {
        XCTAssertEqual(DurationValue.nearest(to: 1.0), .quarter)
        XCTAssertEqual(DurationValue.nearest(to: 0.5), .eighth)
        XCTAssertEqual(DurationValue.nearest(to: 0.26), .sixteenth)
        XCTAssertEqual(DurationValue.nearest(to: 1.4), .dottedQuarter)
    }

    func testCoveringBeats() {
        XCTAssertEqual(DurationValue.covering(beats: 1.0), [.quarter])
        XCTAssertEqual(DurationValue.covering(beats: 3.5), [.dottedHalf, .eighth])
        XCTAssertEqual(DurationValue.covering(beats: 0), [])
    }

    func testMonophonicPrefersUpperVoiceOfChord() {
        let events = [
            MIDINoteEvent(pitch: 60, onset: 0, duration: 1),
            MIDINoteEvent(pitch: 64, onset: 0, duration: 1),
            MIDINoteEvent(pitch: 67, onset: 0, duration: 1)
        ]
        let mono = MIDIMelodyImporter.extractMonophonic(from: events)
        XCTAssertEqual(mono.map(\.pitch), [67])
    }

    func testMonophonicSkipsOverlappingNotes() {
        let events = [
            MIDINoteEvent(pitch: 60, onset: 0, duration: 2),
            MIDINoteEvent(pitch: 62, onset: 1, duration: 1), // overlaps
            MIDINoteEvent(pitch: 64, onset: 2, duration: 1)
        ]
        let mono = MIDIMelodyImporter.extractMonophonic(from: events)
        XCTAssertEqual(mono.map(\.pitch), [60, 64])
    }

    func testSequentialNotesInsertRestsForGaps() {
        let events = [
            MIDINoteEvent(pitch: 60, onset: 0, duration: 1),
            MIDINoteEvent(pitch: 64, onset: 2, duration: 1) // 1-beat gap
        ]
        let notes = MIDIMelodyImporter.sequentialNotes(from: events, maxBeats: 8)
        XCTAssertEqual(notes.count, 3)
        XCTAssertEqual(notes[0].pitch, 60)
        XCTAssertFalse(notes[0].isRest)
        XCTAssertTrue(notes[1].isRest)
        XCTAssertEqual(notes[1].value, .quarter)
        XCTAssertEqual(notes[2].pitch, 64)
    }

    func testSequentialNotesRespectMaxBeats() {
        let events = [
            MIDINoteEvent(pitch: 60, onset: 0, duration: 1),
            MIDINoteEvent(pitch: 62, onset: 1, duration: 1),
            MIDINoteEvent(pitch: 64, onset: 2, duration: 1),
            MIDINoteEvent(pitch: 65, onset: 3, duration: 1)
        ]
        let notes = MIDIMelodyImporter.sequentialNotes(from: events, maxBeats: 2.0)
        XCTAssertEqual(notes.totalBeats, 2.0, accuracy: 1e-9)
        XCTAssertEqual(notes.filter { !$0.isRest }.map(\.pitch), [60, 62])
    }

    func testMelodyFromEventsEnablesWhenNonEmpty() {
        let events = [MIDINoteEvent(pitch: 60, onset: 0, duration: 1)]
        let melody = MIDIMelodyImporter.melody(from: events, maxBeats: 8)
        XCTAssertTrue(melody.isEnabled)
        XCTAssertEqual(melody.pitches, [60])
    }

    func testImportRoundTripFromWrittenMIDIFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("slonimsky_import_test_\(UUID().uuidString).mid")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try writeSimpleMIDIFile(
            to: tempURL,
            notes: [
                (pitch: 60, onset: 0.0, duration: 1.0),
                (pitch: 64, onset: 1.5, duration: 0.5),
                (pitch: 67, onset: 2.0, duration: 2.0)
            ]
        )

        let melody = try MIDIMelodyImporter.importMelody(from: tempURL, maxBeats: 32)
        XCTAssertTrue(melody.isEnabled)
        XCTAssertEqual(melody.pitches, [60, 64, 67])
        XCTAssertTrue(melody.notes.contains(where: { $0.isRest }), "Gap before E should become a rest")
        XCTAssertLessThanOrEqual(melody.totalBeats, 32.0 + 1e-6)
    }

    func testImportEmptyMIDIThrows() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("slonimsky_empty_\(UUID().uuidString).mid")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try writeSimpleMIDIFile(to: tempURL, notes: [])

        XCTAssertThrowsError(try MIDIMelodyImporter.importMelody(from: tempURL, maxBeats: 8)) { error in
            XCTAssertTrue(error is MIDIMelodyImportError)
        }
    }

    // MARK: - Helpers

    private func writeSimpleMIDIFile(
        to url: URL,
        notes: [(pitch: Int, onset: Double, duration: Double)]
    ) throws {
        var sequence: MusicSequence?
        XCTAssertEqual(NewMusicSequence(&sequence), noErr)
        guard let sequence = sequence else {
            return XCTFail("NewMusicSequence failed")
        }
        defer { DisposeMusicSequence(sequence) }

        var track: MusicTrack?
        XCTAssertEqual(MusicSequenceNewTrack(sequence, &track), noErr)
        guard let track = track else {
            return XCTFail("MusicSequenceNewTrack failed")
        }

        for note in notes {
            var message = MIDINoteMessage(
                channel: 0,
                note: UInt8(note.pitch),
                velocity: 80,
                releaseVelocity: 0,
                duration: Float32(note.duration)
            )
            XCTAssertEqual(
                MusicTrackNewMIDINoteEvent(track, MusicTimeStamp(note.onset), &message),
                noErr
            )
        }

        let status = MusicSequenceFileCreate(sequence, url as CFURL, .midiType, .eraseFile, 0)
        XCTAssertEqual(status, noErr, "MusicSequenceFileCreate failed: \(status)")
    }
}

private extension Array where Element == MelodyNote {
    var totalBeats: Double {
        reduce(0.0) { $0 + $1.beats }
    }
}
