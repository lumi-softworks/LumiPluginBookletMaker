#if os(iOS)
import PDFKit
import SwiftUI
import UIKit

// MARK: - Welcome Workflow Illustration

/// 首页「制作小册子」卡片里的流程示意图。
///
/// 静态形态按真实纸张比例、2×2 展示四步：原 PDF（8 页）→ 转换为 A4 `[8|1]`
/// 两张 → 双面打印 → 对折装订；动效形态把 A4 沿中线折成小册子。
/// 纸页内容全部来自内置示例 PDF（`DemoPDFProvider`），因此和用户
/// 在 App 里打开的演示绘本完全一致。
struct BookletWelcomeWorkflowView: View {
    @Binding var isAnimating: Bool
    let onOpen: () -> Void

    @StateObject private var thumbnails = BookletDemoPageThumbnails.shared
    @State private var animationStart = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 统一比例尺 ≈ 0.38pt/mm：A5 页高 80、A4 横向宽 113。
    ///
    /// 四步按 2×2 排列而不是并排一行：并排时每步只有列表宽度的一半，
    /// 纸页缩到 37pt 宽，用户看不清示例内容。
    private let pageHeight: CGFloat = 80
    private var pageWidth: CGFloat { pageHeight * DemoStoryStyle.pageAspectRatio }
    private var sheetWidth: CGFloat { pageHeight * 297 / 210 }
    private var cellWidth: CGFloat { (sheetWidth - 9 - 3) / 2 }
    private var cellHeight: CGFloat { pageHeight - 9 }

    private let artHeight: CGFloat = 84
    private let arrowWidth: CGFloat = 10
    private let rowSpacing: CGFloat = 10
    /// 两行示意图 + 顶部切换按钮留白 + 底部留白的固定高度。
    /// 形态切换时高度不变，避免卡片跳动。
    private let illustrationHeight: CGFloat = 252

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if isAnimating {
                    animatedFlow
                } else {
                    staticFlow
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 7)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .accessibilityHidden(true)

