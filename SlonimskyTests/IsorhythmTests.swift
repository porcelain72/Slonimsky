//
//  IsorhythmTests.swift
//  SlonimskyTests
//
//  Tests for the isorhythm (talea/color) mode of the rhythm engine.
//

import XCTest
@testable import Slonimsky

final class IsorhythmTests: XCTestCase {

    private func isorhythmParameters(talea: [TaleaEntry], accentBoost: Int = 0) -> PatternParameters {
        var rhythm = RhythmSettings()
        rhythm.mode = .isorhythm
        rhythm.talea = talea
        rhythm.accentBoost = accentBoost
        return PatternParameters(rhythmSettings: rhythm)
    }

    func testColorAndTaleaRealign() {
        // 7 pitches against a 5-note talea (no rests): realigns after 35 events
        let pitches = [60, 62, 64, 65, 67, 69, 71]
        let talea = [TaleaEntry(value: .quarter), TaleaEntry(value: .eighth), TaleaEntry(value: .eighth),
                     TaleaEntry(value: .quarter), TaleaEntry(value: .sixteenth)]
        let params = isorhythmParameters(talea: talea)

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        XCTAssertEqual(events.count, 35, "lcm(7, 5) = 35 events until realignment")
        XCTAssertEqual(events.soundingNotes.count, 35, "No rests in this talea")
        // Pitch sequence must be the color repeated
        for (i, event) in events.enumerated() {
            XCTAssertEqual(event.note, pitches[i % pitches.count], "Pitch \(i) should follow the color cycle")
        }
    }

    func testRestsAdvanceTimeWithoutConsumingPitches() {
        let pitches = [60, 64, 67]
        let talea = [TaleaEntry(value: .quarter),
                     TaleaEntry(value: .eighth, isRest: true),
                     TaleaEntry(value: .quarter)]
        let params = isorhythmParameters(talea: talea)

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        // 2 note entries per talea cycle, color of 3: realigns after 3/gcd(2,3) = 3 talea cycles = 9 events
        XCTAssertEqual(events.count, 9)
        XCTAssertEqual(events.filter { $0.isRest }.count, 3, "One rest per talea cycle")

        // Sounding pitches must be the color repeated, uninterrupted by rests
        let soundingPitches = events.soundingNotes.map { $0.note }
        XCTAssertEqual(soundingPitches, [60, 64, 67, 60, 64, 67])

        // Onsets are the prefix sums of the talea durations: 1.0, 0.5, 1.0 repeating
        let expectedOnsets = [0.0, 1.0, 1.5, 2.5, 3.5, 4.0, 5.0, 6.0, 6.5]
        for (event, expected) in zip(events, expectedOnsets) {
            XCTAssertEqual(event.onset, expected, accuracy: 1e-9)
        }
    }

    func testEventCapRespected() {
        // 101 pitches against a 3-note talea: lcm would be 101 * 3 = 303 talea cycles...
        // (101 and 3 are coprime) -> 101 cycles of 3 entries = 303 events; use bigger primes to exceed cap
        let pitches = Array(0..<127).map { 30 + ($0 % 60) } // 127 pitches (prime count)
        let talea = Array(repeating: TaleaEntry(value: .sixteenth), count: 11) // 11 note entries (coprime with 127)
        let params = isorhythmParameters(talea: talea)

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        // 127/gcd(11,127) = 127 talea cycles * 11 = 1397 > cap
        XCTAssertEqual(events.count, MIDIPatternConverter.isorhythmEventCap, "Event count should be capped")
    }

    func testAllRestTaleaFallsBackToUniform() {
        let pitches = [60, 62, 64]
        let talea = [TaleaEntry(value: .quarter, isRest: true), TaleaEntry(value: .eighth, isRest: true)]
        let params = isorhythmParameters(talea: talea)

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        XCTAssertEqual(events.count, 3, "Should fall back to uniform: one event per pitch")
        XCTAssertTrue(events.allSatisfy { !$0.isRest }, "Uniform fallback has no rests")
    }

    func testEqualLengthColorAndTaleaRealignImmediately() {
        let pitches = [60, 62, 64, 65]
        let talea = [TaleaEntry(value: .quarter), TaleaEntry(value: .eighth),
                     TaleaEntry(value: .eighth), TaleaEntry(value: .quarter)]
        let params = isorhythmParameters(talea: talea)

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        XCTAssertEqual(events.count, 4, "Equal lengths realign after one cycle")
    }
}
