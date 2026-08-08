//
//  RhythmLibraryPatternGenerator.swift
//  Slonimsky
//
//  Turns a built-in rhythm into MIDI: either General MIDI drum-kit hits or
//  the scale/melody pitches placed on the rhythm's grid. Downstream
//  transformations (curves, processes, phasing, meter accents) apply as they
//  do to every other generator.
//

import Foundation

class RhythmLibraryPatternGenerator: BasePatternGenerator {

    init() {
        super.init(
            name: "Rhythm Library Generator",
            description: "Plays a built-in rhythm as GM drums or as pitches on the rhythm's grid"
        )
    }

    // MARK: - Note pattern

    override func generateNotePattern(parameters: PatternParameters, cycleIndex: Int) -> [Int] {
        let modified = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        let settings = modified.rhythmLibrary
        guard let pattern = settings.pattern else { return [] }

        switch settings.output {
        case .drumKit:
            // Percussion notes are fixed GM values — no pitch transformation
            return placedHits(pattern: pattern, settings: settings).map { $0.voice.midiNote }
        case .pitched:
            return pitchSource(parameters: parameters, cycleIndex: cycleIndex)
        }
    }

    // MARK: - Scheduling

    override func generatePattern(parameters: PatternParameters, cycleIndex: Int) -> [MIDIInfo] {
        let modified = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        let settings = modified.rhythmLibrary
        guard let pattern = settings.pattern, pattern.isValid else { return [] }

        switch settings.output {
        case .drumKit:
            return drumEvents(pattern: pattern, settings: settings, parameters: modified)
        case .pitched:
            return pitchedEvents(
                pattern: pattern,
                settings: settings,
                parameters: modified,
                cycleIndex: cycleIndex
            )
        }
    }

    override func estimateNoteCount(parameters: PatternParameters) -> Int {
        parameters.rhythmLibrary.pattern?.hits.count ?? 0
    }

    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        guard let pattern = parameters.rhythmLibrary.pattern, pattern.isValid else { return false }
        return !parameters.rhythmLibrary.audibleVoices.isEmpty
    }

    // MARK: - Private helpers

    /// The pattern's audible hits with rotation applied, ordered in time.
    private func placedHits(pattern: RhythmPattern, settings: RhythmLibrarySettings) -> [RhythmHit] {
        let total = max(1, pattern.totalSteps)
        let rotation = ((settings.rotationSteps % total) + total) % total

        return pattern.hits
            .filter { !settings.mutedVoices.contains($0.voice) }
            .map { hit in
                RhythmHit(step: (hit.step + rotation) % total, voice: hit.voice, accent: hit.accent)
            }
            .sorted { $0.step < $1.step }
    }

    /// GM drum events, one per audible hit, flagged for the percussion channel.
    private func drumEvents(
        pattern: RhythmPattern,
        settings: RhythmLibrarySettings,
        parameters: PatternParameters
    ) -> [MIDIInfo] {
        let base = Int(parameters.velocitySettings.baseVelocity)

        return placedHits(pattern: pattern, settings: settings).map { hit in
            let velocity = UInt8(clamping: max(1, base + (hit.accent ? settings.accentBoost : 0)))
            return MIDIInfo(
                note: hit.voice.midiNote,
                velocity: velocity,
                onset: Double(hit.step) * pattern.stepBeats,
                duration: pattern.stepBeats,
                isPercussion: true,
                cycleIndex: 0
            )
        }
    }

    /// Pitched events: the rhythm supplies onsets and durations, the scale or
    /// custom melody supplies the pitches (cycling if the rhythm is longer).
    private func pitchedEvents(
        pattern: RhythmPattern,
        settings: RhythmLibrarySettings,
        parameters: PatternParameters,
        cycleIndex: Int
    ) -> [MIDIInfo] {
        var pitches = pitchSource(parameters: parameters, cycleIndex: cycleIndex)
        guard !pitches.isEmpty else { return [] }

        // Slonimsky modulations expand the pitch stream before it meets the grid
        pitches = MIDIPatternConverter.applySlonimskyModulations(
            notes: pitches,
            parameters: parameters
        )
        guard !pitches.isEmpty else { return [] }

        let total = max(1, pattern.totalSteps)
        let rotation = ((settings.rotationSteps % total) + total) % total
        let steps = pattern.onsetSteps(excluding: settings.mutedVoices)
            .map { ($0 + rotation) % total }
            .sorted()
        guard !steps.isEmpty else { return [] }

        var events: [MIDIInfo] = []
        for (index, step) in steps.enumerated() {
            // Each note lasts until the next onset (the last wraps to the bar end)
            let nextStep = index + 1 < steps.count ? steps[index + 1] : total
            let pitch = min(127, max(0, pitches[index % pitches.count]))
            let velocity = max(1, parameters.velocitySettings.calculateVelocity(for: index, note: pitch))

            events.append(MIDIInfo(
                note: pitch,
                velocity: velocity,
                onset: Double(step) * pattern.stepBeats,
                duration: Double(nextStep - step) * pattern.stepBeats,
                cycleIndex: 0
            ))
        }

        return MIDIPatternConverter.applyMeterAccents(to: events, parameters: parameters)
    }

    /// Pitches for pitched output: the custom melody when one is entered,
    /// otherwise the scale pattern. Each source applies its own transforms.
    private func pitchSource(parameters: PatternParameters, cycleIndex: Int) -> [Int] {
        if parameters.customMelody.isEnabled && !parameters.customMelody.pitches.isEmpty {
            return CustomMelodyPatternGenerator()
                .generateNotePattern(parameters: parameters, cycleIndex: cycleIndex)
        }
        return ScalePatternGenerator()
            .generateNotePattern(parameters: parameters, cycleIndex: cycleIndex)
    }
}
