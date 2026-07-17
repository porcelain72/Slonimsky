//
//  ScalePatternGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Generates scale-based patterns according to Slonimsky's Thesaurus
class ScalePatternGenerator: BasePatternGenerator {
    
    init() {
        super.init(
            name: "Scale Pattern Generator",
            description: "Generates melodic patterns based on various scale types including chromatic, diatonic, pentatonic, and symmetrical scales"
        )
    }
    
    // MARK: - New Pattern Generation (Pure Mathematical)
    
    /// Generate a pure mathematical note pattern (note numbers only)
    override func generateNotePattern(parameters: PatternParameters, cycleIndex: Int) -> [Int] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        print("🎵 ScalePatternGenerator: Starting note pattern generation")
        print("   Root Note: \(parameters.rootNote)")
        print("   Scale Type: \(parameters.scaleType.rawValue)")
        print("   Number of Octaves: \(parameters.numberOfOctaves)")
        print("   Divisions of Octave: \(parameters.divisionsOfOctave)")
        print("   Mirror: \(parameters.mirror)")
        
        // Apply cyclical changes to parameters for the current cycle
        let modifiedParameters = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        
        // Generate base scale notes
        var baseNotes = generateBaseScale(parameters: modifiedParameters)
        
        // Ensure the sequence ends at the octave above the starting note
        // For multiple octaves, this should be the target octave (firstNote + numberOfOctaves * 12)
        // This creates a proper arpeggio that reaches the target octave before descending
        if let firstNote = baseNotes.first, let lastNote = baseNotes.last {
            let targetOctave = firstNote + (modifiedParameters.numberOfOctaves * 12)
            // Only add octave if it's not already the last note
            if lastNote != targetOctave && targetOctave <= 127 {
                baseNotes.append(targetOctave)
                print("   Added octave note: \(targetOctave)")
            }
        }
        
        print("   Generated base scale notes: \(baseNotes)")
        print("   Base scale note count: \(baseNotes.count)")
        
        // Use ParameterApplicationManager to apply parameters in correct order
        // This returns pure note numbers (no MIDI conversion)
        let finalNotes = ParameterApplicationManager.applyParameters(
            baseNotes: baseNotes,
            parameters: modifiedParameters,
            generatorType: "Scale"
        )
        print("   After parameter application: \(finalNotes.count) notes")
        print("   Final note pattern: \(finalNotes)")
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log performance metrics
        logPerformanceMetrics(
            generationTime: generationTime,
            noteCount: finalNotes.count,
            parameters: modifiedParameters
        )
        
