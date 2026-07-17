//
//  PhaseCycleTests.swift
//  SlonimskyTests
//
//  Tests for phase-based cyclical parameter curves (period + shape, lcm realignment).
//

import XCTest
@testable import Slonimsky

final class PhaseCycleTests: XCTestCase {

    private func settings(min: Double, max: Double, period: Int, shape: CycleShape) -> CyclicalParameterSettings {
        CyclicalParameterSettings(isEnabled: true, minValue: min, maxValue: max, period: period, shape: shape)
    }

    // MARK: - Shape endpoints

    func testRampUp() {
        let s = settings(min: 0, max: 12, period: 4, shape: .rampUp)
        XCTAssertEqual(s.value(atCycle: 0, baseValue: 99), 0.0, accuracy: 1e-9)
        XCTAssertEqual(s.value(atCycle: 1, baseValue: 99), 3.0, accuracy: 1e-9)
        XCTAssertEqual(s.value(atCycle: 3, baseValue: 99), 9.0, accuracy: 1e-9)
        XCTAssertEqual(s.value(atCycle: 4, baseValue: 99), 0.0, accuracy: 1e-9, "Wraps at period")
    }

    func testRampDown() {
        let s = settings(min: 0, max: 12, period: 4, shape: .rampDown)
        XCTAssertEqual(s.value(atCycle: 0, baseValue: 99), 12.0, accuracy: 1e-9)
        XCTAssertEqual(s.value(atCycle: 2, baseValue: 99), 6.0, accuracy: 1e-9)
        XCTAssertEqual(s.value(atCycle: 4, baseValue: 99), 12.0, accuracy: 1e-9, "Wraps at period")
    }

    func testTriangle() {
        let s = settings(min: 0, max: 10, period: 4, shape: .triangle)
        XCTAssertEqual(s.value(atCycle: 0, baseValue: 99), 0.0, accuracy: 1e-9, "Starts at min")
        XCTAssertEqual(s.value(atCycle: 2, baseValue: 99), 10.0, accuracy: 1e-9, "Peaks mid-period")
        XCTAssertEqual(s.value(atCycle: 3, baseValue: 99), 5.0, accuracy: 1e-9, "Falls in second half")
        XCTAssertEqual(s.value(atCycle: 4, baseValue: 99), 0.0, accuracy: 1e-9, "Returns to min")
    }

    func testSine() {
        let s = settings(min: 0, max: 10, period: 4, shape: .sine)
        XCTAssertEqual(s.value(atCycle: 0, baseValue: 99), 0.0, accuracy: 1e-9, "Raised cosine starts at min")
        XCTAssertEqual(s.value(atCycle: 2, baseValue: 99), 10.0, accuracy: 1e-9, "Peaks mid-period")
        XCTAssertEqual(s.value(atCycle: 1, baseValue: 99), 5.0, accuracy: 1e-9, "Quarter period is halfway")
    }

    func testRandomHoldDeterministicAndBounded() {
        let s = settings(min: 40, max: 100, period: 8, shape: .randomHold)
        for c in 0..<32 {
            let v1 = s.value(atCycle: c, baseValue: 99)
            let v2 = s.value(atCycle: c, baseValue: 99)
            XCTAssertEqual(v1, v2, "Same cycle must give the same value")
            XCTAssertGreaterThanOrEqual(v1, 40)
            XCTAssertLessThanOrEqual(v1, 100)
        }
        // Not all values identical (it is actually random-ish)
        let distinct = Set((0..<8).map { s.value(atCycle: $0, baseValue: 99) })
        XCTAssertGreaterThan(distinct.count, 1)
    }

    // MARK: - Periodicity

    func testPeriodicityAcrossAllShapes() {
        for shape in CycleShape.allCases {
            let s = settings(min: 1, max: 9, period: 5, shape: shape)
            for c in 0..<10 {
                XCTAssertEqual(
                    s.value(atCycle: c, baseValue: 0),
                    s.value(atCycle: c + 5, baseValue: 0),
                    accuracy: 1e-9,
                    "\(shape) must repeat every period"
                )
            }
        }
    }

    func testDisabledReturnsBase() {
        var s = settings(min: 0, max: 10, period: 4, shape: .rampUp)
        s.isEnabled = false
        XCTAssertEqual(s.value(atCycle: 3, baseValue: 42.5), 42.5)
    }

