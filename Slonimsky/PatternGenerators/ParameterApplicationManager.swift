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
        case directionalPatterns = 1 // Primary direction, interval patterns
        case registerShifts = 2      // Tone shifting, register shifts
        case contourPatterns = 3     // Contour patterns (with reduced intensity)
        case velocitySettings = 4    // Velocity calculations
        case durationPatterns = 5    // Note duration patterns
        case modulations = 6         // Slonimsky modulations (final)
    }
    
    /// Applies parameters in the correct order to prevent conflicts
    static func applyParameters(
        baseNotes: [Int],
        parameters: PatternParameters,
        generatorType: String
    ) -> [MIDIInfo] {
        var currentNotes = baseNotes
        
        // Apply parameters in priority order
        for priority in ParameterPriority.allCases {
            currentNotes = applyParameterGroup(
                notes: currentNotes,
                priority: priority,
                parameters: parameters,
                generatorType: generatorType
            )
        }
        
        // Convert to MIDIInfo with final velocity and duration
        return convertToMIDIInfo(
            notes: currentNotes,
            parameters: parameters
        )
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
            
        case .directionalPatterns:
            return applyDirectionalPatterns(notes: notes, parameters: parameters, generatorType: generatorType)
            
        case .registerShifts:
            return applyRegisterShifts(notes: notes, parameters: parameters)
            
        case .contourPatterns:
            return applyContourPatterns(notes: notes, parameters: parameters, generatorType: generatorType)
            
        case .velocitySettings, .durationPatterns, .modulations:
            // These are applied during MIDIInfo conversion
            return notes
        }
    }
    
    private static func applyDirectionalPatterns(notes: [Int], parameters: PatternParameters, generatorType: String) -> [Int] {
        var modifiedNotes = notes
        
        // Apply primary direction
        switch parameters.primaryDirection {
        case .ascending:
            // Notes are already in ascending order, no change needed
            break
        case .descending:
            modifiedNotes = notes.reversed()
        case .alternating:
            modifiedNotes = applyAlternatingDirection(notes: notes)
        }
        
        // Apply interval patterns if applicable (but not for scale generators)
        if !notes.isEmpty && !generatorType.contains("Scale") {
            modifiedNotes = applyIntervalPatterns(notes: modifiedNotes, parameters: parameters)
        }
        
        return modifiedNotes
    }
    
    private static func applyAlternatingDirection(notes: [Int]) -> [Int] {
        var result: [Int] = []
        let midPoint = notes.count / 2
        
        // First half ascending
        result.append(contentsOf: notes.prefix(midPoint))
        
        // Second half descending
        result.append(contentsOf: notes.suffix(notes.count - midPoint).reversed())
        
        return result
    }
    
    private static func applyIntervalPatterns(notes: [Int], parameters: PatternParameters) -> [Int] {
        // Only apply if we have interval-specific parameters
        guard parameters.primaryInterval > 0 else { return notes }
        
        var result: [Int] = []
        let rootNote = parameters.rootNote
        
        for (index, _) in notes.enumerated() {
            let interval = index % 2 == 0 ? parameters.primaryInterval : parameters.secondaryInterval
            
            switch parameters.intervalPattern {
            case .ascending:
                result.append(rootNote + (index * interval))
            case .descending:
                result.append(rootNote - (index * interval))
            case .alternating:
                let direction = index % 2 == 0 ? 1 : -1
                result.append(rootNote + (direction * index * interval))
            case .mirror:
                let mirrorIndex = index % (parameters.mirrorPoints * 2)
                let direction = mirrorIndex < parameters.mirrorPoints ? 1 : -1
                result.append(rootNote + (direction * index * interval))
            case .retrograde:
                result.append(rootNote + ((notes.count - 1 - index) * interval))
            }
        }
        
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
        // Skip contour patterns for interval and scale generators to preserve their relationships
        if generatorType.contains("Interval") || generatorType.contains("Scale") {
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
    
    private static func convertToMIDIInfo(notes: [Int], parameters: PatternParameters) -> [MIDIInfo] {
        return notes.enumerated().map { index, note in
            let duration = calculateNoteDuration(
                baseDuration: parameters.baseNoteDuration,
                pattern: parameters.noteDurationPattern,
                index: index,
                density: parameters.rhythmicDensity
            )
            
            let velocity = calculateVelocity(
                for: index,
                note: note,
                settings: parameters.velocitySettings
            )
            
            return MIDIInfo(
                note: note,
                velocity: velocity,
                beatLength: duration
            )
        }
    }
    
    private static func calculateNoteDuration(
        baseDuration: TimeInterval,
        pattern: DurationPattern,
        index: Int,
        density: Double
    ) -> TimeInterval {
        var duration = baseDuration
        
        switch pattern {
        case .uniform:
            break
        case .alternating:
            duration = index % 2 == 0 ? baseDuration : baseDuration * 0.7
        case .progressive:
            duration *= 1.0 + (Double(index) * 0.05)
        case .random:
            duration *= Double.random(in: 0.7...1.3)
        }
        
        // Apply rhythmic density
        duration /= density
        
        return max(duration, 0.0625) // Minimum duration
    }
    
    private static func calculateVelocity(
        for index: Int,
        note: Int,
        settings: VelocitySettings
    ) -> UInt8 {
        return settings.calculateVelocity(for: index, note: note)
    }
} 