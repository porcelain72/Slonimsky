//
//  ModulationSettings.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Settings for Slonimsky's modulation techniques
struct ModulationSettings: Codable, Equatable, Hashable {
    var numberOfNotes: Int
    var interval: Int
    var enabled: Bool
    
    init(numberOfNotes: Int = 0, interval: Int = 1, enabled: Bool = false) {
        self.numberOfNotes = numberOfNotes
        self.interval = interval
        self.enabled = enabled
    }
    
    static var `default`: ModulationSettings {
        ModulationSettings(numberOfNotes: 0, interval: 1, enabled: false)
    }
    
    func validate() -> Bool {
        guard numberOfNotes >= 0 && numberOfNotes <= 10 else { return false }
        guard interval >= 1 && interval <= 12 else { return false }
        return true
    }
}

/// Register shift patterns for octave displacement
enum RegisterShiftPattern: String, CaseIterable, Codable {
    case none = "None"
    case linear = "Linear"
    case exponential = "Exponential"
    case random = "Random"
    case mirror = "Mirror"
    case symmetrical = "Symmetrical"
    
    func calculateShift(baseNote: Int, index: Int, maxShift: Int) -> Int {
        switch self {
        case .none:
            return 0
        case .linear:
            let shift = (index * maxShift) / 100
            return min(shift, maxShift)
        case .exponential:
            let normalizedIndex = Double(index) / 100.0
            let shift = Int(Double(maxShift) * pow(normalizedIndex, 2))
            return min(shift, maxShift)
        case .random:
            return Int.random(in: 0...maxShift)
        case .mirror:
            let normalizedIndex = Double(index) / 100.0
            let shift = Int(Double(maxShift) * sin(normalizedIndex * .pi))
            return abs(shift)
        case .symmetrical:
            let normalizedIndex = Double(index) / 100.0
            let shift = Int(Double(maxShift) * (1.0 - abs(2.0 * normalizedIndex - 1.0)))
            return shift
        }
    }
}

/// Metric modulation settings for tempo changes
struct MetricModulationSettings: Codable, Equatable, Hashable {
    var enabled: Bool
    var modulationType: MetricModulationType
    var intensity: Double // 0.0 to 1.0
    var frequency: Int // How often to apply modulation
    
    init(enabled: Bool = false, modulationType: MetricModulationType = .accelerando, intensity: Double = 0.5, frequency: Int = 4) {
        self.enabled = enabled
        self.modulationType = modulationType
        self.intensity = intensity
        self.frequency = frequency
    }
    
    static var `default`: MetricModulationSettings {
        MetricModulationSettings()
    }
    
    func validate() -> Bool {
        guard intensity >= 0.0 && intensity <= 1.0 else { return false }
        guard frequency >= 1 && frequency <= 16 else { return false }
        return true
    }
}

/// Types of metric modulation
enum MetricModulationType: String, CaseIterable, Codable {
    case accelerando = "Accelerando"
    case ritardando = "Ritardando"
    case rubato = "Rubato"
    case pulse = "Pulse"
}

/// Chord generation settings
struct ChordSettings: Codable, Equatable, Hashable {
    var enabled: Bool
    var chordSize: Int
    var voicingPreference: VoicingPreference
    var velocityScale: Double
    
    init(enabled: Bool = true, chordSize: Int = 3, voicingPreference: VoicingPreference = .close, velocityScale: Double = 0.8) {
        self.enabled = enabled
        self.chordSize = chordSize
        self.voicingPreference = voicingPreference
        self.velocityScale = velocityScale
    }
    
    static var `default`: ChordSettings {
        ChordSettings()
    }
    
    func validate() -> Bool {
        guard chordSize >= 2 && chordSize <= 6 else { return false }
        guard velocityScale >= 0.1 && velocityScale <= 1.0 else { return false }
        return true
    }
}

/// Voicing preferences for chord generation
enum VoicingPreference: String, CaseIterable, Codable {
    case close = "Close"
    case open = "Open"
    case mixed = "Mixed"
}

/// Harmonic rhythm settings
struct HarmonicRhythmSettings: Codable, Equatable, Hashable {
    var chordChangeFrequency: Int // Every N notes
    var syncopationLevel: Double // 0.0 to 1.0
    var harmonicTension: Double // 0.0 to 1.0
    
    init(chordChangeFrequency: Int = 4, syncopationLevel: Double = 0.0, harmonicTension: Double = 0.5) {
        self.chordChangeFrequency = chordChangeFrequency
        self.syncopationLevel = syncopationLevel
        self.harmonicTension = harmonicTension
    }
    
    static var `default`: HarmonicRhythmSettings {
        HarmonicRhythmSettings()
    }
    
    func validate() -> Bool {
        guard chordChangeFrequency >= 1 && chordChangeFrequency <= 16 else { return false }
        guard syncopationLevel >= 0.0 && syncopationLevel <= 1.0 else { return false }
        guard harmonicTension >= 0.0 && harmonicTension <= 1.0 else { return false }
        return true
    }
}

/// Tone shifting settings
struct ToneShiftSettings: Codable, Equatable, Hashable {
    var toneIncrement: Int
    var maxToneShift: Int
    var shiftPattern: RegisterShiftPattern
    
    init(toneIncrement: Int = 0, maxToneShift: Int = 0, shiftPattern: RegisterShiftPattern = .none) {
        self.toneIncrement = toneIncrement
        self.maxToneShift = maxToneShift
        self.shiftPattern = shiftPattern
    }
    
    static var `default`: ToneShiftSettings {
        ToneShiftSettings()
    }
    
    func validate() -> Bool {
        guard toneIncrement >= 0 && toneIncrement <= 24 else { return false }
        guard maxToneShift >= 0 && maxToneShift <= 96 else { return false }
        return true
    }
} 