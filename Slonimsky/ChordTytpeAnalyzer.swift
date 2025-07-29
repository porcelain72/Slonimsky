//
//  ChordTytpeAnalyzer.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 24/07/2025.
//

import Foundation

enum AnalyzerChordType: String {
    case major, minor, diminished, augmented
    case major7, minor7, dominant7
    case sus2, sus4
    case unknown
}

struct ChordTypeAnalyzer {
    
    /// Extracts a chord type and voiced chord from a melodic fragment.
    static func inferChord(
        from notes: [MIDIInfo],
        registerHint: Int = 60,
        velocity: UInt8? = nil,
        channel: UInt8 = 1
    ) -> Chord {
        // 1. Extract pitch classes
        let pitchClasses = orderedUnique(notes.map { $0.note % 12 })
        guard let rootPC = pitchClasses.first else {
            return Chord(notes: [], velocity: 0, channel: channel)
        }

        // 2. Compute intervals from root
        let intervals = pitchClasses.dropFirst().map {
            ($0 - rootPC + 12) % 12
        }

        // 3. Detect chord type
        let type = detectChordType(from: intervals)

        // 4. Voice chord
        let midiRoot = (registerHint / 12) * 12 + rootPC
        let chordNotes = voiceChord(root: midiRoot, type: type)

        // 5. Use average velocity or provided one
        let averageVelocity = velocity ?? UInt8(clamping: Int(notes.map(\.velocity).average * 0.8))

        return Chord(notes: chordNotes.map(clampMIDI), velocity: averageVelocity, channel: channel)
    }

    /// Classifies the chord type based on intervals from the root
    private static func detectChordType(from intervals: [Int]) -> AnalyzerChordType {
        let intervalSet = Set(intervals)

        switch intervalSet {
        case [3, 7]: return .minor
        case [4, 7]: return .major
        case [3, 6]: return .diminished
        case [4, 8]: return .augmented
        case [4, 7, 11]: return .major7
        case [3, 7, 10]: return .minor7
        case [4, 7, 10]: return .dominant7
        case [2, 7]: return .sus2
        case [5, 7]: return .sus4
        default: return .unknown
        }
    }

    /// Returns a voiced chord (as MIDI note numbers) based on type
    private static func voiceChord(root: Int, type: AnalyzerChordType) -> [Int] {
        switch type {
        case .major:      return [root, root + 4, root + 7]
        case .minor:      return [root, root + 3, root + 7]
        case .diminished: return [root, root + 3, root + 6]
        case .augmented:  return [root, root + 4, root + 8]
        case .major7:     return [root, root + 4, root + 7, root + 11]
        case .minor7:     return [root, root + 3, root + 7, root + 10]
        case .dominant7:  return [root, root + 4, root + 7, root + 10]
        case .sus2:       return [root, root + 2, root + 7]
        case .sus4:       return [root, root + 5, root + 7]
        case .unknown:    return [root, root + 5, root + 9]
        }
    }

    /// Clamp MIDI notes into 0...127
    private static func clampMIDI(_ n: Int) -> Int {
        return min(max(n, 0), 127)
    }

    /// Ordered unique helper
    private static func orderedUnique<T: Hashable>(_ xs: [T]) -> [T] {
        var seen = Set<T>()
        var out: [T] = []
        for x in xs where !seen.contains(x) {
            seen.insert(x)
            out.append(x)
        }
        return out
    }
}
