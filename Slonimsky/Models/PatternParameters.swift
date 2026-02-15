//
//  PatternParameters.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Core parameters for pattern generation based on Slonimsky's Thesaurus
struct PatternParameters: Codable, Equatable, Hashable {
    // MARK: - Basic Parameters
    let rootNote: Int
    let scaleType: ScaleType
    let numberOfOctaves: Int
    let divisionsOfOctave: Int
    let tempo: Double
    let timeSignature: TimeSignature
    let iterations: Int
    let randomiseOrder: Bool
    
    // MARK: - Interval Patterns
    let primaryInterval: Int
    let secondaryInterval: Int
    let intervalPattern: IntervalPattern
    let intervalInversion: Bool
    let symmetricalIntervals: Bool
    
    // MARK: - Slonimsky Modulations
    var interpolation: ModulationSettings
    var infrapolation: ModulationSettings
    var ultrapolation: ModulationSettings
    
    // MARK: - Directional Patterns
    let mirror: Bool  // When true, appends inverted sequence (default: true)
    // Legacy parameters - kept for backward compatibility, may be restored later
    let primaryDirection: Direction  // Legacy: kept for compatibility
    let mirrorPoints: Int  // Legacy: kept for compatibility
    let retrogradeSections: Bool  // Legacy: kept for compatibility
    let registerShifts: RegisterShiftPattern
    let contourPattern: ContourPattern
    
    // MARK: - Rhythmic Patterns
    let noteDurationPattern: DurationPattern
    var baseNoteDuration: TimeInterval
    var rhythmicDensity: Double
    let syncopationLevel: Double
    let metricModulation: MetricModulationSettings
    
    // MARK: - Harmonic Context
    let harmonicMode: HarmonicMode
    let chordGeneration: ChordSettings
    let harmonicRhythm: HarmonicRhythmSettings
    
    // MARK: - Expression
    var velocitySettings: VelocitySettings
    var toneShifting: ToneShiftSettings
    
    // MARK: - Cyclical Parameters
    var cyclicalSettings: CyclicalSettings
    
    // MARK: - Initialization
    init(
        rootNote: Int = 60,
        scaleType: ScaleType = .chromatic,
        numberOfOctaves: Int = 1,
        divisionsOfOctave: Int = 12,
        tempo: Double = 120.0,
        timeSignature: TimeSignature = .common,
        iterations: Int = 1,
        randomiseOrder: Bool = false,
        primaryInterval: Int = 1,
        secondaryInterval: Int = 1,
        intervalPattern: IntervalPattern = .ascending,
        intervalInversion: Bool = false,
        symmetricalIntervals: Bool = false,
        interpolation: ModulationSettings = .default,
        infrapolation: ModulationSettings = .default,
        ultrapolation: ModulationSettings = .default,
        mirror: Bool = true,
        primaryDirection: Direction = .ascending,  // Legacy: kept for compatibility
        mirrorPoints: Int = 0,  // Legacy: kept for compatibility
        retrogradeSections: Bool = false,  // Legacy: kept for compatibility
        registerShifts: RegisterShiftPattern = .none,
        contourPattern: ContourPattern = .linear,
        noteDurationPattern: DurationPattern = .uniform,
        baseNoteDuration: TimeInterval = 0.25,
        rhythmicDensity: Double = 1.0,
        syncopationLevel: Double = 0.0,
        metricModulation: MetricModulationSettings = .default,
        harmonicMode: HarmonicMode = .tonal,
        chordGeneration: ChordSettings = .default,
        harmonicRhythm: HarmonicRhythmSettings = .default,
        velocitySettings: VelocitySettings = .default,
        toneShifting: ToneShiftSettings = .default,
        cyclicalSettings: CyclicalSettings = CyclicalSettings()
    ) {
        self.rootNote = rootNote
        self.scaleType = scaleType
        self.numberOfOctaves = numberOfOctaves
        self.divisionsOfOctave = divisionsOfOctave
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.iterations = iterations
        self.randomiseOrder = randomiseOrder
        self.primaryInterval = primaryInterval
        self.secondaryInterval = secondaryInterval
        self.intervalPattern = intervalPattern
        self.intervalInversion = intervalInversion
        self.symmetricalIntervals = symmetricalIntervals
        self.interpolation = interpolation
        self.infrapolation = infrapolation
        self.ultrapolation = ultrapolation
        self.mirror = mirror
        self.primaryDirection = primaryDirection
        self.mirrorPoints = mirrorPoints
        self.retrogradeSections = retrogradeSections
        self.registerShifts = registerShifts
        self.contourPattern = contourPattern
        self.noteDurationPattern = noteDurationPattern
        self.baseNoteDuration = baseNoteDuration
        self.rhythmicDensity = rhythmicDensity
        self.syncopationLevel = syncopationLevel
        self.metricModulation = metricModulation
        self.harmonicMode = harmonicMode
        self.chordGeneration = chordGeneration
        self.harmonicRhythm = harmonicRhythm
        self.velocitySettings = velocitySettings
        self.toneShifting = toneShifting
        self.cyclicalSettings = cyclicalSettings
    }
    
