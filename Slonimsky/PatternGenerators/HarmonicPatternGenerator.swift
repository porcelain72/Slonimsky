//
//  HarmonicPatternGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Generates harmonic patterns according to Slonimsky's Thesaurus
class HarmonicPatternGenerator: BasePatternGenerator {
    
    init() {
        super.init(
            name: "Harmonic Pattern Generator",
            description: "Generates harmonic patterns with chord recognition, harmonic analysis, and harmonic progression patterns"
        )
    }
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate harmonic progression
        let harmonicProgression = generateHarmonicProgression(parameters: parameters)
        
        // Apply harmonic patterns and variations
        let variedHarmony = applyHarmonicVariations(
            progression: harmonicProgression,
            parameters: parameters
        )
        
        // Apply chord voicings
        let voicedHarmony = applyChordVoicings(
            harmony: variedHarmony,
            parameters: parameters
        )
        
        // Apply harmonic rhythm
        let rhythmicHarmony = applyHarmonicRhythm(
            harmony: voicedHarmony,
            parameters: parameters
        )
        
        // Apply harmonic tension
        let tensionedHarmony = applyHarmonicTension(
            harmony: rhythmicHarmony,
            parameters: parameters
        )
        
        // Convert to MIDIInfo with velocity and duration
        let midiSequence = convertToMIDIInfo(
            harmony: tensionedHarmony,
            parameters: parameters
        )
        
        // Apply final harmonic refinements
        let finalSequence = applyHarmonicRefinements(
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
        
        // Harmonic patterns typically generate more notes due to chords
        let chordMultiplier = Double(parameters.chordGeneration.chordSize)
        
        // Harmonic rhythm affects note count
        let rhythmMultiplier = 1.0 + (parameters.harmonicRhythm.syncopationLevel * 0.3)
        
        // Harmonic tension can add complexity
        let tensionMultiplier = 1.0 + (parameters.harmonicRhythm.harmonicTension * 0.2)
        
        return Int(Double(baseCount) * chordMultiplier * rhythmMultiplier * tensionMultiplier)
    }
    
    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        
        // Harmonic-specific validation
        guard parameters.chordGeneration.chordSize >= 2 && parameters.chordGeneration.chordSize <= 6 else {
            return false
        }
        
