//
//  ProcessTests.swift
//  SlonimskyTests
//
//  Tests for the Glass-style additive/subtractive pattern process.
//

import XCTest
@testable import Slonimsky

/// Every shipped preset must validate and generate a non-empty pattern
/// through the same pipeline the Presets panel uses.
final class ShowcasePresetTests: XCTestCase {

    func testAllPresetsValidate() {
        for preset in allPresets {
            XCTAssertTrue(preset.parameters.validate(), "Preset '\(preset.name)' has invalid parameters")
        }
    }

    func testShowcasePresetsGenerate() {
        for preset in showcasePresets {
            let result: PatternGenerationResult?
            if preset.parameters.isCyclicalGeneration {
                result = CyclicalSequenceGenerator().generateCyclicalSequence(
                    baseParameters: preset.parameters,
                    generatorName: preset.generatorName
                )
            } else {
                result = PatternGeneratorRegistry.shared.generatePattern(
                    using: preset.generatorName,
                    parameters: preset.parameters
                )
            }
            XCTAssertNotNil(result, "Preset '\(preset.name)' failed to generate")
            XCTAssertGreaterThan(result?.notes.soundingNotes.count ?? 0, 0,
                                 "Preset '\(preset.name)' generated no sounding notes")
        }
    }

    func testShowcasePresetsAreMultiCycleWhereExpected() {
        let multiCycleNames = ["Balkan Machine", "Glass Pendulum", "Phase Music", "Odd-Time Traveler"]
        for preset in showcasePresets where multiCycleNames.contains(preset.name) {
            XCTAssertTrue(preset.parameters.isCyclicalGeneration,
                          "Preset '\(preset.name)' should trigger multi-cycle generation")
            let result = CyclicalSequenceGenerator().generateCyclicalSequence(
                baseParameters: preset.parameters,
                generatorName: preset.generatorName
            )
            XCTAssertGreaterThan(result?.metadata.totalCycles ?? 0, 1,
                                 "Preset '\(preset.name)' should produce multiple cycles")
        }
    }
}

final class ProcessTests: XCTestCase {

    // MARK: - Kept-note math

    func testAdditiveSequence() {
        var settings = ProcessSettings()
        settings.mode = .additive
        settings.startCount = 1
        settings.notesPerCycle = 1

        XCTAssertEqual(settings.cycleCount(forPatternLength: 5), 5)
        XCTAssertEqual((0..<5).map { settings.keptNoteCount(atCycle: $0, patternLength: 5) },
                       [1, 2, 3, 4, 5])
    }

    func testAdditiveWithStepAndStart() {
        var settings = ProcessSettings()
        settings.mode = .additive
        settings.startCount = 2
        settings.notesPerCycle = 3

        // 2, 5, 8, 10 (clamped) over ceil((10-2)/3)+1 = 4 cycles
        XCTAssertEqual(settings.cycleCount(forPatternLength: 10), 4)
        XCTAssertEqual((0..<4).map { settings.keptNoteCount(atCycle: $0, patternLength: 10) },
                       [2, 5, 8, 10])
    }

    func testSubtractiveSequence() {
        var settings = ProcessSettings()
        settings.mode = .subtractive
        settings.notesPerCycle = 1

        XCTAssertEqual(settings.cycleCount(forPatternLength: 4), 4)
        XCTAssertEqual((0..<4).map { settings.keptNoteCount(atCycle: $0, patternLength: 4) },
                       [4, 3, 2, 1])
    }

    func testPendulumSequence() {
        var settings = ProcessSettings()
        settings.mode = .pendulum
        settings.startCount = 1
        settings.notesPerCycle = 1

        // Up: 1,2,3,4,5 (5 cycles), down: 4,3,2,1 -> 9 cycles total
        XCTAssertEqual(settings.cycleCount(forPatternLength: 5), 9)
        XCTAssertEqual((0..<9).map { settings.keptNoteCount(atCycle: $0, patternLength: 5) },
                       [1, 2, 3, 4, 5, 4, 3, 2, 1])
    }

    func testOffModeKeepsEverything() {
        let settings = ProcessSettings()
        XCTAssertEqual(settings.cycleCount(forPatternLength: 12), 1)
        XCTAssertEqual(settings.keptNoteCount(atCycle: 3, patternLength: 12), 12)
    }

    // MARK: - Sequence generation

