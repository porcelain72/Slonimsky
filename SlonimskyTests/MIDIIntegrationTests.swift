//
//  MIDIIntegrationTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
@testable import Slonimsky

final class MIDIIntegrationTests: XCTestCase {
    
    var midiEngine: MIDIEngine!
    var midiService: MIDIIntegrationService!
    var basicParameters: PatternParameters!
    
    override func setUpWithError() throws {
        midiEngine = MIDIEngine()
        midiService = MIDIIntegrationService()
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
        midiEngine = nil
        midiService = nil
        basicParameters = nil
    }
    
    // MARK: - MIDI Engine Tests
    
    func testMIDIEngineInitialization() throws {
        XCTAssertNotNil(midiEngine)
        XCTAssertFalse(midiEngine.isPlaying)
        XCTAssertEqual(midiEngine.currentTime, 0.0)
        XCTAssertEqual(midiEngine.totalDuration, 0.0)
    }
    
    func testMIDIEngineMusicSequenceGeneration() throws {
        // Create a simple pattern result
        let notes = [
            MIDIInfo(note: 60, velocity: 80, beatLength: 0.25),
            MIDIInfo(note: 62, velocity: 80, beatLength: 0.25),
            MIDIInfo(note: 64, velocity: 80, beatLength: 0.25),
            MIDIInfo(note: 65, velocity: 80, beatLength: 0.25)
        ]
        
        let metadata = PatternMetadata(
            generatorName: "Test Generator",
            parameterHash: "test",
            generationTime: 0.001,
            noteCount: notes.count,
            pitchRange: 60...65,
            duration: 1.0
        )
        
        let performance = PerformanceMetrics(
            generationTime: 0.001,
            memoryUsage: 1024,
            complexity: 1.0
        )
        
        let result = PatternGenerationResult(
            notes: notes,
            metadata: metadata,
            performance: performance
        )
        
        let sequence = midiEngine.generateMusicSequence(from: result)
        XCTAssertNotNil(sequence)
    }
    
    func testMIDIEnginePlaybackControl() throws {
        // Test that playback controls work without crashing
        midiEngine.play()
        XCTAssertFalse(midiEngine.isPlaying) // Should not be playing without sequence
        
        midiEngine.stop()
        XCTAssertFalse(midiEngine.isPlaying)
        
        midiEngine.pause()
        XCTAssertFalse(midiEngine.isPlaying)
        
        midiEngine.resume()
        XCTAssertFalse(midiEngine.isPlaying)
    }
    