            modeToggle
                .padding(.top, 3)
                .padding(.trailing, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: illustrationHeight)
        .background(
            BookletMobileStyle.softAccent,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .onAppear { thumbnails.prepare() }
        .onChange(of: isAnimating) { _, _ in
            animationStart = Date()
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isAnimating.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isAnimating ? "stop.fill" : "play.fill")
                    .font(.system(size: 8, weight: .bold))
                Text(BookletLocalization.string(isAnimating ? "Static" : "Animate"))
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(BookletMobileStyle.accent)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(toggleFill, in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("welcome.bookletMode")
        .accessibilityLabel(BookletLocalization.string(
            isAnimating ? "Show static steps" : "Show fold animation"
        ))
    }

    private var toggleFill: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.12, alpha: 0.72)
                : UIColor.white.withAlphaComponent(0.82)
        })
    }

    // MARK: - Static Flow

    private var staticFlow: some View {
        VStack(spacing: rowSpacing) {
            row(
                stage(1, caption: "PDF") { pageFan },
                stage(2, caption: "To A4") { imposedSheets }
            )
            row(
                stage(3, caption: "Duplex") { printerStage },
                stage(4, caption: "Fold") { finishedBooklet }
            )
        }
        .frame(maxHeight: .infinity)
    }

    /// 一行两步；两步平分列宽，中间是步骤箭头。
    private func row<First: View, Second: View>(
        _ first: First,
        _ second: Second
    ) -> some View {
        HStack(spacing: 0) {
            first
                .frame(maxWidth: .infinity)
            flowArrow
            second
                .frame(maxWidth: .infinity)
        }
    }

    private func stage<Art: View>(
        _ number: Int,
        caption: String,
        @ViewBuilder art: () -> Art
    ) -> some View {
        VStack(spacing: 5) {
            art()
                .frame(height: artHeight)
            HStack(spacing: 3.5) {
                Text("\(number)")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(BookletMobileStyle.accent)
                    .frame(width: 13, height: 13)
                    .background(BookletMobileStyle.accent.opacity(0.12), in: Circle())
                Text(BookletLocalization.string(caption))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private var flowArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(BookletMobileStyle.accent.opacity(0.38))
            .frame(width: arrowWidth, height: artHeight)
    }

    // MARK: - Stage 1 · Source PDF

    private var pageFan: some View {
        ZStack {
            ForEach(SampleStory.pages.reversed()) { page in
                let step = CGFloat(page.id - 1)
                pageSurface(page: page.id, corner: 3, badge: .bottomTrailing)
                    .frame(width: pageWidth, height: pageHeight)
                    .offset(x: step * 2.5, y: step * 0.3)
                    .zIndex(Double(SampleStory.pageCount - page.id))
            }
        }
        .frame(height: artHeight)
    }

    // MARK: - Stage 2 · Imposed A4 Sheets

    private var imposedSheets: some View {
        imposedSheets(showsPDFTag: true)
    }

    private func imposedSheets(showsPDFTag: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            sheetSurface(showsPDFTag: false)
                .offset(x: 2.2, y: 1.6)
            sheetSurface(showsPDFTag: showsPDFTag)
        }
        .frame(width: sheetWidth + 2.2, height: pageHeight + 1.6)
    }

    private func sheetSurface(showsPDFTag: Bool) -> some View {
        HStack(spacing: 3) {
            pageSurface(page: 8, corner: 1.5, badge: .bottomTrailing)
                .frame(width: cellWidth, height: cellHeight)
            pageSurface(page: 1, corner: 1.5, badge: .bottomTrailing)
                .frame(width: cellWidth, height: cellHeight)
        }
        .padding(4.5)
        .frame(width: sheetWidth, height: pageHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(Color.black.opacity(0.14), lineWidth: 0.7)
        }
        .overlay { foldLine }
        .overlay(alignment: .topTrailing) {
            if showsPDFTag {
                pdfTag
                    .offset(x: 2.5, y: -4)
            }
        }
        .shadow(color: .black.opacity(0.12), radius: 1.6, y: 0.8)
    }

    private var foldLine: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: geometry.size.width / 2, y: 4))
                path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height - 4))
            }
            .stroke(
                Color.black.opacity(0.2),
                style: StrokeStyle(lineWidth: 0.7, dash: [2, 2])
            )
        }
    }

    private var pdfTag: some View {
        Text("PDF")
            .font(.system(size: 7, weight: .bold))
            .tracking(0.3)
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .frame(height: 13)
            .background(BookletMobileStyle.paperInk, in: RoundedRectangle(cornerRadius: 3.5))
    }

    // MARK: - Stage 3 · Duplex Printer

    private var printerStage: some View {
        ZStack(alignment: .bottom) {
            imposedSheets(showsPDFTag: false)
                .offset(y: -8)
            printer
                .frame(width: sheetWidth, height: 16)
        }
        .frame(height: artHeight, alignment: .bottom)
    }

    private var printer: some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(deviceFill)
            .overlay {
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .black.opacity(0.14)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(deviceSlot)
                    .frame(height: 3)
                    .padding(.horizontal, 8)
                    .padding(.top, 3)
                    .shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5)
            }
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(BookletMobileStyle.accent)
                    .frame(width: 2.2, height: 2.2)
                    .padding(.trailing, 6)
                    .padding(.top, 7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .strokeBorder(deviceEdge, lineWidth: 0.6)
            }
            .shadow(color: .black.opacity(0.1), radius: 1, y: 0.5)
    }

    private var deviceFill: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.24, green: 0.24, blue: 0.26, alpha: 1)
                : UIColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1)
        })
    }

    private var deviceEdge: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.14)
                : UIColor.black.withAlphaComponent(0.12)
        })
    }

    private var deviceSlot: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.56, alpha: 1)
                : UIColor(white: 0.6, alpha: 1)
        })
    }

    // MARK: - Stage 4 · Finished Booklet

    private var finishedBooklet: some View {
        MiniFinishedBooklet(
            image: thumbnails.images[1],
            pageWidth: pageWidth,
            pageHeight: pageHeight
        )
        .frame(height: artHeight)
    }

    // MARK: - Animated Flow

    private var animatedFlow: some View {
        VStack(spacing: 6) {
            TimelineView(.animation(paused: !isAnimating)) { context in
                BookletFoldScene(
                    elapsed: context.date.timeIntervalSince(animationStart),
                    images: thumbnails.images,
                    reduceMotion: reduceMotion
                )
            }
            .frame(height: 140)

            Text(BookletLocalization.string("Print duplex, then fold and staple."))
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Page Surface

    private func pageSurface(
        page: Int,
        corner: CGFloat,
        badge: Alignment?
    ) -> some View {
        ZStack {
            Color.white
            if let image = thumbnails.images[page] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.6)
        }
        .overlay(alignment: badge ?? .bottomTrailing) {
            if let badge {
                PageNumberChip(number: page)
                    .padding(1.5)
            }
        }
        .shadow(color: .black.opacity(0.12), radius: 1.2, y: 0.6)
    }
}

