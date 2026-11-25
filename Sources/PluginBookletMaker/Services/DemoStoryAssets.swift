import CoreGraphics
import Foundation
import ImageIO

// MARK: - Demo Artwork

/// 演示绘本使用的插画资源。
///
/// JPEG 随插件一起打包在 `DemoStory` 目录中；这里用 ImageIO 按需解码，
/// 并缓存解码结果，避免 SwiftUI 缩略图反复读盘。
enum DemoStoryAssets {

    private final class ImageCache: @unchecked Sendable {
        private let cache = NSCache<NSString, CGImage>()

        init() {
            cache.countLimit = 24
            cache.totalCostLimit = 96 * 1024 * 1024
        }

        func image(for key: String) -> CGImage? {
            cache.object(forKey: key as NSString)
        }

        func insert(_ image: CGImage, for key: String) {
            cache.setObject(image, forKey: key as NSString, cost: image.bytesPerRow * image.height)
        }
    }

    private static let cache = ImageCache()

    /// 插画的资源地址；资源目录被平铺时也能找到。
    static func url(named name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "jpg", subdirectory: "DemoStory")
            ?? Bundle.module.url(forResource: name, withExtension: "jpg")
    }

    /// 解码完整分辨率的插画，供 PDF 渲染使用。
    static func image(named name: String) -> CGImage? {
        let key = "full:\(name)"
        if let cached = cache.image(for: key) { return cached }

        guard let url = url(named: name),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(
                  source,
                  0,
                  [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
              ) else {
            return nil
        }
        cache.insert(image, for: key)
        return image
    }

    /// 解码限定像素尺寸的缩略图，供示意图与预览使用。
    static func thumbnail(named name: String, maxPixelSize: Int) -> CGImage? {
        let pixelSize = max(64, maxPixelSize)
        let key = "thumb:\(name):\(pixelSize)"
        if let cached = cache.image(for: key) { return cached }

        guard let url = url(named: name),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(
                  source,
                  0,
                  [
                      kCGImageSourceCreateThumbnailFromImageAlways: true,
                      kCGImageSourceCreateThumbnailWithTransform: true,
                      kCGImageSourceThumbnailMaxPixelSize: pixelSize,
                      kCGImageSourceShouldCacheImmediately: true,
                  ] as CFDictionary
              ) else {
            return nil
        }
        cache.insert(image, for: key)
        return image
    }
}