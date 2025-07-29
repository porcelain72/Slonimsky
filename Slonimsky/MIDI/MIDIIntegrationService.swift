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
    
    // MARK: - Private Properties
    private let midiEngine = MIDIEngine()
    private let patternRegistry = PatternGeneratorRegistry.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
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
            guard let _ = self.midiEngine.generateMusicSequence(from: result) else {
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
            guard let _ = self.midiEngine.generateMusicSequence(from: result) else {
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
    
    /// Pause playback
    func pausePlayback() {
        midiEngine.pause()
    }
    
    /// Resume playback
    func resumePlayback() {
        midiEngine.resume()
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
    
    /// Send current pattern to external MIDI destination
    /// - Parameter bpm: Tempo in beats per minute
    func sendToExternalMIDI(bpm: Double = 120.0) {
        guard let pattern = currentPattern else {
            errorMessage = "No pattern available to send"
            return
        }
        
        midiEngine.sendToExternalMIDI(notes: pattern.notes, bpm: bpm)
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
        
        generatePatternAndMIDI(using: generatorName, parameters: parameters, completion: completion)
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
            timeSignature: .common,
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
            noteDurationPattern: DurationPattern.allCases.randomElement() ?? .uniform,
            baseNoteDuration: Double.random(in: 0.125...0.5),
            rhythmicDensity: Double.random(in: 0.5...1.5),
            syncopationLevel: Double.random(in: 0...0.8),
            metricModulation: MetricModulationSettings(
                enabled: Bool.random(),
                modulationType: MetricModulationType.allCases.randomElement() ?? .accelerando,
                intensity: Double.random(in: 0.3...0.8),
                frequency: Int.random(in: 2...8)
            ),
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
            )
        )
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