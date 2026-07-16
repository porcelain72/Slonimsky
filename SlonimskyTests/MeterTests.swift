//
//  MeterTests.swift
//  SlonimskyTests
//
//  Tests for the Meter model (time signatures with additive groupings).
//

import XCTest
@testable import Slonimsky

final class MeterTests: XCTestCase {

    // MARK: - Default groupings

    func testDefaultGroupingsFourFour() {
        XCTAssertEqual(Meter.defaultGroupings(numerator: 4, denominator: 4), [1, 1, 1, 1])
    }

    func testDefaultGroupingsSixEight() {
        XCTAssertEqual(Meter.defaultGroupings(numerator: 6, denominator: 8), [3, 3])
    }

    func testDefaultGroupingsSevenEight() {
        XCTAssertEqual(Meter.defaultGroupings(numerator: 7, denominator: 8), [2, 2, 3])
    }

    func testDefaultGroupingsFiveFour() {
        XCTAssertEqual(Meter.defaultGroupings(numerator: 5, denominator: 4), [3, 2])
    }

    // MARK: - Beats per bar (quarter = 1.0)

    func testBeatsPerBar() {
        XCTAssertEqual(Meter.fourFour.beatsPerBar, 4.0, accuracy: 1e-9)
        XCTAssertEqual(Meter.sixEight.beatsPerBar, 3.0, accuracy: 1e-9)
        XCTAssertEqual(Meter.sevenEight.beatsPerBar, 3.5, accuracy: 1e-9)
        XCTAssertEqual(Meter.elevenSixteen.beatsPerBar, 2.75, accuracy: 1e-9)
    }

    // MARK: - Grouping onsets

    func testGroupingOnsetsSevenEightDefault() {
        // 7/8 [2,2,3]: groups start at 0, 1.0, 2.0 beats
        XCTAssertEqual(Meter.sevenEight.groupingOnsets, [0.0, 1.0, 2.0])
    }

    func testGroupingOnsetsSevenEightAlternate() {
        let meter = Meter(numerator: 7, denominator: 8, groupings: [3, 2, 2])
        XCTAssertEqual(meter.groupingOnsets, [0.0, 1.5, 2.5])
    }

    // MARK: - isGroupingStart

    func testGroupingStartsFirstBar() {
        let meter = Meter.sevenEight // [2,2,3]
        XCTAssertTrue(meter.isGroupingStart(0.0))
        XCTAssertTrue(meter.isGroupingStart(1.0))
        XCTAssertTrue(meter.isGroupingStart(2.0))
        XCTAssertFalse(meter.isGroupingStart(0.5))
        XCTAssertFalse(meter.isGroupingStart(1.5))
        XCTAssertFalse(meter.isGroupingStart(3.0))
    }

    func testGroupingStartsAcrossBars() {
        let meter = Meter.sevenEight // bar length 3.5
        XCTAssertTrue(meter.isGroupingStart(3.5))   // bar 2 downbeat
        XCTAssertTrue(meter.isGroupingStart(4.5))   // bar 2 second group
        XCTAssertTrue(meter.isGroupingStart(5.5))   // bar 2 third group
        XCTAssertFalse(meter.isGroupingStart(4.0))
    }

    // MARK: - Validation

    func testValidMeters() {
        XCTAssertTrue(Meter.fourFour.isValid)
        XCTAssertTrue(Meter.sevenEight.isValid)
        XCTAssertTrue(Meter.elevenSixteen.isValid)
    }

    func testGroupingsMustSumToNumerator() {
        let bad = Meter(numerator: 7, denominator: 8, groupings: [2, 2, 2])
        XCTAssertFalse(bad.isValid)
    }

    func testDenominatorMustBePowerOfTwo() {
        let bad = Meter(numerator: 4, denominator: 3)
        XCTAssertFalse(bad.isValid)
    }

    func testGroupingsMustBePositive() {
        let bad = Meter(numerator: 4, denominator: 4, groupings: [4, 0])
        XCTAssertFalse(bad.isValid)
    }

    // MARK: - Display

    func testDisplayName() {
        XCTAssertEqual(Meter.fourFour.displayName, "4/4")
        XCTAssertEqual(Meter.sevenEight.displayName, "7/8 (2+2+3)")
    }
}
