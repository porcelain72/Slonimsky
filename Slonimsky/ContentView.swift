
//
//  ContentView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 22/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
 

    @State private var sequence: [MIDIInfo] = []
    @State private var isPlaying: Bool = false
    @State private var currentNoteIndex: Int? = nil
    
    @StateObject private var sequencer = SlonimskySequencer()
    @StateObject private var sheetMusicVM = SheetMusicViewModel()

    @StateObject var audioPlayer = AudioPlayer()
    
    
    var body: some View {
            HStack(alignment: .top) {
                // Controls on the left
                ParameterControlsView(sequencer: sequencer)
                    .frame(minWidth: 300)
                    .padding()

                // Sheet music view on the right
                SheetMusicView(viewModel: sheetMusicVM)
                    .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Share") {
                        //sheetMusicVM.sharePDFandMIDI(from: sequencer)
                    }
                }
            }
            .onChange(of: sequencer.melodySubsequences) { _ in
                sheetMusicVM.updateFromSequencer(sequencer)
            }
        }
    
    func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, sec)
    }

    
    func export(){
        sequencer.generate()
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "Export.mid"
        savePanel.allowedContentTypes = [.midi]

        savePanel.begin { result in
            if result == .OK, let finalURL = savePanel.url {
                var fixedURL = finalURL
                if fixedURL.pathExtension.lowercased() != "mid" {
                    fixedURL.deletePathExtension()
                    fixedURL.appendPathExtension("mid")
                }

                do {
                    try MIDIExporter.exportMIDI(
                        melodyTracks: sequencer.melodySubsequences,
                        chordEvents: sequencer.chords,
                        noteDuration: sequencer.noteDuration,
                        bpm: sequencer.bpm,
                        fileURL: fixedURL
                    )
                    print("✅ MIDI written to \(fixedURL)")
                } catch {
                    print("❌ Export error: \(error)")
                }
            }
        }

    }
}

#Preview {
    ContentView()
}
