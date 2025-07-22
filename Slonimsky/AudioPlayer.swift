
import AVFoundation

class AudioPlayer {
    private var audioEngine = AVAudioEngine()
    private var sampler = AVAudioUnitSampler()

    init() {
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)

        // Load gs_instruments.dls
        let soundBankURL = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        do {
            try sampler.loadInstrument(at: soundBankURL)
            print("gs_instruments.dls loaded successfully.")
        } catch {
            print("Error loading sound bank: \(error.localizedDescription)")
        }

        do {
            try audioEngine.start()
            print("AudioEngine started successfully.")
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }

    func play(notes: [Int]) {
        for (index, note) in notes.enumerated() {
            let noteOn: UInt8 = 0x90
            let noteOff: UInt8 = 0x80
            let channel: UInt8 = 0
            let velocity: UInt8 = 100

            let delay = TimeInterval(index) * 0.5

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.sampler.startNote(UInt8(note), withVelocity: velocity, onChannel: channel)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
                self.sampler.stopNote(UInt8(note), onChannel: channel)
            }
        }
    }
}
