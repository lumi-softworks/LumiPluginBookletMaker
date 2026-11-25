import CoreGraphics
import CoreText
import Foundation

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Creates the built-in demonstration as a real PDF document.
///
/// Keeping the sample on disk means it travels through exactly the same
/// CGPDF/PDFKit preview and export pipeline as a user-selected file.
enum DemoPDFProvider {
    private static let pageSize = DemoStoryStyle.pageSize

    static func makeDocument() throws -> CurrentPDFDocument {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BookletMakerDemo", isDirectory: true)
        // Keep the version in the filename so an already-running development
        // build never reuses a demo generated with older drawing rules.
        let url = directory.appendingPathComponent("sample-story-v3.pdf")

        if !isValidDemo(at: url) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try makePDFData().write(to: url, options: .atomic)
        }

        return CurrentPDFDocument(
            source: .demo,
            url: url,
            info: PDFInspector.PDFInfo(
                pageCount: SampleStory.pageCount,
                firstPageSize: pageSize
            )
        )
    }

    private static func isValidDemo(at url: URL) -> Bool {
        guard let document = CGPDFDocument(url as CFURL),
              document.numberOfPages == SampleStory.pageCount,
              let firstPage = document.page(at: 1) else {
            return false
        }
        // The old A4 demo is still sitting in the cache directory on some
        // machines; matching the page size forces it to be regenerated.
        let bounds = firstPage.getBoxRect(.mediaBox)
        return abs(bounds.width - pageSize.width) < 1
            && abs(bounds.height - pageSize.height) < 1
    }

    private static func makePDFData() throws -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let metadata: [CFString: Any] = [
            kCGPDFContextTitle: "司马光砸缸 · BookletMaker 演示绘本" as CFString,
            kCGPDFContextAuthor: "Coffic · 快易知 Kids" as CFString,
            kCGPDFContextSubject: "经典水墨绘本演示" as CFString,
            kCGPDFContextCreator: "BookletMaker" as CFString,
        ]

        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(
            consumer: consumer,
            mediaBox: &mediaBox,
            metadata as CFDictionary
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }

        for storyPage in SampleStory.pages {
            context.beginPDFPage(nil)
            draw(storyPage, in: mediaBox, context: context)
            context.endPDFPage()
        }
        context.closePDF()
        return data as Data
    }

    // MARK: - Page composition

    private static func draw(_ page: SampleStory.Page,
                             in bounds: CGRect,
                             context: CGContext) {
        context.setFillColor(DemoStoryPalette.paper.cgColor())
        context.fill(bounds)

        drawArtwork(page, in: bounds, context: context)
        drawHairline(
            x: 0,
            length: bounds.width,
            y: DemoStoryStyle.dividerY,
            color: DemoStoryPalette.hairline.cgColor(alpha: 0.75),
            lineWidth: 0.6,
            context: context
        )

        switch page.kind {
        case .cover:
            drawCover(page, context: context)
        case .story:
            drawStoryPage(page, context: context)
        case .colophon:
            drawColophon(page, context: context)
        }
    }

    private static func drawArtwork(_ page: SampleStory.Page,
                                    in bounds: CGRect,
                                    context: CGContext) {
        let artRect = CGRect(
            x: bounds.minX,
            y: DemoStoryStyle.dividerY,
            width: bounds.width,
            height: DemoStoryStyle.artHeight
        )

        if let image = DemoStoryAssets.image(named: page.imageName) {
            drawAspectFill(image, in: artRect, context: context)
        } else {
            context.setFillColor(DemoStoryPalette.artPlaceholder.cgColor())
            context.fill(artRect)
        }

        // Let the illustration dissolve into the paper instead of ending on
        // a hard photographic edge.
        drawArtworkFade(atBottomOf: artRect, context: context)
    }

    private static func drawAspectFill(_ image: CGImage,
                                       in rect: CGRect,
                                       context: CGContext) {
        let imageSize = CGSize(width: image.width, height: image.height)
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let drawnSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        let drawnRect = CGRect(
            x: rect.midX - drawnSize.width / 2,
            y: rect.midY - drawnSize.height / 2,
            width: drawnSize.width,
            height: drawnSize.height
        )

        context.saveGState()
        context.clip(to: rect)
        context.interpolationQuality = .high
        context.draw(image, in: drawnRect)
        context.restoreGState()
    }

    private static func drawArtworkFade(atBottomOf rect: CGRect,
                                        context: CGContext) {
        let fadeHeight: CGFloat = 26
        // Solid paper at the divider, transparent 26pt up inside the image.
        let colors = [
            DemoStoryPalette.paper.cgColor(),
            DemoStoryPalette.paper.cgColor(alpha: 0),
        ] as CFArray
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0, 1]
        ) else {
            return
        }

        context.saveGState()
        context.clip(to: CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: fadeHeight
        ))
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.minY + fadeHeight),
            options: []
        )
        context.restoreGState()
    }

    // MARK: - Layouts

    private static func drawCover(_ page: SampleStory.Page,
                                  context: CGContext) {
        let centerX = pageSize.width / 2

        drawCenteredLine(
            SampleStory.coverKicker,
            centerX: centerX,
            centerY: 281,
            font: DemoStoryStyle.bodyMediumFont(size: 11),
            color: DemoStoryPalette.accent.color(),
            tracking: 2.6,
            context: context
        )
        drawCenteredLine(
            page.title,
            centerX: centerX,
            centerY: 234,
            font: DemoStoryStyle.titleFont(size: 40),
            color: DemoStoryPalette.ink.color(),
            tracking: 3,
            context: context
        )
        drawCenteredLine(
            page.body,
            centerX: centerX,
            centerY: 196,
            font: DemoStoryStyle.bodyFont(size: 13),
            color: DemoStoryPalette.bodyInk.color(),
            tracking: 0.6,
            context: context
        )
        drawHairline(
            x: centerX - 45,
            length: 90,
            y: 176,
            color: DemoStoryPalette.accent.cgColor(alpha: 0.55),
            lineWidth: 0.7,
            context: context
        )
        drawCenteredLine(
            SampleStory.coverCredit,
            centerX: centerX,
            centerY: 157,
            font: DemoStoryStyle.bodyFont(size: 9.5),
            color: DemoStoryPalette.mutedInk.color(),
            tracking: 0.8,
            context: context
        )
        drawSeal(
            "光",
            in: CGRect(x: 344, y: 208, width: 34, height: 34),
            context: context
        )
        drawCenteredLine(
            SampleStory.coverFooter,
            centerX: centerX,
            centerY: 31,
            font: DemoStoryStyle.bodyMediumFont(size: 8.5),
            color: DemoStoryPalette.accent.color(),
            tracking: 1.2,
            context: context
        )
    }

    private static func drawStoryPage(_ page: SampleStory.Page,
                                      context: CGContext) {
        let x = DemoStoryStyle.sideMargin
        drawLine(
            page.title,
            x: x,
            centerY: 276,
            font: DemoStoryStyle.titleFont(size: 22),
            color: DemoStoryPalette.ink.color(),
            tracking: 1.2,
            context: context
        )
        drawHairline(
            x: x,
            length: 26,
            y: 253,
            color: DemoStoryPalette.accent.cgColor(),
            lineWidth: 1.6,
            context: context
        )
        drawParagraph(
            page.body,
            in: CGRect(
                x: x,
                y: 50,
                width: DemoStoryStyle.contentWidth,
                height: 190
            ),
            font: DemoStoryStyle.bodyFont(size: 15.5),
            color: DemoStoryPalette.bodyInk.color(),
            alignment: .left,
            lineHeight: 27,
            context: context
        )
        drawPageNumber(page.id, context: context)
    }

    private static func drawColophon(_ page: SampleStory.Page,
                                     context: CGContext) {
        let x = DemoStoryStyle.sideMargin
        drawLine(
            page.title,
            x: x,
            centerY: 276,
            font: DemoStoryStyle.titleFont(size: 22),
            color: DemoStoryPalette.ink.color(),
            tracking: 1.2,
            context: context
        )
        drawHairline(
            x: x,
            length: 26,
            y: 253,
            color: DemoStoryPalette.accent.cgColor(),
            lineWidth: 1.6,
            context: context
        )

        let panel = CGRect(x: 24, y: 150, width: 372, height: 96)
        context.saveGState()
        context.setFillColor(DemoStoryPalette.paperShade.cgColor())
        context.addPath(CGPath(
            roundedRect: panel,
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        ))
        context.fillPath()
        context.restoreGState()

        drawParagraph(
            page.body,
            in: CGRect(x: 44, y: 184, width: 332, height: 48),
            font: DemoStoryStyle.quoteFont(size: 13.5),
            color: DemoStoryPalette.ink.color(),
            alignment: .left,
            lineHeight: 24,
            context: context
        )
        if let source = page.source {
            drawRightAlignedLine(
                source,
                rightX: 368,
                centerY: 166,
                font: DemoStoryStyle.bodyFont(size: 9.5),
                color: DemoStoryPalette.mutedInk.color(),
                context: context
            )
        }
        if let note = page.note {
            drawParagraph(
                note,
                in: CGRect(x: x, y: 50, width: DemoStoryStyle.contentWidth, height: 88),
                font: DemoStoryStyle.bodyFont(size: 11.5),
                color: DemoStoryPalette.bodyInk.color(),
                alignment: .left,
                lineHeight: 22,
                context: context
            )
        }
        drawPageNumber(page.id, context: context)
    }

    // MARK: - Details

    private static func drawPageNumber(_ number: Int, context: CGContext) {
        let center = CGPoint(x: pageSize.width / 2, y: 28)
        let radius: CGFloat = 9.5
        context.saveGState()
        context.setStrokeColor(DemoStoryPalette.hairline.cgColor())
        context.setLineWidth(0.7)
        context.strokeEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.restoreGState()

        drawCenteredLine(
            String(number),
            centerX: center.x,
            centerY: center.y,
            font: DemoStoryStyle.bodyMediumFont(size: 8.5),
            color: DemoStoryPalette.accent.color(),
            tracking: 0.2,
            context: context
        )
    }

    private static func drawSeal(_ character: String,
                                 in rect: CGRect,
                                 context: CGContext) {
        context.saveGState()
        context.setFillColor(DemoStoryPalette.seal.cgColor())
        context.addPath(CGPath(
            roundedRect: rect,
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        ))
        context.fillPath()

        context.setStrokeColor(DemoStoryPalette.paper.cgColor(alpha: 0.55))
        context.setLineWidth(0.8)
        context.stroke(rect.insetBy(dx: 3, dy: 3))
        context.restoreGState()

        drawCenteredLine(
            character,
            centerX: rect.midX,
            centerY: rect.midY,
            font: DemoStoryStyle.titleFont(size: 18),
            color: DemoStoryPalette.paper.color(),
            context: context
        )
    }

    private static func drawHairline(x: CGFloat,
                                     length: CGFloat,
                                     y: CGFloat,
                                     color: CGColor,
                                     lineWidth: CGFloat,
                                     context: CGContext) {
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(lineWidth)
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x + length, y: y))
        context.strokePath()
        context.restoreGState()
    }

    // MARK: - Text

    private static func drawLine(_ text: String,
                                 x: CGFloat,
                                 centerY: CGFloat,
                                 font: DemoStoryFont,
                                 color: DemoStoryColor,
                                 tracking: CGFloat = 0,
                                 context: CGContext) {
        let line = makeLine(text, font: font, color: color, tracking: tracking)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        _ = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
        let baseline = centerY - (ascent - descent) / 2

        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: baseline)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func drawCenteredLine(_ text: String,
                                         centerX: CGFloat,
                                         centerY: CGFloat,
                                         font: DemoStoryFont,
                                         color: DemoStoryColor,
                                         tracking: CGFloat = 0,
                                         context: CGContext) {
        let line = makeLine(text, font: font, color: color, tracking: tracking)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
        let baseline = centerY - (ascent - descent) / 2

        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: centerX - width / 2, y: baseline)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func drawRightAlignedLine(_ text: String,
                                             rightX: CGFloat,
                                             centerY: CGFloat,
                                             font: DemoStoryFont,
                                             color: DemoStoryColor,
                                             tracking: CGFloat = 0,
                                             context: CGContext) {
        let line = makeLine(text, font: font, color: color, tracking: tracking)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
        let baseline = centerY - (ascent - descent) / 2

        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: rightX - width, y: baseline)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func makeLine(_ text: String,
                                 font: DemoStoryFont,
                                 color: DemoStoryColor,
                                 tracking: CGFloat) -> CTLine {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        if tracking != 0 {
            attributes[.kern] = tracking
        }
        return CTLineCreateWithAttributedString(
            NSAttributedString(string: text, attributes: attributes)
        )
    }

    private static func drawParagraph(_ text: String,
                                      in rect: CGRect,
                                      font: DemoStoryFont,
                                      color: DemoStoryColor,
                                      alignment: NSTextAlignment,
                                      lineHeight: CGFloat,
                                      context: CGContext) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight

        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph,
            ]
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: attributed.length),
            path,
            nil
        )

        context.saveGState()
        context.textMatrix = .identity
        CTFrameDraw(frame, context)
        context.restoreGState()
    }
}