//
//  SymmetricalPatternGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Generates symmetrical patterns according to Slonimsky's Thesaurus
class SymmetricalPatternGenerator: BasePatternGenerator {
    
    init() {
        super.init(
            name: "Symmetrical Pattern Generator",
            description: "Generates symmetrical patterns with inversions, retrogrades, and symmetrical scale transformations"
        )
    }
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        return generatePattern(parameters: parameters, cycleIndex: 0)
    }
    
    override func generatePattern(parameters: PatternParameters, cycleIndex: Int, parameterCycles: [CyclicalParameterType: Int]? = nil) -> [MIDIInfo] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Apply cyclical changes to parameters for the current cycle
        let modifiedParameters = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        
        // Generate base symmetrical structure
        let baseStructure = generateBaseSymmetricalStructure(parameters: modifiedParameters)
        
        // Apply symmetrical transformations
        let transformedStructure = applySymmetricalTransformations(
            structure: baseStructure,
            parameters: modifiedParameters
        )
        
        // Apply inversions and retrogrades
        let invertedStructure = applyInversionsAndRetrogrades(
            structure: transformedStructure,
            parameters: modifiedParameters
        )
        
        // Apply symmetrical scale patterns
        let scaleStructure = applySymmetricalScalePatterns(
            structure: invertedStructure,
            parameters: modifiedParameters
        )
        
        // Apply register shifts
        let noteValues = scaleStructure.map { $0.note }
        let shiftedNotes = applyRegisterShifts(
            notes: noteValues,
            pattern: modifiedParameters.registerShifts,
            maxShift: modifiedParameters.toneShifting.maxToneShift
        )
        
        // Update the structure with shifted notes
        var shiftedStructure = scaleStructure
        for i in 0..<shiftedStructure.count {
            shiftedStructure[i].note = shiftedNotes[i]
        }
        
        // Convert to MIDIInfo with velocity and duration
        let midiSequence = convertToMIDIInfo(
            structure: shiftedStructure,
            parameters: modifiedParameters
        )
        
        // Apply final symmetrical refinements
        let finalSequence = applySymmetricalRefinements(
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
        
        // Symmetrical patterns typically double the note count
        let symmetryMultiplier = parameters.symmetricalIntervals ? 2.0 : 1.0
        
        // Inversions and retrogrades add complexity
        let transformationMultiplier = calculateTransformationMultiplier(parameters: parameters)
        
        // Mirror points affect note count
        let mirrorMultiplier = parameters.mirrorPoints > 0 ? Double(parameters.mirrorPoints + 1) : 1.0
        
        return Int(Double(baseCount) * symmetryMultiplier * transformationMultiplier * mirrorMultiplier)
    }
    
    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        
        // Symmetrical-specific validation
        guard parameters.mirrorPoints >= 0 && parameters.mirrorPoints <= 10 else {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func generateBaseSymmetricalStructure(parameters: PatternParameters) -> [SymmetricalNote] {
        var symmetricalNotes: [SymmetricalNote] = []
        let rootNote = parameters.rootNote
        
        for i in 0..<parameters.totalNotes {
            let note = generateNoteForSymmetricalPosition(
                index: i,
                rootNote: rootNote,
                parameters: parameters
            )
            
            let symmetricalNote = SymmetricalNote(
                note: note,
                position: i,
                symmetryType: determineSymmetryType(index: i, parameters: parameters),
                axis: calculateSymmetryAxis(index: i, parameters: parameters)
            )
            
            symmetricalNotes.append(symmetricalNote)
        }
        
        return symmetricalNotes
    }
    
    private func generateNoteForSymmetricalPosition(
        index: Int,
        rootNote: Int,
        parameters: PatternParameters
    ) -> Int {
        let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
        
        // Generate base note using scale intervals
        let scaleIntervals = parameters.scaleType.intervals
        let intervalIndex = index % scaleIntervals.count
        let baseInterval = scaleIntervals[intervalIndex]
        
        var note = rootNote + baseInterval
        
        // Apply symmetrical positioning
        if parameters.symmetricalIntervals {
            let symmetryOffset = calculateSymmetryOffset(
                normalizedIndex: normalizedIndex,
                parameters: parameters
            )
            note += symmetryOffset
        }
        
        return note
    }
    
    private func calculateSymmetryOffset(
        normalizedIndex: Double,
        parameters: PatternParameters
    ) -> Int {
        switch parameters.contourPattern {
        case .linear:
            return Int(normalizedIndex * 12)
            
        case .arch:
            let archHeight = sin(normalizedIndex * .pi) * 12
            return Int(archHeight)
            
        case .invertedArch:
            let archHeight = (1.0 - sin(normalizedIndex * .pi)) * 12
            return Int(archHeight)
            
        case .wave:
            let waveHeight = sin(normalizedIndex * .pi * 2) * 8
            return Int(waveHeight)
            
        case .random:
            return Int.random(in: -6...6)
            
        case .mirror:
            let mirrorHeight = (1.0 - abs(2.0 * normalizedIndex - 1.0)) * 12
            return Int(mirrorHeight)
        }
    }
    
    private func determineSymmetryType(index: Int, parameters: PatternParameters) -> SymmetryType {
        let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
        
        if parameters.mirrorPoints > 0 {
            let mirrorIndex = index % (parameters.mirrorPoints * 2)
            if mirrorIndex < parameters.mirrorPoints {
                return .original
            } else {
                return .mirrored
            }
        }
        
        if normalizedIndex < 0.5 {
            return .original
        } else {
            return .inverted
        }
    }
    
    private func calculateSymmetryAxis(index: Int, parameters: PatternParameters) -> Int {
        return parameters.rootNote + 6 // Tritone axis for maximum symmetry
    }
    
    private func applySymmetricalTransformations(
        structure: [SymmetricalNote],
        parameters: PatternParameters
    ) -> [SymmetricalNote] {
        var transformedStructure = structure
        
        // Apply symmetrical transformations based on pattern
        for i in 0..<transformedStructure.count {
            let transformation = calculateSymmetricalTransformation(
                index: i,
                note: transformedStructure[i],
                parameters: parameters
            )
            transformedStructure[i] = transformation
        }
        
        return transformedStructure
    }
    
    private func calculateSymmetricalTransformation(
        index: Int,
        note: SymmetricalNote,
        parameters: PatternParameters
    ) -> SymmetricalNote {
        var transformedNote = note
        
        // Apply interval pattern effects
        switch parameters.intervalPattern {
        case .ascending:
            transformedNote.note += index % 4
            
        case .descending:
            transformedNote.note -= index % 4
            
        case .alternating:
            transformedNote.note += (index % 2 == 0 ? 2 : -2)
            
        case .mirror:
            let mirrorOffset = parameters.mirrorPoints > 0 ? (index % (parameters.mirrorPoints * 2)) : 0
            if mirrorOffset >= parameters.mirrorPoints {
                transformedNote.note = note.axis + (note.axis - note.note)
            }
            
        case .retrograde:
            transformedNote.note += (parameters.totalNotes - index) % 3
        }
        
        // Apply symmetrical intervals
        if parameters.symmetricalIntervals {
            transformedNote.note = applySymmetricalInterval(
                note: transformedNote.note,
                axis: note.axis,
                symmetryType: note.symmetryType
            )
        }
        
        // Ensure note is within valid range
        transformedNote.note = max(0, min(127, transformedNote.note))
        
        return transformedNote
    }
    
    private func applySymmetricalInterval(
        note: Int,
        axis: Int,
        symmetryType: SymmetryType
    ) -> Int {
        switch symmetryType {
        case .original:
            return note
            
        case .inverted:
            // Invert around the axis
            let distance = note - axis
            return axis - distance
            
        case .mirrored:
            // Mirror around the axis
            let distance = note - axis
            return axis + distance
            
        case .retrograde:
            // Retrograde (reverse order)
            return note
        }
    }
    
    private func applyInversionsAndRetrogrades(
        structure: [SymmetricalNote],
        parameters: PatternParameters
    ) -> [SymmetricalNote] {
        var invertedStructure = structure
        
        // Apply inversions if enabled
        if parameters.intervalInversion {
            invertedStructure = applyInversions(structure: invertedStructure, parameters: parameters)
        }
        
        // Apply retrogrades if enabled
        if parameters.retrogradeSections {
            invertedStructure = applyRetrogrades(structure: invertedStructure, parameters: parameters)
        }
        
        return invertedStructure
    }
    
    private func applyInversions(structure: [SymmetricalNote], parameters: PatternParameters) -> [SymmetricalNote] {
        var invertedStructure: [SymmetricalNote] = []
        
        for note in structure {
            invertedStructure.append(note)
            
            // Add inverted note
            let invertedNote = SymmetricalNote(
                note: note.axis + (note.axis - note.note),
                position: note.position,
                symmetryType: .inverted,
                axis: note.axis
            )
            invertedStructure.append(invertedNote)
        }
        
        return invertedStructure
    }
    
    private func applyRetrogrades(structure: [SymmetricalNote], parameters: PatternParameters) -> [SymmetricalNote] {
        var retrogradeStructure: [SymmetricalNote] = []
        
        // Add original structure
        retrogradeStructure.append(contentsOf: structure)
        
        // Add retrograde (reversed) structure
        let retrogradeNotes = structure.reversed().map { note in
            SymmetricalNote(
                note: note.note,
                position: note.position,
                symmetryType: .retrograde,
                axis: note.axis
            )
        }
        retrogradeStructure.append(contentsOf: retrogradeNotes)
        
        return retrogradeStructure
    }
    
    private func applySymmetricalScalePatterns(
        structure: [SymmetricalNote],
        parameters: PatternParameters
    ) -> [SymmetricalNote] {
        var scaleStructure = structure
        
        // Apply symmetrical scale patterns
        for i in 0..<scaleStructure.count {
            let scalePattern = calculateSymmetricalScalePattern(
                index: i,
                note: scaleStructure[i],
                parameters: parameters
            )
            scaleStructure[i] = scalePattern
        }
        
        return scaleStructure
    }
    
    private func calculateSymmetricalScalePattern(
        index: Int,
        note: SymmetricalNote,
        parameters: PatternParameters
    ) -> SymmetricalNote {
        var scaleNote = note
        
        // Apply symmetrical scale transformations
        switch parameters.scaleType {
        case .wholeTone:
            // Whole tone scale is inherently symmetrical
            scaleNote.note = note.note + (index % 2 == 0 ? 2 : -2)
            
        case .octatonic:
            // Octatonic scale is symmetrical
            scaleNote.note = note.note + (index % 2 == 0 ? 1 : 2)
            
        case .diminished:
            // Diminished scale is symmetrical
            scaleNote.note = note.note + (index % 2 == 0 ? 1 : 2)
            
        case .augmented:
            // Augmented scale is symmetrical
            scaleNote.note = note.note + (index % 3 == 0 ? 3 : 1)
            
        default:
            // Apply symmetrical intervals to other scales
            if parameters.symmetricalIntervals {
                scaleNote.note = note.note + (index % 2 == 0 ? 2 : -2)
            }
        }
        
        // Ensure note is within valid range
        scaleNote.note = max(0, min(127, scaleNote.note))
        
        return scaleNote
    }
    
    private func convertToMIDIInfo(
        structure: [SymmetricalNote],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        let pitches = structure.map { $0.note }
        return MIDIPatternConverter.scheduleRhythm(
            pitches: pitches,
            parameters: parameters,
            velocityProvider: { [weak self] index, note in
                let symmetricalNote = structure[index % structure.count]
                return self?.calculateSymmetricalVelocity(
                    for: index,
                    symmetricalNote: symmetricalNote,
                    settings: parameters.velocitySettings,
                    parameters: parameters
                ) ?? parameters.velocitySettings.calculateVelocity(for: index, note: note)
            }
        )
    }
    
    private func calculateSymmetricalVelocity(
        for index: Int,
        symmetricalNote: SymmetricalNote,
        settings: VelocitySettings,
        parameters: PatternParameters
    ) -> UInt8 {
        var velocity = settings.calculateVelocity(for: index, note: symmetricalNote.note)
        
        // Apply symmetry-based velocity adjustments
        switch symmetricalNote.symmetryType {
        case .original:
            velocity = UInt8(clamping: Int(velocity) + 5)
        case .inverted:
            velocity = UInt8(clamping: Int(velocity) - 5)
        case .mirrored:
            velocity = UInt8(clamping: Int(velocity) + 10)
        case .retrograde:
            velocity = UInt8(clamping: Int(velocity) - 10)
        }
        
        // Apply symmetrical emphasis
        if parameters.symmetricalIntervals && index % 2 == 0 {
            velocity = UInt8(clamping: Int(velocity) + 8)
        }
        
        return velocity
    }
    
    private func applySymmetricalRefinements(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var refinedSequence = sequence
        
        // Apply symmetrical-based refinements
        refinedSequence = applySymmetricalPolish(
            sequence: refinedSequence,
            parameters: parameters
        )
        
        return refinedSequence
    }
    
    private func applySymmetricalPolish(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var polishedSequence = sequence
        
        // Apply subtle symmetrical adjustments
        for i in 0..<polishedSequence.count {
            let symmetricalAdjustment = calculateSymmetricalAdjustment(
                index: i,
                parameters: parameters
            )
            polishedSequence[i].velocity = UInt8(clamping: Int(polishedSequence[i].velocity) + symmetricalAdjustment)
        }
        
        return polishedSequence
    }
    
    private func calculateSymmetricalAdjustment(
        index: Int,
        parameters: PatternParameters
    ) -> Int {
        // Apply subtle symmetrical adjustments based on context
        let baseAdjustment = 0
        
        // Add slight emphasis for symmetrical points
        if parameters.mirrorPoints > 0 && index % parameters.mirrorPoints == 0 {
            return baseAdjustment + 5
        }
        
        // Add emphasis for symmetrical intervals
        if parameters.symmetricalIntervals && index % 4 == 0 {
            return baseAdjustment + 3
        }
        
        return baseAdjustment
    }
    
    private func calculateTransformationMultiplier(parameters: PatternParameters) -> Double {
        var multiplier = 1.0
        
        if parameters.intervalInversion {
            multiplier *= 2.0
        }
        
        if parameters.retrogradeSections {
            multiplier *= 2.0
        }
        
        if parameters.symmetricalIntervals {
            multiplier *= 1.5
        }
        
        return multiplier
    }
    
    private func logPerformanceMetrics(
        generationTime: TimeInterval,
        noteCount: Int,
        parameters: PatternParameters
    ) {
        #if DEBUG
        print("SymmetricalPatternGenerator: Generated \(noteCount) notes in \(String(format: "%.3f", generationTime))s")
        print("  - Symmetrical Intervals: \(parameters.symmetricalIntervals)")
        print("  - Interval Inversion: \(parameters.intervalInversion)")
        print("  - Retrograde Sections: \(parameters.retrogradeSections)")
        print("  - Mirror Points: \(parameters.mirrorPoints)")
        #endif
    }
}

// MARK: - Supporting Types

/// Represents a note with symmetrical information
struct SymmetricalNote {
    var note: Int
    let position: Int
    let symmetryType: SymmetryType
    let axis: Int
}

/// Types of symmetry transformations
enum SymmetryType: String, CaseIterable {
    case original = "Original"
    case inverted = "Inverted"
    case mirrored = "Mirrored"
    case retrograde = "Retrograde"
} 