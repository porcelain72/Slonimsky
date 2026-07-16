//
//  PresetPickerView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Preset picker view for selecting Slonimsky pattern presets
struct PresetPickerView: View {
    
    // MARK: - Properties
    @ObservedObject var midiService: MIDIIntegrationService
    @Binding var isGenerating: Bool
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var selectedPreset: SlonimskyPreset?
    @State private var showSavePresetDialog = false
    @State private var newPresetName = ""
    @State private var newPresetDescription = ""
    @State private var searchText = ""
    
    // MARK: - Computed Properties
    private var filteredPresets: [SlonimskyPreset] {
        if searchText.isEmpty {
            return defaultPresets
        } else {
            return defaultPresets.filter { preset in
                preset.name.localizedCaseInsensitiveContains(searchText) ||
                preset.description.localizedCaseInsensitiveContains(searchText) ||
                preset.generatorName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Preset List
                presetList
                
                // Footer Actions
                footerActions
            }
            .navigationTitle("Pattern Presets")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save Current") {
                        showSavePresetDialog = true
                    }
                    .disabled(isGenerating)
                }
            }
        }
        .alert("Save Preset", isPresented: $showSavePresetDialog) {
            TextField("Preset Name", text: $newPresetName)
            TextField("Description", text: $newPresetDescription)
            Button("Save") {
                saveCurrentAsPreset()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name and description for your preset")
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search presets...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Preset List
    
    private var presetList: some View {
        List(filteredPresets, id: \.name) { preset in
            PresetRowView(
                preset: preset,
                isSelected: selectedPreset?.name == preset.name
            )
            .onTapGesture {
                selectedPreset = preset
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Footer Actions
    
    private var footerActions: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Button("Load Selected") {
                    loadSelectedPreset()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPreset == nil || isGenerating)
                
                Spacer()
                
                Button("Generate Random") {
                    generateRandomPattern()
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating)
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func loadSelectedPreset() {
        guard let preset = selectedPreset else { return }
        
        isGenerating = true
        
        midiService.generatePresetPattern(preset: preset) { result in
            DispatchQueue.main.async {
                isGenerating = false
                
                switch result {
                case .success(let pattern):
                    print("✅ Preset loaded: \(preset.name)")
                    dismiss()
                case .failure(let error):
                    print("❌ Failed to load preset: \(error)")
                }
            }
        }
    }
    
    private func generateRandomPattern() {
        isGenerating = true
        
        midiService.generateRandomPattern { result in
            DispatchQueue.main.async {
                isGenerating = false
                
                switch result {
                case .success(let pattern):
                    print("✅ Random pattern generated")
                    dismiss()
                case .failure(let error):
                    print("❌ Random pattern generation failed: \(error)")
                }
            }
        }
    }
    
    private func saveCurrentAsPreset() {
        guard !newPresetName.isEmpty else { return }
        
        let preset = SlonimskyPreset(
            name: newPresetName,
            description: newPresetDescription.isEmpty ? "Custom preset" : newPresetDescription,
            generatorName: "Scale Pattern Generator", // Default
            parameters: PatternParameters.default // This would be the current parameters
        )
        
        // In a real implementation, this would save to persistent storage
        print("💾 Preset saved: \(preset.name)")
        
        newPresetName = ""
        newPresetDescription = ""
    }
}

// MARK: - Supporting Views

struct PresetRowView: View {
    let preset: SlonimskyPreset
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .accentColor : .primary)
                    
                    Text(preset.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            
            HStack {
                Label(preset.generatorName, systemImage: "gear")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Parameter preview
                parameterPreview
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
    
    private var parameterPreview: some View {
        HStack(spacing: 4) {
            ParameterBadge(label: "Root", value: "\(preset.parameters.rootNote)")
            ParameterBadge(label: "Scale", value: preset.parameters.scaleType.rawValue.prefix(3).uppercased())
            ParameterBadge(label: "Tempo", value: "\(Int(preset.parameters.tempo))")
        }
    }
}

struct ParameterBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
    }
}

// MARK: - Default Presets

private let defaultPresets: [SlonimskyPreset] = [
    // Basic Scale Patterns
    SlonimskyPreset(
        name: "Chromatic Ascending",
        description: "Basic chromatic scale ascending pattern",
        generatorName: "Scale Pattern Generator",
        parameters: PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 12,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 1.0,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
    ),
    
    SlonimskyPreset(
        name: "Diatonic Melody",
        description: "Traditional diatonic scale melody",
        generatorName: "Scale Pattern Generator",
        parameters: PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 1,
            divisionsOfOctave: 7,
            tempo: 100.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 2,
            intervalPattern: .alternating,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .arch,
            baseNoteDuration: 2.0,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
    ),
    
    // Interval Patterns
    SlonimskyPreset(
        name: "Interval Cycles",
        description: "Complex interval cycle patterns",
        generatorName: "Interval Pattern Generator",
        parameters: PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 12,
            tempo: 140.0,
            meter: .fourFour,
            primaryInterval: 3,
            secondaryInterval: 4,
            intervalPattern: .mirror,
            intervalInversion: true,
            symmetricalIntervals: true,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 2,
            retrogradeSections: true,
            registerShifts: .linear,
            contourPattern: .wave,
            baseNoteDuration: 1.0,
            harmonicMode: .atonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
    ),
    
    // Modulation Patterns
    SlonimskyPreset(
        name: "Slonimsky Modulations",
        description: "Advanced interpolation and infrapolation",
        generatorName: "Modulation Pattern Generator",
        parameters: PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 3,
            divisionsOfOctave: 12,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 2,
            secondaryInterval: 3,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: ModulationSettings(numberOfNotes: 2, interval: 1, enabled: true),
            infrapolation: ModulationSettings(numberOfNotes: 1, interval: 2, enabled: true),
            ultrapolation: ModulationSettings(numberOfNotes: 1, interval: 3, enabled: true),
            primaryDirection: .ascending,
            mirrorPoints: 1,
            retrogradeSections: false,
            registerShifts: .exponential,
            contourPattern: .invertedArch,
            baseNoteDuration: 1.0,
            harmonicMode: .polymodal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
    ),
    
    // Rhythmic Patterns
    SlonimskyPreset(
        name: "Rhythmic Complexity",
        description: "Pentatonic pattern in 7/8 (2+2+3) with accented groupings",
        generatorName: "Scale Pattern Generator",
        parameters: PatternParameters(
            rootNote: 60,
            scaleType: .pentatonic,
            numberOfOctaves: 2,
            divisionsOfOctave: 5,
            tempo: 160.0,
            meter: .sevenEight,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 0.5,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
    ),
    
    // Harmonic Patterns
    SlonimskyPreset(
        name: "Harmonic Progression",
        description: "Complex harmonic patterns with chord generation",
        generatorName: "Harmonic Pattern Generator",
        parameters: PatternParameters(
            rootNote: 60,
            scaleType: .diatonic,
            numberOfOctaves: 2,
            divisionsOfOctave: 7,
            tempo: 100.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .linear,
            baseNoteDuration: 2.0,
            harmonicMode: .tonal,
            chordGeneration: ChordSettings(enabled: true, chordSize: 3, voicingPreference: .close, velocityScale: 0.8),
            harmonicRhythm: HarmonicRhythmSettings(chordChangeFrequency: 2, syncopationLevel: 0.3, harmonicTension: 0.5),
            velocitySettings: .default,
            toneShifting: .default
        )
    ),
    
    // Contour Patterns
    SlonimskyPreset(
        name: "Melodic Contours",
        description: "Expressive melodic contour patterns",
        generatorName: "Contour Pattern Generator",
        parameters: PatternParameters(
            rootNote: 60,
            scaleType: .chromatic,
            numberOfOctaves: 2,
            divisionsOfOctave: 12,
            tempo: 90.0,
            meter: .fourFour,
            primaryInterval: 1,
            secondaryInterval: 1,
            intervalPattern: .ascending,
            intervalInversion: false,
            symmetricalIntervals: false,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 0,
            retrogradeSections: false,
            registerShifts: .none,
            contourPattern: .wave,
            baseNoteDuration: 2.0,
            harmonicMode: .tonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: VelocitySettings(baseVelocity: 80, range: 40, waveDepth: 0.6, randomness: 0.2, phase: 0.5, emphasisBeat: 4, emphasisAmount: 0.4),
            toneShifting: .default
        )
    ),
    
    // Symmetrical Patterns
    SlonimskyPreset(
        name: "Symmetrical Inversions",
        description: "Symmetrical patterns with inversions and retrogrades",
        generatorName: "Symmetrical Pattern Generator",
        parameters: PatternParameters(
            rootNote: 60,
            scaleType: .octatonic,
            numberOfOctaves: 2,
            divisionsOfOctave: 8,
            tempo: 120.0,
            meter: .fourFour,
            primaryInterval: 2,
            secondaryInterval: 2,
            intervalPattern: .mirror,
            intervalInversion: true,
            symmetricalIntervals: true,
            interpolation: .default,
            infrapolation: .default,
            ultrapolation: .default,
            primaryDirection: .ascending,
            mirrorPoints: 3,
            retrogradeSections: true,
            registerShifts: .symmetrical,
            contourPattern: .mirror,
            baseNoteDuration: 1.0,
            harmonicMode: .atonal,
            chordGeneration: .default,
            harmonicRhythm: .default,
            velocitySettings: .default,
            toneShifting: .default
        )
    )
]

// MARK: - Preview

struct PresetPickerView_Previews: PreviewProvider {
    static var previews: some View {
        PresetPickerView(
            midiService: MIDIIntegrationService(),
            isGenerating: .constant(false)
        )
        .frame(width: 500, height: 600)
    }
} 