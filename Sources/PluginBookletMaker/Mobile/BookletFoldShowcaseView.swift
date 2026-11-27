#if os(iOS)
import SwiftUI
import UIKit

// MARK: - Full-Screen Fold Showcase

/// 点首页「动效」后铺满全屏的折叠演示。
///
/// 想看动效说明用户想弄清楚「一张 A4 怎么变成一本小册子」，所以这里
/// 把纸页按屏幕宽度等比放大：折好后钉上订书钉，再翻开封面露出 2/7
/// 跨页——装订位置和拼版后的页序一眼能看到，而不只是「折了一下」。
struct BookletFoldShowcaseView: View {
    let onClose: () -> Void

    @StateObject private var thumbnails = BookletDemoPageThumbnails.shared
    @State private var animationStart = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 12)
                        // 首次布局宽度为 0 时会得到负宽，先夹到合理区间。
                        stage(sheetWidth: min(max(geometry.size.width - 72, 120), 440))
                        explanation
                            .padding(.top, 24)
                        Spacer(minLength: 12)
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background(BookletMobileStyle.canvas.ignoresSafeArea())
            .navigationTitle(BookletLocalization.string("Fold animation"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(BookletLocalization.string("Close"), action: onClose)
                        .accessibilityIdentifier("booklet.showcase.close")
                }
            }
        }
        .tint(BookletMobileStyle.accent)
        .onAppear { thumbnails.prepare() }
    }

    private func stage(sheetWidth: CGFloat) -> some View {
        let pageHeight = sheetWidth * 210 / 297
        return TimelineView(.animation(paused: reduceMotion)) { context in
            let elapsed = context.date.timeIntervalSince(animationStart)
            VStack(spacing: 0) {
                BookletFoldScene(
                    elapsed: elapsed,
                    images: thumbnails.images,
                    reduceMotion: reduceMotion,
                    pageHeight: pageHeight
                )
                .frame(width: sheetWidth + 40, height: pageHeight + 48)
                .background(
                    BookletMobileStyle.softAccent,
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .accessibilityHidden(true)

                phaseChips(BookletFoldPhase.at(elapsed))
                    .padding(.top, 18)
            }
        }
    }

    /// 与动效同步的三步提示：正在演示哪一步，哪一步就高亮。
    private func phaseChips(_ phase: BookletFoldPhase) -> some View {
        HStack(spacing: 8) {
            ForEach(BookletFoldPhase.allCases, id: \.rawValue) { item in
                let isActive = item == phase
                Text(BookletLocalization.string(item.titleKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isActive ? Color.white : BookletMobileStyle.accent)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isActive ? BookletMobileStyle.accent : BookletMobileStyle.accent.opacity(0.12))
                    )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: phase)
        .accessibilityIdentifier("booklet.showcase.phases")
    }

    private var explanation: some View {
        VStack(spacing: 10) {
            Text(BookletLocalization.string("How the pages come together"))
                .font(.headline)
            Text(BookletLocalization.string(
                "Print both sides, fold along the center, then staple the spine."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: 560)
        .accessibilityIdentifier("booklet.showcase.text")
    }
}

// MARK: - Phase

/// 演示的三个阶段，文案与首页卡片的步骤对应。
enum BookletFoldPhase: Int, CaseIterable {
    case print
    case fold
    case staple

    static func at(_ elapsed: TimeInterval) -> BookletFoldPhase {
        let time = max(0, elapsed)
            .truncatingRemainder(dividingBy: BookletFoldScene.loopLength)
        if time < BookletFoldScene.foldStart { return .print }
        if time < BookletFoldScene.stapleStart { return .fold }
        return .staple
    }

    var titleKey: String {
        switch self {
        case .print: return "Duplex"
        case .fold: return "Fold in half"
        case .staple: return "Staple"
        }
    }
}

// MARK: - Fold Scene

/// A4 张沿中线折成小册子的动效。
///
/// 时间线：印刷 → 翻折 → 装订 → 翻开封面露出 2/7 跨页。所有尺寸都由
/// `pageHeight` 推导：首页卡片里用 128，全屏演示按屏宽放大到 ~260，
/// 细节（圆角、纸厚、页码角标）按 `scale` 同步缩放。
struct BookletFoldScene: View {
    let elapsed: TimeInterval
    let images: [Int: UIImage]
    let reduceMotion: Bool
    var pageHeight: CGFloat = 128

    static let loopLength: TimeInterval = 8.3
    static let foldStart: TimeInterval = 1.15
    static let foldEnd: TimeInterval = 2.37
    static let stapleStart: TimeInterval = 3.6

    private var scale: CGFloat { pageHeight / 128 }
    private var pageWidth: CGFloat { pageHeight * DemoStoryStyle.pageAspectRatio }
    private var sheetWidth: CGFloat { pageHeight * 297 / 210 }
    private var sheetPadding: CGFloat { 4.5 * scale }
    /// 动效里两页紧贴（不留中缝）：翻过去的一页要正好盖住另一页。
    private var cellWidth: CGFloat { (sheetWidth - sheetPadding * 2) / 2 }
    private var cellHeight: CGFloat { pageHeight - sheetPadding * 2 }
    /// 纸张四周留一点空间给 3D 旋转时的透视投影。
    private var sceneWidth: CGFloat { sheetWidth + 7 * scale }
    private var sceneHeight: CGFloat { pageHeight + 10 * scale }

    private var time: TimeInterval {
        let value = max(0, elapsed)
        return value.truncatingRemainder(dividingBy: Self.loopLength)
    }

    private var foldAngle: Double {
        guard !reduceMotion else { return 0 }
        return 179 * ramp(Self.foldStart, Self.foldEnd)
    }

    private var sheetOpacity: Double {
        guard time > 3.0 else { return 1 }
        return 1 - ramp(3.0, 3.32)
    }

    private var sheetScale: Double {
        1 - 0.08 * ramp(3.0, 3.32)
    }

    /// 成品先居中展示；翻开的过程中整本向右漂半页，让摊开的跨页正好居中。
    private var bookDrift: CGFloat {
        pageWidth / 2 * ramp(4.0, 5.5)
    }

    private var bookOpacity: Double {
        ramp(3.28, 3.55)
    }

    private var bookScale: Double {
        0.94 + 0.06 * ramp(3.28, 3.55)
    }

    /// 订书钉从细到实地「咬」进书脊；两针错开一点，像真的按了两下。
    private func stapleBar(start: TimeInterval, end: TimeInterval) -> some View {
        let progress = ramp(start, end)
        return Capsule(style: .continuous)
            .fill(Color(white: 0.45))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.45), lineWidth: 0.4 * scale)
            }
            .frame(width: 2.6 * scale, height: 9 * scale)
            .scaleEffect(0.55 + 0.45 * progress)
            .opacity(progress)
            .shadow(color: .black.opacity(0.22), radius: 0.5 * scale, y: 0.4 * scale)
    }

    /// 封面先微微掀起，再绕书脊（两张纸接缝处）向左翻 180°，
    /// 露出背面的页 2。
    private var coverOpenAngle: Double {
        guard !reduceMotion else { return 0 }
        return 9 * ramp(4.0, 4.5) + 169 * ramp(4.5, 5.6)
    }

    private var pageTwoChipOpacity: Double {
        ramp(5.45, 5.75)
    }

    private var exitOpacity: Double {
        1 - ramp(7.05, 7.55)
    }

    var body: some View {
        ZStack {
            sheet
                .opacity(sheetOpacity)
                .scaleEffect(sheetScale)

            bookAssembly
                .offset(x: bookDrift)
        }
        .frame(width: sceneWidth, height: sceneHeight)
        .opacity(exitOpacity)
    }

    private var bookAssembly: some View {
        ZStack {
            paperStack
                .opacity(bookOpacity)
                .scaleEffect(bookScale)

            // 翻开封面后露出的右页（页 7）；闭合时被封面完全盖住。
            pageCell(page: 7)
                .frame(width: pageWidth, height: pageHeight)
                .opacity(bookOpacity)

            cover
                .frame(width: pageWidth, height: pageHeight)
                .rotation3DEffect(
                    .degrees(-coverOpenAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.4
                )
                .opacity(bookOpacity)
                .scaleEffect(bookScale)

            // 页 2 是封面纸背，自带角标会被镜像，等翻开落定后再叠一个正的。
            PageNumberChip(number: 2, scale: scale)
                .padding(2 * scale)
                .frame(width: pageWidth, height: pageHeight, alignment: .bottomLeading)
                .offset(x: -pageWidth)
                .opacity(pageTwoChipOpacity)

            staples
                .offset(x: -pageWidth / 2)
        }
    }

    /// 纸面不铺整张白底：翻页过半后右侧本应是空的（纸已经翻到左边），
    /// 整张白底会让检视者误以为右侧还留着一张纸。
    private var sheet: some View {
        ZStack(alignment: .topLeading) {
            pageCell(page: 8)
                .frame(width: cellWidth, height: cellHeight)
                .offset(x: sheetPadding, y: sheetPadding)

            foldableCell
                .frame(width: cellWidth, height: cellHeight)
                .rotation3DEffect(
                    .degrees(-foldAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.4
                )
                .offset(x: sheetPadding + cellWidth, y: sheetPadding)
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
        .shadow(color: .black.opacity(0.16), radius: 1.4 * scale, y: 0.7 * scale)
    }

    /// 成品书脊侧的纸堆厚度，翻开后成为右页下方的叠纸边。
    private var paperStack: some View {
        ZStack {
            paperLayer.offset(x: 2.4 * scale, y: 1.6 * scale)
            paperLayer.offset(x: 1.2 * scale, y: 0.8 * scale)
        }
    }

    private var paperLayer: some View {
        RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
            .fill(Color.white)
            .frame(width: pageWidth, height: pageHeight)
            .overlay {
                RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.8 * scale)
            }
    }

    private var cover: some View {
        ZStack {
            pageCell(page: 1)
                .opacity(coverOpenAngle < 90 ? 1 : 0)
            backFace(page: 2)
                .scaleEffect(x: -1, y: 1)
                .opacity(coverOpenAngle < 90 ? 0 : 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 2.6 * scale, y: 1.3 * scale)
    }

    private var staples: some View {
        VStack(spacing: pageHeight * 0.5) {
            stapleBar(start: 3.6, end: 3.88)
            stapleBar(start: 3.76, end: 4.04)
        }
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
        .clipShape(RoundedRectangle(cornerRadius: 3 * scale, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.8 * scale)
        }
        .overlay(alignment: .bottomTrailing) {
            PageNumberChip(number: page, scale: scale)
                .padding(2 * scale)
        }
        .shadow(color: .black.opacity(0.12), radius: 2 * scale, y: scale)
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
        .clipShape(RoundedRectangle(cornerRadius: 3 * scale, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.8 * scale)
        }
    }

    private func ramp(_ start: TimeInterval, _ end: TimeInterval) -> Double {
        guard end > start else { return time >= end ? 1 : 0 }
        let progress = min(max((time - start) / (end - start), 0), 1)
        return progress * progress * (3 - 2 * progress)
    }
}
#endif