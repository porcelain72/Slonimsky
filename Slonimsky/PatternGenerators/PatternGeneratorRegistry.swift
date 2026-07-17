//
//  PatternGeneratorRegistry.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Registry for managing all available pattern generators
class PatternGeneratorRegistry: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PatternGeneratorRegistry()
    
    // MARK: - Properties
    @Published private(set) var generators: [String: PatternGenerator] = [:]
    @Published private(set) var generatorNames: [String] = []
    
    // MARK: - Initialization
    private init() {
        registerDefaultGenerators()
    }
    
    // MARK: - Public Methods
    
    /// Register a new pattern generator
    /// - Parameter generator: The pattern generator to register
    func register(_ generator: PatternGenerator) {
        generators[generator.name] = generator
        updateGeneratorNames()
    }
    
    /// Unregister a pattern generator
    /// - Parameter name: The name of the generator to unregister
    func unregister(name: String) {
        generators.removeValue(forKey: name)
        updateGeneratorNames()
    }
    
    /// Get a pattern generator by name
    /// - Parameter name: The name of the generator
    /// - Returns: The pattern generator if found
    func getGenerator(name: String) -> PatternGenerator? {
        return generators[name]
    }
    
    /// Get all available generator names
    /// - Returns: Array of generator names
    func getAllGeneratorNames() -> [String] {
        return generatorNames
    }
    
    /// Generate a pattern using a specific generator
    /// - Parameters:
    ///   - generatorName: The name of the generator to use
    ///   - parameters: The pattern generation parameters
    /// - Returns: Generated pattern result with metadata
    func generatePattern(
        using generatorName: String,
        parameters: PatternParameters
    ) -> PatternGenerationResult? {
        return generatePattern(using: generatorName, parameters: parameters, cycleIndex: 0)
    }
    
    /// Generate a pattern using a specific generator with cyclical parameters
    /// - Parameters:
    ///   - generatorName: The name of the generator to use
    ///   - parameters: The pattern generation parameters
    ///   - cycleIndex: The current cycle index for cyclical parameters
    /// - Returns: Generated pattern result with metadata
    func generatePattern(
        using generatorName: String,
        parameters: PatternParameters,
        cycleIndex: Int
    ) -> PatternGenerationResult? {
        guard let generator = getGenerator(name: generatorName) else {
            print("❌ Pattern generator '\(generatorName)' not found")
            return nil
        }
        
        guard generator.validateParameters(parameters: parameters) else {
            print("❌ Invalid parameters for generator '\(generatorName)'")
            return nil
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getMemoryUsage()
        
        let notes = generator.generatePattern(parameters: parameters, cycleIndex: cycleIndex)
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        let endMemory = getMemoryUsage()
        let memoryUsage = endMemory - startMemory
        
        let pitches = notes.soundingNotes.map(\.note)
        let metadata = PatternMetadata(
            generatorName: generatorName,
            parameterHash: parameters.hashValue.description,
            generationTime: generationTime,
            noteCount: notes.count,
            pitchRange: (pitches.min() ?? 60)...(pitches.max() ?? 60),
            duration: notes.totalLength,
            cycleIndex: cycleIndex
        )
        
        let performance = PerformanceMetrics(
            generationTime: generationTime,
            memoryUsage: memoryUsage,
            complexity: calculateComplexity(parameters: parameters)
        )
        
        return PatternGenerationResult(
            notes: notes,
            metadata: metadata,
            performance: performance
        )
    }
    
    /// Generate patterns using multiple generators and combine results
    /// - Parameters:
    ///   - generatorNames: Array of generator names to use
    ///   - parameters: The pattern generation parameters
    ///   - combinationMode: How to combine the patterns
    /// - Returns: Combined pattern result
    func generateCombinedPattern(
        using generatorNames: [String],
        parameters: PatternParameters,
        combinationMode: PatternCombinationMode = .sequential
    ) -> PatternGenerationResult? {
        var allNotes: [MIDIInfo] = []
        var totalGenerationTime: TimeInterval = 0
        var totalMemoryUsage: Int64 = 0
        var allPitchRanges: [ClosedRange<Int>] = []
        
        for generatorName in generatorNames {
            guard let result = generatePattern(using: generatorName, parameters: parameters) else {
                continue
            }
            
            switch combinationMode {
            case .sequential:
                let offset = allNotes.totalLength
                allNotes.append(contentsOf: result.notes.map { $0.offset(by: offset) })
            case .layered:
                allNotes = layerNotes(allNotes, with: result.notes)
            }
            
            totalGenerationTime += result.performance.generationTime
            totalMemoryUsage += result.performance.memoryUsage
            allPitchRanges.append(result.metadata.pitchRange)
        }
        
        guard !allNotes.isEmpty else { return nil }
        
        let combinedPitchRange = allPitchRanges.reduce(allPitchRanges[0]) { range1, range2 in
            min(range1.lowerBound, range2.lowerBound)...max(range1.upperBound, range2.upperBound)
        }
        
        let metadata = PatternMetadata(
            generatorName: "Combined (\(generatorNames.joined(separator: ", ")))",
            parameterHash: parameters.hashValue.description,
            generationTime: totalGenerationTime,
            noteCount: allNotes.count,
            pitchRange: combinedPitchRange,
            duration: allNotes.totalLength
        )
        
        let performance = PerformanceMetrics(
            generationTime: totalGenerationTime,
            memoryUsage: totalMemoryUsage,
            complexity: calculateComplexity(parameters: parameters) * Double(generatorNames.count)
        )
        
        return PatternGenerationResult(
            notes: allNotes,
            metadata: metadata,
            performance: performance
        )
    }
    
    /// Generate a combined pattern using multiple generators with cyclical parameters
    /// - Parameters:
    ///   - generatorNames: Array of generator names to use
    ///   - parameters: The pattern generation parameters
    ///   - combinationMode: How to combine the patterns
    ///   - cycleIndex: The current cycle index for cyclical parameters
    /// - Returns: Combined pattern result
    func generateCombinedPattern(
        using generatorNames: [String],
        parameters: PatternParameters,
        combinationMode: PatternCombinationMode = .sequential,
        cycleIndex: Int = 0
    ) -> PatternGenerationResult? {
        var allNotes: [MIDIInfo] = []
        var totalGenerationTime: TimeInterval = 0
        var totalMemoryUsage: Int64 = 0
        var allPitchRanges: [ClosedRange<Int>] = []
        
        for generatorName in generatorNames {
            guard let result = generatePattern(using: generatorName, parameters: parameters, cycleIndex: cycleIndex) else {
                continue
            }
            
            switch combinationMode {
            case .sequential:
                let offset = allNotes.totalLength
                allNotes.append(contentsOf: result.notes.map { $0.offset(by: offset) })
            case .layered:
                allNotes = layerNotes(allNotes, with: result.notes)
            }
            
            totalGenerationTime += result.performance.generationTime
            totalMemoryUsage += result.performance.memoryUsage
            allPitchRanges.append(result.metadata.pitchRange)
        }
        
        guard !allNotes.isEmpty else { return nil }
        
        let combinedPitchRange = allPitchRanges.reduce(allPitchRanges[0]) { range1, range2 in
            min(range1.lowerBound, range2.lowerBound)...max(range1.upperBound, range2.upperBound)
        }
        
        let metadata = PatternMetadata(
            generatorName: "Combined (\(generatorNames.joined(separator: ", ")))",
            parameterHash: parameters.hashValue.description,
            generationTime: totalGenerationTime,
            noteCount: allNotes.count,
            pitchRange: combinedPitchRange,
            duration: allNotes.totalLength,
            cycleIndex: cycleIndex
        )
        
        let performance = PerformanceMetrics(
            generationTime: totalGenerationTime,
            memoryUsage: totalMemoryUsage,
            complexity: calculateComplexity(parameters: parameters) * Double(generatorNames.count)
        )
        
        return PatternGenerationResult(
            notes: allNotes,
            metadata: metadata,
            performance: performance
        )
    }
    
    /// Get generator information for UI display
    /// - Returns: Array of generator info objects
    func getGeneratorInfo() -> [GeneratorInfo] {
        return generatorNames.compactMap { name in
            guard let generator = generators[name] else { return nil }
            return GeneratorInfo(
                name: generator.name,
                description: generator.description,
                isAvailable: true
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func registerDefaultGenerators() {
        register(ScalePatternGenerator())
        register(IntervalPatternGenerator())
        register(ModulationPatternGenerator())
        register(HarmonicPatternGenerator())
        register(ContourPatternGenerator())
        register(SymmetricalPatternGenerator())
    }
    
    private func updateGeneratorNames() {
        generatorNames = Array(generators.keys).sorted()
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    private func calculateComplexity(parameters: PatternParameters) -> Double {
        var complexity = 1.0
        
        // Scale complexity based on number of octaves and divisions
        complexity *= Double(parameters.numberOfOctaves)
        complexity *= Double(parameters.divisionsOfOctave) / 12.0
        
        // Modulation complexity
        if parameters.interpolation.enabled {
            complexity *= Double(parameters.interpolation.numberOfNotes + 1)
        }
        if parameters.infrapolation.enabled {
            complexity *= Double(parameters.infrapolation.numberOfNotes + 1)
        }
        if parameters.ultrapolation.enabled {
            complexity *= Double(parameters.ultrapolation.numberOfNotes + 1)
        }
        
        // Directional complexity
        if parameters.mirrorPoints > 0 {
            complexity *= Double(parameters.mirrorPoints + 1)
        }
        if parameters.symmetricalIntervals {
            complexity *= 2.0
        }
        
        return complexity
    }
    
    private func layerNotes(_ notes1: [MIDIInfo], with notes2: [MIDIInfo]) -> [MIDIInfo] {
        // True layering: both patterns keep their onsets and play simultaneously.
        // Drop exact duplicates (same onset and pitch) so MusicSequence doesn't
        // receive doubled note-ons.
        var result = notes1

        for note in notes2 {
            let isDuplicate = !note.isRest && result.contains {
                !$0.isRest && $0.note == note.note && abs($0.onset - note.onset) < 1e-6
            }
            if !isDuplicate {
                result.append(note)
            }
        }

        return result.sorted { $0.onset < $1.onset }
    }
}

// MARK: - Supporting Types

/// Modes for combining multiple patterns
enum PatternCombinationMode: String, CaseIterable {
    case sequential = "Sequential"
    case layered = "Layered"
}

/// Information about a pattern generator for UI display
struct GeneratorInfo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let isAvailable: Bool
} 