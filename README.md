# Slonimsky Pattern Generator

A sophisticated pattern generation system for musical composition based on Nicolas Slonimsky's *Thesaurus of Scales and Melodic Patterns*. This macOS application provides an interactive interface for exploring and generating musical patterns using advanced algorithmic techniques.

## 🎵 Features

### **Pattern Generation**
- **Multiple Generators**: Scale, Interval, Modulation, Rhythmic, Harmonic, Contour, and Symmetrical pattern generators
- **Combined Generation**: Intelligent combination of multiple generators for complex patterns
- **Real-time Generation**: Live parameter adjustment with immediate pattern updates
- **Auto-generation**: Automatic pattern regeneration based on parameter changes

### **Musical Parameters**
- **Basic Parameters**: Root note, scale type, octaves, tempo, time signature
- **Interval Parameters**: Primary/secondary intervals, patterns, inversions, symmetrical intervals
- **Modulation Parameters**: Interpolation, infrapolation, ultrapolation settings
- **Directional Parameters**: Direction, mirror points, retrograde sections, register shifts, contour patterns
- **Rhythmic Parameters**: Duration patterns, density, syncopation, metric modulation
- **Harmonic Parameters**: Harmonic mode, chord generation, harmonic rhythm
- **Expression Parameters**: Velocity settings, tone shifting

### **MIDI Integration**
- **Real-time Playback**: Play generated patterns immediately
- **MIDI Export**: Export patterns as MIDI files
- **Rhythmic Accompaniment**: Optional rhythmic backing patterns
- **Seamless Updates**: Pattern updates without interrupting playback

### **User Interface**
- **Three-Panel Layout**: Parameter controls, piano roll visualization, and sheet music
- **Interactive Controls**: Real-time parameter adjustment with visual feedback
- **Preset System**: Save and load parameter configurations
- **Randomization**: Randomize individual parameter categories or all parameters
- **Parameter Validation**: Built-in validation to ensure musical coherence

## 🚀 Getting Started

### **Prerequisites**
- macOS 13.5 or later
- Xcode 15.0 or later (for development)
- Swift 5.9 or later

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/porcelain72/Slonimsky.git
   cd Slonimsky
   ```

2. **Build the project**
   ```bash
   xcodebuild -project Slonimsky.xcodeproj -scheme Slonimsky -configuration Debug build
   ```

3. **Run the application**
   ```bash
   open /Users/petermacdonald/Library/Developer/Xcode/DerivedData/Slonimsky-*/Build/Products/Debug/Slonimsky.app
   ```

### **Development Setup**

1. **Open in Xcode**
   ```bash
   open Slonimsky.xcodeproj
   ```

2. **Build and Run**
   - Select the "Slonimsky" scheme
   - Choose your target device (macOS)
   - Press ⌘+R to build and run

## 🎼 Usage

### **Basic Pattern Generation**

1. **Launch the application**
2. **Enable Auto-generation** in the settings panel
3. **Adjust parameters** in the left panel:
   - Set root note and scale type
   - Choose interval patterns
   - Adjust rhythmic parameters
4. **Listen to the pattern** using the playback controls
5. **Export as MIDI** when satisfied with the result

### **Advanced Features**

#### **Combined Generation**
- Enable multiple generators simultaneously
- Choose combination modes: Sequential, Interleaved, or Layered
- Automatic generator selection based on parameter usage

#### **Parameter Randomization**
- Randomize specific parameter categories
- Randomize all parameters at once
- Save interesting configurations as presets

#### **Real-time Adjustment**
- Make live parameter changes
- Observe immediate pattern updates
- Fine-tune patterns during playback

## 🏗️ Architecture

### **Core Components**

#### **Pattern Generators**
- `ScalePatternGenerator`: Basic scale-based patterns
- `IntervalPatternGenerator`: Interval-based melodic patterns
- `ModulationPatternGenerator`: Slonimsky modulation techniques
- `RhythmicPatternGenerator`: Rhythmic pattern generation
- `HarmonicPatternGenerator`: Harmonic accompaniment patterns
- `ContourPatternGenerator`: Melodic contour patterns
- `SymmetricalPatternGenerator`: Symmetrical pattern structures

#### **Services**
- `ParameterManager`: Manages all pattern generation parameters
- `MIDIIntegrationService`: Handles MIDI generation and playback
- `PatternGeneratorRegistry`: Coordinates pattern generators
- `MIDIEngine`: Core MIDI playback engine

#### **User Interface**
- `MainContentView`: Main application interface
- `ParameterPanelView`: Parameter adjustment controls
- `PianoRollPanelView`: Visual pattern representation
- `SheetMusicPanelView`: Sheet music display

### **Key Design Patterns**

- **Observer Pattern**: Parameter changes trigger pattern regeneration
- **Factory Pattern**: Pattern generator creation and management
- **Strategy Pattern**: Different combination modes for pattern generation
- **Publisher-Subscriber**: Real-time parameter change notifications

## 🔧 Configuration

### **Auto-generation Settings**
- **Delay**: Set delay between parameter changes and regeneration
- **Generator Selection**: Choose automatic or manual generator selection
- **Combination Mode**: Select how multiple generators combine patterns

### **MIDI Settings**
- **Output Device**: Select MIDI output device
- **Tempo**: Adjust playback tempo
- **Rhythmic Accompaniment**: Enable/disable backing patterns

### **Interface Settings**
- **Panel Visibility**: Show/hide parameter, piano roll, and sheet music panels
- **Theme**: Light/dark mode support
- **Layout**: Adjustable panel sizes and positions

## 🧪 Testing

### **Running Tests**
```bash
xcodebuild -project Slonimsky.xcodeproj -scheme Slonimsky -configuration Debug test
```

### **Test Coverage**
- **Unit Tests**: Pattern generation algorithms
- **Integration Tests**: MIDI generation and playback
- **UI Tests**: User interface functionality
- **Performance Tests**: Generation speed and memory usage

## 📁 Project Structure

```
Slonimsky/
├── Slonimsky/
│   ├── PatternGenerators/     # Pattern generation algorithms
│   ├── MIDI/                  # MIDI integration and playback
│   ├── UI/                    # User interface components
│   ├── Models/                # Data models and structures
│   ├── Extensions/            # Swift extensions
│   └── Resources/             # Localization and assets
├── SlonimskyTests/            # Unit tests
├── SlonimskyUITests/          # UI tests
└── Documentation/             # Project documentation
```

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### **Development Guidelines**
- Follow Swift style guidelines
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Nicolas Slonimsky**: For his groundbreaking work in *Thesaurus of Scales and Melodic Patterns*
- **Salieri**: For sheet music rendering capabilities
- **SwiftUI**: For the modern user interface framework
- **Core MIDI**: For MIDI integration and playback

## 📞 Support

- **Issues**: Report bugs and request features on [GitHub Issues](https://github.com/porcelain72/Slonimsky/issues)
- **Discussions**: Join the conversation on [GitHub Discussions](https://github.com/porcelain72/Slonimsky/discussions)
- **Documentation**: Check the [Wiki](https://github.com/porcelain72/Slonimsky/wiki) for detailed guides

## 🔄 Recent Updates

### **Latest Release**
- **Fixed autogeneration pattern reversion issue**
- **Added parameter hash tracking** to prevent unnecessary regeneration
- **Improved generator selection stability**
- **Added pattern caching mechanism**
- **Enhanced parameter change detection**

---

**Happy composing! 🎵** 