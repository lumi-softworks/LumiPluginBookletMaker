#if os(iOS)
import Combine
import ProviderToolbar
import SwiftUI

/// 移动端整页：插件自己持有业务会话，并把宿主 / 其他插件贡献到
/// `IOSNavigationBarProviding` 的导航栏项（如设置齿轮）挂到页面自己的导航栈上。
///
/// 页面内部创建了 `NavigationStack`，外层的 `.toolbar` 不会被传进来，
/// 所以导航栏贡献必须由页面自己挂载。
@MainActor
struct BookletMakerMobilePage: View {
    let feature: BookletMakerMobileFeature
    @StateObject private var navigationItems: MobileNavigationItemsBridge

    init(feature: BookletMakerMobileFeature, navigationBar: (any IOSNavigationBarProviding)?) {
        self.feature = feature
        _navigationItems = StateObject(
            wrappedValue: MobileNavigationItemsBridge(provider: navigationBar)
        )
    }

    var body: some View {
        BookletMakerMobileRootView(
            feature: feature,
            trailingToolbarItems: navigationItems.items
        )
    }
}

@MainActor
private final class MobileNavigationItemsBridge: ObservableObject {
    private let provider: (any IOSNavigationBarProviding)?
    private var observation: AnyCancellable?

    init(provider: (any IOSNavigationBarProviding)?) {
        self.provider = provider
        observation = provider?.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var items: [AnyView] {
        (provider?.visibleNavigationBarItems ?? [])
            .sorted { lhs, rhs in
                lhs.order == rhs.order ? lhs.id < rhs.id : lhs.order < rhs.order
            }
            .map { $0.makeView() }
    }
}
#endif