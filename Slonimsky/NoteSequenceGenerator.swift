import Foundation

enum PatternDirection {
    case ascending
    case descending
}

struct NoteSequenceGenerator {
    typealias ModulationData = (count:Int, interval:Int)
    
    static func calculateVelocity(index n: Int, note: Int, model: VelocityModel) -> UInt8 {
        let sinComponent = sin(Double(n) * model.phase) * model.waveDepth
        let randComponent = Double.random(in: -1...1) * model.randomness
        
        let isEmphasized = (model.emphasisBeat > 0) && (n % model.emphasisBeat == 0)
        let emphasisBoost = isEmphasized ? model.emphasisAmount : 0.0
        
        let combined = sinComponent + randComponent + emphasisBoost
        let offset = Double(model.range) * combined
        let velocity = Double(model.baseVelocity) + offset
        
        return UInt8(clamping: Int(round(velocity)))
    }
    
    static func buildAllSubsequences(
        startNote: Int,
        interval: Int,
        count: Int = 8,
        interpolate: SlonimskyModulation?,
        infrapolate: SlonimskyModulation?,
        ultrapolate: SlonimskyModulation?,
        model: VelocityModel,
        noteDuration: NoteDuration = .eighth,
        timeSignature: MIDITimeSignature = .defaultSignature
    ) -> [[MIDIInfo]] {
        let beatLength = noteDuration.beatValue(in: timeSignature)
        
        func baseNotes() -> [Int] {
            return (0..<count).map { i in startNote + i * interval }
        }

        func buildVariant(
            from notes: [Int],
            interpolate: ModulationData,
            infrapolate: ModulationData,
            ultrapolate: ModulationData,
            counter: Double
        ) -> [MIDIInfo] {
            var result: [MIDIInfo] = []

            for i in 0..<notes.count {
                let note = notes[i]
                result.append(MIDIInfo(
                    note: note,
                    velocity: calculateVelocity(index: i, note: note, model: model),
                    beatLength: beatLength
                ))

                if interpolate.count  > 0, i < notes.count - 1 {
                    for p in 1...interpolate.count {
                        let new = note + p * (interpolate.interval)
                        result.append(MIDIInfo(
                            note: new,
                            velocity: calculateVelocity(index: i, note: new, model: model),
                            beatLength: beatLength
                        ))
                    }
                }

                if infrapolate.count > 0, i < notes.count - 1 {
                    for p in 1...infrapolate.count {
                        let new = note - p * infrapolate.interval
                        result.append(MIDIInfo(
                            note: new,
                            velocity: calculateVelocity(index: i, note: new, model: model),
                            beatLength: beatLength
                        ))
                    }
                }

                if ultrapolate.count > 0, i < notes.count - 1 {
                    for p in 1...ultrapolate.count {
                        let new = notes[i + 1] - p * ultrapolate.interval
                        result.append(MIDIInfo(
                            note: new,
                            velocity: calculateVelocity(index: i, note: new, model: model),
                            beatLength: beatLength
                        ))
                    }
                }
            }

            return result
        }

        let principal = baseNotes()
        var subsequences: [[MIDIInfo]] = []

        for i in 0...(ultrapolate?.numberOfNewNotes ?? 0) {
            for f in 0...(infrapolate?.numberOfNewNotes ?? 0) {
                for u in 0...(interpolate?.numberOfNewNotes ?? 0) {
                    let forward = buildVariant(from: principal,
                                               interpolate: (count: u, interval: interpolate?.intervalBetweenNewNotes ?? 1),
                                               infrapolate: (count: f, interval: infrapolate?.intervalBetweenNewNotes ?? 1),
                                               ultrapolate: (count: i, interval: ultrapolate?.intervalBetweenNewNotes ?? 1),
                                               counter: Double(i * (ultrapolate?.numberOfNewNotes ?? 0) +
                                                               f * (infrapolate?.numberOfNewNotes ?? 0) +
                                                               u))
                    let mirrored = Array(forward.dropLast().reversed())
                    let full = forward + mirrored
                    subsequences.append(full.dropLast())
                }
            }
        }

        return subsequences
    }

    
    static func estimateVariantLength(baseCount: Int, interpolate: Int, infrapolate: Int, ultrapolate: Int) -> Int {
        var total = 0
        for i in 0..<baseCount {
            total += 1 // the base note
            if i < baseCount - 1 {
                total += interpolate
                total += infrapolate
                total += ultrapolate
            }
        }

        // Reflect and drop final note as in `buildAllCombinations`
        return (2 * total) - 1
    }

}
