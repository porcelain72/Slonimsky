//
//  ParameterApplicationTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class ParameterApplicationTests: XCTestCase {
    
    func testParameterApplicationOrder() throws {
        let generator = ScalePatternGenerator()
        
        // Create parameters with simpler effects to test parameter application
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .descending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 0.25,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: VelocitySettings(baseVelocity: 80, range: 20),
            toneShifting: .default
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        // Verify that all parameters are affecting the output
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertGreaterThan(result.count, 1, "Should have multiple notes")
        
        // Check that root note affects the pattern
        XCTAssertTrue(result.map { $0.note }.contains(60), "Pattern should contain the root note")
        
        // Check that descending direction is applied
        let firstNote = result.first?.note ?? 0
        let lastNote = result.last?.note ?? 0
        XCTAssertLessThan(lastNote, firstNote, "Descending direction should make last note lower than first")
        
        // Check that velocity settings are applied
        let velocities = result.map { $0.velocity }
        XCTAssertTrue(velocities.contains { $0 >= 80 }, "Should have velocities around base velocity")
        XCTAssertTrue(velocities.contains { $0 <= 100 }, "Should have velocities within range")
        
        // Check that duration patterns are applied
        let durations = result.map { $0.duration }
        XCTAssertNotEqual(durations[0], durations[1], "Alternating duration pattern should create different durations")
    }
    
    func testParameterIsolation() throws {
        let generator = IntervalPatternGenerator()
        
        // Test that interval patterns are preserved
        let params1 = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 2,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 0.25,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
        
        let params2 = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 2,
            secondaryInterval: 1,
            intervalPattern: .descending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 0.25,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
        
        let result1 = generator.generatePattern(parameters: params1)
        let result2 = generator.generatePattern(parameters: params2)
        
        // Verify that interval patterns are different
        XCTAssertNotEqual(result1, result2, "Different interval patterns should produce different results")
        
        // Check that ascending pattern goes up
        if result1.count >= 2 {
            let ascendingTrend = result1[1].note - result1[0].note
            XCTAssertGreaterThan(ascendingTrend, 0, "Ascending pattern should go up")
        }
        
        // Check that descending pattern goes down
        if result2.count >= 2 {
            let descendingTrend = result2[1].note - result2[0].note
            XCTAssertLessThan(descendingTrend, 0, "Descending pattern should go down")
        }
    }
    
    func testContourPatternPreservesOtherParameters() throws {
        let generator = ScalePatternGenerator()
        
        // Create parameters with scale and contour
        let baseParams = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 0.25,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
        
        let linearParams = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 0.25,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
        
        let archParams = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .arch,
            baseNoteDuration: 0.25,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
        
        let baseResult = generator.generatePattern(parameters: baseParams)
        let linearResult = generator.generatePattern(parameters: linearParams)
        let archResult = generator.generatePattern(parameters: archParams)
        
        // All should have the same number of notes (scale-based)
        XCTAssertEqual(baseResult.count, linearResult.count, "Linear contour should preserve note count")
        XCTAssertEqual(baseResult.count, archResult.count, "Arch contour should preserve note count")
        
        // Contour patterns should create different note sequences
        XCTAssertNotEqual(linearResult, archResult, "Different contour patterns should produce different results")
        
        // But they should maintain some scale relationships
        let baseNotes = baseResult.map { $0.note }
        let linearNotes = linearResult.map { $0.note }
        let archNotes = archResult.map { $0.note }
        
        // Check that all results contain notes from the diatonic scale
        let diatonicScale = [60, 62, 64, 65, 67, 69, 71] // C major scale
        for note in baseNotes {
            XCTAssertTrue(diatonicScale.contains(note), "Base result should contain diatonic scale notes")
        }
        for note in linearNotes {
            XCTAssertTrue(diatonicScale.contains(note), "Linear result should contain diatonic scale notes")
        }
        for note in archNotes {
            XCTAssertTrue(diatonicScale.contains(note), "Arch result should contain diatonic scale notes")
        }
    }
    
    func testVelocityClamping() throws {
        let generator = ScalePatternGenerator()
        
        // Create parameters with high velocity settings that could overflow
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 0.25,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: VelocitySettings(baseVelocity: 120, range: 30),
            toneShifting: .default
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        // Verify that all velocities are within valid MIDI range
        for midiInfo in result {
            XCTAssertGreaterThanOrEqual(midiInfo.velocity, 1, "Velocity should be >= 1")
            XCTAssertLessThanOrEqual(midiInfo.velocity, 127, "Velocity should be <= 127")
        }
    }
    
    func testParameterCombinationEffects() throws {
        let generator = ScalePatternGenerator()
        
        // Test multiple parameters working together
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 12,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .alternating,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .alternating,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .symmetrical,
            contourPattern: .wave,
            baseNoteDuration: 0.25,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: VelocitySettings(baseVelocity: 90, range: 15),
            toneShifting: ToneShiftSettings(toneIncrement: 2, maxToneShift: 6)
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        // Verify that the combination produces a complex but valid result
        XCTAssertFalse(result.isEmpty, "Complex parameter combination should produce results")
        XCTAssertGreaterThan(result.count, 10, "Multiple parameters should create more complex patterns")
        
        // Check that all notes are within valid MIDI range
        for midiInfo in result {
            XCTAssertGreaterThanOrEqual(midiInfo.note, 0, "Note should be >= 0")
            XCTAssertLessThanOrEqual(midiInfo.note, 127, "Note should be <= 127")
            XCTAssertGreaterThanOrEqual(midiInfo.velocity, 1, "Velocity should be >= 1")
            XCTAssertLessThanOrEqual(midiInfo.velocity, 127, "Velocity should be <= 127")
            XCTAssertGreaterThan(midiInfo.duration, 0, "Duration should be > 0")
        }
    }
} 