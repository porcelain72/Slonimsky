//
//  IntervalPatternGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Generates interval-based patterns according to Slonimsky's Thesaurus
class IntervalPatternGenerator: BasePatternGenerator {
    
    init() {
        super.init(
            name: "Interval Pattern Generator",
            description: "Generates melodic patterns based on interval cycles, inversions, and symmetrical interval relationships"
        )
    }
    
    // MARK: - New Pattern Generation (Pure Mathematical)
    
    /// Generate a pure mathematical note pattern (note numbers only)
    override func generateNotePattern(parameters: PatternParameters, cycleIndex: Int, parameterCycles: [CyclicalParameterType: Int]? = nil) -> [Int] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Apply cyclical changes to parameters for the current cycle
        let modifiedParameters = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex, parameterCycles: parameterCycles)
        
        // Generate base interval sequence
        let intervalSequence = generateIntervalSequence(parameters: modifiedParameters)
        
        // Apply interval patterns (ascending, descending, alternating, etc.)
        let patternSequence = applyIntervalPatterns(intervals: intervalSequence, parameters: modifiedParameters)
        
        // Convert intervals to absolute notes
        let absoluteNotes = convertIntervalsToNotes(
            intervals: patternSequence,
            rootNote: modifiedParameters.rootNote
        )
        
        // Apply symmetrical transformations if enabled
        let symmetricalNotes = applySymmetricalTransformations(
            notes: absoluteNotes,
            parameters: modifiedParameters
        )
        
        // Use ParameterApplicationManager to apply remaining parameters in correct order
        // This returns pure note numbers (no MIDI conversion)
        let finalNotes = ParameterApplicationManager.applyParameters(
            baseNotes: symmetricalNotes,
            parameters: modifiedParameters,
            generatorType: "Interval"
        )
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log performance metrics
        logPerformanceMetrics(
            generationTime: generationTime,
            noteCount: finalNotes.count,
            parameters: modifiedParameters
        )
        
        return finalNotes
    }
    
    // MARK: - Legacy Pattern Generation (with MIDI conversion)
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        return generatePattern(parameters: parameters, cycleIndex: 0, parameterCycles: nil)
    }
    
    override func generatePattern(parameters: PatternParameters, cycleIndex: Int, parameterCycles: [CyclicalParameterType: Int]? = nil) -> [MIDIInfo] {
        // Generate pure note pattern first
        let notePattern = generateNotePattern(parameters: parameters, cycleIndex: cycleIndex, parameterCycles: parameterCycles)
        
        // Convert to MIDI with modulations and iterations applied
        return MIDIPatternConverter.convertWithModulations(
            notes: notePattern,
            parameters: parameters,
            generatorType: "Interval"
        )
    }
    
    override func estimateNoteCount(parameters: PatternParameters) -> Int {
        let baseCount = parameters.totalNotes
        
        // Interval patterns may create additional notes through inversions
        let inversionMultiplier = parameters.intervalInversion ? 2.0 : 1.0
        
        // Symmetrical intervals may double the note count
        let symmetryMultiplier = parameters.symmetricalIntervals ? 2.0 : 1.0
        
        // Calculate modulation multipliers
        let interpMultiplier = 1.0 + Double(parameters.interpolation.numberOfNotes)
        let infraMultiplier = 1.0 + Double(parameters.infrapolation.numberOfNotes)
        let ultraMultiplier = 1.0 + Double(parameters.ultrapolation.numberOfNotes)
        let modulationMultiplier = interpMultiplier * infraMultiplier * ultraMultiplier
        
        return Int(Double(baseCount) * inversionMultiplier * symmetryMultiplier * modulationMultiplier)
    }
    
    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        
        // Interval-specific validation
        guard parameters.primaryInterval >= 1 && parameters.primaryInterval <= 12 else {
            return false
        }
        
        guard parameters.secondaryInterval >= 1 && parameters.secondaryInterval <= 12 else {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func generateIntervalSequence(parameters: PatternParameters) -> [Int] {
        var intervals: [Int] = []
        
        // Generate primary interval sequence
        for i in 0..<parameters.totalNotes {
            // Use primary interval for all notes unless secondary interval is different
            if i % 2 == 1 && parameters.secondaryInterval != parameters.primaryInterval {
                intervals.append(parameters.secondaryInterval)
            } else {
                intervals.append(parameters.primaryInterval)
            }
        }
        
        return intervals
    }
    
    private func applyIntervalPatterns(intervals: [Int], parameters: PatternParameters) -> [Int] {
        switch parameters.intervalPattern {
        case .ascending:
            return intervals
            
        case .descending:
            return intervals.map { -$0 }
            
        case .alternating:
            return applyAlternatingIntervals(intervals: intervals)
            
        case .mirror:
            return applyMirrorIntervals(intervals: intervals, mirrorPoints: parameters.mirrorPoints)
            
        case .retrograde:
            return intervals.reversed()
        }
    }
    
    private func applyAlternatingIntervals(intervals: [Int]) -> [Int] {
        var result: [Int] = []
        
        for (index, interval) in intervals.enumerated() {
            if index % 2 == 0 {
                result.append(interval)
            } else {
                result.append(-interval)
            }
        }
        
        return result
    }
    
    private func applyMirrorIntervals(intervals: [Int], mirrorPoints: Int) -> [Int] {
        guard mirrorPoints > 0 else { return intervals }
        
        var result: [Int] = []
        
        for (index, interval) in intervals.enumerated() {
            let mirrorIndex = index % (mirrorPoints * 2)
            if mirrorIndex < mirrorPoints {
                result.append(interval)
            } else {
                result.append(-interval)
            }
        }
        
        return result
    }
    
    private func convertIntervalsToNotes(intervals: [Int], rootNote: Int) -> [Int] {
        var notes: [Int] = []
        var currentNote = rootNote
        
        for interval in intervals {
            currentNote += interval
            
            // Ensure note is within valid MIDI range
            if currentNote >= 0 && currentNote <= 127 {
                notes.append(currentNote)
            } else {
                // Wrap around octaves if out of range
                if currentNote < 0 {
                    currentNote += 12
                } else {
                    currentNote -= 12
                }
                notes.append(currentNote)
            }
        }
        
        return notes
    }
    
    private func applySymmetricalTransformations(notes: [Int], parameters: PatternParameters) -> [Int] {
        guard parameters.symmetricalIntervals else { return notes }
        
        var result: [Int] = []
        
        // Add original notes
        result.append(contentsOf: notes)
        
        // Add inverted notes (mirror around the root)
        let invertedNotes = notes.map { note in
            let distanceFromRoot = note - parameters.rootNote
            return parameters.rootNote - distanceFromRoot
        }.filter { $0 >= 0 && $0 <= 127 }
        
        result.append(contentsOf: invertedNotes)
        
        return result
    }
    
    
    private func logPerformanceMetrics(
        generationTime: TimeInterval,
        noteCount: Int,
        parameters: PatternParameters
    ) {
        #if DEBUG
        print("IntervalPatternGenerator: Generated \(noteCount) notes in \(String(format: "%.3f", generationTime))s")
        print("  - Primary Interval: \(parameters.primaryInterval)")
        print("  - Secondary Interval: \(parameters.secondaryInterval)")
        print("  - Pattern: \(parameters.intervalPattern.rawValue)")
        print("  - Symmetrical: \(parameters.symmetricalIntervals)")
        #endif
    }
} 