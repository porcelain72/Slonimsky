//
//  ParameterPanelView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Parameter panel view with collapsible sections
struct ParameterPanelView: View {
    
    // MARK: - Properties
    @ObservedObject var parameterManager: ParameterManager
    @Binding var selectedGenerator: String
    @ObservedObject var midiService: MIDIIntegrationService
    @Binding var isGenerating: Bool
    @Binding var showPresetPicker: Bool
    @Binding var showRandomizeDialog: Bool
    
    // MARK: - State
    @State private var expandedSections: Set<ParameterCategory> = [.basic, .intervals]
    @State private var showGeneratorPicker = false
    @State private var showValidationErrors = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            parameterHeader
            
            // Parameter Sections
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Generator Selection
                    generatorSection
                    
                    // Basic Parameters
                    parameterSection(
                        category: .basic,
                        title: "Basic Parameters",
                        icon: "music.note"
                    ) {
                        BasicParametersView(parameterManager: parameterManager)
                    }
                    
                    // Interval Parameters
                    parameterSection(
                        category: .intervals,
                        title: "Interval Parameters",
                        icon: "arrow.up.and.down"
                    ) {
                        IntervalParametersView(parameterManager: parameterManager)
                    }
                    
                    // Modulation Parameters
                    parameterSection(
                        category: .modulations,
                        title: "Slonimsky Modulations",
                        icon: "waveform.path.ecg"
                    ) {
                        ModulationParametersView(parameterManager: parameterManager)
                    }
                    
                    // Directional Parameters
                    parameterSection(
                        category: .directional,
                        title: "Directional Parameters",
                        icon: "arrow.triangle.turn.up.right.circle"
                    ) {
                        DirectionalParametersView(parameterManager: parameterManager)
                    }
                    
                    // Rhythmic Parameters
                    parameterSection(
                        category: .rhythmic,
                        title: "Rhythmic Parameters",
                        icon: "clock"
                    ) {
                        RhythmicParametersView(parameterManager: parameterManager)
                    }
                    
                    // Harmonic Parameters
                    parameterSection(
                        category: .harmonic,
                        title: "Harmonic Parameters",
                        icon: "music.note.list"
                    ) {
                        HarmonicParametersView(parameterManager: parameterManager)
                    }
                    