// MARK: - Finished Booklet

private struct MiniFinishedBooklet: View {
    let image: UIImage?
    let pageWidth: CGFloat
    let pageHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            thickness(offset: 2.4, opacity: 0.7)
            thickness(offset: 1.2, opacity: 0.9)

            ZStack {
                Color.white
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: pageWidth, height: pageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.6)
            }
            .overlay(alignment: .leading) {
                LinearGradient(
                    colors: [.black.opacity(0.14), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 4)
            }
            .overlay { staples }
            .overlay(alignment: .bottom) {
                PageNumberChip(number: 1)
                    .padding(.bottom, 2)
            }
            .shadow(color: .black.opacity(0.14), radius: 1.6, y: 1)
        }
        .frame(width: pageWidth + 2.4, height: pageHeight + 2.4, alignment: .topLeading)
    }

    private func thickness(offset: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.14), lineWidth: 0.6)
            }
            .frame(width: pageWidth, height: pageHeight)
            .opacity(opacity)
            .offset(x: offset, y: offset * 0.8)
    }

    private var staples: some View {
        VStack {
            staple
            Spacer(minLength: 0)
            staple
        }
        .padding(.leading, 2)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var staple: some View {
        RoundedRectangle(cornerRadius: 0.8)
            .fill(Color(uiColor: .systemGray))
            .frame(width: 2, height: 6)
    }
}

// MARK: - Page Number Chip

private struct PageNumberChip: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.system(size: 7.5, weight: .semibold))
            .foregroundStyle(BookletMobileStyle.paperInk)
            .padding(.horizontal, 2.5)
            .frame(minWidth: 11, minHeight: 10)
            .background(Color.white.opacity(0.86), in: Capsule())
    }
}

// MARK: - Fold Scene

private struct BookletFoldScene: View {
    let elapsed: TimeInterval
    let images: [Int: UIImage]
    let reduceMotion: Bool

    private let loop: TimeInterval = 6.4
    private let sceneWidth: CGFloat = 188
    private let sceneHeight: CGFloat = 138
    private let pageHeight: CGFloat = 128
    private var pageWidth: CGFloat { pageHeight * DemoStoryStyle.pageAspectRatio }
    private var sheetWidth: CGFloat { pageHeight * 297 / 210 }
    /// 动效里两页紧贴（不留中缝）：翻过去的一页要正好盖住另一页。
    private var cellWidth: CGFloat { (sheetWidth - 9) / 2 }
    private var cellHeight: CGFloat { pageHeight - 9 }

    private var time: TimeInterval {
        let value = max(0, elapsed)
        return value.truncatingRemainder(dividingBy: loop)
    }

    private var foldAngle: Double {
        guard !reduceMotion else { return 0 }
        return 179 * ramp(1.15, 2.37)
    }

    private var sheetOpacity: Double {
        guard time > 3.0 else { return 1 }
        return 1 - ramp(3.0, 3.6)
    }

    private var sheetScale: Double {
        1 - 0.1 * ramp(3.0, 3.6)
    }

    private var bookOpacity: Double {
        guard time > 3.2 else { return 0 }
        return ramp(3.2, 3.8) * (1 - ramp(5.5, 6.0))
    }

    private var bookScale: Double {
        0.82 + 0.18 * ramp(3.2, 3.8)
    }

