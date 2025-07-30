//
//  ContourPatternGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Generates melodic contour patterns according to Slonimsky's Thesaurus
class ContourPatternGenerator: BasePatternGenerator {
    
    init() {
        super.init(
            name: "Contour Pattern Generator",
            description: "Generates melodic contour patterns with contour analysis, transformations, and contour-based variations"
        )
    }
    
    override func generatePattern(parameters: PatternParameters) -> [MIDIInfo] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate base melodic contour
        let baseContour = generateBaseContour(parameters: parameters)
        
        // Apply contour patterns and transformations
        let transformedContour = applyContourTransformations(
            contour: baseContour,
            parameters: parameters
        )
        
        // Apply contour analysis and refinement
        let analyzedContour = applyContourAnalysis(
            contour: transformedContour,
            parameters: parameters
        )
        
        // Apply contour-based variations
        let variedContour = applyContourVariations(
            contour: analyzedContour,
            parameters: parameters
        )
        
        // Apply register shifts
        let noteValues = variedContour.map { $0.note }
        let shiftedNotes = applyRegisterShifts(
            notes: noteValues,
            pattern: parameters.registerShifts,
            maxShift: parameters.toneShifting.maxToneShift
        )
        
        // Update the contour with shifted notes
        var shiftedContour = variedContour
        for i in 0..<shiftedContour.count {
            shiftedContour[i].note = shiftedNotes[i]
        }
        
        // Convert to MIDIInfo with velocity and duration
        let midiSequence = convertToMIDIInfo(
            contour: shiftedContour,
            parameters: parameters
        )
        
