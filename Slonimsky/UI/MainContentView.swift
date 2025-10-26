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
    
    init() {
        print("🎵 MainContentView: Initializing")
        print("🎵 MainContentView: Creating ParameterManager and MIDIIntegrationService")
    }
    
    // MARK: - State Properties
    @State private var selectedGenerator: String = "Scale Pattern Generator"
    @State private var isGenerating = false
    @State private var showPresetPicker = false
    @State private var showRandomizeDialog = false
    @State private var showSheetMusicPopup = false
    @State private var showCyclicalParameters = false
    @State private var selectedParameterCategory: ParameterCategory? = .basic
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 0) {
            // Left: Parameter List
            parameterListPanel
            
            // Center: Selected Parameter Controls
            parameterDetailPanel
            
            // Right: MIDI Controls Sidebar
            midiControlsSidebar
        }
        .background(Color.garageBandBackground)
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
    
    // MARK: - Panel Views
    
    private var parameterListPanel: some View {
        VStack(spacing: 0) {
            // Parameters Header
            HStack {
                Text("Parameters")
                    .font(.headline)
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Button("Cycles") {
                    showCyclicalParameters.toggle()
                }
                .buttonStyle(.bordered)
                .foregroundColor(Color.garageBandAccent)
            }
            .padding()
            .background(Color.garageBandPanel)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.garageBandBorder),
                alignment: .bottom
            )
            
            // Parameter List
            List(ParameterCategory.allCases, selection: $selectedParameterCategory) { category in
                    HStack {
                        Image(systemName: category.icon)
                        .foregroundColor(Color.garageBandAccent)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.title)
                                .font(.headline)
                            .foregroundColor(Color.garageBandText)
                            Text(category.description)
                                .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                                .lineLimit(2)
                    }
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedParameterCategory = category
                }
                .background(
                    selectedParameterCategory == category ? 
                    Color.garageBandAccent.opacity(0.2) : Color.clear
                )
            }
            .listStyle(SidebarListStyle())
            .scrollContentBackground(.hidden)
            .background(Color.garageBandBackground)
            
            // Reset and Generate Buttons
            VStack(spacing: 12) {
                Divider()
                    .background(Color.garageBandBorder)
                
                // Reset Button
                Button(action: {
                    parameterManager.resetToDefaults()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        Text("Reset to Defaults")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.garageBandPanel)
                    .foregroundColor(Color.garageBandText)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.garageBandBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Generate Button
                Button(action: generatePattern) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.garageBandText))
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                        }
                        Text(isGenerating ? "Generating..." : "Generate Pattern")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isGenerating ? Color.garageBandSecondary.opacity(0.3) : Color.garageBandAccent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isGenerating)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.garageBandPanel)
        }
        .frame(width: 250)
        .background(Color.garageBandBackground)
    }
    
    private var parameterDetailPanel: some View {
        VStack(spacing: 0) {
            // Detail Header
            HStack {
                if let category = selectedParameterCategory {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(Color.garageBandAccent)
                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(Color.garageBandText)
                } else {
                    Text("Select a Parameter Category")
                        .font(.headline)
                        .foregroundColor(Color.garageBandSecondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.garageBandPanel)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.garageBandBorder),
                alignment: .bottom
            )
            
            // Parameter Controls
            if let category = selectedParameterCategory {
                ScrollView {
                    parameterCategoryDetailView(for: category)
                        .padding()
                }
                .background(Color.garageBandBackground)
            } else {
                VStack {
                    Spacer()
                    Text("Choose a parameter category from the list to configure settings")
                        .font(.subheadline)
                        .foregroundColor(Color.garageBandSecondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.garageBandBackground)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var midiControlsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MIDI Header
            HStack {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundColor(Color.garageBandAccent)
                Text("MIDI")
                    .font(.headline)
                    .foregroundColor(Color.garageBandText)
                Spacer()
                
                Button("Sheet Music") {
                    showSheetMusicPopup = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(Color.garageBandAccent)
                .disabled(midiService.currentPattern == nil)
            }
            .padding()
            .background(Color.garageBandPanel)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.garageBandBorder),
                alignment: .bottom
            )
            
            // MIDI Controls - Top Aligned
            MIDIPlaybackControllerView(midiService: midiService)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            // Auto-generation Settings
            VStack(alignment: .leading, spacing: 0) {
                // Auto-generation Header
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.title2)
                        .foregroundColor(Color.garageBandAccent)
                    Text("Auto-generation")
                        .font(.headline)
                        .foregroundColor(Color.garageBandText)
                    Spacer()
                }
                .padding()
                .background(Color.garageBandPanel)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.garageBandBorder),
                    alignment: .bottom
                )
                
                // Auto-generation Settings
                AutoGenerationSettingsView(
                    parameterManager: parameterManager,
                    midiService: midiService
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 300, alignment: .topLeading)
        .background(Color.garageBandBackground)
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
                }
            }
            .padding()
            Spacer()
        }
    }
