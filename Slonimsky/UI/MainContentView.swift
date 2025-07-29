//
//  MainContentView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Main content view with three-panel layout
struct MainContentView: View {
    
    // MARK: - State Objects
    @StateObject private var midiService = MIDIIntegrationService()
    @StateObject private var parameterManager = ParameterManager()
    @StateObject private var sheetMusicVM = SheetMusicViewModel()
    
    // MARK: - State Properties
    @State private var selectedGenerator: String = "Scale Pattern Generator"
    @State private var showPianoRoll = true
    @State private var showSheetMusic = true
    @State private var showParameterControls = true
    @State private var isGenerating = false
    @State private var showPresetPicker = false
    @State private var showRandomizeDialog = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            HSplitView {
                // Left Panel: Parameter Controls
                if showParameterControls {
                    ParameterPanelView(
                        parameterManager: parameterManager,
                        selectedGenerator: $selectedGenerator,
                        midiService: midiService,
                        isGenerating: $isGenerating,
                        showPresetPicker: $showPresetPicker,
                        showRandomizeDialog: $showRandomizeDialog
                    )
                    .frame(minWidth: 350, maxWidth: 450)
                }
                
                // Center Panel: Piano Roll
                if showPianoRoll {
                    PianoRollPanelView(
                        midiService: midiService,
                        parameterManager: parameterManager
                    )
                    .frame(minWidth: 400, maxWidth: .infinity)
                }
                
                // Right Panel: Sheet Music
                if showSheetMusic {
                    SheetMusicPanelView(
                        sheetMusicVM: sheetMusicVM,
                        midiService: midiService
                    )
                    .frame(minWidth: 400, maxWidth: .infinity)
                }
            }
            .navigationTitle("Slonimsky Pattern Generator")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    // Panel Visibility Toggles
                    Button(action: { showParameterControls.toggle() }) {
                        Image(systemName: showParameterControls ? "slider.horizontal.3" : "slider.horizontal.3.slash")
                        Text("Parameters")
                    }
                    
                    Button(action: { showPianoRoll.toggle() }) {
                        Image(systemName: showPianoRoll ? "pianokeys" : "pianokeys.slash")
                        Text("Piano Roll")
                    }
                    
                    Button(action: { showSheetMusic.toggle() }) {
                        Image(systemName: showSheetMusic ? "music.note.list" : "music.note.list.slash")
                        Text("Sheet Music")
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    // Quick Actions
                    Button(action: generateRandomPattern) {
                        Image(systemName: "dice")
                        Text("Random")
                    }
                    .disabled(isGenerating)
                    
                    Button(action: { showPresetPicker = true }) {
                        Image(systemName: "list.bullet")
                        Text("Presets")
                    }
                    .disabled(isGenerating)
                    
                    Button(action: exportCurrentPattern) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .disabled(midiService.currentPattern == nil)
                }
            }
        }
        .sheet(isPresented: $showPresetPicker) {
            PresetPickerView(
                midiService: midiService,
                isGenerating: $isGenerating
            )
        }
        .alert("Randomize Parameters", isPresented: $showRandomizeDialog) {
            Button("Randomize All") {
                randomizeAllParameters()
            }
            Button("Randomize Selected") {
                randomizeSelectedParameters()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose which parameters to randomize")
        }
    }
    
    // MARK: - Actions
    
    private func generateRandomPattern() {
        isGenerating = true
        
        midiService.generateRandomPattern { result in
            DispatchQueue.main.async {
                isGenerating = false
                
                switch result {
                case .success(let pattern):
                    print("✅ Random pattern generated: \(pattern.notes.count) notes")
                    updateSheetMusic(with: pattern)
                case .failure(let error):
                    print("❌ Random pattern generation failed: \(error)")
                }
            }
        }
    }
    
    private func randomizeAllParameters() {
        parameterManager.randomizeAllParameters()
    }
    
    private func randomizeSelectedParameters() {
        parameterManager.randomizeSelectedParameters()
    }
    
    private func exportCurrentPattern() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.midi]
        panel.nameFieldStringValue = "slonimsky_pattern.mid"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let success = midiService.exportToMIDI(url: url)
                if success {
                    print("✅ MIDI file exported successfully")
                } else {
                    print("❌ Failed to export MIDI file")
                }
            }
        }
    }
    
    private func updateSheetMusic(with pattern: PatternGenerationResult) {
        // Update sheet music view model with new pattern
        // This will be implemented when we integrate with Salieri
        print("📝 Sheet music updated with \(pattern.notes.count) notes")
    }
}

// MARK: - Preview

struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .frame(minWidth: 1200, minHeight: 800)
    }
} 