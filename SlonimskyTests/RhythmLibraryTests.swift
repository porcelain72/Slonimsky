//
//  RhythmLibraryTests.swift
//  SlonimskyTests
//
//  Tests for the built-in rhythm catalog, its GM drum mapping, and the
//  generator that turns a rhythm into MIDI.
//

import XCTest
@testable import Slonimsky

final class RhythmLibraryTests: XCTestCase {

    // MARK: - Catalog integrity

    func testEveryPatternIsValid() {
        XCTAssertGreaterThanOrEqual(RhythmLibrary.patterns.count, 30,
                                    "The library should offer a wide variety of rhythms")
        for pattern in RhythmLibrary.patterns {
            XCTAssertTrue(pattern.isValid, "Invalid pattern: \(pattern.name)")
            XCTAssertTrue(pattern.meter.isValid, "\(pattern.name): invalid meter")
            XCTAssertFalse(pattern.note.isEmpty, "\(pattern.name): missing description")
            XCTAssertFalse(pattern.voicesUsed.isEmpty, "\(pattern.name): no lanes")
            for hit in pattern.hits {
                XCTAssertTrue((0..<pattern.totalSteps).contains(hit.step),
                              "\(pattern.name): hit at step \(hit.step) outside 0..<\(pattern.totalSteps)")
            }
        }
    }

    func testPatternNamesAreUnique() {
        let names = RhythmLibrary.patterns.map { $0.name }
        XCTAssertEqual(Set(names).count, names.count, "Pattern names must be unique — they are the stored id")
    }

    func testFamiliesAndMetersAreDiscoverable() {
        XCTAssertGreaterThanOrEqual(RhythmLibrary.families.count, 6, "Expect a broad spread of families")
        XCTAssertGreaterThanOrEqual(RhythmLibrary.meters.count, 5, "Expect several time signatures")
        for family in RhythmLibrary.families {
            XCTAssertFalse(RhythmLibrary.patterns.filter { $0.family == family }.isEmpty)
        }
    }

    func testStepGridMatchesMeter() {
        for pattern in RhythmLibrary.patterns {
            // One bar of steps must add up to exactly one bar of beats
            let barBeats = Double(pattern.stepsPerBar) * pattern.stepBeats
            XCTAssertEqual(barBeats, pattern.meter.beatsPerBar, accuracy: 1e-9,
                           "\(pattern.name): step grid does not fill the bar")
        }
    }

    // MARK: - General MIDI mapping

    func testGeneralMIDINoteNumbers() {
        XCTAssertEqual(DrumVoice.kick.midiNote, 36)
        XCTAssertEqual(DrumVoice.snare.midiNote, 38)
        XCTAssertEqual(DrumVoice.closedHat.midiNote, 42)
        XCTAssertEqual(DrumVoice.openHat.midiNote, 46)
        XCTAssertEqual(DrumVoice.ride.midiNote, 51)
        XCTAssertEqual(DrumVoice.cowbell.midiNote, 56)
        XCTAssertEqual(DrumVoice.claves.midiNote, 75)

        for voice in DrumVoice.allCases {
            XCTAssertTrue((35...81).contains(voice.midiNote) || voice.midiNote == 82,
                          "\(voice.displayName) should sit in the GM percussion range")
        }
    }

    // MARK: - Canonical grooves

    func testFourOnTheFloorKicksOnEveryBeat() {
        guard let pattern = RhythmLibrary.pattern(named: "Four on the Floor") else {
            return XCTFail("Missing pattern")
        }
        let kickSteps = pattern.hits.filter { $0.voice == .kick }.map { $0.step }.sorted()
        XCTAssertEqual(kickSteps, [0, 4, 8, 12])
        // …which is one kick per quarter-note beat
        XCTAssertEqual(kickSteps.map { Double($0) * pattern.stepBeats }, [0.0, 1.0, 2.0, 3.0])
    }

    func testSonClaveThreeTwoPositions() {
        guard let pattern = RhythmLibrary.pattern(named: "Son Clave 3-2") else {
            return XCTFail("Missing pattern")
        }
        let steps = pattern.hits.filter { $0.voice == .claves }.map { $0.step }.sorted()
        XCTAssertEqual(steps, [0, 3, 6, 10, 12], "Canonical 3-2 son clave in sixteenths")
    }

    func testTresilloMatchesEuclideanThreeEight() {
        guard let pattern = RhythmLibrary.pattern(named: "Tresillo") else {
            return XCTFail("Missing pattern")
        }
        let steps = pattern.hits.filter { $0.voice == .claves }.map { $0.step }.sorted()
        let euclidean = EuclideanRhythm.pattern(hits: 3, steps: 8)
            .enumerated().filter { $0.element }.map { $0.offset }
        XCTAssertEqual(steps, euclidean, "Tresillo is E(3,8)")
    }

