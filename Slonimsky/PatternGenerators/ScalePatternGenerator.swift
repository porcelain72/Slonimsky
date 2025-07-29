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
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate base scale notes
        let baseNotes = generateBaseScale(parameters: parameters)
        
        // Apply directional patterns
        let directionalNotes = applyDirectionalPatterns(notes: baseNotes, parameters: parameters)
        
        // Apply register shifts
        let shiftedNotes = applyRegisterShifts(
            notes: directionalNotes,
            pattern: parameters.registerShifts,
            maxShift: parameters.toneShifting.maxToneShift
        )
        
        // Apply contour patterns
        let contourNotes = applyContourPattern(
            notes: shiftedNotes,
            pattern: parameters.contourPattern
        )
        
        // Convert to MIDIInfo with velocity and duration
        let midiNotes = convertToMIDIInfo(
            notes: contourNotes,
            parameters: parameters
        )
        
        // Apply Slonimsky modulations
        let modulatedNotes = applySlonimskyModulations(
            notes: midiNotes,
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
        let scaleIntervals = parameters.scaleType.intervals
        var notes: [Int] = []
        
        for octave in 0..<parameters.numberOfOctaves {
            for (index, interval) in scaleIntervals.enumerated() {
                let note = parameters.rootNote + (octave * 12) + interval
                
                // Ensure note is within valid MIDI range
                if note >= 0 && note <= 127 {
                    notes.append(note)
                }
                
                // Stop if we've reached the desired number of divisions
                if notes.count >= parameters.divisionsOfOctave {
                    break
                }
            }
        }
        
        return notes
    }
    
    private func applyDirectionalPatterns(notes: [Int], parameters: PatternParameters) -> [Int] {
        switch parameters.intervalPattern {
        case .ascending:
            return notes.sorted()
            
        case .descending:
            return notes.sorted(by: >)
            
        case .alternating:
            return applyAlternatingPattern(notes: notes)
            
        case .mirror:
            return applyMirrorPattern(notes: notes, mirrorPoints: parameters.mirrorPoints)
            
        case .retrograde:
            return notes.reversed()
        }
    }
    
    private func applyAlternatingPattern(notes: [Int]) -> [Int] {
        let sortedNotes = notes.sorted()
        var result: [Int] = []
        
        for i in 0..<sortedNotes.count {
            if i % 2 == 0 {
                result.append(sortedNotes[i / 2])
            } else {
                result.append(sortedNotes[sortedNotes.count - 1 - (i / 2)])
            }
        }
        
        return result
    }
    
    private func applyMirrorPattern(notes: [Int], mirrorPoints: Int) -> [Int] {
        guard mirrorPoints > 0 else { return notes }
        
        let sortedNotes = notes.sorted()
        var result: [Int] = []
        
        for i in 0..<sortedNotes.count {
            let mirrorIndex = i % (mirrorPoints * 2)
            if mirrorIndex < mirrorPoints {
                result.append(sortedNotes[i])
            } else {
                result.append(sortedNotes[mirrorPoints * 2 - 1 - mirrorIndex])
            }
        }
        
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