        // Apply final contour refinements
        let finalSequence = applyContourRefinements(
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
        
        // Contour patterns may add complexity through transformations
        let contourMultiplier = calculateContourMultiplier(parameters: parameters)
        
        // Directional patterns affect note count
        let directionalMultiplier = calculateDirectionalMultiplier(parameters: parameters)
        
        // Register shifts may add notes
        let registerMultiplier = parameters.toneShifting.maxToneShift > 0 ? 1.2 : 1.0
        
        return Int(Double(baseCount) * contourMultiplier * directionalMultiplier * registerMultiplier)
    }
    
    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        
        // Contour-specific validation
        guard parameters.contourPattern != .random || parameters.totalNotes <= 50 else {
            return false // Limit random contour complexity
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func generateBaseContour(parameters: PatternParameters) -> [ContourNote] {
        var contourNotes: [ContourNote] = []
        let rootNote = parameters.rootNote
        
        for i in 0..<parameters.totalNotes {
            let note = generateNoteForContourPosition(
                index: i,
                rootNote: rootNote,
                parameters: parameters
            )
            
            let contour = ContourNote(
                note: note,
                position: i,
                contourType: determineContourType(index: i, parameters: parameters),
                direction: determineContourDirection(index: i, parameters: parameters)
            )
            
            contourNotes.append(contour)
        }
        
        return contourNotes
    }
    
    private func generateNoteForContourPosition(
        index: Int,
        rootNote: Int,
        parameters: PatternParameters
    ) -> Int {
        // Prevent division by zero
        guard parameters.totalNotes > 1 else {
            return rootNote
        }
        let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
        
        switch parameters.contourPattern {
        case .linear:
            // Linear progression
            let interval = Int(normalizedIndex * 24) // Two octaves range
            return rootNote + interval
            
        case .arch:
            // Arch shape - higher in middle
            let archHeight = sin(normalizedIndex * .pi) * 24
            return rootNote + Int(archHeight)
            
        case .invertedArch:
            // Inverted arch - lower in middle
            let archHeight = (1.0 - sin(normalizedIndex * .pi)) * 24
            return rootNote + Int(archHeight)
            
        case .wave:
            // Wave pattern
            let waveHeight = sin(normalizedIndex * .pi * 3) * 12
            return rootNote + Int(waveHeight)
            
        case .random:
            // Random contour
            let randomInterval = Int.random(in: -12...12)
            return rootNote + randomInterval
            
        case .mirror:
            // Mirror pattern - symmetrical around center
            let mirrorHeight = (1.0 - abs(2.0 * normalizedIndex - 1.0)) * 24
            return rootNote + Int(mirrorHeight)
        }
    }
    
    private func determineContourType(index: Int, parameters: PatternParameters) -> ContourType {
        let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
        
        switch parameters.contourPattern {
        case .linear:
            return normalizedIndex < 0.5 ? .ascending : .descending
            
        case .arch:
            return normalizedIndex < 0.5 ? .ascending : .descending
            
        case .invertedArch:
            return normalizedIndex < 0.5 ? .descending : .ascending
            
        case .wave:
            let wavePhase = sin(normalizedIndex * .pi * 3)
            return wavePhase > 0 ? .ascending : .descending
            
        case .random:
            return Bool.random() ? .ascending : .descending
            
        case .mirror:
            return normalizedIndex < 0.5 ? .ascending : .descending
        }
    }
    
    private func determineContourDirection(index: Int, parameters: PatternParameters) -> ContourDirection {
        let normalizedIndex = Double(index) / Double(parameters.totalNotes - 1)
        
        switch parameters.contourPattern {
        case .linear:
            return .steady
            
        case .arch:
            return normalizedIndex < 0.5 ? .accelerating : .decelerating
            
        case .invertedArch:
            return normalizedIndex < 0.5 ? .decelerating : .accelerating
            
        case .wave:
            return .oscillating
            
        case .random:
            return .irregular
            
        case .mirror:
            return .steady
        }
    }
    
    private func applyContourTransformations(
        contour: [ContourNote],
        parameters: PatternParameters
    ) -> [ContourNote] {
        var transformedContour = contour
        
        // Apply contour transformations based on pattern
        for i in 0..<transformedContour.count {
            let transformation = calculateContourTransformation(
                index: i,
                note: transformedContour[i],
                parameters: parameters
            )
            transformedContour[i] = transformation
        }
        
        return transformedContour
    }
    
    private func calculateContourTransformation(
        index: Int,
        note: ContourNote,
        parameters: PatternParameters
    ) -> ContourNote {
        var transformedNote = note
        
        // Apply interval pattern effects
        switch parameters.intervalPattern {
        case .ascending:
            transformedNote.note += index % 3
            
        case .descending:
            transformedNote.note -= index % 3
            
        case .alternating:
            transformedNote.note += (index % 2 == 0 ? 2 : -2)
            
        case .mirror:
            let mirrorOffset = parameters.mirrorPoints > 0 ? (index % (parameters.mirrorPoints * 2)) : 0
            if mirrorOffset >= parameters.mirrorPoints {
                transformedNote.note -= 4
            } else {
                transformedNote.note += 4
            }
            
        case .retrograde:
            transformedNote.note += (parameters.totalNotes - index) % 3
        }
        
        // Ensure note is within valid range
        transformedNote.note = max(0, min(127, transformedNote.note))
        
        return transformedNote
    }
    
    private func applyContourAnalysis(
        contour: [ContourNote],
        parameters: PatternParameters
    ) -> [ContourNote] {
        var analyzedContour = contour
        
        // Analyze contour characteristics
        let contourAnalysis = analyzeContourCharacteristics(contour: contour)
        
        // Apply analysis-based refinements
        for i in 0..<analyzedContour.count {
            let refinement = applyContourRefinement(
                index: i,
                note: analyzedContour[i],
                analysis: contourAnalysis,
                parameters: parameters
            )
            analyzedContour[i] = refinement
        }
        
        return analyzedContour
    }
    
    private func analyzeContourCharacteristics(contour: [ContourNote]) -> ContourAnalysis {
        let notes = contour.map(\.note)
        let minNote = notes.min() ?? 0
        let maxNote = notes.max() ?? 0
        let range = maxNote - minNote
        
        // Calculate contour direction changes
        var directionChanges = 0
        for i in 1..<notes.count {
            let prevDirection = notes[i-1] < notes[i] ? 1 : -1
            let currDirection = notes[i] < notes[i+1] ? 1 : -1
            if prevDirection != currDirection {
                directionChanges += 1
            }
        }
        
        // Calculate contour complexity
        let complexity = Double(directionChanges) / Double(notes.count)
        
        return ContourAnalysis(
            range: range,
            directionChanges: directionChanges,
            complexity: complexity,
            averageInterval: Double(range) / Double(notes.count)
        )
    }
    
    private func applyContourRefinement(
        index: Int,
        note: ContourNote,
        analysis: ContourAnalysis,
        parameters: PatternParameters
    ) -> ContourNote {
        var refinedNote = note
        
        // Apply complexity-based refinements
        if analysis.complexity > 0.5 {
            // High complexity - add more variation
            let variation = Int(sin(Double(index) * 0.5) * 3)
            refinedNote.note += variation
        } else if analysis.complexity < 0.2 {
            // Low complexity - smooth the contour
            refinedNote.note = note.note + (index % 2 == 0 ? 1 : -1)
        }
        
        // Apply range-based refinements
        if analysis.range > 24 {
            // Large range - compress slightly
            refinedNote.note = note.note + (note.note > parameters.rootNote ? -1 : 1)
        } else if analysis.range < 6 {
            // Small range - expand slightly
            refinedNote.note = note.note + (index % 2 == 0 ? 2 : -2)
        }
        
        // Ensure note is within valid range
        refinedNote.note = max(0, min(127, refinedNote.note))
        
        return refinedNote
    }
    
    private func applyContourVariations(
        contour: [ContourNote],
        parameters: PatternParameters
    ) -> [ContourNote] {
        var variedContour = contour
        
        // Apply contour-based variations
        for i in 0..<variedContour.count {
            let variation = calculateContourVariation(
                index: i,
                note: variedContour[i],
                parameters: parameters
            )
            variedContour[i] = variation
        }
        
        return variedContour
    }
    
    private func calculateContourVariation(
        index: Int,
        note: ContourNote,
        parameters: PatternParameters
    ) -> ContourNote {
        var variedNote = note
        
        // Apply primary direction effects
        switch parameters.primaryDirection {
        case .ascending:
            variedNote.note += index % 4
            
        case .descending:
            variedNote.note -= index % 4
            
        case .alternating:
            variedNote.note += (index % 2 == 0 ? 2 : -2)
        }
        
        // Apply symmetrical intervals if enabled
        if parameters.symmetricalIntervals {
            let symmetryOffset = (index % 2 == 0 ? 1 : -1) * (index % 6)
            variedNote.note += symmetryOffset
        }
        
        // Apply register shifts
        if parameters.toneShifting.toneIncrement > 0 {
            let shiftOffset = (index / 4) * parameters.toneShifting.toneIncrement
            variedNote.note += shiftOffset
        }
        
        // Ensure note is within valid range
        variedNote.note = max(0, min(127, variedNote.note))
        
        return variedNote
    }
    
    private func convertToMIDIInfo(
        contour: [ContourNote],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        return contour.enumerated().map { index, contourNote in
            let duration = calculateContourDuration(
                index: index,
                contourNote: contourNote,
                baseDuration: parameters.baseNoteDuration,
                parameters: parameters
            )
            
            let velocity = calculateContourVelocity(
                for: index,
                contourNote: contourNote,
                settings: parameters.velocitySettings
            )
            
            return MIDIInfo(
                note: contourNote.note,
                velocity: velocity,
                beatLength: duration
            )
        }
    }
    
    private func calculateContourDuration(
        index: Int,
        contourNote: ContourNote,
        baseDuration: TimeInterval,
        parameters: PatternParameters
    ) -> TimeInterval {
        var duration = baseDuration
        
        // Apply contour-based duration variations
        switch contourNote.contourType {
        case .ascending:
            duration *= 1.0 + (Double(index) * 0.01)
        case .descending:
            duration *= 1.0 - (Double(index) * 0.01)
        case .level:
            duration *= 1.0
        }
        
        // Apply direction-based duration
        switch contourNote.direction {
        case .accelerating:
            duration *= 0.9
        case .decelerating:
            duration *= 1.1
        case .oscillating:
            duration *= 1.0 + sin(Double(index) * 0.5) * 0.1
        case .steady:
            break
        case .irregular:
            duration *= Double.random(in: 0.8...1.2)
        }
        
        // Apply pattern-based duration
        switch parameters.noteDurationPattern {
        case .uniform:
            break
        case .alternating:
            duration = index % 2 == 0 ? baseDuration : baseDuration * 0.7
        case .progressive:
            duration *= 1.0 + (Double(index) * 0.05)
        case .random:
            duration *= Double.random(in: 0.7...1.3)
        }
        
        return max(duration, 0.0625) // Minimum duration
    }
    
    private func calculateContourVelocity(
        for index: Int,
        contourNote: ContourNote,
        settings: VelocitySettings
    ) -> UInt8 {
        var velocity = settings.calculateVelocity(for: index, note: contourNote.note)
        
        // Apply contour-based velocity adjustments
        switch contourNote.contourType {
        case .ascending:
            velocity = UInt8(clamping: Int(velocity) + 5)
        case .descending:
            velocity = UInt8(clamping: Int(velocity) - 5)
        case .level:
            break
        }
        
        // Apply direction-based velocity
        switch contourNote.direction {
        case .accelerating:
            velocity = UInt8(clamping: Int(velocity) + 10)
        case .decelerating:
            velocity = UInt8(clamping: Int(velocity) - 10)
        case .oscillating:
            let oscillation = Int(sin(Double(index) * 0.5) * 8)
            velocity = UInt8(clamping: Int(velocity) + oscillation)
        case .steady:
            break
        case .irregular:
            let irregularity = Int.random(in: -10...10)
            velocity = UInt8(clamping: Int(velocity) + irregularity)
        }
        
        return velocity
    }
    
    private func applyContourRefinements(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var refinedSequence = sequence
        
        // Apply contour-based refinements
        refinedSequence = applyContourPolish(
            sequence: refinedSequence,
            parameters: parameters
        )
        
        return refinedSequence
    }
    
    private func applyContourPolish(
        sequence: [MIDIInfo],
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        var polishedSequence = sequence
        
        // Apply subtle contour adjustments
        for i in 0..<polishedSequence.count {
            let contourAdjustment = calculateContourAdjustment(
                index: i,
                parameters: parameters
            )
            polishedSequence[i].velocity = UInt8(clamping: Int(polishedSequence[i].velocity) + contourAdjustment)
        }
        
        return polishedSequence
    }
    
    private func calculateContourAdjustment(
        index: Int,
        parameters: PatternParameters
    ) -> Int {
        // Apply subtle contour adjustments based on context
        let baseAdjustment = 0
        
        // Add slight emphasis for contour direction changes
        if index > 0 && index < parameters.totalNotes - 1 {
            let prevNote = index - 1
            let nextNote = index + 1
            if (prevNote < nextNote && index > prevNote) || (prevNote > nextNote && index < prevNote) {
                return baseAdjustment + 3
            }
        }
        
        return baseAdjustment
    }
    
    private func calculateContourMultiplier(parameters: PatternParameters) -> Double {
        switch parameters.contourPattern {
        case .linear:
            return 1.0
        case .arch:
            return 1.2
        case .invertedArch:
            return 1.2
        case .wave:
            return 1.5
        case .random:
            return 1.3
        case .mirror:
            return 1.1
        }
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
        print("ContourPatternGenerator: Generated \(noteCount) notes in \(String(format: "%.3f", generationTime))s")
        print("  - Contour Pattern: \(parameters.contourPattern.rawValue)")
        print("  - Primary Direction: \(parameters.primaryDirection.rawValue)")
        print("  - Symmetrical Intervals: \(parameters.symmetricalIntervals)")
        print("  - Register Shifts: \(parameters.registerShifts.rawValue)")
        #endif
    }
}

// MARK: - Supporting Types

/// Represents a note with contour information
struct ContourNote {
    var note: Int
    let position: Int
    let contourType: ContourType
    let direction: ContourDirection
}

/// Types of contour movements
enum ContourType: String, CaseIterable {
    case ascending = "Ascending"
    case descending = "Descending"
    case level = "Level"
}

/// Directions of contour movement
enum ContourDirection: String, CaseIterable {
    case accelerating = "Accelerating"
    case decelerating = "Decelerating"
    case steady = "Steady"
    case oscillating = "Oscillating"
    case irregular = "Irregular"
}

/// Analysis of contour characteristics
struct ContourAnalysis {
    let range: Int
    let directionChanges: Int
    let complexity: Double
    let averageInterval: Double
} 