//
//  MidiInfo.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 26/07/2025.
//

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
