#if os(iOS)
import SwiftUI
import UIKit

// MARK: - Full-Screen Fold Showcase

/// 点首页「动效」后铺满全屏的折叠演示。
///
/// 想看动效说明用户想弄清楚「一张 A4 怎么变成一本小册子」，所以这里
/// 把纸页按屏幕宽度等比放大，并配一段说明，让折叠过程看得清楚。
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
                            .padding(.top, 28)
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
            BookletFoldScene(
                elapsed: context.date.timeIntervalSince(animationStart),
                images: thumbnails.images,
                reduceMotion: reduceMotion,
                pageHeight: pageHeight
            )
        }
        .frame(width: sheetWidth + 40, height: pageHeight + 48)
        .background(
            BookletMobileStyle.softAccent,
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .accessibilityHidden(true)
    }

    private var explanation: some View {
        VStack(spacing: 10) {
            Text(BookletLocalization.string("How the pages come together"))
                .font(.headline)
            Text(BookletLocalization.string(
                "Print both sides, flip on the long edge, then fold along the center."
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

// MARK: - Fold Scene

/// A4 张沿中线折成小册子的动效。
///
/// 所有尺寸都由 `pageHeight` 推导：首页卡片里用 128，全屏演示按屏宽
/// 放大到 ~260，细节（圆角、纸厚、页码角标）按 `scale` 同步缩放。
struct BookletFoldScene: View {
    let elapsed: TimeInterval
    let images: [Int: UIImage]
    let reduceMotion: Bool
    var pageHeight: CGFloat = 128

    private let loop: TimeInterval = 6.4
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
        return value.truncatingRemainder(dividingBy: loop)
    }

    private var foldAngle: Double {
        guard !reduceMotion else { return 0 }
        return 179 * ramp(1.15, 2.37)
    }

    private var sheetOpacity: Double {
        guard time > 3.0 else { return 1 }
        return 1 - ramp(3.0, 3.32)
    }

    private var sheetScale: Double {
        1 - 0.08 * ramp(3.0, 3.32)
    }

    private var bookOpacity: Double {
        guard time > 3.28 else { return 0 }
        return ramp(3.28, 3.6) * (1 - ramp(5.5, 6.0))
    }

    private var bookScale: Double {
        0.9 + 0.1 * ramp(3.28, 3.6)
    }

    var body: some View {
        ZStack {
            sheet
                .opacity(sheetOpacity)
                .scaleEffect(sheetScale)
            MiniFinishedBooklet(
                image: images[1],
                pageWidth: pageWidth,
                pageHeight: pageHeight,
                scale: scale
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