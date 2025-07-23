//
//  VelocityModel.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 23/07/2025.
//

struct VelocityModel {
    var randomness: Double       // 0.0–1.0
    var waveDepth: Double        // 0.0–1.0
    var phase: Double            // frequency
    var baseVelocity: UInt8      // center of range
    var range: UInt8             // total amplitude range

    var emphasisBeat: Int        // e.g., every 4th note
    var emphasisAmount: Double   // 0.0–1.0: how much louder

    static let `default` = VelocityModel(
        randomness: 0.0,
        waveDepth: 0.5,
        phase: 0.2,
        baseVelocity: 80,
        range: 40,
        emphasisBeat: 4,
        emphasisAmount: 0.4
    )
}
