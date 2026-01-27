import Foundation

/// Generates sequences of patterns based on cyclical parameter settings
class CyclicalSequenceGenerator {
    
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
        
        // Calculate total cycles needed (product of all parameter cycles for nested cycling)
        let parameterCycleInfo = calculateNestedCycles(for: enabledParameters)
        let totalCycles = parameterCycleInfo.totalCycles
        
        print("🔄 Generating cyclical sequence with \(totalCycles) total cycles (nested/Cartesian product)")
        print("   Parameters will cycle in nested order: \(parameterCycleInfo.parameterOrder.map { $0.rawValue }.joined(separator: " (outer) -> ")) (inner)")
        print("   Each parameter cycles fully before the next parameter increments")
        
        var allNotes: [MIDIInfo] = []
        var totalGenerationTime: TimeInterval = 0.0
        var totalNoteCount = 0
        var actualCycles = 0
        
        // Generate patterns for each global cycle
        for globalCycleIndex in 0..<totalCycles {
            // Map global cycle index to individual parameter cycle indices using nested loop logic
            let parameterCycles = mapGlobalCycleToNestedParameterCycles(
                globalCycleIndex: globalCycleIndex,
                cycleInfo: parameterCycleInfo
            )
            
            print("🔄 Generating cycle \(globalCycleIndex + 1)/\(totalCycles)")
            for (paramType, localCycle) in parameterCycles {
                if let settings = enabledParameters[paramType] {
                    let value = settings.minValue + (Double(localCycle) * settings.stepSize)
                    print("   \(paramType.rawValue): cycle \(localCycle) (value: \(value))")
                }
            }
            
            guard let cycleResult = patternRegistry.generatePattern(
                using: generatorName,
                parameters: baseParameters,
                cycleIndex: globalCycleIndex,
                parameterCycles: parameterCycles
            ) else {
                print("❌ Failed to generate pattern for cycle \(globalCycleIndex)")
                return nil
            }
            
            // Add cycle information to notes
            let cycleNotes = cycleResult.notes.map { note in
                var modifiedNote = note
                modifiedNote.cycleIndex = globalCycleIndex
                return modifiedNote
            }
            
            // Drop the last note of each appended cycle sequence to avoid repetition
            // (only the last cycle should retain its final note)
            let notesToAppend: [MIDIInfo]
            let isLastCycle = (globalCycleIndex == totalCycles - 1)
            
            if isLastCycle {
                // Last cycle: append all notes (retain final note)
                notesToAppend = cycleNotes
            } else if cycleNotes.count > 1 {
                // Not the last cycle: drop the last note to avoid repetition
                notesToAppend = Array(cycleNotes.dropLast())
            } else {
                // If only one note, keep it (can't drop it)
                notesToAppend = cycleNotes
            }
            
            allNotes.append(contentsOf: notesToAppend)
            totalGenerationTime += cycleResult.metadata.generationTime
            totalNoteCount += notesToAppend.count
            actualCycles += 1
            
            let dropStatus = isLastCycle ? "retained (last cycle)" : "dropped"
            print("✅ Cycle \(globalCycleIndex + 1): \(cycleResult.notes.count) notes generated, \(notesToAppend.count) notes appended (last note \(dropStatus))")
        }
        
        // Create combined metadata
        let pitchRangeTuple = calculatePitchRange(notes: allNotes)
        let pitchRange = pitchRangeTuple.min...pitchRangeTuple.max
        
        let combinedMetadata = PatternMetadata(
            generatorName: generatorName,
            parameterHash: baseParameters.hashValue.description,
            generationTime: totalGenerationTime,
            noteCount: totalNoteCount,
            pitchRange: pitchRange,
            duration: calculateTotalDuration(notes: allNotes),
            cycleIndex: 0, // Base cycle for combined result
            isCyclicalSequence: true,
            totalCycles: actualCycles
        )
        
        let performance = PerformanceMetrics(
            generationTime: totalGenerationTime,
            memoryUsage: 0, // We don't track memory usage in cyclical generation
            complexity: Double(actualCycles)
        )
        
