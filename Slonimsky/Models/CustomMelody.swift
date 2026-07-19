//
//  CustomMelody.swift
//  Slonimsky
//
//  A user-entered melody used as the base material for the pattern
//  transformations (mirror, modulations, rhythm modes, curves, processes,
//  phasing). Entered via step entry in the Melody panel.
//

import Foundation

/// One entered melody event: a pitch (or rest) with a duration from the
/// standard duration palette. No identity fields — PatternParameters' hash
/// drives auto-generation change detection.
struct MelodyNote: Codable, Equatable, Hashable {
    /// MIDI note number (0–127). Ignored when `isRest` is true.
    var pitch: Int
    var value: DurationValue
    var isRest: Bool = false

    var beats: Double { value.beats }
}

/// A user-entered melody, capped at `maxBars` bars of the current meter cycle.
struct CustomMelody: Codable, Equatable, Hashable {
    /// When true (and non-empty), the melody replaces the scale generator as
    /// the base pitch/rhythm source.
    var isEnabled: Bool = false

    var notes: [MelodyNote] = []

    /// Maximum melody length in bars of the active meter cycle.
    static let maxBars = 8

    /// Total entered length in beats (rests included).
    var totalBeats: Double {
        notes.reduce(0.0) { $0 + $1.beats }
    }

    /// Sounding pitches in order (the melody's "color").
    var pitches: [Int] {
        notes.filter { !$0.isRest }.map { $0.pitch }
    }

    /// The melody's own rhythm as a talea: durations and rests exactly as
    /// entered. With an untransformed pitch stream, isorhythm scheduling of
    /// this talea reproduces the melody verbatim in a single pass.
    var derivedTalea: [TaleaEntry] {
        notes.map { TaleaEntry(value: $0.value, isRest: $0.isRest) }
    }

    /// Beats available for input: the first `maxBars` bars of the meter cycle.
    func maxBeats(for meterCycle: MeterCycle) -> Double {
        guard meterCycle.totalBeats > 0 else { return 0 }
        var beats = 0.0
        var barIndex = 0
        for _ in 0..<CustomMelody.maxBars {
            beats += meterCycle.bars[barIndex % meterCycle.bars.count].beatsPerBar
            barIndex += 1
        }
        return beats
    }

    func validate() -> Bool {
        for note in notes where !note.isRest {
            guard note.pitch >= 0 && note.pitch <= 127 else { return false }
        }
        if isEnabled {
            guard !notes.isEmpty, !pitches.isEmpty else { return false }
        }
        return true
    }
}
