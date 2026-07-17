import Foundation

/// Generates sequences of patterns from phase-based cyclical parameter curves
/// and the additive/subtractive pattern process. Each enabled parameter follows
/// its own curve (period + shape); the process adds or removes notes per cycle.
/// The sequence runs until curves and process realign (lcm), capped at `cycleCap`.
class CyclicalSequenceGenerator {

    // MARK: - Constants

    /// Maximum number of pattern cycles a cyclical sequence may contain.
    static let cycleCap = 64

    // MARK: - Properties
    private let patternRegistry = PatternGeneratorRegistry.shared

    // MARK: - Public Methods

    /// Generate a complete cyclical sequence of patterns
    /// - Parameters:
    ///   - baseParameters: The base parameters for pattern generation
    ///   - generatorName: The name of the generator to use
    /// - Returns: A combined pattern result with all cycles
    func generateCyclicalSequence(
        baseParameters: PatternParameters,
        generatorName: String
    ) -> PatternGenerationResult? {

        guard baseParameters.isCyclicalGeneration else {
            // No cyclical curves or process active, generate single pattern
            return patternRegistry.generatePattern(using: generatorName, parameters: baseParameters)
        }

        // Reference generation (cycle 0) to size the pattern process
        guard let reference = patternRegistry.generatePattern(
            using: generatorName, parameters: baseParameters, cycleIndex: 0
        ) else {
            print("❌ Failed to generate reference pattern")
            return nil
        }
        let totalCycles = calculateTotalCycles(
            for: baseParameters,
            referenceSoundingCount: reference.notes.soundingNotes.count
        )
        logSequenceStart(totalCycles: totalCycles, parameters: baseParameters, generatorCount: 1)

        var allNotes: [MIDIInfo] = []
        var totalGenerationTime: TimeInterval = 0.0
        var totalNoteCount = 0
        var actualCycles = 0

        for cycleIndex in 0..<totalCycles {
            guard let cycleResult = patternRegistry.generatePattern(
                using: generatorName,
                parameters: baseParameters,
                cycleIndex: cycleIndex
            ) else {
                print("❌ Failed to generate pattern for cycle \(cycleIndex)")
                return nil
            }

            let processedNotes = applyProcess(
                to: cycleResult.notes,
                cycleIndex: cycleIndex,
                settings: baseParameters.processSettings
            )

            let notesToAppend = appendableNotes(
                from: processedNotes,
                cycleIndex: cycleIndex,
                isLastCycle: cycleIndex == totalCycles - 1,
                runningLength: allNotes.totalLength,
                dropSeamNote: baseParameters.processSettings.mode == .none
            )

            allNotes.append(contentsOf: notesToAppend)
            totalGenerationTime += cycleResult.metadata.generationTime
            totalNoteCount += notesToAppend.count
            actualCycles += 1
        }

        return buildResult(
            notes: allNotes,
            generatorName: generatorName,
            parameters: baseParameters,
            generationTime: totalGenerationTime,
            noteCount: totalNoteCount,
            cycles: actualCycles,
            generatorCount: 1
        )
    }

    /// Generate a cyclical sequence using multiple generators
    /// - Parameters:
    ///   - baseParameters: The base parameters for pattern generation
    ///   - generatorNames: The names of the generators to use
    ///   - combinationMode: How to combine the generators
    /// - Returns: A combined pattern result with all cycles
    func generateCombinedCyclicalSequence(
        baseParameters: PatternParameters,
        generatorNames: [String],
        combinationMode: PatternCombinationMode
    ) -> PatternGenerationResult? {

        guard baseParameters.isCyclicalGeneration else {
            // No cyclical curves or process active, generate single combined pattern
            return patternRegistry.generateCombinedPattern(
                using: generatorNames,
                parameters: baseParameters,
                combinationMode: combinationMode
            )
        }

        // Reference generation (cycle 0) to size the pattern process
        guard let reference = patternRegistry.generateCombinedPattern(
            using: generatorNames,
            parameters: baseParameters,
            combinationMode: combinationMode,
            cycleIndex: 0
        ) else {
            print("❌ Failed to generate reference pattern")
            return nil
        }
        let totalCycles = calculateTotalCycles(
            for: baseParameters,
            referenceSoundingCount: reference.notes.soundingNotes.count
        )
        logSequenceStart(totalCycles: totalCycles, parameters: baseParameters, generatorCount: generatorNames.count)

        var allNotes: [MIDIInfo] = []
        var totalGenerationTime: TimeInterval = 0.0
        var totalNoteCount = 0
        var actualCycles = 0

        for cycleIndex in 0..<totalCycles {
            guard let cycleResult = patternRegistry.generateCombinedPattern(
                using: generatorNames,
                parameters: baseParameters,
                combinationMode: combinationMode,
                cycleIndex: cycleIndex
            ) else {
                print("❌ Failed to generate combined pattern for cycle \(cycleIndex)")
                return nil
            }

            let processedNotes = applyProcess(
                to: cycleResult.notes,
                cycleIndex: cycleIndex,
                settings: baseParameters.processSettings
            )

            let notesToAppend = appendableNotes(
                from: processedNotes,
                cycleIndex: cycleIndex,
                isLastCycle: cycleIndex == totalCycles - 1,
                runningLength: allNotes.totalLength,
                dropSeamNote: baseParameters.processSettings.mode == .none
            )

            allNotes.append(contentsOf: notesToAppend)
            totalGenerationTime += cycleResult.metadata.generationTime
            totalNoteCount += notesToAppend.count
            actualCycles += 1
        }

        return buildResult(
            notes: allNotes,
            generatorName: generatorNames.joined(separator: " + "),
            parameters: baseParameters,
            generationTime: totalGenerationTime,
            noteCount: totalNoteCount,
            cycles: actualCycles,
            generatorCount: generatorNames.count
        )
    }

