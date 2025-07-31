//
//  RhythmicPatternGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Generates rhythmic patterns according to Slonimsky's Thesaurus
class RhythmicPatternGenerator: BasePatternGenerator {
    
    init() {
        super.init(
            name: "Rhythmic Pattern Generator",
            description: "Generates complex rhythmic patterns with syncopation, metric modulation, and rhythmic density variations"
        )
    }
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        return generatePattern(parameters: parameters, cycleIndex: 0)
    }
    
    override func generatePattern(parameters: PatternParameters, cycleIndex: Int) -> [MIDIInfo] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Apply cyclical changes to parameters for the current cycle
        let modifiedParameters = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        
        // Generate base rhythmic structure
        let rhythmicStructure = generateRhythmicStructure(parameters: modifiedParameters)
        
        // Apply rhythmic patterns and variations
        let variedRhythm = applyRhythmicVariations(
            structure: rhythmicStructure,
            parameters: modifiedParameters
        )
        
        // Apply syncopation
        let syncopatedRhythm = applySyncopation(
            rhythm: variedRhythm,
            level: modifiedParameters.syncopationLevel
        )
        
        // Apply metric modulation
        let metricModulatedRhythm = applyMetricModulation(
            rhythm: syncopatedRhythm,
            parameters: modifiedParameters
        )
        
        // Apply rhythmic density
        let denseRhythm = applyRhythmicDensity(
            rhythm: metricModulatedRhythm,
            density: modifiedParameters.rhythmicDensity
        )
        
        // Convert to MIDIInfo with velocity and duration
        let midiSequence = convertToMIDIInfo(
            rhythm: denseRhythm,
            parameters: modifiedParameters
        )
        
        // Apply final rhythmic refinements
        let finalSequence = applyRhythmicRefinements(
            sequence: midiSequence,
            parameters: modifiedParameters
        )
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log performance metrics
        logPerformanceMetrics(
            generationTime: generationTime,
            noteCount: finalSequence.count,
            parameters: modifiedParameters
        )
        
        return finalSequence
    }
    
    override func estimateNoteCount(parameters: PatternParameters) -> Int {
        let baseCount = parameters.totalNotes
        
        // Rhythmic density affects note count
        let densityMultiplier = parameters.rhythmicDensity
        
        // Syncopation can add extra notes
        let syncopationMultiplier = 1.0 + (parameters.syncopationLevel * 0.5)
        
        // Metric modulation can add complexity
        let metricMultiplier = parameters.metricModulation.enabled ? 1.3 : 1.0
        
        return Int(Double(baseCount) * densityMultiplier * syncopationMultiplier * metricMultiplier)
    }
    
    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        
        // Rhythmic-specific validation
        guard parameters.rhythmicDensity >= 0.1 && parameters.rhythmicDensity <= 2.0 else {
            return false
        }
        
        guard parameters.syncopationLevel >= 0.0 && parameters.syncopationLevel <= 1.0 else {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func generateRhythmicStructure(parameters: PatternParameters) -> [RhythmicNote] {
        var rhythmicNotes: [RhythmicNote] = []
        
        let timeSignature = parameters.timeSignature
        let beatsPerMeasure = timeSignature.beatsPerMeasure
        let baseDuration = parameters.baseNoteDuration
        
        for i in 0..<parameters.totalNotes {
            let beatPosition = i % beatsPerMeasure
            let measureNumber = i / beatsPerMeasure
            
            // Generate note based on rhythmic position
            let note = generateNoteForRhythmicPosition(
                beatPosition: beatPosition,
                measureNumber: measureNumber,
                parameters: parameters
            )
            
            // Calculate duration based on rhythmic pattern
            let duration = calculateRhythmicDuration(
                beatPosition: beatPosition,
                measureNumber: measureNumber,
                baseDuration: baseDuration,
                pattern: parameters.noteDurationPattern,
                parameters: parameters
            )
            
            let rhythmicNote = RhythmicNote(
                note: note,
                duration: duration,
                beatPosition: beatPosition,
                measureNumber: measureNumber,
                isAccented: isAccentedBeat(beatPosition: beatPosition, parameters: parameters)
            )
            
            rhythmicNotes.append(rhythmicNote)
        }
        
        return rhythmicNotes
    }
    
    private func generateNoteForRhythmicPosition(
        beatPosition: Int,
        measureNumber: Int,
        parameters: PatternParameters
    ) -> Int {
        let baseNote = parameters.rootNote
        
        // Generate note based on rhythmic position and pattern
        switch parameters.primaryDirection {
        case .ascending:
            return baseNote + (beatPosition * 2) + (measureNumber * 3)
        case .descending:
            return baseNote - (beatPosition * 2) - (measureNumber * 3)
        case .alternating:
            return baseNote + (beatPosition % 2 == 0 ? beatPosition : -beatPosition)
        }
    }
    
    private func calculateRhythmicDuration(
        beatPosition: Int,
        measureNumber: Int,
        baseDuration: TimeInterval,
        pattern: DurationPattern,
        parameters: PatternParameters
    ) -> TimeInterval {
        var duration = baseDuration
        
        switch pattern {
        case .uniform:
            break
            
        case .alternating:
            duration = beatPosition % 2 == 0 ? baseDuration : baseDuration * 0.5
            
        case .progressive:
            let progression = 1.0 + (Double(beatPosition) * 0.1)
            duration = baseDuration * progression
            
        case .random:
            let randomFactor = Double.random(in: 0.5...1.5)
            duration = baseDuration * randomFactor
        }
        
        // Apply rhythmic emphasis based on beat position
        if isAccentedBeat(beatPosition: beatPosition, parameters: parameters) {
            duration *= 1.5
        }
        
        return duration
    }
    
    private func isAccentedBeat(beatPosition: Int, parameters: PatternParameters) -> Bool {
        let beatsPerMeasure = parameters.timeSignature.beatsPerMeasure
        
        // Strong beats are typically 1 and 3 in 4/4 time
        switch beatsPerMeasure {
        case 4:
            return beatPosition == 0 || beatPosition == 2
        case 3:
            return beatPosition == 0
        case 6:
            return beatPosition == 0 || beatPosition == 3
        default:
            return beatPosition == 0
        }
    }
    
    private func applyRhythmicVariations(
        structure: [RhythmicNote],
        parameters: PatternParameters
    ) -> [RhythmicNote] {
        var variedStructure = structure
        
        // Apply rhythmic variations based on pattern
        for i in 0..<variedStructure.count {
            let variation = calculateRhythmicVariation(
                index: i,
                note: variedStructure[i],
                parameters: parameters
            )
            variedStructure[i] = variation
        }
        
        return variedStructure
    }
    
    private func calculateRhythmicVariation(
        index: Int,
        note: RhythmicNote,
        parameters: PatternParameters
    ) -> RhythmicNote {
        var variedNote = note
        
        // Apply contour-based variations
        switch parameters.contourPattern {
        case .linear:
            // Linear progression
            variedNote.duration *= 1.0 + (Double(index) * 0.01)
            
        case .arch:
            // Arch shape - longer in middle
            let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
            let archFactor = sin(normalizedIndex * .pi)
            variedNote.duration *= 1.0 + (archFactor * 0.3)
            
        case .invertedArch:
            // Inverted arch - shorter in middle
            let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
            let archFactor = 1.0 - sin(normalizedIndex * .pi)
            variedNote.duration *= 1.0 + (archFactor * 0.3)
            
        case .wave:
            // Wave pattern
            let waveFactor = sin(Double(index) * 0.5) * 0.2
            variedNote.duration *= 1.0 + waveFactor
            
        case .random:
            // Random variation
            let randomFactor = Double.random(in: 0.8...1.2)
            variedNote.duration *= randomFactor
            
        case .mirror:
            // Mirror pattern - symmetrical around center
            let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
            let mirrorFactor = 1.0 - abs(2.0 * normalizedIndex - 1.0)
            variedNote.duration *= 1.0 + (mirrorFactor * 0.3)
        }
        
        return variedNote
    }
    
    private func applySyncopation(
        rhythm: [RhythmicNote],
        level: Double
    ) -> [RhythmicNote] {
        guard level > 0 else { return rhythm }
        
        var syncopatedRhythm: [RhythmicNote] = []
        
        for (index, note) in rhythm.enumerated() {
            syncopatedRhythm.append(note)
            
            // Add syncopated notes based on level
            if Double.random(in: 0...1) < level && index < rhythm.count - 1 {
                let syncopatedNote = RhythmicNote(
                    note: note.note,
                    duration: note.duration * 0.5,
                    beatPosition: note.beatPosition,
                    measureNumber: note.measureNumber,
                    isAccented: false
                )
                syncopatedRhythm.append(syncopatedNote)
            }
        }
        
        return syncopatedRhythm
    }
    
    private func applyMetricModulation(
        rhythm: [RhythmicNote],
        parameters: PatternParameters
    ) -> [RhythmicNote] {
        guard parameters.metricModulation.enabled else { return rhythm }
        
        var modulatedRhythm: [RhythmicNote] = []
        
        for (index, note) in rhythm.enumerated() {
            modulatedRhythm.append(note)
            
            // Apply metric modulation based on frequency
            if index % parameters.metricModulation.frequency == 0 {
                let metricNotes = generateMetricModulationNotes(
                    baseNote: note,
                    modulationType: parameters.metricModulation.modulationType,
                    intensity: parameters.metricModulation.intensity
                )
                modulatedRhythm.append(contentsOf: metricNotes)
            }
        }
        
        return modulatedRhythm
    }
    
    private func generateMetricModulationNotes(
        baseNote: RhythmicNote,
        modulationType: MetricModulationType,
        intensity: Double
    ) -> [RhythmicNote] {
        var metricNotes: [RhythmicNote] = []
        
        switch modulationType {
        case .accelerando:
            // Add progressively faster notes
            for i in 1...2 {
                let metricNote = RhythmicNote(
                    note: baseNote.note + (i * 2),
                    duration: baseNote.duration * (1.0 - Double(i) * intensity * 0.2),
                    beatPosition: baseNote.beatPosition,
                    measureNumber: baseNote.measureNumber,
                    isAccented: false
                )
                metricNotes.append(metricNote)
            }
            
        case .ritardando:
            // Add progressively slower notes
            for i in 1...2 {
                let metricNote = RhythmicNote(
                    note: baseNote.note - (i * 2),
                    duration: baseNote.duration * (1.0 + Double(i) * intensity * 0.2),
                    beatPosition: baseNote.beatPosition,
                    measureNumber: baseNote.measureNumber,
                    isAccented: false
                )
                metricNotes.append(metricNote)
            }
            
        case .rubato:
            // Add rubato notes with varying durations
            for i in 1...2 {
                let rubatoFactor = sin(Double(i) * .pi) * intensity
                let metricNote = RhythmicNote(
                    note: baseNote.note + Int(rubatoFactor * 4),
                    duration: baseNote.duration * (1.0 + rubatoFactor * 0.3),
                    beatPosition: baseNote.beatPosition,
                    measureNumber: baseNote.measureNumber,
                    isAccented: false
                )
                metricNotes.append(metricNote)
            }
            
        case .pulse:
            // Add rhythmic pulse notes
            for i in 1...2 {
                let metricNote = RhythmicNote(
                    note: baseNote.note + (i % 2 == 0 ? 2 : -2),
                    duration: baseNote.duration * (i % 2 == 0 ? 1.2 : 0.8),
                    beatPosition: baseNote.beatPosition,
                    measureNumber: baseNote.measureNumber,
                    isAccented: i % 2 == 0
                )
                metricNotes.append(metricNote)
            }
        }
        
        return metricNotes
    }
    
    private func applyRhythmicDensity(
        rhythm: [RhythmicNote],
        density: Double
    ) -> [RhythmicNote] {
        guard density != 1.0 else { return rhythm }
        
        var denseRhythm: [RhythmicNote] = []
        
        for note in rhythm {
            denseRhythm.append(note)
            
            // Add additional notes based on density
            if density > 1.0 && Double.random(in: 0...1) < (density - 1.0) {
                let denseNote = RhythmicNote(
                    note: note.note + Int.random(in: -2...2),
                    duration: note.duration * 0.5,
                    beatPosition: note.beatPosition,
                    measureNumber: note.measureNumber,
                    isAccented: false
                )
                denseRhythm.append(denseNote)
            }
        }
        
        return denseRhythm
    }
    
    private func convertToMIDIInfo(
        rhythm: [RhythmicNote],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        return rhythm.enumerated().map { index, rhythmicNote in
            let velocity = calculateRhythmicVelocity(
                for: index,
                rhythmicNote: rhythmicNote,
                settings: parameters.velocitySettings
            )
            
            return MIDIInfo(
                note: rhythmicNote.note,
                velocity: velocity,
                beatLength: rhythmicNote.duration,
                cycleIndex: 0
            )
        }
    }
    
    private func calculateRhythmicVelocity(
        for index: Int,
        rhythmicNote: RhythmicNote,
        settings: VelocitySettings
    ) -> UInt8 {
        var velocity = settings.calculateVelocity(for: index, note: rhythmicNote.note)
        
        // Apply rhythmic emphasis
        if rhythmicNote.isAccented {
            velocity = UInt8(clamping: Int(velocity) + 20)
        }
        
        // Apply beat position emphasis
        if rhythmicNote.beatPosition == 0 {
            velocity = UInt8(clamping: Int(velocity) + 10)
        }
        
        return velocity
    }
    
    private func applyRhythmicRefinements(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var refinedSequence = sequence
        
        // Apply harmonic rhythm if enabled
        if parameters.harmonicRhythm.chordChangeFrequency > 0 {
            refinedSequence = applyHarmonicRhythm(
                sequence: refinedSequence,
                settings: parameters.harmonicRhythm
            )
        }
        
        // Apply final rhythmic polish
        refinedSequence = applyRhythmicPolish(
            sequence: refinedSequence,
            parameters: parameters
        )
        
        return refinedSequence
    }
    
    private func applyHarmonicRhythm(
        sequence: [MIDIInfo],
        settings: HarmonicRhythmSettings
    ) -> [MIDIInfo] {
        var harmonizedSequence: [MIDIInfo] = []
        
        for (index, note) in sequence.enumerated() {
            harmonizedSequence.append(note)
            
            // Add harmonic notes based on harmonic rhythm
            if index % settings.chordChangeFrequency == 0 {
                let harmonicNotes = generateHarmonicRhythmNotes(
                    baseNote: note.note,
                    tension: settings.harmonicTension
                )
                
                for harmonicNote in harmonicNotes {
                    let harmonicMIDI = MIDIInfo(
                        note: harmonicNote,
                        velocity: UInt8(clamping: Int(note.velocity) - 10),
                        beatLength: note.beatLength,
                        cycleIndex: 0
                    )
                    harmonizedSequence.append(harmonicMIDI)
                }
            }
        }
        
        return harmonizedSequence
    }
    
    private func generateHarmonicRhythmNotes(
        baseNote: Int,
        tension: Double
    ) -> [Int] {
        var harmonicNotes: [Int] = []
        
        // Generate harmonic notes based on tension level
        let intervals = tension > 0.5 ? [3, 7] : [4, 7] // Minor vs Major
        
        for interval in intervals {
            let harmonicNote = baseNote + interval
            if harmonicNote >= 0 && harmonicNote <= 127 {
                harmonicNotes.append(harmonicNote)
            }
        }
        
        return harmonicNotes
    }
    
    private func applyRhythmicPolish(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var polishedSequence = sequence
        
        // Apply subtle timing adjustments
        for i in 0..<polishedSequence.count {
            let timingAdjustment = calculateTimingAdjustment(
                index: i,
                parameters: parameters
            )
            polishedSequence[i].beatLength *= timingAdjustment
        }
        
        return polishedSequence
    }
    
    private func calculateTimingAdjustment(
        index: Int,
        parameters: PatternParameters
    ) -> Double {
        // Apply subtle timing adjustments based on rhythmic context
        let baseAdjustment = 1.0
        
        // Add slight swing for certain patterns
        if parameters.noteDurationPattern == .alternating && index % 2 == 1 {
            return baseAdjustment * 1.1
        }
        
        // Add slight rubato for expressive patterns
        if parameters.contourPattern == .wave {
            let rubatoFactor = sin(Double(index) * 0.3) * 0.05
            return baseAdjustment + rubatoFactor
        }
        
        return baseAdjustment
    }
    
    private func logPerformanceMetrics(
        generationTime: TimeInterval,
        noteCount: Int,
        parameters: PatternParameters
    ) {
        #if DEBUG
        print("RhythmicPatternGenerator: Generated \(noteCount) notes in \(String(format: "%.3f", generationTime))s")
        print("  - Rhythmic Density: \(parameters.rhythmicDensity)")
        print("  - Syncopation Level: \(parameters.syncopationLevel)")
        print("  - Duration Pattern: \(parameters.noteDurationPattern.rawValue)")
        print("  - Metric Modulation: \(parameters.metricModulation.enabled ? "Enabled" : "Disabled")")
        #endif
    }
}

// MARK: - Supporting Types

/// Represents a note with rhythmic information
struct RhythmicNote {
    let note: Int
    var duration: TimeInterval
    let beatPosition: Int
    let measureNumber: Int
    let isAccented: Bool
} 