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
        stop() // Stop any existing playback

        guard !notes.isEmpty else {
            completion?()
            return
        }

        if !engine.isRunning {
            do {
                try engine.start()
                print("✅ Engine restarted before playback.")
            } catch {
                print("❌ Failed to start engine before playback: \(error)")
            }
        }

        let startTime = DispatchTime.now()
        let beatInterval = duration

        var tasks: [DispatchWorkItem] = []

        for (index, note) in notes.enumerated() {
            let scheduledTime = startTime + beatInterval * Double(index)

            // Note-on task
            let onTask = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                let noteValue = UInt8(clamping: note.note)
                self.sampler.startNote(noteValue, withVelocity: note.velocity, onChannel: 0)
                DispatchQueue.main.async {
                    self.currentNoteIndex = index
                }
            }

            // Note-off task
            let offTask = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                let noteValue = UInt8(clamping: note.note)
                self.sampler.stopNote(noteValue, onChannel: 0)
                if index == notes.count - 1 {
                    DispatchQueue.main.async {
                        self.currentNoteIndex = nil
                        completion?()
                    }
                }
            }

            // Schedule both tasks
            queue.asyncAfter(deadline: scheduledTime, execute: onTask)
            queue.asyncAfter(deadline: scheduledTime + beatInterval, execute: offTask)

            tasks.append(onTask)
            tasks.append(offTask)
        }

        // Save references if you want to cancel later
        self.playbackTask = DispatchWorkItem {
            tasks.forEach { $0.cancel() }
        }
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

