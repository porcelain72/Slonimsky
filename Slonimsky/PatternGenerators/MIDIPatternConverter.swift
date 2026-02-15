//
//  MIDIPatternConverter.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Service responsible for converting mathematical note patterns to MIDI information
/// Separates pure mathematical pattern generation from MIDI-specific attributes (velocity, duration)
class MIDIPatternConverter {
    
    // MARK: - Main Conversion Methods
    
    /// Convert a mathematical note pattern to MIDI information
    /// - Parameters:
    ///   - notes: Array of MIDI note numbers (0-127)
    ///   - parameters: Pattern parameters for velocity and duration calculation
    ///   - indexOffset: Starting index offset for velocity/duration calculations
    /// - Returns: Array of MIDIInfo with velocity and duration applied
    static func convertToMIDIInfo(
        notes: [Int],
        parameters: PatternParameters,
        indexOffset: Int = 0
    ) -> [MIDIInfo] {
        return notes.enumerated().map { index, note in
            let globalIndex = indexOffset + index
            
            let duration = calculateNoteDuration(
                baseDuration: parameters.baseNoteDuration,
                pattern: parameters.noteDurationPattern,
                index: globalIndex,
                density: parameters.rhythmicDensity
            )
            
            let velocity = calculateVelocity(
                for: globalIndex,
                note: note,
                settings: parameters.velocitySettings
            )
            
            return MIDIInfo(
                note: note,
                velocity: velocity,
                beatLength: duration,
                cycleIndex: 0
            )
        }
    }
    
    /// Apply Slonimsky modulations to note patterns (mathematical operation before MIDI conversion)
    /// - Parameters:
    ///   - notes: Array of MIDI note numbers
    ///   - parameters: Pattern parameters containing modulation settings
    /// - Returns: Expanded array of note numbers with modulations applied
    static func applySlonimskyModulations(
        notes: [Int],
        parameters: PatternParameters
    ) -> [Int] {
        var result: [Int] = []
        
        for (index, note) in notes.enumerated() {
            // Add the base note
            result.append(note)
            
            // Apply interpolation (notes between existing notes)
            if parameters.interpolation.enabled && index < notes.count - 1 {
                let interpolatedNotes = generateInterpolatedNotes(
                    from: note,
                    to: notes[index + 1],
                    settings: parameters.interpolation
                )
                result.append(contentsOf: interpolatedNotes)
            }
            
            // Apply infrapolation (notes below existing notes)
            if parameters.infrapolation.enabled && index < notes.count - 1 {
                let infrapolatedNotes = generateInfrapolatedNotes(
                    baseNote: note,
                    settings: parameters.infrapolation
                )
                result.append(contentsOf: infrapolatedNotes)
            }
            
            // Apply ultrapolation (notes above existing notes)
            if parameters.ultrapolation.enabled && index < notes.count - 1 {
                let ultrapolatedNotes = generateUltrapolatedNotes(
                    baseNote: note,
                    nextNote: notes[index + 1],
                    settings: parameters.ultrapolation
                )
                result.append(contentsOf: ultrapolatedNotes)
            }
        }
        
        return result
    }
    
    /// Complete conversion: Apply iterations (optional), modulations, then convert to MIDI
    /// When iterations > 1, the pattern is re-processed: ParameterApplicationManager + modulations
    /// are applied repeatedly before MIDI conversion.
    /// - Parameters:
    ///   - notes: Base note pattern (already has ParameterApplicationManager applied from generator)
    ///   - parameters: Pattern parameters
    ///   - indexOffset: Starting index offset
    ///   - generatorType: Generator type for ParameterApplicationManager (e.g. "Scale", "Interval")
    /// - Returns: Final MIDIInfo array
    static func convertWithModulations(
        notes: [Int],
        parameters: PatternParameters,
        indexOffset: Int = 0,
        generatorType: String = "Scale"
    ) -> [MIDIInfo] {
        var currentNotes = notes
        
        // Randomise note order if enabled (before iterations and modulations)
        if parameters.randomiseOrder {
            currentNotes.shuffle()
        }
        
        // Iteration 1: apply modulations (notes already have ParameterApplicationManager from generator)
        currentNotes = applySlonimskyModulations(
            notes: currentNotes,
            parameters: parameters
        )
        
        // Iterations 2..<N: re-apply ParameterApplicationManager then modulations
        // Mirror is skipped in iterations—it runs only in the initial generator
        for _ in 1..<parameters.iterations {
            currentNotes = ParameterApplicationManager.applyParameters(
                baseNotes: currentNotes,
                parameters: parameters,
                generatorType: generatorType,
                skipMirror: true
            )
            currentNotes = applySlonimskyModulations(
                notes: currentNotes,
                parameters: parameters
            )
        }
        
        // Convert to MIDI (velocity, duration)
        return convertToMIDIInfo(
            notes: currentNotes,
            parameters: parameters,
            indexOffset: indexOffset
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func generateInterpolatedNotes(
        from startNote: Int,
        to endNote: Int,
        settings: ModulationSettings
    ) -> [Int] {
        var notes: [Int] = []
        
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let interpolatedNote = startNote + interval
            
            // Ensure note is within valid MIDI range
            // Allow notes beyond the target note for extended interpolation
            if interpolatedNote >= 0 && interpolatedNote <= 127 {
                notes.append(interpolatedNote)
            }
        }
        
        return notes
    }
    
    private static func generateInfrapolatedNotes(
        baseNote: Int,
        settings: ModulationSettings
    ) -> [Int] {
        var notes: [Int] = []
        
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let infrapolatedNote = baseNote - interval
            
            if infrapolatedNote >= 0 && infrapolatedNote <= 127 {
                notes.append(infrapolatedNote)
            }
        }
        
        return notes
    }
    
    private static func generateUltrapolatedNotes(
        baseNote: Int,
        nextNote: Int,
        settings: ModulationSettings
    ) -> [Int] {
        var notes: [Int] = []
        
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let ultrapolatedNote = nextNote - interval
            
            // Allow notes beyond the base note for extended ultrapolation
            if ultrapolatedNote >= 0 && ultrapolatedNote <= 127 {
                notes.append(ultrapolatedNote)
            }
        }
        
        return notes
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
