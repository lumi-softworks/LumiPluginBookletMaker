#if os(iOS)
import SwiftUI
import UIKit

// MARK: - Welcome Illustration Scale

/// 首页三张卡片的纸页共用同一比例尺，保证各卡片里的纸页看起来一样大。
enum BookletWelcomeIllustrationMetrics {
    /// scale = 1 时四个舞台宽度之和（54 + 77 + 77 + 54）。
    static let baseRowWidth: CGFloat = 262
    static let arrowWidth: CGFloat = 10
    static let arrowCount: CGFloat = 3
    static let minimumScale: CGFloat = 0.85
    static let maximumScale: CGFloat = 1.6

    static func scale(for width: CGFloat) -> CGFloat {
        let fit = (width - arrowWidth * arrowCount) / baseRowWidth
        return min(max(fit, minimumScale), maximumScale)
    }
}

// MARK: - File Tool Illustration

/// 首页「拆分 PDF」「合并 PDF」卡片的示意图。
///
/// 纸页内容和「制作小册子」一样来自内置示例 PDF，比例尺也与那张卡共用，
/// 因此三张卡里的纸页大小一致。这两张卡只做静态示意，不做动效。
struct BookletFileToolIllustrationView: View {
    enum Kind {
        case split
        case merge
    }

    let kind: Kind
    let illustrationWidth: CGFloat

    @StateObject private var thumbnails = BookletDemoPageThumbnails.shared

    private var scale: CGFloat {
        BookletWelcomeIllustrationMetrics.scale(for: illustrationWidth)
    }

    private var pageHeight: CGFloat { 52.5 * scale }
    private var pageWidth: CGFloat { pageHeight * DemoStoryStyle.pageAspectRatio }
    private var artHeight: CGFloat { pageHeight + 10 * scale }
    private var panelHeight: CGFloat { artHeight + 28 }

    var body: some View {
        Group {
            switch kind {
            case .split:
                splitFlow
            case .merge:
                mergeFlow
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: panelHeight)
        .background(
            BookletMobileStyle.softAccent,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .onAppear { thumbnails.prepare() }
        .accessibilityHidden(true)
    }

    // MARK: - Split

    /// 一叠多页 PDF ——剪刀—— 三份单页文件。
    private var splitFlow: some View {
        HStack(spacing: 13 * scale) {
            pageFan([1, 2, 3, 4], showsChip: true)
                .overlay(alignment: .topTrailing) {
                    pdfTag
                        .offset(x: 3 * scale, y: -5 * scale)
                }

            Image(systemName: "scissors")
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(BookletMobileStyle.accent.opacity(0.75))

            splitOutputs
        }
    }

    private var splitOutputs: some View {
        HStack(spacing: 8 * scale) {
            ForEach(1...3, id: \.self) { page in
                pageCard(page: page, corner: 3 * scale, showsChip: true)
            }
        }
    }

    // MARK: - Merge

    /// 文件 A + 文件 B —— 合并后的一叠 PDF。
    private var mergeFlow: some View {
        HStack(spacing: 13 * scale) {
            HStack(spacing: 9 * scale) {
                inputFile(page: 1, letter: "A")
                Text("+")
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(.tertiary)
                inputFile(page: 4, letter: "B")
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(BookletMobileStyle.accent.opacity(0.5))

            pageFan([1, 4, 2, 3], showsChip: true)
        }
    }

    private func inputFile(page: Int, letter: String) -> some View {
        pageCard(page: page, corner: 3 * scale, showsChip: false)
            .overlay(alignment: .topLeading) {
                Text(letter)
                    .font(.system(size: 8 * scale, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 15 * scale, height: 15 * scale)
                    .background(BookletMobileStyle.accent, in: Circle())
                    .padding(3 * scale)
            }
    }

    // MARK: - Shared Pieces

    /// 多层纸页向右下错开；最上面的第一页带页码角标。
    private func pageFan(_ pages: [Int], showsChip: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                let depth = CGFloat(index)
                pageCard(
                    page: page,
                    corner: 3 * scale,
                    showsChip: showsChip && index == 0
                )
                .offset(x: depth * 2.4 * scale, y: depth * 0.5 * scale)
                .zIndex(Double(pages.count - index))
            }
        }
        .frame(
            width: pageWidth + CGFloat(pages.count - 1) * 2.4 * scale,
            height: pageHeight + CGFloat(pages.count - 1) * 0.5 * scale,
            alignment: .topLeading
        )
    }

    private func pageCard(page: Int, corner: CGFloat, showsChip: Bool) -> some View {
        ZStack {
            Color.white
            if let image = thumbnails.images[page] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: pageWidth, height: pageHeight)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.6 * scale)
        }
        .overlay(alignment: .bottomTrailing) {
            if showsChip {
                PageNumberChip(number: page, scale: scale)
                    .padding(2 * scale)
            }
        }
        .shadow(color: .black.opacity(0.12), radius: 1.6 * scale, y: 0.8 * scale)
    }

    private var pdfTag: some View {
        Text("PDF")
            .font(.system(size: 7 * scale, weight: .bold))
            .tracking(0.3 * scale)
            .foregroundStyle(.white)
            .padding(.horizontal, 5 * scale)
            .frame(height: 13 * scale)
            .background(
                BookletMobileStyle.paperInk,
                in: RoundedRectangle(cornerRadius: 3.5 * scale)
            )
    }
}
#endif