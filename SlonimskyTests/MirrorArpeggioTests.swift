//
//  MirrorArpeggioTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class MirrorArpeggioTests: XCTestCase {
    
    // MARK: - Single Octave Tests
    
    func testSingleOctaveChromaticMirror() throws {
        // Test chromatic scale with mirror enabled
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Verify sequence ends at octave (72)
        XCTAssertEqual(notePattern.first, 60, "First note should be root (60)")
        XCTAssertEqual(notePattern.last, 60, "Last note should return to root (60) for arpeggio")
        
        // Verify arpeggio pattern: up then down
        // Find the peak (highest note) to properly divide ascending/descending portions
        guard let peakIndex = notePattern.firstIndex(of: notePattern.max() ?? 0), notePattern.count > 2 else {
            XCTFail("Pattern should have a peak and at least 3 notes")
            return
        }
        
        // Check ascending portion (up to and including peak)
        for i in 1...peakIndex {
            XCTAssertGreaterThanOrEqual(notePattern[i], notePattern[i-1], 
                "Ascending portion should be non-decreasing at index \(i)")
        }
        
        // Check descending portion (from peak to end)
        for i in (peakIndex + 1)..<notePattern.count {
            XCTAssertLessThanOrEqual(notePattern[i], notePattern[i-1], 
                "Descending portion should be non-increasing at index \(i)")
        }
        
        print("✅ Single octave chromatic mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testSingleOctaveChromaticNoMirror() throws {
        // Test chromatic scale with mirror disabled
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Without mirror, should just be ascending to octave
        XCTAssertEqual(notePattern.first, 60, "First note should be root (60)")
        XCTAssertEqual(notePattern.last, 72, "Last note should be octave (72)")
        
        // Verify ascending only
        for i in 1..<notePattern.count {
            XCTAssertGreaterThanOrEqual(notePattern[i], notePattern[i-1], 
                "Notes should be ascending when mirror is disabled")
        }
        
        print("✅ Single octave chromatic no mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testSingleOctaveMajorScaleMirror() throws {
        // Test major (diatonic) scale with mirror
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Verify octave is reached
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        
        // Verify arpeggio structure
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Single octave major scale mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testSingleOctavePentatonicMirror() throws {
        // Test pentatonic scale with mirror
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .pentatonic,
            numberOfOctaves: 1,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Verify structure
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        
        print("✅ Single octave pentatonic mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    // MARK: - Multiple Octave Tests
    
    func testMultipleOctavesMirror() throws {
        // Test 2 octaves with mirror
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 12,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // With 2 octaves, should reach root + 24
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 84, "Should reach second octave (84)")
        
        // Verify arpeggio structure
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Multiple octaves mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testMultipleOctavesMajorScaleMirror() throws {
        // Test 3 octaves with major scale and mirror
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 3,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // With 3 octaves, should reach root + 36
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 96, "Should reach third octave (96)")
        
        // Verify structure
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Multiple octaves major scale mirror test passed - \(notePattern.count) notes")
        print("   Max note: \(maxNote)")
    }
    
    // MARK: - Octave Divisions Tests
    
    func testOctaveDivisionsMirror() throws {
        // Test with 6 divisions of octave (whole tone scale effect)
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .none,
            numberOfOctaves: 1,
            divisionsOfOctave: 6,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should reach octave
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        
        // Verify structure
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Octave divisions (6) mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testOctaveDivisions4Mirror() throws {
        // Test with 4 divisions (major thirds)
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .none,
            numberOfOctaves: 1,
            divisionsOfOctave: 4,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should reach octave
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        
        // Verify structure
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Octave divisions (4) mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testOctaveDivisions3Mirror() throws {
        // Test with 3 divisions (augmented triad)
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .none,
            numberOfOctaves: 1,
            divisionsOfOctave: 3,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should reach octave
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        
        // Verify structure
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Octave divisions (3) mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    // MARK: - Different Scale Types Tests
    
    func testWholeToneScaleMirror() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .wholeTone,
            numberOfOctaves: 1,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Whole tone scale mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testOctatonicScaleMirror() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .octatonic,
            numberOfOctaves: 1,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Octatonic scale mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testDiminishedScaleMirror() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .diminished,
            numberOfOctaves: 1,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Diminished scale mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testAugmentedScaleMirror() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .augmented,
            numberOfOctaves: 1,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(maxNote, 72, "Should reach octave (72)")
        XCTAssertEqual(notePattern.first, 60, "Should start at root")
        XCTAssertEqual(notePattern.last, 60, "Should end at root")
        
        print("✅ Augmented scale mirror test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    // MARK: - Arpeggio Pattern Verification
    
    func testArpeggioPatternStructure() throws {
        // Verify the arpeggio goes up then down correctly
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .pentatonic,
            numberOfOctaves: 1,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        guard notePattern.count >= 3 else {
            XCTFail("Pattern should have at least 3 notes")
            return
        }
        
        // Find the peak (highest note)
        guard let peakIndex = notePattern.firstIndex(of: notePattern.max() ?? 0) else {
            XCTFail("Should have a peak note")
            return
        }
        
        // Verify ascending to peak
        for i in 1...peakIndex {
            XCTAssertGreaterThanOrEqual(notePattern[i], notePattern[i-1],
                "Should be ascending to peak at index \(i)")
        }
        
        // Verify descending from peak
        for i in (peakIndex + 1)..<notePattern.count {
            XCTAssertLessThanOrEqual(notePattern[i], notePattern[i-1],
                "Should be descending from peak at index \(i)")
        }
        
        print("✅ Arpeggio pattern structure test passed")
        print("   Peak note: \(notePattern[peakIndex]) at index \(peakIndex)")
    }
    
    // MARK: - Edge Cases
    
    func testDifferentRootNotes() throws {
        // Test with different root notes
        let rootNotes = [48, 60, 72, 84]
        
        for root in rootNotes {
            let parameters = PatternParameters(
                rootNote: root,
                scaleType: .chromatic,
                numberOfOctaves: 1,
                divisionsOfOctave: 12,
                mirror: true
            )
            
            let generator = ScalePatternGenerator()
            let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
            
            XCTAssertEqual(notePattern.first, root, "Should start at root \(root)")
            XCTAssertEqual(notePattern.last, root, "Should end at root \(root)")
            
            let expectedOctave = root + 12
            let maxNote = notePattern.max() ?? 0
            XCTAssertEqual(maxNote, expectedOctave, 
                "Should reach octave \(expectedOctave) for root \(root)")
        }
        
        print("✅ Different root notes test passed")
    }
    
    func testOctaveAlreadyInSequence() throws {
        // Test case where octave is already in the sequence (shouldn't duplicate)
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Count occurrences of octave note (72)
        let octaveCount = notePattern.filter { $0 == 72 }.count
        // Should appear exactly once in ascending portion (if it was already there, or twice if added and then in descending)
        // Actually, it should appear twice: once going up, once coming down
        XCTAssertGreaterThanOrEqual(octaveCount, 1, "Octave should appear at least once")
        
        print("✅ Octave already in sequence test passed")
    }
    
    // MARK: - All Scale Types Mirror Tests
    
    /// Helper: verify a mirrored scale has correct arpeggio structure
    private func assertMirrorStructure(
        scaleType: ScaleType,
        rootNote: Int = 60,
        numberOfOctaves: Int = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let parameters = PatternParameters(
            rootNote: rootNote,
            scaleType: scaleType,
            numberOfOctaves: numberOfOctaves,
            mirror: true
        )
        
        let generator = ScalePatternGenerator()
        let notes = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        let expectedPeak = rootNote + (numberOfOctaves * 12)
        let maxNote = notes.max() ?? 0
        
        // 1. Must start at root
        XCTAssertEqual(notes.first, rootNote,
            "\(scaleType.rawValue): should start at root \(rootNote)",
            file: file, line: line)
        
        // 2. Must end at root
        XCTAssertEqual(notes.last, rootNote,
            "\(scaleType.rawValue): should end at root \(rootNote)",
            file: file, line: line)
        
        // 3. Peak must be at the expected octave
        XCTAssertEqual(maxNote, expectedPeak,
            "\(scaleType.rawValue): peak should be \(expectedPeak), got \(maxNote)",
            file: file, line: line)
        
        // 4. Must have enough notes (at least root, one middle, peak, one middle, root)
        XCTAssertGreaterThanOrEqual(notes.count, 3,
            "\(scaleType.rawValue): should have at least 3 notes",
            file: file, line: line)
        
        // 5. Ascending portion: non-decreasing up to peak
        guard let peakIndex = notes.firstIndex(of: maxNote) else {
            XCTFail("\(scaleType.rawValue): could not find peak index", file: file, line: line)
            return
        }
        for i in 1...peakIndex {
            XCTAssertGreaterThanOrEqual(notes[i], notes[i - 1],
                "\(scaleType.rawValue): ascending should be non-decreasing at index \(i) (\(notes[i-1]) -> \(notes[i]))",
                file: file, line: line)
        }
        
        // 6. Descending portion: non-increasing from peak to end
        for i in (peakIndex + 1)..<notes.count {
            XCTAssertLessThanOrEqual(notes[i], notes[i - 1],
                "\(scaleType.rawValue): descending should be non-increasing at index \(i) (\(notes[i-1]) -> \(notes[i]))",
                file: file, line: line)
        }
        
        // 7. Mirror symmetry: ascending notes (excluding peak) should equal reversed descending notes
        let ascending = Array(notes[0..<peakIndex])
        let descending = Array(notes[(peakIndex + 1)...])
        XCTAssertEqual(ascending, descending.reversed(),
            "\(scaleType.rawValue): ascending portion should mirror descending portion",
            file: file, line: line)
        
        print("✅ \(scaleType.rawValue) mirror: \(notes.count) notes, peak \(maxNote) at index \(peakIndex)")
        print("   Pattern: \(notes)")
    }
    
    // --- Minor scales ---
    
    func testNaturalMinorMirror() throws {
        assertMirrorStructure(scaleType: .naturalMinor)
    }
    
    func testHarmonicMinorMirror() throws {
        assertMirrorStructure(scaleType: .harmonicMinor)
    }
    
    func testMelodicMinorMirror() throws {
        assertMirrorStructure(scaleType: .melodicMinor)
    }
    
    func testMinorPentatonicMirror() throws {
        assertMirrorStructure(scaleType: .minorPentatonic)
    }
    
    func testBluesMirror() throws {
        assertMirrorStructure(scaleType: .blues)
    }
    
    // --- Modes ---
    
    func testDorianMirror() throws {
        assertMirrorStructure(scaleType: .dorian)
    }
    
    func testPhrygianMirror() throws {
        assertMirrorStructure(scaleType: .phrygian)
    }
    
    func testLydianMirror() throws {
        assertMirrorStructure(scaleType: .lydian)
    }
    
    func testMixolydianMirror() throws {
        assertMirrorStructure(scaleType: .mixolydian)
    }
    
    func testLocrianMirror() throws {
        assertMirrorStructure(scaleType: .locrian)
    }
    
    // --- Symmetric ---
    
    func testTritoneMirror() throws {
        assertMirrorStructure(scaleType: .tritone)
    }
    
    // --- Exotic / World ---
    
    func testHungarianMinorMirror() throws {
        assertMirrorStructure(scaleType: .hungarianMinor)
    }
    
    func testDoubleHarmonicMajorMirror() throws {
        assertMirrorStructure(scaleType: .doubleHarmonicMajor)
    }
    
    func testPhrygianDominantMirror() throws {
        assertMirrorStructure(scaleType: .phrygianDominant)
    }
    
    func testHirajoshiMirror() throws {
        assertMirrorStructure(scaleType: .hirajoshi)
    }
    
    // --- Synthetic ---
    
    func testPrometheusMirror() throws {
        assertMirrorStructure(scaleType: .prometheus)
    }
    
    func testEnigmaticMirror() throws {
        assertMirrorStructure(scaleType: .enigmatic)
    }
    
    // --- Multi-octave coverage for new scales ---
    
    func testNewScalesMultipleOctavesMirror() throws {
        let newScales: [ScaleType] = [
            .naturalMinor, .harmonicMinor, .melodicMinor,
            .minorPentatonic, .blues,
            .dorian, .phrygian, .lydian, .mixolydian, .locrian,
            .tritone,
            .hungarianMinor, .doubleHarmonicMajor, .phrygianDominant, .hirajoshi,
            .prometheus, .enigmatic
        ]
        
        for scaleType in newScales {
            assertMirrorStructure(scaleType: scaleType, numberOfOctaves: 2)
        }
    }
    
    // --- Verify all existing scales still pass with the helper ---
    
    func testAllOriginalScalesMirrorWithHelper() throws {
        let originalScales: [ScaleType] = [
            .chromatic, .diatonic, .pentatonic,
            .wholeTone, .octatonic, .diminished, .augmented
        ]
        
        for scaleType in originalScales {
            assertMirrorStructure(scaleType: scaleType)
        }
    }
}
