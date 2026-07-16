//
//  Meter.swift
//  Slonimsky
//
//  Time signature with additive beat groupings.
//  All beat values use quarter note = 1.0 beat.
//

import Foundation

/// A time signature with additive groupings, e.g. 7/8 grouped as 2+2+3.
/// Groupings define the accent grid: the first pulse of each group is accented.
struct Meter: Codable, Equatable, Hashable {
    /// Number of denominator-value pulses per bar (e.g. 7 in 7/8).
    var numerator: Int
    /// Note value of one pulse: 1, 2, 4, 8, or 16.
    var denominator: Int
    /// Additive grouping of the numerator's pulses, e.g. [2, 2, 3]. Must sum to numerator.
    var groupings: [Int]

    init(numerator: Int, denominator: Int, groupings: [Int]? = nil) {
        self.numerator = numerator
        self.denominator = denominator
        self.groupings = groupings ?? Meter.defaultGroupings(numerator: numerator, denominator: denominator)
    }

    // MARK: - Derived values (quarter note = 1.0 beat)

    /// Length of one bar in beats. 4/4 = 4.0, 7/8 = 3.5, 6/8 = 3.0.
    var beatsPerBar: Double {
        Double(numerator) * denominatorBeatValue
    }

    /// Length of one denominator pulse in beats. Eighth = 0.5, quarter = 1.0.
    var denominatorBeatValue: Double {
        4.0 / Double(denominator)
    }

    /// Onsets of each grouping start within a bar, in beats from the barline.
    /// 7/8 [2,2,3] -> [0.0, 1.0, 2.0]; 7/8 [3,2,2] -> [0.0, 1.5, 2.5].
    var groupingOnsets: [Double] {
        var onsets: [Double] = []
        var position = 0.0
        for group in groupings {
            onsets.append(position)
            position += Double(group) * denominatorBeatValue
        }
        return onsets
    }

    /// True when an absolute onset (in beats from sequence start) falls on a grouping start.
    func isGroupingStart(_ onset: Double, epsilon: Double = 1e-6) -> Bool {
        guard beatsPerBar > 0 else { return false }
        let positionInBar = onset.truncatingRemainder(dividingBy: beatsPerBar)
        return groupingOnsets.contains { abs($0 - positionInBar) < epsilon }
    }

    // MARK: - Validation

    var isValid: Bool {
        numerator >= 1 && numerator <= 32
            && [1, 2, 4, 8, 16].contains(denominator)
            && !groupings.isEmpty
            && groupings.allSatisfy { $0 > 0 }
            && groupings.reduce(0, +) == numerator
    }

    // MARK: - Defaults

    /// Conventional groupings: compound meters in threes, aksak-style for 5 and 7,
    /// otherwise one pulse per group.
    static func defaultGroupings(numerator: Int, denominator: Int) -> [Int] {
        if denominator >= 8 && numerator % 3 == 0 && numerator > 3 {
            return Array(repeating: 3, count: numerator / 3)
        }
        switch numerator {
        case 5: return [3, 2]
        case 7: return [2, 2, 3]
        default: return Array(repeating: 1, count: max(1, numerator))
        }
    }

    // MARK: - Presets

    static let twoFour = Meter(numerator: 2, denominator: 4)
    static let threeFour = Meter(numerator: 3, denominator: 4)
    static let fourFour = Meter(numerator: 4, denominator: 4)
    static let fiveFour = Meter(numerator: 5, denominator: 4)
    static let fiveEight = Meter(numerator: 5, denominator: 8)
    static let sixEight = Meter(numerator: 6, denominator: 8)
    static let sevenEight = Meter(numerator: 7, denominator: 8)
    static let nineEight = Meter(numerator: 9, denominator: 8)
    static let elevenSixteen = Meter(numerator: 11, denominator: 16, groupings: [3, 3, 3, 2])

    static let presets: [Meter] = [
        .twoFour, .threeFour, .fourFour, .fiveFour,
        .fiveEight, .sixEight, .sevenEight, .nineEight, .elevenSixteen
    ]

    /// Display string, e.g. "7/8 (2+2+3)".
    var displayName: String {
        let base = "\(numerator)/\(denominator)"
        let isTrivialGrouping = groupings.allSatisfy { $0 == 1 }
        if isTrivialGrouping {
            return base
        }
        return "\(base) (\(groupings.map(String.init).joined(separator: "+")))"
    }
}
