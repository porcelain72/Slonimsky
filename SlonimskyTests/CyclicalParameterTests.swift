//
//  CyclicalParameterTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class CyclicalParameterTests: XCTestCase {
    
    // MARK: - Test Properties
    private var cyclicalGenerator: CyclicalSequenceGenerator!
    private var patternRegistry: PatternGeneratorRegistry!
    
    override func setUp() {
        super.setUp()
        cyclicalGenerator = CyclicalSequenceGenerator()
        patternRegistry = PatternGeneratorRegistry.shared
    }
    
    override func tearDown() {
        cyclicalGenerator = nil
        patternRegistry = nil
        super.tearDown()
    }
    
    // MARK: - Basic Cyclical Tests
    
    func testCyclicalRootNoteProgression() throws {
        // Test that cyclical root note changes create distinct patterns
        let baseParameters = createBaseParameters()
        
        // Enable cyclical root note changes: 60 -> 62 -> 64 -> 66
        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.rootNote = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 60.0,
            maxValue: 66.0,
            stepSize: 2.0,
            maxCycles: 4,
            operationType: .replace
        )
        cyclicalSettings.enabledParameters = [.rootNote]
        
        baseParameters.cyclicalSettings = cyclicalSettings
        
        // Generate cyclical sequence
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        // Verify we have notes from multiple cycles
        XCTAssertTrue(result.metadata.isCyclicalSequence, "Should be marked as cyclical sequence")
        XCTAssertEqual(result.metadata.totalCycles, 4, "Should have 4 cycles")
        
        // Group notes by cycle index
        let notesByCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        XCTAssertEqual(notesByCycle.count, 4, "Should have notes from 4 different cycles")
        
        // Verify each cycle has distinct root notes
        for cycleIndex in 0..<4 {
            guard let cycleNotes = notesByCycle[cycleIndex] else {
                XCTFail("Missing notes for cycle \(cycleIndex)")
                continue
            }
            
            // Get the first note of each cycle (should be the root note)
            let firstNote = cycleNotes.min { $0.note < $1.note }?.note ?? 0
            let expectedRootNote = 60 + (cycleIndex * 2) // 60, 62, 64, 66
            
            XCTAssertEqual(firstNote, expectedRootNote, 
                          "Cycle \(cycleIndex) should start with root note \(expectedRootNote), got \(firstNote)")
        }
    }
    
    func testCyclicalNumberOfOctavesProgression() throws {
        // Test cyclical octave changes: 1 -> 2 -> 3 octaves
        let baseParameters = createBaseParameters()
        
        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.numberOfOctaves = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            stepSize: 1.0,
            maxCycles: 3,
            operationType: .replace
        )
        cyclicalSettings.enabledParameters = [.numberOfOctaves]
        
        baseParameters.cyclicalSettings = cyclicalSettings
        
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        // Verify each cycle has increasing note counts (more octaves = more notes)
        let notesByCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        
        var previousNoteCount = 0
        for cycleIndex in 0..<3 {
            guard let cycleNotes = notesByCycle[cycleIndex] else {
                XCTFail("Missing notes for cycle \(cycleIndex)")
                continue
            }
            
            let currentNoteCount = cycleNotes.count
            XCTAssertGreaterThan(currentNoteCount, previousNoteCount, 
                               "Cycle \(cycleIndex) should have more notes than previous cycle")
            previousNoteCount = currentNoteCount
        }
    }
    
    func testCyclicalTempoProgression() throws {
        // Test cyclical tempo changes: 120 -> 140 -> 160 BPM
        let baseParameters = createBaseParameters()
        
        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.tempo = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 120.0,
            maxValue: 160.0,
            stepSize: 20.0,
            maxCycles: 3,
            operationType: .replace
        )
        cyclicalSettings.enabledParameters = [.tempo]
        
        baseParameters.cyclicalSettings = cyclicalSettings
        
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        // Verify we have the expected number of cycles
        XCTAssertEqual(result.metadata.totalCycles, 3, "Should have 3 cycles")
        
        // Verify each cycle has notes (tempo affects timing, not note generation)
        let notesByCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        XCTAssertEqual(notesByCycle.count, 3, "Should have notes from 3 different cycles")
        
        for cycleIndex in 0..<3 {
            guard let cycleNotes = notesByCycle[cycleIndex] else {
                XCTFail("Missing notes for cycle \(cycleIndex)")
                continue
            }
            
            XCTAssertGreaterThan(cycleNotes.count, 0, "Cycle \(cycleIndex) should have notes")
        }
    }
    
    // MARK: - Multiple Cyclical Parameters Tests
    
    func testMultipleCyclicalParameters() throws {
        // Test multiple parameters changing simultaneously
        let baseParameters = createBaseParameters()
        
        var cyclicalSettings = CyclicalSettings()
        
        // Root note: 60 -> 64 -> 68
        cyclicalSettings.rootNote = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 60.0,
            maxValue: 68.0,
            stepSize: 4.0,
            maxCycles: 3,
            operationType: .replace
        )
        
        // Number of octaves: 1 -> 2 -> 3
        cyclicalSettings.numberOfOctaves = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            stepSize: 1.0,
            maxCycles: 3,
            operationType: .replace
        )
        
        cyclicalSettings.enabledParameters = [.rootNote, .numberOfOctaves]
        
        baseParameters.cyclicalSettings = cyclicalSettings
        
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        // Verify we have 3 cycles with increasing complexity
        XCTAssertEqual(result.metadata.totalCycles, 3, "Should have 3 cycles")
        
        let notesByCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        XCTAssertEqual(notesByCycle.count, 3, "Should have notes from 3 different cycles")
        
        // Verify each cycle has the expected characteristics
        for cycleIndex in 0..<3 {
            guard let cycleNotes = notesByCycle[cycleIndex] else {
                XCTFail("Missing notes for cycle \(cycleIndex)")
                continue
            }
            
            // Root note should be 60 + (cycleIndex * 4)
            let expectedRootNote = 60 + (cycleIndex * 4)
            let firstNote = cycleNotes.min { $0.note < $1.note }?.note ?? 0
            XCTAssertEqual(firstNote, expectedRootNote, 
                          "Cycle \(cycleIndex) should start with root note \(expectedRootNote)")
            
            // Note count should increase with more octaves
            let expectedOctaves = 1 + cycleIndex
            let expectedMinNotes = expectedOctaves * 7 // Assuming diatonic scale
            XCTAssertGreaterThanOrEqual(cycleNotes.count, expectedMinNotes, 
                                      "Cycle \(cycleIndex) should have at least \(expectedMinNotes) notes for \(expectedOctaves) octaves")
        }
    }
    
    // MARK: - Cyclical Operation Types Tests
    
    func testCyclicalOperationTypes() throws {
        let baseParameters = createBaseParameters()
        
        // Test ADD operation: base value + cyclical value
        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.rootNote = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 0.0,  // Will be added to base value
            maxValue: 6.0,
            stepSize: 2.0,
            maxCycles: 3,
            operationType: .add
        )
        cyclicalSettings.enabledParameters = [.rootNote]
        
        baseParameters.cyclicalSettings = cyclicalSettings
        
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        // Verify ADD operation: base 60 + (0, 2, 4) = 60, 62, 64
        let notesByCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        
        for cycleIndex in 0..<3 {
            guard let cycleNotes = notesByCycle[cycleIndex] else {
                XCTFail("Missing notes for cycle \(cycleIndex)")
                continue
            }
            
            let expectedRootNote = 60 + (cycleIndex * 2) // 60, 62, 64
            let firstNote = cycleNotes.min { $0.note < $1.note }?.note ?? 0
            XCTAssertEqual(firstNote, expectedRootNote, 
                          "Cycle \(cycleIndex) should start with root note \(expectedRootNote) using ADD operation")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testSingleCycleCyclical() throws {
        // Test with only one cycle (should behave like normal generation)
        let baseParameters = createBaseParameters()
        
        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.rootNote = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 60.0,
            maxValue: 60.0,
            stepSize: 0.0,
            maxCycles: 1,
            operationType: .replace
        )
        cyclicalSettings.enabledParameters = [.rootNote]
        
        baseParameters.cyclicalSettings = cyclicalSettings
        
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        // Should have only one cycle
        XCTAssertEqual(result.metadata.totalCycles, 1, "Should have 1 cycle")
        XCTAssertTrue(result.metadata.isCyclicalSequence, "Should still be marked as cyclical")
        
        // All notes should have cycle index 0
        let cycleIndices = Set(result.notes.map { $0.cycleIndex })
        XCTAssertEqual(cycleIndices.count, 1, "Should have notes from only one cycle")
        XCTAssertTrue(cycleIndices.contains(0), "Should have cycle index 0")
    }
    
    func testNoCyclicalParameters() throws {
        // Test with no cyclical parameters enabled
        let baseParameters = createBaseParameters()
        
        // No cyclical parameters enabled
        baseParameters.cyclicalSettings = CyclicalSettings()
        
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        // Should behave like normal pattern generation
        XCTAssertFalse(result.metadata.isCyclicalSequence, "Should not be marked as cyclical")
        XCTAssertEqual(result.metadata.totalCycles, 0, "Should have 0 cycles")
        
        // All notes should have cycle index 0 (default)
        let cycleIndices = Set(result.notes.map { $0.cycleIndex })
        XCTAssertEqual(cycleIndices.count, 1, "Should have notes from only one cycle")
        XCTAssertTrue(cycleIndices.contains(0), "Should have cycle index 0")
    }
    
    // MARK: - Performance Tests
    
    func testCyclicalPerformance() throws {
        // Test that cyclical generation doesn't take too long
        let baseParameters = createBaseParameters()
        
        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.rootNote = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 60.0,
            maxValue: 80.0,
            stepSize: 2.0,
            maxCycles: 10,
            operationType: .replace
        )
        cyclicalSettings.enabledParameters = [.rootNote]
        
        baseParameters.cyclicalSettings = cyclicalSettings
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete within reasonable time (adjust threshold as needed)
        XCTAssertLessThan(generationTime, 5.0, "Cyclical generation should complete within 5 seconds")
        
        // Should have generated notes from all 10 cycles
        XCTAssertEqual(result.metadata.totalCycles, 10, "Should have 10 cycles")
        XCTAssertGreaterThan(result.notes.count, 0, "Should have generated notes")
    }
    
    // MARK: - Helper Methods
    
    private func createBaseParameters() -> PatternParameters {
        return PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            tempo: 120.0,
            timeSignature: TimeSignature(numerator: 4, denominator: 4),
            primaryInterval: 2,
            secondaryInterval: 3,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: ModulationSettings(enabled: false),
            infrapolation: ModulationSettings(enabled: false),
            ultrapolation: ModulationSettings(enabled: false),
            primaryDirection: .ascending,
            mirrorPoints: 0,
            baseNoteDuration: 0.25,
            rhythmicDensity: 1.0,
            velocitySettings: VelocitySettings(),
            metricModulation: MetricModulationSettings(enabled: false),
            chordGeneration: ChordSettings(enabled: false),
            cyclicalSettings: CyclicalSettings()
        )
    }
}
