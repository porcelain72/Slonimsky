import Foundation

class SlonimskySequencer: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var melodySubsequences: [[MIDIInfo]] = []
    @Published var chords: [Chord] = []

    private let audioPlayer = AudioPlayer()
    private let chordPlayer = AudioPlayer()

    private var playbackTasks: [DispatchWorkItem] = []

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
        let interval = 12 / divisionsOfOctave
        let count = (12 / interval) * numberOfOctaves

        let interp = modulations.first { $0.type == .interpolation }
        let infra  = modulations.first { $0.type == .infrapolation }
        let ultra  = modulations.first { $0.type == .ultrapolation }

        // Build structured melody
        melodySubsequences = NoteSequenceGenerator.buildAllSubsequences(
            startNote: rootNote,
            interval: interval,
            count: count,
            maxInterpolate: interp?.numberOfNewNotes ?? 0,
            maxInfrapolate: infra?.numberOfNewNotes ?? 0,
            maxUltrapolate: ultra?.numberOfNewNotes ?? 0,
            model: model
        )

        // Generate one chord per subsequence
        chords = melodySubsequences.enumerated().map { (i, _) in
            let root = rootNote + (i * interval)
            let chordNotes = (0..<chordParams.chordSize).map { j in root + j * interval }
            let velocity = calculateVelocity(index: i, note: root, model: model)
            return Chord(notes: chordNotes, velocity: velocity, channel: 1)
        }
    }

    func play() {
        stop() // Cancel old tasks
        generate()
        isPlaying = true

        let beatDuration = 60.0 / bpm
        let noteTime = noteDuration * beatDuration

        var startTime: TimeInterval = 0

        for (i, subsequence) in melodySubsequences.enumerated() {
            let chord = chords[i]
            let duration = Double(subsequence.count) * noteTime

            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }

                // Play chord
                for note in chord.notes {
                    self.chordPlayer.startNote(UInt8(clamping: note), velocity: chord.velocity, channel: chord.channel)
                }

                // Play melody notes
                for (j, note) in subsequence.enumerated() {
                    self.audioPlayer.startNote(UInt8(clamping: note.note), velocity: note.velocity, channel: 0)
                    Thread.sleep(forTimeInterval: noteTime)
                    self.audioPlayer.stopNote(UInt8(clamping: note.note), channel: 0)
                }

                // Stop chord after melody segment
                for note in chord.notes {
                    self.chordPlayer.stopNote(UInt8(clamping: note), channel: chord.channel)
                }

                if i == self.melodySubsequences.count - 1 {
                    DispatchQueue.main.async {
                        self.isPlaying = false
                    }
                }
            }

            playbackTasks.append(task)
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + startTime, execute: task)

            startTime += duration
        }
    }

    func stop() {
        playbackTasks.forEach { $0.cancel() }
        playbackTasks.removeAll()
        audioPlayer.stop()
        chordPlayer.stop()
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
}
