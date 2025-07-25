import Foundation

class SlonimskySequencer: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var melodySubsequences: [[MIDIInfo]] = []
    @Published var chords: [ChordEvent] = []
    @Published var toneIncrement: Int = 0       // number of semitones to shift rootNote each time
    @Published var maxToneShift: Int = 0      // max total shift in semitones

    private let audioPlayer = MusicSequencePlayer()
    private let chordPlayer = AudioPlayer()


    // Config
    @Published var rootNote: Int = 60
    @Published var numberOfOctaves: Int = 1
    @Published var divisionsOfOctave: Int = 3
    @Published var noteDuration: TimeInterval = 0.25
    @Published var bpm: Double = 120.0
    @Published var model: VelocityModel = .default
    @Published var modulations: [SlonimskyModulation] = []
    @Published var chordParams: ChordExtractionParams = .init()
    
    
    func generate() {
        melodySubsequences = []
        chords = []

        let interval = 12 / divisionsOfOctave
        let count = (12 / interval) * numberOfOctaves

        let interp = modulations.first { $0.type == .interpolation }
        let infra  = modulations.first { $0.type == .infrapolation }
        let ultra  = modulations.first { $0.type == .ultrapolation }

        var toneShift = 0
        var startBeatOffset: Double = 0
        let effectiveToneIncrement = toneIncrement > 0 ? toneIncrement : maxToneShift + 1

        while toneShift <= maxToneShift {
            let shiftedRoot = rootNote + toneShift
            let subsequences = NoteSequenceGenerator.buildAllSubsequences(
                startNote: shiftedRoot,
                interval: interval,
                count: count,
                interpolate: interp,
                infrapolate: infra,
                ultrapolate: ultra,
                model: model
            )

            melodySubsequences.append(contentsOf: subsequences)

            // Count total number of notes in all these subsequences
            let notesInThisRound = subsequences.flatMap { $0 }.count
            let durationBeats = Double(notesInThisRound) * noteDuration

            let newChords = extractChords(
                from: subsequences,
                chordSize: chordParams.chordSize,
                spreadOctaves: chordParams.spreadOctaves,
                preferCloseVoicing: chordParams.preferCloseVoicing,
                beatLengthPerNote: noteDuration,
                channel: 1,
                velocityScale: chordParams.velocityScale,
                startBeatOffset: startBeatOffset
            )

            chords.append(contentsOf: newChords)
            startBeatOffset += durationBeats
            toneShift += effectiveToneIncrement
        }
    }


    func play() {
        stop() // Cancel old tasks
        generate()
        isPlaying = true

        let beatDuration = 60.0 / bpm
        let noteTime = noteDuration * beatDuration

        var startTime: TimeInterval = 0
        let player = audioPlayer

       // player.load(sequences: melodySubsequences, noteDuration: noteTime)
        player.load(melodySequences: melodySubsequences, chords: chords, noteDuration: noteTime)
        player.play()
        
    }

    func stop() {
    
        audioPlayer.stop()
      //  chordPlayer.stop()
        isPlaying = false
    }

    func calculateVelocity(index n: Int, note: Int, model: VelocityModel) -> UInt8 {
        let sinComponent = sin(Double(n) * model.phase) * model.waveDepth
        let randComponent = Double.random(in: -1...1) * model.randomness
        let isEmphasized = (model.emphasisBeat > 0) && (n % model.emphasisBeat == 0)
        let emphasisBoost = isEmphasized ? model.emphasisAmount : 0.0
        let combined = sinComponent + randComponent + emphasisBoost
        let offset = Double(model.range) * combined
        let velocity = Double(model.baseVelocity) + offset
        return UInt8(clamping: Int(round(velocity)))
    }
    
    func extractChords(
        from melodyGroups: [[MIDIInfo]],
        chordSize: Int = 3,
        spreadOctaves: Int = 1,
        preferCloseVoicing: Bool = true,
        beatLengthPerNote: Double,
        channel: UInt8 = 1,
        velocityScale: Double = 0.8,
        startBeatOffset: Double = 0
    ) -> [ChordEvent] {
        var events: [ChordEvent] = []
        var currentBeat: Double = startBeatOffset

        for group in melodyGroups {
            guard !group.isEmpty else { continue }

            let avgVelocity = group.map(\.velocity).average
            let chordVelocity = UInt8(clamping: Int(avgVelocity * velocityScale))

            let notes = group.map(\.note)
            let pcs = notes.map { (($0 % 12) + 12) % 12 }
            let pcCounts = Dictionary(pcs.map { ($0, 1) }, uniquingKeysWith: +)
            let rankedPCs = pcCounts.sorted { $0.value > $1.value }.map(\.key)

            let rootPC = rankedPCs.first ?? 0
            let chordPCs = buildChordFromPitchClasses(ranked: rankedPCs, rootHint: rootPC, size: chordSize)

            let register = notes.sorted()[notes.count / 2]
            let chordNotes = voiceChord(pcs: chordPCs, around: register, spreadOctaves: spreadOctaves, preferClose: preferCloseVoicing)
                .map { min(max($0, 0), 127) }

            let durationBeats = Double(group.count) * beatLengthPerNote
            let event = ChordEvent(
                startBeat: currentBeat,
                durationBeats: durationBeats,
                notes: chordNotes,
                velocity: chordVelocity,
                channel: channel
            )

            events.append(event)
            currentBeat += durationBeats
        }

        return events
    }

    func buildChordFromPitchClasses(ranked: [Int], rootHint: Int?, size: Int) -> [Int] {
        let root = rootHint ?? ranked.first ?? 0

        var out: [Int] = [root]
        if ranked.contains((root + 4) % 12) {
            out.append((root + 4) % 12) // major
        } else if ranked.contains((root + 3) % 12) {
            out.append((root + 3) % 12) // minor
        }

        if ranked.contains((root + 7) % 12) {
            out.append((root + 7) % 12) // fifth
        }

        if size >= 4, let next = ranked.first(where: { !out.contains($0) }) {
            out.append(next)
        }

        return Array(out.prefix(size))
    }

    func voiceChord(pcs: [Int], around note: Int, spreadOctaves: Int, preferClose: Bool) -> [Int] {
        let baseOct = note / 12
        var result: [Int] = []

        if preferClose {
            var current = baseOct * 12
            for pc in pcs {
                var candidate = current - (current % 12) + pc
                if let last = result.last, candidate <= last { candidate += 12 }
                result.append(candidate)
                current = candidate
            }
        } else {
            for (i, pc) in pcs.enumerated() {
                let offset = (i * spreadOctaves) / max(pcs.count - 1, 1)
                result.append((baseOct + offset) * 12 + pc)
            }
        }

        return result
    }

    func estimatedMelodyNoteCount() -> Int {
        let interval = 12 / divisionsOfOctave
        let count = (12 / interval) * numberOfOctaves

        let interp = modulations.first { $0.type == .interpolation }?.numberOfNewNotes ?? 0
        let infra  = modulations.first { $0.type == .infrapolation }?.numberOfNewNotes ?? 0
        let ultra  = modulations.first { $0.type == .ultrapolation }?.numberOfNewNotes ?? 0

        // Estimate per shifted root
        var notesPerShift = 0
        for i in 0...ultra {
            for j in 0...infra {
                for k in 0...interp {
                    // This matches your logic: sequence + reversed (minus one) = (2 * n - 1)
                    let base = count
                    let variant = NoteSequenceGenerator.estimateVariantLength(baseCount: base, interpolate: k, infrapolate: j, ultrapolate: i)
                    notesPerShift += variant
                }
            }
        }

        let totalShifts = ((maxToneShift / toneIncrement) + 1)
        return totalShifts * notesPerShift
    }
    
    var estimatedDuration: TimeInterval {
        let interval = 12 / divisionsOfOctave
        let count = (12 / interval) * numberOfOctaves

        let interp = modulations.first { $0.type == .interpolation }?.numberOfNewNotes ?? 0
        let infra  = modulations.first { $0.type == .infrapolation }?.numberOfNewNotes ?? 0
        let ultra  = modulations.first { $0.type == .ultrapolation }?.numberOfNewNotes ?? 0

        var notesPerShift = 0
        for i in 0...ultra {
            for j in 0...infra {
                for k in 0...interp {
                    let variant = NoteSequenceGenerator.estimateVariantLength(
                        baseCount: count,
                        interpolate: k,
                        infrapolate: j,
                        ultrapolate: i
                    )
                    notesPerShift += variant
                }
            }
        }

        let shifts = maxToneShift > 0 && toneIncrement > 0
            ? (maxToneShift / toneIncrement) + 1
            : 1

        let totalNotes = shifts * notesPerShift
        return Double(totalNotes) * noteDuration
    }

}

extension Array where Element: BinaryInteger {
    var average: Double {
        guard !isEmpty else { return 0.0 }
        let sum = self.reduce(0) { $0 + Int($1) }  // Convert to Int during summing
        return Double(sum) / Double(self.count)
    }
}