    func testMIDIEngineExport() throws {
        // Test MIDI export functionality
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.mid")
        
        // Should fail without sequence
        let success = midiEngine.exportToMIDI(url: tempURL)
        XCTAssertFalse(success)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - MIDI Integration Service Tests
    
    func testMIDIServiceInitialization() throws {
        XCTAssertNotNil(midiService)
        XCTAssertNil(midiService.currentPattern)
        XCTAssertFalse(midiService.isGenerating)
        XCTAssertEqual(midiService.generationProgress, 0.0)
        XCTAssertEqual(midiService.lastGenerationTime, 0.0)
        XCTAssertNil(midiService.errorMessage)
    }
    
    func testMIDIServicePatternGeneration() throws {
        let expectation = XCTestExpectation(description: "Pattern generation completed")
        
        midiService.generatePatternAndMIDI(
            using: "Scale Pattern Generator",
            parameters: basicParameters
        ) { result in
            switch result {
            case .success(let patternResult):
                XCTAssertNotNil(patternResult)
                XCTAssertGreaterThan(patternResult.notes.count, 0)
                XCTAssertEqual(patternResult.metadata.generatorName, "Scale Pattern Generator")
                XCTAssertLessThan(patternResult.performance.generationTime, 0.5)
            case .failure(let error):
                XCTFail("Pattern generation failed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMIDIServiceCombinedPatternGeneration() throws {
        let expectation = XCTestExpectation(description: "Combined pattern generation completed")
        
        let generatorNames = ["Scale Pattern Generator", "Interval Pattern Generator"]
        
        midiService.generateCombinedPatternAndMIDI(
            using: generatorNames,
            parameters: basicParameters,
            combinationMode: .sequential
        ) { result in
            switch result {
            case .success(let patternResult):
                XCTAssertNotNil(patternResult)
                XCTAssertGreaterThan(patternResult.notes.count, 0)
                XCTAssertTrue(patternResult.metadata.generatorName.contains("Combined"))
                XCTAssertLessThan(patternResult.performance.generationTime, 0.5)
            case .failure(let error):
                XCTFail("Combined pattern generation failed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMIDIServiceRandomPatternGeneration() throws {
        let expectation = XCTestExpectation(description: "Random pattern generation completed")
        
        midiService.generateRandomPattern { result in
            switch result {
            case .success(let patternResult):
                XCTAssertNotNil(patternResult)
                XCTAssertGreaterThan(patternResult.notes.count, 0)
                XCTAssertLessThan(patternResult.performance.generationTime, 0.5)
            case .failure(let error):
                XCTFail("Random pattern generation failed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMIDIServicePlaybackControl() throws {
        // Test playback controls without pattern
        midiService.playCurrentPattern()
        XCTAssertNil(midiService.currentPattern)
        
        midiService.stopPlayback()
        midiService.pausePlayback()
        midiService.resumePlayback()
        
        // Should not crash
        XCTAssertTrue(true)
    }
    
    func testMIDIServiceExport() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.mid")
        
        // Should fail without pattern
        let success = midiService.exportToMIDI(url: tempURL)
        XCTAssertFalse(success)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testMIDIServiceExternalMIDI() throws {
        // Test external MIDI sending without pattern
        midiService.sendToExternalMIDI(bpm: 120.0)
        
        // Should not crash
        XCTAssertTrue(true)
    }
    
    func testMIDIServiceGeneratorInfo() throws {
        let generators = midiService.getAvailableGenerators()
        XCTAssertGreaterThan(generators.count, 0)
        
        // Check that expected generators are present
        let generatorNames = generators.map { $0.name }
        XCTAssertTrue(generatorNames.contains("Scale Pattern Generator"))
        XCTAssertTrue(generatorNames.contains("Interval Pattern Generator"))
        XCTAssertTrue(generatorNames.contains("Modulation Pattern Generator"))
        XCTAssertTrue(generatorNames.contains("Rhythmic Pattern Generator"))
        XCTAssertTrue(generatorNames.contains("Harmonic Pattern Generator"))
        XCTAssertTrue(generatorNames.contains("Contour Pattern Generator"))
        XCTAssertTrue(generatorNames.contains("Symmetrical Pattern Generator"))
    }
    
    func testMIDIServiceDestinations() throws {
        let destinations = midiService.getAvailableDestinations()
        
        // May or may not have destinations depending on system
        XCTAssertNotNil(destinations)
        
        if !destinations.isEmpty {
            let firstDestination = destinations.first!
            XCTAssertNotNil(firstDestination.name)
            XCTAssertNotEqual(firstDestination.name, "")
        }
    }
    
    func testMIDIServicePlaybackStatus() throws {
        let status = midiService.getPlaybackStatus()
        XCTAssertFalse(status.isPlaying)
        XCTAssertEqual(status.currentTime, 0.0)
        XCTAssertEqual(status.totalDuration, 0.0)
        XCTAssertEqual(status.progress, 0.0)
    }
    
    // MARK: - Integration Tests
    
    func testFullIntegrationWorkflow() throws {
        let expectation = XCTestExpectation(description: "Full integration workflow completed")
        
        // 1. Generate pattern
        midiService.generatePatternAndMIDI(
            using: "Scale Pattern Generator",
            parameters: basicParameters
        ) { result in
            switch result {
            case .success(let patternResult):
                // 2. Verify pattern was generated
                XCTAssertNotNil(patternResult)
                XCTAssertGreaterThan(patternResult.notes.count, 0)
                
                // 3. Test playback controls
                self.midiService.playCurrentPattern()
                XCTAssertNotNil(self.midiService.currentPattern)
                
                // 4. Test export
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("integration_test.mid")
                let exportSuccess = self.midiService.exportToMIDI(url: tempURL)
                XCTAssertTrue(exportSuccess)
                
                // Clean up
                try? FileManager.default.removeItem(at: tempURL)
                
            case .failure(let error):
                XCTFail("Integration workflow failed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testErrorHandling() throws {
        // Test with invalid generator name
        let expectation = XCTestExpectation(description: "Error handling test completed")
        
        midiService.generatePatternAndMIDI(
            using: "Non-existent Generator",
            parameters: basicParameters
        ) { result in
            switch result {
            case .success(_):
                XCTFail("Should have failed with non-existent generator")
            case .failure(let error):
                XCTAssertNotNil(error)
                XCTAssertTrue(error is MIDIIntegrationError)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testGenerationPerformance() throws {
        let expectation = XCTestExpectation(description: "Performance test completed")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        midiService.generatePatternAndMIDI(
            using: "Scale Pattern Generator",
            parameters: basicParameters
        ) { result in
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            
            switch result {
            case .success(let patternResult):
                XCTAssertLessThan(patternResult.performance.generationTime, 0.5)
                XCTAssertLessThan(totalTime, 1.0) // Total time including MIDI generation
            case .failure(let error):
                XCTFail("Performance test failed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testComplexPatternPerformance() throws {
        let expectation = XCTestExpectation(description: "Complex pattern performance test completed")
        
        let complexParameters = PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 3,
            divisionsOfOctave: 12,
            tempo: 120.0,
            timeSignature: .common,
            primaryInterval: 2,
            secondaryInterval: 3,
            intervalPattern: .alternating,
            intervalInversion: true,
            symmetricalIntervals: true,
            interpolation: ModulationSettings(numberOfNotes: 2, interval: 1, enabled: true),
            infrapolation: ModulationSettings(numberOfNotes: 1, interval: 1, enabled: true),
            ultrapolation: ModulationSettings(numberOfNotes: 1, interval: 1, enabled: true),
            primaryDirection: .ascending,
            mirrorPoints: 2,
            retrogradeSections: true,
            registerShifts: .linear,
            contourPattern: .wave,
            noteDurationPattern: .progressive,
            baseNoteDuration: 0.25,
            rhythmicDensity: 1.5,
            syncopationLevel: 0.5,
            metricModulation: MetricModulationSettings(enabled: true, modulationType: .accelerando, intensity: 0.7, frequency: 4),
            harmonicMode: .polymodal,
            chordGeneration: ChordSettings(enabled: true, chordSize: 4, voicingPreference: .open, velocityScale: 0.8),
            harmonicRhythm: HarmonicRhythmSettings(chordChangeFrequency: 3, syncopationLevel: 0.4, harmonicTension: 0.6),
            velocitySettings: VelocitySettings(baseVelocity: 85, range: 45, waveDepth: 0.7, randomness: 0.3, phase: 1.0, emphasisBeat: 3, emphasisAmount: 0.5),
            toneShifting: ToneShiftSettings(toneIncrement: 6, maxToneShift: 12, shiftPattern: .exponential)
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        midiService.generatePatternAndMIDI(
            using: "Modulation Pattern Generator",
            parameters: complexParameters
        ) { result in
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            
            switch result {
            case .success(let patternResult):
                XCTAssertLessThan(patternResult.performance.generationTime, 0.5)
                XCTAssertLessThan(totalTime, 1.0)
                XCTAssertGreaterThan(patternResult.notes.count, 50) // Should generate many notes
            case .failure(let error):
                XCTFail("Complex pattern performance test failed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
} 