//
//  CustomMelodyPatternGenerator.swift
//  Slonimsky
//
//  Uses the user-entered melody as the base pitch (and, in uniform rhythm
//  mode, rhythm) source. All pattern transformations apply to it exactly as
//  they do to generated scales.
//

import Foundation

/// Generates patterns from the user-entered custom melody.
///
/// Rhythm contract:
/// - rhythm mode **Uniform** → "as entered": the melody's own durations and
///   rests become a talea scheduled via the isorhythm engine. Untransformed,
///   the melody plays back verbatim in one pass; when mirror/modulations
///   lengthen the pitch stream, the entered rhythm cycles against it.
/// - **Isorhythm / Euclidean** → the user's explicit rhythm settings win and
///   the melody contributes pitches only.
class CustomMelodyPatternGenerator: BasePatternGenerator {

    init() {
        super.init(
            name: "Custom Melody Generator",
            description: "Uses your entered melody as the base material for all transformations"
        )
    }

    override func generateNotePattern(parameters: PatternParameters, cycleIndex: Int) -> [Int] {
        let modifiedParameters = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        let basePitches = modifiedParameters.customMelody.pitches
        guard !basePitches.isEmpty else { return [] }

        // Mirror, register shifts, and contour transform the melody exactly
        // as they transform generated scales
        return ParameterApplicationManager.applyParameters(
            baseNotes: basePitches,
            parameters: modifiedParameters,
            generatorType: "Melody"
        )
    }

    override func generatePattern(parameters: PatternParameters, cycleIndex: Int) -> [MIDIInfo] {
        let modifiedParameters = applyCyclicalChanges(to: parameters, cycleIndex: cycleIndex)
        let notePattern = generateNotePattern(parameters: parameters, cycleIndex: cycleIndex)
        guard !notePattern.isEmpty else { return [] }

        // Effective scheduling parameters: in uniform mode the melody's own
        // rhythm (as a derived talea) replaces the flat base duration
        var effectiveParameters = modifiedParameters
        if effectiveParameters.rhythmSettings.mode == .uniform {
            effectiveParameters.rhythmSettings.mode = .isorhythm
            effectiveParameters.rhythmSettings.talea = modifiedParameters.customMelody.derivedTalea
        }

        return MIDIPatternConverter.convertWithModulations(
            notes: notePattern,
            parameters: effectiveParameters,
            generatorType: "Melody"
        )
    }

    override func estimateNoteCount(parameters: PatternParameters) -> Int {
        parameters.customMelody.notes.count
    }

    override func validateParameters(parameters: PatternParameters) -> Bool {
        guard super.validateParameters(parameters: parameters) else { return false }
        return !parameters.customMelody.pitches.isEmpty
    }
}
