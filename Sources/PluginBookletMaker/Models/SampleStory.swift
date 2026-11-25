import Foundation

// MARK: - Sample Story

/// 示意图与内置演示共用的示例故事：共 8 页，内容取自《宋史·司马光传》，
/// 插画复用快易知 Kids 的水墨绘本。8 页正好满足一张 A4 纸的骑马钉拼版。
enum SampleStory {

    /// 示例故事的页数（也是示意图中输出纸张数的两倍）
    static let pageCount = 8

    /// 页面在绘本里的角色
    enum Kind: Sendable {
        case cover
        case story
        case colophon
    }

    /// 一页故事内容
    struct Page: Identifiable, Sendable {
        /// 页码（1-based）
        var id: Int
        /// 页面角色，决定 PDF 与示意图的版式
        let kind: Kind
        /// DemoStory 资源目录中的插画名（不含扩展名）
        let imageName: String
        /// 页面标题
        let title: String
        /// 正文；封面页这一项是副标题
        let body: String
        /// 引文出处，仅末页使用
        var source: String? = nil
        /// 补充注释，仅末页使用
        var note: String? = nil
    }

    /// 封面眉题
    static let coverKicker = "北宋 · 司马光的故事"
    /// 封面署名
    static let coverCredit = "快易知 Kids 经典绘本"
    /// 封面底注，说明这是 BookletMaker 的内置演示
    static let coverFooter = "BookletMaker 演示绘本"

    /// 《司马光砸缸》，共 8 页
    static let pages: [Page] = [
        Page(
            id: 1,
            kind: .cover,
            imageName: "01-cover",
            title: "司马光砸缸",
            body: "一块石头，救回一个小伙伴"
        ),
        Page(
            id: 2,
            kind: .story,
            imageName: "02-children-play",
            title: "群儿戏于庭",
            body: """
            一个晴朗的下午，
            一群孩子在院子里玩耍。
            司马光也在其中。

            院子里有一口大水缸，
            缸里盛满了水，亮晶晶的。
            """
        ),
        Page(
            id: 3,
            kind: .story,
            imageName: "03-climbs-jar",
            title: "一儿登瓮",
            body: """
            有个孩子好奇心起，
            爬上缸沿，探头往里看。

            水缸又高又滑。
            """
        ),
        Page(
            id: 4,
            kind: .story,
            imageName: "04-falls-in",
            title: "足跌没水中",
            body: """
            水缸一晃，倒了。
            孩子脚下一滑，
            跌进水里。

            水花四溅，
            他在水里挣扎。
            """
        ),
        Page(
            id: 5,
            kind: .story,
            imageName: "05-everyone-runs",
            title: "众皆弃去",
            body: """
            孩子们吓坏了，
            四散跑开。

            只有司马光没有跑。
            他在想办法。
            """
        ),
        Page(
            id: 6,
            kind: .story,
            imageName: "06-smash-jar",
            title: "光持石击瓮",
            body: """
            司马光抱起一块大石头，
            用力砸向水缸。

            一下，两下——
            「砰！」
            """
        ),
        Page(
            id: 7,
            kind: .story,
            imageName: "07-child-alive",
            title: "儿得活",
            body: """
            缸破了一个大洞，
            水哗哗地流出来。

            孩子得救了。
            大家都松了一口气。
            """
        ),
        Page(
            id: 8,
            kind: .colophon,
            imageName: "08-original-text",
            title: "原文与出处",
            body: """
            群儿戏于庭，一儿登瓮，足跌没水中。
            众皆弃去，光持石击瓮破之，水迸，儿得活。
            """,
            source: "——《宋史·司马光传》",
            note: """
            「瓮」是大水缸；「迸」是水涌出来的意思。
            后来，人们用「司马光砸缸」形容遇事不慌、机智勇敢。
            """
        ),
    ]

    /// 按页码（1-based）取一页；越界时返回 nil
    static func page(_ number: Int) -> Page? {
        pages.first { $0.id == number }
    }
}