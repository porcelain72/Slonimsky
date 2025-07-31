# Slonimsky Pattern Generation System Documentation

## Overview

The Slonimsky Pattern Generation System is a sophisticated, modular architecture for generating musical patterns based on Nicolas Slonimsky's Thesaurus of Scales and Melodic Patterns. The system supports both individual generator operation and intelligent combined generation modes.

## Architecture

### Core Components

1. **PatternGenerator Protocol** - Core interface all generators implement
2. **PatternGeneratorRegistry** - Central registry managing all generators
3. **ParameterApplicationManager** - Coordinates parameter application order
4. **Individual Generators** - Specialized implementations for different pattern types
5. **ParameterManager** - Manages all parameters and automatic generator selection

### Generator Types

| Generator | Purpose | Triggered By |
|-----------|---------|--------------|
| Scale Pattern Generator | Generates scale-based melodic patterns | Basic parameters (always active) |
| Interval Pattern Generator | Creates interval-based patterns with inversions | Interval parameters |
| Modulation Pattern Generator | Handles Slonimsky modulations | Modulation parameters |
| Contour Pattern Generator | Focuses on melodic contour shapes | Directional parameters |
| Harmonic Pattern Generator | Creates harmonic progressions | Harmonic parameters |
| Rhythmic Pattern Generator | Specializes in rhythmic patterns | Rhythmic parameters |
| Symmetrical Pattern Generator | Creates symmetrical patterns | Symmetrical parameters |

## Generation Modes

### 1. Single Generator Mode (Default)
- Each generator operates independently
- Generators are selected individually via `selectedGenerator` parameter
- Only one generator processes the parameters at a time
- Example: `ScalePatternGenerator` processes all parameters alone

### 2. Combined Mode (Automatic/Manual)
- Multiple generators can be combined using `generateCombinedPattern()`
- Three combination modes available:
  - **Sequential**: Patterns concatenated end-to-end
  - **Interleaved**: Notes from different generators alternated
  - **Layered**: Notes combined at same time positions

## Automatic Generator Selection

### Overview
The system now includes intelligent automatic generator selection that analyzes parameter usage and automatically activates the most appropriate generators.

### How It Works

1. **Parameter Monitoring**: System monitors all parameter changes
2. **Generator Detection**: Analyzes which generators are needed based on active parameters
3. **Automatic Activation**: Activates appropriate generators automatically
4. **Combination Mode Selection**: Chooses optimal combination mode
5. **Pattern Generation**: Uses selected generators to create patterns

### Parameter-to-Generator Mapping

```swift
// Scale Pattern Generator (Always Active)
- rootNote, scaleType, numberOfOctaves, divisionsOfOctave, tempo, timeSignature

// Interval Pattern Generator
- primaryInterval != 1 || secondaryInterval != 1
- intervalPattern != .ascending
- intervalInversion = true
- symmetricalIntervals = true

// Modulation Pattern Generator
- interpolation.enabled = true
- infrapolation.enabled = true
- ultrapolation.enabled = true

// Contour Pattern Generator
- primaryDirection != .ascending
- mirrorPoints > 0
- retrogradeSections = true
- registerShifts != .none
- contourPattern != .linear

// Rhythmic Pattern Generator
- noteDurationPattern != .uniform
- rhythmicDensity != 1.0
- syncopationLevel > 0
- metricModulation.enabled = true

// Harmonic Pattern Generator
- harmonicMode != .tonal
- chordGeneration.enabled = true
- harmonicRhythm.chordChangeFrequency != 4

// Symmetrical Pattern Generator
- symmetricalIntervals = true
- mirrorPoints > 0
```

### Combination Mode Logic

```swift
func determineCombinationMode() -> PatternCombinationMode {
    guard activeGenerators.count > 1 else { return .sequential }
    
    // Use layered mode if harmonic generator is active with others
    if activeGenerators.contains("Harmonic Pattern Generator") && activeGenerators.count > 1 {
        return .layered
    }
    
    // Use interleaved mode for rhythmic + melodic combinations
    if activeGenerators.contains("Rhythmic Pattern Generator") && 
       (activeGenerators.contains("Scale Pattern Generator") || activeGenerators.contains("Interval Pattern Generator")) {
        return .interleaved
    }
    
    // Default to sequential for other combinations
    return .sequential
}
```

## Parameter Application Process

### Priority-Based Application
The system uses a sophisticated priority-based parameter application system:

```swift
enum ParameterPriority: Int, CaseIterable {
    case baseGeneration = 0      // Root note, scale type, intervals
    case directionalPatterns = 1 // Primary direction, interval patterns
    case registerShifts = 2      // Tone shifting, register shifts
    case contourPatterns = 3     // Contour patterns (with reduced intensity)
    case velocitySettings = 4    // Velocity calculations
    case durationPatterns = 5    // Note duration patterns
    case modulations = 6         // Slonimsky modulations (final)
}
```

