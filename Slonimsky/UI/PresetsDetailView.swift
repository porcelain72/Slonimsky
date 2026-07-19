//
//  PresetsDetailView.swift
//  Slonimsky
//
//  Presets panel: one-tap example configurations, including a showcase set
//  that demonstrates the rhythm engine (meters, meter cycles, isorhythm,
//  Euclidean rhythms, phase curves, and the pattern process).
//

import SwiftUI

// MARK: - Showcase Presets

/// Presets that exercise the rhythm-engine features. Shown above the classic
/// presets in both the Presets panel and the preset picker sheet.
let showcasePresets: [SlonimskyPreset] = [

    // Euclidean groove in an asymmetric meter, rotating one step per cycle
    SlonimskyPreset(
        name: "Balkan Machine",
        description: "E(5,8) in 7/8 (2+2+3); the grid rotates one step per cycle and comes full circle after 8",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var rhythm = RhythmSettings()
            rhythm.mode = .euclidean
            rhythm.euclideanHits = 5
            rhythm.euclideanSteps = 8
            rhythm.euclideanRotation = 0
            rhythm.euclideanStepDuration = .eighth
            rhythm.accentBoost = 24

            var cyclical = CyclicalSettings()
            cyclical.euclideanRotation = CyclicalParameterSettings(
                isEnabled: true, minValue: 0, maxValue: 7, period: 8, shape: .rampUp
            )

            return PatternParameters(
                rootNote: 62,
                scaleType: .phrygianDominant,
                numberOfOctaves: 1,
                divisionsOfOctave: 7,
                tempo: 140.0,
                meter: .sevenEight,
                mirror: false,
                cyclicalSettings: cyclical,
                rhythmSettings: rhythm
            )
        }(),
        category: "Rhythm Engine Showcase"
    ),

    // The Cuban tresillo as a low pentatonic line
    SlonimskyPreset(
        name: "Tresillo Bass",
        description: "Minor pentatonic walking an E(3,8) tresillo grid — the off-steps are real rests",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var rhythm = RhythmSettings()
            rhythm.mode = .euclidean
            rhythm.euclideanHits = 3
            rhythm.euclideanSteps = 8
            rhythm.euclideanStepDuration = .eighth
            rhythm.accentBoost = 16

            return PatternParameters(
                rootNote: 43,
                scaleType: .minorPentatonic,
                numberOfOctaves: 1,
                divisionsOfOctave: 5,
                tempo: 110.0,
                mirror: false,
                rhythmSettings: rhythm
            )
        }(),
        category: "Rhythm Engine Showcase"
    ),

    // Medieval isorhythm: a 5-entry talea (with a rest) against a Dorian color
    SlonimskyPreset(
        name: "Machaut in Five",
        description: "Isorhythm in 5/4 (3+2): a talea with a built-in rest keeps re-punctuating the Dorian line",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var rhythm = RhythmSettings()
            rhythm.mode = .isorhythm
            rhythm.talea = [
                TaleaEntry(value: .quarter),
                TaleaEntry(value: .quarter),
                TaleaEntry(value: .eighth),
                TaleaEntry(value: .eighth, isRest: true),
                TaleaEntry(value: .half)
            ]
            rhythm.accentBoost = 18

            return PatternParameters(
                rootNote: 62,
                scaleType: .dorian,
                numberOfOctaves: 1,
                divisionsOfOctave: 7,
                tempo: 96.0,
                meter: .fiveFour,
                mirror: false,
                rhythmSettings: rhythm
            )
        }(),
        category: "Rhythm Engine Showcase"
    ),

    // Glass-style pendulum: the pattern grows note by note, then collapses
    SlonimskyPreset(
        name: "Glass Pendulum",
        description: "Additive process up and back down: 1, 12, 123 … full pattern … 321, 1",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var process = ProcessSettings()
            process.mode = .pendulum
            process.startCount = 1
            process.notesPerCycle = 1

            return PatternParameters(
                rootNote: 64,
                scaleType: .pentatonic,
                numberOfOctaves: 1,
                divisionsOfOctave: 5,
                tempo: 132.0,
                mirror: false,
                baseNoteDuration: 0.5,
                processSettings: process
            )
        }(),
        category: "Rhythm Engine Showcase"
    ),

    // Two phase curves with different periods drifting against each other
    SlonimskyPreset(
        name: "Phase Music",
        description: "Root rises on a 3-cycle ramp while ornament density breathes on a 4-cycle triangle — realigns every 12",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var cyclical = CyclicalSettings()
            cyclical.rootNote = CyclicalParameterSettings(
                isEnabled: true, minValue: 60, maxValue: 72, period: 3, shape: .rampUp
            )
            cyclical.interpolationNotes = CyclicalParameterSettings(
                isEnabled: true, minValue: 0, maxValue: 3, period: 4, shape: .triangle
            )

            return PatternParameters(
                rootNote: 60,
                scaleType: .diatonic,
                numberOfOctaves: 1,
                divisionsOfOctave: 7,
                tempo: 120.0,
                interpolation: ModulationSettings(numberOfNotes: 1, interval: 2, enabled: true),
                mirror: false,
                baseNoteDuration: 0.5,
                cyclicalSettings: cyclical
            )
        }(),
        category: "Rhythm Engine Showcase"
    ),

    // Meter cycle + additive process: everything at once
    SlonimskyPreset(
        name: "Odd-Time Traveler",
        description: "A growing Hirajoshi line flowing across a 4/4 | 7/8 | 5/8 meter cycle — accents migrate every pass",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var process = ProcessSettings()
            process.mode = .additive
            process.startCount = 2
            process.notesPerCycle = 1

            var rhythm = RhythmSettings()
            rhythm.accentBoost = 22

            return PatternParameters(
                rootNote: 57,
                scaleType: .hirajoshi,
                numberOfOctaves: 1,
                divisionsOfOctave: 5,
                tempo: 126.0,
                meterCycle: MeterCycle(bars: [.fourFour, .sevenEight, .fiveEight]),
                mirror: false,
                baseNoteDuration: 0.5,
                rhythmSettings: rhythm,
                processSettings: process
            )
        }(),
        category: "Rhythm Engine Showcase"
    )
]

