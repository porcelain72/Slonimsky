import Foundation

/// Types of parameters that can be cycled
public enum CyclicalParameterType: String, CaseIterable, Codable {
    case interpolationNotes = "Interpolation Notes"
    case infrapolationNotes = "Infrapolation Notes"
    case ultrapolationNotes = "Ultrapolation Notes"
    case modulationInterval = "Modulation Interval"
    case baseNoteDuration = "Base Note Duration"
    case rhythmicDensity = "Rhythmic Density"
    case primaryInterval = "Primary Interval"
    case secondaryInterval = "Secondary Interval"
    case baseVelocity = "Base Velocity"
    case velocityRange = "Velocity Range"
    case tempo = "Tempo"
    case rootNote = "Root Note"
    case numberOfOctaves = "Number of Octaves"
    case divisionsOfOctave = "Divisions of Octave"
    case mirrorPoints = "Mirror Points"
}

/// How cyclical values should be applied to base values
public enum CyclicalOperationType: String, CaseIterable, Codable {
    case replace = "Replace"
    case add = "Add"
    case multiply = "Multiply"
    case modulate = "Modulate"
}

/// Defines how a parameter should change cyclically
public struct CyclicalParameterSettings: Codable, Equatable, Hashable {
    /// Whether cyclical changes are enabled for this parameter
    public var isEnabled: Bool = false
    
    /// The minimum value for the parameter
    public var minValue: Double = 0.0
    
    /// The maximum value for the parameter
    public var maxValue: Double = 10.0
    
    /// The step size for each cycle increment
    public var stepSize: Double = 1.0
    
    /// The current cycle value (0-based)
    public var currentCycle: Int = 0
    
    /// Whether to reset to minValue after reaching maxCycles
    public var resetAfterMax: Bool = true
    
    /// How the cyclical value should be applied to the base value
    public var operationType: CyclicalOperationType = .replace
    
    /// The type of cycling behavior
    public var cycleType: CycleType = .increment
    
    public init(
        isEnabled: Bool = false,
        minValue: Double = 0.0,
        maxValue: Double = 10.0,
        stepSize: Double = 1.0,
        currentCycle: Int = 0,
        resetAfterMax: Bool = true,
        cycleType: CycleType = .increment
    ) {
        self.isEnabled = isEnabled
        self.minValue = minValue
        self.maxValue = maxValue
        self.stepSize = stepSize
        self.currentCycle = currentCycle
        self.resetAfterMax = resetAfterMax
        self.cycleType = cycleType
    }
    
    /// Calculate the current parameter value based on cycle
    public func currentValue(baseValue: Double) -> Double {
        guard isEnabled else { return baseValue }
        
        let cycleValue: Double
        switch cycleType {
        case .increment:
            cycleValue = minValue + (Double(currentCycle) * stepSize)
        case .decrement:
            cycleValue = maxValue - (Double(currentCycle) * stepSize)
        case .oscillate:
            let maxCycles = Int(ceil((maxValue - minValue) / stepSize)) + 1
            let halfCycles = maxCycles / 2
            let cycleInHalf = currentCycle % (halfCycles * 2)
            if cycleInHalf < halfCycles {
                cycleValue = minValue + (Double(cycleInHalf) * stepSize)
            } else {
                cycleValue = maxValue - (Double(cycleInHalf - halfCycles) * stepSize)
            }
        case .random:
            // Use currentCycle as seed for deterministic randomness
            let random = Double((currentCycle * 12345) % 1000) / 1000.0
            cycleValue = minValue + (random * (maxValue - minValue))
        }
        
        return max(minValue, min(maxValue, cycleValue))
    }
    
    /// Advance to the next cycle
    public mutating func advanceCycle() {
        guard isEnabled else { return }
        
        let maxCycles = Int(ceil((maxValue - minValue) / stepSize)) + 1
        currentCycle += 1
        
        if currentCycle >= maxCycles {
            if resetAfterMax {
                currentCycle = 0
            } else {
                currentCycle = maxCycles - 1
            }
        }
    }
    
    /// Reset the cycle counter
    public mutating func resetCycle() {
        currentCycle = 0
    }
}

/// Types of cycling behavior
public enum CycleType: String, CaseIterable, Codable {
    case increment = "Increment"
    case decrement = "Decrement"
    case oscillate = "Oscillate"
    case random = "Random"
    
    public var description: String {
        switch self {
        case .increment:
            return "Gradually increase from min to max"
        case .decrement:
            return "Gradually decrease from max to min"
        case .oscillate:
            return "Oscillate between min and max values"
        case .random:
            return "Use random values within range"
        }
    }
}

