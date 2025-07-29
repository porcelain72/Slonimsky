# Slonimsky Music Generator - Complete Specification

## Overview
A macOS music generation app that implements Nicolas Slonimsky's "Thesaurus of Scales and Melodic Patterns" with advanced parameter controls, real-time preview, and polyphonic output capabilities.

## Target Platform
- **OS**: macOS 13.5+
- **Framework**: SwiftUI
- **Architecture**: MVVM with modular components
- **Dependencies**: Salieri (sheet music), Core MIDI, AVFoundation

## User Interface Design

### Three-Panel Layout

#### Panel 1: Parameter Controls (Left - 350px width)
**Collapsible Sections:**

1. **Basic Parameters**
   - Root Note (0-127, with note name display)
   - Scale Type (Chromatic, Diatonic, Pentatonic, Whole-tone, Octatonic, Diminished, Augmented, Custom)
   - Number of Octaves (1-8)
   - Divisions of Octave (1-12)
   - Base Tempo (60-240 BPM)
   - Time Signature (2/4, 3/4, 4/4, 6/8, Custom)

2. **Interval Patterns**
   - Primary Interval (1-12 semitones)
   - Secondary Interval (1-12 semitones)
   - Interval Cycle Pattern (Ascending, Descending, Alternating, Mirror, Retrograde)
   - Interval Inversion (On/Off)
   - Symmetrical Intervals (On/Off)

3. **Slonimsky Modulations**
   - **Interpolation**: Insert notes between existing notes
     - Number of interpolated notes (0-10)
     - Interval between interpolated notes (1-12)
   - **Infrapolation**: Insert notes below existing notes
     - Number of infrapolated notes (0-10)
     - Interval between infrapolated notes (1-12)
   - **Ultrapolation**: Insert notes above existing notes
     - Number of ultrapolated notes (0-10)
     - Interval between ultrapolated notes (1-12)

4. **Directional Patterns**
   - Primary Direction (Ascending, Descending, Alternating)
   - Mirror Points (0-10)
   - Retrograde Sections (On/Off)
   - Register Shifts (Octave displacement patterns)
   - Contour Patterns (Melodic shape variations)

5. **Rhythmic Patterns**
   - Note Duration Pattern (Uniform, Alternating, Progressive, Random)
   - Base Note Duration (0.0625-4.0 seconds)
   - Rhythmic Density (0.1-2.0 multiplier)
   - Syncopation Level (0-100%)
   - Metric Modulation (Tempo changes based on patterns)

6. **Harmonic Context**
   - Harmonic Mode (Modal, Tonal, Atonal, Polymodal)
   - Chord Generation (On/Off)
   - Chord Size (2-6 notes)
   - Voicing Preference (Close, Open, Mixed)
   - Harmonic Rhythm (Chord change frequency)

7. **Velocity & Expression**
   - Base Velocity (1-127)
   - Velocity Range (0-127)
   - Wave Depth (0-1)
   - Randomness (0-1)
   - Phase (0-2π)
   - Emphasis Beat (1-16)
   - Emphasis Amount (0-1)

8. **Tone Shifting**
   - Tone Increment (0-24 semitones)
   - Max Tone Shift (0-96 semitones)
   - Shift Pattern (Linear, Exponential, Random)

9. **Presets & Randomization**
   - Preset Library (Classic Slonimsky patterns)
   - Randomize All Parameters
   - Randomize Selected Section
   - Save Custom Preset
   - Load Preset

10. **Playback Controls**
    - Generate & Play
    - Stop
    - Pause/Resume
    - Loop (On/Off)
    - External MIDI Output (On/Off)
    - Estimated Duration Display

#### Panel 2: Piano Roll Visualization (Center - 400px width)
- **Real-time note display** with color-coded velocity
- **Zoom controls** (horizontal and vertical)
- **Playhead indicator** during playback
- **Note selection** for editing
- **Grid options** (beat, measure, note)
- **Channel separation** for polyphonic display
- **Timeline scrubber**

#### Panel 3: Sheet Music Display (Right - Flexible width)
- **Salieri-rendered score** with real-time updates
- **Multiple staff options** (piano, ensemble, custom)
- **Zoom controls**
- **Page navigation**
- **Export options** (PDF, MIDI, MusicXML)

## Sequence Engine Architecture

### Core Components

#### 1. PatternGenerator Protocol
```swift
protocol PatternGenerator {
    func generatePattern(parameters: PatternParameters) -> [MIDIInfo]
    func estimateNoteCount(parameters: PatternParameters) -> Int
    func validateParameters(parameters: PatternParameters) -> Bool
}
```

#### 2. Modular Pattern Types
- **ScalePatternGenerator**: Basic scale patterns
- **IntervalPatternGenerator**: Interval-based patterns
- **ModulationPatternGenerator**: Slonimsky modulations
- **RhythmicPatternGenerator**: Rhythmic variations
- **HarmonicPatternGenerator**: Chord progressions
- **ContourPatternGenerator**: Melodic shapes
- **SymmetricalPatternGenerator**: Symmetrical scales