        guard parameters.harmonicRhythm.chordChangeFrequency >= 1 && parameters.harmonicRhythm.chordChangeFrequency <= 16 else {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func generateHarmonicProgression(parameters: PatternParameters) -> [HarmonicChord] {
        var progression: [HarmonicChord] = []
        
        let rootNote = parameters.rootNote
        let chordChangeFrequency = parameters.harmonicRhythm.chordChangeFrequency
        let harmonicMode = parameters.harmonicMode
        
        for i in 0..<parameters.totalNotes {
            let chordIndex = i / chordChangeFrequency
            let chordRoot = calculateChordRoot(
                baseNote: rootNote,
                chordIndex: chordIndex,
                harmonicMode: harmonicMode
            )
            
            let chordType = determineChordType(
                chordIndex: chordIndex,
                harmonicMode: harmonicMode,
                parameters: parameters
            )
            
            let chord = HarmonicChord(
                root: chordRoot,
                type: chordType,
                position: i,
                function: determineHarmonicFunction(chordIndex: chordIndex, harmonicMode: harmonicMode)
            )
            
            progression.append(chord)
        }
        
        return progression
    }
    
    private func calculateChordRoot(
        baseNote: Int,
        chordIndex: Int,
        harmonicMode: HarmonicMode
    ) -> Int {
        switch harmonicMode {
        case .tonal:
            // Traditional tonal progression (I-IV-V-I)
            let progression = [0, 5, 7, 0] // C, F, G, C
            let rootOffset = progression[chordIndex % progression.count]
            return baseNote + rootOffset
            
        case .modal:
            // Modal progression
            let modalProgression = [0, 2, 4, 5, 7, 9, 11] // Modal scale degrees
            let rootOffset = modalProgression[chordIndex % modalProgression.count]
            return baseNote + rootOffset
            
        case .atonal:
            // Atonal progression - more random
            let randomOffset = Int.random(in: -6...6)
            return baseNote + randomOffset
            
        case .polymodal:
            // Polymodal progression - multiple modes
            let modes = [0, 2, 4, 5, 7, 9, 11, 1, 3, 6, 8, 10]
            let rootOffset = modes[chordIndex % modes.count]
            return baseNote + rootOffset
        }
    }
    
    private func determineChordType(
        chordIndex: Int,
        harmonicMode: HarmonicMode,
        parameters: PatternParameters
    ) -> ChordType {
        switch harmonicMode {
        case .tonal:
            // Traditional chord types
            let types: [ChordType] = [.major, .minor, .major, .diminished]
            return types[chordIndex % types.count]
            
        case .modal:
            // Modal chord types
            let types: [ChordType] = [.major, .minor, .minor, .major, .major, .minor, .diminished]
            return types[chordIndex % types.count]
            
        case .atonal:
            // Atonal chord types
            let types: [ChordType] = [.augmented, .diminished, .major, .minor, .suspended]
            return types[chordIndex % types.count]
            
        case .polymodal:
            // Polymodal chord types
            let types: [ChordType] = [.major, .minor, .diminished, .augmented, .suspended, .major7, .minor7]
            return types[chordIndex % types.count]
        }
    }
    
    private func determineHarmonicFunction(chordIndex: Int, harmonicMode: HarmonicMode) -> HarmonicFunction {
        switch harmonicMode {
        case .tonal:
            let functions: [HarmonicFunction] = [.tonic, .subdominant, .dominant, .tonic]
            return functions[chordIndex % functions.count]
            
        case .modal:
            return .passing
            
        case .atonal:
            return .passing
            
        case .polymodal:
            return .neighbor
        }
    }
    
    private func applyHarmonicVariations(
        progression: [HarmonicChord],
        parameters: PatternParameters
    ) -> [HarmonicChord] {
        var variedProgression = progression
        
        // Apply harmonic variations based on pattern
        for i in 0..<variedProgression.count {
            let variation = calculateHarmonicVariation(
                index: i,
                chord: variedProgression[i],
                parameters: parameters
            )
            variedProgression[i] = variation
        }
        
        return variedProgression
    }
    
    private func calculateHarmonicVariation(
        index: Int,
        chord: HarmonicChord,
        parameters: PatternParameters
    ) -> HarmonicChord {
        var variedChord = chord
        
        // Apply contour-based variations
        switch parameters.contourPattern {
        case .linear:
            // Linear harmonic progression
            variedChord.root += (index % 12)
            
        case .arch:
            // Arch shape - higher in middle
            let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
            let archOffset = Int(sin(normalizedIndex * .pi) * 6)
            variedChord.root += archOffset
            
        case .invertedArch:
            // Inverted arch - lower in middle
            let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
            let archOffset = Int((1.0 - sin(normalizedIndex * .pi)) * 6)
            variedChord.root += archOffset
            
        case .wave:
            // Wave pattern
            let waveOffset = Int(sin(Double(index) * 0.5) * 4)
            variedChord.root += waveOffset
            
        case .random:
            // Random variation
            let randomOffset = Int.random(in: -3...3)
            variedChord.root += randomOffset
            
        case .mirror:
            // Mirror pattern - symmetrical around center
            let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
            let mirrorOffset = Int(Double(12) * (1.0 - abs(2.0 * normalizedIndex - 1.0)))
            variedChord.root += mirrorOffset
        }
        
        // Ensure root is within valid range
        variedChord.root = max(0, min(127, variedChord.root))
        
        return variedChord
    }
    
    private func applyChordVoicings(
        harmony: [HarmonicChord],
        parameters: PatternParameters
    ) -> [VoicedChord] {
        return harmony.map { chord in
            let notes = generateChordNotes(
                chord: chord,
                settings: parameters.chordGeneration
            )
            
            return VoicedChord(
                chord: chord,
                notes: notes,
                voicing: parameters.chordGeneration.voicingPreference
            )
        }
    }
    
    private func generateChordNotes(
        chord: HarmonicChord,
        settings: ChordSettings
    ) -> [Int] {
        var notes: [Int] = []
        let root = chord.root
        
        // Add root note
        notes.append(root)
        
        // Add chord tones based on chord type
        let intervals = getChordIntervals(chordType: chord.type)
        
        for i in 0..<min(settings.chordSize - 1, intervals.count) {
            let note = root + intervals[i]
            if note >= 0 && note <= 127 {
                notes.append(note)
            }
        }
        
        // Apply voicing preference
        notes = applyVoicing(notes: notes, preference: settings.voicingPreference)
        
        return notes
    }
    
    private func getChordIntervals(chordType: ChordType) -> [Int] {
        switch chordType {
        case .major:
            return [4, 7] // Major third, perfect fifth
        case .minor:
            return [3, 7] // Minor third, perfect fifth
        case .diminished:
            return [3, 6] // Minor third, diminished fifth
        case .augmented:
            return [4, 8] // Major third, augmented fifth
        case .suspended:
            return [5, 7] // Perfect fourth, perfect fifth
        case .major7:
            return [4, 7, 11] // Major third, perfect fifth, major seventh
        case .minor7:
            return [3, 7, 10] // Minor third, perfect fifth, minor seventh
        }
    }
    
    private func applyVoicing(notes: [Int], preference: VoicingPreference) -> [Int] {
        switch preference {
        case .close:
            return notes // Keep close voicing
            
        case .open:
            // Spread out the voicing
            var openNotes: [Int] = []
            for (index, note) in notes.enumerated() {
                openNotes.append(note + (index * 12)) // Add octaves
            }
            return openNotes
            
        case .mixed:
            // Mix of close and open voicing
            var mixedNotes: [Int] = []
            for (index, note) in notes.enumerated() {
                if index % 2 == 0 {
                    mixedNotes.append(note)
                } else {
                    mixedNotes.append(note + 12) // Add octave
                }
            }
            return mixedNotes
        }
    }
    
    private func applyHarmonicRhythm(
        harmony: [VoicedChord],
        parameters: PatternParameters
    ) -> [VoicedChord] {
        var rhythmicHarmony = harmony
        
        // Apply harmonic rhythm based on settings
        let changeFrequency = parameters.harmonicRhythm.chordChangeFrequency
        let syncopationLevel = parameters.harmonicRhythm.syncopationLevel
        
        for i in 0..<rhythmicHarmony.count {
            // Apply syncopation to chord changes
            if i % changeFrequency == 0 && syncopationLevel > 0 {
                let syncopatedChord = applySyncopationToChord(
                    chord: rhythmicHarmony[i],
                    level: syncopationLevel
                )
                rhythmicHarmony[i] = syncopatedChord
            }
        }
        
        return rhythmicHarmony
    }
    
    private func applySyncopationToChord(
        chord: VoicedChord,
        level: Double
    ) -> VoicedChord {
        var syncopatedChord = chord
        
        // Add syncopated notes to the chord
        if Double.random(in: 0...1) < level {
            let syncopatedNote = chord.chord.root + 1 // Add chromatic neighbor
            if syncopatedNote >= 0 && syncopatedNote <= 127 {
                syncopatedChord.notes.append(syncopatedNote)
            }
        }
        
        return syncopatedChord
    }
    
    private func applyHarmonicTension(
        harmony: [VoicedChord],
        parameters: PatternParameters
    ) -> [VoicedChord] {
        var tensionedHarmony = harmony
        let tension = parameters.harmonicRhythm.harmonicTension
        
        for i in 0..<tensionedHarmony.count {
            let tensionedChord = applyTensionToChord(
                chord: tensionedHarmony[i],
                tension: tension,
                index: i
            )
            tensionedHarmony[i] = tensionedChord
        }
        
        return tensionedHarmony
    }
    
    private func applyTensionToChord(
        chord: VoicedChord,
        tension: Double,
        index: Int
    ) -> VoicedChord {
        var tensionedChord = chord
        
        // Add tension notes based on tension level
        if tension > 0.5 {
            let tensionNote = chord.chord.root + 6 // Tritone for maximum tension
            if tensionNote >= 0 && tensionNote <= 127 {
                tensionedChord.notes.append(tensionNote)
            }
        }
        
        // Add passing tones for moderate tension
        if tension > 0.3 && index % 2 == 0 {
            let passingNote = chord.chord.root + 2 // Major second
            if passingNote >= 0 && passingNote <= 127 {
                tensionedChord.notes.append(passingNote)
            }
        }
        
        return tensionedChord
    }
    
    private func convertToMIDIInfo(
        harmony: [VoicedChord],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var midiSequence: [MIDIInfo] = []
        
        for (index, voicedChord) in harmony.enumerated() {
            for (noteIndex, note) in voicedChord.notes.enumerated() {
                let velocity = calculateHarmonicVelocity(
                    for: index,
                    noteIndex: noteIndex,
                    note: note,
                    chord: voicedChord.chord,
                    settings: parameters.velocitySettings
                )
                
                let duration = calculateHarmonicDuration(
                    chordIndex: index,
                    noteIndex: noteIndex,
                    baseDuration: parameters.baseNoteDuration,
                    parameters: parameters
                )
                
                let midiNote = MIDIInfo(
                    note: note,
                    velocity: velocity,
                    beatLength: duration
                )
                
                midiSequence.append(midiNote)
            }
        }
        
        return midiSequence
    }
    
    private func calculateHarmonicVelocity(
        for chordIndex: Int,
        noteIndex: Int,
        note: Int,
        chord: HarmonicChord,
        settings: VelocitySettings
    ) -> UInt8 {
        var velocity = settings.calculateVelocity(for: chordIndex, note: note)
        
        // Apply harmonic function emphasis
        switch chord.function {
        case .tonic:
            velocity = UInt8(clamping: Int(velocity) + 10)
        case .dominant:
            velocity = UInt8(clamping: Int(velocity) + 15)
        case .subdominant:
            velocity = UInt8(clamping: Int(velocity) + 5)
        case .leadingTone:
            velocity = UInt8(clamping: Int(velocity) + 20)
        case .passing:
            velocity = UInt8(clamping: Int(velocity) - 5)
        case .neighbor:
            velocity = UInt8(clamping: Int(velocity) - 10)
        }
        
        // Apply root note emphasis
        if noteIndex == 0 {
            velocity = UInt8(clamping: Int(velocity) + 10)
        }
        
        return velocity
    }
    
    private func calculateHarmonicDuration(
        chordIndex: Int,
        noteIndex: Int,
        baseDuration: TimeInterval,
        parameters: PatternParameters
    ) -> TimeInterval {
        var duration = baseDuration
        
        // Apply harmonic rhythm
        let changeFrequency = parameters.harmonicRhythm.chordChangeFrequency
        if chordIndex % changeFrequency == 0 {
            duration *= 1.5 // Longer duration for chord changes
        }
        
        // Apply note position within chord
        if noteIndex == 0 {
            duration *= 1.2 // Root note gets longer duration
        }
        
        return duration
    }
    
    private func applyHarmonicRefinements(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var refinedSequence = sequence
        
        // Apply harmonic polish
        refinedSequence = applyHarmonicPolish(
            sequence: refinedSequence,
            parameters: parameters
        )
        
        return refinedSequence
    }
    
    private func applyHarmonicPolish(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var polishedSequence = sequence
        
        // Apply subtle harmonic adjustments
        for i in 0..<polishedSequence.count {
            let harmonicAdjustment = calculateHarmonicAdjustment(
                index: i,
                parameters: parameters
            )
            polishedSequence[i].velocity = UInt8(clamping: Int(polishedSequence[i].velocity) + harmonicAdjustment)
        }
        
        return polishedSequence
    }
    
    private func calculateHarmonicAdjustment(
        index: Int,
        parameters: PatternParameters
    ) -> Int {
        // Apply subtle harmonic adjustments based on context
        let baseAdjustment = 0
        
        // Add slight emphasis for harmonic function changes
        if index % 4 == 0 {
            return baseAdjustment + 5
        }
        
        return baseAdjustment
    }
    
    private func logPerformanceMetrics(
        generationTime: TimeInterval,
        noteCount: Int,
        parameters: PatternParameters
    ) {
        #if DEBUG
        print("HarmonicPatternGenerator: Generated \(noteCount) notes in \(String(format: "%.3f", generationTime))s")
        print("  - Harmonic Mode: \(parameters.harmonicMode.rawValue)")
        print("  - Chord Size: \(parameters.chordGeneration.chordSize)")
        print("  - Voicing: \(parameters.chordGeneration.voicingPreference.rawValue)")
        print("  - Harmonic Tension: \(parameters.harmonicRhythm.harmonicTension)")
        #endif
    }
}

// MARK: - Supporting Types

/// Represents a harmonic chord
struct HarmonicChord {
    var root: Int
    let type: ChordType
    let position: Int
    let function: HarmonicFunction
}

/// Represents a chord with specific voicing
struct VoicedChord {
    let chord: HarmonicChord
    var notes: [Int]
    let voicing: VoicingPreference
}

/// Types of chords
enum ChordType: String, CaseIterable {
    case major = "Major"
    case minor = "Minor"
    case diminished = "Diminished"
    case augmented = "Augmented"
    case suspended = "Suspended"
    case major7 = "Major 7"
    case minor7 = "Minor 7"
} 