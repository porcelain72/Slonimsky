//
//  ParameterManager.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation
import Combine

/// Manages all Slonimsky pattern generation parameters
class ParameterManager: ObservableObject {
    
    // MARK: - Published Properties
    
    // Basic Parameters
    @Published var rootNote: Int = 60 {
        didSet { validateAndNotify() }
    }
    @Published var scaleType: ScaleType = .chromatic {
        didSet { validateAndNotify() }
    }
    @Published var numberOfOctaves: Int = 1 {
        didSet { validateAndNotify() }
    }
    @Published var divisionsOfOctave: Int = 12 {
        didSet { validateAndNotify() }
    }
    @Published var tempo: Double = 120.0 {
        didSet { validateAndNotify() }
    }
    @Published var timeSignature: TimeSignature = .common {
        didSet { validateAndNotify() }
    }
    
    // Interval Parameters
    @Published var primaryInterval: Int = 1 {
        didSet { validateAndNotify() }
    }
    @Published var secondaryInterval: Int = 1 {
        didSet { validateAndNotify() }
    }
    @Published var intervalPattern: IntervalPattern = .ascending {
        didSet { validateAndNotify() }
    }
    @Published var intervalInversion: Bool = false {
        didSet { validateAndNotify() }
    }
    @Published var symmetricalIntervals: Bool = false {
        didSet { validateAndNotify() }
    }
    
    // Slonimsky Modulations
    @Published var interpolation: ModulationSettings = .default {
        didSet { validateAndNotify() }
    }
    @Published var infrapolation: ModulationSettings = .default {
        didSet { validateAndNotify() }
    }
    @Published var ultrapolation: ModulationSettings = .default {
        didSet { validateAndNotify() }
    }
    
    // Directional Parameters
    @Published var primaryDirection: Direction = .ascending {
        didSet { validateAndNotify() }
    }
    @Published var mirrorPoints: Int = 0 {
        didSet { validateAndNotify() }
    }
    @Published var retrogradeSections: Bool = false {
        didSet { validateAndNotify() }
    }
    @Published var registerShifts: RegisterShiftPattern = .none {
        didSet { validateAndNotify() }
    }
    @Published var contourPattern: ContourPattern = .linear {
        didSet { validateAndNotify() }
    }
    
    // Rhythmic Parameters
    @Published var noteDurationPattern: DurationPattern = .uniform {
        didSet { validateAndNotify() }
    }
    @Published var baseNoteDuration: Double = 0.25 {
        didSet { validateAndNotify() }
    }
    @Published var rhythmicDensity: Double = 1.0 {
        didSet { validateAndNotify() }
    }
    @Published var syncopationLevel: Double = 0.0 {
        didSet { validateAndNotify() }
    }
    @Published var metricModulation: MetricModulationSettings = .default {
        didSet { validateAndNotify() }
    }
    
    // Harmonic Parameters
    @Published var harmonicMode: HarmonicMode = .tonal {
        didSet { validateAndNotify() }
    }
    @Published var chordGeneration: ChordSettings = .default {
        didSet { validateAndNotify() }
    }
    @Published var harmonicRhythm: HarmonicRhythmSettings = .default {
        didSet { validateAndNotify() }
    }
    
    // Expression Parameters
    @Published var velocitySettings: VelocitySettings = .default {
        didSet { validateAndNotify() }
    }
    @Published var toneShifting: ToneShiftSettings = .default {
        didSet { validateAndNotify() }
    }
    
