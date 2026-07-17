import Foundation

/// Generates sequences of patterns based on phase-based cyclical parameter curves.
/// Each enabled parameter follows its own curve (period + shape); the sequence
/// runs until all curves realign (lcm of the periods), capped at `cycleCap`.
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

        let enabledParameters = baseParameters.cyclicalSettings.enabledParameters
        guard !enabledParameters.isEmpty else {
            // No cyclical parameters enabled, generate single pattern
            return patternRegistry.generatePattern(using: generatorName, parameters: baseParameters)
        }

        let totalCycles = calculateTotalCycles(for: baseParameters.cyclicalSettings)
        logSequenceStart(totalCycles: totalCycles, settings: baseParameters.cyclicalSettings, generatorCount: 1)

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

            let notesToAppend = appendableNotes(
                from: cycleResult.notes,
                cycleIndex: cycleIndex,
                isLastCycle: cycleIndex == totalCycles - 1,
                runningLength: allNotes.totalLength
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

        let enabledParameters = baseParameters.cyclicalSettings.enabledParameters
        guard !enabledParameters.isEmpty else {
            // No cyclical parameters enabled, generate single combined pattern
            return patternRegistry.generateCombinedPattern(
                using: generatorNames,
                parameters: baseParameters,
                combinationMode: combinationMode
            )
        }

        let totalCycles = calculateTotalCycles(for: baseParameters.cyclicalSettings)
        logSequenceStart(totalCycles: totalCycles, settings: baseParameters.cyclicalSettings, generatorCount: generatorNames.count)

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

            let notesToAppend = appendableNotes(
                from: cycleResult.notes,
                cycleIndex: cycleIndex,
                isLastCycle: cycleIndex == totalCycles - 1,
                runningLength: allNotes.totalLength
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

    /// Total cycles for a sequence: all enabled curves realign at the lcm of
    /// their periods, capped at `cycleCap`.
    private func calculateTotalCycles(for settings: CyclicalSettings) -> Int {
        let realignment = settings.realignmentCycles
        if realignment > CyclicalSequenceGenerator.cycleCap {
            print("⚠️ Cyclical realignment (\(realignment) cycles) exceeds cap; truncating to \(CyclicalSequenceGenerator.cycleCap)")
            return CyclicalSequenceGenerator.cycleCap
        }
        return max(1, realignment)
    }

    private func logSequenceStart(totalCycles: Int, settings: CyclicalSettings, generatorCount: Int) {
        let paramSummary = settings.enabledParameters
            .map { "\($0.key.rawValue) (period \($0.value.period), \($0.value.shape.rawValue))" }
            .joined(separator: ", ")
        print("🔄 Generating cyclical sequence: \(totalCycles) cycles (curves realign at lcm of periods) using \(generatorCount) generator(s)")
        print("   Curves: \(paramSummary)")
    }

    /// Shift a cycle's notes onto the end of the running sequence and apply the
    /// drop-last-note rule (only the final cycle keeps its last sounding note,
    /// to avoid repeated notes at cycle seams; rests are never dropped).
    private func appendableNotes(
        from notes: [MIDIInfo],
        cycleIndex: Int,
        isLastCycle: Bool,
        runningLength: Double
    ) -> [MIDIInfo] {
        let cycleNotes = notes.map { note -> MIDIInfo in
            var modifiedNote = note.offset(by: runningLength)
            modifiedNote.cycleIndex = cycleIndex
            return modifiedNote
        }

        if isLastCycle {
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