// MARK: - Reich Showcase

/// Presets built on Steve Reich's techniques: phasing voices, and
/// substitution of beats for rests (construct/reduce).
let reichPresets: [SlonimskyPreset] = [

    // Discrete phasing: the second voice jumps one grid step per cycle,
    // realigning after one full trip around the pattern
    SlonimskyPreset(
        name: "Clapping Pattern",
        description: "E(7,12) sixteenths; a second voice jumps one step ahead each cycle and realigns after 12",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var rhythm = RhythmSettings()
            rhythm.mode = .euclidean
            rhythm.euclideanHits = 7
            rhythm.euclideanSteps = 12
            rhythm.euclideanStepDuration = .sixteenth
            rhythm.accentBoost = 20

            var phasing = PhasingSettings()
            phasing.mode = .discrete
            phasing.stepsPerCycle = 1

            return PatternParameters(
                rootNote: 60,
                scaleType: .minorPentatonic,
                numberOfOctaves: 1,
                divisionsOfOctave: 5,
                tempo: 138.0,
                meter: Meter(numerator: 12, denominator: 16, groupings: [3, 3, 3, 3]),
                mirror: false,
                rhythmSettings: rhythm,
                phasingSettings: phasing
            )
        }(),
        category: "Reich Showcase"
    ),

    // Continuous phasing: the second voice drifts a quarter step per cycle,
    // passing through the blurred zones between lock points
    SlonimskyPreset(
        name: "Piano Phase",
        description: "Two voices on the same line; voice 2 drifts a quarter of a step each cycle — blur, lock, repeat",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var phasing = PhasingSettings()
            phasing.mode = .continuous
            phasing.driftPerCycle = 0.25
            phasing.voiceVelocityOffset = -12

            return PatternParameters(
                rootNote: 64,
                scaleType: .diatonic,
                numberOfOctaves: 1,
                divisionsOfOctave: 7,
                tempo: 144.0,
                mirror: false,
                baseNoteDuration: 0.25,
                phasingSettings: phasing
            )
        }(),
        category: "Reich Showcase"
    ),

    // Substitution of beats for rests: fixed footprint, notes arrive one at a
    // time in spread order and never move once placed
    SlonimskyPreset(
        name: "Drumming Build",
        description: "Construction over E(9,16): beats replace rests one per cycle while the bar length never changes",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var rhythm = RhythmSettings()
            rhythm.mode = .euclidean
            rhythm.euclideanHits = 9
            rhythm.euclideanSteps = 16
            rhythm.euclideanStepDuration = .eighth
            rhythm.accentBoost = 18

            var process = ProcessSettings()
            process.mode = .construct
            process.startCount = 1
            process.notesPerCycle = 1

            return PatternParameters(
                rootNote: 55,
                scaleType: .hirajoshi,
                numberOfOctaves: 1,
                divisionsOfOctave: 5,
                tempo: 120.0,
                mirror: false,
                rhythmSettings: rhythm,
                processSettings: process
            )
        }(),
        category: "Reich Showcase"
    ),

    // A preloaded entered melody phasing against itself: the point of the
    // custom-melody feature in one preset
    SlonimskyPreset(
        name: "Entered Motif Phase",
        description: "A hand-entered two-bar motif (rests included) phasing against itself, one step per cycle",
        generatorName: "Custom Melody Generator",
        parameters: {
            var melody = CustomMelody()
            melody.isEnabled = true
            melody.notes = [
                MelodyNote(pitch: 62, value: .quarter),                // D4
                MelodyNote(pitch: 64, value: .eighth),                 // E4
                MelodyNote(pitch: 65, value: .eighth),                 // F4
                MelodyNote(pitch: 67, value: .quarter),                // G4
                MelodyNote(pitch: 0,  value: .eighth, isRest: true),   // breath
                MelodyNote(pitch: 64, value: .eighth),                 // E4
                MelodyNote(pitch: 60, value: .quarter),                // C4
                MelodyNote(pitch: 62, value: .quarter)                 // D4
            ]

            var phasing = PhasingSettings()
            phasing.mode = .discrete
            phasing.stepsPerCycle = 1
            phasing.voiceVelocityOffset = -10

            var rhythm = RhythmSettings()
            rhythm.accentBoost = 16

            return PatternParameters(
                tempo: 126.0,
                mirror: false,
                rhythmSettings: rhythm,
                phasingSettings: phasing,
                customMelody: melody
            )
        }(),
        category: "Reich Showcase"
    ),

    // Construction and phasing interacting: the pattern hollows out while the
    // second voice slips against it, an octave up
    SlonimskyPreset(
        name: "Phase & Fade",
        description: "Reduce mode empties the pattern beat by beat while a second voice phases against it an octave up",
        generatorName: "Scale Pattern Generator",
        parameters: {
            var rhythm = RhythmSettings()
            rhythm.accentBoost = 16

            var process = ProcessSettings()
            process.mode = .reduce
            process.notesPerCycle = 1

            var phasing = PhasingSettings()
            phasing.mode = .discrete
            phasing.stepsPerCycle = 1
            phasing.voiceTranspose = 12
            phasing.voiceVelocityOffset = -10

            return PatternParameters(
                rootNote: 57,
                scaleType: .pentatonic,
                numberOfOctaves: 1,
                divisionsOfOctave: 5,
                tempo: 112.0,
                mirror: false,
                baseNoteDuration: 0.5,
                rhythmSettings: rhythm,
                processSettings: process,
                phasingSettings: phasing
            )
        }(),
        category: "Reich Showcase"
    )
]

