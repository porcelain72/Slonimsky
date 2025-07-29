//
//  ParameterControlsView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 25/07/2025.
//

import SwiftUI

struct ParameterControlsView: View {
    @ObservedObject var sequencer: SlonimskySequencer

    var body: some View {
        Form {
            Section(header: Text("Generation Parameters")) {
                Stepper("Root Note: \(sequencer.rootNote)", value: $sequencer.rootNote, in: 0...127)
                Stepper("Divisions of Octave: \(sequencer.divisionsOfOctave)", value: $sequencer.divisionsOfOctave, in: 1...12)
                Stepper("Number of Octaves: \(sequencer.numberOfOctaves)", value: $sequencer.numberOfOctaves, in: 1...4)
                Stepper("Note Duration: \(String(format: "%.1f", sequencer.noteDuration))s", value: $sequencer.noteDuration, in: 0.0625...1.0, step: 0.0625)
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
                            Stepper("New Notes: \(modulation.numberOfNewNotes)", value: $modulation.numberOfNewNotes, in: 1...10)
                            Stepper("Interval: \(modulation.intervalBetweenNewNotes)", value: $modulation.intervalBetweenNewNotes, in: 1...12)
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

            Section(header: Text("Velocity")) {
                Slider(value: $sequencer.model.waveDepth, in: 0...1, label: { Text("Wave Depth") })
                Slider(value: $sequencer.model.randomness, in: 0...1, label: { Text("Randomness") })
                Slider(value: $sequencer.model.phase, in: 0.0...2.0, label: { Text("Phase") })
                Stepper("Emphasize every \(sequencer.model.emphasisBeat) notes", value: $sequencer.model.emphasisBeat, in: 1...16)
                Slider(value: $sequencer.model.emphasisAmount, in: 0...1, label: { Text("Emphasis Amount") })
            }

            Section(header: Text("Tone Shifting")) {
                Stepper("Tone Increment: \(sequencer.toneIncrement)", value: $sequencer.toneIncrement, in: 0...24)
                Stepper("Max Tone Shift: \(sequencer.maxToneShift)", value: $sequencer.maxToneShift, in: 0...96)
            }

            Section(header: Text("Playback Info")) {
                HStack {
                    Text("Estimated Time")
                    Spacer()
                    Text(formatTime(sequencer.estimatedDuration))
                        .foregroundColor(.secondary)
                }
                Toggle("Use External MIDI Output", isOn: $sequencer.useMIDIOutput)
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
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, sec)
    }
}
