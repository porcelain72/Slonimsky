//
//  PatternComposition.swift
//  Slonimsky
//
//  User-authored chain of patterns (slots) with a global playback repeat count.
//

import Foundation

/// One step in a pattern composition: its own generator selection and parameters.
struct PatternSlot: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var generatorNames: [String]
    var combinationMode: PatternCombinationMode
    var parameters: PatternParameters

    init(
        id: UUID = UUID(),
        name: String,
        generatorNames: [String] = ["Scale Pattern Generator"],
        combinationMode: PatternCombinationMode = .sequential,
        parameters: PatternParameters = PatternParameters()
    ) {
        self.id = id
        self.name = name
        self.generatorNames = generatorNames.isEmpty ? ["Scale Pattern Generator"] : generatorNames
        self.combinationMode = combinationMode
        self.parameters = parameters
    }

    /// Primary generator for single-generator APIs and compact labels.
    var primaryGeneratorName: String {
        generatorNames.first ?? "Scale Pattern Generator"
    }

    var displayGeneratorName: String {
        if generatorNames.count <= 1 {
            return primaryGeneratorName
        }
        return "\(generatorNames.count) generators"
    }

    /// Duplicate this slot with a new identity and optional display name.
    func duplicated(name: String? = nil) -> PatternSlot {
        PatternSlot(
            id: UUID(),
            name: name ?? self.name,
            generatorNames: generatorNames,
            combinationMode: combinationMode,
            parameters: parameters
        )
    }
}

/// A user-authored sequence of pattern slots with finite playback repeats.
struct PatternComposition: Codable, Equatable {
    static let minRepeatCount = 1
    static let maxRepeatCount = 99

    var slots: [PatternSlot]
    /// How many times the full slot chain plays (and is written into MIDI export). Default 1.
    var playbackRepeatCount: Int

    init(slots: [PatternSlot] = [], playbackRepeatCount: Int = 1) {
        self.slots = slots
        self.playbackRepeatCount = Self.clampedRepeatCount(playbackRepeatCount)
    }

    static func clampedRepeatCount(_ value: Int) -> Int {
        min(max(value, minRepeatCount), maxRepeatCount)
    }

    mutating func setPlaybackRepeatCount(_ value: Int) {
        playbackRepeatCount = Self.clampedRepeatCount(value)
    }

    /// Stable hash of composition content for auto-generation cache checks.
    var contentHash: Int {
        var hasher = Hasher()
        hasher.combine(playbackRepeatCount)
        for slot in slots {
            hasher.combine(slot.id)
            hasher.combine(slot.name)
            hasher.combine(slot.generatorNames)
            hasher.combine(slot.combinationMode)
            hasher.combine(slot.parameters)
        }
        return hasher.finalize()
    }

    /// Bootstrap a composition with a single slot from current editor state.
    static func bootstrapped(
        parameters: PatternParameters,
        generatorNames: [String],
        combinationMode: PatternCombinationMode = .sequential,
        name: String = "Pattern 1"
    ) -> PatternComposition {
        let slot = PatternSlot(
            name: name,
            generatorNames: generatorNames,
            combinationMode: combinationMode,
            parameters: parameters
        )
        return PatternComposition(slots: [slot], playbackRepeatCount: 1)
    }
}

/// Tempo change written into the MusicSequence at a beat boundary.
struct TempoChangeMarker: Equatable {
    let beat: Double
    let bpm: Double
}

/// Result of concatenating slots (and applying playback repeats).
struct CompositionBuildResult {
    let result: PatternGenerationResult
    let tempoMarkers: [TempoChangeMarker]
    /// Parameters used for harmony/rhythm track decisions (first slot).
    let primaryParameters: PatternParameters
    /// Beat length of one pass through all slots (before repeats).
    let singlePassDuration: Double
}

/// Pure helpers for concatenating and repeating note lists (testable without MIDI I/O).
enum CompositionNoteBuilder {

    /// Concatenate slot note lists end-to-end with same-pitch seam drops between slots.
    static func concatenateSlotNotes(_ slotNoteLists: [[MIDIInfo]]) -> (notes: [MIDIInfo], slotStartBeats: [Double]) {
        let result = PatternSeam.concatenate(slotNoteLists, dropMatchingSeam: true)
        return (result.notes, result.segmentStartBeats)
    }

    /// Repeat a single-pass note list `count` times, dropping a matching seam
    /// note between passes (keeps the final pass intact).
    static func applyRepeats(notes: [MIDIInfo], count: Int) -> [MIDIInfo] {
        let repeats = PatternComposition.clampedRepeatCount(count)
        guard repeats > 1, !notes.isEmpty else { return notes }

        let segments = Array(repeating: notes, count: repeats)
        return PatternSeam.concatenate(segments, dropMatchingSeam: true).notes
    }

    /// Tempo markers from already-resolved segment start beats.
    static func tempoMarkers(
        tempos: [Double],
        startBeats: [Double]
    ) -> [TempoChangeMarker] {
        guard tempos.count == startBeats.count else { return [] }
        let markers = zip(startBeats, tempos).map { TempoChangeMarker(beat: $0, bpm: $1) }
        return collapseRedundantTempos(markers)
    }

    private static func collapseRedundantTempos(_ markers: [TempoChangeMarker]) -> [TempoChangeMarker] {
        var result: [TempoChangeMarker] = []
        for marker in markers.sorted(by: { $0.beat < $1.beat }) {
            if let last = result.last, abs(last.bpm - marker.bpm) < 0.001 {
                continue
            }
            result.append(marker)
        }
        return result
    }
}
