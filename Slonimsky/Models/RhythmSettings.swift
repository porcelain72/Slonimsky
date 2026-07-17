//
//  RhythmSettings.swift
//  Slonimsky
//
//  Rhythm engine configuration: uniform, isorhythm (talea/color), and Euclidean modes.
//  All durations use quarter note = 1.0 beat.
//

import Foundation

/// How the rhythm engine assigns onsets and durations to a pitch stream.
enum RhythmMode: String, CaseIterable, Codable, Hashable {
    case uniform = "Uniform"
    case isorhythm = "Isorhythm"
    case euclidean = "Euclidean"

    var description: String {
        switch self {
        case .uniform:
            return "Every note gets the base duration"
        case .isorhythm:
            return "A repeating duration cycle (talea) runs independently against the pitch cycle (color)"
        case .euclidean:
            return "Notes fall on Euclidean-distributed hits within a step grid; other steps are rests"
        }
    }
}

/// Musical duration values for talea entries and Euclidean steps (quarter = 1.0 beat).
enum DurationValue: String, CaseIterable, Codable, Hashable {
    case sixteenth = "Sixteenth"
    case eighth = "Eighth"
    case dottedEighth = "Dotted Eighth"
    case quarter = "Quarter"
    case dottedQuarter = "Dotted Quarter"
    case half = "Half"
    case dottedHalf = "Dotted Half"

    var beats: Double {
        switch self {
        case .sixteenth: return 0.25
        case .eighth: return 0.5
        case .dottedEighth: return 0.75
        case .quarter: return 1.0
        case .dottedQuarter: return 1.5
        case .half: return 2.0
        case .dottedHalf: return 3.0
        }
    }

    /// Compact notation symbol for menus.
    var symbol: String {
        switch self {
        case .sixteenth: return "𝅘𝅥𝅯"
        case .eighth: return "𝅘𝅥𝅮"
        case .dottedEighth: return "𝅘𝅥𝅮."
        case .quarter: return "𝅘𝅥"
        case .dottedQuarter: return "𝅘𝅥."
        case .half: return "𝅗𝅥"
        case .dottedHalf: return "𝅗𝅥."
        }
    }

    var displayName: String { rawValue }
}

/// One entry of a talea (duration cycle): a duration that either sounds or rests.
/// Deliberately has no identity field — PatternParameters' hash drives auto-generation
/// change detection, so equality/hash must depend only on musical content.
struct TaleaEntry: Codable, Equatable, Hashable {
    var value: DurationValue
    var isRest: Bool

    init(value: DurationValue, isRest: Bool = false) {
        self.value = value
        self.isRest = isRest
    }
}

/// Glass/Reich-style pattern process: each cycle adds or removes notes.
/// Additive/subtractive/pendulum truncate (the time footprint grows/shrinks);
/// construct/reduce mask (fixed footprint — beats substitute for rests in place).
enum PatternProcessMode: String, CaseIterable, Codable, Hashable {
    case none = "Off"
    case additive = "Additive"          // grow: start, start+step, ..., full pattern
    case subtractive = "Subtractive"    // shrink: full pattern down to one note
    case pendulum = "Pendulum"          // grow to full, then shrink back
    case construct = "Construct"        // fixed footprint: rests become beats one by one
    case reduce = "Reduce"              // fixed footprint: beats become rests one by one

    var description: String {
        switch self {
        case .none:
            return "Play the full pattern every cycle"
        case .additive:
            return "Each cycle adds notes until the full pattern is reached"
        case .subtractive:
            return "Each cycle removes notes until one remains"
        case .pendulum:
            return "Grow to the full pattern, then shrink back"
        case .construct:
            return "Beats substitute for rests one by one — the pattern length never changes"
        case .reduce:
            return "Beats fall silent one by one — the pattern length never changes"
        }
    }

    /// True for the fixed-footprint (masking) modes.
    var isMasking: Bool {
        self == .construct || self == .reduce
    }
}

/// Settings for the additive/subtractive pattern process.
struct ProcessSettings: Codable, Equatable, Hashable {
    var mode: PatternProcessMode = .none

    /// Notes sounding in the first cycle (additive/pendulum), 1...16.
    var startCount: Int = 1

    /// Notes added or removed per cycle, 1...8.
    var notesPerCycle: Int = 1

    /// Number of cycles the process needs for a pattern of `n` sounding notes.
    func cycleCount(forPatternLength n: Int) -> Int {
        guard n > 0 else { return 1 }
        let step = max(1, notesPerCycle)
        let start = min(max(1, startCount), n)
        switch mode {
        case .none:
            return 1
        case .additive, .construct:
            return Int(ceil(Double(n - start) / Double(step))) + 1
        case .subtractive, .reduce:
            return Int(ceil(Double(n - 1) / Double(step))) + 1
        case .pendulum:
            let up = Int(ceil(Double(n - start) / Double(step))) + 1
            return max(1, 2 * up - 1)
        }
    }