//    }
    
    // MARK: - Actions
    
    private func generatePattern() {
        print("🎵 MainContentView: Generate Pattern button pressed")
        print("🎵 MainContentView: Current parameters:")
        print("   Root Note: \(parameterManager.rootNote)")
        print("   Scale Type: \(parameterManager.scaleType.rawValue)")
        print("   Number of Octaves: \(parameterManager.numberOfOctaves)")
        print("   Active Generators: \(parameterManager.activeGenerators)")
        print("   Combination Mode: \(parameterManager.combinationMode.rawValue)")
        
        isGenerating = true
        
        // Use current parameters instead of random ones
        let currentParameters = parameterManager.currentParameters
        
        // Check if cyclical parameters are enabled
        let enabledCyclicalParameters = currentParameters.cyclicalSettings.enabledParameters
        let hasCyclicalParameters = !enabledCyclicalParameters.isEmpty
        
        if hasCyclicalParameters {
            print("🔄 Cyclical parameters detected: \(enabledCyclicalParameters.keys.map { $0.rawValue }.joined(separator: ", "))")
            
            // Use cyclical generation
            if parameterManager.activeGenerators.count > 1 {
                print("🔄 Using combined cyclical generation with \(parameterManager.activeGenerators.count) generators")
                
                midiService.generateCombinedCyclicalPatternAndMIDI(
                    using: parameterManager.activeGenerators,
                    parameters: currentParameters,
                    combinationMode: parameterManager.combinationMode
                ) { result in
                    DispatchQueue.main.async {
                        isGenerating = false
                        
                        switch result {
                        case .success(let pattern):
                            print("✅ MainContentView: Cyclical pattern generated successfully")
                            print("   Generated \(pattern.notes.count) notes")
                            print("   Generation time: \(pattern.performance.generationTime)s")
                            print("   Memory usage: \(pattern.performance.memoryUsage) bytes")
                            updateSheetMusic(with: pattern)
                        case .failure(let error):
                            print("❌ MainContentView: Cyclical pattern generation failed: \(error)")
                        }
                    }
                }
            } else {
                let generatorName = parameterManager.activeGenerators.first ?? "Scale Pattern Generator"
                print("🔄 Using single generator with cyclical generation: \(generatorName)")
                
                midiService.generateCyclicalPatternAndMIDI(using: generatorName, parameters: currentParameters) { result in
                    DispatchQueue.main.async {
                        isGenerating = false
                        
                        switch result {
                        case .success(let pattern):
                            print("✅ MainContentView: Cyclical pattern generated successfully")
                            print("   Generated \(pattern.notes.count) notes")
                            print("   Generation time: \(pattern.performance.generationTime)s")
                            print("   Memory usage: \(pattern.performance.memoryUsage) bytes")
                            updateSheetMusic(with: pattern)
                        case .failure(let error):
                            print("❌ MainContentView: Cyclical pattern generation failed: \(error)")
                        }
                    }
                }
            }
        } else {
            // No cyclical parameters, use regular generation
            if parameterManager.activeGenerators.count > 1 {
                midiService.generateCombinedPatternAndMIDI(
                    using: parameterManager.activeGenerators,
                    parameters: currentParameters,
                    combinationMode: parameterManager.combinationMode
                ) { result in
                    DispatchQueue.main.async {
                        isGenerating = false
                        
                        switch result {
                        case .success(let pattern):
                            print("✅ MainContentView: Pattern generated successfully")
                            print("   Generated \(pattern.notes.count) notes")
                            print("   Generation time: \(pattern.performance.generationTime)s")
                            print("   Memory usage: \(pattern.performance.memoryUsage) bytes")
                            updateSheetMusic(with: pattern)
                        case .failure(let error):
                            print("❌ MainContentView: Pattern generation failed: \(error)")
                        }
                    }
                }
            } else {
                // Use single generator
                let generatorName = parameterManager.activeGenerators.first ?? "Scale Pattern Generator"
                
                midiService.generatePatternAndMIDI(using: generatorName, parameters: currentParameters) { result in
                DispatchQueue.main.async {
                    isGenerating = false
                    
                    switch result {
                    case .success(let pattern):
                            print("✅ MainContentView: Pattern generated successfully")
                            print("   Generated \(pattern.notes.count) notes")
                            print("   Generation time: \(pattern.performance.generationTime)s")
                            print("   Memory usage: \(pattern.performance.memoryUsage) bytes")
                        updateSheetMusic(with: pattern)
                    case .failure(let error):
                            print("❌ MainContentView: Pattern generation failed: \(error)")
                        }
                    }
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
