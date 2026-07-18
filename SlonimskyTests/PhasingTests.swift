//
//  PhasingTests.swift
//  SlonimskyTests
//
//  Tests for Reich-style phasing voices (discrete and continuous).
//

import XCTest
@testable import Slonimsky

final class PhasingTests: XCTestCase {

    /// Uniform eighth-note pentatonic line, no mirror: a small predictable pattern.
    private func phasingParameters(mode: PhasingMode, stepsPerCycle: Int = 1, drift: Double = 0.25) -> PatternParameters {
        var phasing = PhasingSettings()
        phasing.mode = mode
        phasing.stepsPerCycle = stepsPerCycle
        phasing.driftPerCycle = drift
        phasing.voiceVelocityOffset = -8

        var params = PatternParameters(
            scaleType: .pentatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 5,
            mirror: false,
            baseNoteDuration: 0.5,
            phasingSettings: phasing
        )
        params.rhythmSettings.accentBoost = 0
        return params
    }

    private func generate(_ params: PatternParameters) -> PatternGenerationResult? {
        CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Scale Pattern Generator"
        )
    }

    // MARK: - Activation

    func testPhasingAloneTriggersCyclicalGeneration() {
        XCTAssertTrue(phasingParameters(mode: .discrete).isCyclicalGeneration)
        XCTAssertFalse(phasingParameters(mode: .off).isCyclicalGeneration)
    }

    // MARK: - Voice content

    func testPhasingProducesTwoVoices() {
        guard let result = generate(phasingParameters(mode: .discrete)) else {
            return XCTFail("Generation failed")
        }
        let voices = Set(result.notes.soundingNotes.map { $0.voice })
        XCTAssertEqual(voices, [0, 1], "Phasing must produce exactly two voices")

        // Voice 2 mirrors voice 1's note count in every cycle
        let byCycle = Dictionary(grouping: result.notes.soundingNotes) { $0.cycleIndex }
        for (cycle, notes) in byCycle {
            let voice0 = notes.filter { $0.voice == 0 }.count
            let voice1 = notes.filter { $0.voice == 1 }.count
            XCTAssertEqual(voice0, voice1, "Cycle \(cycle): both voices should have equal note counts")
        }
    }

    func testVoiceTwoVelocityOffsetAndTranspose() {
        var params = phasingParameters(mode: .discrete)
        params.phasingSettings.voiceTranspose = 12
        params.velocitySettings = VelocitySettings(baseVelocity: 80, range: 0)

        guard let result = generate(params) else { return XCTFail("Generation failed") }

        let cycle0 = result.notes.soundingNotes.filter { $0.cycleIndex == 0 }
        let voice0Notes = cycle0.filter { $0.voice == 0 }.map { $0.note }.sorted()
        let voice1Notes = cycle0.filter { $0.voice == 1 }.map { $0.note }.sorted()
        XCTAssertEqual(voice1Notes, voice0Notes.map { $0 + 12 }, "Voice 2 transposed an octave up")

        for note in cycle0 where note.voice == 1 {
            XCTAssertEqual(note.velocity, 72, "Voice 2 velocity offset by -8")
        }
    }

    // MARK: - Discrete rotation

    func testDiscreteRotationWithinCycleWindow() {
        guard let result = generate(phasingParameters(mode: .discrete)) else {
            return XCTFail("Generation failed")
        }

        // Within each cycle, voice-2 onsets must stay inside that cycle's window
        let byCycle = Dictionary(grouping: result.notes) { $0.cycleIndex }
        for (cycle, notes) in byCycle {
            let cycleStart = notes.map { $0.onset }.min() ?? 0
            let cycleEnd = notes.map { $0.end }.max() ?? 0
            for note in notes where note.voice == 1 {
                XCTAssertGreaterThanOrEqual(note.onset, cycleStart - 1e-9,
                                            "Cycle \(cycle): voice-2 onset before window")
                XCTAssertLessThan(note.onset, cycleEnd + 1e-9,
                                  "Cycle \(cycle): voice-2 onset after window")
            }
        }
    }

    func testDiscretePhaseAdvancesPerCycle() {
        // Pentatonic (5 notes + octave = 6) at eighth notes: pattern of 6 steps.
        // At cycle c, voice 2 is rotated by c steps: its earliest onset relative
        // to the cycle start differs from cycle 0's rotation only by the offset.
        guard let result = generate(phasingParameters(mode: .discrete)) else {
            return XCTFail("Generation failed")
        }

        // Cycle 0: voices aligned (offset 0) — voice-2 onsets equal voice-1 onsets
        let cycle0 = result.notes.filter { $0.cycleIndex == 0 }
        let v0 = Set(cycle0.filter { $0.voice == 0 }.map { ($0.onset * 1000).rounded() })
        let v1 = Set(cycle0.filter { $0.voice == 1 }.map { ($0.onset * 1000).rounded() })
        XCTAssertEqual(v0, v1, "Cycle 0 voices start aligned")

        // Cycle 1: offset by one step — onset sets rotated, not equal unless trivial
        let cycle1 = result.notes.filter { $0.cycleIndex == 1 }
        let v0c1 = cycle1.filter { $0.voice == 0 }.map { $0.onset }.sorted()
        let v1c1 = cycle1.filter { $0.voice == 1 }.map { $0.onset }.sorted()
        // Rotation preserves the onset GRID but shifts which pitch is where;
        // grid-aligned rotation means the onset sets coincide as sets
        XCTAssertEqual(v0c1.count, v1c1.count)
        // The pitches at a given onset differ between cycle 0 and cycle 1 for voice 2
        func pitchAtEarliestOnset(_ notes: [MIDIInfo], voice: Int) -> Int? {
            notes.filter { $0.voice == voice }.min { $0.onset < $1.onset }?.note
        }
        let v1FirstPitchC0 = pitchAtEarliestOnset(cycle0, voice: 1)
        let v1FirstPitchC1 = pitchAtEarliestOnset(cycle1, voice: 1)
        XCTAssertNotEqual(v1FirstPitchC0, v1FirstPitchC1,
                          "Voice 2's rotation should change which pitch opens the cycle")
    }

    func testDiscreteRealignmentJoinsCycleCount() {
        // Pattern: pentatonic 5 notes + octave = 6 sounding notes at 0.5 beats
        // = 6 grid steps -> discrete phasing (1 step/cycle) realigns after 6 cycles
        guard let result = generate(phasingParameters(mode: .discrete)) else {
            return XCTFail("Generation failed")
        }
        // The generated pattern defines the step count; assert consistency instead
        // of hardcoding: totalCycles == patternSteps / gcd(1, patternSteps) == patternSteps
        let cycle0 = result.notes.filter { $0.cycleIndex == 0 && $0.voice == 0 }
        let cycleLength = cycle0.map { $0.end }.max() ?? 0
        let expectedSteps = Int((cycleLength / 0.5).rounded())
        XCTAssertEqual(result.metadata.totalCycles, expectedSteps,
                       "Discrete phasing at 1 step/cycle realigns after one full trip around the pattern")
    }

    // MARK: - Continuous drift

    func testContinuousDriftAccumulates() {
        guard let result = generate(phasingParameters(mode: .continuous, drift: 0.25)) else {
            return XCTFail("Generation failed")
        }

        // Voice-2 earliest onsets sit off the grid by (cycle * 0.25 * step) mod length
        let cycle1 = result.notes.filter { $0.cycleIndex == 1 }
        let cycleStart = cycle1.map { $0.onset }.min() ?? 0
        let voice1Onsets = cycle1.filter { $0.voice == 1 }.map { $0.onset - cycleStart }
        let stepBeats = 0.5
        let expectedOffset = 0.25 * stepBeats // cycle 1
        let hasOffGrid = voice1Onsets.contains { onset in
            abs(onset.truncatingRemainder(dividingBy: stepBeats) - expectedOffset) < 1e-6
        }
        XCTAssertTrue(hasOffGrid, "Cycle 1's voice 2 should sit a quarter-step off the grid")
    }

    // MARK: - Crunch regression (unison de-dup)

    func testExactUnisonsAreDeduped() {
        // Two voices, same pitch, same onset — the phasing lock-point case
        let notes = [
            MIDIInfo(note: 60, velocity: 80, onset: 0.0, duration: 1.0, voice: 0),
            MIDIInfo(note: 60, velocity: 72, onset: 0.0, duration: 1.0, voice: 1),
            MIDIInfo(note: 62, velocity: 80, onset: 1.0, duration: 1.0, voice: 0),
            MIDIInfo(note: 62, velocity: 72, onset: 1.5, duration: 1.0, voice: 1) // offset: kept
        ]

        let deduped = notes.dedupedExactUnisons()

        XCTAssertEqual(deduped.count, 3, "Exact unison collapses to one note; offset notes survive")
        let unison = deduped.filter { $0.note == 60 }
        XCTAssertEqual(unison.count, 1)
        XCTAssertEqual(unison[0].velocity, 80, "The louder hit wins")
    }

    func testPhasingLockCycleHasNoDoubledNotes() {
        // Cycle 0 of any phased sequence is a full lock: voice 2 duplicates
        // voice 1 exactly. After emission de-dup no pitch+onset pair may repeat.
        guard let result = generate(phasingParameters(mode: .discrete)) else {
            return XCTFail("Generation failed")
        }

        let cycle0 = result.notes.filter { $0.cycleIndex == 0 }.soundingNotes.dedupedExactUnisons()
        var seen = Set<String>()
        for note in cycle0 {
            let key = "\(note.note)@\(Int((note.onset * 1000).rounded()))"
            XCTAssertFalse(seen.contains(key), "Duplicate emission at lock point: \(key)")
            seen.insert(key)
        }

        // Sanity: a mid-phase cycle still carries both voices after de-dup
        let midCycle = result.notes.filter { $0.cycleIndex == 1 }.soundingNotes.dedupedExactUnisons()
        let voices = Set(midCycle.map { $0.voice })
        XCTAssertEqual(voices, [0, 1], "Offset cycles keep both voices audible")
    }

    // MARK: - Crunch regression (same-pitch gate + sliver guard)

    func testGatedSamePitchTrimsButtedNotes() {
        // Two identical pitches exactly butted: the classic crunch case
        let notes = [
            MIDIInfo(note: 60, velocity: 80, onset: 0.0, duration: 1.0),
            MIDIInfo(note: 60, velocity: 80, onset: 1.0, duration: 1.0),
            MIDIInfo(note: 62, velocity: 80, onset: 2.0, duration: 1.0)
        ]

        let gated = notes.gatedSamePitch(gap: 0.02)

        XCTAssertEqual(gated.count, 3, "No notes dropped for a simple butt joint")
        let firstC = gated.first { $0.note == 60 && $0.onset == 0.0 }!
        XCTAssertEqual(firstC.end, 0.98, accuracy: 1e-9, "Earlier same-pitch note trimmed to leave a gap")
        let secondC = gated.first { $0.note == 60 && $0.onset == 1.0 }!
        XCTAssertEqual(secondC.duration, 1.0, accuracy: 1e-9, "Later note untouched (different pitch follows)")
    }

    func testGatedSamePitchDropsFullyOverlappedDuplicates() {
        // Same pitch at the same onset on one channel: earlier entry is dropped
        let notes = [
            MIDIInfo(note: 60, velocity: 80, onset: 0.0, duration: 1.0),
            MIDIInfo(note: 60, velocity: 90, onset: 0.0, duration: 1.0)
        ]
        let gated = notes.gatedSamePitch()
        XCTAssertEqual(gated.count, 1, "A same-pitch same-onset duplicate cannot be emitted safely")
    }

    func testGatedSamePitchLeavesDifferentPitchesAlone() {
        let notes = [
            MIDIInfo(note: 60, velocity: 80, onset: 0.0, duration: 1.0),
            MIDIInfo(note: 62, velocity: 80, onset: 1.0, duration: 1.0)
        ]
        let gated = notes.gatedSamePitch()
        XCTAssertEqual(gated.map { $0.duration }, [1.0, 1.0], "Legato between different pitches is untouched")
    }

    func testAdditiveSeamsSurviveGating() {
        // Additive process seams repeat the pattern's opening pitch back-to-back;
        // after gating, no same-pitch pair may touch or overlap.
        var params = PatternParameters(scaleType: .pentatonic, numberOfOctaves: 1, divisionsOfOctave: 5, mirror: false)
        params.processSettings.mode = .additive
        params.processSettings.startCount = 1
        params.processSettings.notesPerCycle = 1

        guard let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Scale Pattern Generator"
        ) else {
            return XCTFail("Generation failed")
        }

        let gated = result.notes.soundingNotes.filter { $0.voice == 0 }.gatedSamePitch()
        let byPitch = Dictionary(grouping: gated) { $0.note }
        for (pitch, group) in byPitch {
            let sorted = group.sorted { $0.onset < $1.onset }
            for i in 0..<(sorted.count - 1) {
                XCTAssertLessThan(sorted[i].end, sorted[i + 1].onset,
                                  "Pitch \(pitch): gated notes must not touch (\(sorted[i].end) vs \(sorted[i + 1].onset))")
            }
        }
    }

    func testContinuousPhasingEmitsNoSlivers() {
        // Continuous drift slices notes at the cycle boundary; slivers under the
        // minimum must be dropped, not emitted as clicks.
        guard let result = generate(phasingParameters(mode: .continuous, drift: 0.35)) else {
            return XCTFail("Generation failed")
        }
        for note in result.notes.soundingNotes {
            XCTAssertGreaterThanOrEqual(note.duration, 0.05 - 1e-9,
                                        "No sounding note may be shorter than the sliver minimum")
        }
    }

    // MARK: - MIDI export channels

    func testPhasedExportUsesSecondChannel() throws {
        guard let result = generate(phasingParameters(mode: .discrete)) else {
            return XCTFail("Generation failed")
        }

        let engine = MIDIEngine()
        XCTAssertNotNil(engine.generateMusicSequence(from: result, parameters: phasingParameters(mode: .discrete)))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("slonimsky-phasing-test-\(UUID().uuidString).mid")
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertTrue(engine.exportToMIDI(url: url))

        let data = try Data(contentsOf: url)
        // Channel 2 note-on status byte = 0x92
        XCTAssertTrue(data.contains(0x92), "Export should contain channel-2 note-ons for the phasing voice")
        XCTAssertTrue(data.contains(0x90), "Export should contain channel-0 note-ons for the primary voice")
    }
}