### Parameter Conflict Resolution
The `ParameterApplicationManager` prevents conflicts by:
- Applying parameters in priority order
- Using reduced intensity for certain generators (e.g., contour intensity 0.3 for scale generators)
- Skipping incompatible parameters for specific generator types

## Individual Generator Analysis

### ScalePatternGenerator
- **Purpose**: Generates scale-based melodic patterns
- **Process Flow**:
  1. Generate base scale notes using `scaleType.intervals`
  2. Apply parameters via `ParameterApplicationManager`
  3. Apply Slonimsky modulations (interpolation, infrapolation, ultrapolation)
- **Specialization**: Preserves scale relationships, reduced contour intensity (0.3)

### IntervalPatternGenerator
- **Purpose**: Creates interval-based patterns with inversions
- **Process Flow**:
  1. Generate interval sequence using primary/secondary intervals
  2. Apply interval patterns (ascending, descending, alternating, mirror, retrograde)
  3. Convert intervals to absolute notes
  4. Apply symmetrical transformations if enabled
  5. Apply remaining parameters via `ParameterApplicationManager`
- **Specialization**: Handles interval inversions and symmetrical relationships

### Other Generators
- **ContourPatternGenerator**: Focuses on melodic contour shapes
- **HarmonicPatternGenerator**: Creates harmonic progressions
- **RhythmicPatternGenerator**: Specializes in rhythmic patterns
- **ModulationPatternGenerator**: Handles Slonimsky modulations
- **SymmetricalPatternGenerator**: Creates symmetrical patterns

## Performance Monitoring

Each generation includes comprehensive metrics:
- Generation time
- Memory usage
- Complexity calculation
- Note count estimation

## User Interface

### Automatic Generator Selection Controls
- **Toggle**: Enable/disable automatic selection in Auto-generation settings
- **Visual Feedback**: Shows active generators and combination mode
- **Fallback**: Manual generator selection when automatic mode is disabled

### UI Features
- Real-time display of active generators
- Combination mode indicator
- Parameter-based activation feedback
- Help text explaining the feature

## Implementation Details

### ParameterManager Properties
```swift
@Published var automaticGeneratorSelectionEnabled = true
@Published var activeGenerators: [String] = ["Scale Pattern Generator"]
@Published var combinationMode: PatternCombinationMode = .sequential
```

### Key Methods
```swift
func determineActiveGenerators() -> [String]
func updateActiveGenerators()
func determineCombinationMode() -> PatternCombinationMode
func updateCombinationMode()
func updateGeneratorSelection()
```

### MIDI Integration
- Auto-generation uses combined patterns when multiple generators are active
- Falls back to single generator when only one is needed
- Maintains backward compatibility with manual selection

## Testing

### Test Coverage
- Initial state verification
- Parameter-based activation of generators
- Combination mode selection
- Disabling automatic selection
- All parameter categories trigger appropriate generators

### Example Test
```swift
func testAutomaticGeneratorSelection() {
    let parameterManager = ParameterManager()
    
    // Test interval parameters activation
    parameterManager.primaryInterval = 3
    parameterManager.intervalInversion = true
    
    // Should now include Interval Pattern Generator
    XCTAssertTrue(parameterManager.activeGenerators.contains("Interval Pattern Generator"))
}
```

## Benefits

1. **Seamless Experience**: Users don't need to manually select generators
2. **Intelligent Combinations**: System automatically chooses the best way to combine generators
3. **Parameter-Driven**: Generator selection is based on actual parameter usage
4. **Transparent**: Users can see which generators are active and why
5. **Flexible**: Can be disabled for manual control when needed

## Usage Examples

### Basic Usage
1. User adjusts parameters (e.g., changes interval pattern, enables modulations)
2. System detects parameter changes via `validateAndNotify()`
3. Automatic selection triggers and analyzes which generators are needed
4. Generators are activated based on parameter usage
5. Combination mode is selected based on generator types
6. Pattern generation uses the appropriate generators automatically
7. UI updates to show active generators and combination mode

### Advanced Usage
- Multiple parameter categories can be active simultaneously
- System intelligently combines generators for complex patterns
- Real-time feedback shows which generators are contributing to the pattern
- Users can override automatic selection for manual control

## Future Enhancements

1. **Machine Learning**: Could use ML to optimize generator combinations based on user preferences
2. **Custom Generator Rules**: Allow users to define custom parameter-to-generator mappings
3. **Generator Weighting**: Assign importance weights to different generators
4. **Pattern Templates**: Pre-defined generator combinations for common musical styles
5. **Performance Optimization**: Cache generator combinations for faster pattern generation

---

*This documentation covers the complete PatternGeneration system as of January 2025, including the new automatic generator selection feature.* 