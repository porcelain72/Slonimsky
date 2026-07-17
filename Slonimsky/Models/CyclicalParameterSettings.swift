import Foundation

/// Types of parameters that can be cycled
public enum CyclicalParameterType: String, CaseIterable, Codable {
    case interpolationNotes = "Interpolation Notes"
    case infrapolationNotes = "Infrapolation Notes"
    case ultrapolationNotes = "Ultrapolation Notes"
    case modulationInterval = "Modulation Interval"
    case baseNoteDuration = "Base Note Duration"
    case primaryInterval = "Primary Interval"
    case secondaryInterval = "Secondary Interval"
    case baseVelocity = "Base Velocity"
    case velocityRange = "Velocity Range"
    case tempo = "Tempo"
    case rootNote = "Root Note"
    case numberOfOctaves = "Number of Octaves"
    case divisionsOfOctave = "Divisions of Octave"
    case mirrorPoints = "Mirror Points"
    case euclideanRotation = "Euclidean Rotation"
}

/// Waveform shape of a phase-based parameter curve
public enum CycleShape: String, CaseIterable, Codable {
    case rampUp = "Ramp Up"
    case rampDown = "Ramp Down"
    case triangle = "Triangle"
    case sine = "Sine"
    case randomHold = "Random"

    public var description: String {
        switch self {
        case .rampUp:
            return "Rise from min to max over one period, then wrap"
        case .rampDown:
            return "Fall from max to min over one period, then wrap"
        case .triangle:
            return "Rise to max mid-period, fall back to min"
        case .sine:
            return "Smooth rise and fall (raised cosine)"
        case .randomHold:
            return "A different random value each cycle, repeating every period"
        }
    }
}

/// A phase-based parameter curve: the parameter sweeps its range over `period`
/// pattern cycles following `shape`, then wraps. Parameters with different
/// periods phase against each other and realign at the lcm of their periods.
public struct CyclicalParameterSettings: Codable, Equatable, Hashable {
    /// Whether cyclical changes are enabled for this parameter
    public var isEnabled: Bool = false

    /// The minimum value for the parameter
    public var minValue: Double = 0.0

    /// The maximum value for the parameter
    public var maxValue: Double = 10.0

    /// Pattern cycles per full sweep of the curve (1...64)
    public var period: Int = 8

    /// Waveform of the sweep
    public var shape: CycleShape = .rampUp

    public init(
        isEnabled: Bool = false,
        minValue: Double = 0.0,
        maxValue: Double = 10.0,
        period: Int = 8,
        shape: CycleShape = .rampUp
    ) {
        self.isEnabled = isEnabled
        self.minValue = minValue
        self.maxValue = maxValue
        self.period = period
        self.shape = shape
    }

    /// Value at a global cycle index.
    /// Guaranteed periodic: `value(atCycle: c) == value(atCycle: c + period)`.
    public func value(atCycle cycle: Int, baseValue: Double) -> Double {
        guard isEnabled, period >= 1 else { return baseValue }

        let step = ((cycle % period) + period) % period
        let phase = Double(step) / Double(period)
        let t: Double
        switch shape {
        case .rampUp:
            t = phase
        case .rampDown:
            t = 1.0 - phase
        case .triangle:
            t = 1.0 - abs(2.0 * phase - 1.0)
        case .sine:
            t = 0.5 - 0.5 * cos(2.0 * .pi * phase)
        case .randomHold:
            // Deterministic pseudo-random per step; repeats every period
            t = Double((step &* 2654435761) % 1000) / 999.0
        }
        return minValue + t * (maxValue - minValue)
    }
}

/// Collection of cyclical settings for different parameter categories
public struct CyclicalSettings: Codable, Equatable, Hashable {
    // Slonimsky Modulations
    public var interpolationNotes: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 5.0
    )

    public var infrapolationNotes: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 5.0
    )

    public var ultrapolationNotes: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 5.0
    )

    public var modulationInterval: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 1.0,
        maxValue: 12.0
    )

    // Rhythmic Parameters (quarter note = 1.0 beat: sweeps 16th note up to half note)
    public var baseNoteDuration: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.25,
        maxValue: 2.0
    )

    // Interval Parameters
    public var primaryInterval: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 1.0,
        maxValue: 12.0
    )

    public var secondaryInterval: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 1.0,
        maxValue: 12.0
    )

    // Velocity Parameters
    public var baseVelocity: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 40.0,
        maxValue: 100.0
    )

    public var velocityRange: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 10.0,
        maxValue: 50.0
    )

    // Tempo Parameters
    public var tempo: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 60.0,
        maxValue: 180.0
    )

    // Basic Parameters
    public var rootNote: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 48.0, // C3
        maxValue: 72.0  // C5
    )

    public var numberOfOctaves: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 1.0,
        maxValue: 4.0
    )

    public var divisionsOfOctave: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 12.0,
        maxValue: 24.0
    )

    // Directional Parameters
    public var mirrorPoints: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 5.0
    )

    // Rhythm Engine Parameters (rotates the Euclidean grid one step per cycle)
    public var euclideanRotation: CyclicalParameterSettings = CyclicalParameterSettings(
        isEnabled: false,
        minValue: 0.0,
        maxValue: 8.0
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
        if primaryInterval.isEnabled { enabled[.primaryInterval] = primaryInterval }
        if secondaryInterval.isEnabled { enabled[.secondaryInterval] = secondaryInterval }
        if baseVelocity.isEnabled { enabled[.baseVelocity] = baseVelocity }
        if velocityRange.isEnabled { enabled[.velocityRange] = velocityRange }
        if tempo.isEnabled { enabled[.tempo] = tempo }
        if rootNote.isEnabled { enabled[.rootNote] = rootNote }
        if numberOfOctaves.isEnabled { enabled[.numberOfOctaves] = numberOfOctaves }
        if divisionsOfOctave.isEnabled { enabled[.divisionsOfOctave] = divisionsOfOctave }
        if mirrorPoints.isEnabled { enabled[.mirrorPoints] = mirrorPoints }
        if euclideanRotation.isEnabled { enabled[.euclideanRotation] = euclideanRotation }

        return enabled
    }

    /// Number of pattern cycles after which all enabled curves realign
    /// (lcm of their periods), before capping.
    public var realignmentCycles: Int {
        let periods = enabledParameters.values.map { max(1, $0.period) }
        guard !periods.isEmpty else { return 1 }
        return periods.reduce(1, CyclicalSettings.lcm)
    }

    public static func lcm(_ a: Int, _ b: Int) -> Int {
        let g = gcd(a, b)
        guard g > 0 else { return max(a, b, 1) }
        return abs(a / g * b)
    }

    public static func gcd(_ a: Int, _ b: Int) -> Int {
        var (a, b) = (abs(a), abs(b))
        while b != 0 { (a, b) = (b, a % b) }
        return max(a, 1)
    }
}
