//
//  SheetMusicViewModel.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 25/07/2025.
//

import Foundation
import PDFKit
import SwiftUI

@MainActor
class SheetMusicViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument? = nil
    private let generator = SheetMusicGenerator()

    var midiURL: URL?
    var pdfURL: URL?
    var lyURL: URL?

    /// Regenerates sheet music from sequencer state
    func updateFromSequencer(_ sequencer: SlonimskySequencer) {
        Task {
            await generateSheet(
                from: sequencer.flattenedMelody,
                chords: sequencer.chords,
                noteDuration: sequencer.noteDuration,
                bpm: sequencer.bpm
            )
        }
    }

    /// Generates sheet music and updates published PDF
    func generateSheet(from melody: [MIDIInfo],
                       chords: [ChordEvent],
                       noteDuration: TimeInterval,
                       bpm: Double) async {
        do {
            let base = FileManager.default.temporaryDirectory.appendingPathComponent("SheetMusic")
            midiURL = base.appendingPathExtension("midi")
            pdfURL = base.appendingPathExtension("pdf")
            lyURL = base.appendingPathExtension("ly")

            try await Task.detached(priority: .userInitiated) {
                try self.generator.generateSheetMusic(
                    melody: melody,
                    chords: chords,
                    noteDuration: noteDuration,
                    bpm: bpm,
                    outputURL: base
                )
            }.value

            if let pdfURL, let doc = PDFDocument(url: pdfURL) {
                self.pdfDocument = doc
            }

        } catch {
            print("❌ Sheet music generation failed: \(error)")
        }
    }

    func shareItems() -> [URL] {
        return [pdfURL, midiURL, lyURL]
            .compactMap { $0 }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