    // MARK: - Drum output

    private func drumParameters(_ name: String) -> PatternParameters {
        var settings = RhythmLibrarySettings()
        settings.isEnabled = true
        settings.patternName = name
        settings.output = .drumKit
        var params = PatternParameters(mirror: false, rhythmLibrary: settings)
        params.velocitySettings = VelocitySettings(baseVelocity: 80, range: 0)
        return params
    }

    func testDrumOutputPlacesGMNotesOnTheGrid() {
        let params = drumParameters("Four on the Floor")
        let events = RhythmLibraryPatternGenerator().generatePattern(parameters: params, cycleIndex: 0)

        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.allSatisfy { $0.isPercussion }, "Drum output must be flagged as percussion")

        let kicks = events.filter { $0.note == DrumVoice.kick.midiNote }.map { $0.onset }.sorted()
        XCTAssertEqual(kicks, [0.0, 1.0, 2.0, 3.0], "Kick lands on every beat")
    }

    func testAccentsRaiseVelocity() {
        let params = drumParameters("Basic Rock")
        let events = RhythmLibraryPatternGenerator().generatePattern(parameters: params, cycleIndex: 0)

        let snares = events.filter { $0.note == DrumVoice.snare.midiNote }
        let hats = events.filter { $0.note == DrumVoice.closedHat.midiNote }
        XCTAssertFalse(snares.isEmpty)
        XCTAssertFalse(hats.isEmpty)
        // Snares are written as accents in Basic Rock, hats are not
        XCTAssertTrue(snares.allSatisfy { $0.velocity > 80 }, "Accented hits get the boost")
        XCTAssertTrue(hats.allSatisfy { $0.velocity == 80 }, "Unaccented hits keep the base velocity")
    }

    func testMutingALaneRemovesIt() {
        var params = drumParameters("Basic Rock")
        params.rhythmLibrary.mutedVoices = [.closedHat]
        let events = RhythmLibraryPatternGenerator().generatePattern(parameters: params, cycleIndex: 0)

        XCTAssertTrue(events.allSatisfy { $0.note != DrumVoice.closedHat.midiNote },
                      "Muted lanes must not sound")
        XCTAssertFalse(events.isEmpty, "Other lanes still play")
    }

    func testRotationShiftsTheGrooveCircularly() {
        var params = drumParameters("Four on the Floor")
        params.rhythmLibrary.rotationSteps = 2
        let events = RhythmLibraryPatternGenerator().generatePattern(parameters: params, cycleIndex: 0)

        let kicks = events.filter { $0.note == DrumVoice.kick.midiNote }.map { $0.onset }.sorted()
        XCTAssertEqual(kicks, [0.5, 1.5, 2.5, 3.5], "Two sixteenths later, wrapping inside the bar")
    }

    // MARK: - Pitched output

    func testPitchedOutputUsesRhythmGridAndScalePitches() {
        var params = drumParameters("Son Clave 3-2")
        params.rhythmLibrary.output = .pitched

        let events = RhythmLibraryPatternGenerator().generatePattern(parameters: params, cycleIndex: 0)

        XCTAssertEqual(events.count, 5, "One note per clave stroke")
        XCTAssertTrue(events.allSatisfy { !$0.isPercussion }, "Pitched output is not percussion")
        XCTAssertEqual(events.map { $0.onset }.sorted(), [0.0, 0.75, 1.5, 2.5, 3.0],
                       "Onsets follow the clave grid")
        XCTAssertTrue(events.allSatisfy { $0.note >= 0 && $0.note <= 127 })
    }

    func testPitchedOutputPrefersTheCustomMelody() {
        var params = drumParameters("Tresillo")
        params.rhythmLibrary.output = .pitched
        var melody = CustomMelody()
        melody.isEnabled = true
        melody.notes = [
            MelodyNote(pitch: 60, value: .quarter),
            MelodyNote(pitch: 67, value: .quarter)
        ]
        params.customMelody = melody

        let events = RhythmLibraryPatternGenerator().generatePattern(parameters: params, cycleIndex: 0)
        XCTAssertEqual(events.map { $0.note }, [60, 67, 60], "Melody pitches cycle over the rhythm's onsets")
    }

    // MARK: - Roles and transformations

    func testSourceRoleReplacesBaseGeneratorAndLayerAddsToIt() {
        let manager = ParameterManager()
        XCTAssertTrue(manager.determineActiveGenerators().contains("Scale Pattern Generator"))

        var settings = RhythmLibrarySettings()
        settings.isEnabled = true
        settings.role = .source
        manager.rhythmLibrary = settings

        var generators = manager.determineActiveGenerators()
        XCTAssertTrue(generators.contains("Rhythm Library Generator"))
        XCTAssertFalse(generators.contains("Scale Pattern Generator"), "Source role replaces the base")

        manager.rhythmLibrary.role = .layer
        generators = manager.determineActiveGenerators()
        XCTAssertTrue(generators.contains("Rhythm Library Generator"))
        XCTAssertTrue(generators.contains("Scale Pattern Generator"), "Layer role plays alongside the base")
    }

    func testLayeredGenerationProducesBothMelodicAndPercussionNotes() {
        var settings = RhythmLibrarySettings()
        settings.isEnabled = true
        settings.role = .layer
        settings.patternName = "Basic Rock"
        let params = PatternParameters(scaleType: .pentatonic, numberOfOctaves: 1,
                                       divisionsOfOctave: 5, mirror: false,
                                       rhythmLibrary: settings)

        guard let result = PatternGeneratorRegistry.shared.generateCombinedPattern(
            using: ["Scale Pattern Generator", "Rhythm Library Generator"],
            parameters: params,
            combinationMode: .layered
        ) else {
            return XCTFail("Combined generation failed")
        }

        XCTAssertTrue(result.notes.contains { $0.isPercussion }, "Kit part present")
        XCTAssertTrue(result.notes.contains { !$0.isPercussion && !$0.isRest }, "Melodic part present")
    }

    func testProcessAndPhasingWorkOnARhythmSource() {
        var params = drumParameters("Basic Rock")
        params.processSettings.mode = .additive
        params.processSettings.startCount = 1
        params.processSettings.notesPerCycle = 2

        guard let processed = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: params,
            generatorName: "Rhythm Library Generator"
        ) else {
            return XCTFail("Process generation failed")
        }
        XCTAssertGreaterThan(processed.metadata.totalCycles, 1, "Additive process expands the groove")

        var phased = drumParameters("Basic Rock")
        phased.phasingSettings.mode = .discrete
        phased.phasingSettings.stepsPerCycle = 1

        guard let result = CyclicalSequenceGenerator().generateCyclicalSequence(
            baseParameters: phased,
            generatorName: "Rhythm Library Generator"
        ) else {
            return XCTFail("Phasing generation failed")
        }
        XCTAssertEqual(Set(result.notes.soundingNotes.map { $0.voice }), [0, 1],
                       "The groove phases against itself")
    }

    // MARK: - Export

    func testDrumExportUsesChannelTen() throws {
        let params = drumParameters("Basic Rock")
        let generator = RhythmLibraryPatternGenerator()
        let notes = generator.generatePattern(parameters: params, cycleIndex: 0)
        XCTAssertFalse(notes.isEmpty)

        let metadata = PatternMetadata(
            generatorName: "Rhythm Library Generator",
            parameterHash: "test",
            generationTime: 0.001,
            noteCount: notes.count,
            pitchRange: 36...42,
            duration: notes.totalLength
        )
        let result = PatternGenerationResult(
            notes: notes,
            metadata: metadata,
            performance: PerformanceMetrics(generationTime: 0.001, memoryUsage: 0, complexity: 1.0)
        )

        let engine = MIDIEngine()
        XCTAssertNotNil(engine.generateMusicSequence(from: result, parameters: params))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("slonimsky-rhythm-test-\(UUID().uuidString).mid")
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertTrue(engine.exportToMIDI(url: url))

        let data = try Data(contentsOf: url)
        XCTAssertTrue(data.contains(0x99), "Percussion must be written as channel-10 note-ons")
    }

    func testChannelMapping() {
        XCTAssertEqual(MIDIEngine.channel(forVoice: 0), 0)
        XCTAssertEqual(MIDIEngine.channel(forVoice: 1), 2)
        XCTAssertEqual(MIDIEngine.channel(forVoice: 0, isPercussion: true), 9)
        XCTAssertEqual(MIDIEngine.channel(forVoice: 1, isPercussion: true), 9)
    }

    // MARK: - Validation

    func testValidationRejectsAllLanesMuted() {
        var settings = RhythmLibrarySettings()
        settings.isEnabled = true
        settings.patternName = "Basic Rock"
        settings.mutedVoices = Set(settings.pattern?.voicesUsed ?? [])
        XCTAssertFalse(settings.validate(), "Silencing every lane is not a usable pattern")
    }

    func testValidationIgnoresDisabledLibrary() {
        var settings = RhythmLibrarySettings()
        settings.patternName = "Does Not Exist"
        XCTAssertTrue(settings.validate(), "A disabled library never blocks generation")
    }
}
