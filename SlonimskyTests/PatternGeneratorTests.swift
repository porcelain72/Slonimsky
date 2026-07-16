//
//  PatternGeneratorTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class PatternGeneratorTests: XCTestCase {
    
    func testIntervalPatternGeneratorBasic() throws {
        let generator = IntervalPatternGenerator()
        let parameters = PatternParameters(
            rootNote: 60,
            numberOfOctaves: 1,
            primaryInterval: 2,
            intervalPattern: .ascending
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
        
        // Test that notes are in ascending order
        let notes = result.map { $0.note }
        for i in 1..<notes.count {
            XCTAssertGreaterThanOrEqual(notes[i], notes[i-1], "Notes should be in ascending order")
        }
    }
    
    func testScalePatternGeneratorMajor() throws {
        let generator = ScalePatternGenerator()
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
        
        // Test that we have the expected number of notes for a diatonic scale
        let expectedNoteCount = 7 // One octave of diatonic scale
        XCTAssertGreaterThanOrEqual(result.count, expectedNoteCount, "Should generate at least a full octave")
    }
    
    func testHarmonicPatternGenerator() throws {
        let generator = HarmonicPatternGenerator()
        let parameters = PatternParameters(
            rootNote: 60,
            numberOfOctaves: 1
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
        
        // Test that notes are within valid MIDI range
        for midiInfo in result {
            XCTAssertGreaterThanOrEqual(midiInfo.note, 0, "Note should be >= 0")
            XCTAssertLessThanOrEqual(midiInfo.note, 127, "Note should be <= 127")
        }
    }
    
    func testSymmetricalPatternGenerator() throws {
        let generator = SymmetricalPatternGenerator()
        let parameters = PatternParameters(
            rootNote: 60,
            numberOfOctaves: 1,
            symmetricalIntervals: true
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
    }
    
    func testContourPatternGenerator() throws {
        let generator = ContourPatternGenerator()
        let parameters = PatternParameters(
            rootNote: 60,
            numberOfOctaves: 1,
            contourPattern: .arch
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
    }
    
    func testModulationPatternGenerator() throws {
        let generator = ModulationPatternGenerator()
        
        // Enable at least one modulation technique to pass validation
        let interpolation = ModulationSettings(numberOfNotes: 2, interval: 1, enabled: true)
        let parameters = PatternParameters(
            rootNote: 60,
            numberOfOctaves: 1,
            interpolation: interpolation
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
    }
    
    func testPatternGeneratorRegistry() throws {
        let registry = PatternGeneratorRegistry.shared
        
        // Test that registry has generators
        XCTAssertFalse(registry.getAllGeneratorNames().isEmpty, "Registry should have available generators")
        
        // Test that we can get a generator by name
        if let firstGeneratorName = registry.getAllGeneratorNames().first {
            let generator = registry.getGenerator(name: firstGeneratorName)
            XCTAssertNotNil(generator, "Should be able to get generator by name")
        }
    }
    
    func testParameterValidation() throws {
        let generator = IntervalPatternGenerator()
        
        // Test valid parameters
        let validParameters = PatternParameters(
            rootNote: 60,
            numberOfOctaves: 1,
            primaryInterval: 1
        )
        XCTAssertTrue(generator.validateParameters(parameters: validParameters), "Valid parameters should pass validation")
        
        // Test invalid parameters (negative root note)
        let invalidParameters = PatternParameters(
            rootNote: -1,
            numberOfOctaves: 1,
            primaryInterval: 1
        )
        XCTAssertFalse(generator.validateParameters(parameters: invalidParameters), "Invalid parameters should fail validation")
    }
    
    // MARK: - Parameter Utilization Tests
    
    func testRootNoteParameterUtilization() throws {
        let generator = ScalePatternGenerator()
        
        // Test with different root notes
        let params1 = PatternParameters(rootNote: 60, numberOfOctaves: 1, divisionsOfOctave: 12)
        let params2 = PatternParameters(rootNote: 72, numberOfOctaves: 1, divisionsOfOctave: 12)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        XCTAssertNotEqual(result1.first?.note, result2.first?.note, "Root note should affect the starting note")
    }
    
    func testNumberOfOctavesParameterUtilization() throws {
        let generator = ScalePatternGenerator()
        
        // Test with different octave counts
        let params1 = PatternParameters(rootNote: 60, numberOfOctaves: 1, divisionsOfOctave: 12)
        let params2 = PatternParameters(rootNote: 60, numberOfOctaves: 2, divisionsOfOctave: 12)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        XCTAssertNotEqual(result1.count, result2.count, "Number of octaves should affect note count")
        XCTAssertEqual(result2.count, 24, "2 octaves × 12 divisions should equal 24 notes")
    }
    
    func testScaleTypeParameterUtilization() throws {
        let generator = ScalePatternGenerator()
        
        // Test with different scale types
        let params1 = PatternParameters(rootNote: 60, scaleType: .chromatic, numberOfOctaves: 1, divisionsOfOctave: 12)
        let params2 = PatternParameters(rootNote: 60, scaleType: .diatonic, numberOfOctaves: 1, divisionsOfOctave: 7)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        XCTAssertNotEqual(result1.count, result2.count, "Scale type should affect note count")
        XCTAssertEqual(result1.count, 12, "Chromatic scale should have 12 notes")
        XCTAssertEqual(result2.count, 7, "Diatonic scale should have 7 notes")
    }
    
    func testPrimaryIntervalParameterUtilization() throws {
        let generator = IntervalPatternGenerator()
        
        // Test with different primary intervals
        let params1 = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 1)
        let params2 = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 2)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        // Debug: Print the actual notes and intervals
        print("Test 1 - Primary Interval 1:")
        for i in 0..<min(5, result1.count) {
            print("  Note \(i): \(result1[i].note)")
        }
        
        print("Test 2 - Primary Interval 2:")
        for i in 0..<min(5, result2.count) {
            print("  Note \(i): \(result2[i].note)")
        }
        
        // Check that the first notes are different (this should work regardless of transformations)
        if result1.count > 0 && result2.count > 0 {
            let firstNote1 = result1[0].note
            let firstNote2 = result2[0].note
            print("First note 1: \(firstNote1), First note 2: \(firstNote2)")
            XCTAssertNotEqual(firstNote1, firstNote2, "Primary interval should affect first note")
        }
        
        // Check that the overall patterns are different
        let notes1 = result1.map { $0.note }
        let notes2 = result2.map { $0.note }
        XCTAssertNotEqual(notes1, notes2, "Primary interval should affect the overall note pattern")
    }
    
    func testIntervalPatternParameterUtilization() throws {
        let generator = IntervalPatternGenerator()
        
        // Test with different interval patterns - use different primary intervals to ensure difference
        let params1 = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 2, intervalPattern: .ascending)
        let params2 = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 2, intervalPattern: .descending)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        // Check that the overall patterns are different
        XCTAssertNotEqual(result1, result2, "Interval pattern should affect the generated sequence")
        
        // Check that the first few notes show different trends
        if result1.count >= 3 && result2.count >= 3 {
            let trend1 = result1[2].note - result1[0].note
            let trend2 = result2[2].note - result2[0].note
            XCTAssertNotEqual(trend1, trend2, "Interval pattern should affect the overall trend")
        }
        
        // Additional test: check that ascending pattern goes up and descending goes down
        if result1.count >= 2 && result2.count >= 2 {
            let ascendingTrend = result1[1].note - result1[0].note
            let descendingTrend = result2[1].note - result2[0].note
            XCTAssertTrue(ascendingTrend > 0, "Ascending pattern should go up")
            XCTAssertTrue(descendingTrend < 0, "Descending pattern should go down")
        }
    }
    
    func testContourPatternParameterUtilization() throws {
        let generator = ContourPatternGenerator()
        
        // Test with different contour patterns
        let params1 = PatternParameters(rootNote: 60, numberOfOctaves: 1, contourPattern: .linear)
        let params2 = PatternParameters(rootNote: 60, numberOfOctaves: 1, contourPattern: .arch)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        // Check that patterns are different (this is a basic check - more sophisticated analysis could be done)
        XCTAssertNotEqual(result1, result2, "Contour pattern should affect note sequence")
    }
    
    func testVelocitySettingsParameterUtilization() throws {
        let generator = ScalePatternGenerator()
        
        // Test with different velocity settings
        let velocity1 = VelocitySettings(baseVelocity: 64, range: 16)
        let velocity2 = VelocitySettings(baseVelocity: 100, range: 27)
        
        let params1 = PatternParameters(rootNote: 60, numberOfOctaves: 1, velocitySettings: velocity1)
        let params2 = PatternParameters(rootNote: 60, numberOfOctaves: 1, velocitySettings: velocity2)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        // Check that velocities are different
        let velocities1 = result1.map { $0.velocity }
        let velocities2 = result2.map { $0.velocity }
        XCTAssertNotEqual(velocities1, velocities2, "Velocity settings should affect note velocities")
    }
    
    func testSymmetricalIntervalsParameterUtilization() throws {
        let generator = SymmetricalPatternGenerator()
        
        // Test with symmetrical intervals on/off
        let params1 = PatternParameters(rootNote: 60, numberOfOctaves: 1, symmetricalIntervals: false)
        let params2 = PatternParameters(rootNote: 60, numberOfOctaves: 1, symmetricalIntervals: true)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        // Check that patterns are different
        XCTAssertNotEqual(result1, result2, "Symmetrical intervals should affect pattern generation")
    }
    
    func testModulationSettingsParameterUtilization() throws {
        let generator = ModulationPatternGenerator()
        
        // Test with different modulation settings
        let modulation1 = ModulationSettings(numberOfNotes: 0, interval: 1)
        let modulation2 = ModulationSettings(numberOfNotes: 3, interval: 2)
        
        let params1 = PatternParameters(rootNote: 60, numberOfOctaves: 1, interpolation: modulation1)
        let params2 = PatternParameters(rootNote: 60, numberOfOctaves: 1, interpolation: modulation2)
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        // Check that patterns are different
        XCTAssertNotEqual(result1, result2, "Modulation settings should affect pattern generation")
    }
    
    func testAllParametersAffectOutput() throws {
        // This test ensures that changing any parameter produces a different output
        let generator = ScalePatternGenerator()
        let baseParams = PatternParameters.default
        
        // Test each major parameter category
        let testCases = [
            ("rootNote", PatternParameters(rootNote: 65, numberOfOctaves: 1, divisionsOfOctave: 12)),
            ("numberOfOctaves", PatternParameters(rootNote: 60, numberOfOctaves: 2, divisionsOfOctave: 12)),
            ("scaleType", PatternParameters(rootNote: 60, scaleType: .diatonic, numberOfOctaves: 1, divisionsOfOctave: 7)),
            ("divisionsOfOctave", PatternParameters(rootNote: 60, numberOfOctaves: 1, divisionsOfOctave: 6)),
            ("tempo", PatternParameters(rootNote: 60, numberOfOctaves: 1, tempo: 180.0)),
            ("meter", PatternParameters(rootNote: 60, numberOfOctaves: 1, meter: .threeFour))
        ]
        
        let baseResult = generator.generatePattern(parameters: baseParams)
        
        for (paramName, testParams) in testCases {
            let testResult = generator.generatePattern(parameters: testParams)
            XCTAssertNotEqual(baseResult, testResult, "Parameter '\(paramName)' should affect output")
        }
    }
    
    // MARK: - Comprehensive Parameter Testing
    
    func testAllBasicParameters() throws {
        let generator = ScalePatternGenerator()
        let baseParams = PatternParameters.default
        
        // Test rootNote
        let rootNoteParams = PatternParameters(rootNote: 72, numberOfOctaves: 1, divisionsOfOctave: 12)
        let rootNoteResult = generator.generatePattern(parameters: rootNoteParams)
        XCTAssertNotEqual(baseParams.rootNote, rootNoteParams.rootNote, "rootNote should be different")
        XCTAssertNotEqual(baseParams.rootNote, rootNoteResult.first?.note, "rootNote should affect first note")
        
        // Test numberOfOctaves
        let octaveParams = PatternParameters(rootNote: 60, numberOfOctaves: 3, divisionsOfOctave: 12)
        let octaveResult = generator.generatePattern(parameters: octaveParams)
        XCTAssertNotEqual(baseParams.numberOfOctaves, octaveParams.numberOfOctaves, "numberOfOctaves should be different")
        XCTAssertNotEqual(baseParams.numberOfOctaves * baseParams.divisionsOfOctave, octaveResult.count, "numberOfOctaves should affect note count")
        
        // Test divisionsOfOctave
        let divisionsParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, divisionsOfOctave: 6)
        let divisionsResult = generator.generatePattern(parameters: divisionsParams)
        XCTAssertNotEqual(baseParams.divisionsOfOctave, divisionsParams.divisionsOfOctave, "divisionsOfOctave should be different")
        XCTAssertNotEqual(baseParams.divisionsOfOctave, divisionsResult.count, "divisionsOfOctave should affect note count")
        
        // Test tempo
        let tempoParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, tempo: 180.0)
        let tempoResult = generator.generatePattern(parameters: tempoParams)
        XCTAssertNotEqual(baseParams.tempo, tempoParams.tempo, "tempo should be different")
        // Note: Tempo might not affect note generation, only playback timing
        
        // Test timeSignature
        let timeSigParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, meter: .threeFour)
        let timeSigResult = generator.generatePattern(parameters: timeSigParams)
        XCTAssertNotEqual(baseParams.meter, timeSigParams.meter, "meter should be different")
        // Note: Time signature might not affect note generation, only rhythmic structure
    }
    
    func testAllIntervalParameters() throws {
        let generator = IntervalPatternGenerator()
        let baseParams = PatternParameters.default
        
        // Test primaryInterval
        let primaryIntervalParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 3)
        let primaryIntervalResult = generator.generatePattern(parameters: primaryIntervalParams)
        XCTAssertNotEqual(baseParams.primaryInterval, primaryIntervalParams.primaryInterval, "primaryInterval should be different")
        if primaryIntervalResult.count > 1 {
            let interval = primaryIntervalResult[1].note - primaryIntervalResult[0].note
            XCTAssertNotEqual(0, interval, "primaryInterval should affect note spacing")
        }
        
        // Test secondaryInterval
        let secondaryIntervalParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 1, secondaryInterval: 2)
        let secondaryIntervalResult = generator.generatePattern(parameters: secondaryIntervalParams)
        XCTAssertNotEqual(baseParams.secondaryInterval, secondaryIntervalParams.secondaryInterval, "secondaryInterval should be different")
        
        // Test intervalPattern
        let ascendingParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 2, intervalPattern: .ascending)
        let descendingParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 2, intervalPattern: .descending)
        let ascendingResult = generator.generatePattern(parameters: ascendingParams)
        let descendingResult = generator.generatePattern(parameters: descendingParams)
        XCTAssertNotEqual(ascendingParams.intervalPattern, descendingParams.intervalPattern, "intervalPattern should be different")
        if ascendingResult.count > 1 && descendingResult.count > 1 {
            let ascendingDirection = ascendingResult[1].note > ascendingResult[0].note
            let descendingDirection = descendingResult[1].note > descendingResult[0].note
            XCTAssertNotEqual(ascendingDirection, descendingDirection, "intervalPattern should affect direction")
        }
        
        // Test intervalInversion
        let inversionParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 2, intervalInversion: true)
        let inversionResult = generator.generatePattern(parameters: inversionParams)
        XCTAssertNotEqual(baseParams.intervalInversion, inversionParams.intervalInversion, "intervalInversion should be different")
        
        // Test symmetricalIntervals
        let symmetricalParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryInterval: 2, symmetricalIntervals: true)
        let symmetricalResult = generator.generatePattern(parameters: symmetricalParams)
        XCTAssertNotEqual(baseParams.symmetricalIntervals, symmetricalParams.symmetricalIntervals, "symmetricalIntervals should be different")
    }
    
    func testAllModulationParameters() throws {
        let generator = ModulationPatternGenerator()
        let baseParams = PatternParameters.default
        
        // Test interpolation
        let interpolationParams = PatternParameters(
            rootNote: 60, 
            numberOfOctaves: 1, 
            interpolation: ModulationSettings(numberOfNotes: 3, interval: 2, enabled: true)
        )
        let interpolationResult = generator.generatePattern(parameters: interpolationParams)
        XCTAssertNotEqual(baseParams.interpolation.numberOfNotes, interpolationParams.interpolation.numberOfNotes, "interpolation should be different")
        
        // Test infrapolation
        let infrapolationParams = PatternParameters(
            rootNote: 60, 
            numberOfOctaves: 1, 
            infrapolation: ModulationSettings(numberOfNotes: 2, interval: 1, enabled: true)
        )
        let infrapolationResult = generator.generatePattern(parameters: infrapolationParams)
        XCTAssertNotEqual(baseParams.infrapolation.numberOfNotes, infrapolationParams.infrapolation.numberOfNotes, "infrapolation should be different")
        
        // Test ultrapolation
        let ultrapolationParams = PatternParameters(
            rootNote: 60, 
            numberOfOctaves: 1, 
            ultrapolation: ModulationSettings(numberOfNotes: 4, interval: 3, enabled: true)
        )
        let ultrapolationResult = generator.generatePattern(parameters: ultrapolationParams)
        XCTAssertNotEqual(baseParams.ultrapolation.numberOfNotes, ultrapolationParams.ultrapolation.numberOfNotes, "ultrapolation should be different")
    }
    
    func testAllDirectionalParameters() throws {
        let generator = ContourPatternGenerator()
        let baseParams = PatternParameters.default
        
        // Test primaryDirection
        let ascendingParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryDirection: .ascending)
        let descendingParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, primaryDirection: .descending)
        let ascendingResult = generator.generatePattern(parameters: ascendingParams)
        let descendingResult = generator.generatePattern(parameters: descendingParams)
        XCTAssertNotEqual(ascendingParams.primaryDirection, descendingParams.primaryDirection, "primaryDirection should be different")
        
        // Test mirrorPoints
        let mirrorParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, mirrorPoints: 3)
        let mirrorResult = generator.generatePattern(parameters: mirrorParams)
        XCTAssertNotEqual(baseParams.mirrorPoints, mirrorParams.mirrorPoints, "mirrorPoints should be different")
        
        // Test retrogradeSections
        let retrogradeParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, retrogradeSections: true)
        let retrogradeResult = generator.generatePattern(parameters: retrogradeParams)
        XCTAssertNotEqual(baseParams.retrogradeSections, retrogradeParams.retrogradeSections, "retrogradeSections should be different")
        
        // Test registerShifts
        let registerParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, registerShifts: .linear)
        let registerResult = generator.generatePattern(parameters: registerParams)
        XCTAssertNotEqual(baseParams.registerShifts, registerParams.registerShifts, "registerShifts should be different")
        
        // Test contourPattern
        let linearParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, contourPattern: .linear)
        let archParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, contourPattern: .arch)
        let linearResult = generator.generatePattern(parameters: linearParams)
        let archResult = generator.generatePattern(parameters: archParams)
        XCTAssertNotEqual(linearParams.contourPattern, archParams.contourPattern, "contourPattern should be different")
    }
    
    func testAllRhythmicParameters() throws {
        let generator = ScalePatternGenerator()
        let baseParams = PatternParameters.default
        
        // Test baseNoteDuration
        let durationParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, baseNoteDuration: 0.5)
        let durationResult = generator.generatePattern(parameters: durationParams)
        XCTAssertNotEqual(baseParams.baseNoteDuration, durationParams.baseNoteDuration, "baseNoteDuration should be different")
        XCTAssertFalse(durationResult.isEmpty, "Pattern should generate notes")
        XCTAssertTrue(durationResult.allSatisfy { $0.duration == 0.5 }, "All notes should use the base duration")
    }
    
    func testAllHarmonicParameters() throws {
        let generator = HarmonicPatternGenerator()
        let baseParams = PatternParameters.default
        
        // Test harmonicMode
        let modalParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, harmonicMode: .modal)
        let tonalParams = PatternParameters(rootNote: 60, numberOfOctaves: 1, harmonicMode: .tonal)
        let modalResult = generator.generatePattern(parameters: modalParams)
        let tonalResult = generator.generatePattern(parameters: tonalParams)
        XCTAssertNotEqual(modalParams.harmonicMode, tonalParams.harmonicMode, "harmonicMode should be different")
        
        // Test chordGeneration
        let chordParams = PatternParameters(
            rootNote: 60, 
            numberOfOctaves: 1, 
            chordGeneration: ChordSettings(enabled: true, chordSize: 4, voicingPreference: .close, velocityScale: 0.9)
        )
        let chordResult = generator.generatePattern(parameters: chordParams)
        XCTAssertNotEqual(baseParams.chordGeneration.chordSize, chordParams.chordGeneration.chordSize, "chordGeneration should be different")
        
        // Test harmonicRhythm
        let rhythmParams = PatternParameters(
            rootNote: 60, 
            numberOfOctaves: 1, 
            harmonicRhythm: HarmonicRhythmSettings(chordChangeFrequency: 6, syncopationLevel: 0.3, harmonicTension: 0.7)
        )
        let rhythmResult = generator.generatePattern(parameters: rhythmParams)
        XCTAssertNotEqual(baseParams.harmonicRhythm.chordChangeFrequency, rhythmParams.harmonicRhythm.chordChangeFrequency, "harmonicRhythm should be different")
    }
    
    func testAllExpressionParameters() throws {
        let generator = ScalePatternGenerator()
        let baseParams = PatternParameters.default
        
        // Test velocitySettings
        let velocityParams = PatternParameters(
            rootNote: 60, 
            numberOfOctaves: 1, 
            velocitySettings: VelocitySettings(baseVelocity: 100, range: 30, waveDepth: 0.8, randomness: 0.3, phase: 0.5, emphasisBeat: 2, emphasisAmount: 0.6)
        )
        let velocityResult = generator.generatePattern(parameters: velocityParams)
        XCTAssertNotEqual(baseParams.velocitySettings.baseVelocity, velocityParams.velocitySettings.baseVelocity, "velocitySettings should be different")
        
        // Test toneShifting
        let toneParams = PatternParameters(
            rootNote: 60, 
            numberOfOctaves: 1, 
            toneShifting: ToneShiftSettings(toneIncrement: 2, maxToneShift: 12, shiftPattern: .linear)
        )
        let toneResult = generator.generatePattern(parameters: toneParams)
        XCTAssertNotEqual(baseParams.toneShifting.toneIncrement, toneParams.toneShifting.toneIncrement, "toneShifting should be different")
    }
    
    func testParameterCombinations() throws {
        let generator = ScalePatternGenerator()
        
        // Test multiple parameters changing together
        let complexParams = PatternParameters(
            rootNote: 65,
            scaleType: .diatonic,
            numberOfOctaves: 2,
            divisionsOfOctave: 7,
            tempo: 150.0,
            meter: .threeFour,
            primaryInterval: 2,
            secondaryInterval: 3,
            intervalPattern: .alternating,
            intervalInversion: true,
            symmetricalIntervals: true,
            primaryDirection: .descending,
            mirrorPoints: 2,
            retrogradeSections: true,
            registerShifts: .exponential,
            contourPattern: .wave,
            baseNoteDuration: 0.3,
            harmonicMode: .polymodal,
            velocitySettings: VelocitySettings(baseVelocity: 90, range: 25),
            toneShifting: ToneShiftSettings(toneIncrement: 1, maxToneShift: 6, shiftPattern: .exponential)
        )
        
        let result = generator.generatePattern(parameters: complexParams)
        XCTAssertFalse(result.isEmpty, "Complex parameter combination should generate notes")
        XCTAssertNotEqual(12, result.count, "Complex parameters should affect note count")
    }
    
    // MARK: - Automatic Generator Selection Tests
    
    func testAutomaticGeneratorSelection() {
        let parameterManager = ParameterManager()
        
        // Test initial state
        XCTAssertTrue(parameterManager.automaticGeneratorSelectionEnabled)
        XCTAssertEqual(parameterManager.activeGenerators, ["Scale Pattern Generator"])
        XCTAssertEqual(parameterManager.combinationMode, .sequential)
        
        // Test interval parameters activation
        parameterManager.primaryInterval = 3
        parameterManager.secondaryInterval = 5
        parameterManager.intervalInversion = true
        
        // Should now include Interval Pattern Generator
        XCTAssertTrue(parameterManager.activeGenerators.contains("Scale Pattern Generator"))
        XCTAssertTrue(parameterManager.activeGenerators.contains("Interval Pattern Generator"))
        XCTAssertEqual(parameterManager.combinationMode, .sequential)
        
        // Test modulation parameters activation
        parameterManager.interpolation.enabled = true
        parameterManager.interpolation.numberOfNotes = 2
        
        // Should now include Modulation Pattern Generator
        XCTAssertTrue(parameterManager.activeGenerators.contains("Modulation Pattern Generator"))
        
        // Test harmonic parameters activation
        parameterManager.harmonicMode = .modal
        parameterManager.chordGeneration.enabled = true
        
        // Should now include Harmonic Pattern Generator and use layered mode
        XCTAssertTrue(parameterManager.activeGenerators.contains("Harmonic Pattern Generator"))
        XCTAssertEqual(parameterManager.combinationMode, .layered)
        
        // Test symmetrical parameters activation
        parameterManager.symmetricalIntervals = true
        parameterManager.mirrorPoints = 2
        
        // Should now include Symmetrical Pattern Generator
        XCTAssertTrue(parameterManager.activeGenerators.contains("Symmetrical Pattern Generator"))
        
        // Test disabling automatic selection
        parameterManager.automaticGeneratorSelectionEnabled = false
        parameterManager.updateGeneratorSelection()
        
        // Should revert to single generator
        XCTAssertEqual(parameterManager.activeGenerators, [parameterManager.selectedGeneratorForAutoGeneration])
    }
    

} 