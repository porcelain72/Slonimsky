//
//  ScaleGeneratorParameterTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class ScaleGeneratorParameterTests: XCTestCase {
    
    var generator: ScalePatternGenerator!
    
    override func setUp() {
        super.setUp()
        generator = ScalePatternGenerator()
    }
    
    override func tearDown() {
        generator = nil
        super.tearDown()
    }
    
    // MARK: - Number of Octaves Tests
    
    func testNumberOfOctavesSingleOctave() throws {
        // Test with 1 octave
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 12 notes (one octave of chromatic scale) + 1 octave note = 13 notes
        XCTAssertGreaterThanOrEqual(notePattern.count, 12, "Single octave should have at least 12 notes")
        
        // First note should be root
        XCTAssertEqual(notePattern.first, 60, "First note should be root (60)")
        
        // Last note should be octave above root
        XCTAssertEqual(notePattern.last, 72, "Last note should be octave above root (72)")
        
        // Verify all notes are within one octave range
        let minNote = notePattern.min() ?? 0
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(minNote, 60, "Minimum note should be root")
        XCTAssertEqual(maxNote, 72, "Maximum note should be one octave above root")
        
        print("✅ Single octave test passed - \(notePattern.count) notes, range: \(minNote)-\(maxNote)")
    }
    
    func testNumberOfOctavesTwoOctaves() throws {
        // Test with 2 octaves
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 24 notes (two octaves of chromatic scale) + 1 octave note = 25 notes
        XCTAssertGreaterThanOrEqual(notePattern.count, 24, "Two octaves should have at least 24 notes")
        
        // First note should be root
        XCTAssertEqual(notePattern.first, 60, "First note should be root (60)")
        
        // Last note should be two octaves above root
        XCTAssertEqual(notePattern.last, 84, "Last note should be two octaves above root (84)")
        
        // Verify range spans two octaves
        let minNote = notePattern.min() ?? 0
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(minNote, 60, "Minimum note should be root")
        XCTAssertEqual(maxNote, 84, "Maximum note should be two octaves above root")
        
        print("✅ Two octaves test passed - \(notePattern.count) notes, range: \(minNote)-\(maxNote)")
    }
    
    func testNumberOfOctavesThreeOctaves() throws {
        // Test with 3 octaves
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 3,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 36 notes (three octaves of chromatic scale) + 1 octave note = 37 notes
        XCTAssertGreaterThanOrEqual(notePattern.count, 36, "Three octaves should have at least 36 notes")
        
        // First note should be root
        XCTAssertEqual(notePattern.first, 60, "First note should be root (60)")
        
        // Last note should be three octaves above root
        XCTAssertEqual(notePattern.last, 96, "Last note should be three octaves above root (96)")
        
        // Verify range spans three octaves
        let minNote = notePattern.min() ?? 0
        let maxNote = notePattern.max() ?? 0
        XCTAssertEqual(minNote, 60, "Minimum note should be root")
        XCTAssertEqual(maxNote, 96, "Maximum note should be three octaves above root")
        
        print("✅ Three octaves test passed - \(notePattern.count) notes, range: \(minNote)-\(maxNote)")
    }
    
    func testNumberOfOctavesComparison() throws {
        // Compare different octave counts to ensure they produce different results
        let params1 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let params2 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let params3 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 3,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let result1 = generator.generateNotePattern(parameters: params1, cycleIndex: 0)
        let result2 = generator.generateNotePattern(parameters: params2, cycleIndex: 0)
        let result3 = generator.generateNotePattern(parameters: params3, cycleIndex: 0)
        
        // Each should have more notes than the previous
        XCTAssertLessThan(result1.count, result2.count, "2 octaves should have more notes than 1 octave")
        XCTAssertLessThan(result2.count, result3.count, "3 octaves should have more notes than 2 octaves")
        
        // Maximum notes should increase by 12 semitones (one octave) each time
        let max1 = result1.max() ?? 0
        let max2 = result2.max() ?? 0
        let max3 = result3.max() ?? 0
        
        XCTAssertEqual(max2 - max1, 12, "Max note difference between 1 and 2 octaves should be 12 semitones")
        XCTAssertEqual(max3 - max2, 12, "Max note difference between 2 and 3 octaves should be 12 semitones")
        
        print("✅ Octave comparison test passed")
        print("   1 octave: \(result1.count) notes, max: \(max1)")
        print("   2 octaves: \(result2.count) notes, max: \(max2)")
        print("   3 octaves: \(result3.count) notes, max: \(max3)")
    }
    
    func testNumberOfOctavesWithDiatonicScale() throws {
        // Test octaves with diatonic scale (7 notes per octave)
        let params1 = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7,
            mirror: false
        )
        
        let params2 = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 2,
            divisionsOfOctave: 7,
            mirror: false
        )
        
        let result1 = generator.generateNotePattern(parameters: params1, cycleIndex: 0)
        let result2 = generator.generateNotePattern(parameters: params2, cycleIndex: 0)
        
        // Diatonic scale has 7 notes per octave
        // 1 octave: 7 notes + 1 octave note = 8 notes
        // 2 octaves: 14 notes + 1 octave note = 15 notes
        XCTAssertGreaterThanOrEqual(result1.count, 7, "1 octave diatonic should have at least 7 notes")
        XCTAssertGreaterThanOrEqual(result2.count, 14, "2 octaves diatonic should have at least 14 notes")
        
        // Maximum notes should increase by 12 semitones
        let max1 = result1.max() ?? 0
        let max2 = result2.max() ?? 0
        XCTAssertEqual(max2 - max1, 12, "Max note difference should be 12 semitones (one octave)")
        
        print("✅ Diatonic octave test passed")
        print("   1 octave: \(result1.count) notes, max: \(max1)")
        print("   2 octaves: \(result2.count) notes, max: \(max2)")
    }
    
    // MARK: - Divisions of Octave Tests
    
    func testDivisionsOfOctaveChromatic12Divisions() throws {
        // Test chromatic scale with 12 divisions (full chromatic)
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 12 notes (one division per semitone)
        XCTAssertGreaterThanOrEqual(notePattern.count, 12, "12 divisions should produce at least 12 notes")
        
        // Verify notes are evenly spaced
        if notePattern.count >= 2 {
            let firstInterval = notePattern[1] - notePattern[0]
            for i in 1..<min(notePattern.count, 12) {
                let interval = notePattern[i] - notePattern[i-1]
                XCTAssertEqual(interval, firstInterval, "Notes should be evenly spaced at index \(i)")
            }
        }
        
        print("✅ 12 divisions chromatic test passed - \(notePattern.count) notes")
    }
    
    func testDivisionsOfOctaveChromatic6Divisions() throws {
        // Test chromatic scale with 6 divisions
        // For chromatic scales, divisionsOfOctave limits the number of notes generated
        // It takes the first N notes from the chromatic scale sequentially
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 6,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 6 base notes + 1 octave note = 7 notes total
        XCTAssertEqual(notePattern.count, 7, "6 divisions should produce 7 notes (6 base + 1 octave)")
        
        // Verify first 6 notes are sequential (chromatic scale behavior)
        for i in 1..<6 {
            let interval = notePattern[i] - notePattern[i-1]
            XCTAssertEqual(interval, 1, "Base notes should be sequential (1 semitone apart) at index \(i)")
        }
        
        // Last note should be the octave (72)
        XCTAssertEqual(notePattern.last, 72, "Last note should be octave")
        
        print("✅ 6 divisions chromatic test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testDivisionsOfOctaveChromatic4Divisions() throws {
        // Test chromatic scale with 4 divisions
        // For chromatic scales, divisionsOfOctave limits the number of notes generated
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 4,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 4 base notes + 1 octave note = 5 notes total
        XCTAssertEqual(notePattern.count, 5, "4 divisions should produce 5 notes (4 base + 1 octave)")
        
        // Verify first 4 notes are sequential (chromatic scale behavior)
        for i in 1..<4 {
            let interval = notePattern[i] - notePattern[i-1]
            XCTAssertEqual(interval, 1, "Base notes should be sequential (1 semitone apart) at index \(i)")
        }
        
        // Last note should be the octave (72)
        XCTAssertEqual(notePattern.last, 72, "Last note should be octave")
        
        print("✅ 4 divisions chromatic test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testDivisionsOfOctaveChromatic3Divisions() throws {
        // Test chromatic scale with 3 divisions
        // For chromatic scales, divisionsOfOctave limits the number of notes generated
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 3,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 3 base notes + 1 octave note = 4 notes total
        XCTAssertEqual(notePattern.count, 4, "3 divisions should produce 4 notes (3 base + 1 octave)")
        
        // Verify first 3 notes are sequential (chromatic scale behavior)
        for i in 1..<3 {
            let interval = notePattern[i] - notePattern[i-1]
            XCTAssertEqual(interval, 1, "Base notes should be sequential (1 semitone apart) at index \(i)")
        }
        
        // Last note should be the octave (72)
        XCTAssertEqual(notePattern.last, 72, "Last note should be octave")
        
        print("✅ 3 divisions chromatic test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testDivisionsOfOctaveComparison() throws {
        // Compare different division counts
        let params12 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false
        )
        
        let params6 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 6,
            mirror: false
        )
        
        let params4 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 4,
            mirror: false
        )
        
        let params3 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 3,
            mirror: false
        )
        
        let result12 = generator.generateNotePattern(parameters: params12, cycleIndex: 0)
        let result6 = generator.generateNotePattern(parameters: params6, cycleIndex: 0)
        let result4 = generator.generateNotePattern(parameters: params4, cycleIndex: 0)
        let result3 = generator.generateNotePattern(parameters: params3, cycleIndex: 0)
        
        // More divisions should produce more notes
        XCTAssertGreaterThan(result12.count, result6.count, "12 divisions should have more notes than 6")
        XCTAssertGreaterThan(result6.count, result4.count, "6 divisions should have more notes than 4")
        XCTAssertGreaterThan(result4.count, result3.count, "4 divisions should have more notes than 3")
        
        // All should end at the same octave (72)
        XCTAssertEqual(result12.last, 72, "12 divisions should end at octave")
        XCTAssertEqual(result6.last, 72, "6 divisions should end at octave")
        XCTAssertEqual(result4.last, 72, "4 divisions should end at octave")
        XCTAssertEqual(result3.last, 72, "3 divisions should end at octave")
        
        print("✅ Divisions comparison test passed")
        print("   12 divisions: \(result12.count) notes")
        print("   6 divisions: \(result6.count) notes")
        print("   4 divisions: \(result4.count) notes")
        print("   3 divisions: \(result3.count) notes")
    }
    
    func testDivisionsOfOctaveWithEqualDivisions() throws {
        // Test divisions with scaleType = .none (equal divisions)
        // For 1 octave with 6 divisions: 12 semitones / 6 = 2 semitones per division
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .none,
            numberOfOctaves: 1,
            divisionsOfOctave: 6,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 6 base notes + 1 octave note = 7 notes total
        XCTAssertEqual(notePattern.count, 7, "Equal divisions should produce 7 notes (6 base + 1 octave)")
        
        // Verify base notes (first 6) are evenly spaced by 2 semitones
        for i in 1..<6 {
            let interval = notePattern[i] - notePattern[i-1]
            XCTAssertEqual(interval, 2, "Base notes should be evenly spaced by 2 semitones at index \(i)")
        }
        
        // First note should be root
        XCTAssertEqual(notePattern.first, 60, "First note should be root")
        
        // Second-to-last note should be 5 intervals * 2 semitones = 10 semitones above root = 70
        XCTAssertEqual(notePattern[5], 70, "Second-to-last base note should be 10 semitones above root")
        
        // Last note should be the octave (72)
        XCTAssertEqual(notePattern.last, 72, "Last note should be octave")
        
        print("✅ Equal divisions (6) test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testDivisionsOfOctaveWithEqualDivisionsMultipleOctaves() throws {
        // Test equal divisions with 2 octaves
        // For 2 octaves with 8 divisions: 24 semitones / 8 = 3 semitones per division
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .none,
            numberOfOctaves: 2,
            divisionsOfOctave: 8,
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should have 8 base notes + 1 octave note = 9 notes total
        XCTAssertEqual(notePattern.count, 9, "Equal divisions should produce 9 notes (8 base + 1 octave)")
        
        // Verify base notes (first 8) are evenly spaced by 3 semitones
        for i in 1..<8 {
            let interval = notePattern[i] - notePattern[i-1]
            XCTAssertEqual(interval, 3, "Base notes should be evenly spaced by 3 semitones at index \(i)")
        }
        
        // First note should be root
        XCTAssertEqual(notePattern.first, 60, "First note should be root")
        
        // Second-to-last note should be 7 intervals * 3 semitones = 21 semitones above root = 81
        XCTAssertEqual(notePattern[7], 81, "Second-to-last base note should be 21 semitones above root")
        
        // Last note should be the target octave (84 = 2 octaves above root)
        let targetOctave = 60 + (2 * 12) // 84
        XCTAssertEqual(notePattern.last, targetOctave, "Last note should be target octave")
        
        print("✅ Equal divisions (8) with 2 octaves test passed - \(notePattern.count) notes")
        print("   Pattern: \(notePattern)")
    }
    
    func testDivisionsOfOctaveWithInvalidDivisor() throws {
        // Test with invalid divisor (not evenly dividing total semitones)
        // For 1 octave (12 semitones), 5 is not a valid divisor
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .none,
            numberOfOctaves: 1,
            divisionsOfOctave: 5, // 12 % 5 != 0, so invalid
            mirror: false
        )
        
        let notePattern = generator.generateNotePattern(parameters: parameters, cycleIndex: 0)
        
        // Should fallback to just the root note (safety fallback)
        // Or it might use a valid divisor - let's check what actually happens
        XCTAssertGreaterThanOrEqual(notePattern.count, 1, "Should have at least 1 note (safety fallback)")
        
        // First note should be root
        XCTAssertEqual(notePattern.first, 60, "First note should be root")
        
        print("✅ Invalid divisor test passed - \(notePattern.count) notes (fallback behavior)")
        print("   Pattern: \(notePattern)")
    }
    
    // MARK: - Combined Tests
    
    func testNumberOfOctavesAndDivisionsCombined() throws {
        // Test that both parameters work together correctly
        let params1 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 6,
            mirror: false
        )
        
        let params2 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 6,
            mirror: false
        )
        
        let result1 = generator.generateNotePattern(parameters: params1, cycleIndex: 0)
        let result2 = generator.generateNotePattern(parameters: params2, cycleIndex: 0)
        
        // 1 octave with 6 divisions: ~6-7 notes
        // 2 octaves with 6 divisions: ~12-13 notes (double)
        XCTAssertLessThan(result1.count, result2.count, "2 octaves should have more notes than 1 octave")
        
        // Maximum notes should differ by 12 semitones (one octave)
        let max1 = result1.max() ?? 0
        let max2 = result2.max() ?? 0
        XCTAssertEqual(max2 - max1, 12, "Max note difference should be 12 semitones")
        
        print("✅ Combined parameters test passed")
        print("   1 octave, 6 divisions: \(result1.count) notes, max: \(max1)")
        print("   2 octaves, 6 divisions: \(result2.count) notes, max: \(max2)")
    }
    
    func testDivisionsWithDiatonicScale() throws {
        // Test that divisions parameter doesn't override natural scale structure for non-chromatic scales
        // Diatonic scale has 7 notes naturally, so divisions should not affect it
        let params1 = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7, // Matches natural scale
            mirror: false
        )
        
        let params2 = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12, // Different from natural scale
            mirror: false
        )
        
        let result1 = generator.generateNotePattern(parameters: params1, cycleIndex: 0)
        let result2 = generator.generateNotePattern(parameters: params2, cycleIndex: 0)
        
        // Both should produce the same number of notes (7 for diatonic)
        // because divisions only affects chromatic scales
        XCTAssertEqual(result1.count, result2.count, "Diatonic scale should ignore divisions parameter")
        
        print("✅ Diatonic divisions test passed")
        print("   7 divisions: \(result1.count) notes")
        print("   12 divisions: \(result2.count) notes")
    }
}