    // MARK: - Realignment (lcm)

    func testRealignmentIsLcmOfPeriods() {
        var cyclical = CyclicalSettings()
        cyclical.rootNote.isEnabled = true
        cyclical.rootNote.period = 3
        cyclical.euclideanRotation.isEnabled = true
        cyclical.euclideanRotation.period = 4
        XCTAssertEqual(cyclical.realignmentCycles, 12, "Periods 3 and 4 realign at 12")

        cyclical.euclideanRotation.period = 8
        cyclical.rootNote.period = 2
        XCTAssertEqual(cyclical.realignmentCycles, 8, "Periods 2 and 8 realign at 8")
    }

    func testRealignmentWithNoEnabledParameters() {
        XCTAssertEqual(CyclicalSettings().realignmentCycles, 1)
    }

    // MARK: - Sequence generation

    func testCyclicalSequenceLengthIsLcm() {
        var params = PatternParameters(numberOfOctaves: 1)
        params.cyclicalSettings.rootNote.isEnabled = true
        params.cyclicalSettings.rootNote.minValue = 60
        params.cyclicalSettings.rootNote.maxValue = 72
        params.cyclicalSettings.rootNote.period = 3
        params.cyclicalSettings.baseVelocity.isEnabled = true
        params.cyclicalSettings.baseVelocity.period = 4

        let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Scale Pattern Generator"
        )

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.metadata.isCyclicalSequence)
        XCTAssertEqual(result!.metadata.totalCycles, 12, "Sequence runs until periods 3 and 4 realign")
    }

    func testCyclicalSequenceCapped() {
        var params = PatternParameters(numberOfOctaves: 1)
        params.cyclicalSettings.rootNote.isEnabled = true
        params.cyclicalSettings.rootNote.minValue = 60
        params.cyclicalSettings.rootNote.maxValue = 72
        params.cyclicalSettings.rootNote.period = 63
        params.cyclicalSettings.baseVelocity.isEnabled = true
        params.cyclicalSettings.baseVelocity.period = 64
        // lcm(63, 64) = 4032, far above the cap

        let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Scale Pattern Generator"
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.metadata.totalCycles, CyclicalSequenceGenerator.cycleCap,
                       "Runaway realignments are capped")
    }

    func testPhasingParametersChangeIndependently() {
        // rootNote ramps over period 2; the generated cycles should show the root
        // moving between cycles (phase evaluation reaches the generators)
        var params = PatternParameters(numberOfOctaves: 1)
        params.cyclicalSettings.rootNote.isEnabled = true
        params.cyclicalSettings.rootNote.minValue = 60
        params.cyclicalSettings.rootNote.maxValue = 72
        params.cyclicalSettings.rootNote.period = 2
        params.cyclicalSettings.rootNote.shape = .rampUp

        let manager0 = CyclicalParameterManager(cyclicalSettings: params.cyclicalSettings)
        let cycle0 = manager0.getModifiedParameters(from: params, cycleIndex: 0)
        let cycle1 = manager0.getModifiedParameters(from: params, cycleIndex: 1)

        XCTAssertEqual(cycle0.rootNote, 60, "Cycle 0 sits at min")
        XCTAssertEqual(cycle1.rootNote, 66, "Cycle 1 is halfway up the ramp")
    }

    // MARK: - Integer rounding

    func testIntegerParametersRound() {
        var cyclical = CyclicalSettings()
        cyclical.rootNote.isEnabled = true
        cyclical.rootNote.minValue = 60
        cyclical.rootNote.maxValue = 61
        cyclical.rootNote.period = 3
        cyclical.rootNote.shape = .rampUp

        let params = PatternParameters(cyclicalSettings: cyclical)
        let manager = CyclicalParameterManager(cyclicalSettings: cyclical)
        // phase 1/3 -> 60.333 -> rounds to 60; phase 2/3 -> 60.667 -> rounds to 61
        XCTAssertEqual(manager.getModifiedParameters(from: params, cycleIndex: 1).rootNote, 60)
        XCTAssertEqual(manager.getModifiedParameters(from: params, cycleIndex: 2).rootNote, 61)
    }
}
