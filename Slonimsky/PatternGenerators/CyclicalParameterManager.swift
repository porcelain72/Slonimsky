import Foundation

/// Applies phase-based cyclical parameter curves to pattern parameters.
/// Each enabled parameter is evaluated independently at a global cycle index;
/// curves with different periods phase against each other and realign at the
/// lcm of their periods.
class CyclicalParameterManager {
    // MARK: - Properties
    private let cyclicalSettings: CyclicalSettings
    let isCyclingEnabled: Bool

    // MARK: - Initialization
    init(cyclicalSettings: CyclicalSettings = CyclicalSettings()) {
        self.cyclicalSettings = cyclicalSettings
        self.isCyclingEnabled = !cyclicalSettings.enabledParameters.isEmpty
    }

    // MARK: - Public Methods

    /// Get modified parameters for a given global cycle index.
    /// Every enabled parameter derives its own phase from `cycleIndex` and its period.
    func getModifiedParameters(from baseParameters: PatternParameters, cycleIndex: Int) -> PatternParameters {
        guard isCyclingEnabled else { return baseParameters }

        let settings = cyclicalSettings

        // Create modified modulation settings
        let modifiedInterpolation = ModulationSettings(
            numberOfNotes: Int(settings.interpolationNotes.value(atCycle: cycleIndex, baseValue: Double(baseParameters.interpolation.numberOfNotes)).rounded()),
            interval: Int(settings.modulationInterval.value(atCycle: cycleIndex, baseValue: Double(baseParameters.interpolation.interval)).rounded()),
            enabled: baseParameters.interpolation.enabled
        )

        let modifiedInfrapolation = ModulationSettings(
            numberOfNotes: Int(settings.infrapolationNotes.value(atCycle: cycleIndex, baseValue: Double(baseParameters.infrapolation.numberOfNotes)).rounded()),
            interval: Int(settings.modulationInterval.value(atCycle: cycleIndex, baseValue: Double(baseParameters.infrapolation.interval)).rounded()),
            enabled: baseParameters.infrapolation.enabled
        )

        let modifiedUltrapolation = ModulationSettings(
            numberOfNotes: Int(settings.ultrapolationNotes.value(atCycle: cycleIndex, baseValue: Double(baseParameters.ultrapolation.numberOfNotes)).rounded()),
            interval: Int(settings.modulationInterval.value(atCycle: cycleIndex, baseValue: Double(baseParameters.ultrapolation.interval)).rounded()),
            enabled: baseParameters.ultrapolation.enabled
        )

        // Create modified velocity settings
        let modifiedVelocitySettings = VelocitySettings(
            baseVelocity: UInt8(clamping: Int(settings.baseVelocity.value(atCycle: cycleIndex, baseValue: Double(baseParameters.velocitySettings.baseVelocity)).rounded())),
            range: UInt8(clamping: Int(settings.velocityRange.value(atCycle: cycleIndex, baseValue: Double(baseParameters.velocitySettings.range)).rounded())),
            waveDepth: baseParameters.velocitySettings.waveDepth,
            randomness: baseParameters.velocitySettings.randomness,
            phase: baseParameters.velocitySettings.phase,
            emphasisBeat: baseParameters.velocitySettings.emphasisBeat,
            emphasisAmount: baseParameters.velocitySettings.emphasisAmount
        )

        // Apply cycled Euclidean rotation to the rhythm settings
        var modifiedRhythmSettings = baseParameters.rhythmSettings
        modifiedRhythmSettings.euclideanRotation = Int(
            settings.euclideanRotation.value(
                atCycle: cycleIndex,
                baseValue: Double(baseParameters.rhythmSettings.euclideanRotation)
            ).rounded()
        )

        return PatternParameters(
            rootNote: Int(settings.rootNote.value(atCycle: cycleIndex, baseValue: Double(baseParameters.rootNote)).rounded()),
            scaleType: baseParameters.scaleType,
            numberOfOctaves: Int(settings.numberOfOctaves.value(atCycle: cycleIndex, baseValue: Double(baseParameters.numberOfOctaves)).rounded()),
            divisionsOfOctave: Int(settings.divisionsOfOctave.value(atCycle: cycleIndex, baseValue: Double(baseParameters.divisionsOfOctave)).rounded()),
            tempo: settings.tempo.value(atCycle: cycleIndex, baseValue: baseParameters.tempo),
            meterCycle: baseParameters.meterCycle,
            iterations: baseParameters.iterations,
            randomiseOrder: baseParameters.randomiseOrder,
            primaryInterval: Int(settings.primaryInterval.value(atCycle: cycleIndex, baseValue: Double(baseParameters.primaryInterval)).rounded()),
            secondaryInterval: Int(settings.secondaryInterval.value(atCycle: cycleIndex, baseValue: Double(baseParameters.secondaryInterval)).rounded()),
            intervalPattern: baseParameters.intervalPattern,
            intervalInversion: baseParameters.intervalInversion,
            symmetricalIntervals: baseParameters.symmetricalIntervals,
            interpolation: modifiedInterpolation,
            infrapolation: modifiedInfrapolation,
            ultrapolation: modifiedUltrapolation,
            mirror: baseParameters.mirror,
            primaryDirection: baseParameters.primaryDirection,
            mirrorPoints: Int(settings.mirrorPoints.value(atCycle: cycleIndex, baseValue: Double(baseParameters.mirrorPoints)).rounded()),
            retrogradeSections: baseParameters.retrogradeSections,
            registerShifts: baseParameters.registerShifts,
            contourPattern: baseParameters.contourPattern,
            baseNoteDuration: settings.baseNoteDuration.value(atCycle: cycleIndex, baseValue: baseParameters.baseNoteDuration),
            harmonicMode: baseParameters.harmonicMode,
            chordGeneration: baseParameters.chordGeneration,
            harmonicRhythm: baseParameters.harmonicRhythm,
            velocitySettings: modifiedVelocitySettings,
            toneShifting: baseParameters.toneShifting,
            cyclicalSettings: settings,
            rhythmSettings: modifiedRhythmSettings,
            processSettings: baseParameters.processSettings,
            phasingSettings: baseParameters.phasingSettings,
            customMelody: baseParameters.customMelody
        )
    }
}
