#!/usr/bin/env python3

import re
import uuid

# UI files to add
ui_files = [
    "UI/MainContentView.swift",
    "UI/ParameterManager.swift", 
    "UI/ParameterPanelView.swift",
    "UI/PianoRollPanelView.swift",
    "UI/SheetMusicPanelView.swift",
    "UI/PresetPickerView.swift"
]

# Generate unique IDs for each file
file_ids = {}
build_file_ids = {}

for file_path in ui_files:
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
            # Add UI files to children
            ui_children = []
            for file_path in ui_files:
                file_id = file_ids[file_path]
                file_name = file_path.split('/')[-1]
                ui_children.append(f'\t\t\t\t{file_id} /* {file_name} */')
            
            new_children = '\n\t\t\t\t' + ',\n\t\t\t\t'.join(ui_children) + ',\n\t\t\t\t'
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
            # Add UI build files to sources
            ui_build_files = []
            for file_path in ui_files:
                build_file_id = build_file_ids[file_path]
                file_name = file_path.split('/')[-1]
                ui_build_files.append(f'\t\t\t\t{build_file_id} /* {file_name} in Sources */')
            
            new_build_files = ',\n\t\t\t\t' + ',\n\t\t\t\t'.join(ui_build_files) + ',\n\t\t\t\t'
            content = content[:files_end] + new_build_files + content[files_end:]

# Write the updated project file
with open('Slonimsky.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ UI files added to Xcode project successfully!")
print("\nAdded files:")
for file_path in ui_files:
    print(f"  - {file_path}") 