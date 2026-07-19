//
//  ParameterApplicationManager.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Manages the application of parameters in a specific order to prevent conflicts
class ParameterApplicationManager {
    
    /// Defines the priority order for parameter application
    enum ParameterPriority: Int, CaseIterable {
        case baseGeneration = 0      // Root note, scale type, intervals
        case mirrorPattern = 1       // Mirror/invert sequence
        case registerShifts = 2      // Tone shifting, register shifts
        case contourPatterns = 3     // Contour patterns (with reduced intensity)
        case velocitySettings = 4    // Velocity calculations
        case durationPatterns = 5    // Note duration patterns
        case modulations = 6         // Slonimsky modulations (final)
    }
    
    /// Applies parameters in the correct order to prevent conflicts
    /// Returns pure note numbers (no MIDI conversion - use MIDIPatternConverter for that)
    /// - Parameter skipMirror: When true, mirror is skipped (e.g. for iteration passes where mirror runs only in the initial generator)
    static func applyParameters(
        baseNotes: [Int],
        parameters: PatternParameters,
        generatorType: String,
        skipMirror: Bool = false
    ) -> [Int] {
        var currentNotes = baseNotes
        
        // Apply parameters in priority order
        for priority in ParameterPriority.allCases {
            if skipMirror && priority == .mirrorPattern { continue }
            currentNotes = applyParameterGroup(
                notes: currentNotes,
                priority: priority,
                parameters: parameters,
                generatorType: generatorType
            )
        }
        
        // Return pure note numbers - MIDI conversion happens separately
        return currentNotes
    }
    
    private static func applyParameterGroup(
        notes: [Int],
        priority: ParameterPriority,
        parameters: PatternParameters,
        generatorType: String
    ) -> [Int] {
        switch priority {
        case .baseGeneration:
            // Base generation is already done, just return notes
            return notes
            
        case .mirrorPattern:
            return applyMirrorPattern(notes: notes, parameters: parameters)
            
        case .registerShifts:
            return applyRegisterShifts(notes: notes, parameters: parameters)
            
        case .contourPatterns:
            return applyContourPatterns(notes: notes, parameters: parameters, generatorType: generatorType)
            
        case .velocitySettings, .durationPatterns, .modulations:
            // These are applied during MIDI conversion (via MIDIPatternConverter)
            // Not applied during pattern generation phase
            return notes
        }
    }
    
    /// Apply mirror pattern: when enabled, appends reversed sequence (arpeggio effect)
    /// Creates a pattern that ascends and then descends back to start
    /// Example: [60, 62, 64] becomes [60, 62, 64, 62, 60]
    private static func applyMirrorPattern(notes: [Int], parameters: PatternParameters) -> [Int] {
        guard parameters.mirror else { return notes }
        
        var result = notes
        
        // Create descending sequence by reversing and skipping the last note to avoid repetition
        guard notes.count > 1 else { return notes }
        
        // Reverse the sequence and drop the first element to avoid repeating the top note
        let descendingNotes = Array(notes.reversed().dropFirst())
            .filter { $0 >= 0 && $0 <= 127 }
        
        // Append descending sequence to create arpeggio effect
        result.append(contentsOf: descendingNotes)
        
        return result
    }
    
    private static func applyRegisterShifts(notes: [Int], parameters: PatternParameters) -> [Int] {
        guard parameters.toneShifting.maxToneShift > 0 else { return notes }
        
        return notes.enumerated().map { index, note in
            let shift = calculateRegisterShift(
                index: index,
                pattern: parameters.registerShifts,
                maxShift: parameters.toneShifting.maxToneShift,
                toneIncrement: parameters.toneShifting.toneIncrement
            )
            return max(0, min(127, note + shift))
        }
    }
    
    private static func calculateRegisterShift(
        index: Int,
        pattern: RegisterShiftPattern,
        maxShift: Int,
        toneIncrement: Int
    ) -> Int {
        switch pattern {
        case .none:
            return 0
        case .linear:
            return min(maxShift, index * toneIncrement)
        case .exponential:
            let normalizedIndex = Double(index) / 100.0
            let shift = Int(Double(maxShift) * pow(normalizedIndex, 2))
            return min(shift, maxShift)
        case .random:
            return Int.random(in: -maxShift...maxShift)
        case .mirror:
            let normalizedIndex = Double(index) / 100.0
            let shift = Int(Double(maxShift) * sin(normalizedIndex * .pi))
            return abs(shift)
        case .symmetrical:
            let normalizedIndex = Double(index) / 100.0
            let shift = Int(Double(maxShift) * (1.0 - abs(2.0 * normalizedIndex - 1.0)))
            return shift
        }
    }
    
    private static func applyContourPatterns(
        notes: [Int],
        parameters: PatternParameters,
        generatorType: String
    ) -> [Int] {
        // Skip contour patterns for interval, scale, and melody generators to
        // preserve their pitch relationships (a user's entered melody must play
        // back verbatim unless explicitly transformed)
        if generatorType.contains("Interval") || generatorType.contains("Scale") || generatorType.contains("Melody") {
            return notes
        }
        
        // Apply contour patterns with reduced intensity to preserve other parameter effects
        let intensity: Double
        switch generatorType {
        case let type where type.contains("Scale"):
            intensity = 0.3 // Reduced intensity for scale generators
        case let type where type.contains("Contour"):
            intensity = 0.8 // Higher intensity for contour generators
        default:
            intensity = 0.5 // Default intensity
        }
        
        return applyContourPattern(
            notes: notes,
            pattern: parameters.contourPattern,
            intensity: intensity
        )
    }
    
    private static func applyContourPattern(
        notes: [Int],
        pattern: ContourPattern,
        intensity: Double
    ) -> [Int] {
        guard notes.count > 1 else { return notes }
        
        let originalRange = notes.max()! - notes.min()!
        
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
            
            // Apply contour as a modification to the existing note
            let contourShift = Int(Double(originalRange) * (contourOffset - 0.5) * intensity)
            let modifiedNote = note + contourShift
            
            return max(0, min(127, modifiedNote))
        }
    }
    
    // Note: MIDI conversion methods have been moved to MIDIPatternConverter
    // This class now only handles mathematical pattern transformations
} 