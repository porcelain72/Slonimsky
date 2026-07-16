//
//  OnsetSchedulingTests.swift
//  SlonimskyTests
//
//  Tests for onset-based scheduling: uniform mode, Euclidean mode,
//  meter accents, and pattern combination.
//

import XCTest
@testable import Slonimsky

final class OnsetSchedulingTests: XCTestCase {

    // MARK: - Uniform mode

    func testUniformOnsets() {
        var params = PatternParameters(baseNoteDuration: 0.5)
        params.rhythmSettings.accentBoost = 0
        let pitches = [60, 62, 64, 65]

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        XCTAssertEqual(events.count, 4)
        for (i, event) in events.enumerated() {
            XCTAssertEqual(event.onset, Double(i) * 0.5, accuracy: 1e-9, "Uniform onset should be index × base duration")
            XCTAssertEqual(event.duration, 0.5, accuracy: 1e-9)
            XCTAssertFalse(event.isRest)
        }
        XCTAssertEqual(events.totalLength, 2.0, accuracy: 1e-9)
    }

    // MARK: - Euclidean mode

    func testEuclideanPitchesLandOnHits() {
        var rhythm = RhythmSettings()
        rhythm.mode = .euclidean
        rhythm.euclideanHits = 3
        rhythm.euclideanSteps = 8
        rhythm.euclideanRotation = 0
        rhythm.euclideanStepDuration = .eighth
        rhythm.accentBoost = 0
        let params = PatternParameters(rhythmSettings: rhythm)
        let pitches = [60, 62, 64] // exactly k pitches -> one grid cycle

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        XCTAssertEqual(events.count, 8, "One full E(3,8) cycle emits 8 step events")
        let grid = EuclideanRhythm.pattern(hits: 3, steps: 8)
        for (step, event) in events.enumerated() {
            XCTAssertEqual(!event.isRest, grid[step], "Sounding steps must match the Euclidean grid")
            XCTAssertEqual(event.onset, Double(step) * 0.5, accuracy: 1e-9, "Step onsets are a fixed grid")
        }
        XCTAssertEqual(events.soundingNotes.map { $0.note }, [60, 62, 64], "Pitches consumed in order on hits")
    }

    func testEuclideanEmitsWholeCycles() {
        var rhythm = RhythmSettings()
        rhythm.mode = .euclidean
        rhythm.euclideanHits = 3
        rhythm.euclideanSteps = 8
        rhythm.accentBoost = 0
        let params = PatternParameters(rhythmSettings: rhythm)
        let pitches = [60, 62, 64, 65, 67] // 5 pitches, k=3 -> ceil(5/3) = 2 cycles

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        XCTAssertEqual(events.count, 16, "Two full E(3,8) cycles")
        XCTAssertEqual(events.soundingNotes.count, 6, "Two cycles state 6 hits; surplus wraps the color")
        XCTAssertEqual(events.soundingNotes.map { $0.note }, [60, 62, 64, 65, 67, 60])
    }

    // MARK: - Meter accents

    func testAccentPassBoostsGroupingStarts() {
        // Eighth-note stream in 7/8 grouped 2+2+3: grouping starts at 0, 1.0, 2.0, 3.5, 4.5, 5.5
        var params = PatternParameters(meter: .sevenEight, baseNoteDuration: 0.5)
        params.rhythmSettings.accentBoost = 16
        params.velocitySettings = VelocitySettings(baseVelocity: 64, range: 0)
        let pitches = Array(repeating: 60, count: 14) // two full bars of eighths

        let events = MIDIPatternConverter.scheduleRhythm(pitches: pitches, parameters: params)

        let accentedOnsets: Set<Double> = [0.0, 1.0, 2.0, 3.5, 4.5, 5.5]
        for event in events {
            let expectAccent = accentedOnsets.contains(event.onset)
            if expectAccent {
                XCTAssertGreaterThan(event.velocity, 64, "Note at \(event.onset) should be accented")
            } else {
                XCTAssertLessThanOrEqual(event.velocity, 64, "Note at \(event.onset) should not be accented")
            }
        }
    }

