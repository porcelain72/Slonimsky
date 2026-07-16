//
//  SimpleCyclicalTest.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class SimpleCyclicalTest: XCTestCase {
    
    func testCyclicalBasicFunctionality() throws {
        // Test basic cyclical functionality
        let cyclicalGenerator = CyclicalSequenceGenerator()
        
        // Create base parameters
        let baseParameters = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 2,
            secondaryInterval: 3,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: ModulationSettings(enabled: false),
            infrapolation: ModulationSettings(enabled: false),
            ultrapolation: ModulationSettings(enabled: false),
            primaryDirection: .ascending,
            mirrorPoints: 0,
            baseNoteDuration: 0.25,
            chordGeneration: ChordSettings(enabled: false),
            velocitySettings: VelocitySettings(),
            cyclicalSettings: CyclicalSettings()
        )
        
        // Test 1: No cyclical parameters (should work like normal generation)
        guard let result1 = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParameters,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate sequence without cyclical parameters")
            return
        }
        
        XCTAssertFalse(result1.metadata.isCyclicalSequence, "Should not be marked as cyclical")
        XCTAssertEqual(result1.metadata.totalCycles, 1, "Should have 1 cycle (single pattern)")
        XCTAssertGreaterThan(result1.notes.count, 0, "Should have generated notes")
        
        // Test 2: With cyclical root note changes
        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.rootNote = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 60.0,
            maxValue: 64.0,
            stepSize: 2.0
        )
        
        let baseParametersWithCyclical = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 12,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 2,
            secondaryInterval: 3,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: ModulationSettings(enabled: false),
            infrapolation: ModulationSettings(enabled: false),
            ultrapolation: ModulationSettings(enabled: false),
            primaryDirection: .ascending,
            mirrorPoints: 0,
            baseNoteDuration: 0.25,
            chordGeneration: ChordSettings(enabled: false),
            velocitySettings: VelocitySettings(),
            cyclicalSettings: cyclicalSettings
        )
        
        guard let result2 = cyclicalGenerator.generateCyclicalSequence(
            baseParameters: baseParametersWithCyclical,
            generatorName: "Scale Pattern Generator"
        ) else {
            XCTFail("Failed to generate cyclical sequence")
            return
        }
        
        XCTAssertTrue(result2.metadata.isCyclicalSequence, "Should be marked as cyclical")
        XCTAssertEqual(result2.metadata.totalCycles, 2, "Should have 2 cycles (stops when parameter reaches max value)")
        
        // Verify we have notes from multiple cycles
        let notesByCycle = Dictionary(grouping: result2.notes) { $0.cycleIndex }
        XCTAssertEqual(notesByCycle.count, 2, "Should have notes from 2 different cycles")
        
        // Verify each cycle has distinct root notes (60, 62)
        for cycleIndex in 0..<2 {
            guard let cycleNotes = notesByCycle[cycleIndex] else {
                XCTFail("Missing notes for cycle \(cycleIndex)")
                continue
            }
            
            let firstNote = cycleNotes.min { $0.note < $1.note }?.note ?? 0
            let expectedRootNote = 60 + (cycleIndex * 2) // 60, 62
            
            XCTAssertEqual(firstNote, expectedRootNote, 
                          "Cycle \(cycleIndex) should start with root note \(expectedRootNote), got \(firstNote)")
        }
        
        print("✅ Cyclical functionality test passed!")
        print("   Generated \(result2.notes.count) total notes across \(result2.metadata.totalCycles) cycles")
        print("   Notes by cycle: \(notesByCycle.map { "\($0.key): \($0.value.count) notes" }.joined(separator: ", "))")
    }
}
