import CoreGraphics
import Foundation

#if canImport(AppKit)
import AppKit
typealias DemoStoryFont = NSFont
typealias DemoStoryColor = NSColor
#elseif canImport(UIKit)
import UIKit
typealias DemoStoryFont = UIFont
typealias DemoStoryColor = UIColor
#endif

// MARK: - Story Style

/// 内置演示绘本的共享版式。
///
/// PDF 渲染和 SwiftUI 预览都从这里取尺寸、颜色与字体，避免两套版式
/// 随时间漂移。所有值都是不可变的，可在任意线程读取。
enum DemoStoryStyle {

    // MARK: Page

    /// A5 竖版，单位 pt
    static let pageSize = CGSize(width: 420, height: 595)
    /// 顶部插画带高度
    static let artHeight: CGFloat = 280
    /// 正文左右留白
    static let sideMargin: CGFloat = 36
    /// 插画与文字的分界线
    static var dividerY: CGFloat { pageSize.height - artHeight }
    /// 正文可用宽度
    static var contentWidth: CGFloat { pageSize.width - sideMargin * 2 }
    /// 宽高比，供 SwiftUI 保持纸张比例
    static var pageAspectRatio: CGFloat { pageSize.width / pageSize.height }
    /// 插画带占整页的比例
    static var artHeightRatio: CGFloat { artHeight / pageSize.height }

    // MARK: Fonts

    /// 标题字体（楷体加粗）；机器上没有楷体时回退到系统半粗体
    static func titleFont(size: CGFloat) -> DemoStoryFont {
        font(named: titleFontName, size: size, weight: .semibold)
    }

    /// 正文与说明字体（苹方）
    static func bodyFont(size: CGFloat) -> DemoStoryFont {
        font(named: bodyFontName, size: size, weight: .regular)
    }

    /// 正文强调字体（苹方中等）
    static func bodyMediumFont(size: CGFloat) -> DemoStoryFont {
        font(named: bodyMediumFontName, size: size, weight: .medium)
    }

    /// 引文字体（楷体常规）
    static func quoteFont(size: CGFloat) -> DemoStoryFont {
        font(named: quoteFontName, size: size, weight: .regular)
    }

    /// 供 SwiftUI 的 `Font.custom` 使用；返回 nil 时调用方回退到系统字体
    static let titleFontName = resolvedFontName(candidates: [
        "Kaiti SC Bold", "STKaitiSC-Bold", "KaitiSC-Bold",
        "Kaiti SC", "STKaitiSC-Regular", "STKaiti",
    ])
    static let bodyFontName = resolvedFontName(candidates: [
        "PingFang SC", "PingFangSC-Regular", "Hiragino Sans GB",
    ])
    static let bodyMediumFontName = resolvedFontName(candidates: [
        "PingFang SC Medium", "PingFangSC-Medium", "PingFang SC", "PingFangSC-Regular",
    ])
    static let quoteFontName = resolvedFontName(candidates: [
        "Kaiti SC", "STKaitiSC-Regular", "STKaiti",
    ])

    private static func resolvedFontName(candidates: [String]) -> String? {
        for name in candidates {
            if let font = DemoStoryFont(name: name, size: 12) {
                return font.fontName
            }
        }
        return nil
    }

    private static func font(named name: String?,
                             size: CGFloat,
                             weight: DemoStoryFont.Weight) -> DemoStoryFont {
        if let name, let font = DemoStoryFont(name: name, size: size) {
            return font
        }
        return DemoStoryFont.systemFont(ofSize: size, weight: weight)
    }
}

// MARK: - Palette

/// 水墨绘本的纸张与墨色，使用 sRGB 分量存储以保持线程安全。
struct DemoStoryRGB: Sendable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    func cgColor(alpha: CGFloat = 1) -> CGColor {
        CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }

    func color(alpha: CGFloat = 1) -> DemoStoryColor {
        DemoStoryColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}

enum DemoStoryPalette {
    /// 纸色
    static let paper = DemoStoryRGB(red: 0.980, green: 0.965, blue: 0.933)
    /// 引文底纹
    static let paperShade = DemoStoryRGB(red: 0.953, green: 0.922, blue: 0.867)
    /// 标题墨色
    static let ink = DemoStoryRGB(red: 0.184, green: 0.165, blue: 0.141)
    /// 正文墨色
    static let bodyInk = DemoStoryRGB(red: 0.286, green: 0.263, blue: 0.235)
    /// 次级文字
    static let mutedInk = DemoStoryRGB(red: 0.420, green: 0.392, blue: 0.357)
    /// 细线
    static let hairline = DemoStoryRGB(red: 0.851, green: 0.788, blue: 0.659)
    /// 金色点缀
    static let accent = DemoStoryRGB(red: 0.690, green: 0.541, blue: 0.310)
    /// 印章
    static let seal = DemoStoryRGB(red: 0.702, green: 0.227, blue: 0.169)
    /// 插画缺失时的占位底色
    static let artPlaceholder = DemoStoryRGB(red: 0.910, green: 0.863, blue: 0.784)
}