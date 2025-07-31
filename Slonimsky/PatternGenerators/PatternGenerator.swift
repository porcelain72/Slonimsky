//
//  PatternGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Core protocol for all pattern generators in the Slonimsky system
protocol PatternGenerator {
    /// Generate a musical pattern based on the given parameters
    /// - Parameter parameters: The pattern generation parameters
    /// - Returns: Array of MIDI note information
    func generatePattern(parameters: PatternParameters) -> [MIDIInfo]
    
    /// Generate a musical pattern with cyclical parameter support
    /// - Parameters:
    ///   - parameters: The pattern generation parameters
    ///   - cycleIndex: The current cycle index for cyclical parameters
    /// - Returns: Array of MIDI note information
    func generatePattern(parameters: PatternParameters, cycleIndex: Int) -> [MIDIInfo]
    
    /// Estimate the number of notes that will be generated
    /// - Parameter parameters: The pattern generation parameters
    /// - Returns: Estimated note count
    func estimateNoteCount(parameters: PatternParameters) -> Int
    
    /// Validate that the parameters are suitable for this generator
    /// - Parameter parameters: The pattern generation parameters
    /// - Returns: True if parameters are valid
    func validateParameters(parameters: PatternParameters) -> Bool
    
    /// Get the name of this pattern generator
    var name: String { get }
    
    /// Get a description of what this generator does
    var description: String { get }
}

/// Base implementation for pattern generators
class BasePatternGenerator: PatternGenerator {
    let name: String
    let description: String
    
    init(name: String, description: String) {
        self.name = name
        self.description = description
    }
    
    func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        return generatePattern(parameters: parameters, cycleIndex: 0)
    }
    
    func generatePattern(parameters: PatternParameters, cycleIndex: Int) -> [MIDIInfo] {
        fatalError("Subclasses must implement generatePattern with cycleIndex")
    }
    
    func estimateNoteCount(parameters: PatternParameters) -> Int {
        fatalError("Subclasses must implement estimateNoteCount")
    }
    
    func validateParameters(parameters: PatternParameters) -> Bool {
        return parameters.validate()
    }
    
    // MARK: - Helper Methods
    
    /// Calculate note duration based on pattern parameters
    func calculateNoteDuration(
        baseDuration: TimeInterval,
        pattern: DurationPattern,
        index: Int,
        density: Double
    ) -> TimeInterval {
        switch pattern {
        case .uniform:
            return baseDuration
            
        case .alternating:
            return index % 2 == 0 ? baseDuration : baseDuration * 0.5
            
        case .progressive:
            let progression = 1.0 + (Double(index) * 0.1)
            return baseDuration * progression
            
        case .random:
            let randomFactor = Double.random(in: 0.5...1.5)
            return baseDuration * randomFactor
        }
    }
    
    /// Apply register shifts to notes
    func applyRegisterShifts(
        notes: [Int],
        pattern: RegisterShiftPattern,
        maxShift: Int
    ) -> [Int] {
        guard maxShift > 0 else { return notes }
        
        return notes.enumerated().map { index, note in
            let shift = pattern.calculateShift(
                baseNote: note,
                index: index,
                maxShift: maxShift
            )
            return note + shift
        }
    }
    
    /// Apply contour patterns to melodic shapes
    func applyContourPattern(
        notes: [Int],
        pattern: ContourPattern,
        intensity: Double = 0.5
    ) -> [Int] {
        guard notes.count > 1 else { return notes }
        
        // Calculate the original range and center
        let originalRange = notes.max()! - notes.min()!
        let _ = notes.min()! + (originalRange / 2)
        
        return notes.enumerated().map { index, note in
            let normalizedIndex = Double(index) / Double(notes.count - 1)
            let contourOffset: Double
            
            switch pattern {
            case .linear:
                contourOffset = normalizedIndex
                
            case .arch:
                contourOffset = sin(normalizedIndex * .pi)
                
            case .invertedArch:
                contourOffset = 1.0 - sin(normalizedIndex * .pi)
                
            case .wave:
                contourOffset = sin(normalizedIndex * .pi * 2)
                
            case .random:
                contourOffset = Double.random(in: 0...1)
                
            case .mirror:
                contourOffset = 1.0 - abs(2.0 * normalizedIndex - 1.0)
            }
            
            // Apply contour as a modification to the existing note, not a complete recalculation
            let contourShift = Int(Double(originalRange) * (contourOffset - 0.5) * intensity)
            let modifiedNote = note + contourShift
            
            // Ensure the note stays within valid MIDI range
            return max(0, min(127, modifiedNote))
        }
    }
    
    /// Calculate velocity for a note with context
    func calculateVelocity(
        for noteIndex: Int,
        note: Int,
        settings: VelocitySettings,
        harmonicContext: HarmonicContext? = nil
    ) -> UInt8 {
        if let context = harmonicContext {
            return settings.calculateVelocityWithHarmonicContext(
                for: noteIndex,
                note: note,
                harmonicTension: context.tension,
                melodicContour: context.contour
            )
        } else {
            return settings.calculateVelocity(for: noteIndex, note: note)
        }
    }
    
    // MARK: - Cyclical Parameter Helpers
    
    /// Apply cyclical parameter changes to a value
    func applyCyclicalParameter(
        baseValue: Double,
        settings: CyclicalParameterSettings,
        cycleIndex: Int
    ) -> Double {
        guard settings.isEnabled else { return baseValue }
        
        let adjustedCycle = cycleIndex % settings.maxCycles
        let cyclicalValue = settings.minValue + (Double(adjustedCycle) * settings.stepSize)
        
        // Clamp to max value
        let clampedValue = min(cyclicalValue, settings.maxValue)
        
        // Apply to base value based on operation type
        switch settings.operationType {
        case .replace:
            return clampedValue
        case .add:
            return baseValue + clampedValue
        case .multiply:
            return baseValue * clampedValue
        case .modulate:
            let modulation = sin(Double(adjustedCycle) * .pi / Double(settings.maxCycles))
            return baseValue + (modulation * settings.maxValue)
        }
    }
    
    /// Get cyclical parameter value for a specific parameter
    func getCyclicalValue(
        for parameter: CyclicalParameterType,
        settings: CyclicalSettings,
        cycleIndex: Int
    ) -> Double? {
        let parameterSettings: CyclicalParameterSettings?
        
        switch parameter {
        case .interpolationNotes:
            parameterSettings = settings.interpolationNotes
        case .infrapolationNotes:
            parameterSettings = settings.infrapolationNotes
        case .ultrapolationNotes:
            parameterSettings = settings.ultrapolationNotes
        case .baseNoteDuration:
            parameterSettings = settings.baseNoteDuration
        case .rhythmicDensity:
            parameterSettings = settings.rhythmicDensity
        case .primaryInterval:
            parameterSettings = settings.primaryInterval
        case .secondaryInterval:
            parameterSettings = settings.secondaryInterval
        case .baseVelocity:
            parameterSettings = settings.baseVelocity
        case .velocityRange:
            parameterSettings = settings.velocityRange
        }
        
        guard let settings = parameterSettings, settings.isEnabled else { return nil }
        return applyCyclicalParameter(baseValue: 0.0, settings: settings, cycleIndex: cycleIndex)
    }
}