    // MARK: - Validation
    func validate() -> Bool {
        guard rootNote >= 0 && rootNote <= 127 else { return false }
        guard numberOfOctaves >= 1 && numberOfOctaves <= 8 else { return false }
        guard divisionsOfOctave >= 1 && divisionsOfOctave <= 12 else { return false }
        guard tempo >= 20.0 && tempo <= 300.0 else { return false }
        guard iterations >= 1 && iterations <= 10 else { return false }
        guard primaryInterval >= 1 && primaryInterval <= 12 else { return false }
        guard secondaryInterval >= 1 && secondaryInterval <= 12 else { return false }
        guard mirrorPoints >= 0 && mirrorPoints <= 10 else { return false }
        guard baseNoteDuration >= 0.0625 && baseNoteDuration <= 4.0 else { return false }
        guard rhythmicDensity >= 0.1 && rhythmicDensity <= 2.0 else { return false }
        guard syncopationLevel >= 0.0 && syncopationLevel <= 1.0 else { return false }
        
        return true
    }
    
    // MARK: - Helper Methods
    var totalNotes: Int {
        return numberOfOctaves * divisionsOfOctave
    }
    
    var intervalBetweenNotes: Int {
        return 12 / divisionsOfOctave
    }
    
    var estimatedDuration: TimeInterval {
        let totalNoteCount = totalNotes
        let modulationMultiplier = calculateModulationMultiplier()
        return Double(totalNoteCount) * baseNoteDuration * modulationMultiplier
    }
    
    private func calculateModulationMultiplier() -> Double {
        let interpMultiplier = 1.0 + Double(interpolation.numberOfNotes)
        let infraMultiplier = 1.0 + Double(infrapolation.numberOfNotes)
        let ultraMultiplier = 1.0 + Double(ultrapolation.numberOfNotes)
        return interpMultiplier * infraMultiplier * ultraMultiplier
    }
}

// MARK: - Supporting Types

/// Scale types based on Slonimsky's Thesaurus
enum ScaleType: String, CaseIterable, Codable {
    // Basic
    case none = "None"
    case chromatic = "Chromatic"
    case custom = "Custom"
    
    // Major / Minor
    case diatonic = "Diatonic"
    case naturalMinor = "Natural Minor"
    case harmonicMinor = "Harmonic Minor"
    case melodicMinor = "Melodic Minor"
    
    // Pentatonic / Blues
    case pentatonic = "Pentatonic"
    case minorPentatonic = "Minor Pentatonic"
    case blues = "Blues"
    
    // Modes
    case dorian = "Dorian"
    case phrygian = "Phrygian"
    case lydian = "Lydian"
    case mixolydian = "Mixolydian"
    case locrian = "Locrian"
    
    // Symmetric
    case wholeTone = "Whole-tone"
    case octatonic = "Octatonic"
    case diminished = "Diminished"
    case augmented = "Augmented"
    case tritone = "Tritone"
    
    // Exotic / World
    case hungarianMinor = "Hungarian Minor"
    case doubleHarmonicMajor = "Double Harmonic Major"
    case phrygianDominant = "Phrygian Dominant"
    case hirajoshi = "Hirajoshi"
    
    // Synthetic
    case prometheus = "Prometheus"
    case enigmatic = "Enigmatic"
    
