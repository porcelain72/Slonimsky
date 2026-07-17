//
//  CyclicalModulationTests.swift
//  SlonimskyTests
//
//  Tests for phase-based cyclical modulation parameters.
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

    // MARK: - Curve Value Tests

    func testCyclicalInterpolationNotesRampUp() throws {
        // Ramp up over a period of 4: values rise linearly from min and wrap
        let settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 0.0,
            maxValue: 8.0,
            period: 4,
            shape: .rampUp
        )

        XCTAssertEqual(settings.value(atCycle: 0, baseValue: 99), 0.0, accuracy: 1e-9, "Cycle 0 starts at min")
        XCTAssertEqual(settings.value(atCycle: 1, baseValue: 99), 2.0, accuracy: 1e-9)
        XCTAssertEqual(settings.value(atCycle: 2, baseValue: 99), 4.0, accuracy: 1e-9)
        XCTAssertEqual(settings.value(atCycle: 3, baseValue: 99), 6.0, accuracy: 1e-9)
        XCTAssertEqual(settings.value(atCycle: 4, baseValue: 99), 0.0, accuracy: 1e-9, "Wraps after one period")
    }

    func testCyclicalInterpolationNotesRampDown() throws {
        // Ramp down starts at max and falls
        let settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 2.0,
            maxValue: 4.0,
            period: 4,
            shape: .rampDown
        )

        XCTAssertEqual(settings.value(atCycle: 0, baseValue: 99), 4.0, accuracy: 1e-9, "Cycle 0 starts at max")
        XCTAssertEqual(settings.value(atCycle: 2, baseValue: 99), 3.0, accuracy: 1e-9, "Mid-period is halfway down")
        XCTAssertEqual(settings.value(atCycle: 4, baseValue: 99), 4.0, accuracy: 1e-9, "Wraps after one period")
    }

    func testCyclicalInterpolationNotesTriangle() throws {
        // Triangle rises to max mid-period and falls back
        let settings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 2.0,
            maxValue: 4.0,
            period: 4,
            shape: .triangle
        )

        var values: [Double] = []
        for cycle in 0..<5 {
            values.append(settings.value(atCycle: cycle, baseValue: 99))
        }

        XCTAssertGreaterThanOrEqual(values[2], values[0], "Triangle rises to mid-period")
        XCTAssertLessThanOrEqual(values[4], values[2], "Triangle falls in second half")
        XCTAssertEqual(values[0], values[4], accuracy: 1e-9, "Triangle returns to start after one period")
        XCTAssertEqual(values[2], 4.0, accuracy: 1e-9, "Triangle peaks at max")
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
        cyclicalSettings.interpolationNotes = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            period: 3,
            shape: .rampUp
        )
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
        XCTAssertEqual(result.metadata.totalCycles, 3, "Sequence should run one full period")

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

        // Create base parameters with mirror disabled to simplify the test
        var baseParameters = createBaseParametersWithModulation(mirror: false)

        // Enable cyclical interpolation: rampUp over period 2 gives
        // numberOfNotes 1 at cycle 0 and 2 at cycle 1 (phase 0.5 of 1...3)
        baseParameters.interpolation = ModulationSettings(
            numberOfNotes: 1,
            interval: 1,
            enabled: true
        )

        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.interpolationNotes = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            period: 2,
            shape: .rampUp
        )
        baseParameters.cyclicalSettings = cyclicalSettings

        // We need to use generatePattern (not generateNotePattern) because interpolation
        // is applied during MIDI conversion in MIDIPatternConverter
        let scaleGenerator = ScalePatternGenerator()

        // Generate pattern for cycle 0 (numberOfNotes = 1)
        let cycle0MIDINotes = scaleGenerator.generatePattern(parameters: baseParameters, cycleIndex: 0)
        let cycle0Count = cycle0MIDINotes.count

        // Generate pattern for cycle 1 (numberOfNotes = 2)
        let cycle1MIDINotes = scaleGenerator.generatePattern(parameters: baseParameters, cycleIndex: 1)
        let cycle1Count = cycle1MIDINotes.count

        XCTAssertGreaterThan(cycle0Count, 0, "Cycle 0 should have notes")
        XCTAssertGreaterThan(cycle1Count, 0, "Cycle 1 should have notes")

        // Cycle 1 should have more notes than cycle 0 because numberOfNotes increases from 1 to 2
        XCTAssertGreaterThan(cycle1Count, cycle0Count,
                           "Cycle 1 should have more notes than cycle 0 due to increased interpolation numberOfNotes (1 -> 2)")

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

    func testMultipleCyclicalModulationsPhaseIndependently() throws {
        // Two curves with different periods evolve independently and
        // realign at the lcm of their periods
        let interpolationSettings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 3.0,
            period: 2,
            shape: .rampUp
        )

        let infrapolationSettings = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 1.0,
            maxValue: 4.0,
            period: 3,
            shape: .rampUp
        )

        // Period 2 curve: 1.0, 2.0, 1.0, 2.0, ...
        XCTAssertEqual(interpolationSettings.value(atCycle: 0, baseValue: 0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(interpolationSettings.value(atCycle: 1, baseValue: 0), 2.0, accuracy: 1e-9)
        XCTAssertEqual(interpolationSettings.value(atCycle: 2, baseValue: 0), 1.0, accuracy: 1e-9)

        // Period 3 curve: 1.0, 2.0, 3.0, 1.0, ...
        XCTAssertEqual(infrapolationSettings.value(atCycle: 0, baseValue: 0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(infrapolationSettings.value(atCycle: 1, baseValue: 0), 2.0, accuracy: 1e-9)
        XCTAssertEqual(infrapolationSettings.value(atCycle: 3, baseValue: 0), 1.0, accuracy: 1e-9)

        // They first coincide again at cycle 6 = lcm(2, 3)
        var settings = CyclicalSettings()
        settings.interpolationNotes = interpolationSettings
        settings.infrapolationNotes = infrapolationSettings
        XCTAssertEqual(settings.realignmentCycles, 6, "Periods 2 and 3 realign at 6")
    }

    // MARK: - Edge Cases Tests

    func testCyclicalModulationWhenDisabled() throws {
        // Test that when cyclical settings are disabled, base value is returned
        let settings = CyclicalParameterSettings(
            isEnabled: false,  // Disabled
            minValue: 1.0,
            maxValue: 5.0,
            period: 4,
            shape: .rampUp
        )

        XCTAssertEqual(settings.value(atCycle: 0, baseValue: 2.0), 2.0, "When disabled, should return base value")
        XCTAssertEqual(settings.value(atCycle: 10, baseValue: 2.0), 2.0, "When disabled, should return base value even at high cycle")
    }

    func testCyclicalModulationBoundsRespected() throws {
        // Test that min/max bounds are respected for every shape
        for shape in CycleShape.allCases {
            let settings = CyclicalParameterSettings(
                isEnabled: true,
                minValue: 1.0,
                maxValue: 3.0,
                period: 5,
                shape: shape
            )

            for cycleIndex in 0..<10 {
                let value = settings.value(atCycle: cycleIndex, baseValue: 2.0)
                XCTAssertGreaterThanOrEqual(value, 1.0,
                                           "\(shape) cycle \(cycleIndex) should respect min bound")
                XCTAssertLessThanOrEqual(value, 3.0,
                                        "\(shape) cycle \(cycleIndex) should respect max bound")
            }
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
