
//
//  ContentView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 22/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
 

    @State private var sequence: [MIDIInfo] = []
    @State private var isPlaying: Bool = false
    @State private var currentNoteIndex: Int? = nil
    @StateObject private var sequencer = SlonimskySequencer()

    
    @StateObject var audioPlayer = AudioPlayer()

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Generation Parameters")) {
                    Stepper("Root Note: \(sequencer.rootNote)", value: $sequencer.rootNote, in: 0...127)
                    Stepper("Divisions of Octave: \(sequencer.divisionsOfOctave)", value: $sequencer.divisionsOfOctave, in: 1...12)
                    Stepper("Number of Octaves: \(sequencer.numberOfOctaves)", value: $sequencer.numberOfOctaves, in: 1...4) // Changed from numberOfNotes
                    Stepper("Note Duration: \(String(format: "%.1f", sequencer.noteDuration))s", value: $sequencer.noteDuration, in: 0.0625...1.0, step: 0.0625)
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Modulations")) {
                    ForEach($sequencer.modulations) { $modulation in
                        VStack(alignment: .leading) {
                            Picker("Type", selection: $modulation.type) {
                                ForEach(ModulationType.allCases) { type in
                                    Text(type.rawValue.capitalized).tag(type)
                                }
                            }
                            if modulation.type != .none {
                                Stepper("Number of New Notes: \(modulation.numberOfNewNotes)", value: $modulation.numberOfNewNotes, in: 1...10)
                                Stepper("Interval Between New Notes: \(modulation.intervalBetweenNewNotes)", value: $modulation.intervalBetweenNewNotes, in: 1...12)
                            }
                        }
                    }
                    Button("Add Modulation") {
                        sequencer.modulations.append(SlonimskyModulation.defaultModulation)
                    }
                    Button("Remove Last Modulation") {
                        if !sequencer.modulations.isEmpty {
                            sequencer.modulations.removeLast()
                        }
                    }
                }
                
                Section(header:Text("Velocity")){
                    Slider(value: $sequencer.model.waveDepth, in: 0...1, label: { Text("Wave Depth") })
                    Slider(value:  $sequencer.model.randomness, in: 0...1, label: { Text("Randomness") })
                    Slider(value:  $sequencer.model.phase, in: 0.0...2.0, label: { Text("Phase") })
                    Stepper("Emphasize every \( sequencer.model.emphasisBeat) notes", value:  $sequencer.model.emphasisBeat, in: 1...16)

                   
                           
                    Slider(value:  $sequencer.model.emphasisAmount, in: 0...1, label:{Text("Emphasis Amount")})
                       
                }
            }

            Button(action: {
                if sequencer.isPlaying {
                    sequencer.stop()
                } else {
                    sequencer.play()
                }
            }) {
                Text(sequencer.isPlaying ? "Stop Playing" : "Generate and Play")
            }

            .padding()

            Button("Save MIDI") {
                /*
                let interp = modulations.first { mod in
                    mod.type == .interpolation
                }
                let infra =  modulations.first { mod in
                    mod.type == .infrapolation
                }
                
                let ultra =  modulations.first { mod in
                    mod.type == .ultrapolation
                }
                
                let interval = 12/divisionsOfOctave
                let count = (12/interval) * numberOfOctaves
                sequence = NoteSequenceGenerator.buildAllCombinations(startNote: rootNote, interval: interval, count: count, maxInterpolate: interp?.numberOfNewNotes ?? 0, maxInfrapolate: infra?.numberOfNewNotes ?? 0, maxUltrapolate:ultra?.numberOfNewNotes ?? 0, model:  sequencer.model)
                
                
               // let midiSequence = sequence.map{max(0, min(127, $0)) }

                do {
                    let url = try MIDIFileGenerator.generate(tracks: [MIDITrack(notes: sequence)], noteDuration: Double(noteDuration))
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.midi]
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
                 */}
            .padding()
/*
            if !sequence.isEmpty {
                Text("Generated Sequence:")
                    .font(.headline)
                Text(sequence.map { String($0) }.joined(separator: ", "))
                    .padding()
            }
            */
            VelocityVisualizer(sequence: sequence, currentNoteIndex: audioPlayer.currentNoteIndex)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