        print("✅ Generated cyclical sequence: \(allNotes.count) total notes across \(actualCycles) cycles")
        
        return PatternGenerationResult(
            notes: allNotes,
            metadata: combinedMetadata,
            performance: performance
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
        
        // Calculate total cycles needed (product of all parameter cycles for nested cycling)
        let parameterCycleInfo = calculateNestedCycles(for: enabledParameters)
        let totalCycles = parameterCycleInfo.totalCycles
        
        print("🔄 Generating combined cyclical sequence with \(totalCycles) total cycles (nested/Cartesian product) using \(generatorNames.count) generators")
        print("   Parameters will cycle in nested order: \(parameterCycleInfo.parameterOrder.map { $0.rawValue }.joined(separator: " (outer) -> ")) (inner)")
        print("   Each parameter cycles fully before the next parameter increments")
        
        var allNotes: [MIDIInfo] = []
        var totalGenerationTime: TimeInterval = 0.0
        var totalNoteCount = 0
        var actualCycles = 0
        
        // Generate combined patterns for each global cycle
        for globalCycleIndex in 0..<totalCycles {
            // Map global cycle index to individual parameter cycle indices using nested loop logic
            let parameterCycles = mapGlobalCycleToNestedParameterCycles(
                globalCycleIndex: globalCycleIndex,
                cycleInfo: parameterCycleInfo
            )
            
            print("🔄 Generating combined cycle \(globalCycleIndex + 1)/\(totalCycles)")
            for (paramType, localCycle) in parameterCycles {
                if let settings = enabledParameters[paramType] {
                    let value = settings.minValue + (Double(localCycle) * settings.stepSize)
                    print("   \(paramType.rawValue): cycle \(localCycle) (value: \(value))")
                }
            }
            
            guard let cycleResult = patternRegistry.generateCombinedPattern(
                using: generatorNames,
                parameters: baseParameters,
                combinationMode: combinationMode,
                cycleIndex: globalCycleIndex,
                parameterCycles: parameterCycles
            ) else {
                print("❌ Failed to generate combined pattern for cycle \(globalCycleIndex)")
                return nil
            }
            
            // Add cycle information to notes
            let cycleNotes = cycleResult.notes.map { note in
                var modifiedNote = note
                modifiedNote.cycleIndex = globalCycleIndex
                return modifiedNote
            }
            
            // Drop the last note of each appended cycle sequence to avoid repetition
            // (only the last cycle should retain its final note)
            let notesToAppend: [MIDIInfo]
            let isLastCycle = (globalCycleIndex == totalCycles - 1)
            
            if isLastCycle {
                // Last cycle: append all notes (retain final note)
                notesToAppend = cycleNotes
            } else if cycleNotes.count > 1 {
                // Not the last cycle: drop the last note to avoid repetition
                notesToAppend = Array(cycleNotes.dropLast())
            } else {
                // If only one note, keep it (can't drop it)
                notesToAppend = cycleNotes
            }
            
            allNotes.append(contentsOf: notesToAppend)
            totalGenerationTime += cycleResult.metadata.generationTime
            totalNoteCount += notesToAppend.count
            actualCycles += 1
            
            let dropStatus = isLastCycle ? "retained (last cycle)" : "dropped"
            print("✅ Combined cycle \(globalCycleIndex + 1): \(cycleResult.notes.count) notes generated, \(notesToAppend.count) notes appended (last note \(dropStatus))")
        }
        
        // Create combined metadata
        let pitchRangeTuple = calculatePitchRange(notes: allNotes)
        let pitchRange = pitchRangeTuple.min...pitchRangeTuple.max
        
        let combinedMetadata = PatternMetadata(
            generatorName: generatorNames.joined(separator: " + "),
            parameterHash: baseParameters.hashValue.description,
            generationTime: totalGenerationTime,
            noteCount: totalNoteCount,
            pitchRange: pitchRange,
            duration: calculateTotalDuration(notes: allNotes),
            cycleIndex: 0, // Base cycle for combined result
            isCyclicalSequence: true,
            totalCycles: actualCycles
        )
        
        let performance = PerformanceMetrics(
            generationTime: totalGenerationTime,
            memoryUsage: 0, // We don't track memory usage in cyclical generation
            complexity: Double(actualCycles) * Double(generatorNames.count)
        )
        
        print("✅ Generated combined cyclical sequence: \(allNotes.count) total notes across \(actualCycles) cycles")
        
        return PatternGenerationResult(
            notes: allNotes,
            metadata: combinedMetadata,
            performance: performance
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func calculatePitchRange(notes: [MIDIInfo]) -> (min: Int, max: Int) {
        guard !notes.isEmpty else { return (0, 0) }
        
        let pitches = notes.map { $0.note }
        let minPitch = pitches.min() ?? 0
        let maxPitch = pitches.max() ?? 0
        
        return (minPitch, maxPitch)
    }
    
    private func calculateTotalDuration(notes: [MIDIInfo]) -> TimeInterval {
        return notes.reduce(0.0) { $0 + $1.beatLength }
    }
    
    /// Information about nested parameter cycling
    private struct ParameterCycleInfo {
        let parameterOrder: [CyclicalParameterType]  // Left to right: slowest (outer) to fastest (inner)
        let cyclesPerParameter: [CyclicalParameterType: Int]
        let totalCycles: Int
    }
    
    /// Calculate nested cycles: product of all parameter cycles (Cartesian product)
    /// Parameters are ordered from slowest (outer loop) to fastest (inner loop)
    private func calculateNestedCycles(for enabledParameters: [CyclicalParameterType: CyclicalParameterSettings]) -> ParameterCycleInfo {
        var parameterOrder: [CyclicalParameterType] = []
        var cyclesPerParameter: [CyclicalParameterType: Int] = [:]
        var totalCycles = 1
        
        // Process parameters in order (sorted by type for consistency)
        // Leftmost parameter cycles slowest (outer loop), rightmost cycles fastest (inner loop)
        let sortedParameters = enabledParameters.sorted { $0.key.rawValue < $1.key.rawValue }
        
        for (parameterType, settings) in sortedParameters {
            guard settings.isEnabled else { continue }
            
            let range = settings.maxValue - settings.minValue
            let cyclesNeeded = Int(ceil(range / settings.stepSize)) + 1
            
            parameterOrder.append(parameterType)
            cyclesPerParameter[parameterType] = cyclesNeeded
            totalCycles *= cyclesNeeded
        }
        
        return ParameterCycleInfo(
            parameterOrder: parameterOrder,
            cyclesPerParameter: cyclesPerParameter,
            totalCycles: totalCycles
        )
    }
    
    /// Map global cycle index to individual parameter cycle indices using nested loop logic
    /// Rightmost parameter cycles fastest, leftmost cycles slowest
    /// Example: For A, B, C (each 0-3):
    ///   C = globalCycleIndex % cycles_C (cycles fastest)
    ///   B = (globalCycleIndex / cycles_C) % cycles_B
    ///   A = (globalCycleIndex / (cycles_C * cycles_B)) % cycles_A
    private func mapGlobalCycleToNestedParameterCycles(
        globalCycleIndex: Int,
        cycleInfo: ParameterCycleInfo
    ) -> [CyclicalParameterType: Int] {
        var parameterCycles: [CyclicalParameterType: Int] = [:]
        
        // Reverse order to process from rightmost (fastest) to leftmost (slowest)
        let reversedOrder = cycleInfo.parameterOrder.reversed()
        var divisor = 1
        
        for parameterType in reversedOrder {
            guard let cyclesNeeded = cycleInfo.cyclesPerParameter[parameterType] else {
                continue
            }
            
            // Calculate this parameter's cycle index
            // Rightmost parameter: globalCycleIndex % cyclesNeeded
            // Next parameter: (globalCycleIndex / cyclesNeeded_rightmost) % cyclesNeeded
            // And so on...
            let cycleIndex = (globalCycleIndex / divisor) % cyclesNeeded
            parameterCycles[parameterType] = cycleIndex
            
            // Update divisor for next parameter (moving left)
            divisor *= cyclesNeeded
        }
        
        return parameterCycles
    }
} 