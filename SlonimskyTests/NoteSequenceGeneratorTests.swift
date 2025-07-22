import XCTest
@testable import MidiGen

final class NoteSequenceGeneratorTests: XCTestCase {

    func testGenerateTritoneAscending() {
        let sequence = NoteSequenceGenerator.generate(
            rootNote: 60,
            scalePattern: .tritone,
            numberOfNotes: 4,
            direction: .ascending
        )
        XCTAssertEqual(sequence, [60, 66, 72, 78])
    }

    func testGenerateAugmentedDescending() {
        let sequence = NoteSequenceGenerator.generate(
            rootNote: 72,
            scalePattern: .augmented,
            numberOfNotes: 5,
            direction: .descending
        )
        XCTAssertEqual(sequence, [72, 68, 64, 60, 56])
    }

    func testGenerateDiminished7Ascending() {
        let sequence = NoteSequenceGenerator.generate(
            rootNote: 60,
            scalePattern: .diminished7,
            numberOfNotes: 5,
            direction: .ascending
        )
        XCTAssertEqual(sequence, [60, 63, 66, 69, 72])
    }

    func testGenerateEmptySequence() {
        let sequence = NoteSequenceGenerator.generate(
            rootNote: 60,
            scalePattern: .tritone,
            numberOfNotes: 0,
            direction: .ascending
        )
        XCTAssertEqual(sequence, [])
    }

    func testClampingAtTop() {
        let sequence = NoteSequenceGenerator.generate(
            rootNote: 125,
            scalePattern: .tritone,
            numberOfNotes: 3,
            direction: .ascending
        )
        XCTAssertEqual(sequence, [125, 127, 127])
    }

    func testClampingAtBottom() {
        let sequence = NoteSequenceGenerator.generate(
            rootNote: 2,
            scalePattern: .augmented,
            numberOfNotes: 3,
            direction: .descending
        )
        XCTAssertEqual(sequence, [2, 0, 0])
    }
}