                    // Expression Parameters
                    parameterSection(
                        category: .expression,
                        title: "Expression Parameters",
                        icon: "slider.horizontal.3"
                    ) {
                        ExpressionParametersView(parameterManager: parameterManager)
                    }
                }
                .padding()
            }
            
            // Footer Actions
            parameterFooter
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showGeneratorPicker) {
            GeneratorPickerView(selectedGenerator: $selectedGenerator)
        }
        .alert("Parameter Validation Errors", isPresented: $showValidationErrors) {
            Button("OK") { }
        } message: {
            Text(parameterManager.validateParameters().joined(separator: "\n"))
        }
    }
    
    // MARK: - Header
    
    private var parameterHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                Text("Pattern Parameters")
                    .font(.headline)
                Spacer()
            }
            
            // Generator Selection
            HStack {
                Text("Generator:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(selectedGenerator) {
                    showGeneratorPicker = true
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating)
                
                Spacer()
            }
            
            Divider()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Generator Section
    
    private var generatorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pattern Generator")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Button(action: generatePattern) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(isGenerating ? "Generating..." : "Generate Pattern")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
                
                Spacer()
                
                Button(action: { showRandomizeDialog = true }) {
                    Image(systemName: "dice")
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Parameter Section Helper
    
    private func parameterSection<Content: View>(
        category: ParameterCategory,
        title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: { toggleSection(category) }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: expandedSections.contains(category) ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
            }
            .buttonStyle(.plain)
            
            if expandedSections.contains(category) {
                content()
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(8)
    }
    
    // MARK: - Footer
    
    private var parameterFooter: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Button("Presets") {
                    showPresetPicker = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Validate") {
                    let errors = parameterManager.validateParameters()
                    if !errors.isEmpty {
                        showValidationErrors = true
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Reset") {
                    parameterManager.loadDefaultPreset()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Actions
    
    private func toggleSection(_ category: ParameterCategory) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(category) {
                expandedSections.remove(category)
            } else {
                expandedSections.insert(category)
            }
        }
    }
    
    private func generatePattern() {
        isGenerating = true
        
        midiService.generatePatternAndMIDI(
            using: selectedGenerator,
            parameters: parameterManager.currentParameters
        ) { result in
            DispatchQueue.main.async {
                isGenerating = false
                
                switch result {
                case .success(let pattern):
                    print("✅ Pattern generated: \(pattern.notes.count) notes")
                case .failure(let error):
                    print("❌ Pattern generation failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Parameter Section Views

struct BasicParametersView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Root Note
            HStack {
                Text("Root Note:")
                Spacer()
                Stepper("\(parameterManager.rootNote)", value: $parameterManager.rootNote, in: 0...127)
            }
            
            // Scale Type
            HStack {
                Text("Scale Type:")
                Spacer()
                Picker("Scale Type", selection: $parameterManager.scaleType) {
                    ForEach(ScaleType.allCases, id: \.self) { scaleType in
                        Text(scaleType.rawValue.capitalized).tag(scaleType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Number of Octaves
            HStack {
                Text("Octaves:")
                Spacer()
                Stepper("\(parameterManager.numberOfOctaves)", value: $parameterManager.numberOfOctaves, in: 1...8)
            }
            
            // Divisions of Octave
            HStack {
                Text("Divisions:")
                Spacer()
                Stepper("\(parameterManager.divisionsOfOctave)", value: $parameterManager.divisionsOfOctave, in: 2...24)
            }
            
            // Tempo
            HStack {
                Text("Tempo:")
                Spacer()
                Text("\(Int(parameterManager.tempo)) BPM")
            }
            Slider(value: $parameterManager.tempo, in: 20...300, step: 1)
            
            // Time Signature
            HStack {
                Text("Time Signature:")
                Spacer()
                Picker("Time Signature", selection: $parameterManager.timeSignature) {
                    ForEach(TimeSignature.allCases, id: \.self) { signature in
                        Text(signature.rawValue).tag(signature)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct IntervalParametersView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Primary Interval
            HStack {
                Text("Primary Interval:")
                Spacer()
                Stepper("\(parameterManager.primaryInterval)", value: $parameterManager.primaryInterval, in: 1...12)
            }
            
            // Secondary Interval
            HStack {
                Text("Secondary Interval:")
                Spacer()
                Stepper("\(parameterManager.secondaryInterval)", value: $parameterManager.secondaryInterval, in: 1...12)
            }
            
            // Interval Pattern
            HStack {
                Text("Pattern:")
                Spacer()
                Picker("Interval Pattern", selection: $parameterManager.intervalPattern) {
                    ForEach(IntervalPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue.capitalized).tag(pattern)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Interval Inversion
            Toggle("Interval Inversion", isOn: $parameterManager.intervalInversion)
            
            // Symmetrical Intervals
            Toggle("Symmetrical Intervals", isOn: $parameterManager.symmetricalIntervals)
        }
    }
}

struct ModulationParametersView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Interpolation
            modulationSection(
                title: "Interpolation",
                settings: $parameterManager.interpolation
            )
            
            // Infrapolation
            modulationSection(
                title: "Infrapolation",
                settings: $parameterManager.infrapolation
            )
            
            // Ultrapolation
            modulationSection(
                title: "Ultrapolation",
                settings: $parameterManager.ultrapolation
            )
        }
    }
    
    private func modulationSection(
        title: String,
        settings: Binding<ModulationSettings>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: settings.enabled)
            
            if settings.wrappedValue.enabled {
                HStack {
                    Text("Notes:")
                    Spacer()
                    Stepper("\(settings.numberOfNotes.wrappedValue)", value: settings.numberOfNotes, in: 1...10)
                }
                
                HStack {
                    Text("Interval:")
                    Spacer()
                    Stepper("\(settings.interval.wrappedValue)", value: settings.interval, in: 1...12)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct DirectionalParametersView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Primary Direction
            HStack {
                Text("Direction:")
                Spacer()
                Picker("Direction", selection: $parameterManager.primaryDirection) {
                    ForEach(Direction.allCases, id: \.self) { direction in
                        Text(direction.rawValue.capitalized).tag(direction)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Mirror Points
            HStack {
                Text("Mirror Points:")
                Spacer()
                Stepper("\(parameterManager.mirrorPoints)", value: $parameterManager.mirrorPoints, in: 0...5)
            }
            
            // Retrograde Sections
            Toggle("Retrograde Sections", isOn: $parameterManager.retrogradeSections)
            
            // Register Shifts
            HStack {
                Text("Register Shifts:")
                Spacer()
                Picker("Register Shifts", selection: $parameterManager.registerShifts) {
                    ForEach(RegisterShiftPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue.capitalized).tag(pattern)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Contour Pattern
            HStack {
                Text("Contour:")
                Spacer()
                Picker("Contour Pattern", selection: $parameterManager.contourPattern) {
                    ForEach(ContourPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue.capitalized).tag(pattern)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct RhythmicParametersView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Note Duration Pattern
            HStack {
                Text("Duration Pattern:")
                Spacer()
                Picker("Duration Pattern", selection: $parameterManager.noteDurationPattern) {
                    ForEach(DurationPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue.capitalized).tag(pattern)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Base Note Duration
            HStack {
                Text("Base Duration:")
                Spacer()
                Text("\(String(format: "%.3f", parameterManager.baseNoteDuration))s")
            }
            Slider(value: $parameterManager.baseNoteDuration, in: 0.0625...4.0, step: 0.0625)
            
            // Rhythmic Density
            HStack {
                Text("Rhythmic Density:")
                Spacer()
                Text("\(String(format: "%.2f", parameterManager.rhythmicDensity))")
            }
            Slider(value: $parameterManager.rhythmicDensity, in: 0.1...3.0)
            
            // Syncopation Level
            HStack {
                Text("Syncopation:")
                Spacer()
                Text("\(String(format: "%.2f", parameterManager.syncopationLevel))")
            }
            Slider(value: $parameterManager.syncopationLevel, in: 0...1.0)
            
            // Metric Modulation
            Toggle("Metric Modulation", isOn: $parameterManager.metricModulation.enabled)
            
            if parameterManager.metricModulation.enabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Type:")
                        Spacer()
                        Picker("Modulation Type", selection: $parameterManager.metricModulation.modulationType) {
                            ForEach(MetricModulationType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Intensity:")
                        Spacer()
                        Text("\(String(format: "%.2f", parameterManager.metricModulation.intensity))")
                    }
                    Slider(value: $parameterManager.metricModulation.intensity, in: 0.1...1.0)
                    
                    HStack {
                        Text("Frequency:")
                        Spacer()
                        Stepper("\(parameterManager.metricModulation.frequency)", value: $parameterManager.metricModulation.frequency, in: 1...16)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
        }
    }
}

struct HarmonicParametersView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Harmonic Mode
            HStack {
                Text("Harmonic Mode:")
                Spacer()
                Picker("Harmonic Mode", selection: $parameterManager.harmonicMode) {
                    ForEach(HarmonicMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Chord Generation
            Toggle("Chord Generation", isOn: $parameterManager.chordGeneration.enabled)
            
            if parameterManager.chordGeneration.enabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Chord Size:")
                        Spacer()
                        Stepper("\(parameterManager.chordGeneration.chordSize)", value: $parameterManager.chordGeneration.chordSize, in: 2...6)
                    }
                    
                    HStack {
                        Text("Voicing:")
                        Spacer()
                        Picker("Voicing Preference", selection: $parameterManager.chordGeneration.voicingPreference) {
                            ForEach(VoicingPreference.allCases, id: \.self) { preference in
                                Text(preference.rawValue.capitalized).tag(preference)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Velocity Scale:")
                        Spacer()
                        Text("\(String(format: "%.2f", parameterManager.chordGeneration.velocityScale))")
                    }
                    Slider(value: $parameterManager.chordGeneration.velocityScale, in: 0.1...1.0)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            
            // Harmonic Rhythm
            VStack(spacing: 8) {
                HStack {
                    Text("Chord Change Frequency:")
                    Spacer()
                    Stepper("\(parameterManager.harmonicRhythm.chordChangeFrequency)", value: $parameterManager.harmonicRhythm.chordChangeFrequency, in: 1...16)
                }
                
                HStack {
                    Text("Syncopation:")
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.harmonicRhythm.syncopationLevel))")
                }
                Slider(value: $parameterManager.harmonicRhythm.syncopationLevel, in: 0...1.0)
                
                HStack {
                    Text("Harmonic Tension:")
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.harmonicRhythm.harmonicTension))")
                }
                Slider(value: $parameterManager.harmonicRhythm.harmonicTension, in: 0...1.0)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
    }
}

struct ExpressionParametersView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Velocity Settings
            VStack(spacing: 8) {
                HStack {
                    Text("Base Velocity:")
                    Spacer()
                    Text("\(parameterManager.velocitySettings.baseVelocity)")
                }
                Slider(value: Binding(
                    get: { Double(parameterManager.velocitySettings.baseVelocity) },
                    set: { parameterManager.velocitySettings.baseVelocity = UInt8($0) }
                ), in: 1...127, step: 1)
                
                HStack {
                    Text("Velocity Range:")
                    Spacer()
                    Text("\(parameterManager.velocitySettings.range)")
                }
                Slider(value: Binding(
                    get: { Double(parameterManager.velocitySettings.range) },
                    set: { parameterManager.velocitySettings.range = UInt8($0) }
                ), in: 0...127, step: 1)
                
                HStack {
                    Text("Wave Depth:")
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.velocitySettings.waveDepth))")
                }
                Slider(value: $parameterManager.velocitySettings.waveDepth, in: 0...1.0)
                
                HStack {
                    Text("Randomness:")
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.velocitySettings.randomness))")
                }
                Slider(value: $parameterManager.velocitySettings.randomness, in: 0...1.0)
                
                HStack {
                    Text("Phase:")
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.velocitySettings.phase))")
                }
                Slider(value: $parameterManager.velocitySettings.phase, in: 0...2 * .pi)
                
                HStack {
                    Text("Emphasis Beat:")
                    Spacer()
                    Stepper("\(parameterManager.velocitySettings.emphasisBeat)", value: $parameterManager.velocitySettings.emphasisBeat, in: 1...16)
                }
                
                HStack {
                    Text("Emphasis Amount:")
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.velocitySettings.emphasisAmount))")
                }
                Slider(value: $parameterManager.velocitySettings.emphasisAmount, in: 0...1.0)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            // Tone Shifting
            VStack(spacing: 8) {
                HStack {
                    Text("Tone Increment:")
                    Spacer()
                    Stepper("\(parameterManager.toneShifting.toneIncrement)", value: $parameterManager.toneShifting.toneIncrement, in: 0...24)
                }
                
                HStack {
                    Text("Max Tone Shift:")
                    Spacer()
                    Stepper("\(parameterManager.toneShifting.maxToneShift)", value: $parameterManager.toneShifting.maxToneShift, in: 0...96)
                }
                
                HStack {
                    Text("Shift Pattern:")
                    Spacer()
                    Picker("Shift Pattern", selection: $parameterManager.toneShifting.shiftPattern) {
                        ForEach(RegisterShiftPattern.allCases, id: \.self) { pattern in
                            Text(pattern.rawValue.capitalized).tag(pattern)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
    }
}

// MARK: - Supporting Views

struct GeneratorPickerView: View {
    @Binding var selectedGenerator: String
    @Environment(\.dismiss) private var dismiss
    
    private let generators = [
        "Scale Pattern Generator",
        "Interval Pattern Generator",
        "Modulation Pattern Generator",
        "Rhythmic Pattern Generator",
        "Harmonic Pattern Generator",
        "Contour Pattern Generator",
        "Symmetrical Pattern Generator"
    ]
    
    var body: some View {
        NavigationView {
            List(generators, id: \.self) { generator in
                Button(action: {
                    selectedGenerator = generator
                    dismiss()
                }) {
                    HStack {
                        Text(generator)
                        Spacer()
                        if selectedGenerator == generator {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Generator")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct ParameterPanelView_Previews: PreviewProvider {
    static var previews: some View {
        ParameterPanelView(
            parameterManager: ParameterManager(),
            selectedGenerator: .constant("Scale Pattern Generator"),
            midiService: MIDIIntegrationService(),
            isGenerating: .constant(false),
            showPresetPicker: .constant(false),
            showRandomizeDialog: .constant(false)
        )
        .frame(width: 400)
    }
} 