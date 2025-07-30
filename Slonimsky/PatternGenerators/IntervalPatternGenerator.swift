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
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate base interval sequence
        let intervalSequence = generateIntervalSequence(parameters: parameters)
        
        // Apply interval patterns (ascending, descending, alternating, etc.)
        let patternSequence = applyIntervalPatterns(intervals: intervalSequence, parameters: parameters)
        
        // Convert intervals to absolute notes
        let absoluteNotes = convertIntervalsToNotes(
            intervals: patternSequence,
            rootNote: parameters.rootNote
        )
        
        // Apply symmetrical transformations if enabled
        let symmetricalNotes = applySymmetricalTransformations(
            notes: absoluteNotes,
            parameters: parameters
        )
        
        // Use ParameterApplicationManager to apply remaining parameters in correct order
        let finalNotes = ParameterApplicationManager.applyParameters(
            baseNotes: symmetricalNotes,
            parameters: parameters,
            generatorType: "Interval"
        )
        
        // Apply Slonimsky modulations (final step)
        let modulatedNotes = applySlonimskyModulations(
            notes: finalNotes,
            parameters: parameters
        )
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log performance metrics
        logPerformanceMetrics(
            generationTime: generationTime,
            noteCount: modulatedNotes.count,
            parameters: parameters
        )
        
        return modulatedNotes
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
    
    private func convertToMIDIInfo(notes: [Int], parameters: PatternParameters) -> [MIDIInfo] {
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
    
    private func applySlonimskyModulations(notes: [MIDIInfo], parameters: PatternParameters) -> [MIDIInfo] {
        var result: [MIDIInfo] = []
        
        for (index, note) in notes.enumerated() {
            result.append(note)
            
            // Apply interpolation (notes between existing notes)
            if parameters.interpolation.enabled && index < notes.count - 1 {
                let interpolatedNotes = generateInterpolatedNotes(
                    from: note,
                    to: notes[index + 1],
                    settings: parameters.interpolation,
                    velocitySettings: parameters.velocitySettings
                )
                result.append(contentsOf: interpolatedNotes)
            }
            
            // Apply infrapolation (notes below existing notes)
            if parameters.infrapolation.enabled && index < notes.count - 1 {
                let infrapolatedNotes = generateInfrapolatedNotes(
                    baseNote: note,
                    settings: parameters.infrapolation,
                    velocitySettings: parameters.velocitySettings
                )
                result.append(contentsOf: infrapolatedNotes)
            }
            
            // Apply ultrapolation (notes above existing notes)
            if parameters.ultrapolation.enabled && index < notes.count - 1 {
                let ultrapolatedNotes = generateUltrapolatedNotes(
                    baseNote: note,
                    nextNote: notes[index + 1],
                    settings: parameters.ultrapolation,
                    velocitySettings: parameters.velocitySettings
                )
                result.append(contentsOf: ultrapolatedNotes)
            }
        }
        
        return result
    }
    
    private func generateInterpolatedNotes(
        from startNote: MIDIInfo,
        to endNote: MIDIInfo,
        settings: ModulationSettings,
        velocitySettings: VelocitySettings
    ) -> [MIDIInfo] {
        var notes: [MIDIInfo] = []
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let interpolatedNote = startNote.note + interval
            
            // Ensure note is within valid range and doesn't exceed the target note
            if interpolatedNote < endNote.note && interpolatedNote >= 0 && interpolatedNote <= 127 {
                let velocity = calculateVelocity(
                    for: i,
                    note: interpolatedNote,
                    settings: velocitySettings
                )
                
                notes.append(MIDIInfo(
                    note: interpolatedNote,
                    velocity: velocity,
                    beatLength: startNote.beatLength
                ))
            }
        }
        
        return notes
    }
    
    private func generateInfrapolatedNotes(
        baseNote: MIDIInfo,
        settings: ModulationSettings,
        velocitySettings: VelocitySettings
    ) -> [MIDIInfo] {
        var notes: [MIDIInfo] = []
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let infrapolatedNote = baseNote.note - interval
            
            if infrapolatedNote >= 0 && infrapolatedNote <= 127 {
                let velocity = calculateVelocity(
                    for: i,
                    note: infrapolatedNote,
                    settings: velocitySettings
                )
                
                notes.append(MIDIInfo(
                    note: infrapolatedNote,
                    velocity: velocity,
                    beatLength: baseNote.beatLength
                ))
            }
        }
        
        return notes
    }
    
    private func generateUltrapolatedNotes(
        baseNote: MIDIInfo,
        nextNote: MIDIInfo,
        settings: ModulationSettings,
        velocitySettings: VelocitySettings
    ) -> [MIDIInfo] {
        var notes: [MIDIInfo] = []
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let ultrapolatedNote = nextNote.note - interval
            
            if ultrapolatedNote > baseNote.note && ultrapolatedNote >= 0 && ultrapolatedNote <= 127 {
                let velocity = calculateVelocity(
                    for: i,
                    note: ultrapolatedNote,
                    settings: velocitySettings
                )
                
                notes.append(MIDIInfo(
                    note: ultrapolatedNote,
                    velocity: velocity,
                    beatLength: baseNote.beatLength
                ))
            }
        }
        
        return notes
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