    // MARK: - Private Helper Methods

    /// Total cycles for a sequence: curve realignment (lcm of periods) merged
    /// with the pattern process's own cycle count via lcm, capped at `cycleCap`.
    private func calculateTotalCycles(for parameters: PatternParameters, referenceSoundingCount: Int) -> Int {
        let curveRealignment = parameters.cyclicalSettings.realignmentCycles
        let processCycles = parameters.processSettings.mode == .none
            ? 1
            : parameters.processSettings.cycleCount(forPatternLength: referenceSoundingCount)
        let combined = CyclicalSettings.lcm(curveRealignment, processCycles)
        if combined > CyclicalSequenceGenerator.cycleCap {
            print("⚠️ Cyclical realignment (\(combined) cycles) exceeds cap; truncating to \(CyclicalSequenceGenerator.cycleCap)")
            return CyclicalSequenceGenerator.cycleCap
        }
        return max(1, combined)
    }

    /// Truncate a cycle's scheduled events to the process's kept note count:
    /// keep events (notes and interleaved rests) up to and including the k-th
    /// sounding note, drop the rest. The cycle audibly grows/shrinks.
    private func applyProcess(to notes: [MIDIInfo], cycleIndex: Int, settings: ProcessSettings) -> [MIDIInfo] {
        guard settings.mode != .none else { return notes }
        let soundingCount = notes.soundingNotes.count
        guard soundingCount > 0 else { return notes }

        let keep = settings.keptNoteCount(atCycle: cycleIndex, patternLength: soundingCount)
        guard keep < soundingCount else { return notes }

        var kept: [MIDIInfo] = []
        var sounding = 0
        for event in notes {
            kept.append(event)
            if !event.isRest {
                sounding += 1
                if sounding >= keep { break }
            }
        }
        return kept
    }

    private func logSequenceStart(totalCycles: Int, parameters: PatternParameters, generatorCount: Int) {
        let paramSummary = parameters.cyclicalSettings.enabledParameters
            .map { "\($0.key.rawValue) (period \($0.value.period), \($0.value.shape.rawValue))" }
            .joined(separator: ", ")
        print("🔄 Generating cyclical sequence: \(totalCycles) cycles using \(generatorCount) generator(s)")
        if !paramSummary.isEmpty { print("   Curves: \(paramSummary)") }
        if parameters.processSettings.mode != .none {
            print("   Process: \(parameters.processSettings.mode.rawValue) (start \(parameters.processSettings.startCount), step \(parameters.processSettings.notesPerCycle))")
        }
    }

    /// Shift a cycle's notes onto the end of the running sequence and apply the
    /// drop-last-note rule (only the final cycle keeps its last sounding note,
    /// to avoid repeated notes at cycle seams; rests are never dropped).
    /// The rule is disabled while a pattern process is active — truncated cycles
    /// end exactly on the note the process added, which must be heard.
    private func appendableNotes(
        from notes: [MIDIInfo],
        cycleIndex: Int,
        isLastCycle: Bool,
        runningLength: Double,
        dropSeamNote: Bool
    ) -> [MIDIInfo] {
        let cycleNotes = notes.map { note -> MIDIInfo in
            var modifiedNote = note.offset(by: runningLength)
            modifiedNote.cycleIndex = cycleIndex
            return modifiedNote
        }

        if isLastCycle || !dropSeamNote {
            return cycleNotes
        } else if cycleNotes.count > 1, let last = cycleNotes.last, !last.isRest {
            return Array(cycleNotes.dropLast())
        } else {
            return cycleNotes
        }
    }

    private func buildResult(
        notes: [MIDIInfo],
        generatorName: String,
        parameters: PatternParameters,
        generationTime: TimeInterval,
        noteCount: Int,
        cycles: Int,
        generatorCount: Int
    ) -> PatternGenerationResult {
        let pitches = notes.soundingNotes.map(\.note)
        let pitchRange = (pitches.min() ?? 60)...(pitches.max() ?? 60)

        let combinedMetadata = PatternMetadata(
            generatorName: generatorName,
            parameterHash: parameters.hashValue.description,
            generationTime: generationTime,
            noteCount: noteCount,
            pitchRange: pitchRange,
            duration: notes.totalLength,
            cycleIndex: 0, // Base cycle for combined result
            isCyclicalSequence: true,
            totalCycles: cycles
        )

        let performance = PerformanceMetrics(
            generationTime: generationTime,
            memoryUsage: 0, // We don't track memory usage in cyclical generation
            complexity: Double(cycles) * Double(generatorCount)
        )

        print("✅ Generated cyclical sequence: \(notes.count) total notes across \(cycles) cycles")

        return PatternGenerationResult(
            notes: notes,
            metadata: combinedMetadata,
            performance: performance
        )
    }
}
