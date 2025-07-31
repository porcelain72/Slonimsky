//
//  MainContentView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Main content view with HSplitView layout: NavigationView on left, PianoRoll on right
struct MainContentView: View {
    
    // MARK: - State Objects
    @StateObject private var midiService = MIDIIntegrationService()
    @StateObject private var parameterManager = ParameterManager()
    
    // MARK: - State Properties
    @State private var selectedGenerator: String = "Scale Pattern Generator"
    @State private var isGenerating = false
    @State private var showPresetPicker = false
    @State private var showRandomizeDialog = false
    @State private var showSheetMusicPopup = false
    @State private var showCyclicalParameters = false
    @State private var selectedParameterCategory: ParameterCategory? = nil
    
    // MARK: - Body
    var body: some View {
        HSplitView {
            // Left Panel: NavigationView with Parameter Categories
            VStack(spacing: 0) {
                NavigationStack {
                    parameterCategoriesList
                        .navigationTitle("Parameters")
                        .toolbar {
                            ToolbarItemGroup(placement: .automatic) {
                                Button(action: { showCyclicalParameters.toggle() }) {
                                    Image(systemName: showCyclicalParameters ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                                    Text("Cycles")
                                }
                            }
                            
                            ToolbarItemGroup(placement: .primaryAction) {
                                Button(action: { showPresetPicker = true }) {
                                    Image(systemName: "list.bullet")
                                    Text("Presets")
                                }
                                .disabled(isGenerating)
                                
                                Button(action: { showRandomizeDialog = true }) {
                                    Image(systemName: "dice")
                                    Text("Random")
                                }
                                .disabled(isGenerating)
                            }
                        }
                }
                
                // Generate Button
                VStack(spacing: 12) {
                    Divider()
                    
                    Button(action: generatePattern) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                            }
                            Text(isGenerating ? "Generating..." : "Generate Pattern")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isGenerating ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isGenerating)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(minWidth: 300, maxWidth: 400)
            
            // Right Panel: Piano Roll
            VStack(spacing: 0) {
                // Cycle Information Display
                if let currentPattern = midiService.currentPattern,
                   currentPattern.metadata.isCyclicalSequence {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                        Text("Cyclical Sequence: \(currentPattern.metadata.totalCycles) cycles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(currentPattern.notes.count) total notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                }
                
                PianoRollPanelView(
                    midiService: midiService,
                    parameterManager: parameterManager
                )
            }
            .frame(minWidth: 500, maxWidth: .infinity)
        }
        .navigationTitle("Slonimsky Pattern Generator")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { showSheetMusicPopup = true }) {
                    Image(systemName: "music.note.list")
                    Text("Sheet Music")
                }
                .disabled(midiService.currentPattern == nil)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: exportCurrentPattern) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .disabled(midiService.currentPattern == nil)
            }
        }
        .sheet(isPresented: $showPresetPicker) {
            PresetPickerView(
                midiService: midiService,
                isGenerating: $isGenerating
            )
        }
        .sheet(isPresented: $showSheetMusicPopup) {
            SheetMusicPopupView(midiService: midiService)
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
        .onAppear {
            setupAutoGeneration()
        }
    }
    
    // MARK: - Parameter Categories List
    
    private var parameterCategoriesList: some View {
        List(ParameterCategory.allCases) { category in
            NavigationLink(destination: parameterCategoryDetailView(for: category)) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.title)
                                .font(.headline)
                            Text(category.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding()
              
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    // MARK: - Parameter Category Detail Views
    
    @ViewBuilder
    private func parameterCategoryDetailView(for category: ParameterCategory) -> some View {
        ScrollView{
            Group{
                switch category {
                case .basic:
                    BasicParametersDetailView(parameterManager: parameterManager)
                        .navigationTitle(category.title)
                case .intervals:
                    IntervalParametersDetailView(parameterManager: parameterManager)
                        .navigationTitle(category.title)
                case .modulations:
                    ModulationParametersDetailView(parameterManager: parameterManager)
                        .navigationTitle(category.title)
                case .directional:
                    DirectionalParametersDetailView(parameterManager: parameterManager)
                        .navigationTitle(category.title)
                case .rhythmic:
                    RhythmicParametersDetailView(parameterManager: parameterManager)
                        .navigationTitle(category.title)
                case .harmonic:
                    HarmonicParametersDetailView(parameterManager: parameterManager)
                        .navigationTitle(category.title)
                case .expression:
                    ExpressionParametersDetailView(parameterManager: parameterManager)
                        .navigationTitle(category.title)
                case .accompaniment:
                    RhythmicAccompanimentDetailView(parameterManager: parameterManager)
                        .navigationTitle(category.title)
                case .autoGeneration:
                    AutoGenerationDetailView(parameterManager: parameterManager, midiService: midiService)
                        .navigationTitle(category.title)
                }
            }
            .padding()
            Spacer()
        }
    }
//    }
    
    // MARK: - Actions
    
    private func generatePattern() {
        isGenerating = true
        
        midiService.generateRandomPattern { result in
            DispatchQueue.main.async {
                isGenerating = false
                
                switch result {
                case .success(let pattern):
                    print("✅ Pattern generated: \(pattern.notes.count) notes")
                    updateSheetMusic(with: pattern)
                case .failure(let error):
                    print("❌ Pattern generation failed: \(error)")
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
    
    private func setupAutoGeneration() {
        // Set up auto-generation with the MIDI service
        midiService.setupAutoGeneration(with: parameterManager)
        print("🔄 Auto-generation setup complete")
    }
}

// MARK: - Preview

struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .frame(minWidth: 800, minHeight: 600)
    }
} 
