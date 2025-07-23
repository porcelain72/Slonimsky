import Foundation
import AVFoundation
import AudioToolbox
import SwiftUI

class AudioPlayer : ObservableObject {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private let queue = DispatchQueue(label: "AudioPlayerQueue")

    private var playbackTask: DispatchWorkItem?
    private let lock = NSLock()

    @Published var currentNoteIndex: Int? = nil

    init() {
        setupAudio()
    }

    private func setupAudio() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
        } catch {
            print("❌ Failed to start engine: \(error)")
        }

        loadPianoSound()
    }
    func testNote() {
        let note: UInt8 = 60
        let velocity: UInt8 = 100

        do {
            if !engine.isRunning {
                try engine.start()
            }
            sampler.startNote(note, withVelocity: velocity, onChannel: 0)
            print("🎵 Played test note \(note)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.sampler.stopNote(note, onChannel: 0)
            }
        } catch {
            print("❌ Could not start engine: \(error)")
        }
    }

    private func loadPianoSound() {
        let soundBank = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        
        do {
            try sampler.loadSoundBankInstrument(
                at: soundBank,
                program: 0,  // Acoustic Grand Piano
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            print("✅ Piano sound loaded.")
        } catch {
            print("❌ Failed to load piano sound: \(error)")
        }
    }

    func startNote(_ note: UInt8, velocity: UInt8 = 100, channel: UInt8 = 0) {
        DispatchQueue.main.async {
            self.sampler.startNote(note, withVelocity: velocity, onChannel: channel)
        }
    }

    func stopNote(_ note: UInt8, channel: UInt8 = 0) {
        DispatchQueue.main.async {
            self.sampler.stopNote(note, onChannel: channel)
        }
    }

    func play(notes: [MIDIInfo], duration: TimeInterval, completion: (() -> Void)?) {
        // stop()  // Optional: cancel existing playback

        if !engine.isRunning {
            do {
                try engine.start()
                print("✅ Engine restarted before playback.")
            } catch {
                print("❌ Failed to start engine before playback: \(error)")
            }
        }

        var task: DispatchWorkItem!  // must be var to allow reference inside itself

        task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            for (index, note) in notes.enumerated() {
                if task.isCancelled {
                    DispatchQueue.main.async { self.currentNoteIndex = nil }
                    completion?()
                    break
                }

                DispatchQueue.main.async {
                    self.currentNoteIndex = index
                }

                let noteValue = UInt8(note.note)
                self.sampler.startNote(noteValue, withVelocity: note.velocity, onChannel: 0)

                let noteEndTime = Date().addingTimeInterval(duration)
                while Date() < noteEndTime {
                    if task.isCancelled {
                        self.sampler.stopNote(noteValue, onChannel: 0)
                        DispatchQueue.main.async { self.currentNoteIndex = nil }
                        completion?()
                        return
                    }
                    Thread.sleep(forTimeInterval: 0.05)
                }

                self.sampler.stopNote(noteValue, onChannel: 0)
            }

            DispatchQueue.main.async {
                self.currentNoteIndex = nil
                completion?()
            }
        }

        playbackTask = task
        queue.async(execute: task)  // ✅ THIS LINE RUNS THE TASK!
    }



    func stop() {
        lock.lock()
        playbackTask?.cancel()
        playbackTask = nil
        lock.unlock()

        // Optionally: stop all possible active notes (if using a fixed range)
        for note in 0...127 {
            sampler.stopNote(UInt8(note), onChannel: 0)
        }
        DispatchQueue.main.async {
            self.currentNoteIndex = nil
        }

        print("🛑 Playback stopped.")
    }
}

