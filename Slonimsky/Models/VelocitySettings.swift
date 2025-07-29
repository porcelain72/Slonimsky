//
//  VelocitySettings.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Settings for note velocity and expression control
struct VelocitySettings: Codable, Equatable, Hashable {
    var baseVelocity: UInt8
    var range: UInt8
    var waveDepth: Double
    var randomness: Double
    var phase: Double
    var emphasisBeat: Int
    var emphasisAmount: Double
    
    init(
        baseVelocity: UInt8 = 80,
        range: UInt8 = 40,
        waveDepth: Double = 0.5,
        randomness: Double = 0.2,
        phase: Double = 0.0,
        emphasisBeat: Int = 4,
        emphasisAmount: Double = 0.3
    ) {
        self.baseVelocity = baseVelocity
        self.range = range
        self.waveDepth = waveDepth
        self.randomness = randomness
        self.phase = phase
        self.emphasisBeat = emphasisBeat
        self.emphasisAmount = emphasisAmount
    }
    
    static var `default`: VelocitySettings {
        VelocitySettings()
    }
    
    func validate() -> Bool {
        guard baseVelocity >= 1 && baseVelocity <= 127 else { return false }
        guard range >= 0 && range <= 127 else { return false }
        guard waveDepth >= 0.0 && waveDepth <= 1.0 else { return false }
        guard randomness >= 0.0 && randomness <= 1.0 else { return false }
        guard phase >= 0.0 && phase <= 2.0 * .pi else { return false }
        guard emphasisBeat >= 1 && emphasisBeat <= 16 else { return false }
        guard emphasisAmount >= 0.0 && emphasisAmount <= 1.0 else { return false }
        return true
    }
    
    /// Calculate velocity for a note at a given index
    func calculateVelocity(for noteIndex: Int, note: Int) -> UInt8 {
        // Base velocity component
        var velocity = Double(baseVelocity)
        
        // Wave component (sinusoidal variation)
        let sinComponent = sin(Double(noteIndex) * phase) * waveDepth
        velocity += Double(range) * sinComponent
        
        // Randomness component
        let randComponent = Double.random(in: -1...1) * randomness
        velocity += Double(range) * randComponent
        
        // Emphasis component
        let isEmphasized = emphasisBeat > 0 && (noteIndex % emphasisBeat == 0)
        if isEmphasized {
            velocity += Double(range) * emphasisAmount
        }
        
        // Clamp to valid MIDI velocity range
        return UInt8(clamping: Int(round(velocity)))
    }
    
    /// Calculate velocity with additional harmonic context
    func calculateVelocityWithHarmonicContext(
        for noteIndex: Int,
        note: Int,
        harmonicTension: Double = 0.5,
        melodicContour: Double = 0.0
    ) -> UInt8 {
        var velocity = calculateVelocity(for: noteIndex, note: note)
        
        // Harmonic tension affects velocity
        let tensionComponent = Double(velocity) * harmonicTension * 0.3
        velocity = UInt8(clamping: Int(round(Double(velocity) + tensionComponent)))
        
        // Melodic contour affects velocity (higher notes get more emphasis)
        let contourComponent = Double(velocity) * melodicContour * 0.2
        velocity = UInt8(clamping: Int(round(Double(velocity) + contourComponent)))
        
        return velocity
    }
}

// MARK: - Velocity Presets

extension VelocitySettings {
    /// Preset for classical performance
    static var classical: VelocitySettings {
        VelocitySettings(
            baseVelocity: 70,
            range: 30,
            waveDepth: 0.3,
            randomness: 0.1,
            phase: 0.0,
            emphasisBeat: 4,
            emphasisAmount: 0.4
        )
    }
    
    /// Preset for jazz performance
    static var jazz: VelocitySettings {
        VelocitySettings(
            baseVelocity: 85,
            range: 50,
            waveDepth: 0.6,
            randomness: 0.4,
            phase: 0.5,
            emphasisBeat: 2,
            emphasisAmount: 0.5
        )
    }
    
    /// Preset for electronic music
    static var electronic: VelocitySettings {
        VelocitySettings(
            baseVelocity: 90,
            range: 20,
            waveDepth: 0.8,
            randomness: 0.1,
            phase: 1.0,
            emphasisBeat: 8,
            emphasisAmount: 0.2
        )
    }
    
    /// Preset for experimental/atonal music
    static var experimental: VelocitySettings {
        VelocitySettings(
            baseVelocity: 75,
            range: 60,
            waveDepth: 0.9,
            randomness: 0.7,
            phase: 1.5,
            emphasisBeat: 3,
            emphasisAmount: 0.6
        )
    }
} 