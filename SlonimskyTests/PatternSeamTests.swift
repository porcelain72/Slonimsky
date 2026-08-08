//
//  PatternSeamTests.swift
//  SlonimskyTests
//

import XCTest
@testable import Slonimsky

final class PatternSeamTests: XCTestCase {

    func testDropsMatchingSeamPitch() {
        let leading = [
            MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1),
            MIDIInfo(note: 64, velocity: 80, onset: 1, duration: 1)
        ]
        let trailing = [
            MIDIInfo(note: 64, velocity: 80, onset: 0, duration: 1),
            MIDIInfo(note: 67, velocity: 80, onset: 1, duration: 1)
        ]
        let trimmed = PatternSeam.droppingTrailingSeamNote(of: leading, before: trailing)
        XCTAssertEqual(trimmed.map(\.note), [60])
    }

    func testKeepsDifferingSeamPitch() {
        let leading = [
            MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1),
            MIDIInfo(note: 62, velocity: 80, onset: 1, duration: 1)
        ]
        let trailing = [
            MIDIInfo(note: 64, velocity: 80, onset: 0, duration: 1)
        ]
        let trimmed = PatternSeam.droppingTrailingSeamNote(of: leading, before: trailing)
        XCTAssertEqual(trimmed.count, 2)
    }

    func testDoesNotDropSoleNote() {
        let leading = [MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1)]
        let trailing = [MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1)]
        let trimmed = PatternSeam.droppingTrailingSeamNote(of: leading, before: trailing)
        XCTAssertEqual(trimmed.count, 1, "Never leave a segment empty by seam drop")
    }

    func testIgnoresRestsWhenFindingSeam() {
        let leading = [
            MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1),
            MIDIInfo(note: 64, velocity: 80, onset: 1, duration: 1),
            MIDIInfo(note: 0, velocity: 0, onset: 2, duration: 1, isRest: true)
        ]
        let trailing = [
            MIDIInfo(note: 64, velocity: 80, onset: 0, duration: 1)
        ]
        let trimmed = PatternSeam.droppingTrailingSeamNote(of: leading, before: trailing)
        XCTAssertEqual(trimmed.count, 2)
        XCTAssertEqual(trimmed[0].note, 60)
        XCTAssertTrue(trimmed[1].isRest)
    }

    func testAppendingOffsetsAfterTrim() {
        let leading = [
            MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1),
            MIDIInfo(note: 64, velocity: 80, onset: 1, duration: 1)
        ]
        let trailing = [
            MIDIInfo(note: 64, velocity: 80, onset: 0, duration: 0.5),
            MIDIInfo(note: 67, velocity: 80, onset: 0.5, duration: 0.5)
        ]
        let joined = PatternSeam.appending(trailing, to: leading, dropMatchingSeam: true)
        XCTAssertEqual(joined.soundingNotes.map(\.note), [60, 64, 67])
        XCTAssertEqual(joined.totalLength, 2.0, accuracy: 1e-9)
    }

    func testFinalPassKeptWhenConcatenatingRepeats() {
        let pass = [
            MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1),
            MIDIInfo(note: 64, velocity: 80, onset: 1, duration: 1),
            MIDIInfo(note: 60, velocity: 80, onset: 2, duration: 1)
        ]
        let joined = PatternSeam.concatenate([pass, pass, pass], dropMatchingSeam: true)
        let pitches = joined.notes.soundingNotes.map(\.note)
        // Two seams dropped; final tonic retained
        XCTAssertEqual(pitches, [60, 64, 60, 64, 60, 64, 60])
        XCTAssertEqual(pitches.last, 60)
    }

    func testPitchListHelper() {
        XCTAssertEqual(
            PatternSeam.droppingTrailingSeamPitch(of: [60, 62, 64, 60], before: [60, 62]),
            [60, 62, 64]
        )
        XCTAssertEqual(
            PatternSeam.droppingTrailingSeamPitch(of: [60, 62], before: [64]),
            [60, 62]
        )
    }
}
