import SwiftUI

/// View for controlling and monitoring cycle progression
struct CycleControlView: View {
    @ObservedObject var parameterManager: ParameterManager
    @State private var isAutoAdvancing = false
    @State private var autoAdvanceInterval: TimeInterval = 2.0
    @State private var autoAdvanceTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "timer.circle.fill")
                    .foregroundColor(Color.garageBandAccent)
                Text("Cycle Control")
                    .font(.headline)
                    .foregroundColor(Color.garageBandText)
                Spacer()
                
                // Auto-advance toggle
                Toggle("Auto-advance", isOn: $isAutoAdvancing)
                    .foregroundColor(Color.garageBandText)
                    .onChange(of: isAutoAdvancing) { newValue in
                        if newValue {
                            startAutoAdvance()
                        } else {
                            stopAutoAdvance()
                        }
                    }
            }
            
            // Current Cycle Display
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Cycle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.garageBandText)
                    Spacer()
                    Text("\(parameterManager.cyclicalSettings.currentCycle)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.garageBandAccent)
                }
                
                // Progress Bar
                ProgressView(value: cycleProgress)
                    .progressViewStyle(.linear)
                
                HStack {
                    Text("Progress: \(Int(cycleProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(Color.garageBandSecondary)
                    Spacer()
                    Text("Max: \(maxCycles)")
                        .font(.caption)
                        .foregroundColor(Color.garageBandSecondary)
                }
            }
            
            // Manual Controls
            HStack(spacing: 12) {
                Button("Previous") {
                    previousCycle()
                }
                .buttonStyle(.bordered)
                .disabled(parameterManager.cyclicalSettings.currentCycle <= 0)
                
                Button("Reset") {
                    resetCycles()
                }
                .buttonStyle(.bordered)
                
                Button("Next") {
                    nextCycle()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            
            // Auto-advance Settings
            if isAutoAdvancing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Auto-advance Interval")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.garageBandText)
                    
                    HStack {
                        Slider(value: $autoAdvanceInterval, in: 0.5...10.0, step: 0.5)
                        Text("\(String(format: "%.1f", autoAdvanceInterval))s")
                            .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                    }
                }
            }
            
            // Active Parameters Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Cyclical Parameters")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.garageBandText)
                
                let activeParams = parameterManager.cyclicalSettings.enabledParameters
                if activeParams.isEmpty {
                    Text("No cyclical parameters active")
                        .foregroundColor(Color.garageBandSecondary)
                        .italic()
                } else {
                    ForEach(activeParams.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { paramType in
                        if let settings = activeParams[paramType] {
                            HStack {
                                Text(paramType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(Color.garageBandText)
                                Spacer()
                                Text("\(settings.currentCycle)/\(Int(ceil((settings.maxValue - settings.minValue) / settings.stepSize)) + 1)")
                                    .font(.caption)
                                    .foregroundColor(Color.garageBandSecondary)
                                Text("\(String(format: "%.1f", settings.currentValue(baseValue: 0)))")
                                    .font(.caption)
                                    .foregroundColor(Color.garageBandAccent)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.garageBandAccent.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.garageBandPanel)
        .cornerRadius(12)
        .onDisappear {
            stopAutoAdvance()
        }
    }
    
    // MARK: - Computed Properties
    
    private var cycleProgress: Double {
        let maxCycles = calculateMaxCycles()
        return maxCycles > 0 ? Double(parameterManager.cyclicalSettings.currentCycle) / Double(maxCycles) : 0.0
    }
    
    private var maxCycles: Int {
        calculateMaxCycles()
    }
    
    // MARK: - Methods
    
    private func calculateMaxCycles() -> Int {
        let enabledParameters = parameterManager.cyclicalSettings.enabledParameters
        var maxCycles = 1
        
        for (_, settings) in enabledParameters {
            guard settings.isEnabled else { continue }
            
            let range = settings.maxValue - settings.minValue
            let cyclesNeeded = Int(ceil(range / settings.stepSize)) + 1
            
            maxCycles = max(maxCycles, cyclesNeeded)
        }
        
        return maxCycles
    }
    
    private func nextCycle() {
        parameterManager.cyclicalSettings.advanceAllCycles()
    }
    
    private func previousCycle() {
        parameterManager.cyclicalSettings.currentCycle = max(0, parameterManager.cyclicalSettings.currentCycle - 1)
    }
    
    private func resetCycles() {
        parameterManager.cyclicalSettings.resetAllCycles()
    }
    
    private func startAutoAdvance() {
        stopAutoAdvance() // Ensure we don't have multiple timers
        
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { _ in
            nextCycle()
        }
    }
    
    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }
}

/// Extension to add cycle control methods to CyclicalSettings
extension CyclicalSettings {
    var currentCycle: Int {
        get {
            // Return the maximum current cycle among all enabled parameters
            return enabledParameters.values.map { $0.currentCycle }.max() ?? 0
        }
        set {
            // Set the current cycle for all enabled parameters
            for (key, _) in enabledParameters {
                switch key {
                case .interpolationNotes:
                    interpolationNotes.currentCycle = newValue
                case .infrapolationNotes:
                    infrapolationNotes.currentCycle = newValue
                case .ultrapolationNotes:
                    ultrapolationNotes.currentCycle = newValue
                case .modulationInterval:
                    modulationInterval.currentCycle = newValue
                case .baseNoteDuration:
                    baseNoteDuration.currentCycle = newValue
                case .rhythmicDensity:
                    rhythmicDensity.currentCycle = newValue
                case .primaryInterval:
                    primaryInterval.currentCycle = newValue
                case .secondaryInterval:
                    secondaryInterval.currentCycle = newValue
                case .baseVelocity:
                    baseVelocity.currentCycle = newValue
                case .velocityRange:
                    velocityRange.currentCycle = newValue
                case .tempo:
                    tempo.currentCycle = newValue
                case .rootNote:
                    rootNote.currentCycle = newValue
                case .numberOfOctaves:
                    numberOfOctaves.currentCycle = newValue
                case .divisionsOfOctave:
                    divisionsOfOctave.currentCycle = newValue
                case .mirrorPoints:
                    mirrorPoints.currentCycle = newValue
                }
            }
        }
    }
    
    var maxCycles: Int {
        // Return the maximum cycles among all enabled parameters
        return enabledParameters.values.map { Int(ceil(($0.maxValue - $0.minValue) / $0.stepSize)) + 1 }.max() ?? 0
    }
}

#Preview {
    CycleControlView(parameterManager: ParameterManager())
        .frame(width: 400)
        .padding()
} 