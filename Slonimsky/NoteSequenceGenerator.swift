import Foundation

enum PatternDirection {
    case ascending
    case descending
}

struct NoteSequenceGenerator {

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
        maxInterpolate: Int = 0,
        maxInfrapolate: Int = 0,
        maxUltrapolate: Int = 0,
        model: VelocityModel
    ) -> [[MIDIInfo]] {

        var subsequences: [[MIDIInfo]] = []

        func baseNotes() -> [Int] {
            return (0..<count).map { i in startNote + i * interval }
        }

        func buildVariant(
            from notes: [Int],
            interpolate: Int,
            infrapolate: Int,
            ultrapolate: Int,
            counter: Double
        ) -> [MIDIInfo] {
            var result: [MIDIInfo] = []
            let increment = 1

            for i in 0..<notes.count {
                let note = notes[i]
                result.append(MIDIInfo(
                    note: note,
                    velocity: calculateVelocity(index: i, note: note, model: model)
                ))

                // Interpolation
                if interpolate > 0, i < notes.count - 1 {
                    for p in 1...interpolate {
                        let new = note + p * increment
                        result.append(MIDIInfo(
                            note: new,
                            velocity: calculateVelocity(index: i, note: new, model: model)
                        ))
                    }
                }

                // Infrapolation
                if infrapolate > 0, i < notes.count - 1 {
                    for p in 1...infrapolate {
                        let new = note - p * increment
                        result.append(MIDIInfo(
                            note: new,
                            velocity: calculateVelocity(index: i, note: new, model: model)
                        ))
                    }
                }

                // Ultrapolation
                if ultrapolate > 0, i < notes.count - 1 {
                    for p in 1...ultrapolate {
                        let new = notes[i + 1] - p * increment
                        result.append(MIDIInfo(
                            note: new,
                            velocity: calculateVelocity(index: i, note: new, model: model)
                        ))
                    }
                }
            }

            return result
        }


        let principal = baseNotes()

        for i in 0...maxUltrapolate {
            for f in 0...maxInfrapolate {
                for u in 0...maxInterpolate {
                    let forward = buildVariant(from: principal, interpolate: u, infrapolate: f, ultrapolate: i, counter: Double(i * maxUltrapolate + f * maxInfrapolate + u))
                    let mirrored = Array(forward.dropLast().reversed())
                    let full = forward + mirrored
                    subsequences.append(full)
                }
            }
        }

        return subsequences
    }
}
