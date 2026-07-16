//
//  EuclideanRhythm.swift
//  Slonimsky
//
//  Bjorklund's algorithm for Euclidean rhythm generation.
//

import Foundation

/// Generates Euclidean rhythms: `hits` onsets distributed as evenly as possible
/// across `steps` grid positions (Bjorklund's algorithm, equivalent to Toussaint's
/// Euclidean rhythms). E(3,8) is the tresillo [x . . x . . x .]; E(5,8) the cinquillo.
enum EuclideanRhythm {

    /// Returns `steps` booleans containing exactly `min(hits, steps)` true values,
    /// maximally evenly distributed, rotated left by `rotation` steps.
    /// - Parameters:
    ///   - hits: number of onsets (clamped to 0...steps)
    ///   - steps: grid length (minimum 1)
    ///   - rotation: left rotation; any integer, normalized modulo steps
    static func pattern(hits: Int, steps: Int, rotation: Int = 0) -> [Bool] {
        let n = max(1, steps)
        let k = min(max(0, hits), n)

        guard k > 0 else { return Array(repeating: false, count: n) }
        guard k < n else { return Array(repeating: true, count: n) }

        // Bjorklund: repeatedly distribute the remainder sequences into the counts.
        var counts: [[Bool]] = Array(repeating: [true], count: k)
        var remainders: [[Bool]] = Array(repeating: [false], count: n - k)

        while remainders.count > 1 {
            let pairs = min(counts.count, remainders.count)
            var newCounts: [[Bool]] = []
            for i in 0..<pairs {
                newCounts.append(counts[i] + remainders[i])
            }
            let leftoverCounts = Array(counts.dropFirst(pairs))
            let leftoverRemainders = Array(remainders.dropFirst(pairs))
            counts = newCounts
            remainders = leftoverCounts + leftoverRemainders
        }

        var result = (counts + remainders).flatMap { $0 }

        // Normalize and apply left rotation.
        let r = ((rotation % n) + n) % n
        if r > 0 {
            result = Array(result[r...] + result[..<r])
        }
        return result
    }
}
