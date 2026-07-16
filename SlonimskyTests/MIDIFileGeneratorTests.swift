
import XCTest
@testable import Slonimsky

final class MIDIFileGeneratorTests: XCTestCase {
    
    func testMIDITrackCreation() throws {
        let midiInfos = [
            MIDIInfo(note: 60, velocity: 80, duration: 1.0, cycleIndex: 0),
            MIDIInfo(note: 62, velocity: 75, duration: 0.5, cycleIndex: 0),
            MIDIInfo(note: 64, velocity: 85, duration: 1.0, cycleIndex: 0)
        ]
        
        let track = MIDITrack(notes: midiInfos)
        
        XCTAssertEqual(track.notes.count, 3, "Track should have 3 notes")
        XCTAssertEqual(track.notes[0].note, 60, "First note should be C4")
        XCTAssertEqual(track.notes[1].note, 62, "Second note should be D4")
        XCTAssertEqual(track.notes[2].note, 64, "Third note should be E4")
    }
    
    func testMIDIInfoEquality() throws {
        let midiInfo1 = MIDIInfo(note: 60, velocity: 80, duration: 1.0, cycleIndex: 0)
        let midiInfo2 = MIDIInfo(note: 60, velocity: 80, duration: 1.0, cycleIndex: 0)
        let midiInfo3 = MIDIInfo(note: 62, velocity: 80, duration: 1.0, cycleIndex: 0)
        
        XCTAssertEqual(midiInfo1, midiInfo2, "Identical MIDIInfo objects should be equal")
        XCTAssertNotEqual(midiInfo1, midiInfo3, "Different MIDIInfo objects should not be equal")
    }
    
    func testBaseNoteDurationBeatValues() throws {
        XCTAssertEqual(BaseNoteDuration.whole.beatValue, 4.0, "Whole note should be 4 beats")
        XCTAssertEqual(BaseNoteDuration.half.beatValue, 2.0, "Half note should be 2 beats")
        XCTAssertEqual(BaseNoteDuration.quarter.beatValue, 1.0, "Quarter note should be 1 beat")
        XCTAssertEqual(BaseNoteDuration.eighth.beatValue, 0.5, "Eighth note should be 0.5 beats")
        XCTAssertEqual(BaseNoteDuration.sixteenth.beatValue, 0.25, "Sixteenth note should be 0.25 beats")
    }
    
    func testMIDIInfoOnsetAndEnd() throws {
        let note = MIDIInfo(note: 60, velocity: 80, onset: 2.5, duration: 1.5, cycleIndex: 0)
        XCTAssertEqual(note.onset, 2.5, "Onset should be stored")
        XCTAssertEqual(note.end, 4.0, "End should be onset + duration")
        
        let shifted = note.offset(by: 3.5)
        XCTAssertEqual(shifted.onset, 6.0, "Offset should shift onset")
        XCTAssertEqual(shifted.duration, 1.5, "Offset should preserve duration")
    }
    
    func testMIDIInfoRest() throws {
        let rest = MIDIInfo(note: 0, velocity: 0, onset: 1.0, duration: 0.5, isRest: true, cycleIndex: 0)
        XCTAssertTrue(rest.isRest, "Rest flag should be stored")
        
        let notes = [
            MIDIInfo(note: 60, velocity: 80, onset: 0.0, duration: 1.0),
            rest,
            MIDIInfo(note: 62, velocity: 80, onset: 1.5, duration: 1.0)
        ]
        XCTAssertEqual(notes.soundingNotes.count, 2, "Rests should be excluded from sounding notes")
        XCTAssertEqual(notes.totalLength, 2.5, "Total length should be the latest event end")
    }
    
    func testSequentialOnsets() throws {
        let notes = [
            MIDIInfo(note: 60, velocity: 80, duration: 1.0),
            MIDIInfo(note: 62, velocity: 80, duration: 0.5),
            MIDIInfo(note: 64, velocity: 80, duration: 2.0)
        ].withSequentialOnsets()
        
        XCTAssertEqual(notes[0].onset, 0.0)
        XCTAssertEqual(notes[1].onset, 1.0)
        XCTAssertEqual(notes[2].onset, 1.5)
        XCTAssertEqual(notes.totalLength, 3.5)
    }
    
    func testMIDIInfoVelocityRange() throws {
        // Test valid velocity values
        let midiInfo1 = MIDIInfo(note: 60, velocity: 1, duration: 1.0, cycleIndex: 0)
        let midiInfo2 = MIDIInfo(note: 60, velocity: 127, duration: 1.0, cycleIndex: 0)
        let midiInfo3 = MIDIInfo(note: 60, velocity: 64, duration: 1.0, cycleIndex: 0)
        
        XCTAssertEqual(midiInfo1.velocity, 1, "Minimum velocity should be 1")
        XCTAssertEqual(midiInfo2.velocity, 127, "Maximum velocity should be 127")
        XCTAssertEqual(midiInfo3.velocity, 64, "Middle velocity should be 64")
    }
    
    func testMIDIInfoNoteRange() throws {
        // Test valid note values
        let midiInfo1 = MIDIInfo(note: 0, velocity: 80, duration: 1.0, cycleIndex: 0)
        let midiInfo2 = MIDIInfo(note: 127, velocity: 80, duration: 1.0, cycleIndex: 0)
        let midiInfo3 = MIDIInfo(note: 60, velocity: 80, duration: 1.0, cycleIndex: 0) // Middle C
        
        XCTAssertEqual(midiInfo1.note, 0, "Minimum note should be 0")
        XCTAssertEqual(midiInfo2.note, 127, "Maximum note should be 127")
        XCTAssertEqual(midiInfo3.note, 60, "Middle C should be 60")
    }
    
    func testMIDIInfoBeatLength() throws {
        let midiInfo1 = MIDIInfo(note: 60, velocity: 80, duration: 0.25, cycleIndex: 0)
        let midiInfo2 = MIDIInfo(note: 60, velocity: 80, duration: 1.0, cycleIndex: 0)
        let midiInfo3 = MIDIInfo(note: 60, velocity: 80, duration: 4.0, cycleIndex: 0)
        
        XCTAssertEqual(midiInfo1.duration, 0.25, "Short beat length should be 0.25")
        XCTAssertEqual(midiInfo2.duration, 1.0, "Standard beat length should be 1.0")
        XCTAssertEqual(midiInfo3.duration, 4.0, "Long beat length should be 4.0")
    }
    
    func testMIDITrackEmptyNotes() throws {
        let track = MIDITrack(notes: [])
        
        XCTAssertTrue(track.notes.isEmpty, "Empty track should have no notes")
    }
    
    func testMIDITrackSingleNote() throws {
        let midiInfo = MIDIInfo(note: 60, velocity: 80, duration: 1.0, cycleIndex: 0)
        let track = MIDITrack(notes: [midiInfo])
        
        XCTAssertEqual(track.notes.count, 1, "Track should have 1 note")
        XCTAssertEqual(track.notes[0], midiInfo, "Track should contain the same MIDIInfo")
    }
}
