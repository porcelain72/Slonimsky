//
//  PatternSeam.swift
//  Slonimsky
//
//  Seam handling when concatenating pattern passes: drop the trailing sounding
//  note of the leading segment only when it matches the next segment's first
//  sounding pitch (avoids tonic–tonic doubles on closed scales/arpeggios).
//  The final pass is never trimmed — trimming happens only when a following
//  segment is appended.
//

import Foundation

enum PatternSeam {

    /// First sounding pitch in a MIDI event list, if any.
    static func firstSoundingPitch(in notes: [MIDIInfo]) -> Int? {
        notes.first(where: { !$0.isRest })?.note
    }

    /// Index of the last sounding (non-rest) event, if any.
    static func lastSoundingIndex(in notes: [MIDIInfo]) -> Int? {
        notes.lastIndex(where: { !$0.isRest })
    }

    /// Whether joining `trailing` after `leading` would attack the same pitch twice.
    static func hasMatchingSeam(leading: [MIDIInfo], trailing: [MIDIInfo]) -> Bool {
        guard let lastIndex = lastSoundingIndex(in: leading),
              let nextPitch = firstSoundingPitch(in: trailing) else {
            return false
        }
        return leading[lastIndex].note == nextPitch
    }

    /// Copy of `leading` with its last sounding note removed when it matches
    /// the first sounding pitch of `trailing`. Rests are never dropped as the
    /// seam note; if the last sounding note is not the final event, only that
    /// sounding event is removed.
    static func droppingTrailingSeamNote(
        of leading: [MIDIInfo],
        before trailing: [MIDIInfo]
    ) -> [MIDIInfo] {
        guard hasMatchingSeam(leading: leading, trailing: trailing),
              let lastIndex = lastSoundingIndex(in: leading),
              leading.count > 1 else {
            return leading
        }
        var result = leading
        result.remove(at: lastIndex)
        return result
    }

    /// Pitch-list variant for pre-scheduling seams (e.g. mirrored scale joins).
    static func droppingTrailingSeamPitch(
        of leading: [Int],
        before trailing: [Int]
    ) -> [Int] {
        guard let last = leading.last,
              let first = trailing.first,
              last == first,
              leading.count > 1 else {
            return leading
        }
        return Array(leading.dropLast())
    }

    /// Append `next` after `existing`, optionally dropping a matching seam note
    /// from `existing` first. `next` onsets are shifted to start at the end of
    /// the (possibly trimmed) head.
    static func appending(
        _ next: [MIDIInfo],
        to existing: [MIDIInfo],
        dropMatchingSeam: Bool
    ) -> [MIDIInfo] {
        guard !next.isEmpty else { return existing }
        guard !existing.isEmpty else { return next }

        let head = dropMatchingSeam
            ? droppingTrailingSeamNote(of: existing, before: next)
            : existing
        let offset = head.totalLength
        return head + next.map { $0.offset(by: offset) }
    }

    /// Concatenate segments end-to-end with optional same-pitch seam drops
    /// between consecutive segments. Returns notes and each segment's start beat
    /// (after prior trims).
    static func concatenate(
        _ segments: [[MIDIInfo]],
        dropMatchingSeam: Bool
    ) -> (notes: [MIDIInfo], segmentStartBeats: [Double]) {
        var allNotes: [MIDIInfo] = []
        var starts: [Double] = []

        for segment in segments {
            guard !segment.isEmpty else {
                starts.append(allNotes.totalLength)
                continue
            }
            if allNotes.isEmpty {
                starts.append(0)
                allNotes = segment
            } else {
                let head = dropMatchingSeam
                    ? droppingTrailingSeamNote(of: allNotes, before: segment)
                    : allNotes
                let start = head.totalLength
                starts.append(start)
                allNotes = head + segment.map { $0.offset(by: start) }
            }
        }

        return (allNotes, starts)
    }
}
