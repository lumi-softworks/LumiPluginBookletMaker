#if os(iOS)
import SwiftUI

/// 首页：一屏列出三个工具，点卡片进入全屏引导。
///
/// 工具的具体操作说明放在引导页，首页只回答「能做什么」，避免一进来
/// 就面对文件选择器。
struct BookletWelcomeView: View {
    @ObservedObject var feature: BookletMakerMobileFeature
    let onChooseTool: (BookletMakerMobileFeature.Tool) -> Void

    @State private var showsFoldShowcase = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // 列宽上限 620 再减页面与卡片各 16pt 内边距，得到插图可用宽度。
                    let illustrationWidth = min(geometry.size.width - 32, 620) - 32

                    toolCard(
                        tool: .booklet,
                        title: BookletLocalization.string("Make a Booklet"),
                        subtitle: BookletLocalization.string(
                            "Reorder pages for folded, double-sided printing."
                        ),
                        illustration: .booklet,
                        illustrationWidth: illustrationWidth
                    )

                    toolCard(
                        tool: .split,
                        title: BookletLocalization.string("Split a PDF"),
                        subtitle: BookletLocalization.string(
                            "Mark page breaks and export separate files."
                        ),
                        illustration: .split,
                        illustrationWidth: illustrationWidth
                    )

                    toolCard(
                        tool: .merge,
                        title: BookletLocalization.string("Merge PDFs"),
                        subtitle: BookletLocalization.string(
                            "Combine several PDFs into one file, in any order."
                        ),
                        illustration: .merge,
                        illustrationWidth: illustrationWidth
                    )

                    if let message = feature.sessionErrorMessage {
                        sessionErrorBanner(message)
                    }
                    Spacer(minLength: 24)
                    privacyNotice
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
        }
        .background(BookletMobileStyle.canvas)
        .fullScreenCover(isPresented: $showsFoldShowcase) {
            BookletFoldShowcaseView(onClose: { showsFoldShowcase = false })
        }
        .navigationTitle(BookletLocalization.string("Booklet Maker"))
        .navigationBarTitleDisplayMode(.inline)
        // 导航栏工具栏由根视图统一挂载（首页与工具页共用 `documentMenu`），
        // 这里不再自带一份，避免同一屏出现两个「更多」菜单。
    }

    private enum Illustration: Equatable {
        case booklet
        case split
        case merge
    }

    private func toolCard(
        tool: BookletMakerMobileFeature.Tool,
        title: String,
        subtitle: String,
        illustration: Illustration,
        illustrationWidth: CGFloat
    ) -> some View {
        Group {
            if illustration == .booklet {
                bookletCard(
                    tool: tool,
                    title: title,
                    subtitle: subtitle,
                    illustrationWidth: illustrationWidth
                )
            } else {
                Button { onChooseTool(tool) } label: {
                    BookletMobileStyle.cardBackground {
                        VStack(alignment: .leading, spacing: 13) {
                            cardHeader(tool: tool, title: title, subtitle: subtitle)

                            BookletFileToolIllustrationView(
                                kind: illustration == .split ? .split : .merge,
                                illustrationWidth: illustrationWidth
                            )
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("welcome.\(tool.rawValue)Tool")
            }
        }
    }

    /// 小册子卡片自带「动效」入口按钮：点它全屏播放折叠演示，
    /// 点标题行或示意图则进入工具。按钮必须是卡片主体的兄弟节点，
    /// 否则会被整卡点击吞掉。
    private func bookletCard(
        tool: BookletMakerMobileFeature.Tool,
        title: String,
        subtitle: String,
        illustrationWidth: CGFloat
    ) -> some View {
        BookletMobileStyle.cardBackground {
            VStack(alignment: .leading, spacing: 13) {
                Button { onChooseTool(tool) } label: {
                    cardHeader(tool: tool, title: title, subtitle: subtitle)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("welcome.\(tool.rawValue)Tool")

                BookletWelcomeWorkflowView(
                    illustrationWidth: illustrationWidth,
                    onShowAnimation: { showsFoldShowcase = true },
                    onOpen: { onChooseTool(tool) }
                )
            }
        }
    }

    private func cardHeader(
        tool: BookletMakerMobileFeature.Tool,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tool.systemImage)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(BookletMobileStyle.accent)
                .frame(width: 46, height: 46)
                .background(BookletMobileStyle.softAccent, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private var privacyNotice: some View {
        Label {
            Text(BookletLocalization.string(
                "Your documents stay on this device. Nothing is uploaded."
            ))
        } icon: {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(BookletMobileStyle.privacyAccent)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func sessionErrorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.subheadline)
            Spacer()
            Button {
                feature.dismissSessionError()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(BookletLocalization.string("Dismiss"))
        }
        .padding(12)
        .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}
#endif
