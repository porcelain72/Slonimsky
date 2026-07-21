//
//  CompositionGenerator.swift
//  Slonimsky
//
//  Generates a full PatternComposition by generating each slot and concatenating.
//

import Foundation

/// Builds a single PatternGenerationResult from a user-authored composition.
final class CompositionGenerator {

    private let patternRegistry = PatternGeneratorRegistry.shared
    private let cyclicalSequenceGenerator = CyclicalSequenceGenerator()

    /// Generate concatenated + repeated notes for the composition.
    func build(_ composition: PatternComposition) -> CompositionBuildResult? {
        guard !composition.slots.isEmpty else {
            print("❌ Composition has no slots")
            return nil
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        var slotNoteLists: [[MIDIInfo]] = []
        var slotTempos: [Double] = []
        var totalNoteCount = 0

        for (index, slot) in composition.slots.enumerated() {
            guard let slotResult = generateSlot(slot) else {
                print("❌ Failed to generate slot \(index): \(slot.name)")
                return nil
            }
            slotNoteLists.append(slotResult.notes)
            slotTempos.append(slot.parameters.tempo)
            totalNoteCount += slotResult.notes.count
        }

        let concatenated = CompositionNoteBuilder.concatenateSlotNotes(slotNoteLists)
        let singlePassDuration = concatenated.notes.totalLength
        let repeatedNotes = CompositionNoteBuilder.applyRepeats(
            notes: concatenated.notes,
            count: composition.playbackRepeatCount
        )
        let markers = CompositionNoteBuilder.tempoMarkers(
            slotTempos: slotTempos,
            slotStartBeats: concatenated.slotStartBeats,
            singlePassDuration: singlePassDuration,
            repeatCount: composition.playbackRepeatCount
        )

        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        let pitches = repeatedNotes.soundingNotes.map(\.note)
        let pitchRange = (pitches.min() ?? 60)...(pitches.max() ?? 60)
        let slotNames = composition.slots.map(\.name).joined(separator: " → ")

        let metadata = PatternMetadata(
            generatorName: "Composition (\(composition.slots.count) patterns)",
            parameterHash: "composition-\(composition.slots.count)-\(composition.playbackRepeatCount)",
            generationTime: generationTime,
            noteCount: repeatedNotes.count,
            pitchRange: pitchRange,
            duration: repeatedNotes.totalLength,
            cycleIndex: 0,
            isCyclicalSequence: composition.playbackRepeatCount > 1 || composition.slots.count > 1,
            totalCycles: composition.playbackRepeatCount
        )

        let performance = PerformanceMetrics(
            generationTime: generationTime,
            memoryUsage: 0,
            complexity: Double(composition.slots.count * composition.playbackRepeatCount)
        )

        let result = PatternGenerationResult(
            notes: repeatedNotes,
            metadata: metadata,
            performance: performance
        )

        print("✅ Composition built: \(slotNames); \(repeatedNotes.count) notes; repeats=\(composition.playbackRepeatCount)")

        return CompositionBuildResult(
            result: result,
            tempoMarkers: markers,
            primaryParameters: composition.slots[0].parameters,
            singlePassDuration: singlePassDuration
        )
    }

    private func generateSlot(_ slot: PatternSlot) -> PatternGenerationResult? {
        let parameters = slot.parameters
        let generators = slot.generatorNames

        if parameters.isCyclicalGeneration {
            if generators.count > 1 {
                return cyclicalSequenceGenerator.generateCombinedCyclicalSequence(
                    baseParameters: parameters,
                    generatorNames: generators,
                    combinationMode: slot.combinationMode
                )
            }
            return cyclicalSequenceGenerator.generateCyclicalSequence(
                baseParameters: parameters,
                generatorName: slot.primaryGeneratorName
            )
        }

        if generators.count > 1 {
            return patternRegistry.generateCombinedPattern(
                using: generators,
                parameters: parameters,
                combinationMode: slot.combinationMode
            )
        }

        return patternRegistry.generatePattern(
            using: slot.primaryGeneratorName,
            parameters: parameters
        )
    }
}
