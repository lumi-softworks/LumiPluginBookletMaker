import XCTest

/// 首页「制作小册子」卡片内的流程示意图。
///
/// 卡片目前由两部分组成：标题行（`welcome.bookletTool`）与示意图。
/// 示意图自带「动效 / 静态」切换按钮，两者是兄弟节点——切换按钮必须
/// 独立可点，不能被卡片主体的点击吞掉；点示意图本身又应该进入工具页。
final class BookletMakerMobileWelcomeIllustrationUITests: BookletMakerMobileUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        XCTAssertTrue(
            element("welcome.bookletTool").waitForExistence(timeout: 20),
            "首页未出现。\(app.debugDescription)"
        )
    }

    /// 切换按钮在两种形态之间往返，且始终可点。
    ///
    /// 回归重点：卡片曾经是整卡 Button，切换按钮嵌在其中会被整卡点击
    /// 吞掉（点「动效」直接进入工具页）。这里连续切换两次，确认第二次
    /// 仍停留在首页。
    func testModeToggleSwitchesBetweenStaticAndAnimated() {
        let toggle = element("welcome.bookletMode")
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(toggle.label, "Show fold animation")

        toggle.tap()
        XCTAssertTrue(
            waitForLabel("Show static steps", on: toggle),
            "点击后未进入动效形态。\(app.debugDescription)"
        )
        XCTAssertTrue(
            element("welcome.bookletTool").exists,
            "切换动效后应仍停留在首页。\(app.debugDescription)"
        )

        toggle.tap()
        XCTAssertTrue(
            waitForLabel("Show fold animation", on: toggle),
            "再次点击后未回到静态形态。\(app.debugDescription)"
        )
    }

    /// 动画确实在跑：进入动效形态 1.6 秒后画面发生变化。
    ///
    /// 折叠动效的起始帧与 1.6 秒处（折叠角约 90°）帧内容不同；
    /// 若 TimelineView 没有驱动，两张截图会完全一致。
    func testAnimatedModeRendersMovingFrames() {
        let toggle = element("welcome.bookletMode")
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), app.debugDescription)

        toggle.tap()
        XCTAssertTrue(waitForLabel("Show static steps", on: toggle), app.debugDescription)

        Thread.sleep(forTimeInterval: 1.5)
        let midFold = XCUIScreen.main.screenshot()
        Thread.sleep(forTimeInterval: 1.1)
        let second = XCUIScreen.main.screenshot()

        XCTAssertNotEqual(
            midFold.pngRepresentation,
            second.pngRepresentation,
            "动效形态的画面在持续时间内没有变化。"
        )

        for (name, shot) in [("welcome-animated-folding", midFold), ("welcome-animated-folded", second)] {
            let attachment = XCTAttachment(image: shot.image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    /// 点示意图主体（非标题行、非切换按钮）进入小册子引导页。
    func testTappingIllustrationOpensTool() {
        let toggle = element("welcome.bookletMode")
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), app.debugDescription)

        // 示意图被 `accessibilityHidden(true)` 隐藏（内部全是装饰性小字），
        // 只能按坐标点击：切换按钮正下方即示意图中段。
        let screen = app.windows.firstMatch
        let target = screen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: toggle.frame.maxY + 45))
        target.tap()

        // 引导页是 push 出来的，首页仍留在导航栈里（AX 树中可见但不可点），
        // 因此这里只断言目标页出现，不断言首页消失。
        XCTAssertTrue(
            element("guide.next").waitForExistence(timeout: 10),
            "点示意图后未进入小册子引导页。\(app.debugDescription)"
        )
    }

    private func waitForLabel(_ expected: String, on element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: 5) == .completed
    }
}