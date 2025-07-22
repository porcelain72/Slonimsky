
import Foundation

/// Defines the foundational Slonimsky-style patterns based on octave divisions.
enum ScalePattern {
    case tritone       // Divides the octave into 2 equal intervals (6 semitones)
    case augmented     // Divides the octave into 3 equal intervals (4 semitones)
    case diminished7   // Divides the octave into 4 equal intervals (3 semitones)

    /// The intervals in semitones for each pattern.
    var intervals: [Int] {
        switch self {
        case .tritone:
            return [6]
        case .augmented:
            return [4, 4, 4]
        case .diminished7:
            return [3, 3, 3, 3]
        }
    }
}

/// Specifies the direction of the melodic sequence.
enum PatternDirection {
    case ascending
    case descending
}

/// A helper struct to generate numerical sequences of notes.
struct NoteSequenceGenerator {

    /// Generates a sequence of MIDI note numbers based on the provided parameters.
    ///
    /// - Parameters:
    ///   - rootNote: The starting MIDI note number (0-127).
    ///   - scalePattern: The core pattern to use for generation.
    ///   - numberOfNotes: The total number of notes to generate in the sequence.
    ///   - direction: The melodic direction (ascending or descending).
    /// - Returns: An array of integers representing the MIDI note numbers.
    static func generate(
        rootNote: Int,
        scalePattern: ScalePattern,
        numberOfNotes: Int,
        direction: PatternDirection
    ) -> [Int] {
        guard numberOfNotes > 0 else {
            return []
        }

        var sequence: [Int] = []
        var currentNote = rootNote
        let intervals = scalePattern.intervals
        var intervalIndex = 0

        for _ in 0..<numberOfNotes {
            // Clamp the note to the valid MIDI range
            let clampedNote = max(0, min(127, currentNote))
            sequence.append(clampedNote)

            // Determine the next interval
            let interval = intervals[intervalIndex % intervals.count]

            // Calculate the next note based on direction
            switch direction {
            case .ascending:
                currentNote += interval
            case .descending:
                currentNote -= interval
            }
            
            intervalIndex += 1
        }

        return sequence
    }
}
