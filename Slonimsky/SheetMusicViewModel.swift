//
//  SheetMusicViewModel.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 25/07/2025.
//

import Foundation
import PDFKit
import SwiftUI
import Salieri

@MainActor
class SheetMusicViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument? = nil
    

    private let generator = Salieri(configuration: SalieriConfiguration(
        pageSize: CGSize(width: 612, height: 792), // US Letter
        margins: EdgeInsets(top: 72, left: 72, bottom: 72, right: 72),
        staffSize: 4.0 ))

    var midiURL: URL?
    var pdfData: Data?
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
         //   pdfURL = base.appendingPathExtension("pdf")

           
            
           
            if   let sequence =  try MIDIExporter.getSequence(melodyTracks: [melody], chordEvents: chords, noteDuration: noteDuration, bpm: bpm),
                 let doc = generator.renderPDF(from: sequence) {
                self.pdfDocument = doc
                pdfData = self.pdfDocument?.dataRepresentation()
            }

        } catch {
            print("❌ Sheet music generation failed: \(error)")
        }
    }

    func shareItems() -> [Data] {
        return [pdfData]
            .compactMap { $0 }
           // .filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