        print("🎵 ScalePatternGenerator: Note pattern generation complete")
        return finalNotes
    }
    
    // MARK: - Legacy Pattern Generation (with MIDI conversion)
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        return generatePattern(parameters: parameters, cycleIndex: 0)
    }
    
    override func generatePattern(parameters: PatternParameters, cycleIndex: Int) -> [MIDIInfo] {
        // Generate pure note pattern first (this applies cyclical changes internally)
        let notePattern = generateNotePattern(parameters: parameters, cycleIndex: cycleIndex)
        
        // Apply cyclical changes to get modified parameters for MIDI conversion
        // (Note: generateNotePattern also applies these, but we need them here for convertWithModulations)
        let modifiedParameters = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        
        // Convert to MIDI with modulations and iterations applied using modified parameters
        // This ensures cyclical changes to interpolation/infrapolation/ultrapolation are applied
        let midiNotes = MIDIPatternConverter.convertWithModulations(
            notes: notePattern,
            parameters: modifiedParameters,
            generatorType: "Scale"
        )
        
        // Log the actual generated MIDI notes
        print("   Generated MIDI notes:")
        for (index, note) in midiNotes.enumerated() {
            print("     \(index + 1): Note \(note.note), Velocity \(note.velocity), Duration \(note.duration)")
        }
        
        return midiNotes
    }
    
    override func estimateNoteCount(parameters: PatternParameters) -> Int {
        let baseCount = parameters.totalNotes
        
        // Calculate modulation multipliers
        let interpMultiplier = 1.0 + Double(parameters.interpolation.numberOfNotes)
        let infraMultiplier = 1.0 + Double(parameters.infrapolation.numberOfNotes)
        let ultraMultiplier = 1.0 + Double(parameters.ultrapolation.numberOfNotes)
        
        let modulationMultiplier = interpMultiplier * infraMultiplier * ultraMultiplier
        
        // Apply directional pattern multipliers
        let directionalMultiplier = calculateDirectionalMultiplier(parameters: parameters)
        
        return Int(Double(baseCount) * modulationMultiplier * directionalMultiplier)
    }
    
    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        
        // Scale-specific validation
        guard parameters.divisionsOfOctave >= 1 && parameters.divisionsOfOctave <= 12 else {
            return false
        }
        
        guard parameters.numberOfOctaves >= 1 && parameters.numberOfOctaves <= 8 else {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func generateBaseScale(parameters: PatternParameters) -> [Int] {
        var notes: [Int] = []
        
        print("   Generating base scale:")
        print("     Scale type: \(parameters.scaleType.rawValue)")
        print("     Number of octaves: \(parameters.numberOfOctaves)")
        print("     Divisions per octave: \(parameters.divisionsOfOctave)")
        
        if parameters.scaleType == .none {
            // Use equal divisions of the octave
            notes = generateEqualDivisions(parameters: parameters)
        } else {
            // Use predefined scale intervals
            let scaleIntervals = parameters.scaleType.intervals
            print("     Scale intervals: \(scaleIntervals)")
            
            for octave in 0..<parameters.numberOfOctaves {
                let rootNote = parameters.rootNote + (octave * 12)
                print("     Octave \(octave): Root note \(rootNote)")
                
                for (index, interval) in scaleIntervals.enumerated() {
                    let note: Int
                    if index == 0 {
                        // First note is the root note
                        note = rootNote
                    } else {
                        // For chromatic scale, each note should be exactly one semitone higher
                        // For other scales, use the interval from the root note
                        if parameters.scaleType == .chromatic {
                            note = rootNote + index
                        } else {
                            // For non-chromatic scales, use accumulated intervals
                            let accumulatedInterval = scaleIntervals.prefix(index).reduce(0, +)
                            note = rootNote + accumulatedInterval
                        }
                    }
                    
                    print("       Note \(index): Interval \(interval), MIDI note \(note)")
                    
                    // Ensure note is within valid MIDI range
                    if note >= 0 && note <= 127 {
                        notes.append(note)
                    }
                    
                    // For chromatic scales, respect divisionsOfOctave parameter
                    // For diatonic scales (pentatonic, major, minor, etc.), use natural scale structure
                    if parameters.scaleType == .chromatic && (index + 1) >= parameters.divisionsOfOctave {
                        print("       Stopping at division \(index + 1) (limit: \(parameters.divisionsOfOctave))")
                        break
                    }
                }
            }
        }
        
        print("     Final base scale notes: \(notes)")
        return notes
    }
    
    private func generateEqualDivisions(parameters: PatternParameters) -> [Int] {
        let totalSemitones = 12 * parameters.numberOfOctaves
        let divisions = parameters.divisionsOfOctave
        
        print("     Using equal divisions:")
        print("       Total semitones: \(totalSemitones)")
        print("       Divisions: \(divisions)")
        
        // Validate that divisions is a valid divisor of totalSemitones
        guard totalSemitones % divisions == 0 else {
            print("       ❌ Invalid divisions: \(divisions) is not a divisor of \(totalSemitones)")
            print("       Valid divisors of \(totalSemitones): \(getValidDivisors(totalSemitones))")
            print("       🛡️ Safety fallback: Using 1 division to prevent crash")
            // Safety fallback: use 1 division to prevent crash
            return [parameters.rootNote]
        }
        
        let interval = totalSemitones / divisions
        print("       Interval: \(interval) semitones")
        
        var notes: [Int] = []
        var currentNote = parameters.rootNote
        
        for i in 0..<divisions {
            print("       Note \(i): MIDI note \(currentNote)")
            
            // Ensure note is within valid MIDI range
            if currentNote >= 0 && currentNote <= 127 {
                notes.append(currentNote)
            }
            
            currentNote += interval
        }
        
        return notes
    }
    
    private func getValidDivisors(_ number: Int) -> [Int] {
        var divisors: [Int] = []
        for i in 1...number {
            if number % i == 0 {
                divisors.append(i)
            }
        }
        return divisors
    }
    
    
    private func calculateDirectionalMultiplier(parameters: PatternParameters) -> Double {
        // Mirror doubles the note count when enabled
        return parameters.mirror ? 2.0 : 1.0
    }
    
    private func logPerformanceMetrics(
        generationTime: TimeInterval,
        noteCount: Int,
        parameters: PatternParameters
    ) {
        #if DEBUG
        print("ScalePatternGenerator: Generated \(noteCount) notes in \(String(format: "%.3f", generationTime))s")
        print("  - Scale: \(parameters.scaleType.rawValue)")
        print("  - Octaves: \(parameters.numberOfOctaves)")
        print("  - Divisions: \(parameters.divisionsOfOctave)")
        #endif
    }
} 