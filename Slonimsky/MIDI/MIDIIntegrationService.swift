//
//  MIDIIntegrationService.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation
import Combine

/// Service that integrates pattern generators with MIDI output
class MIDIIntegrationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentPattern: PatternGenerationResult?
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var lastGenerationTime: TimeInterval = 0.0
    @Published var errorMessage: String?
    @Published var isLooping = false
    @Published var autosaveEnabled = false
    
    // MARK: - Computed Properties
    var isPlaying: Bool {
        return midiEngine.isPlaying
    }
    
    // MARK: - Private Properties
    private let midiEngine = MIDIEngine()
    private let patternRegistry = PatternGeneratorRegistry.shared
    private let cyclicalSequenceGenerator = CyclicalSequenceGenerator()
    private var cancellables = Set<AnyCancellable>()
    private var parameterManager: ParameterManager?
    private var lastGeneratedPatternHash: Int = 0
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Set up auto-generation with parameter manager
    /// - Parameter parameterManager: The parameter manager to monitor for changes
    func setupAutoGeneration(with parameterManager: ParameterManager) {
        self.parameterManager = parameterManager
        
        // Set parameter manager in MIDI engine for rhythmic accompaniment
        midiEngine.setParameterManager(parameterManager)
        
        // Subscribe to auto-generation triggers
        parameterManager.autoGenerationPublisher
            .sink { [weak self] in
                self?.handleAutoGeneration()
            }
            .store(in: &cancellables)
        
        print("🔄 Auto-generation setup complete")
    }
    
    /// Reset auto-generation state
    func resetAutoGeneration() {
        print("🔄 Resetting auto-generation state")
        errorMessage = nil
        isGenerating = false
        generationProgress = 0.0
        lastGeneratedPatternHash = 0
        
        // Force a new generation if auto-generation is enabled
        if let parameterManager = parameterManager, parameterManager.autoGenerateEnabled {
            print("🔄 Forcing auto-generation after reset")
            handleAutoGeneration()
        }
    }
    
    /// Reset pattern cache to force regeneration
    func resetPatternCache() {
        lastGeneratedPatternHash = 0
        print("🔄 Pattern cache reset")
    }
    
    /// Handle auto-generation when parameters change
    private func handleAutoGeneration() {
        guard let parameterManager = parameterManager else { 
            print("❌ Auto-generation failed: no parameter manager")
            return 
        }
        
        let parameters = parameterManager.currentParameters
        let currentHash = parameters.hashValue
        
        // Check if we've already generated this exact pattern
        if currentHash == lastGeneratedPatternHash && currentPattern != nil {
            print("🔄 Pattern already generated for these parameters, skipping regeneration")
            return
        }
        
        print("🔄 Starting auto-generation...")
        
        // Validate parameters before generation
        let errors = parameterManager.validateParameters()
        if !errors.isEmpty {
            print("❌ Auto-generation failed: parameter validation errors: \(errors)")
            errorMessage = "Parameter validation failed: \(errors.joined(separator: ", "))"
            return
        }
        
        // Check if cyclical parameters are enabled
        let enabledCyclicalParameters = parameters.cyclicalSettings.enabledParameters
        let hasCyclicalParameters = parameters.isCyclicalGeneration
        
        if hasCyclicalParameters {
            print("🔄 Cyclical parameters detected: \(enabledCyclicalParameters.keys.map { $0.rawValue }.joined(separator: ", "))")
            
            // Use automatic generator selection if enabled
            if parameterManager.automaticGeneratorSelectionEnabled && parameterManager.activeGenerators.count > 1 {
                print("🔄 Using combined cyclical generation with \(parameterManager.activeGenerators.count) generators")
                
                // Use combined cyclical generation
                guard let result = cyclicalSequenceGenerator.generateCombinedCyclicalSequence(
                    baseParameters: parameters,
                    generatorNames: parameterManager.activeGenerators,
                    combinationMode: parameterManager.combinationMode
                ) else {
                    print("❌ Auto-generation failed: combined cyclical pattern generation failed")
                    errorMessage = "Combined cyclical pattern generation failed"
                    return
                }
                
                // Update the MIDI sequence seamlessly
                if midiEngine.updateSequence(with: result, parameters: parameters) {
                    self.currentPattern = result
                    self.lastGeneratedPatternHash = currentHash
                    self.errorMessage = nil
                    print("✅ Auto-generated combined cyclical sequence with \(parameterManager.activeGenerators.count) generators")
                    
                    // Autosave if enabled
                    self.autosaveCurrentPattern()
                } else {
                    print("❌ Auto-generation failed: sequence update failed")
                    errorMessage = "MIDI sequence update failed"
                }
            } else {
                // Use single generator (either manual selection or automatic single generator)
                let generatorName = parameterManager.automaticGeneratorSelectionEnabled ? 
                    parameterManager.activeGenerators.first ?? parameterManager.selectedGeneratorForAutoGeneration :
                    parameterManager.selectedGeneratorForAutoGeneration
                
                print("🔄 Using single generator with cyclical generation: \(generatorName)")
                
                guard let result = cyclicalSequenceGenerator.generateCyclicalSequence(
                    baseParameters: parameters,
                    generatorName: generatorName
                ) else {
                    print("❌ Auto-generation failed: cyclical pattern generation failed for \(generatorName)")
                    errorMessage = "Cyclical pattern generation failed for \(generatorName)"
                    return
                }
                
                // Update the MIDI sequence seamlessly
                if midiEngine.updateSequence(with: result, parameters: parameters) {
                    self.currentPattern = result
                    self.lastGeneratedPatternHash = currentHash
                    self.errorMessage = nil
                    print("✅ Auto-generated cyclical sequence with \(generatorName)")
                    
                    // Autosave if enabled
                    self.autosaveCurrentPattern()
                } else {
                    print("❌ Auto-generation failed: sequence update failed")
                    errorMessage = "MIDI sequence update failed"
                }
            }
        } else {
            // No cyclical parameters, use standard generation
            // Use automatic generator selection if enabled
            if parameterManager.automaticGeneratorSelectionEnabled && parameterManager.activeGenerators.count > 1 {
                print("🔄 Using combined generation with \(parameterManager.activeGenerators.count) generators")
                
                // Use combined generation
                guard let result = patternRegistry.generateCombinedPattern(
                    using: parameterManager.activeGenerators,
                    parameters: parameters,
                    combinationMode: parameterManager.combinationMode
                ) else {
                    print("❌ Auto-generation failed: combined pattern generation failed")
                    errorMessage = "Combined pattern generation failed"
                    return
                }
                
                // Update the MIDI sequence seamlessly
                if midiEngine.updateSequence(with: result, parameters: parameters) {
                    self.currentPattern = result
                    self.lastGeneratedPatternHash = currentHash
                    self.errorMessage = nil
                    print("✅ Auto-generated combined sequence with \(parameterManager.activeGenerators.count) generators")
                    
                    // Autosave if enabled
                    self.autosaveCurrentPattern()
                } else {
                    print("❌ Auto-generation failed: sequence update failed")
                    errorMessage = "MIDI sequence update failed"
                }
            } else {
                // Use single generator (either manual selection or automatic single generator)
                let generatorName = parameterManager.automaticGeneratorSelectionEnabled ? 
                    parameterManager.activeGenerators.first ?? parameterManager.selectedGeneratorForAutoGeneration :
                    parameterManager.selectedGeneratorForAutoGeneration
                
                print("🔄 Using single generator: \(generatorName)")
                
                guard let result = patternRegistry.generatePattern(
                    using: generatorName,
                    parameters: parameters
                ) else {
                    print("❌ Auto-generation failed: pattern generation failed for \(generatorName)")
                    errorMessage = "Pattern generation failed for \(generatorName)"
                    return
                }
                
                // Update the MIDI sequence seamlessly
                if midiEngine.updateSequence(with: result, parameters: parameters) {
                    self.currentPattern = result
                    self.lastGeneratedPatternHash = currentHash
                    self.errorMessage = nil
                    print("✅ Auto-generated sequence with \(generatorName)")
                    
                    // Autosave if enabled
                    self.autosaveCurrentPattern()
                } else {
                    print("❌ Auto-generation failed: sequence update failed")
                    errorMessage = "MIDI sequence update failed"
                }
            }
        }
    }
    
    /// Generate a pattern and create MIDI sequence
    /// - Parameters:
    ///   - generatorName: Name of the pattern generator to use
    ///   - parameters: Pattern generation parameters
    ///   - completion: Completion handler with result
    func generatePatternAndMIDI(
        using generatorName: String,
        parameters: PatternParameters,
        completion: @escaping (Result<PatternGenerationResult, Error>) -> Void
    ) {
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Generate pattern
            guard let result = self.patternRegistry.generatePattern(
                using: generatorName,
                parameters: parameters
            ) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to generate pattern"
                    completion(.failure(MIDIIntegrationError.patternGenerationFailed))
                }
                return
            }
            
            // Create MIDI sequence
            guard let _ = self.midiEngine.generateMusicSequence(from: result, parameters: parameters) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to create MIDI sequence"
                    completion(.failure(MIDIIntegrationError.midiSequenceCreationFailed))
                }
                return
            }
            
            let generationTime = CFAbsoluteTimeGetCurrent() - startTime
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.generationProgress = 1.0
                self.lastGenerationTime = generationTime
                self.currentPattern = result
                
                // Autosave if enabled
                self.autosaveCurrentPattern()
                
                completion(.success(result))
            }
        }
    }
    
    /// Generate a combined pattern using multiple generators
    /// - Parameters:
    ///   - generatorNames: Array of generator names to use
    ///   - parameters: Pattern generation parameters
    ///   - combinationMode: How to combine the patterns
    ///   - completion: Completion handler with result
    func generateCombinedPatternAndMIDI(
        using generatorNames: [String],
        parameters: PatternParameters,
        combinationMode: PatternCombinationMode = .sequential,
        completion: @escaping (Result<PatternGenerationResult, Error>) -> Void
    ) {
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Generate combined pattern
            guard let result = self.patternRegistry.generateCombinedPattern(
                using: generatorNames,
                parameters: parameters,
                combinationMode: combinationMode
            ) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to generate combined pattern"
                    completion(.failure(MIDIIntegrationError.patternGenerationFailed))
                }
                return
            }
            
            // Create MIDI sequence
            guard let _ = self.midiEngine.generateMusicSequence(from: result, parameters: parameters) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to create MIDI sequence"
                    completion(.failure(MIDIIntegrationError.midiSequenceCreationFailed))
                }
                return
            }
            
            let generationTime = CFAbsoluteTimeGetCurrent() - startTime
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.generationProgress = 1.0
                self.lastGenerationTime = generationTime
                self.currentPattern = result
                
                // Autosave if enabled
                self.autosaveCurrentPattern()
                
                completion(.success(result))
            }
        }
    }
    
    /// Play the current pattern
    func playCurrentPattern() {
        guard currentPattern != nil else {
            errorMessage = "No pattern available to play"
            return
        }
        
        midiEngine.play()
    }
    
    /// Stop playback
    func stopPlayback() {
        midiEngine.stop()
    }
    
    /// Stop external MIDI playback thread
    func stopExternalMIDI() {
        midiEngine.stopExternalMIDI()
    }
    
    /// Pause playback
    func pausePlayback() {
        midiEngine.pause()
    }
    
    /// Resume playback
    func resumePlayback() {
        midiEngine.resume()
    }
    
    /// Toggle looping behavior
    func toggleLooping() {
        isLooping.toggle()
        midiEngine.setLooping(isLooping)
    }
    
    /// Export current pattern to MIDI file
    /// - Parameter url: URL to save the MIDI file
    /// - Returns: True if successful
    func exportToMIDI(url: URL) -> Bool {
        guard currentPattern != nil else {
            errorMessage = "No pattern available to export"
            return false
        }
        
        let success = midiEngine.exportToMIDI(url: url)
        if !success {
            errorMessage = "Failed to export MIDI file"
        }
        return success
    }
    
    /// Current tempo from the parameter manager, or 120 BPM as fallback
    var currentTempo: Double {
        return parameterManager?.tempo ?? 120.0
    }
    
    /// Send current pattern to external MIDI destination
    /// - Parameter bpm: Tempo in beats per minute (defaults to current parameter tempo)
    func sendToExternalMIDI(bpm: Double? = nil) {
        guard let pattern = currentPattern else {
            errorMessage = "No pattern available to send"
            return
        }
        
        let tempo = bpm ?? currentTempo
        midiEngine.sendToExternalMIDI(notes: pattern.notes, bpm: tempo)
    }
    
    /// Get available pattern generators
    /// - Returns: Array of generator information
    func getAvailableGenerators() -> [GeneratorInfo] {
        return patternRegistry.getGeneratorInfo()
    }
    
    /// Get available MIDI destinations
    /// - Returns: Array of MIDI destinations
    func getAvailableDestinations() -> [MIDIDestination] {
        return midiEngine.availableDestinations
    }
    
    /// Set selected MIDI destination
    /// - Parameter destination: The destination to select
    func setSelectedDestination(_ destination: MIDIDestination) {
        midiEngine.selectedDestination = destination
    }
    
    /// Toggle autosave functionality
    func toggleAutosave() {
        autosaveEnabled.toggle()
        print("💾 Autosave \(autosaveEnabled ? "enabled" : "disabled")")
    }
    
    /// Autosave current pattern if autosave is enabled
    private func autosaveCurrentPattern() {
        guard autosaveEnabled, let pattern = currentPattern else { return }
        
        // Create autosave directory if it doesn't exist
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let slonimskyPath = documentsPath.appendingPathComponent("Slonimsky")
        let sequencesPath = slonimskyPath.appendingPathComponent("Sequences")
        
        do {
            try FileManager.default.createDirectory(at: sequencesPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("❌ Failed to create autosave directory: \(error)")
            return
        }
        
        // Generate descriptive filename
        let filename = generateAutosaveFilename(for: pattern)
        let fileURL = sequencesPath.appendingPathComponent(filename)
        
        // Save the MIDI file
        let success = midiEngine.exportToMIDI(url: fileURL)
        if success {
            print("💾 Autosaved sequence: \(filename)")
        } else {
            print("❌ Failed to autosave sequence: \(filename)")
        }
    }
    
    /// Generate a descriptive filename for autosave
    private func generateAutosaveFilename(for pattern: PatternGenerationResult) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let generatorName = pattern.metadata.generatorName.replacingOccurrences(of: " ", with: "")
        let noteCount = pattern.metadata.noteCount
        let pitchRange = pattern.metadata.pitchRange
        let isCyclical = pattern.metadata.isCyclicalSequence
        
        // Create a descriptive suffix based on available metadata
        var suffix = "\(noteCount)notes"
        if isCyclical {
            suffix += "_cycle\(pattern.metadata.cycleIndex)"
        }
        if pitchRange.lowerBound != pitchRange.upperBound {
            suffix += "_range\(pitchRange.lowerBound)-\(pitchRange.upperBound)"
        }
        
        return "\(generatorName)_\(suffix)_\(timestamp).mid"
    }
    
    /// Get playback status
    /// - Returns: Current playback status
    func getPlaybackStatus() -> PlaybackStatus {
        return PlaybackStatus(
            isPlaying: midiEngine.isPlaying,
            currentTime: midiEngine.currentTime,
            totalDuration: midiEngine.totalDuration
        )
    }
    
    /// Generate a random pattern using random parameters
    /// - Parameter completion: Completion handler with result
    func generateRandomPattern(completion: @escaping (Result<PatternGenerationResult, Error>) -> Void) {
        let randomParameters = generateRandomParameters()
        let generators = patternRegistry.getAllGeneratorNames()
        
        guard let randomGenerator = generators.randomElement() else {
            completion(.failure(MIDIIntegrationError.noGeneratorsAvailable))
            return
        }
        
        generatePatternAndMIDI(using: randomGenerator, parameters: randomParameters, completion: completion)
    }
    
    /// Generate a preset pattern
    /// - Parameters:
    ///   - preset: The preset to use
    ///   - completion: Completion handler with result
    func generatePresetPattern(
        preset: SlonimskyPreset,
        completion: @escaping (Result<PatternGenerationResult, Error>) -> Void
    ) {
        let parameters = preset.parameters
        let generatorName = preset.generatorName
        
        // Presets that use cyclical curves or a pattern process must run the
        // multi-cycle pipeline, not the single-pattern path.
        if parameters.isCyclicalGeneration {
            generateCyclicalPatternAndMIDI(using: generatorName, parameters: parameters, completion: completion)
        } else {
            generatePatternAndMIDI(using: generatorName, parameters: parameters, completion: completion)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind MIDI engine properties to this service
        midiEngine.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        midiEngine.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func generateRandomParameters() -> PatternParameters {
        let scaleTypes: [ScaleType] = [.chromatic, .diatonic, .pentatonic, .wholeTone, .octatonic]
        let intervalPatterns: [IntervalPattern] = [.ascending, .descending, .alternating, .mirror, .retrograde]
        let contourPatterns: [ContourPattern] = [.linear, .arch, .invertedArch, .wave, .random]
        
        return PatternParameters(
            rootNote: Int.random(in: 48...72),
            scaleType: scaleTypes.randomElement() ?? .chromatic,
            numberOfOctaves: Int.random(in: 1...3),
            divisionsOfOctave: Int.random(in: 6...12),
            tempo: Double.random(in: 80...160),
            meter: Meter.presets.randomElement() ?? .fourFour,
            iterations: Int.random(in: 1...3),
            randomiseOrder: Bool.random(),
            primaryInterval: Int.random(in: 1...7),
            secondaryInterval: Int.random(in: 1...7),
            intervalPattern: intervalPatterns.randomElement() ?? .ascending,
            intervalInversion: Bool.random(),
            symmetricalIntervals: Bool.random(),
            interpolation: ModulationSettings(
                numberOfNotes: Int.random(in: 0...3),
                interval: Int.random(in: 1...3),
                enabled: Bool.random()
            ),
            infrapolation: ModulationSettings(
                numberOfNotes: Int.random(in: 0...2),
                interval: Int.random(in: 1...3),
                enabled: Bool.random()
            ),
            ultrapolation: ModulationSettings(
                numberOfNotes: Int.random(in: 0...2),
                interval: Int.random(in: 1...3),
                enabled: Bool.random()
            ),
            primaryDirection: .ascending,
            mirrorPoints: Int.random(in: 0...3),
            retrogradeSections: Bool.random(),
            registerShifts: RegisterShiftPattern.allCases.randomElement() ?? .none,
            contourPattern: contourPatterns.randomElement() ?? .linear,
            baseNoteDuration: Double.random(in: 0.5...2.0),
            harmonicMode: HarmonicMode.allCases.randomElement() ?? .tonal,
            chordGeneration: ChordSettings(
                enabled: Bool.random(),
                chordSize: Int.random(in: 2...4),
                voicingPreference: VoicingPreference.allCases.randomElement() ?? .close,
                velocityScale: Double.random(in: 0.6...0.9)
            ),
            harmonicRhythm: HarmonicRhythmSettings(
                chordChangeFrequency: Int.random(in: 2...8),
                syncopationLevel: Double.random(in: 0...0.6),
                harmonicTension: Double.random(in: 0.2...0.8)
            ),
            velocitySettings: VelocitySettings(
                baseVelocity: UInt8.random(in: 60...100),
                range: UInt8.random(in: 20...50),
                waveDepth: Double.random(in: 0.3...0.8),
                randomness: Double.random(in: 0.1...0.4),
                phase: Double.random(in: 0...2 * .pi),
                emphasisBeat: Int.random(in: 2...8),
                emphasisAmount: Double.random(in: 0.2...0.6)
            ),
            toneShifting: ToneShiftSettings(
                toneIncrement: Int.random(in: 0...12),
                maxToneShift: Int.random(in: 0...24),
                shiftPattern: RegisterShiftPattern.allCases.randomElement() ?? .none
            ),
            rhythmSettings: ParameterManager.randomRhythmSettings()
        )
    }
    
    /// Generate a cyclical pattern and create MIDI sequence
    /// - Parameters:
    ///   - generatorName: Name of the pattern generator to use
    ///   - parameters: Pattern generation parameters
    ///   - completion: Completion handler with result
    func generateCyclicalPatternAndMIDI(
        using generatorName: String,
        parameters: PatternParameters,
        completion: @escaping (Result<PatternGenerationResult, Error>) -> Void
    ) {
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Generate cyclical pattern
            guard let result = self.cyclicalSequenceGenerator.generateCyclicalSequence(
                baseParameters: parameters,
                generatorName: generatorName
            ) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to generate cyclical pattern"
                    completion(.failure(MIDIIntegrationError.patternGenerationFailed))
                }
                return
            }
            
            // Create MIDI sequence
            guard let _ = self.midiEngine.generateMusicSequence(from: result, parameters: parameters) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to create MIDI sequence"
                    completion(.failure(MIDIIntegrationError.midiSequenceCreationFailed))
                }
                return
            }
            
            let generationTime = CFAbsoluteTimeGetCurrent() - startTime
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.generationProgress = 1.0
                self.lastGenerationTime = generationTime
                self.currentPattern = result
                
                // Autosave if enabled
                self.autosaveCurrentPattern()
                
                completion(.success(result))
            }
        }
    }
    
    /// Generate a combined cyclical pattern using multiple generators
    /// - Parameters:
    ///   - generatorNames: Array of generator names to use
    ///   - parameters: Pattern generation parameters
    ///   - combinationMode: How to combine the patterns
    ///   - completion: Completion handler with result
    func generateCombinedCyclicalPatternAndMIDI(
        using generatorNames: [String],
        parameters: PatternParameters,
        combinationMode: PatternCombinationMode = .sequential,
        completion: @escaping (Result<PatternGenerationResult, Error>) -> Void
    ) {
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Generate combined cyclical pattern
            guard let result = self.cyclicalSequenceGenerator.generateCombinedCyclicalSequence(
                baseParameters: parameters,
                generatorNames: generatorNames,
                combinationMode: combinationMode
            ) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to generate combined cyclical pattern"
                    completion(.failure(MIDIIntegrationError.patternGenerationFailed))
                }
                return
            }
            
            // Create MIDI sequence
            guard let _ = self.midiEngine.generateMusicSequence(from: result, parameters: parameters) else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to create MIDI sequence"
                    completion(.failure(MIDIIntegrationError.midiSequenceCreationFailed))
                }
                return
            }
            
            let generationTime = CFAbsoluteTimeGetCurrent() - startTime
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.generationProgress = 1.0
                self.lastGenerationTime = generationTime
                self.currentPattern = result
                
                // Autosave if enabled
                self.autosaveCurrentPattern()
                
                completion(.success(result))
            }
        }
    }
}

// MARK: - Supporting Types

/// Playback status information
struct PlaybackStatus {
    let isPlaying: Bool
    let currentTime: TimeInterval
    let totalDuration: TimeInterval
    
    var progress: Double {
        guard totalDuration > 0 else { return 0.0 }
        return currentTime / totalDuration
    }
}

/// Slonimsky preset patterns
struct SlonimskyPreset {
    let name: String
    let description: String
    let generatorName: String
    let parameters: PatternParameters
    var category: String = "Classic"
}

/// MIDI integration errors
enum MIDIIntegrationError: Error, LocalizedError {
    case patternGenerationFailed
    case midiSequenceCreationFailed
    case noGeneratorsAvailable
    case invalidParameters
    
    var errorDescription: String? {
        switch self {
        case .patternGenerationFailed:
            return "Failed to generate pattern"
        case .midiSequenceCreationFailed:
            return "Failed to create MIDI sequence"
        case .noGeneratorsAvailable:
            return "No pattern generators available"
        case .invalidParameters:
            return "Invalid parameters provided"
        }
    }
} 