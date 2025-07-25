import PDFKit
import AppKit

class SheetMusicRenderer {
    let pageWidth: CGFloat = 612
    let pageHeight: CGFloat = 792
    let margin: CGFloat = 40
    let systemSpacing: CGFloat = 60
    let staffSpacing: CGFloat = 50
    let staffLineSpacing: CGFloat = 10
    let clefGap: CGFloat = 20

    let baseBarWidth: CGFloat = 100
    let maxBarWidth: CGFloat = 180
    let minBarWidth: CGFloat = 60
    let notePerUnit: CGFloat = 4.0

    struct RenderedBar {
        let notes: [MIDIInfo]
        let width: CGFloat
    }

    func renderBlankScore(from melody: [MIDIInfo]) -> PDFDocument {
        let bars = melody.chunked(into: 4)
        let renderedBars = bars.map { RenderedBar(notes: $0, width: widthForBar(noteCount: $0.count)) }
        let systems = layoutSystems(from: renderedBars)
        let pages = paginateSystems(systems)

        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return PDFDocument() }
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return PDFDocument() }

        for systemsOnPage in pages {
            context.beginPDFPage(nil)
            context.saveGState()

            // Flip coordinates for macOS rendering
            context.translateBy(x: 0, y: pageHeight)
            context.scaleBy(x: 1.0, y: -1.0)

            var y = margin
            for system in systemsOnPage {
                drawSystem(at: y, bars: system, context: context)
                y += totalSystemHeight() + systemSpacing
            }

            context.restoreGState()
            context.endPDFPage()
        }

        context.closePDF()
        return PDFDocument(data: pdfData as Data) ?? PDFDocument()
    }

    // MARK: - Layout

    private func widthForBar(noteCount: Int) -> CGFloat {
        let scale = CGFloat(noteCount) / notePerUnit
        return max(minBarWidth, min(baseBarWidth * scale, maxBarWidth))
    }

    private func layoutSystems(from bars: [RenderedBar]) -> [[RenderedBar]] {
        var systems: [[RenderedBar]] = []
        var currentSystem: [RenderedBar] = []
        var currentWidth: CGFloat = 0
        let availableWidth = pageWidth - 2 * margin - 30

        for bar in bars {
            if currentWidth + bar.width > availableWidth {
                systems.append(currentSystem)
                currentSystem = []
                currentWidth = 0
            }
            currentSystem.append(bar)
            currentWidth += bar.width
        }

        if !currentSystem.isEmpty {
            systems.append(currentSystem)
        }

        return systems
    }

    private func paginateSystems(_ systems: [[RenderedBar]]) -> [[[RenderedBar]]] {
        let systemHeight = totalSystemHeight() + systemSpacing
        let availableHeight = pageHeight - 2 * margin
        let maxSystemsPerPage = Int(availableHeight / systemHeight)

        var pages: [[[RenderedBar]]] = []
        var currentPage: [[RenderedBar]] = []

        for system in systems {
            if currentPage.count >= maxSystemsPerPage {
                pages.append(currentPage)
                currentPage = []
            }
            currentPage.append(system)
        }

        if !currentPage.isEmpty {
            pages.append(currentPage)
        }

        return pages
    }

    private func totalSystemHeight() -> CGFloat {
        return 2 * staffSpacing + 4 * staffLineSpacing + clefGap
    }

    // MARK: - Drawing

    private func drawSystem(at topY: CGFloat, bars: [RenderedBar], context ctx: CGContext) {
        var x = margin
        drawClefs(at: topY, x: x, context: ctx)
        x += 30

        for bar in bars {
            drawBar(x: x, topY: topY, width: bar.width, notes: bar.notes, context: ctx)
            x += bar.width
        }
    }

    private func drawBar(x: CGFloat, topY: CGFloat, width: CGFloat, notes: [MIDIInfo], context ctx: CGContext) {
        let trebleTop = topY
        let bassTop = topY + staffSpacing + 4 * staffLineSpacing + clefGap

        ctx.setStrokeColor(NSColor.black.cgColor)

        for i in 0..<5 {
            let yTreble = trebleTop + CGFloat(i) * staffLineSpacing
            let yBass = bassTop + CGFloat(i) * staffLineSpacing

            ctx.move(to: CGPoint(x: x, y: yTreble))
            ctx.addLine(to: CGPoint(x: x + width, y: yTreble))
            ctx.move(to: CGPoint(x: x, y: yBass))
            ctx.addLine(to: CGPoint(x: x + width, y: yBass))
        }

        // Bar lines
        ctx.move(to: CGPoint(x: x, y: trebleTop))
        ctx.addLine(to: CGPoint(x: x, y: bassTop + 4 * staffLineSpacing))
        ctx.move(to: CGPoint(x: x + width, y: trebleTop))
        ctx.addLine(to: CGPoint(x: x + width, y: bassTop + 4 * staffLineSpacing))

        ctx.strokePath()

        // Draw notes + stems + beams
        let noteSpacing = width / CGFloat(max(1, notes.count))
        var notePoints: [(CGPoint, Bool)] = []

        var noteX = x + noteSpacing / 2

        for note in notes {
            let y = yForMIDINote(note.note, topY: trebleTop)
            let point = CGPoint(x: noteX, y: y)
            drawNoteHead(at: point, context: ctx)

            let isUp = note.note < 71
            drawStem(for: point, isUp: isUp, context: ctx)

            notePoints.append((point, isUp))
            noteX += noteSpacing
        }

        // Beam all notes together if same direction (basic logic)
        if notePoints.count >= 2 {
            let isUp = notePoints[0].1
            let sameDirection = notePoints.allSatisfy { $0.1 == isUp }

            if sameDirection {
                for i in 0..<(notePoints.count - 1) {
                    drawBeam(from: notePoints[i].0, to: notePoints[i+1].0, y: notePoints[i].0.y, isUp: isUp, context: ctx)
                }
            }
        }
    }
    private func drawStem(for note: CGPoint, isUp: Bool, context ctx: CGContext) {
        let length: CGFloat = 25
        let stemX = isUp ? note.x + 3.5 : note.x - 3.5
        let stemStart = CGPoint(x: stemX, y: note.y)
        let stemEnd = CGPoint(x: stemX, y: isUp ? note.y + length : note.y - length)
        ctx.move(to: stemStart)
        ctx.addLine(to: stemEnd)
        ctx.strokePath()
    }

    private func drawBeam(from start: CGPoint, to end: CGPoint, y: CGFloat, isUp: Bool, context ctx: CGContext) {
        let beamHeight: CGFloat = 3
        let yOffset = isUp ? 25 : -25
        let beamY = y + CGFloat(yOffset)
        let rect = CGRect(x: start.x, y: beamY, width: end.x - start.x, height: beamHeight * (isUp ? 1 : -1))

        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fill(rect)
    }


    private func drawNoteHead(at point: CGPoint, context ctx: CGContext) {
        let noteSize = CGSize(width: 8, height: 6)
        let rect = CGRect(origin: CGPoint(x: point.x - noteSize.width / 2, y: point.y - noteSize.height / 2), size: noteSize)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillEllipse(in: rect)
    }

    private func drawLedgerLinesIfNeeded(for midiNote: Int, atX x: CGFloat, topY: CGFloat, context ctx: CGContext) {
        let lineSpacing = staffLineSpacing
        let middleCLineY = topY + 5 * lineSpacing
        let noteY = yForMIDINote(midiNote, topY: topY)

        let linesAbove = max(0, Int((middleCLineY - noteY) / (lineSpacing / 2)) - 8)
        let linesBelow = max(0, Int((noteY - middleCLineY) / (lineSpacing / 2)) - 8)

        ctx.setStrokeColor(NSColor.black.cgColor)

        for i in 0..<linesAbove {
            let y = middleCLineY - CGFloat(i + 1) * lineSpacing
            ctx.move(to: CGPoint(x: x - 6, y: y))
            ctx.addLine(to: CGPoint(x: x + 6, y: y))
        }

        for i in 0..<linesBelow {
            let y = middleCLineY + CGFloat(i + 1) * lineSpacing
            ctx.move(to: CGPoint(x: x - 6, y: y))
            ctx.addLine(to: CGPoint(x: x + 6, y: y))
        }

        ctx.strokePath()
    }

    private func drawClefs(at topY: CGFloat, x: CGFloat, context ctx: CGContext) {
        let trebleClefSymbol = "𝄞"
        let bassClefSymbol = "𝄢"

        let treblePoint = CGPoint(x: x, y: topY + 3)
        let bassPoint = CGPoint(x: x, y: topY + staffSpacing + 4 * staffLineSpacing + clefGap + 3)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Arial Unicode MS", size: 28) ?? NSFont.systemFont(ofSize: 28),
            .foregroundColor: NSColor.black
        ]

        trebleClefSymbol.draw(at: treblePoint, withAttributes: attributes)
        bassClefSymbol.draw(at: bassPoint, withAttributes: attributes)
    }

    private func yForMIDINote(_ note: Int, topY: CGFloat) -> CGFloat {
        let staffMiddleNote = 60 // Middle C
        let stepsFromMiddleC = note - staffMiddleNote
        let stepHeight: CGFloat = staffLineSpacing / 2
        return topY + 5 * staffLineSpacing - CGFloat(stepsFromMiddleC) * stepHeight
    }
}

// MARK: - Array Helpers

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
