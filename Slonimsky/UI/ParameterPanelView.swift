//
//  ParameterPanelView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Parameter panel view with navigation-based categories
struct ParameterPanelView: View {
    
    // MARK: - Properties
    @ObservedObject var parameterManager: ParameterManager
    @Binding var selectedGenerator: String
    @ObservedObject var midiService: MIDIIntegrationService
    @Binding var isGenerating: Bool
    @Binding var showPresetPicker: Bool
    @Binding var showRandomizeDialog: Bool
    
    // MARK: - State
    @State private var selectedCategory: ParameterCategory = .basic
    @State private var showGeneratorPicker = false
    @State private var showValidationErrors = false
    @State private var showInfoPopup = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            // Sidebar with parameter categories
            List(ParameterCategory.allCases, id: \.self, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        Text(category.title)
                        Spacer()
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, maxWidth: 250)
            .navigationTitle("Parameters")
            
            // Detail view for selected category
            ParameterCategoryDetailView(
                category: selectedCategory,
                parameterManager: parameterManager,
                selectedGenerator: $selectedGenerator,
                midiService: midiService,
                isGenerating: $isGenerating,
                showPresetPicker: $showPresetPicker,
                showRandomizeDialog: $showRandomizeDialog,
                showGeneratorPicker: $showGeneratorPicker,
                showValidationErrors: $showValidationErrors,
                showInfoPopup: $showInfoPopup
            )
        }
        .sheet(isPresented: $showGeneratorPicker) {
            GeneratorPickerView(selectedGenerator: $selectedGenerator)
        }
        .alert("Parameter Validation Errors", isPresented: $showValidationErrors) {
            Button("OK") { }
        } message: {
            Text(parameterManager.validateParameters().joined(separator: "\n"))
        }
        .sheet(isPresented: $showInfoPopup) {
            ParameterInfoPopupView(category: selectedCategory)
        }
    }
}

// MARK: - Parameter Categories

enum ParameterCategory: String, CaseIterable, Identifiable {
    case basic = "Basic"
    case intervals = "Intervals"
    case modulations = "Modulations"
    case directional = "Directional"
    case rhythmic = "Rhythmic"
    case harmonic = "Harmonic"
    case expression = "Expression"
    case accompaniment = "Accompaniment"
    case autoGeneration = "Auto-Generation"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .basic: return "Basic Parameters"
        case .intervals: return "Interval Parameters"
        case .modulations: return "Slonimsky Modulations"
        case .directional: return "Directional Parameters"
        case .rhythmic: return "Rhythmic Parameters"
        case .harmonic: return "Harmonic Parameters"
        case .expression: return "Expression Parameters"
        case .accompaniment: return "Rhythmic Accompaniment"
        case .autoGeneration: return "Auto-generation"
        }
    }
    
    var icon: String {
        switch self {
        case .basic: return "music.note"
        case .intervals: return "arrow.up.and.down"
        case .modulations: return "waveform.path.ecg"
        case .directional: return "arrow.triangle.turn.up.right.circle"
        case .rhythmic: return "clock"
        case .harmonic: return "music.note.list"
        case .expression: return "slider.horizontal.3"
        case .accompaniment: return "drumsticks"
        case .autoGeneration: return "arrow.clockwise"
        }
    }
    
    var description: String {
        switch self {
        case .basic:
            return "Root note, scale type, octaves, tempo"
        case .intervals:
            return "Primary/secondary intervals, patterns, inversions"
        case .modulations:
            return "Interpolation, infrapolation, ultrapolation"
        case .directional:
            return "Direction, mirror points, retrograde, contours"
        case .rhythmic:
            return "Duration patterns, density, syncopation"
        case .harmonic:
            return "Harmonic mode, chord generation, rhythm"
        case .expression:
            return "Velocity, tone shifting, expression"
        case .accompaniment:
            return "Rhythmic accompaniment settings and controls"
        case .autoGeneration:
            return "Auto-generation settings and controls"
        }
    }
}

// MARK: - Parameter Category Detail View