    private func additiveParameters() -> PatternParameters {
        var params = PatternParameters(scaleType: .pentatonic, numberOfOctaves: 1, divisionsOfOctave: 5, mirror: false)
        params.processSettings.mode = .additive
        params.processSettings.startCount = 1
        params.processSettings.notesPerCycle = 1
        return params
    }

    func testProcessAloneTriggersCyclicalGeneration() {
        let params = additiveParameters()
        XCTAssertTrue(params.isCyclicalGeneration, "An active process alone should run the multi-cycle pipeline")

        guard let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Scale Pattern Generator"
        ) else {
            return XCTFail("Generation failed")
        }

        XCTAssertTrue(result.metadata.isCyclicalSequence)
        // Reference pattern length N drives the cycle count: one cycle per added note
        let notesByCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        XCTAssertEqual(result.metadata.totalCycles, notesByCycle.keys.count)
        XCTAssertGreaterThan(result.metadata.totalCycles, 1, "Additive process should produce multiple cycles")

        // Cycle 0 keeps exactly one sounding note (plus the seam rule keeps it intact:
        // single-note cycles are never dropped)
        let cycle0 = notesByCycle[0] ?? []
        XCTAssertEqual(cycle0.soundingNotes.count, 1, "First additive cycle should have one note")

        // Sounding counts grow monotonically until the seam rule trims one note
        // per non-final cycle; the last cycle holds the full pattern
        let lastCycle = notesByCycle[result.metadata.totalCycles - 1] ?? []
        XCTAssertGreaterThan(lastCycle.soundingNotes.count, cycle0.soundingNotes.count,
                             "Final cycle should contain the grown pattern")
    }

    func testProcessMergesWithCurveRealignmentViaLcm() {
        // First measure the process's own cycle count (depends on the
        // generator's pattern length), then verify the lcm merge with a curve.
        let processOnly = additiveParameters()
        guard let reference = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: processOnly,
            generatorName: "Scale Pattern Generator"
        ) else {
            return XCTFail("Reference generation failed")
        }
        let processCycles = reference.metadata.totalCycles
        XCTAssertGreaterThan(processCycles, 1)

        var params = additiveParameters()
        params.cyclicalSettings.baseVelocity.isEnabled = true
        params.cyclicalSettings.baseVelocity.period = 3

        guard let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Scale Pattern Generator"
        ) else {
            return XCTFail("Generation failed")
        }

        let expected = min(CyclicalSettings.lcm(processCycles, 3), CyclicalSequenceGenerator.cycleCap)
        XCTAssertEqual(result.metadata.totalCycles, expected,
                       "Process (\(processCycles)) and curve (3) should realign at their lcm")
    }

    func testProcessTruncationKeepsInterleavedRests() {
        // Euclidean E(3,8): each grid cycle has rests between hits. Additive cycle 0
        // must keep the leading rests up to (and including) the first sounding note.
        var params = additiveParameters()
        params.rhythmSettings.mode = .euclidean
        params.rhythmSettings.euclideanHits = 3
        params.rhythmSettings.euclideanSteps = 8
        params.rhythmSettings.euclideanRotation = 1 // grid starts with a rest after rotation
        params.rhythmSettings.accentBoost = 0

        guard let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Scale Pattern Generator"
        ) else {
            return XCTFail("Generation failed")
        }

        let notesByCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        let cycle0 = (notesByCycle[0] ?? []).sorted { $0.onset < $1.onset }
        XCTAssertEqual(cycle0.soundingNotes.count, 1, "Additive cycle 0 keeps one sounding note")
        if let lastEvent = cycle0.last {
            XCTAssertFalse(lastEvent.isRest, "Truncation ends at the kept sounding note")
        }
        // E(3,8) rotated by 1 = [..x..x.x] style grid — the kept note may be preceded by rests
        XCTAssertGreaterThanOrEqual(cycle0.count, 1)
    }

    func testProcessCycleCountRespectsCap() {
        var params = PatternParameters(numberOfOctaves: 8, divisionsOfOctave: 12) // large pattern
        params.processSettings.mode = .additive
        params.processSettings.startCount = 1
        params.processSettings.notesPerCycle = 1

        guard let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Scale Pattern Generator"
        ) else {
            return XCTFail("Generation failed")
        }

        XCTAssertLessThanOrEqual(result.metadata.totalCycles, CyclicalSequenceGenerator.cycleCap,
                                 "Process cycle count is capped")
    }
}