    // Parameter Selection for Randomization
    @Published var selectedParametersForRandomization: Set<ParameterCategory> = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let validationSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadDefaultPreset()
    }
    
    // MARK: - Public Methods
    
    /// Get current parameters as PatternParameters
    var currentParameters: PatternParameters {
        return PatternParameters(
            rootNote: rootNote,
            scaleType: scaleType,
            numberOfOctaves: numberOfOctaves,
            divisionsOfOctave: divisionsOfOctave,
            tempo: tempo,
            timeSignature: timeSignature,
            primaryInterval: primaryInterval,
            secondaryInterval: secondaryInterval,
            intervalPattern: intervalPattern,
            intervalInversion: intervalInversion,
            symmetricalIntervals: symmetricalIntervals,
            interpolation: interpolation,
            infrapolation: infrapolation,
            ultrapolation: ultrapolation,
            primaryDirection: primaryDirection,
            mirrorPoints: mirrorPoints,
            retrogradeSections: retrogradeSections,
            registerShifts: registerShifts,
            contourPattern: contourPattern,
            noteDurationPattern: noteDurationPattern,
            baseNoteDuration: baseNoteDuration,
            rhythmicDensity: rhythmicDensity,
            syncopationLevel: syncopationLevel,
            metricModulation: metricModulation,
            harmonicMode: harmonicMode,
            chordGeneration: chordGeneration,
            harmonicRhythm: harmonicRhythm,
            velocitySettings: velocitySettings,
            toneShifting: toneShifting
        )
    }
    
    /// Set parameters from PatternParameters
    func setParameters(_ parameters: PatternParameters) {
        rootNote = parameters.rootNote
        scaleType = parameters.scaleType
        numberOfOctaves = parameters.numberOfOctaves
        divisionsOfOctave = parameters.divisionsOfOctave
        tempo = parameters.tempo
        timeSignature = parameters.timeSignature
        primaryInterval = parameters.primaryInterval
        secondaryInterval = parameters.secondaryInterval
        intervalPattern = parameters.intervalPattern
        intervalInversion = parameters.intervalInversion
        symmetricalIntervals = parameters.symmetricalIntervals
        interpolation = parameters.interpolation
        infrapolation = parameters.infrapolation
        ultrapolation = parameters.ultrapolation
        primaryDirection = parameters.primaryDirection
        mirrorPoints = parameters.mirrorPoints
        retrogradeSections = parameters.retrogradeSections
        registerShifts = parameters.registerShifts
        contourPattern = parameters.contourPattern
        noteDurationPattern = parameters.noteDurationPattern
        baseNoteDuration = parameters.baseNoteDuration
        rhythmicDensity = parameters.rhythmicDensity
        syncopationLevel = parameters.syncopationLevel
        metricModulation = parameters.metricModulation
        harmonicMode = parameters.harmonicMode
        chordGeneration = parameters.chordGeneration
        harmonicRhythm = parameters.harmonicRhythm
        velocitySettings = parameters.velocitySettings
        toneShifting = parameters.toneShifting
    }
    
    /// Randomize all parameters
    func randomizeAllParameters() {
        randomizeBasicParameters()
        randomizeIntervalParameters()
        randomizeModulationParameters()
        randomizeDirectionalParameters()
        randomizeRhythmicParameters()
        randomizeHarmonicParameters()
        randomizeExpressionParameters()
    }
    
    /// Randomize selected parameter categories
    func randomizeSelectedParameters() {
        for category in selectedParametersForRandomization {
            switch category {
            case .basic:
                randomizeBasicParameters()
            case .intervals:
                randomizeIntervalParameters()
            case .modulations:
                randomizeModulationParameters()
            case .directional:
                randomizeDirectionalParameters()
            case .rhythmic:
                randomizeRhythmicParameters()
            case .harmonic:
                randomizeHarmonicParameters()
            case .expression:
                randomizeExpressionParameters()
            }
        }
    }
    
    /// Load a preset
    func loadPreset(_ preset: SlonimskyPreset) {
        setParameters(preset.parameters)
    }
    
    /// Save current parameters as a preset
    func saveAsPreset(name: String, description: String) -> SlonimskyPreset {
        return SlonimskyPreset(
            name: name,
            description: description,
            generatorName: "Scale Pattern Generator", // Default
            parameters: currentParameters
        )
    }
    
    /// Validate current parameters
    func validateParameters() -> [String] {
        var errors: [String] = []
        
        if rootNote < 0 || rootNote > 127 {
            errors.append("Root note must be between 0 and 127")
        }
        
        if numberOfOctaves < 1 || numberOfOctaves > 8 {
            errors.append("Number of octaves must be between 1 and 8")
        }
        
        if divisionsOfOctave < 2 || divisionsOfOctave > 24 {
            errors.append("Divisions of octave must be between 2 and 24")
        }
        
        if tempo < 20 || tempo > 300 {
            errors.append("Tempo must be between 20 and 300 BPM")
        }
        
        if baseNoteDuration < 0.0625 || baseNoteDuration > 4.0 {
            errors.append("Base note duration must be between 0.0625 and 4.0")
        }
        
        return errors
    }
    
    /// Get parameter change publisher
    var parameterChangePublisher: AnyPublisher<Void, Never> {
        return validationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Set up parameter change notifications
        validationSubject
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func validateAndNotify() {
        validationSubject.send()
    }
    
    func loadDefaultPreset() {
        // Load a sensible default preset
        let defaultPreset = SlonimskyPreset(
            name: "Default",
            description: "Basic chromatic scale pattern",
            generatorName: "Scale Pattern Generator",
            parameters: PatternParameters.default
        )
        loadPreset(defaultPreset)
    }
    
    private func randomizeBasicParameters() {
        rootNote = Int.random(in: 48...72)
        scaleType = ScaleType.allCases.randomElement() ?? .chromatic
        numberOfOctaves = Int.random(in: 1...3)
        divisionsOfOctave = Int.random(in: 6...12)
        tempo = Double.random(in: 80...160)
        timeSignature = TimeSignature.allCases.randomElement() ?? .common
    }
    
    private func randomizeIntervalParameters() {
        primaryInterval = Int.random(in: 1...7)
        secondaryInterval = Int.random(in: 1...7)
        intervalPattern = IntervalPattern.allCases.randomElement() ?? .ascending
        intervalInversion = Bool.random()
        symmetricalIntervals = Bool.random()
    }
    
    private func randomizeModulationParameters() {
        interpolation = ModulationSettings(
            numberOfNotes: Int.random(in: 0...3),
            interval: Int.random(in: 1...3),
            enabled: Bool.random()
        )
        infrapolation = ModulationSettings(
            numberOfNotes: Int.random(in: 0...2),
            interval: Int.random(in: 1...3),
            enabled: Bool.random()
        )
        ultrapolation = ModulationSettings(
            numberOfNotes: Int.random(in: 0...2),
            interval: Int.random(in: 1...3),
            enabled: Bool.random()
        )
    }
    
    private func randomizeDirectionalParameters() {
        primaryDirection = Direction.allCases.randomElement() ?? .ascending
        mirrorPoints = Int.random(in: 0...3)
        retrogradeSections = Bool.random()
        registerShifts = RegisterShiftPattern.allCases.randomElement() ?? .none
        contourPattern = ContourPattern.allCases.randomElement() ?? .linear
    }
    
    private func randomizeRhythmicParameters() {
        noteDurationPattern = DurationPattern.allCases.randomElement() ?? .uniform
        baseNoteDuration = Double.random(in: 0.125...0.5)
        rhythmicDensity = Double.random(in: 0.5...1.5)
        syncopationLevel = Double.random(in: 0...0.8)
        metricModulation = MetricModulationSettings(
            enabled: Bool.random(),
            modulationType: MetricModulationType.allCases.randomElement() ?? .accelerando,
            intensity: Double.random(in: 0.3...0.8),
            frequency: Int.random(in: 2...8)
        )
    }
    
    private func randomizeHarmonicParameters() {
        harmonicMode = HarmonicMode.allCases.randomElement() ?? .tonal
        chordGeneration = ChordSettings(
            enabled: Bool.random(),
            chordSize: Int.random(in: 2...4),
            voicingPreference: VoicingPreference.allCases.randomElement() ?? .close,
            velocityScale: Double.random(in: 0.6...0.9)
        )
        harmonicRhythm = HarmonicRhythmSettings(
            chordChangeFrequency: Int.random(in: 2...8),
            syncopationLevel: Double.random(in: 0...0.6),
            harmonicTension: Double.random(in: 0.2...0.8)
        )
    }
    
    private func randomizeExpressionParameters() {
        velocitySettings = VelocitySettings(
            baseVelocity: UInt8.random(in: 60...100),
            range: UInt8.random(in: 20...50),
            waveDepth: Double.random(in: 0.3...0.8),
            randomness: Double.random(in: 0.1...0.4),
            phase: Double.random(in: 0...2 * .pi),
            emphasisBeat: Int.random(in: 2...8),
            emphasisAmount: Double.random(in: 0.2...0.6)
        )
        toneShifting = ToneShiftSettings(
            toneIncrement: Int.random(in: 0...12),
            maxToneShift: Int.random(in: 0...24),
            shiftPattern: RegisterShiftPattern.allCases.randomElement() ?? .none
        )
    }
}

// MARK: - Supporting Types

/// Parameter categories for selective randomization
enum ParameterCategory: String, CaseIterable, Identifiable {
    case basic = "Basic"
    case intervals = "Intervals"
    case modulations = "Modulations"
    case directional = "Directional"
    case rhythmic = "Rhythmic"
    case harmonic = "Harmonic"
    case expression = "Expression"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .basic:
            return "Root note, scale type, octaves, tempo"
        case .intervals:
            return "Primary/secondary intervals, patterns, inversions"
        case .modulations:
            return "Interpolation, infrapolation, ultrapolation"
        case .directional:
            return "Direction, mirror points, retrograde, contours"
        case .rhythmic:
            return "Duration patterns, density, syncopation"
        case .harmonic:
            return "Harmonic mode, chord generation, rhythm"
        case .expression:
            return "Velocity, tone shifting, expression"
        }
    }
} 