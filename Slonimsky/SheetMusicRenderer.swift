import PDFKit
import AppKit



class SheetMusicRenderer {
    let pageWidth: CGFloat = 612
    let pageHeight: CGFloat = 792
    let margin: CGFloat = 40
    let systemSpacing: CGFloat = 40
    let staffSpacing: CGFloat = 20
    let staffLineSpacing: CGFloat = 6
    let clefGap: CGFloat = 20
    let minNoteSpacing: CGFloat = 20
    let minStemHeight: CGFloat = 24

    struct RenderedBar {
        let notes: [MIDIInfo]
        let width: CGFloat
    }

    struct TimeSignature {
        let beatsPerBar: Int
        let beatValue: Int
    }

    let timeSignature = TimeSignature(beatsPerBar: 4, beatValue: 4)

    func renderBlankScore(from melody: [MIDIInfo]) -> PDFDocument {
        let bars = splitIntoBars(melody, timeSignature: timeSignature)
        let systems = layoutSystems(from: bars)
        let pages = paginateSystems(systems)

        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return PDFDocument() }
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return PDFDocument() }

        for systemsOnPage in pages {
            context.beginPDFPage(nil)
            context.saveGState()
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

    private func splitIntoBars(_ melody: [MIDIInfo], timeSignature: TimeSignature) -> [[MIDIInfo]] {
        var result: [[MIDIInfo]] = []
        var currentBar: [MIDIInfo] = []
        var currentSum = 0.0
        let barLength = Double(timeSignature.beatsPerBar)

        for note in melody {
            currentSum += note.beatLength
            currentBar.append(note)
            if currentSum >= barLength {
                result.append(currentBar)
                currentBar = []
                currentSum = 0.0
            }
        }

        if !currentBar.isEmpty {
            result.append(currentBar)
        }

        return result
    }

    private func layoutSystems(from bars: [[MIDIInfo]]) -> [[[MIDIInfo]]] {
        var systems: [[[MIDIInfo]]] = []
        var currentSystem: [[MIDIInfo]] = []
        var currentWidth: CGFloat = 0
        let availableWidth = pageWidth - 2 * margin - 30

        for bar in bars {
            let width = max(CGFloat(bar.count) * minNoteSpacing, 60)
            if currentWidth + width > availableWidth {
                systems.append(currentSystem)
                currentSystem = []
                currentWidth = 0
            }
            currentSystem.append(bar)
            currentWidth += width
        }

        if !currentSystem.isEmpty {
            systems.append(currentSystem)
        }

        return systems
    }

    private func paginateSystems(_ systems: [[[MIDIInfo]]]) -> [[[[MIDIInfo]]]] {
        let systemHeight = totalSystemHeight() + systemSpacing
        let availableHeight = pageHeight - 2 * margin
        let maxSystemsPerPage = Int(availableHeight / systemHeight)

        var pages: [[[[MIDIInfo]]]] = []
        var currentPage: [[[MIDIInfo]]] = []

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

    private func drawSystem(at topY: CGFloat, bars: [[MIDIInfo]], context ctx: CGContext) {
        var x = margin
        drawClefs(at: topY, x: x, context: ctx)
        x += 30

        let totalWidth = pageWidth - 2 * margin - 30
        let barWidth = totalWidth / CGFloat(bars.count)

        for bar in bars {
            drawBar(x: x, topY: topY, width: barWidth, notes: bar, context: ctx)
            x += barWidth
        }
    }

    private func drawBar(x: CGFloat, topY: CGFloat, width: CGFloat, notes: [MIDIInfo], context ctx: CGContext) {
        let trebleTop = topY
        let bassTop = topY + staffSpacing + 4 * staffLineSpacing + clefGap

        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.0)

        for i in 0..<5 {
            let yTreble = trebleTop + CGFloat(i) * staffLineSpacing
            let yBass = bassTop + CGFloat(i) * staffLineSpacing
            ctx.move(to: CGPoint(x: x, y: yTreble))
            ctx.addLine(to: CGPoint(x: x + width, y: yTreble))
            ctx.move(to: CGPoint(x: x, y: yBass))
            ctx.addLine(to: CGPoint(x: x + width, y: yBass))
        }

        ctx.move(to: CGPoint(x: x, y: trebleTop))
        ctx.addLine(to: CGPoint(x: x, y: bassTop + 4 * staffLineSpacing))
        ctx.move(to: CGPoint(x: x + width, y: trebleTop))
        ctx.addLine(to: CGPoint(x: x + width, y: bassTop + 4 * staffLineSpacing))
        ctx.strokePath()

        // Notes
        let totalBeats = notes.reduce(0.0) { $0 + $1.beatLength }
        let beatUnit = (width - 20) / CGFloat(totalBeats)
        var currentBeat: CGFloat = 0
        var notePositions: [(CGPoint, MIDIInfo)] = []

        for note in notes {
            let noteX = x + 10 + CGFloat(currentBeat) * beatUnit
            let y = yForMIDINote(note.note, topY: trebleTop)
            let pt = CGPoint(x: noteX, y: y)

            drawNoteHead(at: pt, duration: note.beatLength, context: ctx)
            drawLedgerLinesIfNeeded(for: note.note, atX: noteX, topY: trebleTop, context: ctx)
            notePositions.append((pt, note))
            currentBeat += CGFloat(note.beatLength)
        }

        drawStemsAndBeams(for: notePositions, in: ctx, topY: trebleTop)
    }

    private func drawNoteHead(at point: CGPoint, duration: Double, context ctx: CGContext) {
        let noteSize = CGSize(width: 8, height: 6)
        let rect = CGRect(origin: CGPoint(x: point.x - noteSize.width / 2, y: point.y - noteSize.height / 2), size: noteSize)

        switch duration {
        case 1.0:
            ctx.strokeEllipse(in: rect)
        case 2.0...:
            ctx.strokeEllipse(in: rect)
        default:
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillEllipse(in: rect)
        }
    }

    private func drawStemsAndBeams(for notes: [(CGPoint, MIDIInfo)], in ctx: CGContext, topY: CGFloat) {
        var beamGroup: [(CGPoint, MIDIInfo)] = []

        for (index, (pt, note)) in notes.enumerated() {
            if note.beatLength <= 0.5 {
                beamGroup.append((pt, note))
            }

            let isLast = index == notes.count - 1
            let nextLong = isLast || notes[index + 1].1.beatLength > 0.5
            if !beamGroup.isEmpty && (beamGroup.count == 4 || nextLong) {
                drawBeam(for: beamGroup, in: ctx)
                beamGroup.removeAll()
            }

            if note.beatLength > 0.5 {
                let up = shouldStemGoUp(for: pt, topY: topY)
                drawStem(at: pt, up: up, height: stemHeight(for: pt, up: up, topY: topY), in: ctx)
            }
        }
    }

    private func drawStem(at point: CGPoint, up: Bool, height: CGFloat, in ctx: CGContext) {
        let x = point.x + (up ? 3 : -3)
        let y1 = point.y
        let y2 = up ? y1 - height : y1 + height

        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.0)
        ctx.move(to: CGPoint(x: x, y: y1))
        ctx.addLine(to: CGPoint(x: x, y: y2))
        ctx.strokePath()
    }

    private func stemHeight(for pt: CGPoint, up: Bool, topY: CGFloat) -> CGFloat {
        let middleLineY = yForMIDINote(64, topY: topY)
        let distance = abs(pt.y - middleLineY)
        return max(minStemHeight, distance)
    }

    private func drawBeam(for notes: [(CGPoint, MIDIInfo)], in ctx: CGContext) {
        guard notes.count >= 2 else { return }

        let first = notes.first!.0
        let last = notes.last!.0
        let dy = last.y - first.y
        let dx = last.x - first.x
        let slope = dy / dx
        let beamWidth: CGFloat = 5
        let yOffset: CGFloat = -20

        let p1 = CGPoint(x: first.x + 3, y: first.y + yOffset)
        let p2 = CGPoint(x: last.x + 3, y: last.y + yOffset)

        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(beamWidth)
        ctx.setLineCap(.butt)
        ctx.move(to: p1)
        ctx.addLine(to: p2)
        ctx.strokePath()

        for (pt, _) in notes {
            let beamY = p1.y + slope * (pt.x - p1.x)
            let height = pt.y - beamY
            drawStem(at: pt, up: true, height: height, in: ctx)
        }
    }

    private func shouldStemGoUp(for pt: CGPoint, topY: CGFloat) -> Bool {
        let middleLineY = yForMIDINote(64, topY: topY)
        return pt.y > middleLineY
    }

    private func drawLedgerLinesIfNeeded(for midiNote: Int, atX x: CGFloat, topY: CGFloat, context ctx: CGContext) {
        let lineSpacing = staffLineSpacing
        let middleCLineY = yForMIDINote(60, topY: topY)
        let noteY = yForMIDINote(midiNote, topY: topY)

        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.0)

        for y in stride(from: noteY, through: middleCLineY, by: lineSpacing * (noteY < middleCLineY ? 1 : -1)) {
            if abs(y - middleCLineY) >= staffLineSpacing {
                ctx.move(to: CGPoint(x: x - 6, y: y))
                ctx.addLine(to: CGPoint(x: x + 6, y: y))
            }
        }

        ctx.strokePath()
    }

    private func drawClefs(at topY: CGFloat, x: CGFloat, context ctx: CGContext) {
        let trebleClefSymbol = "𝄞"
        let bassClefSymbol = "𝄢"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Arial Unicode MS", size: 28) ?? NSFont.systemFont(ofSize: 28),
            .foregroundColor: NSColor.black
        ]
        trebleClefSymbol.draw(at: CGPoint(x: x, y: topY + 3), withAttributes: attributes)
        bassClefSymbol.draw(at: CGPoint(x: x, y: topY + staffSpacing + 4 * staffLineSpacing + clefGap + 3), withAttributes: attributes)
    }

    private func yForMIDINote(_ note: Int, topY: CGFloat) -> CGFloat {
        let staffMiddleNote = 60
        let stepsFromMiddleC = note - staffMiddleNote
        let stepHeight: CGFloat = staffLineSpacing / 2
        return topY + 5 * staffLineSpacing - CGFloat(stepsFromMiddleC) * stepHeight
    }
}

