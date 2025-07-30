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
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Enable/Disable Auto-generation
            HStack {
                Toggle("Enable Auto-generation", isOn: $parameterManager.autoGenerateEnabled)
                    .toggleStyle(SwitchToggleStyle())
                
                Spacer()
                
                if parameterManager.autoGenerateEnabled {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            if parameterManager.autoGenerateEnabled {
                // Generator Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generator")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
                }
                
                // Delay Setting
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Generation Delay")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(parameterManager.autoGenerationDelay, specifier: "%.1f")s")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                
                // Info Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Auto-generation Info")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("When enabled, new sequences will be automatically generated when parameters change. If looping is active, the new sequence will be used on the next iteration.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    AutoGenerationSettingsView(parameterManager: ParameterManager())
        .padding()
} 