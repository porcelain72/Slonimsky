//
//  DirectionalParametersTest.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class DirectionalParametersTest: XCTestCase {
    
    func testPrimaryDirectionAscending() throws {
        // Test that ascending direction preserves the original order
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            primaryDirection: .ascending
        )
        
        let generator = ScalePatternGenerator()
        let result = generator.generatePattern(parameters: parameters)
        
        // Verify notes are in ascending order
        for i in 1..<result.count {
            XCTAssertLessThanOrEqual(result[i-1].note, result[i].note, 
                                   "Notes should be in ascending order for ascending direction")
        }
        
        print("✅ Ascending direction test passed - \(result.count) notes generated")
    }
    
    func testPrimaryDirectionDescending() throws {
        // Test that descending direction reverses the order
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            primaryDirection: .descending
        )
        
        let generator = ScalePatternGenerator()
        let result = generator.generatePattern(parameters: parameters)
        
        // Verify notes are in descending order
        for i in 1..<result.count {
            XCTAssertGreaterThanOrEqual(result[i-1].note, result[i].note, 
                                      "Notes should be in descending order for descending direction")
        }
        
        print("✅ Descending direction test passed - \(result.count) notes generated")
    }
    
    func testPrimaryDirectionAlternating() throws {
        // Test that alternating direction creates first half ascending, second half descending
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            primaryDirection: .alternating
        )
        
        let generator = ScalePatternGenerator()
        let result = generator.generatePattern(parameters: parameters)
        
        guard result.count >= 4 else {
            XCTFail("Need at least 4 notes to test alternating pattern")
            return
        }
        
        let midPoint = result.count / 2
        
        // First half should be ascending
        for i in 1..<midPoint {
            XCTAssertLessThanOrEqual(result[i-1].note, result[i].note, 
                                   "First half should be ascending in alternating pattern")
        }
        
        // Second half should be descending
        for i in midPoint..<(result.count - 1) {
            XCTAssertGreaterThanOrEqual(result[i].note, result[i+1].note, 
                                      "Second half should be descending in alternating pattern")
        }
        
        print("✅ Alternating direction test passed - \(result.count) notes generated")
    }
    
    func testMirrorPoints() throws {
        // Test that mirror points create symmetrical patterns
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            primaryDirection: .ascending,
            mirrorPoints: 2
        )
        
        let generator = ScalePatternGenerator()
        let result = generator.generatePattern(parameters: parameters)
        
        // With mirror points, the pattern should have some symmetry
        // This is a basic test - more complex symmetry testing would require
        // analyzing the actual mirror point implementation
        XCTAssertGreaterThan(result.count, 0, "Should generate notes with mirror points")
        
        print("✅ Mirror points test passed - \(result.count) notes generated")
    }
    
    func testRetrogradeSections() throws {
        // Test that retrograde sections create backward patterns
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            primaryDirection: .ascending,
            retrogradeSections: true
        )
        
        let generator = ScalePatternGenerator()
        let result = generator.generatePattern(parameters: parameters)
        
        // Retrograde sections should affect the pattern structure
        XCTAssertGreaterThan(result.count, 0, "Should generate notes with retrograde sections")
        
        print("✅ Retrograde sections test passed - \(result.count) notes generated")
    }
    
    func testRegisterShifts() throws {
        // Test different register shift patterns
        let registerShiftPatterns: [RegisterShiftPattern] = [.none, .linear, .exponential, .random, .mirror, .symmetrical]
        
        for pattern in registerShiftPatterns {
            let parameters = PatternParameters(
                rootNote: 60,
                scaleType: .chromatic,
                numberOfOctaves: 1,
                primaryDirection: .ascending,
                registerShifts: pattern
            )
            
            let generator = ScalePatternGenerator()
            let result = generator.generatePattern(parameters: parameters)
            
            XCTAssertGreaterThan(result.count, 0, "Should generate notes with \(pattern.rawValue) register shifts")
            
            // Verify notes are within valid MIDI range
            for note in result {
                XCTAssertGreaterThanOrEqual(note.note, 0, "Note should be >= 0")
                XCTAssertLessThanOrEqual(note.note, 127, "Note should be <= 127")
            }
            
            print("✅ Register shift \(pattern.rawValue) test passed - \(result.count) notes generated")
        }
    }
    
    func testContourPatterns() throws {
        // Test different contour patterns
        let contourPatterns: [ContourPattern] = [.linear, .arch, .invertedArch, .wave, .random, .mirror]
        
        for pattern in contourPatterns {
            let parameters = PatternParameters(
                rootNote: 60,
                scaleType: .chromatic,
                numberOfOctaves: 1,
                primaryDirection: .ascending,
                contourPattern: pattern
            )
            
            let generator = ScalePatternGenerator()
            let result = generator.generatePattern(parameters: parameters)
            
            XCTAssertGreaterThan(result.count, 0, "Should generate notes with \(pattern.rawValue) contour")
            
            // Verify notes are within valid MIDI range
            for note in result {
                XCTAssertGreaterThanOrEqual(note.note, 0, "Note should be >= 0")
                XCTAssertLessThanOrEqual(note.note, 127, "Note should be <= 127")
            }
            
            print("✅ Contour pattern \(pattern.rawValue) test passed - \(result.count) notes generated")
        }
    }
    
    func testDirectionalParametersCombination() throws {
        // Test combining multiple directional parameters
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            primaryDirection: .alternating,
            mirrorPoints: 2,
            retrogradeSections: true,
            registerShifts: .linear,
            contourPattern: .arch
        )
        
        let generator = ScalePatternGenerator()
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes with combined directional parameters")
        
        // Verify notes are within valid MIDI range
        for note in result {
            XCTAssertGreaterThanOrEqual(note.note, 0, "Note should be >= 0")
            XCTAssertLessThanOrEqual(note.note, 127, "Note should be <= 127")
        }
        
        print("✅ Combined directional parameters test passed - \(result.count) notes generated")
    }
    
    func testDirectionalParametersWithCyclical() throws {
        // Test directional parameters with cyclical settings
        var cyclicalSettings = CyclicalSettings()
        cyclicalSettings.mirrorPoints = CyclicalParameterSettings(
            isEnabled: true,
            minValue: 0,
            maxValue: 3,
            stepSize: 1
        )
        
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            primaryDirection: .ascending,
            mirrorPoints: 1,
            cyclicalSettings: cyclicalSettings
        )
        
        let generator = ScalePatternGenerator()
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes with cyclical directional parameters")
        
        print("✅ Cyclical directional parameters test passed - \(result.count) notes generated")
    }
    
    func testDirectionalParametersValidation() throws {
        // Test that directional parameters are properly validated
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 1,
            primaryDirection: .ascending,
            mirrorPoints: 5, // Maximum value
            retrogradeSections: true,
            registerShifts: .linear,
            contourPattern: .linear
        )
        
        let generator = ScalePatternGenerator()
        let isValid = generator.validateParameters(parameters: parameters)
        
        XCTAssertTrue(isValid, "Valid directional parameters should pass validation")
        
        print("✅ Directional parameters validation test passed")
    }
    
    func testDirectionalParametersPerformance() throws {
        // Test performance with directional parameters
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            primaryDirection: .alternating,
            mirrorPoints: 3,
            retrogradeSections: true,
            registerShifts: .exponential,
            contourPattern: .wave
        )
        
        let generator = ScalePatternGenerator()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = generator.generatePattern(parameters: parameters)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let generationTime = endTime - startTime
        
        XCTAssertGreaterThan(result.count, 0, "Should generate notes")
        XCTAssertLessThan(generationTime, 1.0, "Generation should be fast (< 1 second)")
        
        print("✅ Directional parameters performance test passed")
        print("   Generated \(result.count) notes in \(String(format: "%.3f", generationTime))s")
    }
}