    var body: some View {
        ZStack {
            sheet
                .opacity(sheetOpacity)
                .scaleEffect(sheetScale)
            MiniFinishedBooklet(
                image: images[1],
                pageWidth: pageWidth,
                pageHeight: pageHeight
            )
            .opacity(bookOpacity)
            .scaleEffect(bookScale)
        }
        .frame(width: sceneWidth, height: sceneHeight)
    }

    /// 纸面不铺整张白底：翻页过半后右侧本应是空的（纸已经翻到左边），
    /// 整张白底会让检视者误以为右侧还留着一张纸。
    private var sheet: some View {
        ZStack(alignment: .topLeading) {
            pageCell(page: 8)
                .frame(width: cellWidth, height: cellHeight)
                .offset(x: 4.5, y: 4.5)

            foldableCell
                .frame(width: cellWidth, height: cellHeight)
                .rotation3DEffect(
                    .degrees(-foldAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.4
                )
                .offset(x: 4.5 + cellWidth, y: 4.5)
        }
        // 两个子视图都只有半张纸宽（另一半靠 offset 摆位），
        // 用 leading 对齐才是从纸张左边开始铺，否则整张纸会被右移半格。
        .frame(width: sheetWidth, height: pageHeight, alignment: .topLeading)
    }

    private var foldableCell: some View {
        ZStack {
            pageCell(page: 1)
                .opacity(foldAngle < 90 ? 1 : 0)
            // 页 1 的纸背是页 2（A4 背面右半幅），翻过去后正好朝上。
            // 3D 旋转会把背面镜像显示，这里先水平翻转抵消。
            backFace(page: 2)
                .scaleEffect(x: -1, y: 1)
                .opacity(foldAngle < 90 ? 0 : 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 1.4, y: 0.7)
    }

    private func pageCell(page: Int) -> some View {
        ZStack {
            Color.white
            if let image = images[page] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.8)
        }
        .overlay(alignment: .bottomTrailing) {
            PageNumberChip(number: page)
                .padding(2)
        }
        .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
    }

    /// 纸背不带页码角标——翻面后角标会被镜像。
    private func backFace(page: Int) -> some View {
        ZStack {
            Color.white
            if let image = images[page] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.8)
        }
    }

    private func ramp(_ start: TimeInterval, _ end: TimeInterval) -> Double {
        guard end > start else { return time >= end ? 1 : 0 }
        let progress = min(max((time - start) / (end - start), 0), 1)
        return progress * progress * (3 - 2 * progress)
    }
}

// MARK: - Demo PDF Thumbnails

/// 把内置示例 PDF 的每一页渲染成首页示意图用的小缩略图。
/// 只渲染一次并常驻内存；首帧加载完成前纸页显示为空白纸。
final class BookletDemoPageThumbnails: ObservableObject, @unchecked Sendable {
    static let shared = BookletDemoPageThumbnails()

    @Published private(set) var images: [Int: UIImage] = [:]

    private let lock = NSLock()
    private var isPreparing = false

    private struct RenderedPages: @unchecked Sendable {
        let images: [Int: UIImage]
    }

    func prepare() {
        let shouldStart = lock.withLock {
            if !images.isEmpty || isPreparing {
                return false
            }
            isPreparing = true
            return true
        }
        guard shouldStart else { return }

        Task.detached(priority: .userInitiated) { [weak self] in
            let rendered = Self.renderPages()
            guard let self else { return }
            self.lock.withLock { self.isPreparing = false }

            guard !rendered.images.isEmpty else { return }
            DispatchQueue.main.async {
                self.images = rendered.images
            }
        }
    }

    private static func renderPages() -> RenderedPages {
        guard let document = try? DemoPDFProvider.makeDocument(),
              let pdf = PDFDocument(url: document.url) else {
            return RenderedPages(images: [:])
        }

        let pixelHeight = DemoStoryStyle.pageSize.height * 0.5
        let size = CGSize(
            width: pixelHeight * DemoStoryStyle.pageAspectRatio,
            height: pixelHeight
        )

        var images: [Int: UIImage] = [:]
        for index in 0..<min(pdf.pageCount, SampleStory.pageCount) {
            guard let page = pdf.page(at: index) else { continue }
            images[index + 1] = page.thumbnail(of: size, for: .cropBox)
        }
        return RenderedPages(images: images)
    }
}
#endif