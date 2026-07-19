//
//  CustomMelodyTests.swift
//  SlonimskyTests
//
//  Tests for the custom melody model, generator, and its interaction with
//  the transformation pipeline.
//

import XCTest
@testable import Slonimsky

final class CustomMelodyTests: XCTestCase {

    /// C4 quarter, eighth rest, E4 eighth, G4 half — 4 beats total, 3 sounding.
    private func sampleMelody() -> CustomMelody {
        var melody = CustomMelody()
        melody.isEnabled = true
        melody.notes = [
            MelodyNote(pitch: 60, value: .quarter),
            MelodyNote(pitch: 0, value: .eighth, isRest: true),
            MelodyNote(pitch: 64, value: .eighth),
            MelodyNote(pitch: 67, value: .half)
        ]
        return melody
    }

    private func melodyParameters(_ melody: CustomMelody? = nil) -> PatternParameters {
        var params = PatternParameters(mirror: false, customMelody: melody ?? sampleMelody())
        params.rhythmSettings.accentBoost = 0
        return params
    }

    // MARK: - Model

    func testTotalBeatsAndPitches() {
        let melody = sampleMelody()
        XCTAssertEqual(melody.totalBeats, 4.0, accuracy: 1e-9)
        XCTAssertEqual(melody.pitches, [60, 64, 67])
    }

    func testDerivedTaleaPreservesRests() {
        let talea = sampleMelody().derivedTalea
        XCTAssertEqual(talea.count, 4)
        XCTAssertEqual(talea.map { $0.isRest }, [false, true, false, false])
        XCTAssertEqual(talea.map { $0.value }, [.quarter, .eighth, .eighth, .half])
    }

    func testMaxBeatsFollowsMeterCycle() {
        let melody = CustomMelody()
        XCTAssertEqual(melody.maxBeats(for: .fourFour), 32.0, accuracy: 1e-9, "8 bars of 4/4")
        let mixed = MeterCycle(bars: [.fourFour, .sevenEight]) // 4.0 + 3.5 repeating
        XCTAssertEqual(melody.maxBeats(for: mixed), 30.0, accuracy: 1e-9, "4×4.0 + 4×3.5")
    }

    func testValidation() {
        var melody = CustomMelody()
        melody.isEnabled = true
        XCTAssertFalse(melody.validate(), "Enabled but empty must fail")

        melody.notes = [MelodyNote(pitch: 0, value: .quarter, isRest: true)]
        XCTAssertFalse(melody.validate(), "Enabled with only rests must fail")

        melody.notes.append(MelodyNote(pitch: 200, value: .quarter))
        XCTAssertFalse(melody.validate(), "Out-of-range pitch must fail")

        melody.notes = [MelodyNote(pitch: 60, value: .quarter)]
        XCTAssertTrue(melody.validate())

        melody.isEnabled = false
        melody.notes = []
        XCTAssertTrue(melody.validate(), "Disabled empty melody is fine")
    }

    // MARK: - As-entered playback (uniform mode)

    func testUniformModePlaysMelodyAsEntered() {
        let params = melodyParameters()
        let generator = CustomMelodyPatternGenerator()
        let events = generator.generatePattern(parameters: params, cycleIndex: 0)

        // Verbatim single pass: 4 events, exact onsets/durations, rest preserved
        XCTAssertEqual(events.count, 4, "Untransformed melody plays once, verbatim")

        let expected: [(onset: Double, duration: Double, isRest: Bool, pitch: Int)] = [
            (0.0, 1.0, false, 60),
            (1.0, 0.5, true, 0),
            (1.5, 0.5, false, 64),
            (2.0, 2.0, false, 67)
        ]
        for (event, exp) in zip(events.sorted(by: { $0.onset < $1.onset }), expected) {
            XCTAssertEqual(event.onset, exp.onset, accuracy: 1e-9)
            XCTAssertEqual(event.duration, exp.duration, accuracy: 1e-9)
            XCTAssertEqual(event.isRest, exp.isRest)
            if !exp.isRest {
                XCTAssertEqual(event.note, exp.pitch)
            }
        }
    }

    // MARK: - Pitch-only modes

    func testEuclideanModeUsesMelodyPitches() {
        var params = melodyParameters()
        params.rhythmSettings.mode = .euclidean
        params.rhythmSettings.euclideanHits = 3
        params.rhythmSettings.euclideanSteps = 8
        params.rhythmSettings.euclideanStepDuration = .eighth

        let generator = CustomMelodyPatternGenerator()
        let events = generator.generatePattern(parameters: params, cycleIndex: 0)

        XCTAssertEqual(events.count, 8, "One E(3,8) grid cycle for 3 pitches")
        XCTAssertEqual(events.soundingNotes.map { $0.note }, [60, 64, 67],
                       "Melody pitches consumed in order on the Euclidean hits")
        XCTAssertTrue(events.soundingNotes.allSatisfy { $0.duration == 0.5 },
                      "Euclidean mode re-rhythms the melody at the step duration")
    }

    // MARK: - Transformations

    func testMirrorTransformsMelody() {
        var params = PatternParameters(mirror: true, customMelody: sampleMelody())
        params.rhythmSettings.accentBoost = 0

        let generator = CustomMelodyPatternGenerator()
        let pitches = generator.generateNotePattern(parameters: params, cycleIndex: 0)

        XCTAssertEqual(pitches, [60, 64, 67, 64, 60], "Mirror appends the inverted melody")
    }

    func testPhasingOnMelodyProducesTwoVoices() {
        var params = melodyParameters()
        params.phasingSettings.mode = .discrete
        params.phasingSettings.stepsPerCycle = 1

        guard let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Custom Melody Generator"
        ) else {
            return XCTFail("Generation failed")
        }

        XCTAssertTrue(result.metadata.isCyclicalSequence)
        XCTAssertEqual(Set(result.notes.soundingNotes.map { $0.voice }), [0, 1],
                       "The entered melody phases against itself")
    }

    func testAdditiveProcessGrowsMelody() {
        var params = melodyParameters()
        params.processSettings.mode = .additive
        params.processSettings.startCount = 1
        params.processSettings.notesPerCycle = 1

        guard let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Custom Melody Generator"
        ) else {
            return XCTFail("Generation failed")
        }

        XCTAssertEqual(result.metadata.totalCycles, 3, "3 sounding notes → 3 additive cycles")
        let cycle0 = result.notes.filter { $0.cycleIndex == 0 }
        XCTAssertEqual(cycle0.soundingNotes.count, 1, "Additive cycle 0 keeps one melody note")
    }

    // MARK: - Generator selection & validation

    func testEnablingMelodySwapsBaseGenerator() {
        let manager = ParameterManager()
        XCTAssertTrue(manager.determineActiveGenerators().contains("Scale Pattern Generator"))

        manager.customMelody = sampleMelody()
        let generators = manager.determineActiveGenerators()
        XCTAssertTrue(generators.contains("Custom Melody Generator"))
        XCTAssertFalse(generators.contains("Scale Pattern Generator"),
                       "The melody replaces the scale generator as base")
    }

    func testGeneratorRejectsEmptyMelody() {
        let generator = CustomMelodyPatternGenerator()
        let params = PatternParameters() // melody disabled/empty
        XCTAssertFalse(generator.validateParameters(parameters: params))
    }
}
