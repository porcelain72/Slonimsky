#!/usr/bin/env python3

import re
import uuid

# All files to add
all_files = [
    # Models
    "Models/PatternParameters.swift",
    "Models/VelocitySettings.swift", 
    "Models/ModulationSettings.swift",
    
    # Pattern Generators
    "PatternGenerators/PatternGenerator.swift",
    "PatternGenerators/ScalePatternGenerator.swift",
    "PatternGenerators/IntervalPatternGenerator.swift",
    "PatternGenerators/ModulationPatternGenerator.swift",
    "PatternGenerators/RhythmicPatternGenerator.swift",
    "PatternGenerators/HarmonicPatternGenerator.swift",
    "PatternGenerators/ContourPatternGenerator.swift",
    "PatternGenerators/SymmetricalPatternGenerator.swift",
    "PatternGenerators/PatternGeneratorRegistry.swift",
    
    # MIDI
    "MIDI/MIDIEngine.swift",
    "MIDI/MIDIIntegrationService.swift",
    "MIDI/MIDIPlaybackControllerView.swift",
    
    # UI
    "UI/MainContentView.swift",
    "UI/ParameterManager.swift",
    "UI/ParameterPanelView.swift",
    "UI/PianoRollPanelView.swift",
    "UI/PresetPickerView.swift",
    "UI/SheetMusicPanelView.swift",
    
    # Additional files
    "MidiInfo.swift",
    
    # Tests
    "SlonimskyTests/PatternGeneratorTests.swift",
    "SlonimskyTests/MIDIIntegrationTests.swift",
    "SlonimskyTests/MIDIFileGeneratorTests.swift",
    "SlonimskyTests/NoteSequenceGeneratorTests.swift"
]

# Generate unique IDs for each file
file_ids = {}
build_file_ids = {}

for file_path in all_files:
    # Generate a unique ID (similar to Xcode's format)
    file_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
    build_file_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    file_ids[file_path] = file_id
    build_file_ids[file_path] = build_file_id

# Read the project file
with open('Slonimsky.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Add file references to PBXFileReference section
file_references = []
for file_path, file_id in file_ids.items():
    file_name = file_path.split('/')[-1]
    file_references.append(f'\t\t{file_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};')

# Find the end of PBXFileReference section
file_ref_end = content.find('/* End PBXFileReference section */')
if file_ref_end != -1:
    # Insert file references before the end
    new_file_refs = '\n\t\t' + '\n\t\t'.join(file_references) + '\n\t\t'
    content = content[:file_ref_end] + new_file_refs + content[file_ref_end:]

# Add build file references to PBXBuildFile section
build_files = []
for file_path, build_file_id in build_file_ids.items():
    file_name = file_path.split('/')[-1]
    file_id = file_ids[file_path]
    
    # Determine if it's a test file
    if file_path.startswith('SlonimskyTests/'):
        build_files.append(f'\t\t{build_file_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {file_name} */; }};')
    else:
        build_files.append(f'\t\t{build_file_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {file_name} */; }};')

# Find the end of PBXBuildFile section
build_file_end = content.find('/* End PBXBuildFile section */')
if build_file_end != -1:
    # Insert build file references before the end
    new_build_files = '\n\t\t' + '\n\t\t'.join(build_files) + '\n\t\t'
    content = content[:build_file_end] + new_build_files + content[build_file_end:]

# Add files to the main Slonimsky group
slonimsky_group_start = content.find('98692B2B2E2FBE0200223430 /* Slonimsky */ = {')
if slonimsky_group_start != -1:
    # Find the children array
    children_start = content.find('children = (', slonimsky_group_start)
    if children_start != -1:
        # Find the closing parenthesis of children
        children_end = content.find(');', children_start)
        if children_end != -1:
            # Add non-test files to children
            ui_children = []
            for file_path in all_files:
                if not file_path.startswith('SlonimskyTests/'):
                    file_id = file_ids[file_path]
                    file_name = file_path.split('/')[-1]
                    ui_children.append(f'\t\t\t\t{file_id} /* {file_name} */')
            
            new_children = '\n\t\t\t\t' + ',\n\t\t\t\t'.join(ui_children) + ',\n\t\t\t\t'
            content = content[:children_end] + new_children + content[children_end:]

# Add test files to the SlonimskyTests group
tests_group_start = content.find('98692B3D2E2FBE0F00223430 /* SlonimskyTests */ = {')
if tests_group_start != -1:
    # Find the children array
    children_start = content.find('children = (', tests_group_start)
    if children_start != -1:
        # Find the closing parenthesis of children
        children_end = content.find(');', children_start)
        if children_end != -1:
            # Add test files to children
            test_children = []
            for file_path in all_files:
                if file_path.startswith('SlonimskyTests/'):
                    file_id = file_ids[file_path]
                    file_name = file_path.split('/')[-1]
                    test_children.append(f'\t\t\t\t{file_id} /* {file_name} */')
            
            if test_children:
                new_children = ',\n\t\t\t\t' + ',\n\t\t\t\t'.join(test_children) + '\n\t\t\t\t'
                content = content[:children_end] + new_children + content[children_end:]

# Add files to the Sources build phase
sources_phase_start = content.find('98692B252E2FBE0200223430 /* Sources */ = {')
if sources_phase_start != -1:
    # Find the files array in the sources phase
    files_start = content.find('files = (', sources_phase_start)
    if files_start != -1:
        # Find the closing parenthesis of files
        files_end = content.find(');', files_start)
        if files_end != -1:
            # Add non-test build files to sources
            ui_build_files = []
            for file_path in all_files:
                if not file_path.startswith('SlonimskyTests/'):
                    build_file_id = build_file_ids[file_path]
                    file_name = file_path.split('/')[-1]
                    ui_build_files.append(f'\t\t\t\t{build_file_id} /* {file_name} in Sources */')
            
            new_build_files = ',\n\t\t\t\t' + ',\n\t\t\t\t'.join(ui_build_files) + ',\n\t\t\t\t'
            content = content[:files_end] + new_build_files + content[files_end:]

# Add test files to the Tests Sources build phase
tests_sources_phase_start = content.find('98692B362E2FBE0F00223430 /* Sources */ = {')
if tests_sources_phase_start != -1:
    # Find the files array in the tests sources phase
    files_start = content.find('files = (', tests_sources_phase_start)
    if files_start != -1:
        # Find the closing parenthesis of files
        files_end = content.find(');', files_start)
        if files_end != -1:
            # Add test build files to sources
            test_build_files = []
            for file_path in all_files:
                if file_path.startswith('SlonimskyTests/'):
                    build_file_id = build_file_ids[file_path]
                    file_name = file_path.split('/')[-1]
                    test_build_files.append(f'\t\t\t\t{build_file_id} /* {file_name} in Sources */')
            
            if test_build_files:
                new_build_files = ',\n\t\t\t\t' + ',\n\t\t\t\t'.join(test_build_files) + ',\n\t\t\t\t'
                content = content[:files_end] + new_build_files + content[files_end:]

# Write the updated project file
with open('Slonimsky.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ All files added to Xcode project successfully!")
print("\nAdded files:")
for file_path in all_files:
    print(f"  - {file_path}") 