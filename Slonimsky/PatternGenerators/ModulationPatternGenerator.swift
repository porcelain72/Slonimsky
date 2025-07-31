//
//  ModulationPatternGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Generates advanced modulation patterns according to Slonimsky's Thesaurus
class ModulationPatternGenerator: BasePatternGenerator {
    
    init() {
        super.init(
            name: "Modulation Pattern Generator",
            description: "Generates complex modulation patterns using advanced Slonimsky techniques including interpolation, infrapolation, ultrapolation, and metric modulation"
        )
    }
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate base sequence using scale or interval patterns
        let baseSequence = generateBaseSequence(parameters: parameters)
        
        // Apply primary modulation techniques
        let modulatedSequence = applyPrimaryModulations(
            sequence: baseSequence,
            parameters: parameters
        )
        
        // Apply metric modulation if enabled
        let metricModulatedSequence = applyMetricModulation(
            sequence: modulatedSequence,
            parameters: parameters
        )
        
        // Apply register shifts
        let shiftedSequence = applyRegisterShifts(
            notes: metricModulatedSequence,
            pattern: parameters.registerShifts,
            maxShift: parameters.toneShifting.maxToneShift
        )
        
        // Apply contour patterns
        let contourSequence = applyContourPattern(
            notes: shiftedSequence,
            pattern: parameters.contourPattern
        )
        
        // Convert to MIDIInfo with velocity and duration
        let midiSequence = convertToMIDIInfo(
            notes: contourSequence,
            parameters: parameters
        )
        
        // Apply final modulation refinements
        let finalSequence = applyModulationRefinements(
            sequence: midiSequence,
            parameters: parameters
        )
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log performance metrics
        logPerformanceMetrics(
            generationTime: generationTime,
            noteCount: finalSequence.count,
            parameters: parameters
        )
        