/// Harmonic context for velocity calculation
struct HarmonicContext {
    let tension: Double // 0.0 to 1.0
    let contour: Double // -1.0 to 1.0
    let function: HarmonicFunction
    
    init(tension: Double = 0.5, contour: Double = 0.0, function: HarmonicFunction = .tonic) {
        self.tension = tension
        self.contour = contour
        self.function = function
    }
}

/// Harmonic functions for context
enum HarmonicFunction: String, CaseIterable {
    case tonic = "Tonic"
    case dominant = "Dominant"
    case subdominant = "Subdominant"
    case leadingTone = "Leading Tone"
    case passing = "Passing"
    case neighbor = "Neighbor"
    
    var tensionLevel: Double {
        switch self {
        case .tonic: return 0.0
        case .subdominant: return 0.3
        case .dominant: return 0.7
        case .leadingTone: return 0.9
        case .passing: return 0.5
        case .neighbor: return 0.4
        }
    }
}

/// Result of pattern generation with metadata
struct PatternGenerationResult {
    let notes: [MIDIInfo]
    let metadata: PatternMetadata
    let performance: PerformanceMetrics
    
    init(notes: [MIDIInfo], metadata: PatternMetadata, performance: PerformanceMetrics) {
        self.notes = notes
        self.metadata = metadata
        self.performance = performance
    }
}

/// Metadata about the generated pattern
struct PatternMetadata {
    let generatorName: String
    let parameterHash: String
    let generationTime: TimeInterval
    let noteCount: Int
    let pitchRange: ClosedRange<Int>
    let duration: TimeInterval
    let cycleIndex: Int
    
    init(
        generatorName: String,
        parameterHash: String,
        generationTime: TimeInterval,
        noteCount: Int,
        pitchRange: ClosedRange<Int>,
        duration: TimeInterval,
        cycleIndex: Int = 0
    ) {
        self.generatorName = generatorName
        self.parameterHash = parameterHash
        self.generationTime = generationTime
        self.noteCount = noteCount
        self.pitchRange = pitchRange
        self.duration = duration
        self.cycleIndex = cycleIndex
    }
}

/// Performance metrics for pattern generation
struct PerformanceMetrics {
    let generationTime: TimeInterval
    let memoryUsage: Int64
    let complexity: Double
    
    init(generationTime: TimeInterval, memoryUsage: Int64, complexity: Double) {
        self.generationTime = generationTime
        self.memoryUsage = memoryUsage
        self.complexity = complexity
    }
} 