//
//  Chord.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 23/07/2025.
//

import Foundation

struct ChordEvent {
    /// Start position in beats (not seconds) relative to the sequence.
    let startBeat: Double
    /// Length in beats.
    let durationBeats: Double
    /// MIDI notes to play (0–127).
    let notes: [Int]
    /// Velocity for all notes in the chord.
    let velocity: UInt8
    /// MIDI channel for this chord (e.g., 1 for accompaniment).
    let channel: UInt8
}

struct Chord {
    let notes: [Int]
    let velocity: UInt8
    let channel: UInt8
}


struct ChordExtractionParams {
    var groupSize: Int = 4          // how many melody notes per chord window
    var chordSize: Int = 3          // build triads (3) or 4-note chords (7ths)
    var beatLengthPerNote: Double = 1.0 // if melody note = quarter, this is 1.0
    var chordHoldBeats: Double? = nil   // if nil, chord lasts full group window
    var channel: UInt8 = 1          // chords on channel 1
    var velocityScale: Double = 0.8 // scale relative to avg group melody velocity
    var spreadOctaves: Int = 1      // allow chord tones to span upward octaves
    var preferCloseVoicing: Bool = true
}

