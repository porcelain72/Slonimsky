//
//  SheetMusicGenerator.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 25/07/2025.
//

import Foundation

import Foundation
import PDFKit

class SheetMusicGenerator {
    func generateSheetMusic(
        melody: [MIDIInfo],
        chords: [ChordEvent],
        noteDuration: TimeInterval,
        bpm: Double,
        outputURL: URL
    ) throws {
        // Ignore melody/chords for now – draw blank score
        let renderer = SheetMusicRenderer()
        let pdf = renderer.renderBlankScore(from: melody)
        // Save PDF
        let pdfURL = outputURL.appendingPathExtension("pdf")
        pdf.write(to: pdfURL)

        // Create placeholder Lilypond and MIDI files to keep interface intact
        let lilyStub = "% LilyPond stub\n\\version \"2.24.2\"\n{ c' }"
        try lilyStub.write(to: outputURL.appendingPathExtension("ly"), atomically: true, encoding: .utf8)

        let dummyMIDIData = Data() // Optionally export real MIDI later
        try dummyMIDIData.write(to: outputURL.appendingPathExtension("midi"))
    }
}
