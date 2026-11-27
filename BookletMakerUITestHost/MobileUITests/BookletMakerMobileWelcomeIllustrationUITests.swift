import XCTest

/// 首页「制作小册子」卡片内的流程示意图。
///
/// 卡片目前由两部分组成：标题行（`welcome.bookletTool`）与示意图。
/// 示意图右上角的「动效」按钮把折叠演示铺满全屏（`booklet.showcase.*`），
/// 按钮必须独立可点，不能被卡片主体的点击吞掉；点示意图本身则进入工具页。
final class BookletMakerMobileWelcomeIllustrationUITests: BookletMakerMobileUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        XCTAssertTrue(
            element("welcome.bookletTool").waitForExistence(timeout: 20),
            "首页未出现。\(app.debugDescription)"
        )
    }

    /// 点「动效」打开全屏演示，点「关闭」回到首页。
    func testShowcaseButtonOpensFullScreenAndCloses() {
        let open = element("welcome.bookletShowcase")
        XCTAssertTrue(open.waitForExistence(timeout: 10), app.debugDescription)

        open.tap()
        let close = element("booklet.showcase.close")
        XCTAssertTrue(close.waitForExistence(timeout: 10), "未打开全屏折叠演示。\(app.debugDescription)")
        XCTAssertTrue(
            element("booklet.showcase.text").exists,
            "全屏演示缺少说明文字。\(app.debugDescription)"
        )

        close.tap()
        XCTAssertTrue(
            waitForDisappearance(of: close),
            "关闭后全屏演示仍在。\(app.debugDescription)"
        )
        XCTAssertTrue(
            element("welcome.bookletTool").exists,
            "关闭后应回到首页。\(app.debugDescription)"
        )
    }

    /// 动画确实在跑：折叠中、折好、翻开封面这三帧内容各不相同。
    ///
    /// 若 TimelineView 没有驱动，截图会完全一致；订书钉与跨页是最后
    /// 两拍的画面，第三张截图落在大约 5 秒处（封面翻开、露出 2/7 跨页）。
    func testShowcaseRendersMovingFrames() {
        let open = element("welcome.bookletShowcase")
        XCTAssertTrue(open.waitForExistence(timeout: 10), app.debugDescription)
        open.tap()
        XCTAssertTrue(
            element("booklet.showcase.close").waitForExistence(timeout: 10),
            app.debugDescription
        )

        Thread.sleep(forTimeInterval: 1.5)
        let midFold = XCUIScreen.main.screenshot()
        Thread.sleep(forTimeInterval: 1.1)
        let folded = XCUIScreen.main.screenshot()
        Thread.sleep(forTimeInterval: 2.0)
        let opened = XCUIScreen.main.screenshot()

        XCTAssertNotEqual(
            midFold.pngRepresentation,
            folded.pngRepresentation,
            "全屏演示的画面在持续时间内没有变化。"
        )
        XCTAssertNotEqual(
            folded.pngRepresentation,
            opened.pngRepresentation,
            "折好后的画面没有继续演进到翻开封面。"
        )

        let shots = [
            ("showcase-folding", midFold),
            ("showcase-stapled", folded),
            ("showcase-open", opened),
        ]
        for (name, shot) in shots {
            let attachment = XCTAttachment(image: shot.image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    /// 点示意图主体（非标题行、非「动效」按钮）进入小册子引导页。
    func testTappingIllustrationOpensTool() {
        let open = element("welcome.bookletShowcase")
        XCTAssertTrue(open.waitForExistence(timeout: 10), app.debugDescription)

        // 示意图被 `accessibilityHidden(true)` 隐藏（内部全是装饰性小字），
        // 只能按坐标点击：按钮正下方即示意图中段。
        let screen = app.windows.firstMatch
        let target = screen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: open.frame.maxY + 45))
        target.tap()

        // 引导页是 push 出来的，首页仍留在导航栈里（AX 树中可见但不可点），
        // 因此这里只断言目标页出现，不断言首页消失。
        XCTAssertTrue(
            element("guide.next").waitForExistence(timeout: 10),
            "点示意图后未进入小册子引导页。\(app.debugDescription)"
        )
    }

    private func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}