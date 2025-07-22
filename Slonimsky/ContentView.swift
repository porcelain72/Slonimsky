//
//  ContentView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 22/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var rootNote = 60
    @State private var scalePattern: ScalePattern = .tritone
    @State private var numberOfNotes = 12
    @State private var direction: PatternDirection = .ascending
    @State private var sequence: [Int] = []

    private let audioPlayer = AudioPlayer()

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Generation Parameters")) {
                    Stepper("Root Note: \(rootNote)", value: $rootNote, in: 0...127)
                    Picker("Scale Pattern", selection: $scalePattern) {
                        Text("Tritone").tag(ScalePattern.tritone)
                        Text("Augmented").tag(ScalePattern.augmented)
                        Text("Diminished 7th").tag(ScalePattern.diminished7)
                    }
                    Stepper("Number of Notes: \(numberOfNotes)", value: $numberOfNotes, in: 1...100)
                    Picker("Direction", selection: $direction) {
                        Text("Ascending").tag(PatternDirection.ascending)
                        Text("Descending").tag(PatternDirection.descending)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }

            Button("Generate and Play") {
                sequence = NoteSequenceGenerator.generate(
                    rootNote: rootNote,
                    scalePattern: scalePattern,
                    numberOfNotes: numberOfNotes,
                    direction: direction
                )
                audioPlayer.play(notes: sequence)
            }
            .padding()

            Button("Save MIDI") {
                let generatedSequence = NoteSequenceGenerator.generate(
                    rootNote: rootNote,
                    scalePattern: scalePattern,
                    numberOfNotes: numberOfNotes,
                    direction: direction
                )

                do {
                    let url = try MIDIFileGenerator.generate(tracks: [MIDITrack(notes: generatedSequence)])
                    let savePanel = NSSavePanel()
                    savePanel.allowedFileTypes = ["mid"]
                    savePanel.begin { result in
                        if result == .OK,
                           let saveURL = savePanel.url {
                            try? FileManager.default.moveItem(at: url, to: saveURL)
                        }
                    }
                } catch {
                    // Handle error
                    print(error)
                }
            }
            .padding()

            if !sequence.isEmpty {
                Text("Generated Sequence:")
                    .font(.headline)
                Text(sequence.map { String($0) }.joined(separator: ", "))
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
