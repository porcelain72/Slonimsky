//
//  MIDIPatternConverter.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Service responsible for converting mathematical note patterns to MIDI information
/// Separates pure mathematical pattern generation from MIDI-specific attributes (velocity, duration)
class MIDIPatternConverter {
    
    // MARK: - Rhythm Engine

    /// Maximum number of events an isorhythm realignment may emit before capping.
    static let isorhythmEventCap = 1024

    /// Schedule a pitch stream (the "color") in time according to the rhythm settings.
    ///
    /// - uniform: every pitch gets `baseNoteDuration`, back to back.
    /// - isorhythm: a repeating duration cycle (the "talea") runs independently of the
    ///   pitch cycle. Rest entries advance time without consuming pitches. The sequence
    ///   runs until pitch and talea cycles realign (capped at `isorhythmEventCap` events).
    /// - euclidean: pitches fall on the hits of a Bjorklund E(k, n) grid; silent steps
    ///   emit rests. Whole grid cycles are emitted so the result loops seamlessly.
    ///
    /// A final accent pass boosts the velocity of sounding notes that fall on a meter
    /// grouping start (e.g. beats 1, 3, 5 of 7/8 grouped 2+2+3).
    ///
    /// - Parameters:
    ///   - pitches: MIDI note numbers to schedule, in order
    ///   - parameters: pattern parameters (rhythmSettings, meter, baseNoteDuration, velocity)
    ///   - indexOffset: starting index offset for velocity calculations
    ///   - startOnset: onset in beats of the first event
    ///   - velocityProvider: optional custom velocity source (pitch index, pitch) -> velocity;
    ///     defaults to `parameters.velocitySettings`
    /// - Returns: scheduled events with onsets, durations, and explicit rests
    static func scheduleRhythm(
        pitches: [Int],
        parameters: PatternParameters,
        indexOffset: Int = 0,
        startOnset: Double = 0,
        velocityProvider: ((Int, Int) -> UInt8)? = nil
    ) -> [MIDIInfo] {
        guard !pitches.isEmpty else { return [] }

        // Generators occasionally produce out-of-range pitches (register shifts,
        // wide octave counts); the engine guarantees valid MIDI notes.
        let pitches = pitches.map { min(127, max(0, $0)) }

        // Floor at 1: a MIDI note-on with velocity 0 means note-off
        let rawVelocity: (Int, Int) -> UInt8 = velocityProvider ?? { index, pitch in
            parameters.velocitySettings.calculateVelocity(for: index, note: pitch)
        }
        let velocity: (Int, Int) -> UInt8 = { index, pitch in
            max(1, rawVelocity(index, pitch))
        }

        var events: [MIDIInfo]
        switch parameters.rhythmSettings.mode {
        case .uniform:
            events = scheduleUniform(pitches: pitches, parameters: parameters,
                                     indexOffset: indexOffset, startOnset: startOnset, velocity: velocity)
        case .isorhythm:
            events = scheduleIsorhythm(pitches: pitches, parameters: parameters,
                                       indexOffset: indexOffset, startOnset: startOnset, velocity: velocity)
        case .euclidean:
            events = scheduleEuclidean(pitches: pitches, parameters: parameters,
                                       indexOffset: indexOffset, startOnset: startOnset, velocity: velocity)
        }

        return applyMeterAccents(to: events, parameters: parameters)
    }

    private static func scheduleUniform(
        pitches: [Int],
        parameters: PatternParameters,
        indexOffset: Int,
        startOnset: Double,
        velocity: (Int, Int) -> UInt8
    ) -> [MIDIInfo] {
        var onset = startOnset
        return pitches.enumerated().map { index, pitch in
            let info = MIDIInfo(
                note: pitch,
                velocity: velocity(indexOffset + index, pitch),
                onset: onset,
                duration: parameters.baseNoteDuration,
                cycleIndex: 0
            )
            onset += parameters.baseNoteDuration
            return info
        }
    }