    var intervals: [Int] {
        switch self {
        // Basic
        case .none:
            return [] // No predefined intervals - will use equal divisions
        case .chromatic:
            return Array(1...12)
        case .custom:
            return [1] // Default to chromatic for custom
            
        // Major / Minor
        case .diatonic:
            return [2, 2, 1, 2, 2, 2, 1] // Major scale
        case .naturalMinor:
            return [2, 1, 2, 2, 1, 2, 2] // Aeolian mode
        case .harmonicMinor:
            return [2, 1, 2, 2, 1, 3, 1] // Augmented 2nd between 6th and 7th
        case .melodicMinor:
            return [2, 1, 2, 2, 2, 2, 1] // Jazz minor (ascending form)
            
        // Pentatonic / Blues
        case .pentatonic:
            return [2, 2, 3, 2, 3] // Major pentatonic
        case .minorPentatonic:
            return [3, 2, 2, 3, 2] // Minor pentatonic
        case .blues:
            return [3, 2, 1, 1, 3, 2] // Minor pentatonic + flat 5
            
        // Modes
        case .dorian:
            return [2, 1, 2, 2, 2, 1, 2] // Minor with raised 6th
        case .phrygian:
            return [1, 2, 2, 2, 1, 2, 2] // Flamenco character
        case .lydian:
            return [2, 2, 2, 1, 2, 2, 1] // Raised 4th
        case .mixolydian:
            return [2, 2, 1, 2, 2, 1, 2] // Dominant 7th character
        case .locrian:
            return [1, 2, 2, 1, 2, 2, 2] // Diminished tonic
            
        // Symmetric
        case .wholeTone:
            return [2, 2, 2, 2, 2, 2]
        case .octatonic:
            return [1, 2, 1, 2, 1, 2, 1, 2] // Half-whole diminished
        case .diminished:
            return [2, 1, 2, 1, 2, 1, 2, 1] // Whole-half diminished
        case .augmented:
            return [3, 1, 3, 1, 3, 1] // Augmented scale
        case .tritone:
            return [1, 3, 2, 1, 3, 2] // Two tritone-related triads
            
        // Exotic / World
        case .hungarianMinor:
            return [2, 1, 3, 1, 1, 3, 1] // "Gypsy" minor
        case .doubleHarmonicMajor:
            return [1, 3, 1, 2, 1, 3, 1] // Arabic / Byzantine
        case .phrygianDominant:
            return [1, 3, 1, 2, 1, 2, 2] // Hijaz, Middle Eastern
        case .hirajoshi:
            return [2, 1, 4, 1, 4] // Japanese pentatonic
            
        // Synthetic
        case .prometheus:
            return [2, 2, 2, 3, 1, 2] // Scriabin's "mystic" scale
        case .enigmatic:
            return [1, 3, 2, 2, 2, 1, 1] // Verdi's enigmatic scale
        }
    }
}

/// Time signatures for musical patterns
enum TimeSignature: String, CaseIterable, Codable {
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case sixEight = "6/8"
    case custom = "Custom"
    
    var beatsPerMeasure: Int {
        switch self {
        case .twoFour: return 2
        case .threeFour: return 3
        case .fourFour: return 4
        case .sixEight: return 6
        case .custom: return 4
        }
    }
    
    var beatValue: Double {
        switch self {
        case .twoFour, .threeFour, .fourFour: return 1.0
        case .sixEight: return 1.5
        case .custom: return 1.0
        }
    }
    
    static var common: TimeSignature { .fourFour }
}

/// Interval patterns for melodic generation
enum IntervalPattern: String, CaseIterable, Codable {
    case ascending = "Ascending"
    case descending = "Descending"
    case alternating = "Alternating"
    case mirror = "Mirror"
    case retrograde = "Retrograde"
}

/// Directional patterns for melodic contours
enum Direction: String, CaseIterable, Codable {
    case ascending = "Ascending"
    case descending = "Descending"
    case alternating = "Alternating"
}

/// Duration patterns for rhythmic variation
enum DurationPattern: String, CaseIterable, Codable {
    case uniform = "Uniform"
    case alternating = "Alternating"
    case progressive = "Progressive"
    case random = "Random"
}

/// Rhythmic accompaniment styles
enum RhythmicAccompanimentStyle: String, CaseIterable, Codable {
    case basic = "Basic"
    case jazz = "Jazz"
    case latin = "Latin"
    case electronic = "Electronic"
    case orchestral = "Orchestral"
}

/// Harmonic modes for tonal context
enum HarmonicMode: String, CaseIterable, Codable {
    case modal = "Modal"
    case tonal = "Tonal"
    case atonal = "Atonal"
    case polymodal = "Polymodal"
}

/// Contour patterns for melodic shapes
enum ContourPattern: String, CaseIterable, Codable {
    case linear = "Linear"
    case arch = "Arch"
    case invertedArch = "Inverted Arch"
    case wave = "Wave"
    case random = "Random"
    case mirror = "Mirror"
}

// MARK: - Default Parameters

extension PatternParameters {
    /// Default parameters
    static let `default` = PatternParameters(
        rootNote: 60,
        scaleType: .chromatic,
        numberOfOctaves: 1,
        divisionsOfOctave: 12,
        tempo: 120.0,
        timeSignature: .common,
        iterations: 1,
        randomiseOrder: false,
        primaryInterval: 1,
        secondaryInterval: 1,
        intervalPattern: .ascending,
        intervalInversion: false,
        symmetricalIntervals: false,
        interpolation: .default,
        infrapolation: .default,
        ultrapolation: .default,
        mirror: true,
        primaryDirection: .ascending,
        mirrorPoints: 0,
        retrogradeSections: false,
        registerShifts: .none,
        contourPattern: .linear,
        noteDurationPattern: .uniform,
        baseNoteDuration: 0.25,
        rhythmicDensity: 1.0,
        syncopationLevel: 0.0,
        metricModulation: .default,
        harmonicMode: .tonal,
        chordGeneration: .default,
        harmonicRhythm: .default,
        velocitySettings: .default,
        toneShifting: .default
    )
} 