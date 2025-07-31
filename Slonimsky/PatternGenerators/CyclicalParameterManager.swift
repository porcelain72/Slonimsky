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
        case "rhythmicDensity":
            return cyclicalSettings.rhythmicDensity.currentValue(baseValue: baseValue)
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
        default:
            return baseValue
        }
    }
    
    /// Get modified parameters for the current cycle
    func getModifiedParameters(from baseParameters: PatternParameters) -> PatternParameters {
        guard isCyclingEnabled else { return baseParameters }
        
        var modifiedSettings = cyclicalSettings
        
        // Create modified modulation settings
        let modifiedInterpolation = ModulationSettings(
            numberOfNotes: Int(cyclicalSettings.interpolationNotes.currentValue(baseValue: Double(baseParameters.interpolation.numberOfNotes))),
            interval: Int(cyclicalSettings.modulationInterval.currentValue(baseValue: Double(baseParameters.interpolation.interval))),
            enabled: baseParameters.interpolation.enabled
        )
        
        let modifiedInfrapolation = ModulationSettings(
            numberOfNotes: Int(cyclicalSettings.infrapolationNotes.currentValue(baseValue: Double(baseParameters.infrapolation.numberOfNotes))),
            interval: Int(cyclicalSettings.modulationInterval.currentValue(baseValue: Double(baseParameters.infrapolation.interval))),
            enabled: baseParameters.infrapolation.enabled
        )
        
        let modifiedUltrapolation = ModulationSettings(
            numberOfNotes: Int(cyclicalSettings.ultrapolationNotes.currentValue(baseValue: Double(baseParameters.ultrapolation.numberOfNotes))),
            interval: Int(cyclicalSettings.modulationInterval.currentValue(baseValue: Double(baseParameters.ultrapolation.interval))),
            enabled: baseParameters.ultrapolation.enabled
        )
        
        // Create modified velocity settings
        let modifiedVelocitySettings = VelocitySettings(
            baseVelocity: UInt8(cyclicalSettings.baseVelocity.currentValue(baseValue: Double(baseParameters.velocitySettings.baseVelocity))),
            range: UInt8(cyclicalSettings.velocityRange.currentValue(baseValue: Double(baseParameters.velocitySettings.range))),
            waveDepth: baseParameters.velocitySettings.waveDepth,
            randomness: baseParameters.velocitySettings.randomness,
            phase: baseParameters.velocitySettings.phase,
            emphasisBeat: baseParameters.velocitySettings.emphasisBeat,
            emphasisAmount: baseParameters.velocitySettings.emphasisAmount
        )
        
        return PatternParameters(
            rootNote: baseParameters.rootNote,
            scaleType: baseParameters.scaleType,
            numberOfOctaves: baseParameters.numberOfOctaves,
            divisionsOfOctave: baseParameters.divisionsOfOctave,
            tempo: cyclicalSettings.tempo.currentValue(baseValue: baseParameters.tempo),
            timeSignature: baseParameters.timeSignature,
            primaryInterval: Int(cyclicalSettings.primaryInterval.currentValue(baseValue: Double(baseParameters.primaryInterval))),
            secondaryInterval: Int(cyclicalSettings.secondaryInterval.currentValue(baseValue: Double(baseParameters.secondaryInterval))),
            intervalPattern: baseParameters.intervalPattern,
            intervalInversion: baseParameters.intervalInversion,
            symmetricalIntervals: baseParameters.symmetricalIntervals,
            interpolation: modifiedInterpolation,
            infrapolation: modifiedInfrapolation,
            ultrapolation: modifiedUltrapolation,
            primaryDirection: baseParameters.primaryDirection,
            mirrorPoints: baseParameters.mirrorPoints,
            retrogradeSections: baseParameters.retrogradeSections,
            registerShifts: baseParameters.registerShifts,
            contourPattern: baseParameters.contourPattern,
            noteDurationPattern: baseParameters.noteDurationPattern,
            baseNoteDuration: cyclicalSettings.baseNoteDuration.currentValue(baseValue: baseParameters.baseNoteDuration),
            rhythmicDensity: cyclicalSettings.rhythmicDensity.currentValue(baseValue: baseParameters.rhythmicDensity),
            syncopationLevel: baseParameters.syncopationLevel,
            metricModulation: baseParameters.metricModulation,
            harmonicMode: baseParameters.harmonicMode,
            chordGeneration: baseParameters.chordGeneration,
            harmonicRhythm: baseParameters.harmonicRhythm,
            velocitySettings: modifiedVelocitySettings,
            toneShifting: baseParameters.toneShifting,
            cyclicalSettings: modifiedSettings
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
        return enabledParams.values.map { $0.maxCycles }.max() ?? 1
    }
} 