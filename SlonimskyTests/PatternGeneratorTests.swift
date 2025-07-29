//
//  PatternGeneratorTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class PatternGeneratorTests: XCTestCase {
    
    var registry: PatternGeneratorRegistry!
    var basicParameters: PatternParameters!
    
    override func setUpWithError() throws {
        registry = PatternGeneratorRegistry.shared
        basicParameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            tempo: 120.0,
            timeSignature: .common,
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
            noteDurationPattern: .uniform,
            baseNoteDuration: 0.25,
            rhythmicDensity: 1.0,
            syncopationLevel: 0.0,
            metricModulation: .default,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
    }
    
    override func tearDownWithError() throws {
        registry = nil
        basicParameters = nil
    }
    
    // MARK: - PatternGeneratorRegistry Tests
    
    func testRegistryInitialization() throws {
        XCTAssertNotNil(registry)
        XCTAssertFalse(registry.getAllGeneratorNames().isEmpty)
        XCTAssertTrue(registry.getAllGeneratorNames().contains("Scale Pattern Generator"))
        XCTAssertTrue(registry.getAllGeneratorNames().contains("Interval Pattern Generator"))
    }
    
    func testGeneratorRetrieval() throws {
        let scaleGenerator = registry.getGenerator(name: "Scale Pattern Generator")
        XCTAssertNotNil(scaleGenerator)
        XCTAssertEqual(scaleGenerator?.name, "Scale Pattern Generator")
        
        let intervalGenerator = registry.getGenerator(name: "Interval Pattern Generator")
        XCTAssertNotNil(intervalGenerator)
        XCTAssertEqual(intervalGenerator?.name, "Interval Pattern Generator")
        
        let nonExistentGenerator = registry.getGenerator(name: "Non-existent Generator")
        XCTAssertNil(nonExistentGenerator)
    }
    
    // MARK: - ScalePatternGenerator Tests
    
    func testScalePatternGeneratorBasicGeneration() throws {
        let result = registry.generatePattern(using: "Scale Pattern Generator", parameters: basicParameters)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.notes.isEmpty)
        XCTAssertEqual(result!.metadata.generatorName, "Scale Pattern Generator")
        XCTAssertGreaterThan(result!.performance.generationTime, 0)
        XCTAssertLessThan(result!.performance.generationTime, 0.5) // Should complete within 500ms
    }
    
    func testScalePatternGeneratorChromaticScale() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12
        )
        
        let result = registry.generatePattern(using: "Scale Pattern Generator", parameters: parameters)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.notes.count, 12) // Chromatic scale has 12 notes
        
        // Verify notes are in ascending order
        let notes = result!.notes.map(\.note)
        XCTAssertEqual(notes, notes.sorted())
        
        // Verify notes are within expected range
        XCTAssertGreaterThanOrEqual(notes.min()!, 60)
        XCTAssertLessThanOrEqual(notes.max()!, 71)
    }
    
    func testScalePatternGeneratorDiatonicScale() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7
        )
        
        let result = registry.generatePattern(using: "Scale Pattern Generator", parameters: parameters)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.notes.count, 7) // Diatonic scale has 7 notes
        
        let notes = result!.notes.map(\.note)
        XCTAssertEqual(notes, notes.sorted())
    }
    
    func testScalePatternGeneratorWithModulations() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            divisionsOfOctave: 6,
            interpolation: ModulationSettings(numberOfNotes: 2, interval: 1, enabled: true),
            infrapolation: ModulationSettings(numberOfNotes: 1, interval: 1, enabled: true),
            ultrapolation: ModulationSettings(numberOfNotes: 1, interval: 1, enabled: true)
        )
        
        let result = registry.generatePattern(using: "Scale Pattern Generator", parameters: parameters)
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.notes.count, 6) // Should have more notes due to modulations
    }
    
    // MARK: - IntervalPatternGenerator Tests
    
    func testIntervalPatternGeneratorBasicGeneration() throws {
        let result = registry.generatePattern(using: "Interval Pattern Generator", parameters: basicParameters)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.notes.isEmpty)
        XCTAssertEqual(result!.metadata.generatorName, "Interval Pattern Generator")
        XCTAssertGreaterThan(result!.performance.generationTime, 0)
        XCTAssertLessThan(result!.performance.generationTime, 0.5) // Should complete within 500ms
    }
    
    func testIntervalPatternGeneratorWithDifferentIntervals() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            primaryInterval: 2,
            secondaryInterval: 3,
            numberOfOctaves: 1,
            divisionsOfOctave: 8
        )
        
        let result = registry.generatePattern(using: "Interval Pattern Generator", parameters: parameters)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.notes.count, 8)
        
        let notes = result!.notes.map(\.note)
        XCTAssertEqual(notes, notes.sorted())
    }
    
    func testIntervalPatternGeneratorWithSymmetricalIntervals() throws {
        let parameters = PatternParameters(
            rootNote: 60,
            primaryInterval: 2,
            symmetricalIntervals: true,
            numberOfOctaves: 1,
            divisionsOfOctave: 6
        )
        
        let result = registry.generatePattern(using: "Interval Pattern Generator", parameters: parameters)
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.notes.count, 6) // Should have more notes due to symmetry
    }
    
    // MARK: - Parameter Validation Tests
    
    func testParameterValidation() throws {
        // Valid parameters
        XCTAssertTrue(basicParameters.validate())
        
        // Invalid root note
        let invalidRootNote = PatternParameters(rootNote: 150)
        XCTAssertFalse(invalidRootNote.validate())
        
        // Invalid number of octaves
        let invalidOctaves = PatternParameters(numberOfOctaves: 10)
        XCTAssertFalse(invalidOctaves.validate())
        
        // Invalid divisions
        let invalidDivisions = PatternParameters(divisionsOfOctave: 15)
        XCTAssertFalse(invalidDivisions.validate())
        
        // Invalid tempo
        let invalidTempo = PatternParameters(tempo: 300.0)
        XCTAssertFalse(invalidTempo.validate())
    }
    
    // MARK: - Performance Tests
    
    func testGenerationPerformance() throws {
        let complexParameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 4,
            divisionsOfOctave: 12,
            interpolation: ModulationSettings(numberOfNotes: 3, interval: 1, enabled: true),
            infrapolation: ModulationSettings(numberOfNotes: 2, interval: 1, enabled: true),
            ultrapolation: ModulationSettings(numberOfNotes: 2, interval: 1, enabled: true),
            mirrorPoints: 3,
            symmetricalIntervals: true
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = registry.generatePattern(using: "Scale PatternGenerator", parameters: complexParameters)
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertNotNil(result)
        XCTAssertLessThan(generationTime, 0.5) // Should complete within 500ms
        XCTAssertGreaterThan(result!.notes.count, 100) // Should generate many notes
    }
    
    // MARK: - Combined Pattern Tests
    
    func testCombinedPatternGeneration() throws {
        let generatorNames = ["Scale Pattern Generator", "Interval Pattern Generator"]
        
        let result = registry.generateCombinedPattern(
            using: generatorNames,
            parameters: basicParameters,
            combinationMode: .sequential
        )
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.notes.count, 0)
        XCTAssertTrue(result!.metadata.generatorName.contains("Combined"))
    }
    
    func testCombinedPatternInterleaved() throws {
        let generatorNames = ["Scale Pattern Generator", "Interval Pattern Generator"]
        
        let result = registry.generateCombinedPattern(
            using: generatorNames,
            parameters: basicParameters,
            combinationMode: .interleaved
        )
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.notes.count, 0)
    }
    
    // MARK: - Velocity Settings Tests
    
    func testVelocitySettingsCalculation() throws {
        let velocitySettings = VelocitySettings(
            baseVelocity: 80,
            range: 40,
            waveDepth: 0.5,
            randomness: 0.2,
            phase: 0.0,
            emphasisBeat: 4,
            emphasisAmount: 0.3
        )
        
        let velocity = velocitySettings.calculateVelocity(for: 0, note: 60)
        XCTAssertGreaterThanOrEqual(velocity, 1)
        XCTAssertLessThanOrEqual(velocity, 127)
        
        let velocityWithContext = velocitySettings.calculateVelocityWithHarmonicContext(
            for: 0,
            note: 60,
            harmonicTension: 0.5,
            melodicContour: 0.0
        )
        XCTAssertGreaterThanOrEqual(velocityWithContext, 1)
        XCTAssertLessThanOrEqual(velocityWithContext, 127)
    }
    
    func testVelocitySettingsPresets() throws {
        let classical = VelocitySettings.classical
        XCTAssertEqual(classical.baseVelocity, 70)
        XCTAssertEqual(classical.emphasisBeat, 4)
        
        let jazz = VelocitySettings.jazz
        XCTAssertEqual(jazz.baseVelocity, 85)
        XCTAssertEqual(jazz.randomness, 0.4)
        
        let electronic = VelocitySettings.electronic
        XCTAssertEqual(electronic.baseVelocity, 90)
        XCTAssertEqual(electronic.waveDepth, 0.8)
    }
} 