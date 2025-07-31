# Slonimsky Pattern Generator - User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Interface Overview](#interface-overview)
4. [Pattern Generators](#pattern-generators)
5. [Parameter Categories](#parameter-categories)
6. [Basic Parameters](#basic-parameters)
7. [Interval Parameters](#interval-parameters)
8. [Slonimsky Modulations](#slonimsky-modulations)
9. [Directional Parameters](#directional-parameters)
10. [Rhythmic Parameters](#rhythmic-parameters)
11. [Harmonic Parameters](#harmonic-parameters)
12. [Expression Parameters](#expression-parameters)
13. [Auto-Generation](#auto-generation)
14. [Playback Controls](#playback-controls)
15. [Presets](#presets)
16. [Export and Import](#export-and-import)
17. [Tips and Techniques](#tips-and-techniques)
18. [Troubleshooting](#troubleshooting)

## Introduction

Slonimsky Pattern Generator is a sophisticated music composition tool inspired by Nicolas Slonimsky's "Thesaurus of Scales and Melodic Patterns." The app generates complex musical patterns using mathematical principles and advanced modulation techniques, allowing composers, musicians, and music theorists to explore new melodic and rhythmic possibilities.

### Key Features
- **Multiple Pattern Generators**: Scale, Interval, Contour, Harmonic, Rhythmic, and Modulation generators
- **Real-time MIDI Playback**: Hear your patterns immediately
- **Visual Representations**: Piano roll and sheet music views
- **Auto-generation**: Automatic pattern updates when parameters change
- **Looping Playback**: Continuous playback with seamless transitions
- **Export Capabilities**: Save patterns as MIDI files
- **Preset Library**: Pre-configured parameter sets for quick exploration

## Getting Started

### Launching the App
1. Open Slonimsky Pattern Generator
2. The app will load with default parameters and the Scale Pattern Generator selected
3. Click the "Generate" button to create your first pattern
4. Use the playback controls to hear the result

### Basic Workflow
1. **Select a Generator**: Choose from the available pattern generators
2. **Adjust Parameters**: Modify parameters in the left panel
3. **Generate Pattern**: Click "Generate" to create a new pattern
4. **Play and Listen**: Use playback controls to hear the result
5. **Refine**: Adjust parameters and regenerate as needed
6. **Export**: Save your pattern as a MIDI file

## Interface Overview

The app features a three-panel layout:

### Left Panel: Parameter Controls
- **Generator Selection**: Choose your pattern generator
- **Parameter Sections**: Collapsible sections for different parameter categories
- **Auto-generation Settings**: Control automatic pattern updates
- **Quick Actions**: Random generation, presets, and export buttons

### Center Panel: Piano Roll
- **Visual Pattern Display**: See your pattern as a piano roll
- **Playback Controls**: Play, pause, stop, and loop controls
- **Real-time Visualization**: Watch playback progress

### Right Panel: Sheet Music
- **Traditional Notation**: View your pattern in standard musical notation
- **Score Display**: See the pattern as it would appear on sheet music

### Toolbar
- **Panel Visibility**: Toggle visibility of each panel
- **Quick Actions**: Random generation, presets, and export
- **Navigation**: Access to main app functions

## Pattern Generators

### Scale Pattern Generator
Creates patterns based on traditional and non-traditional scales.
- **Best for**: Melodic lines, tonal music, traditional composition
- **Key parameters**: Scale type, root note, number of octaves

### Interval Pattern Generator
Generates patterns using specific interval relationships.
- **Best for**: Melodic development, interval studies, atonal music
- **Key parameters**: Primary/secondary intervals, interval patterns

### Contour Pattern Generator
Creates patterns based on melodic contour shapes.
- **Best for**: Expressive melodies, shape-based composition
- **Key parameters**: Contour pattern, intensity, direction

### Harmonic Pattern Generator
Generates harmonic progressions and chordal patterns.
- **Best for**: Harmonic composition, chord progressions, accompaniment
- **Key parameters**: Harmonic mode, chord generation, harmonic rhythm

### Rhythmic Pattern Generator
Creates complex rhythmic patterns with syncopation and metric modulation.
- **Best for**: Rhythmic composition, percussion patterns, groove creation
- **Key parameters**: Rhythmic density, syncopation, metric modulation

### Modulation Pattern Generator
Applies Slonimsky's modulation techniques to existing patterns.
- **Best for**: Complex transformations, advanced composition techniques
- **Key parameters**: Interpolation, infrapolation, ultrapolation

## Parameter Categories

The app organizes parameters into seven main categories, each controlling different aspects of pattern generation:

## Basic Parameters

Fundamental musical parameters that define the basic structure of your pattern.

### Root Note
- **Range**: 0-127 (MIDI note numbers)
- **Default**: 60 (Middle C)
- **Description**: The starting pitch that serves as the tonal center
- **Effect**: Higher values create higher-pitched patterns, lower values create bass patterns

### Scale Type
- **Options**: Chromatic, Diatonic, Pentatonic, Whole Tone, Octatonic, Custom
- **Default**: Chromatic
- **Description**: Defines the set of notes available for the pattern
- **Effect**: Different scales create distinct tonal characters and harmonic possibilities

### Number of Octaves
- **Range**: 1-8
- **Default**: 1
- **Description**: Determines the vertical range of the pattern
- **Effect**: More octaves create wider pitch ranges and more dramatic melodic possibilities

### Divisions of Octave
- **Range**: 1-12
- **Default**: 12
- **Description**: Splits each octave into equal parts
- **Effect**: 12 divisions = traditional semitones, higher values enable microtonal music

### Tempo
- **Range**: 60-240 BPM
- **Default**: 120 BPM
- **Description**: Sets the speed of the pattern in beats per minute
- **Effect**: Affects the overall energy and character of the pattern

### Time Signature
- **Options**: 2/4, 3/4, 4/4, 6/8, Custom
- **Default**: 4/4 (Common Time)
- **Description**: Defines the rhythmic structure and beat grouping
- **Effect**: Affects how rhythms are organized and emphasized

## Interval Parameters

Control how notes relate to each other melodically.

### Primary Interval
- **Range**: 1-12 semitones
- **Default**: 1
- **Description**: The main interval size between consecutive notes
- **Effect**: Creates the primary melodic character and movement

### Secondary Interval
- **Range**: 1-12 semitones
- **Default**: 1
- **Description**: An alternate interval used for variation and contrast
- **Effect**: Often used in patterns that alternate between different interval sizes

### Interval Pattern
- **Options**: Ascending, Descending, Alternating, Mirror, Retrograde
- **Default**: Ascending
- **Description**: How the interval is applied throughout the pattern
- **Effect**: Creates varied melodic contours and directions

### Interval Inversion
- **Default**: Disabled
- **Description**: Inverts intervals around the octave
- **Effect**: Creates harmonic variety and complexity

### Symmetrical Intervals
- **Default**: Disabled
- **Description**: Creates patterns that mirror around a central point
- **Effect**: Produces mathematically balanced structures with inherent symmetry

## Slonimsky Modulations

Advanced Slonimsky techniques for creating complex melodic transformations.

### Interpolation
- **Enabled**: Toggle on/off
- **Number of Notes**: 0-10
- **Interval**: 1-12 semitones
- **Description**: Inserts new notes between existing notes
- **Effect**: Creates smoother, more flowing melodic lines

### Infrapolation
- **Enabled**: Toggle on/off
- **Number of Notes**: 0-10
- **Interval**: 1-12 semitones
- **Description**: Adds notes below the existing melodic line
- **Effect**: Creates bass lines, harmonic depth, and fuller textures

### Ultrapolation
- **Enabled**: Toggle on/off
- **Number of Notes**: 0-10
- **Interval**: 1-12 semitones
- **Description**: Adds notes above the existing melodic line
- **Effect**: Creates descant lines, harmonic richness, and complex voicings

## Directional Parameters

Control the overall direction and shape of your melodic pattern.

### Primary Direction
- **Options**: Ascending, Descending, Alternating
- **Default**: Ascending
- **Description**: Sets the primary melodic direction
- **Effect**: Determines the overall trajectory of the melodic line

### Mirror Points
- **Range**: 0-10
- **Default**: 0
- **Description**: Number of points where the melody mirrors itself
- **Effect**: Creates symmetrical patterns around these points

### Retrograde Sections
- **Default**: Disabled
- **Description**: Plays some sections of the pattern backwards
- **Effect**: Creates palindrome-like effects where the melody reverses direction

### Register Shifts
- **Options**: None, Linear, Exponential, Random, Mirror, Symmetrical
- **Default**: None
- **Description**: How the pattern moves between different octave registers
- **Effect**: Creates dramatic pitch contrasts and varied tonal colors

### Contour Pattern
- **Options**: Linear, Arch, Inverted Arch, Wave, Random, Mirror
- **Default**: Linear
- **Description**: Defines the overall shape of the melodic line
- **Effect**: Creates different melodic characters and expressive qualities

## Rhythmic Parameters

Control the timing, duration, and rhythmic complexity of your pattern.

### Duration Pattern
- **Options**: Uniform, Alternating, Progressive, Random
- **Default**: Uniform
- **Description**: How note lengths vary throughout the pattern
- **Effect**: Creates rhythmic variety and interest

### Base Note Duration
- **Range**: 0.0625-4.0 seconds
- **Default**: 0.25 seconds
- **Description**: The fundamental note length in seconds
- **Effect**: Shorter values create faster, more energetic rhythms

### Rhythmic Density
- **Range**: 0.1-2.0
- **Default**: 1.0
- **Description**: How many notes occur per beat
- **Effect**: Higher values create busier, more complex rhythms

### Syncopation Level
- **Range**: 0.0-1.0
- **Default**: 0.0
- **Description**: Off-beat emphasis and rhythmic displacement
- **Effect**: Higher values create more syncopated, groove-oriented patterns

### Metric Modulation
- **Enabled**: Toggle on/off
- **Modulation Type**: Accelerando, Ritardando, Rubato, Pulse
- **Intensity**: 0.0-1.0
- **Frequency**: 1-16
- **Description**: Changes in tempo or rhythmic subdivision
- **Effect**: Creates complex, shifting rhythmic structures

## Harmonic Parameters

Control the harmonic content and chordal structure of your pattern.

### Harmonic Mode
- **Options**: Modal, Tonal, Atonal, Polymodal
- **Default**: Tonal
- **Description**: The harmonic approach and relationships
- **Effect**: Tonal follows traditional harmony, atonal avoids traditional consonance

### Chord Generation
- **Enabled**: Toggle on/off
- **Chord Size**: 2-6 notes
- **Voicing Preference**: Close, Open, Mixed
- **Velocity Scale**: 0.1-1.0
- **Description**: Creates chords instead of single notes
- **Effect**: Adds harmonic richness and creates more sophisticated textures

### Harmonic Rhythm
- **Chord Change Frequency**: 1-16 notes
- **Syncopation Level**: 0.0-1.0
- **Harmonic Tension**: 0.0-1.0
- **Description**: How frequently chords change and their rhythmic placement
- **Effect**: Creates harmonic movement, tension, and release

## Expression Parameters

Control the expressive qualities and performance characteristics of your pattern.

### Velocity Settings
- **Base Velocity**: 0-127
- **Velocity Range**: 0-127
- **Velocity Pattern**: Uniform, Random, Progressive, Accent
- **Description**: Control the dynamic intensity of each note
- **Effect**: Creates expressive, human-like performances

### Tone Shifting
- **Tone Increment**: 0-24 semitones
- **Max Tone Shift**: 0-96 semitones
- **Shift Pattern**: Various register shift patterns
- **Description**: Gradual pitch changes over time
- **Effect**: Creates evolving, shifting tonal centers

## Auto-Generation

The auto-generation feature automatically creates new patterns when parameters change.

### Enabling Auto-Generation
1. Open the Auto-Generation Settings section
2. Toggle "Enable Auto-Generation" to on
3. Adjust the delay (0.1-2.0 seconds) to control responsiveness

### How It Works
- When enabled, parameter changes trigger automatic pattern regeneration
- The delay prevents excessive regeneration during rapid parameter changes
- Works seamlessly with looping playback - new patterns start at the next loop iteration

### Best Practices
- Use shorter delays for real-time experimentation
- Use longer delays when making multiple parameter changes
- Disable when making precise adjustments to avoid unwanted regeneration

## Playback Controls

### Basic Controls
- **Play/Pause**: Start or pause playback
- **Stop**: Stop playback and return to beginning
- **Loop**: Toggle continuous looping
- **Progress Bar**: Shows current playback position

### Advanced Features
- **Seamless Looping**: Patterns loop without interruption
- **Real-time Updates**: New patterns integrate smoothly with looping
- **MIDI Output**: Playback through any connected MIDI device

### Playback Tips
- Use looping to hear how patterns develop over time
- Combine with auto-generation for continuous evolution
- Export patterns to hear them in other applications

## Presets

The app includes a library of pre-configured parameter sets for quick exploration.

### Available Presets
- **Classical Scales**: Traditional diatonic and pentatonic patterns
- **Modern Intervals**: Contemporary interval-based patterns
- **Complex Modulations**: Advanced Slonimsky techniques
- **Rhythmic Complexity**: Syncopated and metric-modulated patterns
- **Harmonic Progression**: Chord-based harmonic patterns
- **Melodic Contours**: Expressive contour-based patterns

### Using Presets
1. Click the "Presets" button in the toolbar
2. Browse available presets by category
3. Select a preset to load its parameters
4. Generate a pattern with the preset settings
5. Modify parameters as needed

### Creating Custom Presets
- Adjust parameters to your desired settings
- Note the parameter values for future reference
- Consider saving successful combinations for reuse

## Export and Import

### Exporting Patterns
1. Generate a pattern you want to save
2. Click the "Export" button in the toolbar
3. Choose a location and filename
4. The pattern is saved as a MIDI file

### MIDI File Format
- Standard MIDI file format (.mid)
- Compatible with all major music software
- Includes all note data, timing, and velocity information
- Can be imported into DAWs, notation software, and other applications

### Import Considerations
- MIDI files can be imported into most music software
- Note that the app focuses on generation rather than import
- Use export to integrate with your existing workflow

## Tips and Techniques

### Getting Started
1. **Start Simple**: Begin with basic parameters and gradually add complexity
2. **Listen Actively**: Pay attention to how each parameter affects the sound
3. **Experiment**: Don't be afraid to try extreme parameter values
4. **Use Presets**: Learn from the included presets to understand parameter combinations

### Advanced Techniques
1. **Layered Composition**: Generate multiple patterns and combine them
2. **Parameter Relationships**: Understand how different parameters interact
3. **Rhythmic Complexity**: Use syncopation and metric modulation for groove
4. **Harmonic Development**: Combine different harmonic modes for variety

### Creative Approaches
1. **Algorithmic Composition**: Let the app generate ideas you wouldn't think of
2. **Parameter Exploration**: Systematically explore parameter ranges
3. **Hybrid Techniques**: Combine generated patterns with manual composition
4. **Performance Integration**: Use generated patterns as starting points for performance

## Troubleshooting

### Common Issues

**Pattern Generation Fails**
- Check parameter validation (look for error messages)
- Ensure all parameters are within valid ranges
- Try resetting to default parameters

**Playback Issues**
- Verify MIDI device connections
- Check system audio settings
- Restart the app if necessary

**Performance Problems**
- Reduce rhythmic density for complex patterns
- Lower the number of octaves for simpler patterns
- Disable auto-generation during intensive parameter changes

**Parameter Conflicts**
- Some parameter combinations may not work well together
- Use the validation system to identify conflicts
- Start with presets and modify gradually

### Getting Help
- Check parameter descriptions for guidance
- Use the info buttons for detailed parameter information
- Experiment with presets to understand parameter relationships
- Start with simple patterns and build complexity gradually

---

*This user guide covers the core functionality of Slonimsky Pattern Generator. The app is designed for exploration and experimentation - don't hesitate to try new parameter combinations and discover your own creative possibilities.* 