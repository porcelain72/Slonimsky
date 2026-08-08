//
//  SheetMusicPopupView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI
import PDFKit

/// Sheet music popup view displayed in a modal window
struct SheetMusicPopupView: View {
    
    // MARK: - Properties
    @ObservedObject var midiService: MIDIIntegrationService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var zoomLevel: Double = 1.0
    @State private var pdfDocument: PDFDocument?
    @State private var renderError: String?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                sheetMusicHeader
                sheetMusicContent
                sheetMusicFooter
            }
            .background(Color.garageBandBackground)
            .navigationTitle("Sheet Music")
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    HStack(spacing: 8) {
                        Button(action: zoomOut) {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .disabled(zoomLevel <= 0.5)
                        
                        Text("\(Int(zoomLevel * 100))%")
                            .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                            .frame(minWidth: 50)
                        
                        Button(action: zoomIn) {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .disabled(zoomLevel >= 3.0)
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear(perform: renderPDF)
        .onChange(of: midiService.currentPattern?.notes.count) { _ in
            renderPDF()
        }
    }
    
    // MARK: - Header
    
    private var sheetMusicHeader: some View {
        VStack(spacing: 12) {
            if let pattern = midiService.currentPattern {
                VStack(spacing: 8) {
                    HStack {
                        Text("Pattern: \(pattern.metadata.generatorName)")
                            .font(.headline)
                            .foregroundColor(Color.garageBandText)
                        
                        Spacer()
                        
                        Text("Generated in \(String(format: "%.3f", pattern.performance.generationTime))s")
                            .font(.caption)
                            .foregroundColor(Color.garageBandSecondary)
                    }
                    
                    HStack {
                        Label("\(pattern.notes.count) notes", systemImage: "music.note")
                            .font(.subheadline)
                            .foregroundColor(Color.garageBandSecondary)
                        
                        Spacer()
                        
                        Label("Duration: \(formatTime(pattern.metadata.duration))", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(Color.garageBandSecondary)
                        
                        Spacer()
                        
                        Label("Range: \(pattern.metadata.pitchRange.lowerBound)-\(pattern.metadata.pitchRange.upperBound)", systemImage: "arrow.up.and.down")
                            .font(.subheadline)
                            .foregroundColor(Color.garageBandSecondary)
                    }
                }
                .padding()
                .background(Color.garageBandPanel)
                .cornerRadius(8)
            } else {
                HStack {
                    Text("No pattern available")
                        .font(.subheadline)
                        .foregroundColor(Color.garageBandSecondary)
                    Spacer()
                }
                .padding()
                .background(Color.garageBandPanel)
                .cornerRadius(8)
            }
            
            Divider()
        }
        .padding()
    }
    
    // MARK: - Content
    
    private var sheetMusicContent: some View {
        Group {
            if let pdfDocument {
                SheetMusicPDFView(document: pdfDocument, zoomLevel: zoomLevel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let renderError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(Color.garageBandSecondary)
                    Text(renderError)
                        .font(.body)
                        .foregroundColor(Color.garageBandSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Rendering sheet music…")
                        .font(.body)
                        .foregroundColor(Color.garageBandSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Footer
    
    private var sheetMusicFooter: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Button("Export MIDI") {
                    exportMIDI()
                }
                .buttonStyle(.bordered)
                .disabled(midiService.currentPattern == nil)
                
                Button("Export PDF") {
                    exportPDF()
                }
                .buttonStyle(.bordered)
                .disabled(pdfDocument == nil)
                
                Button("Print") {
                    printSheetMusic()
                }
                .buttonStyle(.bordered)
                .disabled(pdfDocument == nil)
                
                Spacer()
                
                Text(pdfDocument == nil ? "Sheet Music View" : "PDF ready")
                    .font(.caption)
                    .foregroundColor(Color.garageBandSecondary)
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func renderPDF() {
        renderError = nil
        guard midiService.currentPattern != nil else {
            pdfDocument = nil
            renderError = "Generate a pattern to view sheet music"
            return
        }
        if let pdf = midiService.renderSheetMusicPDF() {
            pdfDocument = pdf
        } else {
            pdfDocument = nil
            renderError = midiService.errorMessage ?? "Failed to render sheet music PDF"
        }
    }
    
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
    
    private func exportMIDI() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.midi]
        panel.nameFieldStringValue = "slonimsky_sheet_music.mid"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                _ = midiService.exportToMIDI(url: url)
            }
        }
    }
    
    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "slonimsky_sheet_music.pdf"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let document = pdfDocument {
                    _ = document.write(to: url)
                } else {
                    _ = midiService.exportSheetMusicPDF(url: url)
                }
            }
        }
    }
    
    private func printSheetMusic() {
        guard let document = pdfDocument else { return }
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        printInfo.orientation = .landscape
        
        let pdfView = PDFView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        pdfView.document = document
        pdfView.autoScales = true
        
        let operation = NSPrintOperation(view: pdfView, printInfo: printInfo)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        operation.run()
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - PDFKit bridge

private struct SheetMusicPDFView: NSViewRepresentable {
    let document: PDFDocument
    let zoomLevel: Double
    
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = false
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = document
        view.scaleFactor = zoomLevel
        return view
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document !== document {
            nsView.document = document
        }
        nsView.scaleFactor = zoomLevel
    }
}

// MARK: - Preview

struct SheetMusicPopupView_Previews: PreviewProvider {
    static var previews: some View {
        SheetMusicPopupView(
            midiService: MIDIIntegrationService()
        )
        .frame(width: 800, height: 600)
    }
}
