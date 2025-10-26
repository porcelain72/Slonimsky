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
        
        // Calculate the maximum number of cycles needed based on parameter ranges
        let maxCycles = calculateMaxCycles(for: enabledParameters)
        
        print("🔄 Generating cyclical sequence with \(maxCycles) cycles")
        
        var allNotes: [MIDIInfo] = []
        var totalGenerationTime: TimeInterval = 0.0
        var totalNoteCount = 0
        var actualCycles = 0
        
        // Generate patterns for each cycle
        for cycleIndex in 0..<maxCycles {
            print("🔄 Generating cycle \(cycleIndex + 1)/\(maxCycles)")

            // Check if any parameter would exceed its maximum value in the next cycle
            var shouldStop = false
            for (parameterType, settings) in enabledParameters {
                // Calculate the current value for this cycle
                let currentValue = settings.minValue + (Double(cycleIndex) * settings.stepSize)
                // Calculate the value for the next cycle
                let nextValue = settings.minValue + (Double(cycleIndex + 1) * settings.stepSize)
                
                if settings.cycleType == .increment && nextValue > settings.maxValue {
                    print("🔄 Parameter \(parameterType.rawValue) would exceed max value \(settings.maxValue) at cycle \(cycleIndex + 1)")
                    shouldStop = true
                    break
                } else if settings.cycleType == .decrement && nextValue < settings.minValue {
                    print("🔄 Parameter \(parameterType.rawValue) would exceed min value \(settings.minValue) at cycle \(cycleIndex + 1)")
                    shouldStop = true
                    break
                }
            }
            
            if shouldStop {
                print("🔄 Stopping generation: parameter reached maximum value")
                break
            }
            
            guard let cycleResult = patternRegistry.generatePattern(
                using: generatorName,
                parameters: baseParameters,
                cycleIndex: cycleIndex
            ) else {
                print("❌ Failed to generate pattern for cycle \(cycleIndex)")
                return nil
            }
            
            // Add cycle information to notes
            let cycleNotes = cycleResult.notes.map { note in
                var modifiedNote = note
                modifiedNote.cycleIndex = cycleIndex
                return modifiedNote
            }
            
            allNotes.append(contentsOf: cycleNotes)
            totalGenerationTime += cycleResult.metadata.generationTime
            totalNoteCount += cycleResult.metadata.noteCount
            actualCycles += 1
            
            print("✅ Cycle \(cycleIndex + 1): \(cycleResult.notes.count) notes")
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
        
        // Calculate the maximum number of cycles needed based on parameter ranges
        let maxCycles = calculateMaxCycles(for: enabledParameters)
        
        print("🔄 Generating combined cyclical sequence with \(maxCycles) cycles using \(generatorNames.count) generators")
        
        var allNotes: [MIDIInfo] = []
        var totalGenerationTime: TimeInterval = 0.0
        var totalNoteCount = 0
        var actualCycles = 0
        
        // Generate combined patterns for each cycle
        for cycleIndex in 0..<maxCycles {
            print("🔄 Generating combined cycle \(cycleIndex + 1)/\(maxCycles)")
            
            // Check if any parameter would exceed its maximum value in the next cycle
            var shouldStop = false
            for (parameterType, settings) in enabledParameters {
                // Calculate the current value for this cycle
                let currentValue = settings.minValue + (Double(cycleIndex) * settings.stepSize)
                // Calculate the value for the next cycle
                let nextValue = settings.minValue + (Double(cycleIndex + 1) * settings.stepSize)
                
                if settings.cycleType == .increment && nextValue > settings.maxValue {
                    print("🔄 Parameter \(parameterType.rawValue) would exceed max value \(settings.maxValue) at cycle \(cycleIndex + 1)")
                    shouldStop = true
                    break
                } else if settings.cycleType == .decrement && nextValue < settings.minValue {
                    print("🔄 Parameter \(parameterType.rawValue) would exceed min value \(settings.minValue) at cycle \(cycleIndex + 1)")
                    shouldStop = true
                    break
                }
            }
            
            if shouldStop {
                print("🔄 Stopping generation: parameter reached maximum value")
                break
            }
            
            guard let cycleResult = patternRegistry.generateCombinedPattern(
                using: generatorNames,
                parameters: baseParameters,
                combinationMode: combinationMode,
                cycleIndex: cycleIndex
            ) else {
                print("❌ Failed to generate combined pattern for cycle \(cycleIndex)")
                return nil
            }
            
            // Add cycle information to notes
            let cycleNotes = cycleResult.notes.map { note in
                var modifiedNote = note
                modifiedNote.cycleIndex = cycleIndex
                return modifiedNote
            }
            
            allNotes.append(contentsOf: cycleNotes)
            totalGenerationTime += cycleResult.metadata.generationTime
            totalNoteCount += cycleResult.metadata.noteCount
            actualCycles += 1
            
            print("✅ Combined cycle \(cycleIndex + 1): \(cycleResult.notes.count) notes")
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
    
    /// Calculate the maximum number of cycles needed based on parameter ranges
    private func calculateMaxCycles(for enabledParameters: [CyclicalParameterType: CyclicalParameterSettings]) -> Int {
        var maxCycles = 1
        
        for (_, settings) in enabledParameters {
            guard settings.isEnabled else { continue }
            
            let range = settings.maxValue - settings.minValue
            let cyclesNeeded = Int(ceil(range / settings.stepSize)) + 1
            
            maxCycles = max(maxCycles, cyclesNeeded)
        }
        
        return maxCycles
    }
} 