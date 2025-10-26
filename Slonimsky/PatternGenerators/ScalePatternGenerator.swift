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
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        return generatePattern(parameters: parameters, cycleIndex: 0)
    }
    
    override func generatePattern(parameters: PatternParameters, cycleIndex: Int) -> [MIDIInfo] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        print("🎵 ScalePatternGenerator: Starting pattern generation")
        print("   Root Note: \(parameters.rootNote)")
        print("   Scale Type: \(parameters.scaleType.rawValue)")
        print("   Number of Octaves: \(parameters.numberOfOctaves)")
        print("   Divisions of Octave: \(parameters.divisionsOfOctave)")
        print("   Primary Direction: \(parameters.primaryDirection.rawValue)")
        print("   Interval Pattern: \(parameters.intervalPattern.rawValue)")
        print("   Interpolation Enabled: \(parameters.interpolation.enabled) (\(parameters.interpolation.numberOfNotes) notes)")
        print("   Infrapolation Enabled: \(parameters.infrapolation.enabled) (\(parameters.infrapolation.numberOfNotes) notes)")
        print("   Ultrapolation Enabled: \(parameters.ultrapolation.enabled) (\(parameters.ultrapolation.numberOfNotes) notes)")
        print("   Metric Modulation Enabled: \(parameters.metricModulation.enabled)")
        
        // Apply cyclical changes to parameters for the current cycle
        let modifiedParameters = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        
        // Generate base scale notes
        let baseNotes = generateBaseScale(parameters: modifiedParameters)
        print("   Generated base scale notes: \(baseNotes)")
        print("   Base scale note count: \(baseNotes.count)")
        
        // Use ParameterApplicationManager to apply parameters in correct order
        let finalNotes = ParameterApplicationManager.applyParameters(
            baseNotes: baseNotes,
            parameters: modifiedParameters,
            generatorType: "Scale"
        )
        print("   After parameter application: \(finalNotes.count) notes")
        
        // Apply Slonimsky modulations (final step)
        let modulatedNotes = applySlonimskyModulations(
            notes: finalNotes,
            parameters: modifiedParameters
        )
        print("   After modulations: \(modulatedNotes.count) notes")
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log the actual generated notes
        print("   Generated MIDI notes:")
        for (index, note) in modulatedNotes.enumerated() {
            print("     \(index + 1): Note \(note.note), Velocity \(note.velocity), Duration \(note.beatLength)")
        }
        
        // Log performance metrics
        logPerformanceMetrics(
            generationTime: generationTime,
            noteCount: modulatedNotes.count,
            parameters: modifiedParameters
        )
        
        print("🎵 ScalePatternGenerator: Pattern generation complete")
        return modulatedNotes
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
                beatLength: duration,
                cycleIndex: 0
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
        
        // Guard against numberOfNotes being 0
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let interpolatedNote = startNote.note + interval
            
            // Ensure note is within valid MIDI range (0-127)
            // Allow notes beyond the target note for extended interpolation
            if interpolatedNote >= 0 && interpolatedNote <= 127 {
                let velocity = calculateVelocity(
                    for: i,
                    note: interpolatedNote,
                    settings: velocitySettings
                )
                
                notes.append(MIDIInfo(
                    note: interpolatedNote,
                    velocity: velocity,
                    beatLength: startNote.beatLength,
                    cycleIndex: 0
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
        
        // Guard against numberOfNotes being 0
        guard settings.numberOfNotes > 0 else { return notes }
        
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
                    beatLength: baseNote.beatLength,
                    cycleIndex: 0
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
        
        // Guard against numberOfNotes being 0
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let ultrapolatedNote = nextNote.note - interval
            
            // Allow notes beyond the base note for extended ultrapolation
            if ultrapolatedNote >= 0 && ultrapolatedNote <= 127 {
                let velocity = calculateVelocity(
                    for: i,
                    note: ultrapolatedNote,
                    settings: velocitySettings
                )
                
                notes.append(MIDIInfo(
                    note: ultrapolatedNote,
                    velocity: velocity,
                    beatLength: baseNote.beatLength,
                    cycleIndex: 0
                ))
            }
        }
        
        return notes
    }
    
    private func calculateDirectionalMultiplier(parameters: PatternParameters) -> Double {
        switch parameters.intervalPattern {
        case .ascending, .descending:
            return 1.0
        case .alternating:
            return 1.0
        case .mirror:
            return Double(parameters.mirrorPoints + 1)
        case .retrograde:
            return 1.0
        }
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