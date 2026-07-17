//
//  MeterCycleTests.swift
//  SlonimskyTests
//
//  Tests for MeterCycle: repeating bar sequences with different time signatures.
//

import XCTest
@testable import Slonimsky

final class MeterCycleTests: XCTestCase {

    // 4/4 (4.0 beats) then 7/8 [2,2,3] (3.5 beats): cycle of 7.5 beats
    private let mixedCycle = MeterCycle(bars: [.fourFour, .sevenEight])

    func testTotalBeats() {
        XCTAssertEqual(mixedCycle.totalBeats, 7.5, accuracy: 1e-9)
        XCTAssertEqual(MeterCycle.fourFour.totalBeats, 4.0, accuracy: 1e-9)
    }

    func testEmptyBarsFallsBackToFourFour() {
        let cycle = MeterCycle(bars: [])
        XCTAssertEqual(cycle.bars, [.fourFour], "Empty init must never produce an empty cycle")
    }

    func testBarResolution() {
        // Onset 2.0 falls in the 4/4 bar starting at 0
        let (meter0, start0) = mixedCycle.bar(at: 2.0)
        XCTAssertEqual(meter0, .fourFour)
        XCTAssertEqual(start0, 0.0, accuracy: 1e-9)

        // Onset 4.0 is the downbeat of the 7/8 bar
        let (meter1, start1) = mixedCycle.bar(at: 4.0)
        XCTAssertEqual(meter1, .sevenEight)
        XCTAssertEqual(start1, 4.0, accuracy: 1e-9)

        // Onset 7.5 wraps into the second cycle's 4/4 bar
        let (meter2, start2) = mixedCycle.bar(at: 7.5)
        XCTAssertEqual(meter2, .fourFour)
        XCTAssertEqual(start2, 7.5, accuracy: 1e-9)

        // Onset 12.0 falls in the second cycle's 7/8 bar (starts at 11.5)
        let (meter3, start3) = mixedCycle.bar(at: 12.0)
        XCTAssertEqual(meter3, .sevenEight)
        XCTAssertEqual(start3, 11.5, accuracy: 1e-9)
    }

    func testGroupingStartsAcrossBarBoundary() {
        // 4/4 bar: grouping starts at 0, 1, 2, 3 (all-ones grouping)
        XCTAssertTrue(mixedCycle.isGroupingStart(0.0))
        XCTAssertTrue(mixedCycle.isGroupingStart(3.0))
        XCTAssertFalse(mixedCycle.isGroupingStart(3.5))

        // 7/8 [2,2,3] bar starting at 4.0: grouping starts at 4.0, 5.0, 6.0
        XCTAssertTrue(mixedCycle.isGroupingStart(4.0))
        XCTAssertTrue(mixedCycle.isGroupingStart(5.0))
        XCTAssertTrue(mixedCycle.isGroupingStart(6.0))
        XCTAssertFalse(mixedCycle.isGroupingStart(6.5))
        XCTAssertFalse(mixedCycle.isGroupingStart(7.0))

        // Second cycle repeats the grid shifted by 7.5
        XCTAssertTrue(mixedCycle.isGroupingStart(7.5))
        XCTAssertTrue(mixedCycle.isGroupingStart(11.5))
        XCTAssertTrue(mixedCycle.isGroupingStart(12.5))
    }

    func testBarStartsRepeatTheCycle() {
        let starts = mixedCycle.barStarts(upTo: 16.0)
        let onsets = starts.map { $0.onset }
        let expected = [0.0, 4.0, 7.5, 11.5, 15.0]
        XCTAssertEqual(onsets.count, expected.count)
        for (actual, exp) in zip(onsets, expected) {
            XCTAssertEqual(actual, exp, accuracy: 1e-9)
        }
        XCTAssertEqual(starts[0].meter, .fourFour)
        XCTAssertEqual(starts[1].meter, .sevenEight)
        XCTAssertEqual(starts[2].meter, .fourFour)
    }

    func testAccentPassUsesMeterCycle() {
        // Quarter-note stream over [4/4, 7/8]: accents at 0,1,2,3 (4/4 all-ones),
        // then 4.0, 5.0, 6.0 (7/8 groupings) but NOT 7.0 (mid-group in 7/8)
        var params = PatternParameters(meterCycle: MeterCycle(bars: [.fourFour, .sevenEight]), baseNoteDuration: 1.0)
        params.rhythmSettings.accentBoost = 16
        params.velocitySettings = VelocitySettings(baseVelocity: 64, range: 0)
        let pitches = Array(repeating: 60, count: 8) // onsets 0...7

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        let accented = events.filter { $0.velocity > 64 }.map { $0.onset }
        XCTAssertEqual(accented, [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0], "Onset 7.0 sits mid-group in the 7/8 bar")
    }

    func testValidation() {
        XCTAssertTrue(mixedCycle.isValid)
        var tooMany = MeterCycle(bars: Array(repeating: Meter.fourFour, count: 9))
        XCTAssertFalse(tooMany.isValid)
        tooMany.bars = [Meter(numerator: 7, denominator: 8, groupings: [2, 2, 2])]
        XCTAssertFalse(tooMany.isValid, "Invalid bar invalidates the cycle")
    }

    func testDisplayName() {
        XCTAssertEqual(mixedCycle.displayName, "4/4 | 7/8 (2+2+3)")
        XCTAssertEqual(MeterCycle.fourFour.displayName, "4/4")
    }

    func testExportedMIDICarriesMeterChanges() throws {
        let engine = MIDIEngine()
        let params = PatternParameters(meterCycle: mixedCycle)

        // Two full meter cycles of quarter notes (15 beats)
        let notes = (0..<15).map { MIDIInfo(note: 60, velocity: 80, onset: Double($0), duration: 1.0) }
        let metadata = PatternMetadata(
            generatorName: "Test",
            parameterHash: "test",
            generationTime: 0.001,
            noteCount: notes.count,
            pitchRange: 60...60,
            duration: notes.totalLength
        )
        let result = PatternGenerationResult(
            notes: notes,
            metadata: metadata,
            performance: PerformanceMetrics(generationTime: 0.001, memoryUsage: 0, complexity: 1.0)
        )

        XCTAssertNotNil(engine.generateMusicSequence(from: result, parameters: params))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("slonimsky-metercycle-test-\(UUID().uuidString).mid")
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertTrue(engine.exportToMIDI(url: url), "Export should succeed")

        let data = try Data(contentsOf: url)
        func contains(_ pattern: [UInt8]) -> Bool {
            data.withUnsafeBytes { buffer in
                let bytes = buffer.bindMemory(to: UInt8.self)
                guard bytes.count >= pattern.count else { return false }
                for start in 0...(bytes.count - pattern.count) {
                    if (0..<pattern.count).allSatisfy({ bytes[start + $0] == pattern[$0] }) {
                        return true
                    }
                }
                return false
            }
        }

        XCTAssertTrue(contains([0xFF, 0x58, 0x04, 0x04, 0x02]), "Export should contain the 4/4 meta event")
        XCTAssertTrue(contains([0xFF, 0x58, 0x04, 0x07, 0x03]), "Export should contain the 7/8 meta event")
    }

    func testSingleMeterCompatibilityAccessor() {
        let params = PatternParameters(meter: .sevenEight)
        XCTAssertEqual(params.meter, .sevenEight, "meter: init label still works")
        XCTAssertEqual(params.meterCycle.bars, [.sevenEight])

        let cycled = PatternParameters(meterCycle: mixedCycle)
        XCTAssertEqual(cycled.meter, .fourFour, "meter accessor reads the first bar")
    }
}