    private static func scheduleIsorhythm(
        pitches: [Int],
        parameters: PatternParameters,
        indexOffset: Int,
        startOnset: Double,
        velocity: (Int, Int) -> UInt8
    ) -> [MIDIInfo] {
        let talea = parameters.rhythmSettings.talea
        let noteEntriesPerCycle = talea.filter { !$0.isRest }.count

        // A talea with no sounding entries cannot consume pitches; fall back to uniform
        guard noteEntriesPerCycle > 0 else {
            return scheduleUniform(pitches: pitches, parameters: parameters,
                                   indexOffset: indexOffset, startOnset: startOnset, velocity: velocity)
        }

        // Run until the pitch cycle (color) and talea realign: the number of talea
        // cycles needed is colorLength / gcd(notesPerTalea, colorLength).
        let taleaCycles = pitches.count / gcd(noteEntriesPerCycle, pitches.count)
        var totalEvents = taleaCycles * talea.count
        if totalEvents > isorhythmEventCap {
            print("⚠️ Isorhythm realignment (\(totalEvents) events) exceeds cap; truncating to \(isorhythmEventCap)")
            totalEvents = isorhythmEventCap
        }

        var events: [MIDIInfo] = []
        var onset = startOnset
        var pitchIndex = 0

        for eventIndex in 0..<totalEvents {
            let entry = talea[eventIndex % talea.count]
            if entry.isRest {
                // Rests advance time but never consume pitches
                events.append(MIDIInfo(note: 0, velocity: 0, onset: onset,
                                       duration: entry.value.beats, isRest: true, cycleIndex: 0))
            } else {
                let pitch = pitches[pitchIndex % pitches.count]
                events.append(MIDIInfo(note: pitch,
                                       velocity: velocity(indexOffset + pitchIndex, pitch),
                                       onset: onset, duration: entry.value.beats, cycleIndex: 0))
                pitchIndex += 1
            }
            onset += entry.value.beats
        }

        return events
    }

    private static func scheduleEuclidean(
        pitches: [Int],
        parameters: PatternParameters,
        indexOffset: Int,
        startOnset: Double,
        velocity: (Int, Int) -> UInt8
    ) -> [MIDIInfo] {
        let settings = parameters.rhythmSettings
        let hits = min(max(1, settings.euclideanHits), max(1, settings.euclideanSteps))
        let steps = max(1, settings.euclideanSteps)
        let grid = EuclideanRhythm.pattern(hits: hits, steps: steps, rotation: settings.euclideanRotation)
        let stepBeats = settings.euclideanStepDuration.beats

        // Emit whole grid cycles so the result loops seamlessly; enough cycles
        // to state every pitch at least once (surplus hits wrap the color).
        let cycles = max(1, Int(ceil(Double(pitches.count) / Double(hits))))

        var events: [MIDIInfo] = []
        var onset = startOnset
        var pitchIndex = 0

        for _ in 0..<cycles {
            for step in 0..<steps {
                if grid[step] {
                    let pitch = pitches[pitchIndex % pitches.count]
                    events.append(MIDIInfo(note: pitch,
                                           velocity: velocity(indexOffset + pitchIndex, pitch),
                                           onset: onset, duration: stepBeats, cycleIndex: 0))
                    pitchIndex += 1
                } else {
                    events.append(MIDIInfo(note: 0, velocity: 0, onset: onset,
                                           duration: stepBeats, isRest: true, cycleIndex: 0))
                }
                onset += stepBeats
            }
        }

        return events
    }

    /// Boost the velocity of sounding notes that fall on a meter grouping start.
    static func applyMeterAccents(to events: [MIDIInfo], parameters: PatternParameters) -> [MIDIInfo] {
        let boost = parameters.rhythmSettings.accentBoost
        guard boost > 0 else { return events }

        return events.map { event in
            guard !event.isRest, parameters.meterCycle.isGroupingStart(event.onset) else { return event }
            var accented = event
            accented.velocity = UInt8(clamping: Int(event.velocity) + boost)
            return accented
        }
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var (a, b) = (abs(a), abs(b))
        while b != 0 { (a, b) = (b, a % b) }
        return max(a, 1)
    }
    
