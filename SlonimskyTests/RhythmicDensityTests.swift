//
//  RhythmicDensityTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class RhythmicDensityTests: XCTestCase {
    
    var generator: ScalePatternGenerator!
    
    override func setUp() {
        super.setUp()
        generator = ScalePatternGenerator()
    }
    
    override func tearDown() {
        generator = nil
        super.tearDown()
    }
    
    // MARK: - Basic Density Effect Tests
    
    func testDensityOneHasNoEffect() throws {
        // Test that density = 1.0 has no effect on note durations
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 0.25, // Quarter note (0.25 beats in new system)
            rhythmicDensity: 1.0
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        // With density = 1.0, durations should equal base duration (after pattern effects)
        // Since we're using uniform pattern, durations should be baseDuration / density = 0.25 / 1.0 = 0.25
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // All notes should have duration close to base duration (0.25) when density = 1.0
        for note in result {
            XCTAssertEqual(note.beatLength, 0.25, accuracy: 0.001, 
                          "With density=1.0, note duration should equal base duration (0.25)")
        }
        
        print("✅ Density 1.0 test passed - all durations = 0.25")
    }
    
    func testDensityTwoHalvesDurations() throws {
        // Test that density = 2.0 halves note durations
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 0.25, // Quarter note
            rhythmicDensity: 2.0
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // With density = 2.0, durations should be baseDuration / 2.0 = 0.25 / 2.0 = 0.125
        for note in result {
            XCTAssertEqual(note.beatLength, 0.125, accuracy: 0.001,
                          "With density=2.0, note duration should be halved (0.125)")
        }
        
        print("✅ Density 2.0 test passed - all durations = 0.125 (halved)")
    }
    
    func testDensityHalfDoublesDurations() throws {
        // Test that density = 0.5 doubles note durations
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 0.25, // Quarter note
            rhythmicDensity: 0.5
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // With density = 0.5, durations should be baseDuration / 0.5 = 0.25 / 0.5 = 0.5
        for note in result {
            XCTAssertEqual(note.beatLength, 0.5, accuracy: 0.001,
                          "With density=0.5, note duration should be doubled (0.5)")
        }
        
        print("✅ Density 0.5 test passed - all durations = 0.5 (doubled)")
    }
    
    func testDensityComparison() throws {
        // Compare different density values to verify they produce different durations
        let baseDuration: Double = 0.25
        
        let params1 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: baseDuration,
            rhythmicDensity: 0.5
        )
        
        let params2 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: baseDuration,
            rhythmicDensity: 1.0
        )
        
        let params3 = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: baseDuration,
            rhythmicDensity: 2.0
        )
        
        let result1 = generator.generatePattern(parameters: params1, cycleIndex: 0)
        let result2 = generator.generatePattern(parameters: params2, cycleIndex: 0)
        let result3 = generator.generatePattern(parameters: params3, cycleIndex: 0)
        
        XCTAssertGreaterThan(result1.count, 0, "Result 1 should have notes")
        XCTAssertGreaterThan(result2.count, 0, "Result 2 should have notes")
        XCTAssertGreaterThan(result3.count, 0, "Result 3 should have notes")
        
        // Get average durations
        let avg1 = result1.map { $0.beatLength }.reduce(0, +) / Double(result1.count)
        let avg2 = result2.map { $0.beatLength }.reduce(0, +) / Double(result2.count)
        let avg3 = result3.map { $0.beatLength }.reduce(0, +) / Double(result3.count)
        
        // Density 0.5 should produce longest durations
        XCTAssertGreaterThan(avg1, avg2, "Density 0.5 should produce longer durations than 1.0")
        XCTAssertGreaterThan(avg2, avg3, "Density 1.0 should produce longer durations than 2.0")
        
        // Verify expected ratios
        XCTAssertEqual(avg1, baseDuration / 0.5, accuracy: 0.01, "Density 0.5 should double duration")
        XCTAssertEqual(avg2, baseDuration / 1.0, accuracy: 0.01, "Density 1.0 should keep duration")
        XCTAssertEqual(avg3, baseDuration / 2.0, accuracy: 0.01, "Density 2.0 should halve duration")
        
        print("✅ Density comparison test passed")
        print("   Density 0.5: avg duration = \(avg1)")
        print("   Density 1.0: avg duration = \(avg2)")
        print("   Density 2.0: avg duration = \(avg3)")
    }
    
    // MARK: - Minimum Duration Tests
    
    func testDensityRespectsMinimumDuration() throws {
        // Test that very high density doesn't go below minimum duration (0.0625)
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 0.25,
            rhythmicDensity: 10.0 // Very high density
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // All durations should be at least the minimum (0.0625)
        for note in result {
            XCTAssertGreaterThanOrEqual(note.beatLength, 0.0625,
                                       "Note duration should not go below minimum (0.0625)")
        }
        
        print("✅ Minimum duration test passed - all durations >= 0.0625")
    }
    
    // MARK: - Density with Different Base Durations
    
    func testDensityWithWholeNote() throws {
        // Test density with whole note base duration (1.0 beat)
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 1.0, // Whole note
            rhythmicDensity: 2.0
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // With baseDuration = 1.0 and density = 2.0, durations should be 1.0 / 2.0 = 0.5
        for note in result {
            XCTAssertEqual(note.beatLength, 0.5, accuracy: 0.001,
                          "Whole note with density 2.0 should produce 0.5 beat durations")
        }
        
        print("✅ Whole note density test passed - all durations = 0.5")
    }
    
    func testDensityWithEighthNote() throws {
        // Test density with eighth note base duration (0.125 beat)
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 0.125, // Eighth note
            rhythmicDensity: 2.0
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // With baseDuration = 0.125 and density = 2.0, durations should be 0.125 / 2.0 = 0.0625
        for note in result {
            XCTAssertEqual(note.beatLength, 0.0625, accuracy: 0.001,
                          "Eighth note with density 2.0 should produce 0.0625 beat durations")
        }
        
        print("✅ Eighth note density test passed - all durations = 0.0625")
    }
    
    // MARK: - Density with Duration Patterns
    
    func testDensityWithUniformPattern() throws {
        // Test density with uniform duration pattern
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            noteDurationPattern: .uniform,
            baseNoteDuration: 0.25,
            rhythmicDensity: 2.0
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // All notes should have the same duration (baseDuration / density)
        let firstDuration = result.first?.beatLength ?? 0
        for note in result {
            XCTAssertEqual(note.beatLength, firstDuration, accuracy: 0.001,
                          "Uniform pattern with density should produce uniform durations")
        }
        
        XCTAssertEqual(firstDuration, 0.125, accuracy: 0.001,
                       "Uniform pattern: baseDuration 0.25 / density 2.0 = 0.125")
        
        print("✅ Uniform pattern density test passed")
    }
    
    func testDensityWithAlternatingPattern() throws {
        // Test density with alternating duration pattern
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            noteDurationPattern: .alternating,
            baseNoteDuration: 0.25,
            rhythmicDensity: 2.0
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // Alternating pattern: even indices get baseDuration, odd indices get baseDuration * 0.7
        // Then density is applied: duration /= density
        // So even: 0.25 / 2.0 = 0.125, odd: (0.25 * 0.7) / 2.0 = 0.0875
        if result.count >= 2 {
            let evenDuration = result[0].beatLength
            let oddDuration = result[1].beatLength
            
            XCTAssertEqual(evenDuration, 0.125, accuracy: 0.001,
                          "Even index with alternating pattern and density 2.0")
            XCTAssertEqual(oddDuration, 0.0875, accuracy: 0.001,
                          "Odd index with alternating pattern and density 2.0")
        }
        
        print("✅ Alternating pattern density test passed")
    }
    
    // MARK: - Density Applied Uniformly
    
    func testDensityAppliedUniformlyToAllNotes() throws {
        // Test that density affects all notes uniformly
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 0.25,
            rhythmicDensity: 1.5
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // All notes should have duration = baseDuration / density = 0.25 / 1.5 ≈ 0.1667
        let expectedDuration = 0.25 / 1.5
        
        for (index, note) in result.enumerated() {
            XCTAssertEqual(note.beatLength, expectedDuration, accuracy: 0.001,
                          "Note at index \(index) should have uniform density application")
        }
        
        print("✅ Uniform density application test passed - all \(result.count) notes have duration \(expectedDuration)")
    }
    
    // MARK: - Edge Cases
    
    func testDensityMinimumValue() throws {
        // Test with minimum valid density (0.1)
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 0.25,
            rhythmicDensity: 0.1
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // With density = 0.1, durations should be baseDuration / 0.1 = 0.25 / 0.1 = 2.5
        for note in result {
            XCTAssertEqual(note.beatLength, 2.5, accuracy: 0.001,
                          "Minimum density 0.1 should produce 2.5 beat durations")
        }
        
        print("✅ Minimum density (0.1) test passed - all durations = 2.5")
    }
    
    func testDensityMaximumValue() throws {
        // Test with maximum valid density (2.0)
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            mirror: false,
            baseNoteDuration: 0.25,
            rhythmicDensity: 2.0
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // With density = 2.0, durations should be baseDuration / 2.0 = 0.25 / 2.0 = 0.125
        for note in result {
            XCTAssertEqual(note.beatLength, 0.125, accuracy: 0.001,
                          "Maximum density 2.0 should produce 0.125 beat durations")
        }
        
        print("✅ Maximum density (2.0) test passed - all durations = 0.125")
    }
    
    // MARK: - Density with Multiple Octaves
    
    func testDensityWithMultipleOctaves() throws {
        // Test that density works consistently across multiple octaves
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 12,
            mirror: false, baseNoteDuration: 0.25,
            rhythmicDensity: 2.0
        )
        
        let result = generator.generatePattern(parameters: baseParams, cycleIndex: 0)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        
        // All notes across all octaves should have the same duration
        let expectedDuration = 0.25 / 2.0 // 0.125
        
        for note in result {
            XCTAssertEqual(note.beatLength, expectedDuration, accuracy: 0.001,
                          "All notes across multiple octaves should have uniform density")
        }
        
        print("✅ Multiple octaves density test passed - \(result.count) notes all have duration \(expectedDuration)")
    }
    
    // MARK: - Density Calculation Formula Verification
    
    func testDensityCalculationFormula() throws {
        // Verify the exact formula: duration = baseDuration / density
        let testCases: [(baseDuration: Double, density: Double, expected: Double)] = [
            (0.25, 1.0, 0.25),      // No change
            (0.25, 2.0, 0.125),     // Halved
            (0.25, 0.5, 0.5),       // Doubled
            (0.25, 1.5, 0.25 / 1.5), // 1.5x faster
            (1.0, 2.0, 0.5),        // Whole note halved
            (0.125, 2.0, 0.0625),   // Eighth note halved
        ]
        
        for testCase in testCases {
            let params = PatternParameters(
                rootNote: 60,
                scaleType: .chromatic,
                numberOfOctaves: 1,
                divisionsOfOctave: 12,
                mirror: false,
                baseNoteDuration: testCase.baseDuration,
                rhythmicDensity: testCase.density
            )
            
            let result = generator.generatePattern(parameters: params, cycleIndex: 0)
            
            XCTAssertGreaterThan(result.count, 0, "Should generate notes for baseDuration=\(testCase.baseDuration), density=\(testCase.density)")
            
            // Check first note (should be representative for uniform pattern)
            if let firstNote = result.first {
                XCTAssertEqual(firstNote.beatLength, testCase.expected, accuracy: 0.001,
                              "Formula verification: baseDuration=\(testCase.baseDuration), density=\(testCase.density) should produce \(testCase.expected)")
            }
        }
        
        print("✅ Density calculation formula verification passed for all test cases")
    }
}
