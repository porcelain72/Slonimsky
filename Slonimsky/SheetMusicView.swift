//
//  SheetMusicView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 25/07/2025.
//

import SwiftUI
import PDFKit

struct SheetMusicView: View {
    @ObservedObject var viewModel: SheetMusicViewModel
    @State private var showShareSheet = false
    @State private var shareURL : URL? = nil
    
    var body: some View {
        VStack {
            if let doc = viewModel.pdfDocument {
                PDFKitView(document: Binding(get: {
                    doc
                }, set: { _ in
                    
                }))
                    .frame(minHeight: 400)
            } else {
                Text("Generating sheet music…")
                    .italic()
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    share()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.shareItems().isEmpty)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = self.shareURL{
                ShareView(url: url)
            }
        }
    }
    
    private func share(){
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        if let data = viewModel.shareItems().first{
            do{
                try data.write(to: tempURL)
                shareURL = tempURL
                showShareSheet = true
            } catch {
                
            }
        }
    }
}



struct PDFKitView: NSViewRepresentable {
    @Binding var document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
    }
}


struct ShareView: NSViewControllerRepresentable {
    let url: URL
    //let data: Data
    func makeNSViewController(context: Context) -> NSViewController {
        let vc = NSViewController()
        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: .zero, of: vc.view, preferredEdge: .minY)
        return vc
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

