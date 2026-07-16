import Foundation
import Combine

/// Manages cyclical parameter changes during pattern generation
class CyclicalParameterManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentCycle: Int = 0
    @Published var isCyclingEnabled: Bool = false
    @Published var cycleProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var cyclicalSettings: CyclicalSettings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(cyclicalSettings: CyclicalSettings = CyclicalSettings()) {
        self.cyclicalSettings = cyclicalSettings
        self.isCyclingEnabled = !cyclicalSettings.enabledParameters.isEmpty
    }
    
    // MARK: - Public Methods
    
    /// Update cyclical settings
    func updateSettings(_ settings: CyclicalSettings) {
        cyclicalSettings = settings
        isCyclingEnabled = !settings.enabledParameters.isEmpty
        resetCycle()
    }
    
    /// Get the current parameter value with cyclical adjustments applied
    func getCurrentValue(for parameterName: String, baseValue: Double) -> Double {
        guard isCyclingEnabled else { return baseValue }
        
        switch parameterName {
        case "interpolationNotes":
            return cyclicalSettings.interpolationNotes.currentValue(baseValue: baseValue)
        case "infrapolationNotes":
            return cyclicalSettings.infrapolationNotes.currentValue(baseValue: baseValue)
        case "ultrapolationNotes":
            return cyclicalSettings.ultrapolationNotes.currentValue(baseValue: baseValue)
        case "modulationInterval":
            return cyclicalSettings.modulationInterval.currentValue(baseValue: baseValue)
        case "baseNoteDuration":
            return cyclicalSettings.baseNoteDuration.currentValue(baseValue: baseValue)
        case "primaryInterval":
            return cyclicalSettings.primaryInterval.currentValue(baseValue: Double(baseValue))
        case "secondaryInterval":
            return cyclicalSettings.secondaryInterval.currentValue(baseValue: Double(baseValue))
        case "baseVelocity":
            return cyclicalSettings.baseVelocity.currentValue(baseValue: baseValue)
        case "velocityRange":
            return cyclicalSettings.velocityRange.currentValue(baseValue: baseValue)
        case "tempo":
            return cyclicalSettings.tempo.currentValue(baseValue: baseValue)
        case "rootNote":
            return cyclicalSettings.rootNote.currentValue(baseValue: baseValue)
        case "numberOfOctaves":
            return cyclicalSettings.numberOfOctaves.currentValue(baseValue: baseValue)
        case "divisionsOfOctave":
            return cyclicalSettings.divisionsOfOctave.currentValue(baseValue: baseValue)
        case "mirrorPoints":
            return cyclicalSettings.mirrorPoints.currentValue(baseValue: baseValue)
        case "euclideanRotation":
            return cyclicalSettings.euclideanRotation.currentValue(baseValue: baseValue)
        default:
            return baseValue
        }
    }
    
    /// Get modified parameters for the current cycle
    /// - Parameters:
    ///   - baseParameters: The base parameters to modify
    ///   - parameterCycles: Optional mapping of parameter types to their individual cycle indices (for sequential cycling)
    /// - Returns: Modified parameters with cyclical changes applied
    func getModifiedParameters(from baseParameters: PatternParameters, parameterCycles: [CyclicalParameterType: Int]? = nil) -> PatternParameters {
        guard isCyclingEnabled else { return baseParameters }
        
        var modifiedSettings = cyclicalSettings
        
        // If parameterCycles is provided, use individual cycle indices for sequential cycling
        // Otherwise, use the global currentCycle for parallel cycling (backward compatibility)
        if let parameterCycles = parameterCycles {
            // Sequential cycling: each parameter uses its own cycle index
            modifiedSettings.interpolationNotes.currentCycle = parameterCycles[.interpolationNotes] ?? 0
            modifiedSettings.infrapolationNotes.currentCycle = parameterCycles[.infrapolationNotes] ?? 0
            modifiedSettings.ultrapolationNotes.currentCycle = parameterCycles[.ultrapolationNotes] ?? 0
            modifiedSettings.modulationInterval.currentCycle = parameterCycles[.modulationInterval] ?? 0
            modifiedSettings.baseNoteDuration.currentCycle = parameterCycles[.baseNoteDuration] ?? 0
            modifiedSettings.primaryInterval.currentCycle = parameterCycles[.primaryInterval] ?? 0
            modifiedSettings.secondaryInterval.currentCycle = parameterCycles[.secondaryInterval] ?? 0
            modifiedSettings.baseVelocity.currentCycle = parameterCycles[.baseVelocity] ?? 0
            modifiedSettings.velocityRange.currentCycle = parameterCycles[.velocityRange] ?? 0
            modifiedSettings.tempo.currentCycle = parameterCycles[.tempo] ?? 0
            modifiedSettings.rootNote.currentCycle = parameterCycles[.rootNote] ?? 0
            modifiedSettings.numberOfOctaves.currentCycle = parameterCycles[.numberOfOctaves] ?? 0
            modifiedSettings.divisionsOfOctave.currentCycle = parameterCycles[.divisionsOfOctave] ?? 0
            modifiedSettings.mirrorPoints.currentCycle = parameterCycles[.mirrorPoints] ?? 0
            modifiedSettings.euclideanRotation.currentCycle = parameterCycles[.euclideanRotation] ?? 0
        } else {
            // Parallel cycling: all parameters use the same cycle index
            modifiedSettings.interpolationNotes.currentCycle = currentCycle
            modifiedSettings.infrapolationNotes.currentCycle = currentCycle
            modifiedSettings.ultrapolationNotes.currentCycle = currentCycle
            modifiedSettings.modulationInterval.currentCycle = currentCycle
            modifiedSettings.baseNoteDuration.currentCycle = currentCycle
            modifiedSettings.primaryInterval.currentCycle = currentCycle
            modifiedSettings.secondaryInterval.currentCycle = currentCycle
            modifiedSettings.baseVelocity.currentCycle = currentCycle
            modifiedSettings.velocityRange.currentCycle = currentCycle
            modifiedSettings.tempo.currentCycle = currentCycle
            modifiedSettings.rootNote.currentCycle = currentCycle
            modifiedSettings.numberOfOctaves.currentCycle = currentCycle
            modifiedSettings.divisionsOfOctave.currentCycle = currentCycle
            modifiedSettings.mirrorPoints.currentCycle = currentCycle
            modifiedSettings.euclideanRotation.currentCycle = currentCycle
        }
        
        // Create modified modulation settings
        let modifiedInterpolation = ModulationSettings(
            numberOfNotes: Int(modifiedSettings.interpolationNotes.currentValue(baseValue: Double(baseParameters.interpolation.numberOfNotes))),
            interval: Int(modifiedSettings.modulationInterval.currentValue(baseValue: Double(baseParameters.interpolation.interval))),
            enabled: baseParameters.interpolation.enabled
        )
        
        let modifiedInfrapolation = ModulationSettings(
            numberOfNotes: Int(modifiedSettings.infrapolationNotes.currentValue(baseValue: Double(baseParameters.infrapolation.numberOfNotes))),
            interval: Int(modifiedSettings.modulationInterval.currentValue(baseValue: Double(baseParameters.infrapolation.interval))),
            enabled: baseParameters.infrapolation.enabled
        )
        
        let modifiedUltrapolation = ModulationSettings(
            numberOfNotes: Int(modifiedSettings.ultrapolationNotes.currentValue(baseValue: Double(baseParameters.ultrapolation.numberOfNotes))),
            interval: Int(modifiedSettings.modulationInterval.currentValue(baseValue: Double(baseParameters.ultrapolation.interval))),
            enabled: baseParameters.ultrapolation.enabled
        )
        
        // Create modified velocity settings
        let modifiedVelocitySettings = VelocitySettings(
            baseVelocity: UInt8(modifiedSettings.baseVelocity.currentValue(baseValue: Double(baseParameters.velocitySettings.baseVelocity))),
            range: UInt8(modifiedSettings.velocityRange.currentValue(baseValue: Double(baseParameters.velocitySettings.range))),
            waveDepth: baseParameters.velocitySettings.waveDepth,
            randomness: baseParameters.velocitySettings.randomness,
            phase: baseParameters.velocitySettings.phase,
            emphasisBeat: baseParameters.velocitySettings.emphasisBeat,
            emphasisAmount: baseParameters.velocitySettings.emphasisAmount
        )
        
        // Apply cycled Euclidean rotation to the rhythm settings
        var modifiedRhythmSettings = baseParameters.rhythmSettings
        modifiedRhythmSettings.euclideanRotation = Int(
            modifiedSettings.euclideanRotation.currentValue(
                baseValue: Double(baseParameters.rhythmSettings.euclideanRotation)
            )
        )
        
        return PatternParameters(
            rootNote: Int(modifiedSettings.rootNote.currentValue(baseValue: Double(baseParameters.rootNote))),
            scaleType: baseParameters.scaleType,
            numberOfOctaves: Int(modifiedSettings.numberOfOctaves.currentValue(baseValue: Double(baseParameters.numberOfOctaves))),
            divisionsOfOctave: Int(modifiedSettings.divisionsOfOctave.currentValue(baseValue: Double(baseParameters.divisionsOfOctave))),
            tempo: modifiedSettings.tempo.currentValue(baseValue: baseParameters.tempo),
            meter: baseParameters.meter,
            iterations: baseParameters.iterations,
            randomiseOrder: baseParameters.randomiseOrder,
            primaryInterval: Int(modifiedSettings.primaryInterval.currentValue(baseValue: Double(baseParameters.primaryInterval))),
            secondaryInterval: Int(modifiedSettings.secondaryInterval.currentValue(baseValue: Double(baseParameters.secondaryInterval))),
            intervalPattern: baseParameters.intervalPattern,
            intervalInversion: baseParameters.intervalInversion,
            symmetricalIntervals: baseParameters.symmetricalIntervals,
            interpolation: modifiedInterpolation,
            infrapolation: modifiedInfrapolation,
            ultrapolation: modifiedUltrapolation,
            primaryDirection: baseParameters.primaryDirection,
            mirrorPoints: Int(modifiedSettings.mirrorPoints.currentValue(baseValue: Double(baseParameters.mirrorPoints))),
            retrogradeSections: baseParameters.retrogradeSections,
            registerShifts: baseParameters.registerShifts,
            contourPattern: baseParameters.contourPattern,
            baseNoteDuration: modifiedSettings.baseNoteDuration.currentValue(baseValue: baseParameters.baseNoteDuration),
            harmonicMode: baseParameters.harmonicMode,
            chordGeneration: baseParameters.chordGeneration,
            harmonicRhythm: baseParameters.harmonicRhythm,
            velocitySettings: modifiedVelocitySettings,
            toneShifting: baseParameters.toneShifting,
            cyclicalSettings: modifiedSettings,
            rhythmSettings: modifiedRhythmSettings
        )
    }
    
    /// Advance to the next cycle
    func advanceCycle() {
        guard isCyclingEnabled else { return }
        
        cyclicalSettings.advanceAllCycles()
        currentCycle += 1
        
        // Calculate cycle progress
        let maxCycles = getMaxCycles()
        cycleProgress = maxCycles > 0 ? Double(currentCycle) / Double(maxCycles) : 0.0
        
        print("🔄 Advanced to cycle \(currentCycle) (progress: \(String(format: "%.1f", cycleProgress * 100))%)")
    }
    
    /// Reset cycle counter
    func resetCycle() {
        cyclicalSettings.resetAllCycles()
        currentCycle = 0
        cycleProgress = 0.0
        print("🔄 Reset cyclical parameters to cycle 0")
    }
    
    /// Get information about the current cycle
    func getCycleInfo() -> [String: Any] {
        var info: [String: Any] = [
            "currentCycle": currentCycle,
            "isEnabled": isCyclingEnabled,
            "progress": cycleProgress
        ]
        
        let enabledParams = cyclicalSettings.enabledParameters
        info["enabledParameters"] = enabledParams.keys.map { $0 }
        info["totalEnabled"] = enabledParams.count
        
        return info
    }
    
    // MARK: - Private Methods
    
    private func getMaxCycles() -> Int {
        let enabledParams = cyclicalSettings.enabledParameters
        var maxCycles = 1
        
        for (_, settings) in enabledParams {
            guard settings.isEnabled else { continue }
            
            let range = settings.maxValue - settings.minValue
            let cyclesNeeded = Int(ceil(range / settings.stepSize)) + 1
            
            maxCycles = max(maxCycles, cyclesNeeded)
        }
        
        return maxCycles
    }
} 