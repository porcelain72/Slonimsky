//
//  SheetMusicPanelView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Sheet music panel view for displaying patterns as notation
struct SheetMusicPanelView: View {
    
    // MARK: - Properties
    @ObservedObject var sheetMusicVM: SheetMusicViewModel
    @ObservedObject var midiService: MIDIIntegrationService
    
    // MARK: - State
    @State private var zoomLevel: Double = 1.0
    @State private var showExportOptions = false
    @State private var showPrintDialog = false
    @State private var selectedExportFormat: ExportFormat = .pdf
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetMusicHeader
            
            // Sheet Music Content
            sheetMusicContent
            
            // Footer Controls
            sheetMusicFooter
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(
                selectedFormat: $selectedExportFormat,
                onExport: exportSheetMusic
            )
        }
    }
    
    // MARK: - Header
    
    private var sheetMusicHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "music.note.list")
                    .font(.title2)
                Text("Sheet Music")
                    .font(.headline)
                Spacer()
                
                // Zoom Controls
                HStack(spacing: 8) {
                    Button(action: zoomOut) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .disabled(zoomLevel <= 0.5)
                    
                    Text("\(Int(zoomLevel * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 50)
                    
                    Button(action: zoomIn) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .disabled(zoomLevel >= 3.0)
                }
            }
            
            // Pattern Info
            if let pattern = midiService.currentPattern {
                HStack {
                    Text("Pattern: \(pattern.metadata.generatorName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(pattern.notes.count) notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Duration: \(formatTime(pattern.metadata.duration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Text("No pattern generated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            Divider()
        }
        .padding()
    }
    
    // MARK: - Sheet Music Content
    
    private var sheetMusicContent: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack {
                if let pattern = midiService.currentPattern {
                    // Update sheet music view model with current pattern
                    let _ = updateSheetMusic(with: pattern)
                    
                    // Display sheet music using existing view
                    SheetMusicView(viewModel: sheetMusicVM)
                        .scaleEffect(zoomLevel)
                        .frame(
                            minWidth: 400 * zoomLevel,
                            minHeight: 600 * zoomLevel
                        )
                } else {
                    // Placeholder when no pattern is available
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("No Pattern Generated")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Generate a pattern to see sheet music notation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Footer
    
    private var sheetMusicFooter: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                // Export Controls
                Button("Export") {
                    showExportOptions = true
                }
                .buttonStyle(.bordered)
                .disabled(midiService.currentPattern == nil)
                
                Button("Print") {
                    showPrintDialog = true
                }
                .buttonStyle(.bordered)
                .disabled(midiService.currentPattern == nil)
                
                Spacer()
                
                // Page Controls
                if sheetMusicVM.hasMultiplePages {
                    HStack(spacing: 8) {
                        Button(action: previousPage) {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.bordered)
                        .disabled(sheetMusicVM.currentPage <= 1)
                        
                        Text("\(sheetMusicVM.currentPage) of \(sheetMusicVM.totalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: nextPage) {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.bordered)
                        .disabled(sheetMusicVM.currentPage >= sheetMusicVM.totalPages)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomLevel = min(zoomLevel * 1.2, 3.0)
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomLevel = max(zoomLevel / 1.2, 0.5)
        }
    }
    
    private func previousPage() {
        if sheetMusicVM.currentPage > 1 {
            sheetMusicVM.currentPage -= 1
        }
    }
    
    private func nextPage() {
        if sheetMusicVM.currentPage < sheetMusicVM.totalPages {
            sheetMusicVM.currentPage += 1
        }
    }
    
    private func updateSheetMusic(with pattern: PatternGenerationResult) {
        // Convert pattern to format expected by SheetMusicViewModel
        // This will be implemented when we integrate with Salieri
        print("📝 Updating sheet music with \(pattern.notes.count) notes")
        
        // For now, just update the view model with basic info
        sheetMusicVM.updateFromPattern(pattern)
    }
    
    private func exportSheetMusic() {
        let panel = NSSavePanel()
        
        switch selectedExportFormat {
        case .pdf:
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "slonimsky_pattern.pdf"
        case .musicXML:
            panel.allowedContentTypes = [.xml]
            panel.nameFieldStringValue = "slonimsky_pattern.musicxml"
        case .midi:
            panel.allowedContentTypes = [.midi]
            panel.nameFieldStringValue = "slonimsky_pattern.mid"
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                exportToFile(url: url, format: selectedExportFormat)
            }
        }
    }
    
    private func exportToFile(url: URL, format: ExportFormat) {
        switch format {
        case .pdf:
            exportToPDF(url: url)
        case .musicXML:
            exportToMusicXML(url: url)
        case .midi:
            exportToMIDI(url: url)
        }
    }
    
    private func exportToPDF(url: URL) {
        // This will be implemented when we integrate with Salieri
        print("📄 Exporting to PDF: \(url.path)")
    }
    
    private func exportToMusicXML(url: URL) {
        // This will be implemented when we integrate with Salieri
        print("🎵 Exporting to MusicXML: \(url.path)")
    }
    
    private func exportToMIDI(url: URL) {
        let success = midiService.exportToMIDI(url: url)
        if success {
            print("✅ MIDI exported successfully")
        } else {
            print("❌ MIDI export failed")
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct ExportOptionsView: View {
    @Binding var selectedFormat: ExportFormat
    let onExport: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Sheet Music")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            selectedFormat = format
                        }) {
                            HStack {
                                Image(systemName: format.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(format.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedFormat == format ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Export") {
                        onExport()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Export Options")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case musicXML = "MusicXML"
    case midi = "MIDI"
    
    var name: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .pdf:
            return "High-quality sheet music for printing"
        case .musicXML:
            return "Standard music notation format"
        case .midi:
            return "MIDI file for playback and editing"
        }
    }
    
    var icon: String {
        switch self {
        case .pdf:
            return "doc.text"
        case .musicXML:
            return "music.note"
        case .midi:
            return "music.note.list"
        }
    }
}

// MARK: - SheetMusicViewModel Extension

extension SheetMusicViewModel {
    var hasMultiplePages: Bool {
        return totalPages > 1
    }
    
    var totalPages: Int {
        // This will be implemented when we integrate with Salieri
        return 1
    }
    
    var currentPage: Int {
        get { 1 } // Placeholder
        set { } // Placeholder
    }
    
    func updateFromPattern(_ pattern: PatternGenerationResult) {
        // This will be implemented when we integrate with Salieri
        print("📝 SheetMusicViewModel updated with pattern: \(pattern.notes.count) notes")
    }
}

// MARK: - Preview

struct SheetMusicPanelView_Previews: PreviewProvider {
    static var previews: some View {
        SheetMusicPanelView(
            sheetMusicVM: SheetMusicViewModel(),
            midiService: MIDIIntegrationService()
        )
        .frame(width: 600, height: 800)
    }
} 