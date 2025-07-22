
import AudioToolbox
import Foundation

/// A structure to represent a single musical track, containing a sequence of notes.
struct MIDITrack {
    /// An array of MIDI note numbers (0-127).
    let notes: [Int]
    // In the future, we can add other properties like MIDI channel or instrument type here.
}

/// A helper for generating Standard MIDI Files (.mid) using AudioToolbox.
struct MIDIFileGenerator {

    /// Generates a MIDI file from one or more tracks and saves it to a temporary location.
    ///
    /// - Parameter tracks: An array of `MIDITrack` objects to include in the file.
    /// - Returns: A URL pointing to the newly created temporary MIDI file.
    /// - Throws: An error if the MIDI file cannot be created or written to disk.
    static func generate(tracks: [MIDITrack]) throws -> URL {
        var sequence: MusicSequence?
        var newSequence: MusicSequence?
        guard NewMusicSequence(&newSequence) == noErr, let sequence = newSequence else {
            throw MIDIError.sequenceCreationFailed
        }

        for (index, trackData) in tracks.enumerated() {
            var musicTrack: MusicTrack?
            guard MusicSequenceNewTrack(sequence, &musicTrack) == noErr, let musicTrack = musicTrack else {
                throw MIDIError.trackCreationFailed
            }

            var currentTime: MusicTimeStamp = 0.0

            for noteNumber in trackData.notes {
                var noteMessage = MIDINoteMessage(
                    channel: UInt8(index % 16), // Assign a different channel per track
                    note: UInt8(clamping: noteNumber),
                    velocity: 100, // Default velocity
                    releaseVelocity: 0,
                    duration: 1.0 // Each note is one beat long
                )

                guard MusicTrackNewMIDINoteEvent(musicTrack, currentTime, &noteMessage) == noErr else {
                    // Best effort, continue if one note fails
                    continue
                }
                currentTime += Double(noteMessage.duration)
            }
        }

        // Get the raw MIDI data
        var data: Unmanaged<CFData>?
        guard MusicSequenceFileCreateData(sequence, .midiType, MusicSequenceFileFlags.init(rawValue: 0), 60, &data) == noErr,
              let midiData = data?.takeRetainedValue() as Data? else {
            throw MIDIError.dataCreationFailed
        }

        // Save to a temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mid")
        try midiData.write(to: tempURL)

        return tempURL
    }
}

/// Custom errors for MIDI generation.
enum MIDIError: Error {
    case sequenceCreationFailed
    case trackCreationFailed
    case dataCreationFailed
}

// Helper to clamp integer values to the UInt8 range
extension UInt8 {
    init(clamping value: Int) {
        self = UInt8(Swift.max(0, Swift.min(255, value)))
    }
}
