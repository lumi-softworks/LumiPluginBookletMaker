import SwiftUI

// MARK: - Story Page View

/// 故事页视图：按 A5 竖版比例渲染一页示例故事。
///
/// 版式与 `DemoPDFProvider` 共用 `DemoStoryStyle`：顶部插画、下方纸面文字，
/// 小尺寸时只保留标题与页码，避免示意图里挤成一团。
struct StoryPageView: View {
    /// 页码（1-based，对应 SampleStory）
    let pageNumber: Int

    /// 纸张高度（宽度自动按比例计算）
    let height: CGFloat

    /// 内容缩放：控制文字相对纸张的大小
    var textScale: CGFloat = 1.0

    private var width: CGFloat { height * DemoStoryStyle.pageAspectRatio }
    private var artHeight: CGFloat { height * DemoStoryStyle.artHeightRatio }
    private var textHeight: CGFloat { max(0, height - artHeight) }
    private var page: SampleStory.Page? { SampleStory.page(pageNumber) }

    /// 缩略图与整页预览共用的视觉比例
    private var uiScale: CGFloat { max(0.5, min(1, height / 500)) }
    private var showsBody: Bool { textHeight > 200 }
    private var bodyFontSize: CGFloat { min(15.5, max(9, textHeight * 0.06)) * textScale }