#### 3. Pattern Recognition Engine
- **Harmonic Analysis**: Detect chord progressions
- **Melodic Analysis**: Identify melodic patterns
- **Rhythmic Analysis**: Analyze rhythmic structures
- **Tension Analysis**: Calculate harmonic tension

#### 4. Polyphonic Engine
- **Multi-channel support** (16 MIDI channels)
- **Voice allocation** algorithms
- **Harmonic voicing** for chords
- **Counterpoint generation**

### Data Models

#### PatternParameters
```swift
struct PatternParameters {
    // Basic parameters
    let rootNote: Int
    let scaleType: ScaleType
    let numberOfOctaves: Int
    let divisionsOfOctave: Int
    let tempo: Double
    let timeSignature: TimeSignature
    
    // Interval patterns
    let primaryInterval: Int
    let secondaryInterval: Int
    let intervalPattern: IntervalPattern
    let intervalInversion: Bool
    let symmetricalIntervals: Bool
    
    // Slonimsky modulations
    let interpolation: ModulationSettings
    let infrapolation: ModulationSettings
    let ultrapolation: ModulationSettings
    
    // Directional patterns
    let primaryDirection: Direction
    let mirrorPoints: Int
    let retrogradeSections: Bool
    let registerShifts: RegisterShiftPattern
    let contourPattern: ContourPattern
    
    // Rhythmic patterns
    let noteDurationPattern: DurationPattern
    let baseNoteDuration: TimeInterval
    let rhythmicDensity: Double
    let syncopationLevel: Double
    let metricModulation: MetricModulationSettings
    
    // Harmonic context
    let harmonicMode: HarmonicMode
    let chordGeneration: ChordSettings
    let harmonicRhythm: HarmonicRhythmSettings
    
    // Expression
    let velocitySettings: VelocitySettings
    let toneShifting: ToneShiftSettings
}
```

#### ModulationSettings
```swift
struct ModulationSettings {
    let numberOfNotes: Int
    let interval: Int
    let enabled: Bool
}
```

#### VelocitySettings
```swift
struct VelocitySettings {
    let baseVelocity: UInt8
    let range: UInt8
    let waveDepth: Double
    let randomness: Double
    let phase: Double
    let emphasisBeat: Int
    let emphasisAmount: Double
}
```

## Output System

### MIDI Generation
- **Multi-track MIDI** with separate channels for melody, harmony, and bass
- **Real-time MIDI output** to external devices
- **MIDI file export** with metadata
- **MIDI CC messages** for expression

### Sheet Music Generation
- **Salieri integration** for high-quality notation
- **Multiple staff layouts** (piano, ensemble, custom)
- **Dynamic page layout** based on content
- **PDF export** with proper formatting
- **MusicXML export** (future enhancement)

### Audio Output
- **Internal audio playback** using AVFoundation
- **Real-time synthesis** with velocity-sensitive sounds
- **Audio file export** (WAV, AIFF)

## Performance Requirements

### Real-time Performance
- **Parameter changes**: Update preview within 100ms
- **Pattern generation**: Complete within 500ms for complex patterns
- **Sheet music rendering**: Update within 1 second
- **MIDI playback**: Latency < 10ms

### Memory Management
- **Efficient pattern storage** using lazy evaluation
- **Streaming generation** for large patterns
- **Memory cleanup** for unused patterns

## Error Handling

### Parameter Validation
- **Real-time validation** of parameter combinations
- **Helpful error messages** with suggestions
- **Parameter constraints** to prevent invalid states

### Generation Errors
- **Graceful degradation** when patterns fail
- **Fallback patterns** for edge cases
- **Error logging** for debugging

## Testing Strategy

### Unit Tests
- **Pattern generators** for each modulation type
- **Parameter validation** logic
- **MIDI generation** accuracy
- **Harmonic analysis** algorithms

### Integration Tests
- **End-to-end generation** workflows
- **UI responsiveness** during generation
- **Export functionality** validation

### Performance Tests
- **Generation speed** benchmarks
- **Memory usage** monitoring
- **Real-time performance** validation

## Future Enhancements

### Phase 2 Features
- **MusicXML export** support
- **Advanced harmonic analysis**
- **Machine learning** pattern suggestions
- **Collaborative features** for pattern sharing

### Phase 3 Features
- **Audio synthesis** with custom instruments
- **Real-time collaboration** features
- **Advanced visualization** options
- **Mobile companion app**

## Implementation Priority

### Phase 1 (Core Functionality)
1. **Basic parameter controls** with collapsible sections
2. **Core pattern generators** (Scale, Interval, Modulation)
3. **Three-panel interface** implementation
4. **MIDI generation** and playback
5. **Basic sheet music** rendering

