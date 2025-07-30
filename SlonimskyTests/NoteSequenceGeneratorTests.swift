import XCTest
@testable import Slonimsky

final class NoteSequenceGeneratorTests: XCTestCase {
    
    func testIntervalPatternGenerator() throws {
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
    }
    
    func testScalePatternGenerator() throws {
        let generator = ScalePatternGenerator()
        let parameters = PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
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
    
    func testRhythmicPatternGenerator() throws {
        let generator = RhythmicPatternGenerator()
        let parameters = PatternParameters(
            rootNote: 60,
            numberOfOctaves: 1,
            noteDurationPattern: .alternating
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
    }
    
    func testModulationPatternGenerator() throws {
        let generator = ModulationPatternGenerator()
        let parameters = PatternParameters(
            rootNote: 60,
            numberOfOctaves: 1
        )
        
        let result = generator.generatePattern(parameters: parameters)
        
        XCTAssertFalse(result.isEmpty, "Generated pattern should not be empty")
        XCTAssertTrue(generator.validateParameters(parameters: parameters), "Parameters should be valid")
    }
}
