# BookletMaker 内置演示绘本 · 文本定稿

- 故事：司马光砸缸（《宋史·司马光传》）
- 素材：快易知 Kids《司马光砸缸》（编号 92）现有水墨插画，仅用于 BookletMaker 应用内演示
- 规格：A5 竖版 420×595pt，8 页，上图下文
- 状态：已接入 `SampleStory` / `DemoPDFProvider` / `DemoStoryStyle` / `DemoStoryAssets` / `StoryPageView`；插件测试通过

## 一、封面

| 字段 | 文案 |
| --- | --- |
| 眉题 | 北宋 · 司马光的故事 |
| 书名 | 司马光砸缸 |
| 副标 | 一块石头，救回一个小伙伴 |
| 署名 | 快易知 Kids 经典绘本 |
| 底部小字 | BookletMaker 演示绘本 |

## 二、内页文本

### 第 2 页 · 群儿戏于庭

> 一个晴朗的下午，
> 一群孩子在院子里玩耍。
> 司马光也在其中。
>
> 院子里有一口大水缸，
> 缸里盛满了水，亮晶晶的。

### 第 3 页 · 一儿登瓮

> 有个孩子好奇心起，
> 爬上缸沿，探头往里看。
>
> 水缸又高又滑。

### 第 4 页 · 足跌没水中

> 水缸一晃，倒了。
> 孩子脚下一滑，
> 跌进水里。
>
> 水花四溅，
> 他在水里挣扎。

### 第 5 页 · 众皆弃去

> 孩子们吓坏了，
> 四散跑开。
>
> 只有司马光没有跑。
> 他在想办法。

### 第 6 页 · 光持石击瓮

> 司马光抱起一块大石头，
> 用力砸向水缸。
>
> 一下，两下——
> 「砰！」

### 第 7 页 · 儿得活

> 缸破了一个大洞，
> 水哗哗地流出来。
>
> 孩子得救了。
> 大家都松了一口气。

### 第 8 页 · 原文与出处

> 群儿戏于庭，一儿登瓮，足跌没水中。
> 众皆弃去，光持石击瓮破之，水迸，儿得活。
> ——《宋史·司马光传》
>
> 「瓮」是大水缸；「迸」是水涌出来的意思。
> 后来，人们用「司马光砸缸」形容遇事不慌、机智勇敢。

## 三、版式参数

| 项目 | 数值 |
| --- | --- |
| 页面 | 420 × 595pt（A5 竖版） |
| 图区 | 顶部 420 × 280pt（3:2，不裁切） |
| 文字区 | 420 × 315pt |
| 左右边距 | 36pt |
| 标题 | 22pt，楷体/宋体 Semibold，墨色 |
| 正文 | 15.5pt，PingFang SC，行高 27pt |
| 页码 | 20pt 圆章，底部居中，距底 26pt |
| 纸面 | `#FAF6EE` |
| 墨色 | `#2F2A24` |
| 分隔线 | `#D9C9A8`，1pt |
| 点缀色 | `#B08A4F` |
| 印章 | `#B33A2B`，34 × 34pt |

第 8 页单独排版：原文 14pt 楷体，注释 12pt PingFang SC，行高 24pt。

## 四、图片清单

目录：`Resources/DemoStory/`，均为 1536×1024、sRGB JPEG、q88。

| 演示页 | 文件 | Kids 源页 |
| --- | --- | --- |
| 1 | `01-cover.jpg` | `cover.png` |
| 2 | `02-children-play.jpg` | `04-children-play.png` |
| 3 | `03-climbs-jar.jpg` | `05-climbs-the-jar.png` |
| 4 | `04-falls-in.jpg` | `06-falls-in.png` |
| 5 | `05-everyone-runs.jpg` | `07-everyone-runs.png` |
| 6 | `06-smash-jar.jpg` | `08-smash-the-jar.png` |
| 7 | `07-child-alive.jpg` | `09-child-alive.png` |
| 8 | `08-original-text.jpg` | `11-original-text.png` |

源地址前缀：`https://s.kuaiyizhi.cn/kids/zh-cn/stories/92-simaguang-za-gang/`

## 五、素材取舍说明

- 选用 92《司马光砸缸》的 8 张图：蓝衣少年在封面、庭院、砸缸、救人各页形象一致。
- 未选 01–03 的成年司马光读书页，避免 8 页里出现两条人物线；成年形象留作将来长版再用。
- 已检查 8 张图：无 AI 水印、无画面内文字、无烧伤/惊悚元素，适合儿童。
- 对比结论：91《凿壁偷光》主角在 8 张图里有少年/偏女性/成年男性三种形象，未采用；其压缩素材保留在 `/tmp`，可随时恢复。

## 六、验收清单

- [x] 8 张图全部存在，尺寸 1536×1024，总量 < 3MB（2.2MB）
- [x] 每页正文在 A5 文字区内不溢出（8 页已渲染检查）
- [x] 封面、内页、末页由 `DemoPDFProvider` 统一绘制，`StoryPageView` 复用 `DemoStoryStyle`
- [x] 缩略图高度 140pt 时，页码与标题仍可辨认（已用 ImageRenderer 渲染检查）
- [ ] A4 双面打印、对折后页码顺序正确
- [x] 旧缓存不复用（PDF 文件名升到 `sample-story-v3.pdf`，并校验 420×595）
- [x] PDF 元数据：标题、作者、主题

## 七、代码落点

| 文件 | 职责 |
| --- | --- |
| `Sources/PluginBookletMaker/Models/SampleStory.swift` | 8 页文案、页面类型、插画名 |
| `Sources/PluginBookletMaker/Services/DemoStoryStyle.swift` | A5 尺寸、插画带高度、纸色墨色、字体回退 |
| `Sources/PluginBookletMaker/Services/DemoStoryAssets.swift` | `DemoStory` JPEG 的 ImageIO 解码与缓存 |
| `Sources/PluginBookletMaker/Services/DemoPDFProvider.swift` | 运行时生成 `sample-story-v3.pdf`，含封面/内页/末页版式 |
| `Sources/PluginBookletMaker/Views/ExplanationDiagrams/StoryPageView.swift` | SwiftUI 版式镜像，小尺寸自动收起正文 |
| `Package.swift` | `.copy("../../Resources/DemoStory")` 打包插画 |