### Phase 2 (Advanced Features)
1. **Polyphonic engine** implementation
2. **Pattern recognition** algorithms
3. **Advanced rhythmic** patterns
4. **Harmonic analysis** and suggestions
5. **Preset library** implementation

### Phase 3 (Polish & Optimization)
1. **Performance optimization**
2. **Advanced UI features**
3. **Export enhancements**
4. **Error handling** improvements
5. **Documentation** and help system

## Development Workflow & Commit Rules

### Incremental Development Rules

#### 1. **Small, Focused Commits**
- **Maximum commit size**: One logical feature or component per commit
- **Commit frequency**: Commit after each working feature or significant refactor
- **Commit scope**: Avoid mixing UI changes with engine changes in same commit

#### 2. **Commit Message Format**
```
type(scope): brief description

- Detailed bullet points of changes
- Any breaking changes noted
- Related issue numbers if applicable
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `docs`: Documentation changes
- `style`: Code style/formatting changes
- `perf`: Performance improvements

**Examples:**
```
feat(patterns): add ScalePatternGenerator with chromatic scale support

- Implements basic chromatic scale generation
- Adds ScaleType enum with chromatic variant
- Includes unit tests for scale generation
- Updates PatternGenerator protocol

refactor(ui): extract ParameterControlsView into modular sections

- Creates collapsible section components
- Separates basic parameters from advanced controls
- Improves code organization and maintainability
```

#### 3. **Pre-Commit Checklist**
- [ ] Code compiles without errors
- [ ] All existing tests pass
- [ ] New functionality has corresponding tests
- [ ] No debug code or print statements left in
- [ ] Code follows project style guidelines
- [ ] Documentation updated if needed

#### 4. **Feature Branch Strategy**
- **Main branch**: Always stable and deployable
- **Feature branches**: One per major feature or component
- **Branch naming**: `feature/component-name` or `refactor/component-name`
- **Merge strategy**: Squash and merge for clean history

#### 5. **Testing Requirements**
- **Unit tests**: Required for all new pattern generators
- **Integration tests**: Required for UI components
- **Test coverage**: Maintain minimum 80% coverage
- **Performance tests**: Required for pattern generation algorithms

#### 6. **Code Review Process**
- **Self-review**: Review own code before committing
- **Peer review**: Required for major changes (optional for this project)
- **Documentation**: Update relevant documentation with each change

#### 7. **Incremental Implementation Order**
1. **Data Models First**: Always implement data structures before using them
2. **Core Engine**: Build pattern generators before UI integration
3. **UI Components**: Create reusable components before complex views
4. **Integration**: Connect components only after individual testing
5. **Polish**: Add features like presets after core functionality works

#### 8. **Rollback Strategy**
- **Git tags**: Tag stable versions before major changes
- **Feature flags**: Use feature flags for experimental features
- **Backup branches**: Create backup branches before major refactors

#### 9. **Documentation Updates**
- **Code comments**: Update with each significant change
- **README**: Update when adding new features
- **API documentation**: Update when changing public interfaces
- **User guide**: Update when changing UI behavior

#### 10. **Performance Monitoring**
- **Benchmark tests**: Run performance tests before and after changes
- **Memory profiling**: Monitor memory usage for pattern generation
- **Real-time performance**: Test UI responsiveness after changes

#### 11. **Change Logging Requirements**
- **Development Log**: Maintain `DEVELOPMENT_LOG.md` with all changes and attempts
- **Attempted Changes**: Document failed approaches and lessons learned
- **Decision Rationale**: Record why specific implementation choices were made
- **Performance Impact**: Track performance changes over time
- **Bug Tracking**: Document bugs found and their resolution

**Change Log Format:**
```markdown
## [Date] - [Type of Change]

### Changes Made
- [ ] Feature/Component: Description of what was implemented
- [ ] Files Modified: List of files changed
- [ ] Tests Added: New test coverage
- [ ] Performance Impact: Any performance changes

### Attempted Changes (Failed/Rejected)
- [ ] Approach: Description of what was tried
- [ ] Reason for Failure: Why it didn't work
- [ ] Lessons Learned: What was learned from the attempt
- [ ] Alternative Solution: What was implemented instead

### Decisions Made
- [ ] Decision: What was decided
- [ ] Rationale: Why this choice was made
- [ ] Alternatives Considered: Other options that were evaluated
- [ ] Impact: How this affects future development

### Bugs Found & Fixed
- [ ] Bug Description: What was broken
- [ ] Root Cause: Why it happened
- [ ] Fix Applied: How it was resolved
- [ ] Prevention: How to prevent similar issues
```

**Log Maintenance Rules:**
- **Update frequency**: After each significant change or attempt
- **Detail level**: Include enough context for future reference
- **Cross-references**: Link to relevant commits and issues
- **Archival**: Keep historical logs for reference
- **Review**: Periodically review logs for patterns and improvements

This specification provides a comprehensive roadmap for the complete rewrite of the Slonimsky app, ensuring all requirements are met while maintaining extensibility for future enhancements. 