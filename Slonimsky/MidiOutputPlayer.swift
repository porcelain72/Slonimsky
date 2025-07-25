//
//  MidiOutputPlayer.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 25/07/2025.
//

import Foundation
import CoreMIDI

class MIDIOutputPlayer {
    private var midiClient = MIDIClientRef()
    private var outputPort = MIDIPortRef()
    private var destinations: [MIDIEndpointRef] {
         var dests: [MIDIEndpointRef] = []
         let count = MIDIGetNumberOfDestinations()
         for i in 0..<count {
             dests.append(MIDIGetDestination(i))
         }
         return dests
     }
    
    private var isRunning = false
    private var stopRequested = false

    init() {
        MIDIClientCreate("MIDI Output Client" as CFString, nil, nil, &midiClient)
        MIDIOutputPortCreate(midiClient, "Output Port" as CFString, &outputPort)
    }

    var hasAvailableDestination: Bool {
        return !destinations.isEmpty
    }



    private func sendMIDI(status: UInt8, data1: UInt8, data2: UInt8, channel: UInt8 = 0) {
        guard let destination = destinations.first else {
                  print("⚠️ No MIDI destinations available.")
                  return
              }
        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length = 3
        packet.data.0 = status | channel
        packet.data.1 = data1
        packet.data.2 = data2

        var list = MIDIPacketList(numPackets: 1, packet: packet)
        MIDISend(outputPort, destination, &list)
    }

    func play(melody: [[MIDIInfo]], chords: [ChordEvent], noteDuration: TimeInterval, bpm: Double) {
        stopRequested = false
        isRunning = true

        let beatDuration = noteDuration * (bpm / 60.0)
        let queue = DispatchQueue(label: "MIDIOutputQueue", qos: .userInitiated)

        queue.async { [weak self] in
            guard let self = self else { return }

            let startTime = DispatchTime.now()

            // Schedule melody
            var melodyBeat: Double = 0.0
            for subSeq in melody {
                for note in subSeq {
                    let delay = melodyBeat * 60.0 / bpm
                    self.scheduleNote(note: note, delay: delay, duration: beatDuration)
                    melodyBeat += beatDuration
                }
                melodyBeat += beatDuration * 0.5 // optional spacing
            }

            // Schedule chords
            for chord in chords {
                let delay = chord.startBeat * 60.0 / bpm
                self.scheduleChord(chord, delay: delay)
            }

            // Wait for completion
            let totalDuration = melodyBeat * 60.0 / bpm + 1.0
            Thread.sleep(forTimeInterval: totalDuration)
            self.isRunning = false
        }
    }

    private func scheduleNote(note: MIDIInfo, delay: TimeInterval, duration: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, !self.stopRequested else { return }
            self.sendMIDI(status: 0x90, data1: UInt8(clamping: note.note), data2: note.velocity)

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.sendMIDI(status: 0x80, data1: UInt8(clamping: note.note), data2: 0)
            }
        }
    }

    private func scheduleChord(_ chord: ChordEvent, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, !self.stopRequested else { return }
            for note in chord.notes {
                self.sendMIDI(status: 0x90, data1: UInt8(clamping: note), data2: chord.velocity, channel: chord.channel)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + chord.durationBeats * 60.0 / 120.0) {
                for note in chord.notes {
                    self.sendMIDI(status: 0x80, data1: UInt8(clamping: note), data2: 0, channel: chord.channel)
                }
            }
        }
    }
/*
    func stop() {
        stopRequested = true
        isRunning = false

        for note in 0...127 {
            sendMIDI(status: 0x80, data1: UInt8(note), data2: 0)
        }
    }
*/
    func stop() {
        let allNotesOff: [UInt8] = [0xB0, 123, 0] // 123 = All Notes Off controller
        let destinations = MIDIGetNumberOfDestinations()

        for i in 0..<destinations {
            let destination = MIDIGetDestination(i)
            var packetList = MIDIPacketList()
            var packet = MIDIPacketListInit(&packetList)
            packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, allNotesOff.count, allNotesOff)
            MIDISend(outputPort, destination, &packetList)
        }

        print("🔇 Sent All Notes Off")
    }

    func isPlaying() -> Bool {
        return isRunning
    }
}