    /// Apply Slonimsky modulations to note patterns (mathematical operation before MIDI conversion)
    /// - Parameters:
    ///   - notes: Array of MIDI note numbers
    ///   - parameters: Pattern parameters containing modulation settings
    /// - Returns: Expanded array of note numbers with modulations applied
    static func applySlonimskyModulations(
        notes: [Int],
        parameters: PatternParameters
    ) -> [Int] {
        var result: [Int] = []
        
        for (index, note) in notes.enumerated() {
            // Add the base note
            result.append(note)
            
            // Apply interpolation (notes between existing notes)
            if parameters.interpolation.enabled && index < notes.count - 1 {
                let interpolatedNotes = generateInterpolatedNotes(
                    from: note,
                    to: notes[index + 1],
                    settings: parameters.interpolation
                )
                result.append(contentsOf: interpolatedNotes)
            }
            
            // Apply infrapolation (notes below existing notes)
            if parameters.infrapolation.enabled && index < notes.count - 1 {
                let infrapolatedNotes = generateInfrapolatedNotes(
                    baseNote: note,
                    settings: parameters.infrapolation
                )
                result.append(contentsOf: infrapolatedNotes)
            }
            
            // Apply ultrapolation (notes above existing notes)
            if parameters.ultrapolation.enabled && index < notes.count - 1 {
                let ultrapolatedNotes = generateUltrapolatedNotes(
                    baseNote: note,
                    nextNote: notes[index + 1],
                    settings: parameters.ultrapolation
                )
                result.append(contentsOf: ultrapolatedNotes)
            }
        }
        
        return result
    }
    
    /// Complete conversion: Apply iterations (optional), modulations, then convert to MIDI
    /// When iterations > 1, the pattern is re-processed: ParameterApplicationManager + modulations
    /// are applied repeatedly before MIDI conversion.
    /// - Parameters:
    ///   - notes: Base note pattern (already has ParameterApplicationManager applied from generator)
    ///   - parameters: Pattern parameters
    ///   - indexOffset: Starting index offset
    ///   - generatorType: Generator type for ParameterApplicationManager (e.g. "Scale", "Interval")
    /// - Returns: Final MIDIInfo array
    static func convertWithModulations(
        notes: [Int],
        parameters: PatternParameters,
        indexOffset: Int = 0,
        generatorType: String = "Scale"
    ) -> [MIDIInfo] {
        var currentNotes = notes
        
        // Randomise note order if enabled (before iterations and modulations)
        if parameters.randomiseOrder {
            currentNotes.shuffle()
        }
        
        // Iteration 1: apply modulations (notes already have ParameterApplicationManager from generator)
        currentNotes = applySlonimskyModulations(
            notes: currentNotes,
            parameters: parameters
        )
        
        // Iterations 2..<N: re-apply ParameterApplicationManager then modulations
        // Mirror is skipped in iterations—it runs only in the initial generator
        for _ in 1..<parameters.iterations {
            currentNotes = ParameterApplicationManager.applyParameters(
                baseNotes: currentNotes,
                parameters: parameters,
                generatorType: generatorType,
                skipMirror: true
            )
            currentNotes = applySlonimskyModulations(
                notes: currentNotes,
                parameters: parameters
            )
        }
        
        // Schedule in time (velocity, duration, onsets, rests)
        return scheduleRhythm(
            pitches: currentNotes,
            parameters: parameters,
            indexOffset: indexOffset
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func generateInterpolatedNotes(
        from startNote: Int,
        to endNote: Int,
        settings: ModulationSettings
    ) -> [Int] {
        var notes: [Int] = []
        
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let interpolatedNote = startNote + interval
            
            // Ensure note is within valid MIDI range
            // Allow notes beyond the target note for extended interpolation
            if interpolatedNote >= 0 && interpolatedNote <= 127 {
                notes.append(interpolatedNote)
            }
        }
        
        return notes
    }
    
    private static func generateInfrapolatedNotes(
        baseNote: Int,
        settings: ModulationSettings
    ) -> [Int] {
        var notes: [Int] = []
        
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let infrapolatedNote = baseNote - interval
            
            if infrapolatedNote >= 0 && infrapolatedNote <= 127 {
                notes.append(infrapolatedNote)
            }
        }
        
        return notes
    }
    
    private static func generateUltrapolatedNotes(
        baseNote: Int,
        nextNote: Int,
        settings: ModulationSettings
    ) -> [Int] {
        var notes: [Int] = []
        
        guard settings.numberOfNotes > 0 else { return notes }
        
        for i in 1...settings.numberOfNotes {
            let interval = settings.interval * i
            let ultrapolatedNote = nextNote - interval
            
            // Allow notes beyond the base note for extended ultrapolation
            if ultrapolatedNote >= 0 && ultrapolatedNote <= 127 {
                notes.append(ultrapolatedNote)
            }
        }
        
        return notes
    }
    
}