/// All presets known to the app, showcase groups first.
var allPresets: [SlonimskyPreset] {
    showcasePresets + reichPresets + defaultPresets
}

// MARK: - Presets Panel

/// The Presets sidebar panel: browse and apply example configurations in place.
struct PresetsDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    @ObservedObject var midiService: MIDIIntegrationService
    @Binding var isGenerating: Bool

    @State private var appliedPresetName: String?

    private var groupedPresets: [(category: String, presets: [SlonimskyPreset])] {
        var order: [String] = []
        var groups: [String: [SlonimskyPreset]] = [:]
        for preset in allPresets {
            if groups[preset.category] == nil { order.append(preset.category) }
            groups[preset.category, default: []].append(preset)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(groupedPresets, id: \.category) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.category)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color.garageBandText)

                    ForEach(group.presets, id: \.name) { preset in
                        presetCard(preset)
                    }
                }
            }
        }
    }

    // MARK: - Preset card

    private func presetCard(_ preset: SlonimskyPreset) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(preset.name)
                    .font(.headline)
                    .foregroundColor(Color.garageBandText)
                Spacer()
                if appliedPresetName == preset.name {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.garageBandAccent)
                }
                Button("Apply") {
                    apply(preset)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isGenerating)
            }

            Text(preset.description)
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            // Feature chips derived from the preset's parameters
            HStack(spacing: 6) {
                ForEach(featureChips(for: preset.parameters), id: \.self) { chip in
                    Text(chip)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.garageBandAccent.opacity(0.15))
                        .foregroundColor(Color.garageBandText)
                        .cornerRadius(4)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(Color.garageBandPanel)
        .cornerRadius(8)
    }

    private func featureChips(for parameters: PatternParameters) -> [String] {
        var chips: [String] = []
        chips.append(parameters.meterCycle.displayName)
        chips.append(parameters.scaleType.rawValue)
        if parameters.rhythmSettings.mode != .uniform {
            chips.append(parameters.rhythmSettings.mode.rawValue)
        }
        if parameters.processSettings.mode != .none {
            chips.append("Process: \(parameters.processSettings.mode.rawValue)")
        }
        let curveCount = parameters.cyclicalSettings.enabledParameters.count
        if curveCount > 0 {
            chips.append("Curves: \(curveCount)")
        }
        if parameters.phasingSettings.mode != .off {
            chips.append("Phasing: \(parameters.phasingSettings.mode.rawValue)")
        }
        return chips
    }

    // MARK: - Apply

    private func apply(_ preset: SlonimskyPreset) {
        // Reflect the preset in every parameter panel first, then generate
        // through the full pipeline (cyclical curves and processes included).
        parameterManager.setParameters(preset.parameters)
        isGenerating = true

        midiService.generatePresetPattern(preset: preset) { result in
            DispatchQueue.main.async {
                isGenerating = false
                switch result {
                case .success:
                    appliedPresetName = preset.name
                    print("✅ Preset applied: \(preset.name)")
                case .failure(let error):
                    print("❌ Failed to apply preset: \(error)")
                }
            }
        }
    }
}
