
import XCTest
@testable import Slonimsky

final class MIDIFileGeneratorTests: XCTestCase {

    func testGenerateSingleTrack() throws {
        let track = MIDITrack(notes: [60, 62, 64, 65, 67, 69, 71, 72])
        let url = try MIDIFileGenerator.generate(tracks: [track])

        XCTAssert(FileManager.default.fileExists(atPath: url.path))

        // Clean up the generated file
        try FileManager.default.removeItem(at: url)
    }

    func testGenerateMultipleTracks() throws {
        let track1 = MIDITrack(notes: [60, 64, 67])
        let track2 = MIDITrack(notes: [62, 65, 69])
        let url = try MIDIFileGenerator.generate(tracks: [track1, track2])

        XCTAssert(FileManager.default.fileExists(atPath: url.path))

        // Clean up the generated file
        try FileManager.default.removeItem(at: url)
    }

    func testGenerateEmptyTrack() throws {
        let track = MIDITrack(notes: [])
        let url = try MIDIFileGenerator.generate(tracks: [track])

        XCTAssert(FileManager.default.fileExists(atPath: url.path))

        // Clean up the generated file
        try FileManager.default.removeItem(at: url)
    }
}
