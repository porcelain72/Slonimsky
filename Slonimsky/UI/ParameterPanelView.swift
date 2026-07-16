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
                            .foregroundColor(Color.garageBandAccent)
                            .frame(width: 20)
                        Text(category.title)
                            .foregroundColor(Color.garageBandText)
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
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .basic: return "Basic Parameters"
        case .intervals: return "Interval Parameters"
        case .modulations: return "Slonimsky Modulations"
        case .directional: return "Directional Parameters"
        case .rhythmic: return "Rhythm & Meter"
        case .harmonic: return "Harmonic Parameters"
        case .expression: return "Expression Parameters"
        case .accompaniment: return "Rhythmic Accompaniment"
        }
    }
    
    var icon: String {
        switch self {
        case .basic: return "music.note"
        case .intervals: return "arrow.up.and.down"
        case .modulations: return "waveform.path.ecg"
        case .directional: return "arrow.triangle.turn.up.right.circle"
        case .rhythmic: return "metronome"
        case .harmonic: return "music.note.list"
        case .expression: return "slider.horizontal.3"
        case .accompaniment: return "drumsticks"
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
            return "Time signature, groupings, isorhythm, Euclidean rhythms"
        case .harmonic:
            return "Harmonic mode, chord generation, rhythm"
        case .expression:
            return "Velocity, tone shifting, expression"
        case .accompaniment:
            return "Rhythmic accompaniment settings and controls"
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
                        RhythmMeterDetailView(parameterManager: parameterManager)
                    case .harmonic:
                        HarmonicParametersDetailView(parameterManager: parameterManager)
                    case .expression:
                        ExpressionParametersDetailView(parameterManager: parameterManager)
                    case .accompaniment:
                        RhythmicAccompanimentDetailView(parameterManager: parameterManager)
                    }
                }
                .padding()
            }
            
            // Footer
            categoryFooter
        }
        .background(Color.garageBandBackground)
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
                        .foregroundColor(Color.garageBandSecondary)
                }
                .buttonStyle(.plain)
                .help("Show parameter information")
            }
            
            if category == .basic {
                // Generator Selection for Basic category
                HStack {
                    Text("Generator:")
                        .font(.subheadline)
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    
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
        .background(Color.garageBandBackground)
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
        .background(Color.garageBandBackground)
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
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                Picker("Scale Type", selection: $parameterManager.scaleType) {
                    ForEach(ScaleType.allCases, id: \.self) { scaleType in
                        Text(scaleType.rawValue.capitalized).tag(scaleType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
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
            
            // Iterations
            HStack {
                Text("Iterations:")
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Slider(value: Binding(
                    get: { Double(parameterManager.iterations) },
                    set: { parameterManager.iterations = Int($0.rounded()) }
                ), in: 1...10, step: 1)
                .frame(width: 150)
                Text("\(parameterManager.iterations)")
                    .foregroundColor(Color.garageBandSecondary)
                    .frame(width: 20, alignment: .trailing)
            }
            
            // Randomise Order
            HStack {
                Toggle("Randomise Note Order", isOn: $parameterManager.randomiseOrder)
                    .foregroundColor(Color.garageBandText)
                
                Button("Reseed") {
                    parameterManager.reseedRandomOrder()
                }
                .buttonStyle(.bordered)
                .disabled(!parameterManager.randomiseOrder)
            }
            
            // Meter (full editor with groupings lives in Rhythm & Meter)
            HStack {
                Text("Meter:")
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                Picker("Meter", selection: $parameterManager.meter) {
                    ForEach(Meter.presets, id: \.self) { meter in
                        Text(meter.displayName).tag(meter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
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
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                Picker("Interval Pattern", selection: $parameterManager.intervalPattern) {
                    ForEach(IntervalPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue.capitalized).tag(pattern)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
            }
            
            // Interval Inversion
            Toggle("Interval Inversion", isOn: $parameterManager.intervalInversion)
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
            
            // Symmetrical Intervals
            Toggle("Symmetrical Intervals", isOn: $parameterManager.symmetricalIntervals)
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
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
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                Picker("Direction", selection: $parameterManager.primaryDirection) {
                    ForEach(Direction.allCases, id: \.self) { direction in
                        Text(direction.rawValue.capitalized).tag(direction)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
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
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
            
            // Register Shifts
            HStack {
                Text("Register Shifts:")
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                Picker("Register Shifts", selection: $parameterManager.registerShifts) {
                    ForEach(RegisterShiftPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue.capitalized).tag(pattern)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
            }
            
            // Contour Pattern
            HStack {
                Text("Contour:")
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                Picker("Contour Pattern", selection: $parameterManager.contourPattern) {
                    ForEach(ContourPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue.capitalized).tag(pattern)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
            }
        }
    }
}

struct RhythmMeterDetailView: View {
    @ObservedObject var parameterManager: ParameterManager
    
    var body: some View {
        VStack(spacing: 20) {
            meterSection
            Divider()
            rhythmModeSection
            Divider()
            accentSection
        }
    }
    
    // MARK: - Meter
    
    private var groupingsAreValid: Bool {
        parameterManager.meter.groupings.reduce(0, +) == parameterManager.meter.numerator
    }
    
    private var meterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meter")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(Color.garageBandText)
            
            HStack {
                Text("Preset:")
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Picker("Meter Preset", selection: $parameterManager.meter) {
                    ForEach(Meter.presets, id: \.self) { meter in
                        Text(meter.displayName).tag(meter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 180)
            }
            
            HStack(spacing: 16) {
                Stepper(value: Binding(
                    get: { parameterManager.meter.numerator },
                    set: { newValue in
                        var meter = parameterManager.meter
                        meter.numerator = newValue
                        meter.groupings = Meter.defaultGroupings(numerator: newValue, denominator: meter.denominator)
                        parameterManager.meter = meter
                    }
                ), in: 1...16) {
                    Text("Beats: \(parameterManager.meter.numerator)")
                        .foregroundColor(Color.garageBandText)
                }
                
                Picker("Unit", selection: Binding(
                    get: { parameterManager.meter.denominator },
                    set: { newValue in
                        var meter = parameterManager.meter
                        meter.denominator = newValue
                        meter.groupings = Meter.defaultGroupings(numerator: meter.numerator, denominator: newValue)
                        parameterManager.meter = meter
                    }
                )) {
                    Text("2").tag(2)
                    Text("4").tag(4)
                    Text("8").tag(8)
                    Text("16").tag(16)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 160)
            }
            
            // Grouping editor
            VStack(alignment: .leading, spacing: 6) {
                Text("Groupings (accent grid):")
                    .font(.caption)
                    .foregroundColor(Color.garageBandText.opacity(0.8))
                
                HStack(spacing: 8) {
                    ForEach(parameterManager.meter.groupings.indices, id: \.self) { index in
                        Stepper(value: Binding(
                            get: {
                                index < parameterManager.meter.groupings.count
                                    ? parameterManager.meter.groupings[index] : 1
                            },
                            set: { newValue in
                                var meter = parameterManager.meter
                                if index < meter.groupings.count {
                                    meter.groupings[index] = newValue
                                    parameterManager.meter = meter
                                }
                            }
                        ), in: 1...16) {
                            Text("\(parameterManager.meter.groupings[index])")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(Color.garageBandText)
                        }
                        .fixedSize()
                    }
                    
                    Button(action: {
                        var meter = parameterManager.meter
                        meter.groupings.append(1)
                        parameterManager.meter = meter
                    }) {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(parameterManager.meter.groupings.count >= 8)
                    
                    Button(action: {
                        var meter = parameterManager.meter
                        if meter.groupings.count > 1 {
                            meter.groupings.removeLast()
                            parameterManager.meter = meter
                        }
                    }) {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(parameterManager.meter.groupings.count <= 1)
                    
                    Spacer()
                }
                
                if groupingsAreValid {
                    Text("\(parameterManager.meter.displayName) — \(String(format: "%.2f", parameterManager.meter.beatsPerBar)) beats per bar")
                        .font(.caption)
                        .foregroundColor(Color.garageBandText.opacity(0.7))
                } else {
                    Text("Groupings must sum to \(parameterManager.meter.numerator) (currently \(parameterManager.meter.groupings.reduce(0, +)))")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Rhythm mode
    
    private var rhythmModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rhythm Mode")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(Color.garageBandText)
            
            Picker("Rhythm Mode", selection: $parameterManager.rhythmSettings.mode) {
                ForEach(RhythmMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text(parameterManager.rhythmSettings.mode.description)
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.7))
            
            switch parameterManager.rhythmSettings.mode {
            case .uniform:
                uniformSection
            case .isorhythm:
                taleaSection
            case .euclidean:
                euclideanSection
            }
        }
    }
    
    // MARK: - Uniform
    
    private var uniformSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Base Note Duration:")
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Picker("Base Note Duration", selection: Binding(
                    get: { parameterManager.baseNoteDurationEnum },
                    set: { parameterManager.baseNoteDurationEnum = $0 }
                )) {
                    ForEach(BaseNoteDuration.allCases, id: \.self) { duration in
                        Text(duration.shortName).tag(duration)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 180)
            }
            
            Text("\(String(format: "%.3f", parameterManager.baseNoteDuration)) beats")
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.7))
            
            Toggle("Cyclical", isOn: Binding(
                get: { parameterManager.cyclicalSettings.baseNoteDuration.isEnabled },
                set: { parameterManager.cyclicalSettings.baseNoteDuration.isEnabled = $0 }
            ))
            .toggleStyle(CheckboxToggleStyle())
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.garageBandText)
            
            if parameterManager.cyclicalSettings.baseNoteDuration.isEnabled {
                baseDurationCyclicalDetail
            }
        }
    }
    
    private var baseDurationCyclicalDetail: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().padding(.vertical, 4)
            Text("Cyclical Settings").font(.subheadline).fontWeight(.medium).foregroundColor(Color.garageBandText)
            HStack {
                Text("Cycle Type:").foregroundColor(Color.garageBandText)
                Spacer()
                Picker("Cycle Type", selection: Binding(
                    get: { parameterManager.cyclicalSettings.baseNoteDuration.cycleType },
                    set: { parameterManager.cyclicalSettings.baseNoteDuration.cycleType = $0 }
                )) {
                    ForEach(CycleType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            HStack {
                Text("Min Value:").foregroundColor(Color.garageBandText)
                Spacer()
                TextField("Min", value: Binding(
                    get: { parameterManager.cyclicalSettings.baseNoteDuration.minValue },
                    set: { parameterManager.cyclicalSettings.baseNoteDuration.minValue = $0 }
                ), formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
            }
            HStack {
                Text("Max Value:").foregroundColor(Color.garageBandText)
                Spacer()
                TextField("Max", value: Binding(
                    get: { parameterManager.cyclicalSettings.baseNoteDuration.maxValue },
                    set: { parameterManager.cyclicalSettings.baseNoteDuration.maxValue = $0 }
                ), formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
            }
            HStack {
                Text("Step Size:").foregroundColor(Color.garageBandText)
                Spacer()
                TextField("Step", value: Binding(
                    get: { parameterManager.cyclicalSettings.baseNoteDuration.stepSize },
                    set: { parameterManager.cyclicalSettings.baseNoteDuration.stepSize = $0 }
                ), formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
            }
            HStack {
                Text("Operation:").foregroundColor(Color.garageBandText)
                Spacer()
                Picker("Operation", selection: Binding(
                    get: { parameterManager.cyclicalSettings.baseNoteDuration.operationType },
                    set: { parameterManager.cyclicalSettings.baseNoteDuration.operationType = $0 }
                )) {
                    ForEach(CyclicalOperationType.allCases, id: \.self) { op in
                        Text(op.rawValue).tag(op)
                    }
                }
            }
        }
    }
    
    // MARK: - Talea (isorhythm)
    
    private var taleaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Talea (duration cycle):")
                .foregroundColor(Color.garageBandText)
            
            ForEach(parameterManager.rhythmSettings.talea.indices, id: \.self) { index in
                HStack {
                    Picker("Duration", selection: Binding(
                        get: {
                            index < parameterManager.rhythmSettings.talea.count
                                ? parameterManager.rhythmSettings.talea[index].value : .quarter
                        },
                        set: { newValue in
                            if index < parameterManager.rhythmSettings.talea.count {
                                parameterManager.rhythmSettings.talea[index].value = newValue
                            }
                        }
                    )) {
                        ForEach(DurationValue.allCases, id: \.self) { value in
                            Text(value.displayName).tag(value)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 160)
                    
                    Toggle("Rest", isOn: Binding(
                        get: {
                            index < parameterManager.rhythmSettings.talea.count
                                ? parameterManager.rhythmSettings.talea[index].isRest : false
                        },
                        set: { newValue in
                            if index < parameterManager.rhythmSettings.talea.count {
                                parameterManager.rhythmSettings.talea[index].isRest = newValue
                            }
                        }
                    ))
                    .toggleStyle(CheckboxToggleStyle())
                    .font(.system(size: 12))
                    .foregroundColor(Color.garageBandText)
                    
                    Spacer()
                    
                    Button(action: {
                        if index < parameterManager.rhythmSettings.talea.count,
                           parameterManager.rhythmSettings.talea.count > 1 {
                            parameterManager.rhythmSettings.talea.remove(at: index)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(parameterManager.rhythmSettings.talea.count <= 1)
                }
            }
            
            Button(action: {
                parameterManager.rhythmSettings.talea.append(TaleaEntry(value: .quarter))
            }) {
                Label("Add Entry", systemImage: "plus.circle")
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(Color.garageBandAccent)
            .disabled(parameterManager.rhythmSettings.talea.count >= 16)
            
            taleaFooter
        }
    }
    
    private var taleaFooter: some View {
        let settings = parameterManager.rhythmSettings
        let noteCount = settings.taleaNoteCount
        let beats = settings.taleaBeats
        let barText = parameterManager.meter.beatsPerBar > 0
            ? String(format: "%.2f bars of %@", beats / parameterManager.meter.beatsPerBar, parameterManager.meter.displayName)
            : ""
        let text: String
        if noteCount == 0 {
            text = "Talea has no sounding entries — uniform durations will be used"
        } else {
            text = "Talea: \(settings.talea.count) entries (\(noteCount) notes), \(String(format: "%.2f", beats)) beats ≈ \(barText)"
        }
        return Text(text)
            .font(.caption)
            .foregroundColor(noteCount == 0 ? .orange : Color.garageBandText.opacity(0.7))
    }
    
    // MARK: - Euclidean
    
    private var euclideanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Stepper(value: Binding(
                get: { parameterManager.rhythmSettings.euclideanSteps },
                set: { newValue in
                    parameterManager.rhythmSettings.euclideanSteps = newValue
                    if parameterManager.rhythmSettings.euclideanHits > newValue {
                        parameterManager.rhythmSettings.euclideanHits = newValue
                    }
                    if parameterManager.rhythmSettings.euclideanRotation >= newValue {
                        parameterManager.rhythmSettings.euclideanRotation = 0
                    }
                }
            ), in: 1...32) {
                Text("Steps: \(parameterManager.rhythmSettings.euclideanSteps)")
                    .foregroundColor(Color.garageBandText)
            }
            
            Stepper(value: $parameterManager.rhythmSettings.euclideanHits,
                    in: 1...parameterManager.rhythmSettings.euclideanSteps) {
                Text("Hits: \(parameterManager.rhythmSettings.euclideanHits)")
                    .foregroundColor(Color.garageBandText)
            }
            
            Stepper(value: $parameterManager.rhythmSettings.euclideanRotation,
                    in: 0...max(0, parameterManager.rhythmSettings.euclideanSteps - 1)) {
                Text("Rotation: \(parameterManager.rhythmSettings.euclideanRotation)")
                    .foregroundColor(Color.garageBandText)
            }
            
            HStack {
                Text("Step Duration:")
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Picker("Step Duration", selection: $parameterManager.rhythmSettings.euclideanStepDuration) {
                    ForEach(DurationValue.allCases, id: \.self) { value in
                        Text(value.displayName).tag(value)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 160)
            }
            
            // Dot-strip preview of the pattern
            euclideanPreview
            
            // Cycle the rotation one step per generated cycle
            Toggle("Cyclical Rotation (rotate grid each cycle)", isOn: Binding(
                get: { parameterManager.cyclicalSettings.euclideanRotation.isEnabled },
                set: { enabled in
                    parameterManager.cyclicalSettings.euclideanRotation.isEnabled = enabled
                    if enabled {
                        // One full turn of the current grid, one step at a time
                        parameterManager.cyclicalSettings.euclideanRotation.minValue = 0
                        parameterManager.cyclicalSettings.euclideanRotation.maxValue =
                            Double(max(1, parameterManager.rhythmSettings.euclideanSteps - 1))
                        parameterManager.cyclicalSettings.euclideanRotation.stepSize = 1
                    }
                }
            ))
            .toggleStyle(CheckboxToggleStyle())
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.garageBandText)
        }
    }
    
    private var euclideanPreview: some View {
        let pattern = EuclideanRhythm.pattern(
            hits: parameterManager.rhythmSettings.euclideanHits,
            steps: parameterManager.rhythmSettings.euclideanSteps,
            rotation: parameterManager.rhythmSettings.euclideanRotation
        )
        return HStack(spacing: 4) {
            ForEach(pattern.indices, id: \.self) { index in
                Circle()
                    .fill(pattern[index] ? Color.garageBandAccent : Color.garageBandPanel)
                    .overlay(Circle().stroke(Color.garageBandText.opacity(0.3), lineWidth: 1))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Accents
    
    private var accentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accents")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(Color.garageBandText)
            
            HStack {
                Text("Grouping Accent Boost:")
                    .foregroundColor(Color.garageBandText)
                Spacer()
                Text("+\(parameterManager.rhythmSettings.accentBoost)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color.garageBandText)
            }
            Slider(value: Binding(
                get: { Double(parameterManager.rhythmSettings.accentBoost) },
                set: { parameterManager.rhythmSettings.accentBoost = Int($0) }
            ), in: 0...32, step: 1)
            
            Text("Velocity added to notes that fall on a grouping start (e.g. 1, 3, 5 in 7/8 grouped 2+2+3)")
                .font(.caption)
                .foregroundColor(Color.garageBandText.opacity(0.7))
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
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                Picker("Harmonic Mode", selection: $parameterManager.harmonicMode) {
                    ForEach(HarmonicMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
            }
            
            // Chord Generation
            Toggle("Chord Generation", isOn: $parameterManager.chordGeneration.enabled)
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
            
            if parameterManager.chordGeneration.enabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Chord Size:")
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                        Spacer()
                        Stepper("\(parameterManager.chordGeneration.chordSize)", value: $parameterManager.chordGeneration.chordSize, in: 2...6)
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("Voicing:")
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                        Spacer()
                        Picker("Voicing Preference", selection: $parameterManager.chordGeneration.voicingPreference) {
                            ForEach(VoicingPreference.allCases, id: \.self) { preference in
                                Text(preference.rawValue.capitalized).tag(preference)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("Velocity Scale:")
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                        Spacer()
                        Text("\(String(format: "%.2f", parameterManager.chordGeneration.velocityScale))")
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    }
                    Slider(value: $parameterManager.chordGeneration.velocityScale, in: 0.1...1.0)
                }
                .padding()
                .background(Color.garageBandPanel)
                .cornerRadius(6)
            }
            
            // Harmonic Rhythm
            VStack(spacing: 8) {
                HStack {
                    Text("Chord Change Frequency:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Stepper("\(parameterManager.harmonicRhythm.chordChangeFrequency)", value: $parameterManager.harmonicRhythm.chordChangeFrequency, in: 1...16)
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Syncopation:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.harmonicRhythm.syncopationLevel))")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                Slider(value: $parameterManager.harmonicRhythm.syncopationLevel, in: 0...1.0)
                
                HStack {
                    Text("Harmonic Tension:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.harmonicRhythm.harmonicTension))")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                Slider(value: $parameterManager.harmonicRhythm.harmonicTension, in: 0...1.0)
            }
            .padding()
            .background(Color.garageBandPanel)
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
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.velocitySettings.waveDepth))")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                Slider(value: $parameterManager.velocitySettings.waveDepth, in: 0...1.0)
                
                HStack {
                    Text("Randomness:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.velocitySettings.randomness))")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                Slider(value: $parameterManager.velocitySettings.randomness, in: 0...1.0)
                
                HStack {
                    Text("Phase:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.velocitySettings.phase))")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                Slider(value: $parameterManager.velocitySettings.phase, in: 0...2 * .pi)
                
                HStack {
                    Text("Emphasis Beat:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Stepper("\(parameterManager.velocitySettings.emphasisBeat)", value: $parameterManager.velocitySettings.emphasisBeat, in: 1...16)
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Emphasis Amount:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Text("\(String(format: "%.2f", parameterManager.velocitySettings.emphasisAmount))")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                Slider(value: $parameterManager.velocitySettings.emphasisAmount, in: 0...1.0)
            }
            .padding()
            .background(Color.garageBandPanel)
            .cornerRadius(6)
            
            // Tone Shifting
            VStack(spacing: 8) {
                HStack {
                    Text("Tone Increment:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Stepper("\(parameterManager.toneShifting.toneIncrement)", value: $parameterManager.toneShifting.toneIncrement, in: 0...24)
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Max Tone Shift:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Stepper("\(parameterManager.toneShifting.maxToneShift)", value: $parameterManager.toneShifting.maxToneShift, in: 0...96)
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Shift Pattern:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Picker("Shift Pattern", selection: $parameterManager.toneShifting.shiftPattern) {
                        ForEach(RegisterShiftPattern.allCases, id: \.self) { pattern in
                            Text(pattern.rawValue.capitalized).tag(pattern)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                }
            }
            .padding()
            .background(Color.garageBandPanel)
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
            .background(Color.garageBandPanel)
            .cornerRadius(6)
            
            if parameterManager.rhythmicAccompanimentEnabled {
                // Style Selection
                VStack(spacing: 8) {
                    HStack {
                        Text("Style:")
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                        Spacer()
                        Picker("Style", selection: $parameterManager.rhythmicAccompanimentStyle) {
                            ForEach(RhythmicAccompanimentStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    }
                }
                .padding()
                .background(Color.garageBandPanel)
                .cornerRadius(6)
                
                // Density Control
                VStack(spacing: 8) {
                    HStack {
                        Text("Density:")
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                        Spacer()
                        Text("\(String(format: "%.2f", parameterManager.rhythmicAccompanimentDensity))")
                            .font(.caption)
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    }
                    Slider(value: $parameterManager.rhythmicAccompanimentDensity, in: 0.1...2.0)
                }
                .padding()
                .background(Color.garageBandPanel)
                .cornerRadius(6)
                
                // Velocity Control
                VStack(spacing: 8) {
                    HStack {
                        Text("Velocity:")
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                        Spacer()
                        Text("\(String(format: "%.2f", parameterManager.rhythmicAccompanimentVelocity))")
                            .font(.caption)
                            .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    }
                    Slider(value: $parameterManager.rhythmicAccompanimentVelocity, in: 0.1...1.0)
                }
                .padding()
                .background(Color.garageBandPanel)
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
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                Text(formatter(value))
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
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
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Cyclical", isOn: Binding(
                    get: { cyclicalSettings?.isEnabled ?? false },
                    set: { isEnabled in
                        if isEnabled {
                            cyclicalSettings = CyclicalParameterSettings(
                                isEnabled: true,
                                minValue: Double(truncating: defaultValue as! NSNumber),
                                maxValue: Double(truncating: defaultValue as! NSNumber)
                            )
                        } else {
                            cyclicalSettings = nil
                        }
                    }
                ))
                .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                
                // Show cyclical configuration when enabled
                if cyclicalSettings?.isEnabled == true {
                    VStack(alignment: .leading, spacing: 8) {
                        // Min/Max Values
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Min Value")
                                    .font(.caption)
                                    .foregroundColor(Color.garageBandText)
                                TextField("0", text: Binding(
                                    get: { 
                                        let value = cyclicalSettings?.minValue ?? Double(truncating: defaultValue as! NSNumber)
                                        return String(format: "%.0f", value)
                                    },
                                    set: { newValue in
                                        if let doubleValue = Double(newValue) {
                                            cyclicalSettings?.minValue = doubleValue
                                        }
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Max Value")
                    .font(.caption)
                                    .foregroundColor(Color.garageBandText)
                                TextField("10", text: Binding(
                                    get: { 
                                        let value = cyclicalSettings?.maxValue ?? Double(truncating: defaultValue as! NSNumber)
                                        return String(format: "%.0f", value)
                                    },
                                    set: { newValue in
                                        if let doubleValue = Double(newValue) {
                                            cyclicalSettings?.maxValue = doubleValue
                                        }
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        // Step Size
                        VStack(alignment: .leading) {
                            Text("Step Size")
                                .font(.caption)
                                .foregroundColor(Color.garageBandText)
                            TextField("1", text: Binding(
                                get: { 
                                    let value = cyclicalSettings?.stepSize ?? 1.0
                                    return String(format: "%.0f", value)
                                },
                                set: { newValue in
                                    if let doubleValue = Double(newValue) {
                                        cyclicalSettings?.stepSize = doubleValue
                                    }
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        
                        
                        // Operation Type
                        VStack(alignment: .leading) {
                            Text("Operation Type")
                                .font(.caption)
                                .foregroundColor(Color.garageBandText)
                            Picker("Operation", selection: Binding(
                                get: { cyclicalSettings?.operationType ?? .replace },
                                set: { newValue in
                                    cyclicalSettings?.operationType = newValue
                                }
                            )) {
                                ForEach(CyclicalOperationType.allCases, id: \.self) { operation in
                                    Text(operation.rawValue).tag(operation)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(Color.garageBandText)
                        }
                        
                        // Reset After Max
                        Toggle("Reset After Max", isOn: Binding(
                            get: { cyclicalSettings?.resetAfterMax ?? false },
                            set: { newValue in
                                cyclicalSettings?.resetAfterMax = newValue
                            }
                        ))
                        .foregroundColor(Color.garageBandText)
                        
                        // Current Cycle Display
                        HStack {
                            Text("Current Cycle: \(cyclicalSettings?.currentCycle ?? 0)")
                                .font(.caption)
                                .foregroundColor(Color.garageBandText)
                            Spacer()
                            Button("Reset") {
                                cyclicalSettings?.currentCycle = 0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding()
                    .background(Color.garageBandPanel.opacity(0.5))
                    .cornerRadius(8)
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
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                Spacer()
                
                if settings.enabled {
                    Toggle("Cyclical", isOn: Binding(
                        get: { cyclicalSettings?.isEnabled ?? false },
                        set: { isEnabled in
                            if isEnabled {
                                cyclicalSettings = CyclicalParameterSettings(
                                    isEnabled: true,
                                    minValue: Double(settings.numberOfNotes),
                                    maxValue: Double(settings.numberOfNotes)
                                )
                            } else {
                                cyclicalSettings = nil
                            }
                        }
                    ))
                    .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                }
            }
            
            if settings.enabled {
                HStack {
                    Text("Notes:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Stepper("\(settings.numberOfNotes)", value: $settings.numberOfNotes, in: 1...10)
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Interval:")
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                    Spacer()
                    Stepper("\(settings.interval)", value: $settings.interval, in: 1...12)
                        .foregroundColor(Color.garageBandText)
                .background(Color.garageBandPanel)
                .cornerRadius(4)
                        .background(Color.garageBandPanel)
                        .cornerRadius(4)
                }
                
                // Cyclical parameter configuration
                if cyclicalSettings?.isEnabled == true {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cyclical Settings")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.garageBandText)
                        
                        // Cycle Type
                        HStack {
                            Text("Cycle Type:")
                                .foregroundColor(Color.garageBandText)
                            Spacer()
                            Picker("Cycle Type", selection: Binding(
                                get: { cyclicalSettings?.cycleType ?? .increment },
                                set: { newValue in
                                    if var current = cyclicalSettings {
                                        current.cycleType = newValue
                                        cyclicalSettings = current
                                    }
                                }
                            )) {
                                ForEach(CycleType.allCases, id: \.self) { cycleType in
                                    Text(cycleType.rawValue).tag(cycleType)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(Color.garageBandText)
                        }
                        
                        // Min Value
                        HStack {
                            Text("Min Value:")
                                .foregroundColor(Color.garageBandText)
                            Spacer()
                            TextField("Min", value: Binding(
                                get: { cyclicalSettings?.minValue ?? 0.0 },
                                set: { newValue in
                                    if var current = cyclicalSettings {
                                        current.minValue = newValue
                                        cyclicalSettings = current
                                    }
                                }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                        
                        // Max Value
                        HStack {
                            Text("Max Value:")
                                .foregroundColor(Color.garageBandText)
                            Spacer()
                            TextField("Max", value: Binding(
                                get: { cyclicalSettings?.maxValue ?? 10.0 },
                                set: { newValue in
                                    if var current = cyclicalSettings {
                                        current.maxValue = newValue
                                        cyclicalSettings = current
                                    }
                                }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                        
                        // Step Size
                        HStack {
                            Text("Step Size:")
                                .foregroundColor(Color.garageBandText)
                            Spacer()
                            TextField("Step", value: Binding(
                                get: { cyclicalSettings?.stepSize ?? 1.0 },
                                set: { newValue in
                                    if var current = cyclicalSettings {
                                        current.stepSize = newValue
                                        cyclicalSettings = current
                                    }
                                }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                        
                        // Operation Type
                        HStack {
                            Text("Operation:")
                                .foregroundColor(Color.garageBandText)
                            Spacer()
                            Picker("Operation", selection: Binding(
                                get: { cyclicalSettings?.operationType ?? .replace },
                                set: { newValue in
                                    if var current = cyclicalSettings {
                                        current.operationType = newValue
                                        cyclicalSettings = current
                                    }
                                }
                            )) {
                                ForEach(CyclicalOperationType.allCases, id: \.self) { operation in
                                    Text(operation.rawValue).tag(operation)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(Color.garageBandText)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.garageBandPanel)
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