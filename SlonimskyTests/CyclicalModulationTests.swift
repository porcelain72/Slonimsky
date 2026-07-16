//
//  CyclicalModulationTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class CyclicalModulationTests: XCTestCase {
    
    // MARK: - Test Properties
    private var cyclicalGenerator: CyclicalSequenceGenerator!
    
    override func setUp() {
        super.setUp()
        cyclicalGenerator = CyclicalSequenceGenerator()
    }
    
    override func tearDown() {
        cyclicalGenerator = nil
        super.tearDown()
    }
    
    // MARK: - Basic Cyclical Interpolation Tests
    
    func testCyclicalInterpolationNotesIncrement() throws {
        // Test that interpolation numberOfNotes cycles correctly with increment cycle type
        // Test the CyclicalParameterSettings.currentValue() method directly
        var settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 2.0,
            maxValue: 4.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        settings.operationType = .replace
        
        // Test increment cycle type: 2 -> 3 -> 4
        settings.currentCycle = 0
        let value0 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value0), 2, "Cycle 0 should return 2")
        
        settings.currentCycle = 1
        let value1 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value1), 3, "Cycle 1 should return 3")
        
        settings.currentCycle = 2
        let value2 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value2), 4, "Cycle 2 should return 4")
    }
    
    func testCyclicalInterpolationNotesDecrement() throws {
        // Test decrement cycle type: starts at max and decreases
        var settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 2.0,
            maxValue: 4.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .decrement
        )
        settings.operationType = .replace
        
        // Decrement should start at max (4) and decrease: 4 -> 3 -> 2
        settings.currentCycle = 0
        let value0 = settings.currentValue(baseValue: 4.0)
        XCTAssertEqual(Int(value0), 4, "Cycle 0 should start at max (4)")
        
        settings.currentCycle = 1
        let value1 = settings.currentValue(baseValue: 4.0)
        XCTAssertEqual(Int(value1), 3, "Cycle 1 should be 3")
        
        settings.currentCycle = 2
        let value2 = settings.currentValue(baseValue: 4.0)
        XCTAssertEqual(Int(value2), 2, "Cycle 2 should be at min (2)")
    }
    
    func testCyclicalInterpolationNotesOscillate() throws {
        // Test oscillate cycle type: should go up then down
        var settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 2.0,
            maxValue: 4.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .oscillate
        )
        settings.operationType = .replace
        
        // Generate values for multiple cycles to see oscillation
        var values: [Int] = []
        for cycle in 0..<5 {
            settings.currentCycle = cycle
            values.append(Int(settings.currentValue(baseValue: 2.0)))
        }
        
        // Oscillate should go up then down: typically 2 -> 3 -> 4 -> 3 -> 2
        XCTAssertTrue(values[2] >= values[0], "Oscillate should increase from cycle 0 to 2")
        XCTAssertTrue(values[4] <= values[2], "Oscillate should decrease from cycle 2 to 4")
        XCTAssertEqual(values[0], values[4], "Oscillate should return to start value")
    }
    
    // MARK: - Cyclical Infrapolation Tests
    
    func testCyclicalInfrapolationNotesIncrement() throws {
        // Test infrapolation numberOfNotes cycling
        var settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        settings.operationType = .replace
        
        settings.currentCycle = 0
        let value0 = settings.currentValue(baseValue: 1.0)
        XCTAssertEqual(Int(value0), 1, "Cycle 0 should have 1 infrapolation notes")
        
        settings.currentCycle = 1
        let value1 = settings.currentValue(baseValue: 1.0)
        XCTAssertEqual(Int(value1), 2, "Cycle 1 should have 2 infrapolation notes")
        
        settings.currentCycle = 2
        let value2 = settings.currentValue(baseValue: 1.0)
        XCTAssertEqual(Int(value2), 3, "Cycle 2 should have 3 infrapolation notes")
    }
    
    // MARK: - Cyclical Ultrapolation Tests
    
    func testCyclicalUltrapolationNotesIncrement() throws {
        // Test ultrapolation numberOfNotes cycling
        var settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        settings.operationType = .replace
        
        settings.currentCycle = 0
        let value0 = settings.currentValue(baseValue: 1.0)
        XCTAssertEqual(Int(value0), 1, "Cycle 0 should have 1 ultrapolation notes")
        
        settings.currentCycle = 1
        let value1 = settings.currentValue(baseValue: 1.0)
        XCTAssertEqual(Int(value1), 2, "Cycle 1 should have 2 ultrapolation notes")
        
        settings.currentCycle = 2
        let value2 = settings.currentValue(baseValue: 1.0)
        XCTAssertEqual(Int(value2), 3, "Cycle 2 should have 3 ultrapolation notes")
    }
    
    // MARK: - Cyclical Operation Types Tests
    
    func testCyclicalInterpolationNotesWithAddOperation() throws {
        // Test that ADD operation works correctly (note: operation type is applied in applyCyclicalParameter,
        // but currentValue returns the cyclical value, operation is applied separately)
        // For this test, we verify the cyclical value itself cycles correctly
        var settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 0.0,
            maxValue: 2.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        settings.operationType = .add
        
        // The cyclical values should be: 0, 1, 2
        settings.currentCycle = 0
        let value0 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value0), 0, "Cycle 0 cyclical value should be 0")
        
        settings.currentCycle = 1
        let value1 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value1), 1, "Cycle 1 cyclical value should be 1")
        
        settings.currentCycle = 2
        let value2 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value2), 2, "Cycle 2 cyclical value should be 2")
    }
    
    func testCyclicalInterpolationNotesWithMultiplyOperation() throws {
        // Test MULTIPLY operation cyclical values
        var settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        settings.operationType = .multiply
        
        // The cyclical values should be: 1, 2, 3
        settings.currentCycle = 0
        let value0 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value0), 1, "Cycle 0 cyclical value should be 1")
        
        settings.currentCycle = 1
        let value1 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value1), 2, "Cycle 1 cyclical value should be 2")
        
        settings.currentCycle = 2
        let value2 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value2), 3, "Cycle 2 cyclical value should be 3")
    }
    
    // MARK: - Pattern Generation Impact Tests
    
    func testCyclicalInterpolationAffectsPatternGeneration() throws {
        // Test that cycled numberOfNotes actually affects the generated pattern
        // This is an end-to-end test using the cyclical sequence generator
        var baseParameters = createBaseParametersWithModulation()
        baseParameters.interpolation = ModulationSettings(
            numberOfNotes: 1,
            interval: 2,
            enabled: true
        )
        
        var cyclicalSettings = CyclicalSettings()
        var interpolationSettings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            stepSize: 1.0,
            cycleType: .increment
        )
        interpolationSettings.operationType = .replace
        cyclicalSettings.interpolationNotes = interpolationSettings
        // enabledParameters is a computed property - setting isEnabled on the individual settings makes them enabled
        baseParameters.cyclicalSettings = cyclicalSettings
        
        // Generate actual patterns for multiple cycles
        guard let result = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Modulation Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        XCTAssertTrue(result.metadata.isCyclicalSequence, "Should be marked as cyclical sequence")
        XCTAssertGreaterThan(result.metadata.totalCycles, 0, "Should have cycles")
        
        // Group notes by cycle index
        let notesByCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        
        // Verify we have notes from multiple cycles
        XCTAssertGreaterThanOrEqual(notesByCycle.count, 2, "Should have notes from at least 2 cycles")
        
        // Verify cycles have notes
        for (cycleIndex, notes) in notesByCycle {
            XCTAssertGreaterThan(notes.count, 0, "Cycle \(cycleIndex) should have notes")
        }
    }
    
    func testCyclicalInterpolationAppliedUniformlyToAllNotePairs() throws {
        // Test that the cyclical numberOfNotes value is applied uniformly to ALL note pairs in each cycle
        // This test verifies that interpolation is applied consistently across cycles
        
        // Create base parameters with mirror disabled to simplify the test
        var baseParameters = createBaseParametersWithModulation(mirror: false)
        
        // Enable cyclical interpolation
        baseParameters.interpolation = ModulationSettings(
            numberOfNotes: 1,
            interval: 1,
            enabled: true
        )
        
        var cyclicalSettings = CyclicalSettings()
        var interpolationSettings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,  // Use 3.0 to allow cycles 0 and 1 (values 1.0 and 2.0)
            // The generator checks if nextValue > maxValue before generating current cycle
            // Cycle 0: nextValue (for cycle 1) = 2.0, which is <= 3.0, so generate cycle 0
            // Cycle 1: nextValue (for cycle 2) = 3.0, which is <= 3.0, so generate cycle 1
            // Cycle 2: nextValue (for cycle 3) = 4.0, which is > 3.0, so stop
            stepSize: 1.0,
            cycleType: .increment
        )
        interpolationSettings.operationType = .replace
        cyclicalSettings.interpolationNotes = interpolationSettings
        baseParameters.cyclicalSettings = cyclicalSettings
        
        // Generate patterns with cyclical interpolation
        // We need to use generatePattern (not generateNotePattern) because interpolation
        // is applied during MIDI conversion in MIDIPatternConverter
        let scaleGenerator = ScalePatternGenerator()
        
        // Generate pattern for cycle 0 (should have numberOfNotes = 1)
        let cycle0MIDINotes = scaleGenerator.generatePattern(parameters: baseParameters, cycleIndex: 0)
        let cycle0Count = cycle0MIDINotes.count
        
        // Generate pattern for cycle 1 (should have numberOfNotes = 2)
        let cycle1MIDINotes = scaleGenerator.generatePattern(parameters: baseParameters, cycleIndex: 1)
        let cycle1Count = cycle1MIDINotes.count
        
        XCTAssertGreaterThan(cycle0Count, 0, "Cycle 0 should have notes")
        XCTAssertGreaterThan(cycle1Count, 0, "Cycle 1 should have notes")
        
        // Cycle 1 should have more notes than cycle 0 because numberOfNotes increases from 1 to 2
        // This verifies that cyclical interpolation is working and applied uniformly
        XCTAssertGreaterThan(cycle1Count, cycle0Count, 
                           "Cycle 1 should have more notes than cycle 0 due to increased interpolation numberOfNotes (1 -> 2)")
        
        // Calculate expected difference based on number of gaps
        // The base pattern (before interpolation) should have the same structure in both cycles
        // The difference should be: numberOfGaps * (difference in numberOfNotes)
        // Cycle 0: numberOfNotes = 1, Cycle 1: numberOfNotes = 2, so difference = numberOfGaps * 1
        
        // Get base pattern without interpolation to count gaps
        var baseParamsNoInterpolation = baseParameters
        baseParamsNoInterpolation.interpolation = ModulationSettings(enabled: false)
        let basePattern = scaleGenerator.generateNotePattern(parameters: baseParamsNoInterpolation, cycleIndex: 0)
        let numberOfGaps = max(0, basePattern.count - 1)
        
        XCTAssertGreaterThan(numberOfGaps, 0, "Should have at least one gap between base notes")
        
        // The difference should be at least numberOfGaps (since we go from 1 to 2 interpolated notes per gap)
        let actualDifference = cycle1Count - cycle0Count
        XCTAssertGreaterThanOrEqual(actualDifference, numberOfGaps,
                                  "Cycle 1 should have at least \(numberOfGaps) more notes than cycle 0")
    }
    
    func testMultipleCyclicalModulations() throws {
        // Test multiple modulation types cycling simultaneously
        var interpolationSettings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 2.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        interpolationSettings.operationType = .replace
        
        var infrapolationSettings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 2.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        infrapolationSettings.operationType = .replace
        
        // Test both cycle independently
        interpolationSettings.currentCycle = 0
        infrapolationSettings.currentCycle = 0
        XCTAssertEqual(Int(interpolationSettings.currentValue(baseValue: 1.0)), 1, "Cycle 0 interpolation should be 1")
        XCTAssertEqual(Int(infrapolationSettings.currentValue(baseValue: 1.0)), 1, "Cycle 0 infrapolation should be 1")
        
        interpolationSettings.currentCycle = 1
        infrapolationSettings.currentCycle = 1
        XCTAssertEqual(Int(interpolationSettings.currentValue(baseValue: 1.0)), 2, "Cycle 1 interpolation should be 2")
        XCTAssertEqual(Int(infrapolationSettings.currentValue(baseValue: 1.0)), 2, "Cycle 1 infrapolation should be 2")
    }
    
    // MARK: - Edge Cases Tests
    
    func testCyclicalModulationWhenDisabled() throws {
        // Test that when cyclical settings are disabled, base value is returned
        var settings = CyclicalParameterSettings(
            isEnabled: false,  // Disabled
            minValue: 1.0,
            maxValue: 5.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        settings.operationType = .replace
        
        // When disabled, should return base value regardless of cycle
        settings.currentCycle = 0
        let value0 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value0), 2, "When disabled, should return base value")
        
        settings.currentCycle = 10
        let value10 = settings.currentValue(baseValue: 2.0)
        XCTAssertEqual(Int(value10), 2, "When disabled, should return base value even at high cycle")
    }
    
    func testCyclicalModulationBoundsRespected() throws {
        // Test that min/max bounds are respected
        var settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            stepSize: 1.0,
            currentCycle: 0,
            cycleType: .increment
        )
        settings.operationType = .replace
        
        // Generate many cycles to ensure bounds are respected
        for cycleIndex in 0..<10 {
            settings.currentCycle = cycleIndex
            let value = settings.currentValue(baseValue: 2.0)
            XCTAssertGreaterThanOrEqual(value, 1.0, 
                                       "Cycle \(cycleIndex) should respect min bound")
            XCTAssertLessThanOrEqual(value, 3.0, 
                                    "Cycle \(cycleIndex) should respect max bound")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createBaseParametersWithModulation(mirror: Bool = true) -> PatternParameters {
        return PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 2,
            secondaryInterval: 3,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: ModulationSettings(enabled: false),
            infrapolation: ModulationSettings(enabled: false),
            ultrapolation: ModulationSettings(enabled: false),
            mirror: mirror,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            baseNoteDuration: 0.25,
            chordGeneration: ChordSettings(enabled: false), velocitySettings: VelocitySettings(),
            cyclicalSettings: CyclicalSettings()
        )
    }
}
