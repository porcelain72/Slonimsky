//
//  AutoGenerationFlowTests.swift
//  SlonimskyTests
//
//  Created by Peter Macdonald on 27/01/2025.
//

import XCTest
import Combine
@testable import Slonimsky

/// Tests for auto-generation flow and parameter change handling
class AutoGenerationFlowTests: XCTestCase {
    
    var parameterManager: ParameterManager!
    var midiService: MIDIIntegrationService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        parameterManager = ParameterManager()
        midiService = MIDIIntegrationService()
        cancellables = Set<AnyCancellable>()
        
        // Set up auto-generation
        midiService.setupAutoGeneration(with: parameterManager)
    }
    
    override func tearDown() {
        cancellables.removeAll()
        parameterManager = nil
        midiService = nil
        super.tearDown()
    }
    
    // MARK: - Basic Auto-generation Tests
    
    func testAutoGenerationSetup() {
        // Test that auto-generation is properly set up
        XCTAssertFalse(parameterManager.autoGenerateEnabled, "Auto-generation should be disabled by default")
        
        // Enable auto-generation
        parameterManager.autoGenerateEnabled = true
        XCTAssertTrue(parameterManager.autoGenerateEnabled, "Auto-generation should be enabled")
    }
    
    func testParameterChangeTriggersAutoGeneration() {
        // Enable auto-generation
        parameterManager.autoGenerateEnabled = true
        
        let expectation = XCTestExpectation(description: "Auto-generation should be triggered")
        expectation.expectedFulfillmentCount = 1
        
        // Monitor auto-generation publisher
        parameterManager.autoGenerationPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Change a parameter
        parameterManager.rootNote = 65
        
        // Wait for auto-generation to be triggered
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testAutoGenerationDisabledDoesNotTrigger() {
        // Ensure auto-generation is disabled
        parameterManager.autoGenerateEnabled = false
        
        let expectation = XCTestExpectation(description: "Auto-generation should not be triggered when disabled")
        expectation.isInverted = true // Should not be fulfilled
        
        // Monitor auto-generation publisher
        parameterManager.autoGenerationPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Change a parameter
        parameterManager.rootNote = 65
        
        // Wait to ensure no auto-generation is triggered
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Generator Selection Tests
    
    func testAutomaticGeneratorSelection() {
        // Enable automatic generator selection
        parameterManager.automaticGeneratorSelectionEnabled = true
        
        // Initially should have Scale Pattern Generator
        XCTAssertEqual(parameterManager.activeGenerators, ["Scale Pattern Generator"])
        
        // Change interval parameters to trigger Interval Pattern Generator
        parameterManager.primaryInterval = 3
        parameterManager.intervalPattern = .alternating
        
        // Should now include Interval Pattern Generator
        XCTAssertTrue(parameterManager.activeGenerators.contains("Interval Pattern Generator"))
        XCTAssertTrue(parameterManager.activeGenerators.contains("Scale Pattern Generator"))
    }
    
    func testCombinationModeSelection() {
        // Enable automatic generator selection
        parameterManager.automaticGeneratorSelectionEnabled = true
        
        // Initially should be sequential (single generator)
        XCTAssertEqual(parameterManager.combinationMode, .sequential)
        
        // Add interval parameters to trigger multiple generators
        parameterManager.primaryInterval = 3
        parameterManager.secondaryInterval = 5
        
        // Should now have multiple generators and appropriate combination mode
        XCTAssertTrue(parameterManager.activeGenerators.count > 1)
        XCTAssertTrue(parameterManager.activeGenerators.contains("Interval Pattern Generator"))
    }
    
    // MARK: - Error Handling Tests
    
    func testParameterValidationDuringAutoGeneration() {
        // Enable auto-generation
        parameterManager.autoGenerateEnabled = true
        
        let expectation = XCTestExpectation(description: "Should handle invalid parameters gracefully")
        
        // Monitor for errors
        midiService.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Set invalid parameters
        parameterManager.rootNote = -1 // Invalid root note
        parameterManager.tempo = 500 // Invalid tempo
        
        // Wait for error handling
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Reset Functionality Tests
    
    func testResetAutoGeneration() {
        // Enable auto-generation
        parameterManager.autoGenerateEnabled = true
        
        // Set an error state
        midiService.errorMessage = "Test error"
        midiService.isGenerating = true
        
        // Reset auto-generation
        midiService.resetAutoGeneration()
        
        // Check that error is cleared
        XCTAssertNil(midiService.errorMessage, "Error message should be cleared after reset")
        XCTAssertFalse(midiService.isGenerating, "Generating state should be reset")
    }
} 