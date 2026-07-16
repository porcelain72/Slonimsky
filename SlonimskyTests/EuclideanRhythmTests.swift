//
//  EuclideanRhythmTests.swift
//  SlonimskyTests
//
//  Tests for Bjorklund's Euclidean rhythm algorithm.
//

import XCTest
@testable import Slonimsky

final class EuclideanRhythmTests: XCTestCase {

    private func bools(_ s: String) -> [Bool] {
        s.map { $0 == "x" }
    }

    func testTresillo() {
        // E(3,8) — the Cuban tresillo
        XCTAssertEqual(EuclideanRhythm.pattern(hits: 3, steps: 8), bools("x..x..x."))
    }

    func testCinquillo() {
        // E(5,8) — the Cuban cinquillo
        XCTAssertEqual(EuclideanRhythm.pattern(hits: 5, steps: 8), bools("x.xx.xx."))
    }

    func testTwoFive() {
        XCTAssertEqual(EuclideanRhythm.pattern(hits: 2, steps: 5), bools("x.x.."))
    }

    func testAllHits() {
        XCTAssertEqual(EuclideanRhythm.pattern(hits: 4, steps: 4), [true, true, true, true])
    }

    func testZeroHits() {
        XCTAssertEqual(EuclideanRhythm.pattern(hits: 0, steps: 6), Array(repeating: false, count: 6))
    }

    func testHitsClampedToSteps() {
        XCTAssertEqual(EuclideanRhythm.pattern(hits: 10, steps: 4), [true, true, true, true])
    }

    func testHitCountAlwaysMatches() {
        for steps in 1...16 {
            for hits in 0...steps {
                let pattern = EuclideanRhythm.pattern(hits: hits, steps: steps)
                XCTAssertEqual(pattern.count, steps, "E(\(hits),\(steps)) length")
                XCTAssertEqual(pattern.filter { $0 }.count, hits, "E(\(hits),\(steps)) hit count")
            }
        }
    }

    func testRotationShiftsLeftCircularly() {
        let base = EuclideanRhythm.pattern(hits: 3, steps: 8)
        let rotated = EuclideanRhythm.pattern(hits: 3, steps: 8, rotation: 3)
        XCTAssertEqual(rotated, Array(base[3...] + base[..<3]))
    }

    func testRotationByFullCycleIsIdentity() {
        XCTAssertEqual(
            EuclideanRhythm.pattern(hits: 3, steps: 8, rotation: 8),
            EuclideanRhythm.pattern(hits: 3, steps: 8)
        )
    }

    func testNegativeRotationNormalized() {
        XCTAssertEqual(
            EuclideanRhythm.pattern(hits: 3, steps: 8, rotation: -3),
            EuclideanRhythm.pattern(hits: 3, steps: 8, rotation: 5)
        )
    }
}
