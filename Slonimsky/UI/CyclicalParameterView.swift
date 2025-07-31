import SwiftUI

/// View for managing cyclical parameter settings
struct CyclicalParameterView: View {
    @ObservedObject var parameterManager: ParameterManager
    @State private var selectedParameterType: CyclicalParameterType = .interpolationNotes
    @State private var showingParameterDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundColor(.blue)
                Text("Cyclical Parameters")
                    .font(.headline)
                Spacer()
                Button("Reset All") {
                    parameterManager.cyclicalSettings.resetAllCycles()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Parameter Type Selector
            Picker("Parameter Type", selection: $selectedParameterType) {
                ForEach(CyclicalParameterType.allCases, id: \.self) { parameterType in
                    Text(parameterType.rawValue).tag(parameterType)
                }
            }
            .pickerStyle(.menu)
            
            // Current Parameter Settings
            if let settings = getCurrentParameterSettings() {
                CyclicalParameterDetailView(
                    parameterType: selectedParameterType,
                    settings: settings,
                    onSettingsChanged: { newSettings in
                        updateParameterSettings(for: selectedParameterType, with: newSettings)
                    }
                )
            }
            
            // Enabled Parameters Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Enabled Parameters")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                let enabledParams = parameterManager.cyclicalSettings.enabledParameters
                if enabledParams.isEmpty {
                    Text("No cyclical parameters enabled")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(enabledParams.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { paramType in
                        HStack {
                            Text(paramType.rawValue)
                            Spacer()
                            Text("Cycle \(enabledParams[paramType]?.currentCycle ?? 0)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentParameterSettings() -> CyclicalParameterSettings? {
        switch selectedParameterType {
        case .interpolationNotes:
            return parameterManager.cyclicalSettings.interpolationNotes
        case .infrapolationNotes:
            return parameterManager.cyclicalSettings.infrapolationNotes
        case .ultrapolationNotes:
            return parameterManager.cyclicalSettings.ultrapolationNotes
        case .modulationInterval:
            return parameterManager.cyclicalSettings.modulationInterval
        case .baseNoteDuration:
            return parameterManager.cyclicalSettings.baseNoteDuration
        case .rhythmicDensity:
            return parameterManager.cyclicalSettings.rhythmicDensity
        case .primaryInterval:
            return parameterManager.cyclicalSettings.primaryInterval
        case .secondaryInterval:
            return parameterManager.cyclicalSettings.secondaryInterval
        case .baseVelocity:
            return parameterManager.cyclicalSettings.baseVelocity
        case .velocityRange:
            return parameterManager.cyclicalSettings.velocityRange
        case .tempo:
            return parameterManager.cyclicalSettings.tempo
        case .rootNote:
            return parameterManager.cyclicalSettings.rootNote
        case .numberOfOctaves:
            return parameterManager.cyclicalSettings.numberOfOctaves
        case .divisionsOfOctave:
            return parameterManager.cyclicalSettings.divisionsOfOctave
        case .mirrorPoints:
            return parameterManager.cyclicalSettings.mirrorPoints
        }
    }
    
    private func updateParameterSettings(for parameterType: CyclicalParameterType, with newSettings: CyclicalParameterSettings) {
        switch parameterType {
        case .interpolationNotes:
            parameterManager.cyclicalSettings.interpolationNotes = newSettings
        case .infrapolationNotes:
            parameterManager.cyclicalSettings.infrapolationNotes = newSettings
        case .ultrapolationNotes:
            parameterManager.cyclicalSettings.ultrapolationNotes = newSettings
        case .modulationInterval:
            parameterManager.cyclicalSettings.modulationInterval = newSettings
        case .baseNoteDuration:
            parameterManager.cyclicalSettings.baseNoteDuration = newSettings
        case .rhythmicDensity:
            parameterManager.cyclicalSettings.rhythmicDensity = newSettings
        case .primaryInterval:
            parameterManager.cyclicalSettings.primaryInterval = newSettings
        case .secondaryInterval:
            parameterManager.cyclicalSettings.secondaryInterval = newSettings
        case .baseVelocity:
            parameterManager.cyclicalSettings.baseVelocity = newSettings
        case .velocityRange:
            parameterManager.cyclicalSettings.velocityRange = newSettings
        case .tempo:
            parameterManager.cyclicalSettings.tempo = newSettings
        case .rootNote:
            parameterManager.cyclicalSettings.rootNote = newSettings
        case .numberOfOctaves:
            parameterManager.cyclicalSettings.numberOfOctaves = newSettings
        case .divisionsOfOctave:
            parameterManager.cyclicalSettings.divisionsOfOctave = newSettings
        case .mirrorPoints:
            parameterManager.cyclicalSettings.mirrorPoints = newSettings
        }
    }
}

/// Detail view for editing a specific cyclical parameter
struct CyclicalParameterDetailView: View {
    let parameterType: CyclicalParameterType
    @State var settings: CyclicalParameterSettings
    let onSettingsChanged: (CyclicalParameterSettings) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enable/Disable Toggle
            Toggle("Enable Cyclical Changes", isOn: Binding(
                get: { settings.isEnabled },
                set: { newValue in
                    settings.isEnabled = newValue
                    onSettingsChanged(settings)
                }
            ))
            
            if settings.isEnabled {
                // Min/Max Values
                HStack {
                    VStack(alignment: .leading) {
                        Text("Min Value")
                            .font(.caption)
                        TextField("Min", value: Binding(
                            get: { settings.minValue },
                            set: { newValue in
                                settings.minValue = newValue
                                onSettingsChanged(settings)
                            }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Value")
                            .font(.caption)
                        TextField("Max", value: Binding(
                            get: { settings.maxValue },
                            set: { newValue in
                                settings.maxValue = newValue
                                onSettingsChanged(settings)
                            }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Step Size
                VStack(alignment: .leading) {
                    Text("Step Size")
                        .font(.caption)
                    TextField("Step", value: Binding(
                        get: { settings.stepSize },
                        set: { newValue in
                            settings.stepSize = newValue
                            onSettingsChanged(settings)
                        }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                }
                
                // Max Cycles
                VStack(alignment: .leading) {
                    Text("Max Cycles")
                        .font(.caption)
                    TextField("Cycles", value: Binding(
                        get: { settings.maxCycles },
                        set: { newValue in
                            settings.maxCycles = newValue
                            onSettingsChanged(settings)
                        }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                }
                
                // Operation Type
                VStack(alignment: .leading) {
                    Text("Operation Type")
                        .font(.caption)
                    Picker("Operation", selection: Binding(
                        get: { settings.operationType },
                        set: { newValue in
                            settings.operationType = newValue
                            onSettingsChanged(settings)
                        }
                    )) {
                        ForEach(CyclicalOperationType.allCases, id: \.self) { operation in
                            Text(operation.rawValue).tag(operation)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Reset After Max
                Toggle("Reset After Max", isOn: Binding(
                    get: { settings.resetAfterMax },
                    set: { newValue in
                        settings.resetAfterMax = newValue
                        onSettingsChanged(settings)
                    }
                ))
                
                // Current Cycle Display
                HStack {
                    Text("Current Cycle: \(settings.currentCycle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Reset") {
                        settings.currentCycle = 0
                        onSettingsChanged(settings)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    CyclicalParameterView(parameterManager: ParameterManager())
        .frame(width: 400)
        .padding()
} 