struct ParameterCategoryDetailView: View {
    let category: ParameterCategory
    @ObservedObject var parameterManager: ParameterManager
    @Binding var selectedGenerator: String
    @ObservedObject var midiService: MIDIIntegrationService
    @Binding var isGenerating: Bool
    @Binding var showPresetPicker: Bool
    @Binding var showRandomizeDialog: Bool
    @Binding var showGeneratorPicker: Bool
    @Binding var showValidationErrors: Bool
    @Binding var showInfoPopup: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            categoryHeader
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    switch category {
                    case .basic:
                        BasicParametersDetailView(parameterManager: parameterManager)
                    case .intervals:
                        IntervalParametersDetailView(parameterManager: parameterManager)
                    case .modulations:
                        ModulationParametersDetailView(parameterManager: parameterManager)
                    case .directional:
                        DirectionalParametersDetailView(parameterManager: parameterManager)
                    case .rhythmic:
                        RhythmicParametersDetailView(parameterManager: parameterManager)
                    case .harmonic:
                        HarmonicParametersDetailView(parameterManager: parameterManager)
                    case .expression:
                        ExpressionParametersDetailView(parameterManager: parameterManager)
                    case .accompaniment:
                        RhythmicAccompanimentDetailView(parameterManager: parameterManager)
                    case .autoGeneration:
                        AutoGenerationDetailView(
                            parameterManager: parameterManager,
                            midiService: midiService
                        )
                    }
                }
                .padding()
            }
            
            // Footer
            categoryFooter
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var categoryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.title)
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    showInfoPopup = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Show parameter information")
            }
            
            if category == .basic {
                // Generator Selection for Basic category
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
            }
            
            Divider()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var categoryFooter: some View {
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
}

// MARK: - Parameter Detail Views

struct BasicParametersDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Root Note with cycling
            CyclicalParameterControl(
                title: "Root Note",
                value: $parameterManager.rootNote,
                range: 0...127,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.rootNote.isEnabled ? parameterManager.cyclicalSettings.rootNote : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.rootNote = settings
                        } else {
                            parameterManager.cyclicalSettings.rootNote.isEnabled = false
                        }
                    }
                ),
                defaultValue: 60
            )
            
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
            
            // Number of Octaves with cycling
            CyclicalParameterControl(
                title: "Octaves",
                value: $parameterManager.numberOfOctaves,
                range: 1...8,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.numberOfOctaves.isEnabled ? parameterManager.cyclicalSettings.numberOfOctaves : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.numberOfOctaves = settings
                        } else {
                            parameterManager.cyclicalSettings.numberOfOctaves.isEnabled = false
                        }
                    }
                ),
                defaultValue: 2
            )
            
            // Divisions of Octave with cycling
            CyclicalParameterControl(
                title: "Divisions",
                value: $parameterManager.divisionsOfOctave,
                range: 2...24,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.divisionsOfOctave.isEnabled ? parameterManager.cyclicalSettings.divisionsOfOctave : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.divisionsOfOctave = settings
                        } else {
                            parameterManager.cyclicalSettings.divisionsOfOctave.isEnabled = false
                        }
                    }
                ),
                defaultValue: 12
            )
            
            // Tempo with cycling
            CyclicalParameterControl(
                title: "Tempo (BPM)",
                value: $parameterManager.tempo,
                range: 20...300,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.tempo.isEnabled ? parameterManager.cyclicalSettings.tempo : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.tempo = settings
                        } else {
                            parameterManager.cyclicalSettings.tempo.isEnabled = false
                        }
                    }
                ),
                defaultValue: 120,
                formatter: { "\(Int($0))" }
            )
            
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

struct IntervalParametersDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary Interval with cycling
            CyclicalParameterControl(
                title: "Primary Interval",
                value: $parameterManager.primaryInterval,
                range: 1...12,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.primaryInterval.isEnabled ? parameterManager.cyclicalSettings.primaryInterval : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.primaryInterval = settings
                        } else {
                            parameterManager.cyclicalSettings.primaryInterval.isEnabled = false
                        }
                    }
                ),
                defaultValue: 2
            )
            
            // Secondary Interval with cycling
            CyclicalParameterControl(
                title: "Secondary Interval",
                value: $parameterManager.secondaryInterval,
                range: 1...12,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.secondaryInterval.isEnabled ? parameterManager.cyclicalSettings.secondaryInterval : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.secondaryInterval = settings
                        } else {
                            parameterManager.cyclicalSettings.secondaryInterval.isEnabled = false
                        }
                    }
                ),
                defaultValue: 3
            )
            
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

struct ModulationParametersDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Interpolation
            CyclicalModulationSection(
                title: "Interpolation",
                settings: $parameterManager.interpolation,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.interpolationNotes.isEnabled ? parameterManager.cyclicalSettings.interpolationNotes : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.interpolationNotes = settings
                        } else {
                            parameterManager.cyclicalSettings.interpolationNotes.isEnabled = false
                        }
                    }
                )
            )
            
            // Infrapolation
            CyclicalModulationSection(
                title: "Infrapolation",
                settings: $parameterManager.infrapolation,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.infrapolationNotes.isEnabled ? parameterManager.cyclicalSettings.infrapolationNotes : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.infrapolationNotes = settings
                        } else {
                            parameterManager.cyclicalSettings.infrapolationNotes.isEnabled = false
                        }
                    }
                )
            )
            
            // Ultrapolation
            CyclicalModulationSection(
                title: "Ultrapolation",
                settings: $parameterManager.ultrapolation,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.ultrapolationNotes.isEnabled ? parameterManager.cyclicalSettings.ultrapolationNotes : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.ultrapolationNotes = settings
                        } else {
                            parameterManager.cyclicalSettings.ultrapolationNotes.isEnabled = false
                        }
                    }
                )
            )
        }
    }
}