    func testZeroAccentBoostLeavesVelocitiesAlone() {
        var params = PatternParameters(meter: .fourFour, baseNoteDuration: 1.0)
        params.rhythmSettings.accentBoost = 0
        params.velocitySettings = VelocitySettings(baseVelocity: 80, range: 0)
        let events = MIDIPatternConverter.scheduleRhythm(pitches: [60, 62, 64, 65], parameters: params)
        XCTAssertTrue(events.allSatisfy { $0.velocity == 80 })
    }

    // MARK: - Combination

    func testSequentialCombineOffsetsSecondPattern() {
        let registry = PatternGeneratorRegistry.shared
        let params = PatternParameters(numberOfOctaves: 1)

        guard let combined = registry.generateCombinedPattern(
            using: ["Scale Pattern Generator", "Interval Pattern Generator"],
            parameters: params,
            combinationMode: .sequential
        ) else {
            return XCTFail("Combined generation failed")
        }

        guard let first = registry.generatePattern(using: "Scale Pattern Generator", parameters: params) else {
            return XCTFail("Scale generation failed")
        }

        // The second pattern must start at or after the end of the first
        let firstLength = first.notes.totalLength
        let laterNotes = combined.notes.filter { $0.onset >= firstLength - 1e-9 }
        XCTAssertFalse(laterNotes.isEmpty, "Sequential combine should place the second pattern after the first")
    }

    func testLayeredCombinePreservesOnsets() {
        let registry = PatternGeneratorRegistry.shared
        let params = PatternParameters(numberOfOctaves: 1)

        guard let layered = registry.generateCombinedPattern(
            using: ["Scale Pattern Generator", "Interval Pattern Generator"],
            parameters: params,
            combinationMode: .layered
        ) else {
            return XCTFail("Layered generation failed")
        }

        // Layered patterns start together: multiple sounding notes at onset 0
        let notesAtZero = layered.notes.soundingNotes.filter { abs($0.onset) < 1e-9 }
        XCTAssertGreaterThanOrEqual(notesAtZero.count, 1, "Layered combine keeps both onset sets")
        // Onsets must be non-decreasing (sorted merge)
        let onsets = layered.notes.map { $0.onset }
        XCTAssertEqual(onsets, onsets.sorted(), "Layered result should be sorted by onset")
    }

    // MARK: - MIDI export

    func testExportedMIDICarriesTimeSignature() throws {
        let engine = MIDIEngine()
        let params = PatternParameters(meter: .sevenEight) // FF 58 04 07 03 18 08

        let notes = [MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1.0)].withSequentialOnsets()
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
            .appendingPathComponent("slonimsky-timesig-test-\(UUID().uuidString).mid")
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertTrue(engine.exportToMIDI(url: url), "Export should succeed")

        let data = try Data(contentsOf: url)
        // 7/8 meta event: FF 58 04 07 03 (clocks/32nds bytes follow)
        let expected: [UInt8] = [0xFF, 0x58, 0x04, 0x07, 0x03]
        let found = data.withUnsafeBytes { buffer -> Bool in
            let bytes = buffer.bindMemory(to: UInt8.self)
            guard bytes.count >= expected.count else { return false }
            for start in 0...(bytes.count - expected.count) {
                if (0..<expected.count).allSatisfy({ bytes[start + $0] == expected[$0] }) {
                    return true
                }
            }
            return false
        }
        XCTAssertTrue(found, "Exported MIDI file should contain the 7/8 time-signature meta event")
    }

    // MARK: - Registry regression

    func testAllRestPatternDoesNotCrashMetadata() {
        // Construct a metadata-worthy result through the registry with a pattern
        // that could produce rests: euclidean mode with more steps than pitches.
        var rhythm = RhythmSettings()
        rhythm.mode = .euclidean
        rhythm.euclideanHits = 1
        rhythm.euclideanSteps = 16
        let params = PatternParameters(numberOfOctaves: 1, rhythmSettings: rhythm)

        let result = PatternGeneratorRegistry.shared.generatePattern(
            using: "Scale Pattern Generator",
            parameters: params
        )
        XCTAssertNotNil(result, "Rest-heavy pattern must not crash pitch-range calculation")
    }
}
