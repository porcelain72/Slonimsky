//
//  MidiInfo.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 26/07/2025.
//

import Foundation

/// A structure to represent a single musical track, containing a sequence of notes.
struct MIDITrack {
    /// An array of MIDI note numbers (0-127).
    let notes: [MIDIInfo]
    // In the future, we can add other properties like MIDI channel or instrument type here.
}
struct MIDIInfo : Equatable{
    let note: Int
    var velocity: UInt8
    var beatLength: Double
    var cycleIndex: Int
    
    init(note: Int, velocity: UInt8, beatLength: Double, cycleIndex: Int = 0) {
        self.note = note
        self.velocity = velocity
        self.beatLength = beatLength
        self.cycleIndex = cycleIndex
    }
}


struct MIDITimeSignature {
    let numerator: Int
    let denominator: Int
    
    var beatsPerMeasure: Double {
        Double(numerator) * (4.0 / Double(denominator))
    }
    static let defaultSignature = MIDITimeSignature(numerator: 4, denominator: 4)

}

enum NoteDuration {
    case whole, half, quarter, eighth, sixteenth

    func beatValue(in timeSignature: MIDITimeSignature = .defaultSignature) -> Double {
        let quarterLength = 1.0 // One quarter note = 1 beat
        switch self {
        case .whole: return 4.0 * quarterLength
        case .half: return 2.0 * quarterLength
        case .quarter: return 1.0 * quarterLength
        case .eighth: return 0.5 * quarterLength
        case .sixteenth: return 0.25 * quarterLength
        }
    }
}

/// Base note duration values for pattern generation
/// These represent standard musical note durations in beats
/// Whole note = 1 beat, Half = 0.5 beat, Quarter = 0.25 beat, etc.
enum BaseNoteDuration: String, CaseIterable, Codable {
    case whole = "Whole Note (1 beat)"
    case half = "Half Note (0.5 beat)"
    case quarter = "Quarter Note (0.25 beat)"
    case eighth = "Eighth Note (0.125 beat)"
    case sixteenth = "Sixteenth Note (0.0625 beat)"
    case thirtySecond = "32nd Note (0.03125 beat)"
    case dottedHalf = "Dotted Half (0.75 beat)"
    case dottedQuarter = "Dotted Quarter (0.375 beat)"
    case dottedEighth = "Dotted Eighth (0.1875 beat)"
    case tripletHalf = "Half Note Triplet (0.333 beat)"
    case tripletQuarter = "Quarter Note Triplet (0.167 beat)"
    case tripletEighth = "Eighth Note Triplet (0.083 beat)"
    
    /// Convert to beat value (TimeInterval)
    /// Whole note = 1 beat, all others are fractions of that
    var beatValue: TimeInterval {
        switch self {
        case .whole: return 1.0
        case .half: return 0.5
        case .quarter: return 0.25
        case .eighth: return 0.125
        case .sixteenth: return 0.0625
        case .thirtySecond: return 0.03125
        case .dottedHalf: return 0.75
        case .dottedQuarter: return 0.375
        case .dottedEighth: return 0.1875
        case .tripletHalf: return 1.0 / 3.0
        case .tripletQuarter: return 1.0 / 6.0
        case .tripletEighth: return 1.0 / 12.0
        }
    }
    
    /// Create from a beat value (finds closest match)
    static func from(beatValue: TimeInterval) -> BaseNoteDuration {
        let allDurations = BaseNoteDuration.allCases
        let closest = allDurations.min { 
            let diff0 = $0.beatValue - beatValue
            let diff1 = $1.beatValue - beatValue
            return abs(diff0) < abs(diff1)
        }
        return closest ?? .whole  // Default to whole note (1 beat)
    }
    
    /// Display name for UI
    var displayName: String {
        return self.rawValue
    }
    
    /// Short name for compact display
    var shortName: String {
        switch self {
        case .whole: return "Whole"
        case .half: return "Half"
        case .quarter: return "Quarter"
        case .eighth: return "Eighth"
        case .sixteenth: return "16th"
        case .thirtySecond: return "32nd"
        case .dottedHalf: return "Dotted Half"
        case .dottedQuarter: return "Dotted Quarter"
        case .dottedEighth: return "Dotted 8th"
        case .tripletHalf: return "Half Triplet"
        case .tripletQuarter: return "Quarter Triplet"
        case .tripletEighth: return "8th Triplet"
        }
    }
}