/// Collection of cyclical settings for different parameter categories
public struct CyclicalSettings: Codable, Equatable, Hashable {
    // Slonimsky Modulations
    public var interpolationNotes: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 5.0,
        stepSize: 1.0
    )
    
    public var infrapolationNotes: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 5.0,
        stepSize: 1.0
    )
    
    public var ultrapolationNotes: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 5.0,
        stepSize: 1.0
    )
    
    public var modulationInterval: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 1.0,
        maxValue: 12.0,
        stepSize: 1.0
    )
    
    // Rhythmic Parameters
    public var baseNoteDuration: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.25,
        maxValue: 2.0,
        stepSize: 0.25
    )
    
    public var rhythmicDensity: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.5,
        maxValue: 2.0,
        stepSize: 0.25
    )
    
    // Interval Parameters
    public var primaryInterval: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 1.0,
        maxValue: 12.0,
        stepSize: 1.0
    )
    
    public var secondaryInterval: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 1.0,
        maxValue: 12.0,
        stepSize: 1.0
    )
    
    // Velocity Parameters
    public var baseVelocity: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 40.0,
        maxValue: 100.0,
        stepSize: 10.0
    )
    
    public var velocityRange: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 10.0,
        maxValue: 50.0,
        stepSize: 5.0
    )
    
    // Tempo Parameters
    public var tempo: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 60.0,
        maxValue: 180.0,
        stepSize: 20.0
    )
    
    // Basic Parameters
    public var rootNote: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 48.0, // C3
        maxValue: 72.0, // C5
        stepSize: 1.0
    )
    
    public var numberOfOctaves: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 1.0,
        maxValue: 4.0,
        stepSize: 1.0
    )
    
    public var divisionsOfOctave: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 12.0,
        maxValue: 24.0,
        stepSize: 1.0
    )
    
    // Directional Parameters
    public var mirrorPoints: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 5.0,
        stepSize: 1.0
    )
    
    public init() {}
    
    /// Get all enabled cyclical parameters
    public var enabledParameters: [CyclicalParameterType: CyclicalParameterSettings] {
        var enabled: [CyclicalParameterType: CyclicalParameterSettings] = [:]
        
        if interpolationNotes.isEnabled { enabled[.interpolationNotes] = interpolationNotes }
        if infrapolationNotes.isEnabled { enabled[.infrapolationNotes] = infrapolationNotes }
        if ultrapolationNotes.isEnabled { enabled[.ultrapolationNotes] = ultrapolationNotes }
        if modulationInterval.isEnabled { enabled[.modulationInterval] = modulationInterval }
        if baseNoteDuration.isEnabled { enabled[.baseNoteDuration] = baseNoteDuration }
        if rhythmicDensity.isEnabled { enabled[.rhythmicDensity] = rhythmicDensity }
        if primaryInterval.isEnabled { enabled[.primaryInterval] = primaryInterval }
        if secondaryInterval.isEnabled { enabled[.secondaryInterval] = secondaryInterval }
        if baseVelocity.isEnabled { enabled[.baseVelocity] = baseVelocity }
        if velocityRange.isEnabled { enabled[.velocityRange] = velocityRange }
        if tempo.isEnabled { enabled[.tempo] = tempo }
        if rootNote.isEnabled { enabled[.rootNote] = rootNote }
        if numberOfOctaves.isEnabled { enabled[.numberOfOctaves] = numberOfOctaves }
        if divisionsOfOctave.isEnabled { enabled[.divisionsOfOctave] = divisionsOfOctave }
        if mirrorPoints.isEnabled { enabled[.mirrorPoints] = mirrorPoints }
        
        return enabled
    }
    
    /// Advance all enabled parameters to the next cycle
    public mutating func advanceAllCycles() {
        interpolationNotes.advanceCycle()
        infrapolationNotes.advanceCycle()
        ultrapolationNotes.advanceCycle()
        modulationInterval.advanceCycle()
        baseNoteDuration.advanceCycle()
        rhythmicDensity.advanceCycle()
        primaryInterval.advanceCycle()
        secondaryInterval.advanceCycle()
        baseVelocity.advanceCycle()
        velocityRange.advanceCycle()
        tempo.advanceCycle()
        rootNote.advanceCycle()
        numberOfOctaves.advanceCycle()
        divisionsOfOctave.advanceCycle()
        mirrorPoints.advanceCycle()
    }
    
    /// Reset all cycle counters
    public mutating func resetAllCycles() {
        interpolationNotes.resetCycle()
        infrapolationNotes.resetCycle()
        ultrapolationNotes.resetCycle()
        modulationInterval.resetCycle()
        baseNoteDuration.resetCycle()
        rhythmicDensity.resetCycle()
        primaryInterval.resetCycle()
        secondaryInterval.resetCycle()
        baseVelocity.resetCycle()
        velocityRange.resetCycle()
        tempo.resetCycle()
        rootNote.resetCycle()
        numberOfOctaves.resetCycle()
        divisionsOfOctave.resetCycle()
        mirrorPoints.resetCycle()
    }
} 