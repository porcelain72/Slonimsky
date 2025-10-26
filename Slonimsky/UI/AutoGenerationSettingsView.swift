//
//  AutoGenerationSettingsView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// View for auto-generation settings
struct AutoGenerationSettingsView: View {
    
    // MARK: - Properties
    @ObservedObject var parameterManager: ParameterManager
    @ObservedObject var midiService: MIDIIntegrationService
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Enable/Disable Auto-generation
            HStack {
                Toggle("Enable Auto-generation", isOn: $parameterManager.autoGenerateEnabled)
                    .toggleStyle(SwitchToggleStyle())
                    .foregroundColor(Color.garageBandText)
                
                Spacer()
                
                if parameterManager.autoGenerateEnabled {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color.garageBandAccent)
                        .font(.title2)
                }
            }
            
            if parameterManager.autoGenerateEnabled {
                // Automatic Generator Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Automatic Generator Selection", isOn: $parameterManager.automaticGeneratorSelectionEnabled)
                            .toggleStyle(SwitchToggleStyle())
                            .foregroundColor(Color.garageBandText)
                        
                        Spacer()
                        
                        if parameterManager.automaticGeneratorSelectionEnabled {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(Color.garageBandAccent)
                                .font(.title2)
                        }
                    }
                    
                    if parameterManager.automaticGeneratorSelectionEnabled {
                        // Show active generators
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Generators:")
                                .font(.subheadline)
                                .foregroundColor(Color.garageBandText)
                            
                            ForEach(parameterManager.activeGenerators, id: \.self) { generator in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.garageBandAccent)
                                        .font(.caption)
                                    Text(generator)
                                        .font(.caption)
                                        .foregroundColor(Color.garageBandText)
                                }
                            }
                            
                            if parameterManager.activeGenerators.count > 1 {
                                HStack {
                                    Image(systemName: "arrow.triangle.merge")
                                        .foregroundColor(Color.garageBandAccent)
                                        .font(.caption)
                                    Text("Combination Mode: \(parameterManager.combinationMode.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(Color.garageBandSecondary)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    } else {
                        // Manual Generator Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Generator")
                                .font(.headline)
                                .foregroundColor(Color.garageBandText)
                            
                            Picker("Generator", selection: $parameterManager.selectedGeneratorForAutoGeneration) {
                                Text("Scale Pattern Generator").tag("Scale Pattern Generator")
                                Text("Interval Pattern Generator").tag("Interval Pattern Generator")
                                Text("Harmonic Pattern Generator").tag("Harmonic Pattern Generator")
                                Text("Symmetrical Pattern Generator").tag("Symmetrical Pattern Generator")
                                Text("Contour Pattern Generator").tag("Contour Pattern Generator")
                                Text("Rhythmic Pattern Generator").tag("Rhythmic Pattern Generator")
                                Text("Modulation Pattern Generator").tag("Modulation Pattern Generator")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(Color.garageBandText)
                        }
                    }
                }
                
                // Delay Setting
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Generation Delay")
                            .font(.headline)
                            .foregroundColor(Color.garageBandText)
                        
                        Spacer()
                        
                        Text("\(parameterManager.autoGenerationDelay, specifier: "%.1f")s")
                            .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                    }
                    
                    Slider(
                        value: $parameterManager.autoGenerationDelay,
                        in: 0.5...5.0,
                        step: 0.1
                    ) {
                        Text("Generation Delay")
                    } minimumValueLabel: {
                        Text("0.5s")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("5.0s")
                            .font(.caption2)
                    }
                }
                
                // Reset Button
                if midiService.errorMessage != nil || midiService.isGenerating {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color.garageBandAccent)
                            Text("Auto-generation Issue Detected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.garageBandAccent)
                        }
                        
                        if let errorMessage = midiService.errorMessage {
                            Text("Error: \(errorMessage)")
                                .font(.caption)
                                .foregroundColor(Color.garageBandAccent)
                        }
                        
                        Button(action: {
                            midiService.resetAutoGeneration()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset Auto-generation")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.garageBandAccent)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 8)
                }
                
                // Info Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color.garageBandAccent)
                        Text("Auto-generation Info")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.garageBandText)
                    }
                    
                    if parameterManager.automaticGeneratorSelectionEnabled {
                        Text("Automatic generator selection analyzes your active parameters and selects the most appropriate generators. Multiple generators can be combined automatically for complex patterns.")
                            .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("When enabled, new sequences will be automatically generated when parameters change. If looping is active, the new sequence will be used on the next iteration.")
                            .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.garageBandPanel)
        .cornerRadius(8)
    }
}

#Preview {
    AutoGenerationSettingsView(
        parameterManager: ParameterManager(),
        midiService: MIDIIntegrationService()
    )
    .padding()
} 