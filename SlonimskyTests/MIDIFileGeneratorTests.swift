
import XCTest
@testable import Slonimsky

final class MIDIFileGeneratorTests: XCTestCase {
    
    func testMIDITrackCreation() throws {
        let midiInfos = [
            MIDIInfo(note: 60, velocity: 80, beatLength: 1.0),
            MIDIInfo(note: 62, velocity: 75, beatLength: 0.5),
            MIDIInfo(note: 64, velocity: 85, beatLength: 1.0)
        ]
        
        let track = MIDITrack(notes: midiInfos)
        
        XCTAssertEqual(track.notes.count, 3, "Track should have 3 notes")
        XCTAssertEqual(track.notes[0].note, 60, "First note should be C4")
        XCTAssertEqual(track.notes[1].note, 62, "Second note should be D4")
        XCTAssertEqual(track.notes[2].note, 64, "Third note should be E4")
    }
    
    func testMIDIInfoEquality() throws {
        let midiInfo1 = MIDIInfo(note: 60, velocity: 80, beatLength: 1.0)
        let midiInfo2 = MIDIInfo(note: 60, velocity: 80, beatLength: 1.0)
        let midiInfo3 = MIDIInfo(note: 62, velocity: 80, beatLength: 1.0)
        
        XCTAssertEqual(midiInfo1, midiInfo2, "Identical MIDIInfo objects should be equal")
        XCTAssertNotEqual(midiInfo1, midiInfo3, "Different MIDIInfo objects should not be equal")
    }
    
    func testMIDITimeSignature() throws {
        let timeSignature = MIDITimeSignature(numerator: 3, denominator: 4)
        
        XCTAssertEqual(timeSignature.numerator, 3, "Numerator should be 3")
        XCTAssertEqual(timeSignature.denominator, 4, "Denominator should be 4")
        XCTAssertEqual(timeSignature.beatsPerMeasure, 3.0, "Beats per measure should be 3.0")
    }
    
    func testDefaultTimeSignature() throws {
        let defaultSignature = MIDITimeSignature.defaultSignature
        
        XCTAssertEqual(defaultSignature.numerator, 4, "Default numerator should be 4")
        XCTAssertEqual(defaultSignature.denominator, 4, "Default denominator should be 4")
        XCTAssertEqual(defaultSignature.beatsPerMeasure, 4.0, "Default beats per measure should be 4.0")
    }
    
    func testNoteDurationBeatValues() throws {
        let timeSignature = MIDITimeSignature(numerator: 4, denominator: 4)
        
        XCTAssertEqual(NoteDuration.whole.beatValue(in: timeSignature), 4.0, "Whole note should be 4 beats")
        XCTAssertEqual(NoteDuration.half.beatValue(in: timeSignature), 2.0, "Half note should be 2 beats")
        XCTAssertEqual(NoteDuration.quarter.beatValue(in: timeSignature), 1.0, "Quarter note should be 1 beat")
        XCTAssertEqual(NoteDuration.eighth.beatValue(in: timeSignature), 0.5, "Eighth note should be 0.5 beats")
        XCTAssertEqual(NoteDuration.sixteenth.beatValue(in: timeSignature), 0.25, "Sixteenth note should be 0.25 beats")
    }
    
    func testNoteDurationDefaultTimeSignature() throws {
        XCTAssertEqual(NoteDuration.whole.beatValue(), 4.0, "Whole note should be 4 beats in default time signature")
        XCTAssertEqual(NoteDuration.quarter.beatValue(), 1.0, "Quarter note should be 1 beat in default time signature")
    }
    
    func testMIDIInfoVelocityRange() throws {
        // Test valid velocity values
        let midiInfo1 = MIDIInfo(note: 60, velocity: 1, beatLength: 1.0)
        let midiInfo2 = MIDIInfo(note: 60, velocity: 127, beatLength: 1.0)
        let midiInfo3 = MIDIInfo(note: 60, velocity: 64, beatLength: 1.0)
        
        XCTAssertEqual(midiInfo1.velocity, 1, "Minimum velocity should be 1")
        XCTAssertEqual(midiInfo2.velocity, 127, "Maximum velocity should be 127")
        XCTAssertEqual(midiInfo3.velocity, 64, "Middle velocity should be 64")
    }
    
    func testMIDIInfoNoteRange() throws {
        // Test valid note values
        let midiInfo1 = MIDIInfo(note: 0, velocity: 80, beatLength: 1.0)
        let midiInfo2 = MIDIInfo(note: 127, velocity: 80, beatLength: 1.0)
        let midiInfo3 = MIDIInfo(note: 60, velocity: 80, beatLength: 1.0) // Middle C
        
        XCTAssertEqual(midiInfo1.note, 0, "Minimum note should be 0")
        XCTAssertEqual(midiInfo2.note, 127, "Maximum note should be 127")
        XCTAssertEqual(midiInfo3.note, 60, "Middle C should be 60")
    }
    
    func testMIDIInfoBeatLength() throws {
        let midiInfo1 = MIDIInfo(note: 60, velocity: 80, beatLength: 0.25)
        let midiInfo2 = MIDIInfo(note: 60, velocity: 80, beatLength: 1.0)
        let midiInfo3 = MIDIInfo(note: 60, velocity: 80, beatLength: 4.0)
        
        XCTAssertEqual(midiInfo1.beatLength, 0.25, "Short beat length should be 0.25")
        XCTAssertEqual(midiInfo2.beatLength, 1.0, "Standard beat length should be 1.0")
        XCTAssertEqual(midiInfo3.beatLength, 4.0, "Long beat length should be 4.0")
    }
    
    func testMIDITrackEmptyNotes() throws {
        let track = MIDITrack(notes: [])
        
        XCTAssertTrue(track.notes.isEmpty, "Empty track should have no notes")
    }
    
    func testMIDITrackSingleNote() throws {
        let midiInfo = MIDIInfo(note: 60, velocity: 80, beatLength: 1.0)
        let track = MIDITrack(notes: [midiInfo])
        
        XCTAssertEqual(track.notes.count, 1, "Track should have 1 note")
        XCTAssertEqual(track.notes[0], midiInfo, "Track should contain the same MIDIInfo")
    }
}
