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
/// A single scheduled MIDI event. All times are in beats, quarter note = 1.0
/// (matching CoreAudio MusicTimeStamp).
struct MIDIInfo: Equatable {
    /// MIDI note number (0-127). Ignored when `isRest` is true.
    let note: Int
    var velocity: UInt8
    /// Start time in beats from the beginning of the sequence.
    var onset: Double
    /// Length in beats.
    var duration: Double
    /// True for a rest: occupies time but produces no sound.
    var isRest: Bool
    var cycleIndex: Int

    init(note: Int, velocity: UInt8, onset: Double = 0, duration: Double, isRest: Bool = false, cycleIndex: Int = 0) {
        self.note = note
        self.velocity = velocity
        self.onset = onset
        self.duration = duration
        self.isRest = isRest
        self.cycleIndex = cycleIndex
    }

    /// End time in beats.
    var end: Double { onset + duration }

    /// A copy shifted later in time by `beats`.
    func offset(by beats: Double) -> MIDIInfo {
        var copy = self
        copy.onset += beats
        return copy
    }
}

extension Array where Element == MIDIInfo {
    /// Assigns onsets by sequential accumulation (each event starts when the previous ends).
    func withSequentialOnsets(startingAt start: Double = 0) -> [MIDIInfo] {
        var onset = start
        return map { note in
            var copy = note
            copy.onset = onset
            onset += copy.duration
            return copy
        }
    }

    /// Total length of the sequence in beats (latest event end). Rests count toward length.
    var totalLength: Double {
        map(\.end).max() ?? 0
    }

    /// Events that produce sound (rests filtered out).
    var soundingNotes: [MIDIInfo] {
        filter { !$0.isRest }
    }
}

/// Base note duration values for pattern generation
/// These represent standard musical note durations in beats
/// Quarter note = 1 beat (matches MusicTimeStamp), Whole = 4 beats, Eighth = 0.5 beat, etc.
enum BaseNoteDuration: String, CaseIterable, Codable {
    case whole = "Whole Note (4 beats)"
    case half = "Half Note (2 beats)"
    case quarter = "Quarter Note (1 beat)"
    case eighth = "Eighth Note (0.5 beat)"
    case sixteenth = "Sixteenth Note (0.25 beat)"
    case thirtySecond = "32nd Note (0.125 beat)"
    case dottedHalf = "Dotted Half (3 beats)"
    case dottedQuarter = "Dotted Quarter (1.5 beats)"
    case dottedEighth = "Dotted Eighth (0.75 beat)"
    case tripletHalf = "Half Note Triplet (1.333 beats)"
    case tripletQuarter = "Quarter Note Triplet (0.667 beat)"
    case tripletEighth = "Eighth Note Triplet (0.333 beat)"

    /// Convert to beat value (TimeInterval)
    /// Quarter note = 1 beat, all others scale from that
    var beatValue: TimeInterval {
        switch self {
        case .whole: return 4.0
        case .half: return 2.0
        case .quarter: return 1.0
        case .eighth: return 0.5
        case .sixteenth: return 0.25
        case .thirtySecond: return 0.125
        case .dottedHalf: return 3.0
        case .dottedQuarter: return 1.5
        case .dottedEighth: return 0.75
        case .tripletHalf: return 4.0 / 3.0
        case .tripletQuarter: return 2.0 / 3.0
        case .tripletEighth: return 1.0 / 3.0
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
        return closest ?? .quarter  // Default to quarter note (1 beat)
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