    /// How many sounding notes cycle `c` keeps, for a pattern of `n` notes.
    func keptNoteCount(atCycle c: Int, patternLength n: Int) -> Int {
        guard n > 0 else { return 0 }
        let step = max(1, notesPerCycle)
        let start = min(max(1, startCount), n)
        switch mode {
        case .none:
            return n
        case .additive, .construct:
            return min(n, start + c * step)
        case .subtractive, .reduce:
            return max(1, n - c * step)
        case .pendulum:
            let up = Int(ceil(Double(n - start) / Double(step))) + 1
            if c < up {
                return min(n, start + c * step)
            }
            return max(start, n - (c - up + 1) * step)
        }
    }

    func validate() -> Bool {
        startCount >= 1 && startCount <= 16 && notesPerCycle >= 1 && notesPerCycle <= 8
    }

    /// Nested fill order for construct/reduce: the order in which the pattern's
    /// sounding positions come alive (construct) or fall silent (reduce, reversed).
    /// Greedy farthest-point on a circle: deterministic, evenly spread, and the
    /// first k positions are always a subset of the first k+1 — once a beat is
    /// placed, it never moves (Reich's substitution rule).
    static func fillOrder(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        var chosen: [Int] = [0]
        var remaining = Set(1..<count)

        while !remaining.isEmpty {
            var best = -1
            var bestDistance = -1
            // Iterate candidates in ascending order for deterministic ties
            for candidate in remaining.sorted() {
                let nearest = chosen.map { position -> Int in
                    let direct = abs(candidate - position)
                    return min(direct, count - direct) // circular distance
                }.min() ?? 0
                if nearest > bestDistance {
                    bestDistance = nearest
                    best = candidate
                }
            }
            chosen.append(best)
            remaining.remove(best)
        }
        return chosen
    }
}

/// Steve Reich phasing: a second voice plays the same pattern, slipping ahead
/// by a controlled amount each cycle until the voices realign.
enum PhasingMode: String, CaseIterable, Codable, Hashable {
    case off = "Off"
    case discrete = "Discrete"       // Clapping Music: jump whole grid steps per cycle
    case continuous = "Continuous"   // Piano Phase: drift a fraction of a step per cycle

    var description: String {
        switch self {
        case .off:
            return "Single voice"
        case .discrete:
            return "A second voice jumps ahead by whole grid steps each cycle"
        case .continuous:
            return "A second voice drifts ahead by a fraction of a step each cycle"
        }
    }
}

/// Settings for the phasing voice.
struct PhasingSettings: Codable, Equatable, Hashable {
    var mode: PhasingMode = .off

    /// Discrete: grid steps the second voice advances per cycle (1...8).
    var stepsPerCycle: Int = 1

    /// Continuous: fraction of one grid step drifted per cycle (0.05...1.0).
    var driftPerCycle: Double = 0.25

    /// Semitones added to the second voice (-12...12).
    var voiceTranspose: Int = 0

    /// Velocity offset for the second voice (-32...0), keeping it slightly softer.
    var voiceVelocityOffset: Int = -8

    func validate() -> Bool {
        stepsPerCycle >= 1 && stepsPerCycle <= 8
            && driftPerCycle >= 0.05 && driftPerCycle <= 1.0
            && voiceTranspose >= -12 && voiceTranspose <= 12
            && voiceVelocityOffset >= -32 && voiceVelocityOffset <= 0
    }
}

/// Configuration for the rhythm engine in MIDIPatternConverter.
struct RhythmSettings: Codable, Equatable, Hashable {
    var mode: RhythmMode = .uniform

    /// Isorhythm duration cycle. Rests advance time without consuming pitches.
    var talea: [TaleaEntry] = [
        TaleaEntry(value: .quarter),
        TaleaEntry(value: .eighth),
        TaleaEntry(value: .eighth)
    ]

    /// Euclidean E(hits, steps) rotated left by rotation steps.
    var euclideanHits: Int = 3
    var euclideanSteps: Int = 8
    var euclideanRotation: Int = 0
    var euclideanStepDuration: DurationValue = .eighth

    /// Velocity added to notes that fall on a meter grouping start.
    var accentBoost: Int = 16

    static let `default` = RhythmSettings()

    /// Number of talea entries that sound (non-rest).
    var taleaNoteCount: Int {
        talea.filter { !$0.isRest }.count
    }

    /// Total length of one talea cycle in beats.
    var taleaBeats: Double {
        talea.reduce(0.0) { $0 + $1.value.beats }
    }

    func validate() -> Bool {
        guard accentBoost >= 0 && accentBoost <= 64 else { return false }
        guard euclideanSteps >= 1 && euclideanSteps <= 64 else { return false }
        guard euclideanHits >= 1 && euclideanHits <= euclideanSteps else { return false }
        guard abs(euclideanRotation) < euclideanSteps || euclideanSteps == 1 else { return false }
        if mode == .isorhythm {
            guard !talea.isEmpty else { return false }
        }
        return true
    }
}
