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
        didSet { 
            // Auto-correct invalid divisions when octaves change
            if scaleType == .none {
                let correctedDivisions = getNearestValidDivisions(divisionsOfOctave, for: numberOfOctaves)
                if correctedDivisions != divisionsOfOctave {
                    divisionsOfOctave = correctedDivisions
                    return // Don't call validateAndNotify() again
                }
            }
            validateAndNotify() 
        }
    }
    @Published var divisionsOfOctave: Int = 12 {
        didSet { 
            // Auto-correct invalid divisions for Scale Type "None"
            if scaleType == .none {
                let correctedDivisions = getNearestValidDivisions(divisionsOfOctave, for: numberOfOctaves)
                if correctedDivisions != divisionsOfOctave {
                    divisionsOfOctave = correctedDivisions
                    return // Don't call validateAndNotify() again
                }
            }
            validateAndNotify() 
        }
    }
    @Published var tempo: Double = 120.0 {
        didSet { validateAndNotify() }
    }
    @Published var timeSignature: TimeSignature = .common {
        didSet { validateAndNotify() }
    }
    @Published var iterations: Int = 1 {
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
    @Published var mirror: Bool = true {
        didSet { validateAndNotify() }
    }
    // Legacy parameters - kept for backward compatibility
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
    
    /// Base note duration as an enum for UI selection (computed property)
    var baseNoteDurationEnum: BaseNoteDuration {
        get {
            return BaseNoteDuration.from(beatValue: baseNoteDuration)
        }
        set {
            baseNoteDuration = newValue.beatValue
        }
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
    
    // Cyclical Parameters
    @Published var cyclicalSettings: CyclicalSettings = CyclicalSettings() {
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
    
    // Auto-generation Settings
    @Published var autoGenerateEnabled = false {
        didSet { 
            if autoGenerateEnabled {
                setupAutoGeneration()
            } else {
                stopAutoGeneration()
            }
        }
    }
    @Published var autoGenerationDelay: TimeInterval = 1.0 // seconds
    @Published var selectedGeneratorForAutoGeneration = "Scale Pattern Generator"
    
    // Automatic Generator Selection
    @Published var automaticGeneratorSelectionEnabled = true
    @Published var activeGenerators: [String] = ["Scale Pattern Generator"]
    @Published var combinationMode: PatternCombinationMode = .sequential
    
    // Rhythmic Accompaniment Settings
    @Published var rhythmicAccompanimentEnabled = false {
        didSet { validateAndNotify() }
    }
    @Published var rhythmicAccompanimentDensity: Double = 1.0 {
        didSet { validateAndNotify() }
    }
    @Published var rhythmicAccompanimentStyle: RhythmicAccompanimentStyle = .basic {
        didSet { validateAndNotify() }
    }
    @Published var rhythmicAccompanimentVelocity: Double = 0.7 {
        didSet { validateAndNotify() }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let validationSubject = PassthroughSubject<Void, Never>()
    private let autoGenerationSubject = PassthroughSubject<Void, Never>()
    private var autoGenerationCancellables = Set<AnyCancellable>()
    private var lastParameterHash: Int = 0
    
    // MARK: - Initialization
    init() {
        print("🎵 ParameterManager: Initializing with default parameters")
        setupBindings()
        loadDefaultPreset()
        
        // Initialize automatic generator selection
        updateGeneratorSelection()
        print("🎵 ParameterManager: Initialization complete")
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
            iterations: iterations,
            primaryInterval: primaryInterval,
            secondaryInterval: secondaryInterval,
            intervalPattern: intervalPattern,
            intervalInversion: intervalInversion,
            symmetricalIntervals: symmetricalIntervals,
            interpolation: interpolation,
            infrapolation: infrapolation,
            ultrapolation: ultrapolation,
            mirror: mirror,
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
            toneShifting: toneShifting,
            cyclicalSettings: cyclicalSettings
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
        iterations = parameters.iterations
        primaryInterval = parameters.primaryInterval
        secondaryInterval = parameters.secondaryInterval
        intervalPattern = parameters.intervalPattern
        intervalInversion = parameters.intervalInversion
        symmetricalIntervals = parameters.symmetricalIntervals
        interpolation = parameters.interpolation
        infrapolation = parameters.infrapolation
        ultrapolation = parameters.ultrapolation
        mirror = parameters.mirror
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
        cyclicalSettings = parameters.cyclicalSettings
        
        // Reset parameter hash to force regeneration
        lastParameterHash = 0
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
                    case .accompaniment:
            randomizeRhythmicAccompanimentParameters()
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
        
        // Validate divisions for Scale Type "None" (equal divisions)
        if scaleType == .none {
            let totalSemitones = 12 * numberOfOctaves
            if totalSemitones % divisionsOfOctave != 0 {
                let validDivisors = getValidDivisors(totalSemitones)
                errors.append("Divisions (\(divisionsOfOctave)) is not a valid divisor of \(totalSemitones) semitones. Valid divisors: \(validDivisors.joined(separator: ", "))")
            }
        }
        
        if tempo < 20 || tempo > 300 {
            errors.append("Tempo must be between 20 and 300 BPM")
        }
        
        if iterations < 1 || iterations > 10 {
            errors.append("Iterations must be between 1 and 10")
        }
        
        if baseNoteDuration < 0.0625 || baseNoteDuration > 4.0 {
            errors.append("Base note duration must be between 0.0625 and 4.0")
        }
        
        return errors
    }
    
    /// Get valid divisors for a given number
    private func getValidDivisors(_ number: Int) -> [String] {
        var divisors: [Int] = []
        for i in 1...number {
            if number % i == 0 {
                divisors.append(i)
            }
        }
        return divisors.map { String($0) }
    }
    
    /// Get the nearest valid divisor for the given divisions and octaves
    private func getNearestValidDivisions(_ divisions: Int, for octaves: Int) -> Int {
        let totalSemitones = 12 * octaves
        let validDivisors = getValidDivisorsAsInts(totalSemitones)
        
        // If the current divisions is valid, keep it
        if validDivisors.contains(divisions) {
            return divisions
        }
        
        // Find the nearest valid divisor
        var nearest = validDivisors[0]
        var minDistance = abs(divisions - nearest)
        
        for divisor in validDivisors {
            let distance = abs(divisions - divisor)
            if distance < minDistance {
                minDistance = distance
                nearest = divisor
            }
        }
        
        return nearest
    }
    
    /// Get valid divisors as integers
    private func getValidDivisorsAsInts(_ number: Int) -> [Int] {
        var divisors: [Int] = []
        for i in 1...number {
            if number % i == 0 {
                divisors.append(i)
            }
        }
        return divisors
    }
    
    /// Get parameter change publisher
    var parameterChangePublisher: AnyPublisher<Void, Never> {
        return validationSubject.eraseToAnyPublisher()
    }
    
    /// Get auto-generation trigger publisher
    var autoGenerationPublisher: AnyPublisher<Void, Never> {
        return autoGenerationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Auto-generation Methods
    
    private func setupAutoGeneration() {
        // Cancel any existing auto-generation subscriptions
        autoGenerationCancellables.removeAll()
        
        // Set up debounced auto-generation
        autoGenerationSubject
            .debounce(for: .seconds(autoGenerationDelay), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.performAutoGeneration()
            }
            .store(in: &autoGenerationCancellables)
        
        print("🔄 Auto-generation enabled with \(autoGenerationDelay)s delay")
    }
    
    private func stopAutoGeneration() {
        // Cancel auto-generation subscriptions
        autoGenerationCancellables.removeAll()
        
        print("🔄 Auto-generation disabled")
    }
    
    private func performAutoGeneration() {
        guard autoGenerateEnabled else { return }
        
        print("🔄 Performing auto-generation with \(activeGenerators.count) generators")
        
        // Validate parameters before generation
        let errors = validateParameters()
        if !errors.isEmpty {
            print("❌ Auto-generation skipped due to validation errors: \(errors)")
            return
        }
        
        // Notify that auto-generation should be performed
        // This will be handled by the MIDIIntegrationService
        print("🔄 Auto-generation parameters validated, ready for generation")
    }
    
    // MARK: - Automatic Generator Selection Methods
    
    /// Determine which generators should be active based on current parameter usage
    func determineActiveGenerators() -> [String] {
        print("🎵 ParameterManager: Determining active generators")
        print("   Automatic selection enabled: \(automaticGeneratorSelectionEnabled)")
        
        guard automaticGeneratorSelectionEnabled else {
            print("   Using manual selection: \(selectedGeneratorForAutoGeneration)")
            return [selectedGeneratorForAutoGeneration]
        }
        
        var generators: Set<String> = []
        
        // Always include Scale Pattern Generator for basic parameters
        generators.insert("Scale Pattern Generator")
        print("   Added Scale Pattern Generator (always active)")
        
        // Check interval parameters
        if primaryInterval != 1 || secondaryInterval != 1 || 
           intervalPattern != .ascending || intervalInversion || symmetricalIntervals {
            generators.insert("Interval Pattern Generator")
            print("   Added Interval Pattern Generator (interval parameters active)")
        }
        
        // Check modulation parameters - only add if enabled AND has notes to generate
        // But don't add if ScalePatternGenerator is already active (it handles modulations internally)
        if !generators.contains("Scale Pattern Generator") && 
           ((interpolation.enabled && interpolation.numberOfNotes > 0) || 
            (infrapolation.enabled && infrapolation.numberOfNotes > 0) || 
            (ultrapolation.enabled && ultrapolation.numberOfNotes > 0)) {
            generators.insert("Modulation Pattern Generator")
            print("   Added Modulation Pattern Generator (modulation parameters active)")
        } else if generators.contains("Scale Pattern Generator") {
            print("   Skipped Modulation Pattern Generator (ScalePatternGenerator handles modulations internally)")
        }
        
        // Check directional parameters - only add Contour Pattern Generator for complex directional patterns
        // that ScalePatternGenerator doesn't handle well internally
        if (mirrorPoints > 0 || retrogradeSections || registerShifts != .none || contourPattern != .linear) {
            generators.insert("Contour Pattern Generator")
            print("   Added Contour Pattern Generator (complex directional parameters active)")
        } else if primaryDirection != .ascending {
            // For simple directional changes (ascending/descending/alternating), 
            // ScalePatternGenerator handles these internally, so don't add Contour Pattern Generator
            print("   Skipped Contour Pattern Generator (ScalePatternGenerator handles simple directional patterns internally)")
        }
        
        // Check rhythmic parameters
        if noteDurationPattern != .uniform || rhythmicDensity != 1.0 || 
           syncopationLevel > 0 || metricModulation.enabled {
            generators.insert("Rhythmic Pattern Generator")
            print("   Added Rhythmic Pattern Generator (rhythmic parameters active)")
        }
        
        // Check harmonic parameters
        if harmonicMode != .tonal || chordGeneration.enabled || 
           harmonicRhythm.chordChangeFrequency != 4 {
            generators.insert("Harmonic Pattern Generator")
            print("   Added Harmonic Pattern Generator (harmonic parameters active)")
        }
        
        // Check symmetrical parameters
        if symmetricalIntervals || mirrorPoints > 0 {
            generators.insert("Symmetrical Pattern Generator")
            print("   Added Symmetrical Pattern Generator (symmetrical parameters active)")
        }
        
        let result = Array(generators).sorted()
        print("   Final active generators: \(result)")
        return result
    }
    
    /// Update active generators based on current parameter usage
    func updateActiveGenerators() {
        let newActiveGenerators = determineActiveGenerators()
        if newActiveGenerators != activeGenerators {
            // Only update if the change is significant (not just reordering)
            let oldSet = Set(activeGenerators)
            let newSet = Set(newActiveGenerators)
            
            if oldSet != newSet {
                activeGenerators = newActiveGenerators
                print("🔄 Auto-selected generators: \(activeGenerators.joined(separator: ", "))")
            }
        }
    }
    
    /// Determine the best combination mode based on active generators
    func determineCombinationMode() -> PatternCombinationMode {
        print("🎵 ParameterManager: Determining combination mode")
        print("   Active generators count: \(activeGenerators.count)")
        print("   Active generators: \(activeGenerators)")
        
        guard activeGenerators.count > 1 else { 
            print("   Using sequential mode (single generator)")
            return .sequential 
        }
        
        // Use layered mode if harmonic generator is active with others
        if activeGenerators.contains("Harmonic Pattern Generator") && activeGenerators.count > 1 {
            print("   Using layered mode (harmonic generator active)")
            return .layered
        }
        
        // Use layered mode for modulation + melodic combinations (modulations apply to existing notes)
        if activeGenerators.contains("Modulation Pattern Generator") && 
           (activeGenerators.contains("Scale Pattern Generator") || activeGenerators.contains("Interval Pattern Generator")) {
            print("   Using layered mode (modulation + melodic combination)")
            return .layered
        }
        
        // Use interleaved mode for rhythmic + melodic combinations
        if activeGenerators.contains("Rhythmic Pattern Generator") && 
           (activeGenerators.contains("Scale Pattern Generator") || activeGenerators.contains("Interval Pattern Generator")) {
            print("   Using interleaved mode (rhythmic + melodic combination)")
            return .interleaved
        }
        
        // Default to sequential for other combinations
        print("   Using sequential mode (default for other combinations)")
        return .sequential
    }
    
    /// Update combination mode based on active generators
    func updateCombinationMode() {
        let newMode = determineCombinationMode()
        if newMode != combinationMode {
            combinationMode = newMode
            print("🔄 Auto-selected combination mode: \(combinationMode.rawValue)")
        }
    }
    
    /// Complete update of generator selection based on current parameters
    func updateGeneratorSelection() {
        updateActiveGenerators()
        updateCombinationMode()
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
        
        // Check if parameters have actually changed significantly
        let currentHash = currentParameters.hashValue
        let parametersChanged = currentHash != lastParameterHash
        lastParameterHash = currentHash
        
        // Only update generator selection if automatic selection is enabled
        // and parameters have changed significantly
        if automaticGeneratorSelectionEnabled && parametersChanged {
            updateGeneratorSelection()
        }
        
        // Trigger auto-generation if enabled and parameters changed (will be debounced)
        if autoGenerateEnabled && parametersChanged {
            autoGenerationSubject.send()
        }
    }
    
    func loadDefaultPreset() {
        print("🎵 ParameterManager: Loading default preset")
        // Load a sensible default preset
        let defaultPreset = SlonimskyPreset(
            name: "Default",
            description: "Basic chromatic scale pattern",
            generatorName: "Scale Pattern Generator",
            parameters: PatternParameters.default
        )
        
        print("🎵 Default Parameters:")
        print("   Root Note: \(PatternParameters.default.rootNote)")
        print("   Scale Type: \(PatternParameters.default.scaleType.rawValue)")
        print("   Number of Octaves: \(PatternParameters.default.numberOfOctaves)")
        print("   Divisions of Octave: \(PatternParameters.default.divisionsOfOctave)")
        print("   Tempo: \(PatternParameters.default.tempo)")
        print("   Time Signature: \(PatternParameters.default.timeSignature.rawValue)")
        print("   Primary Direction: \(PatternParameters.default.primaryDirection.rawValue)")
        print("   Interval Pattern: \(PatternParameters.default.intervalPattern.rawValue)")
        print("   Harmonic Mode: \(PatternParameters.default.harmonicMode.rawValue)")
        print("   Chord Generation Enabled: \(PatternParameters.default.chordGeneration.enabled)")
        print("   Chord Size: \(PatternParameters.default.chordGeneration.chordSize)")
        print("   Harmonic Rhythm Chord Change Frequency: \(PatternParameters.default.harmonicRhythm.chordChangeFrequency)")
        print("   Interpolation Enabled: \(PatternParameters.default.interpolation.enabled)")
        print("   Infrapolation Enabled: \(PatternParameters.default.infrapolation.enabled)")
        print("   Ultrapolation Enabled: \(PatternParameters.default.ultrapolation.enabled)")
        print("   Metric Modulation Enabled: \(PatternParameters.default.metricModulation.enabled)")
        
        loadPreset(defaultPreset)
        print("🎵 ParameterManager: Default preset loaded")
    }
    
    /// Reset all parameters to their default values
    func resetToDefaults() {
        print("🔄 ParameterManager: Resetting parameters to defaults")
        loadDefaultPreset()
        print("✅ ParameterManager: Parameters reset to defaults")
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
    
    private func randomizeRhythmicAccompanimentParameters() {
        rhythmicAccompanimentEnabled = Bool.random()
        rhythmicAccompanimentStyle = RhythmicAccompanimentStyle.allCases.randomElement() ?? .basic
        rhythmicAccompanimentDensity = Double.random(in: 0.5...1.5)
        rhythmicAccompanimentVelocity = Double.random(in: 0.3...1.0)
    }
}

// MARK: - Supporting Types

/// Parameter categories for selective randomization
/// Note: ParameterCategory enum is now defined in ParameterPanelView.swift 