struct DirectionalParametersDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            // Mirror Points with cycling
            CyclicalParameterControl(
                title: "Mirror Points",
                value: $parameterManager.mirrorPoints,
                range: 0...5,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.mirrorPoints.isEnabled ? parameterManager.cyclicalSettings.mirrorPoints : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.mirrorPoints = settings
                        } else {
                            parameterManager.cyclicalSettings.mirrorPoints.isEnabled = false
                        }
                    }
                ),
                defaultValue: 0
            )
            
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

struct RhythmicParametersDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            // Base Note Duration with cycling
            CyclicalParameterControl(
                title: "Base Duration (seconds)",
                value: $parameterManager.baseNoteDuration,
                range: 0.0625...4.0,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.baseNoteDuration.isEnabled ? parameterManager.cyclicalSettings.baseNoteDuration : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.baseNoteDuration = settings
                        } else {
                            parameterManager.cyclicalSettings.baseNoteDuration.isEnabled = false
                        }
                    }
                ),
                defaultValue: 0.25,
                formatter: { String(format: "%.3f", $0) }
            )
            
            // Rhythmic Density with cycling
            CyclicalParameterControl(
                title: "Rhythmic Density",
                value: $parameterManager.rhythmicDensity,
                range: 0.1...3.0,
                cyclicalSettings: Binding(
                    get: { parameterManager.cyclicalSettings.rhythmicDensity.isEnabled ? parameterManager.cyclicalSettings.rhythmicDensity : nil },
                    set: { newSettings in
                        if let settings = newSettings {
                            parameterManager.cyclicalSettings.rhythmicDensity = settings
                        } else {
                            parameterManager.cyclicalSettings.rhythmicDensity.isEnabled = false
                        }
                    }
                ),
                defaultValue: 1.0,
                formatter: { String(format: "%.2f", $0) }
            )
            
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

struct HarmonicParametersDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
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

