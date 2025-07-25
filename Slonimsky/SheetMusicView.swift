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

    var body: some View {
        VStack {
            if let doc = viewModel.pdfDocument {
                PDFKitView(document: doc)
                    .frame(minHeight: 400)
            } else {
                Text("Generating sheet music…")
                    .italic()
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.shareItems().isEmpty)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareView(urls: viewModel.shareItems())
        }
    }
}



struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument

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
    let urls: [URL]

    func makeNSViewController(context: Context) -> NSViewController {
        let vc = NSViewController()
        let picker = NSSharingServicePicker(items: urls)
        picker.show(relativeTo: .zero, of: vc.view, preferredEdge: .minY)
        return vc
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