    var body: some View {
        ZStack(alignment: .topLeading) {
            DemoStoryPalette.paper.swiftUIColor

            if let page {
                VStack(spacing: 0) {
                    artwork(for: page)
                        .frame(width: width, height: artHeight)
                        .clipped()
                        .overlay(alignment: .bottom) {
                            LinearGradient(
                                colors: [
                                    DemoStoryPalette.paper.swiftUIColor.opacity(0),
                                    DemoStoryPalette.paper.swiftUIColor,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: max(2, artHeight * 0.09))
                        }

                    textPanel(for: page)
                        .frame(width: width, height: textHeight, alignment: .topLeading)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(
                    DemoStoryPalette.hairline.swiftUIColor.opacity(0.85),
                    lineWidth: 0.7
                )
        }
        .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
    }

    // MARK: - Artwork

    @ViewBuilder
    private func artwork(for page: SampleStory.Page) -> some View {
        if let image = DemoStoryAssets.thumbnail(
            named: page.imageName,
            maxPixelSize: Int(max(240, height * 3))
        ) {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
        } else {
            DemoStoryPalette.artPlaceholder.swiftUIColor
        }
    }

    // MARK: - Text panels

    @ViewBuilder
    private func textPanel(for page: SampleStory.Page) -> some View {
        switch page.kind {
        case .cover:
            coverPanel(page)
        case .story:
            storyPanel(page)
        case .colophon:
            colophonPanel(page)
        }
    }

    private func coverPanel(_ page: SampleStory.Page) -> some View {
        let compact = textHeight < 120

        return VStack(spacing: 0) {
            if !compact {
                Text(SampleStory.coverKicker)
                    .font(demoFont(
                        DemoStoryStyle.bodyMediumFontName,
                        size: max(4, 11 * uiScale),
                        weight: .medium
                    ))
                    .tracking(max(0.5, 2.6 * uiScale))
                    .foregroundColor(DemoStoryPalette.accent.swiftUIColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Text(page.title)
                .font(demoFont(
                    DemoStoryStyle.titleFontName,
                    size: max(10, 40 * uiScale),
                    weight: .semibold,
                    design: .serif
                ))
                .tracking(max(0.5, 3 * uiScale))
                .foregroundColor(DemoStoryPalette.ink.swiftUIColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, compact ? 0 : max(2, 6 * uiScale))

            Text(page.body)
                .font(demoFont(
                    DemoStoryStyle.bodyFontName,
                    size: max(4, 13 * uiScale),
                    weight: .regular
                ))
                .foregroundColor(DemoStoryPalette.bodyInk.swiftUIColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, max(2, 4 * uiScale))

            if !compact {
                Rectangle()
                    .fill(DemoStoryPalette.accent.swiftUIColor.opacity(0.55))
                    .frame(width: max(20, 90 * uiScale), height: 0.7)
                    .padding(.top, max(4, 10 * uiScale))

                Text(SampleStory.coverCredit)
                    .font(demoFont(
                        DemoStoryStyle.bodyFontName,
                        size: max(3.5, 9.5 * uiScale),
                        weight: .regular
                    ))
                    .foregroundColor(DemoStoryPalette.mutedInk.swiftUIColor)
                    .lineLimit(1)
                    .padding(.top, max(3, 8 * uiScale))
            }

            Spacer(minLength: 0)

            if !compact {
                Text(SampleStory.coverFooter)
                    .font(demoFont(
                        DemoStoryStyle.bodyMediumFontName,
                        size: max(3.5, 8.5 * uiScale),
                        weight: .medium
                    ))
                    .tracking(max(0.3, 1.2 * uiScale))
                    .foregroundColor(DemoStoryPalette.accent.swiftUIColor)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, width * 0.08)
        .padding(.top, max(3, textHeight * 0.06))
        .padding(.bottom, max(3, textHeight * 0.06))
    }

    private func storyPanel(_ page: SampleStory.Page) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(page.title)
                .font(demoFont(
                    DemoStoryStyle.titleFontName,
                    size: max(6, 22 * uiScale),
                    weight: .semibold,
                    design: .serif
                ))
                .tracking(max(0.3, 1.2 * uiScale))
                .foregroundColor(DemoStoryPalette.ink.swiftUIColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Rectangle()
                .fill(DemoStoryPalette.accent.swiftUIColor)
                .frame(width: max(10, 26 * uiScale), height: max(0.8, 1.6 * uiScale))
                .padding(.top, max(2, 4 * uiScale))

            if showsBody {
                Text(page.body)
                    .font(demoFont(
                        DemoStoryStyle.bodyFontName,
                        size: max(5, bodyFontSize),
                        weight: .regular
                    ))
                    .foregroundColor(DemoStoryPalette.bodyInk.swiftUIColor)
                    .lineSpacing(max(0.5, 2 * uiScale))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, max(3, 6 * uiScale))
            }

            Spacer(minLength: 0)

            HStack {
                Spacer(minLength: 0)
                pageBadge
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, width * 0.085)
        .padding(.top, max(3, textHeight * 0.09))
        .padding(.bottom, max(3, textHeight * 0.06))
    }

    private func colophonPanel(_ page: SampleStory.Page) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(page.title)
                .font(demoFont(
                    DemoStoryStyle.titleFontName,
                    size: max(6, 22 * uiScale),
                    weight: .semibold,
                    design: .serif
                ))
                .tracking(max(0.3, 1.2 * uiScale))
                .foregroundColor(DemoStoryPalette.ink.swiftUIColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Rectangle()
                .fill(DemoStoryPalette.accent.swiftUIColor)
                .frame(width: max(10, 26 * uiScale), height: max(0.8, 1.6 * uiScale))
                .padding(.top, max(2, 4 * uiScale))

            if textHeight > 180 {
                VStack(alignment: .leading, spacing: max(2, 4 * uiScale)) {
                    Text(page.body)
                        .font(demoFont(
                            DemoStoryStyle.quoteFontName,
                            size: max(5, 12.5 * uiScale),
                            weight: .regular,
                            design: .serif
                        ))
                        .foregroundColor(DemoStoryPalette.ink.swiftUIColor)
                        .lineSpacing(max(0.5, 1.5 * uiScale))
                        .fixedSize(horizontal: false, vertical: true)

                    if let source = page.source {
                        Text(source)
                            .font(demoFont(
                                DemoStoryStyle.bodyFontName,
                                size: max(4, 9.5 * uiScale),
                                weight: .regular
                            ))
                            .foregroundColor(DemoStoryPalette.mutedInk.swiftUIColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(max(4, 8 * uiScale))
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DemoStoryPalette.paperShade.swiftUIColor)
                )
                .padding(.top, max(4, 8 * uiScale))

                if let note = page.note {
                    Text(note)
                        .font(demoFont(
                            DemoStoryStyle.bodyFontName,
                            size: max(4, 10.5 * uiScale),
                            weight: .regular
                        ))
                        .foregroundColor(DemoStoryPalette.bodyInk.swiftUIColor)
                        .lineSpacing(max(0.5, 1.5 * uiScale))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, max(4, 8 * uiScale))
                }
            }

            Spacer(minLength: 0)

            HStack {
                Spacer(minLength: 0)
                pageBadge
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, width * 0.085)
        .padding(.top, max(3, textHeight * 0.09))
        .padding(.bottom, max(3, textHeight * 0.06))
    }

    private var pageBadge: some View {
        Text("\(pageNumber)")
            .font(demoFont(
                DemoStoryStyle.bodyMediumFontName,
                size: max(3.5, 8.5 * uiScale),
                weight: .medium
            ))
            .foregroundColor(DemoStoryPalette.accent.swiftUIColor)
            .frame(
                width: max(10, 19 * uiScale),
                height: max(10, 19 * uiScale)
            )
            .overlay {
                Circle()
                    .strokeBorder(
                        DemoStoryPalette.hairline.swiftUIColor,
                        lineWidth: 0.6
                    )
            }
    }

    // MARK: - Fonts

    private func demoFont(_ name: String?,
                          size: CGFloat,
                          weight: Font.Weight,
                          design: Font.Design = .default) -> Font {
        if let name {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: design)
    }
}

// MARK: - Palette bridge

private extension DemoStoryRGB {
    var swiftUIColor: Color {
        #if canImport(AppKit)
        Color(nsColor: color())
        #elseif canImport(UIKit)
        Color(uiColor: color())
        #endif
    }
}

// MARK: - Preview

#Preview("Story Pages") {
    LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4),
        spacing: 14
    ) {
        ForEach(SampleStory.pages) { page in
            StoryPageView(pageNumber: page.id, height: 210)
        }
    }
    .padding()
    .frame(width: 780)
}

#Preview("Full Page") {
    HStack(spacing: 18) {
        StoryPageView(pageNumber: 1, height: 500)
        StoryPageView(pageNumber: 6, height: 500)
        StoryPageView(pageNumber: 8, height: 500)
    }
    .padding()
}