struct ExpressionParametersDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Velocity Settings
            VStack(spacing: 8) {
                // Base Velocity with cycling
                CyclicalParameterControl(
                    title: "Base Velocity",
                    value: Binding(
                        get: { Double(parameterManager.velocitySettings.baseVelocity) },
                        set: { parameterManager.velocitySettings.baseVelocity = UInt8($0) }
                    ),
                    range: 1...127,
                    cyclicalSettings: Binding(
                        get: { parameterManager.cyclicalSettings.baseVelocity.isEnabled ? parameterManager.cyclicalSettings.baseVelocity : nil },
                        set: { newSettings in
                            if let settings = newSettings {
                                parameterManager.cyclicalSettings.baseVelocity = settings
                            } else {
                                parameterManager.cyclicalSettings.baseVelocity.isEnabled = false
                            }
                        }
                    ),
                    defaultValue: 80,
                    formatter: { "\(Int($0))" }
                )
                
                // Velocity Range with cycling
                CyclicalParameterControl(
                    title: "Velocity Range",
                    value: Binding(
                        get: { Double(parameterManager.velocitySettings.range) },
                        set: { parameterManager.velocitySettings.range = UInt8($0) }
                    ),
                    range: 0...127,
                    cyclicalSettings: Binding(
                        get: { parameterManager.cyclicalSettings.velocityRange.isEnabled ? parameterManager.cyclicalSettings.velocityRange : nil },
                        set: { newSettings in
                            if let settings = newSettings {
                                parameterManager.cyclicalSettings.velocityRange = settings
                            } else {
                                parameterManager.cyclicalSettings.velocityRange.isEnabled = false
                            }
                        }
                    ),
                    defaultValue: 20,
                    formatter: { "\(Int($0))" }
                )
                
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

struct RhythmicAccompanimentDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Enable/Disable Switch
            HStack {
                Text("Enable Rhythmic Accompaniment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Toggle("", isOn: $parameterManager.rhythmicAccompanimentEnabled)
                    .toggleStyle(SwitchToggleStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            if parameterManager.rhythmicAccompanimentEnabled {
                // Style Selection
                VStack(spacing: 8) {
                    HStack {
                        Text("Style:")
                        Spacer()
                        Picker("Style", selection: $parameterManager.rhythmicAccompanimentStyle) {
                            ForEach(RhythmicAccompanimentStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                // Density Control
                VStack(spacing: 8) {
                    HStack {
                        Text("Density:")
                        Spacer()
                        Text("\(String(format: "%.2f", parameterManager.rhythmicAccompanimentDensity))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $parameterManager.rhythmicAccompanimentDensity, in: 0.1...2.0)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                // Velocity Control
                VStack(spacing: 8) {
                    HStack {
                        Text("Velocity:")
                        Spacer()
                        Text("\(String(format: "%.2f", parameterManager.rhythmicAccompanimentVelocity))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $parameterManager.rhythmicAccompanimentVelocity, in: 0.1...1.0)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
        }
    }
}

struct AutoGenerationDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    @ObservedObject var midiService: MIDIIntegrationService
    
    var body: some View {
        AutoGenerationSettingsView(
            parameterManager: parameterManager,
            midiService: midiService
        )
    }
}

// MARK: - Cyclical Parameter Control

struct CyclicalParameterControl<T: Comparable>: View {
    let title: String
    @Binding var value: T
    let range: ClosedRange<T>
    @Binding var cyclicalSettings: CyclicalParameterSettings?
    let defaultValue: T
    let formatter: (T) -> String
    
    init(
        title: String,
        value: Binding<T>,
        range: ClosedRange<T>,
        cyclicalSettings: Binding<CyclicalParameterSettings?>,
        defaultValue: T,
        formatter: @escaping (T) -> String = { "\($0)" }
    ) where T: BinaryFloatingPoint {
        self.title = title
        self._value = value
        self.range = range
        self._cyclicalSettings = cyclicalSettings
        self.defaultValue = defaultValue
        self.formatter = formatter
    }
    
    init(
        title: String,
        value: Binding<T>,
        range: ClosedRange<T>,
        cyclicalSettings: Binding<CyclicalParameterSettings?>,
        defaultValue: T,
        formatter: @escaping (T) -> String = { "\($0)" }
    ) where T: BinaryInteger {
        self.title = title
        self._value = value
        self.range = range
        self._cyclicalSettings = cyclicalSettings
        self.defaultValue = defaultValue
        self.formatter = formatter
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(title):")
                Spacer()
                Text(formatter(value))
            }
            
            Slider(value: Binding(
                get: { Double(truncating: value as! NSNumber) },
                set: { newValue in
                    if T.self == Int.self {
                        value = Int(newValue) as! T
                    } else {
                        value = newValue as! T
                    }
                }
            ), in: Double(truncating: range.lowerBound as! NSNumber)...Double(truncating: range.upperBound as! NSNumber))
            
            // Cyclical Controls
            HStack {
                Toggle("Cyclical", isOn: Binding(
                    get: { cyclicalSettings?.isEnabled ?? false },
                    set: { isEnabled in
                        if isEnabled {
                            cyclicalSettings = CyclicalParameterSettings(
                                isEnabled: true,
                                minValue: Double(truncating: defaultValue as! NSNumber),
                                maxValue: Double(truncating: defaultValue as! NSNumber),
                                maxCycles: 4
                            )
                        } else {
                            cyclicalSettings = nil
                        }
                    }
                ))
                
                Spacer()
                
                if cyclicalSettings?.isEnabled == true {
                    Button("Configure") {
                        // TODO: Show cyclical configuration sheet
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
    }
}

// MARK: - Cyclical Modulation Section

struct CyclicalModulationSection: View {
    let title: String
    @Binding var settings: ModulationSettings
    @Binding var cyclicalSettings: CyclicalParameterSettings?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle(title, isOn: $settings.enabled)
                Spacer()
                
                if settings.enabled {
                    Toggle("Cyclical", isOn: Binding(
                        get: { cyclicalSettings?.isEnabled ?? false },
                        set: { isEnabled in
                            if isEnabled {
                                cyclicalSettings = CyclicalParameterSettings(
                                    isEnabled: true,
                                    minValue: Double(settings.numberOfNotes),
                                    maxValue: Double(settings.numberOfNotes),
                                    maxCycles: 4
                                )
                            } else {
                                cyclicalSettings = nil
                            }
                        }
                    ))
                }
            }
            
            if settings.enabled {
                HStack {
                    Text("Notes:")
                    Spacer()
                    Stepper("\(settings.numberOfNotes)", value: $settings.numberOfNotes, in: 1...10)
                }
                
                HStack {
                    Text("Interval:")
                    Spacer()
                    Stepper("\(settings.interval)", value: $settings.interval, in: 1...12)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
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
        .frame(width: 600, height: 800)
    }
} 