        return finalSequence
    }
    
    override func estimateNoteCount(parameters: PatternParameters) -> Int {
        let baseCount = parameters.totalNotes
        
        // Calculate modulation multipliers based on enabled techniques
        var modulationMultiplier = 1.0
        
        if parameters.interpolation.enabled {
            modulationMultiplier *= Double(parameters.interpolation.numberOfNotes + 1)
        }
        
        if parameters.infrapolation.enabled {
            modulationMultiplier *= Double(parameters.infrapolation.numberOfNotes + 1)
        }
        
        if parameters.ultrapolation.enabled {
            modulationMultiplier *= Double(parameters.ultrapolation.numberOfNotes + 1)
        }
        
        // Metric modulation can add complexity
        if parameters.metricModulation.enabled {
            modulationMultiplier *= 1.5
        }
        
        // Directional patterns may affect note count
        let directionalMultiplier = calculateDirectionalMultiplier(parameters: parameters)
        
        return Int(Double(baseCount) * modulationMultiplier * directionalMultiplier)
    }
    
    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        
        // Modulation-specific validation
        let hasModulations = parameters.interpolation.enabled || 
                           parameters.infrapolation.enabled || 
                           parameters.ultrapolation.enabled
        
        guard hasModulations else {
            return false // This generator requires at least one modulation technique
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func generateBaseSequence(parameters: PatternParameters) -> [Int] {
        // Generate a base sequence using scale or interval patterns
        // This provides the foundation for modulation techniques
        
        var baseNotes: [Int] = []
        
        switch parameters.scaleType {
        case .chromatic:
            for i in 0..<parameters.totalNotes {
                let note = parameters.rootNote + i
                if note <= 127 {
                    baseNotes.append(note)
                }
            }
            
        case .diatonic:
            let scaleIntervals = parameters.scaleType.intervals
            var currentNote = parameters.rootNote
            
            for _ in 0..<parameters.totalNotes {
                baseNotes.append(currentNote)
                currentNote += scaleIntervals[baseNotes.count % scaleIntervals.count]
                if currentNote > 127 {
                    currentNote -= 12
                }
            }
            
        default:
            // For other scale types, use interval-based generation
            var currentNote = parameters.rootNote
            for i in 0..<parameters.totalNotes {
                let interval = i % 2 == 0 ? parameters.primaryInterval : parameters.secondaryInterval
                currentNote += interval
                if currentNote >= 0 && currentNote <= 127 {
                    baseNotes.append(currentNote)
                } else {
                    currentNote = parameters.rootNote
                }
            }
        }
        
        return baseNotes
    }
    
    private func applyPrimaryModulations(
        sequence: [Int],
        parameters: PatternParameters
    ) -> [Int] {
        var modulatedSequence: [Int] = []
        
        for (index, note) in sequence.enumerated() {
            modulatedSequence.append(note)
            
            // Apply interpolation (notes between existing notes)
            if parameters.interpolation.enabled && index < sequence.count - 1 {
                let interpolatedNotes = generateInterpolatedNotes(
                    from: note,
                    to: sequence[index + 1],
                    settings: parameters.interpolation,
                    index: index
                )
                modulatedSequence.append(contentsOf: interpolatedNotes)
            }
            
            // Apply infrapolation (notes below existing notes)
            if parameters.infrapolation.enabled {
                let infrapolatedNotes = generateInfrapolatedNotes(
                    baseNote: note,
                    settings: parameters.infrapolation,
                    index: index
                )
                modulatedSequence.append(contentsOf: infrapolatedNotes)
            }
            
            // Apply ultrapolation (notes above existing notes)
            if parameters.ultrapolation.enabled && index < sequence.count - 1 {
                let ultrapolatedNotes = generateUltrapolatedNotes(
                    baseNote: note,
                    nextNote: sequence[index + 1],
                    settings: parameters.ultrapolation,
                    index: index
                )
                modulatedSequence.append(contentsOf: ultrapolatedNotes)
            }
        }
        
        return modulatedSequence
    }
    
    private func generateInterpolatedNotes(
        from startNote: Int,
        to endNote: Int,
        settings: ModulationSettings,
        index: Int
    ) -> [Int] {
        var notes: [Int] = []
        
        // Guard against numberOfNotes being 0
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let interpolatedNote = startNote + interval
            
            // Ensure note is within valid range and doesn't exceed the target note
            if interpolatedNote < endNote && interpolatedNote >= 0 && interpolatedNote <= 127 {
                notes.append(interpolatedNote)
            }
        }
        
        return notes
    }
    
    private func generateInfrapolatedNotes(
        baseNote: Int,
        settings: ModulationSettings,
        index: Int
    ) -> [Int] {
        var notes: [Int] = []
        
        // Guard against numberOfNotes being 0
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
    
    private func generateUltrapolatedNotes(
        baseNote: Int,
        nextNote: Int,
        settings: ModulationSettings,
        index: Int
    ) -> [Int] {
        var notes: [Int] = []
        
        // Guard against numberOfNotes being 0
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let ultrapolatedNote = nextNote - interval
            
            if ultrapolatedNote > baseNote && ultrapolatedNote >= 0 && ultrapolatedNote <= 127 {
                notes.append(ultrapolatedNote)
            }
        }
        
        return notes
    }
    
    private func applyMetricModulation(
        sequence: [Int],
        parameters: PatternParameters
    ) -> [Int] {
        guard parameters.metricModulation.enabled else { return sequence }
        
        var modulatedSequence: [Int] = []
        
        for (index, note) in sequence.enumerated() {
            modulatedSequence.append(note)
            
            // Apply metric modulation based on frequency
            if index % parameters.metricModulation.frequency == 0 {
                let metricNotes = generateMetricModulationNotes(
                    baseNote: note,
                    modulationType: parameters.metricModulation.modulationType,
                    intensity: parameters.metricModulation.intensity,
                    index: index
                )
                modulatedSequence.append(contentsOf: metricNotes)
            }
        }
        
        return modulatedSequence
    }
    
    private func generateMetricModulationNotes(
        baseNote: Int,
        modulationType: MetricModulationType,
        intensity: Double,
        index: Int
    ) -> [Int] {
        var notes: [Int] = []
        
        switch modulationType {
        case .accelerando:
            // Add progressively faster notes
            for i in 1...3 {
                let interval = Int(Double(i) * intensity * 2)
                let note = baseNote + interval
                if note >= 0 && note <= 127 {
                    notes.append(note)
                }
            }
            
        case .ritardando:
            // Add progressively slower notes
            for i in 1...3 {
                let interval = Int(Double(i) * intensity * -2)
                let note = baseNote + interval
                if note >= 0 && note <= 127 {
                    notes.append(note)
                }
            }
            
        case .rubato:
            // Add notes with varying intervals
            for i in 1...2 {
                let interval = Int(sin(Double(i) * .pi) * intensity * 4)
                let note = baseNote + interval
                if note >= 0 && note <= 127 {
                    notes.append(note)
                }
            }
            
        case .pulse:
            // Add rhythmic pulse notes
            for i in 1...2 {
                let interval = (i % 2 == 0) ? 2 : -2
                let note = baseNote + interval
                if note >= 0 && note <= 127 {
                    notes.append(note)
                }
            }
        }
        
        return notes
    }
    
    private func convertToMIDIInfo(notes: [Int], parameters: PatternParameters) -> [MIDIInfo] {
        return notes.enumerated().map { index, note in
            let duration = calculateModulatedDuration(
                baseDuration: parameters.baseNoteDuration,
                pattern: parameters.noteDurationPattern,
                index: index,
                density: parameters.rhythmicDensity,
                parameters: parameters
            )
            
            let velocity = calculateModulatedVelocity(
                for: index,
                note: note,
                settings: parameters.velocitySettings,
                parameters: parameters
            )
            
            return MIDIInfo(
                note: note,
                velocity: velocity,
                beatLength: duration
            )
        }
    }
    
    private func calculateModulatedDuration(
        baseDuration: TimeInterval,
        pattern: DurationPattern,
        index: Int,
        density: Double,
        parameters: PatternParameters
    ) -> TimeInterval {
        var duration = baseDuration
        
        // Apply base duration pattern
        switch pattern {
        case .uniform:
            break
        case .alternating:
            duration = index % 2 == 0 ? baseDuration : baseDuration * 0.5
        case .progressive:
            let progression = 1.0 + (Double(index) * 0.1)
            duration = baseDuration * progression
        case .random:
            let randomFactor = Double.random(in: 0.5...1.5)
            duration = baseDuration * randomFactor
        }
        
        // Apply metric modulation effects
        if parameters.metricModulation.enabled {
            let modulationEffect = calculateMetricModulationEffect(
                index: index,
                modulationType: parameters.metricModulation.modulationType,
                intensity: parameters.metricModulation.intensity
            )
            duration *= modulationEffect
        }
        
        // Apply density factor
        duration *= density
        
        return max(duration, 0.0625) // Minimum duration of 1/16 note
    }
    
    private func calculateMetricModulationEffect(
        index: Int,
        modulationType: MetricModulationType,
        intensity: Double
    ) -> Double {
        switch modulationType {
        case .accelerando:
            return 1.0 - (Double(index % 4) * intensity * 0.1)
        case .ritardando:
            return 1.0 + (Double(index % 4) * intensity * 0.1)
        case .rubato:
            return 1.0 + sin(Double(index) * 0.5) * intensity * 0.2
        case .pulse:
            return index % 2 == 0 ? 1.0 : 0.8
        }
    }
    
    private func calculateModulatedVelocity(
        for noteIndex: Int,
        note: Int,
        settings: VelocitySettings,
        parameters: PatternParameters
    ) -> UInt8 {
        var velocity = settings.calculateVelocity(for: noteIndex, note: note)
        
        // Apply modulation-specific velocity adjustments
        if parameters.interpolation.enabled && noteIndex % 3 == 0 {
            velocity = UInt8(clamping: Int(velocity) + 10)
        }
        
        if parameters.infrapolation.enabled && noteIndex % 4 == 0 {
            velocity = UInt8(clamping: Int(velocity) - 5)
        }
        
        if parameters.ultrapolation.enabled && noteIndex % 5 == 0 {
            velocity = UInt8(clamping: Int(velocity) + 15)
        }
        
        return velocity
    }
    
    private func applyModulationRefinements(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var refinedSequence = sequence
        
        // Apply syncopation if enabled
        if parameters.syncopationLevel > 0 {
            refinedSequence = applySyncopation(
                sequence: refinedSequence,
                level: parameters.syncopationLevel
            )
        }
        
        // Apply harmonic context if available
        if parameters.harmonicMode != .atonal {
            refinedSequence = applyHarmonicContext(
                sequence: refinedSequence,
                parameters: parameters
            )
        }
        
        return refinedSequence
    }
    
    private func applySyncopation(
        sequence: [MIDIInfo],
        level: Double
    ) -> [MIDIInfo] {
        guard level > 0 else { return sequence }
        
        var syncopatedSequence: [MIDIInfo] = []
        
        for (index, note) in sequence.enumerated() {
            syncopatedSequence.append(note)
            
            // Add syncopated notes based on level
            if Double.random(in: 0...1) < level && index < sequence.count - 1 {
                let syncopatedNote = MIDIInfo(
                    note: note.note,
                    velocity: UInt8(clamping: Int(note.velocity) - 20),
                    beatLength: note.beatLength * 0.5
                )
                syncopatedSequence.append(syncopatedNote)
            }
        }
        
        return syncopatedSequence
    }
    
    private func applyHarmonicContext(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var harmonizedSequence: [MIDIInfo] = []
        
        for (index, note) in sequence.enumerated() {
            harmonizedSequence.append(note)
            
            // Add harmonic notes based on harmonic mode
            if index % 4 == 0 && parameters.chordGeneration.enabled {
                let harmonicNotes = generateHarmonicNotes(
                    baseNote: note.note,
                    settings: parameters.chordGeneration
                )
                
                for harmonicNote in harmonicNotes {
                    let harmonicMIDI = MIDIInfo(
                        note: harmonicNote,
                        velocity: UInt8(clamping: Int(note.velocity) * Int(parameters.chordGeneration.velocityScale)),
                        beatLength: note.beatLength
                    )
                    harmonizedSequence.append(harmonicMIDI)
                }
            }
        }
        
        return harmonizedSequence
    }
    
    private func generateHarmonicNotes(
        baseNote: Int,
        settings: ChordSettings
    ) -> [Int] {
        var harmonicNotes: [Int] = []
        
        // Generate chord tones based on chord size
        for i in 1..<settings.chordSize {
            let interval: Int
            
            switch settings.voicingPreference {
            case .close:
                interval = i * 2 // Major thirds
            case .open:
                interval = i * 4 // Perfect fifths
            case .mixed:
                interval = i % 2 == 0 ? 2 : 4 // Mixed intervals
            }
            
            let harmonicNote = baseNote + interval
            if harmonicNote >= 0 && harmonicNote <= 127 {
                harmonicNotes.append(harmonicNote)
            }
        }
        
        return harmonicNotes
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
        print("ModulationPatternGenerator: Generated \(noteCount) notes in \(String(format: "%.3f", generationTime))s")
        print("  - Interpolation: \(parameters.interpolation.enabled ? "Enabled (\(parameters.interpolation.numberOfNotes) notes)" : "Disabled")")
        print("  - Infrapolation: \(parameters.infrapolation.enabled ? "Enabled (\(parameters.infrapolation.numberOfNotes) notes)" : "Disabled")")
        print("  - Ultrapolation: \(parameters.ultrapolation.enabled ? "Enabled (\(parameters.ultrapolation.numberOfNotes) notes)" : "Disabled")")
        print("  - Metric Modulation: \(parameters.metricModulation.enabled ? "Enabled (\(parameters.metricModulation.modulationType.rawValue))" : "Disabled")")
        #endif
    }
} 