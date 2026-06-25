# Oraculo — 产品说明（v0.1）

## 一句话

极简 iOS 应用：每天一句触动人心的短签，主屏与锁屏随时可见。

## 核心体验

| 场景 | 体验 |
| --- | --- |
| 打开 App | 全屏只显示今日一句，无 Tab、无信息流 |
| 主屏小组件 | 小号 / 中号展示今日短签 |
| 锁屏组件 | 条形 / 内联展示今日短签（iOS 16+） |
| 每日更新 | 本地语料库按日期自动换句，午夜切换 |

## 设计原则

1. **界面极简**：全屏纯色 + 居中一句短语，无导航。色系借鉴日本传统色，但不展示色名、不绑定其文化语义。
2. **每日一色**：248 色库按日轮换，与短语独立配对；字色自动浅/深。
3. **字体**：中文 **Songti SC Regular**，英文 Helvetica，见 [DESIGN.md](DESIGN.md)。
4. **离线可用**：语料与色板均打包进 App。
5. **组件同源**：App 与 Widget 共用选句/选色算法与 App Group 缓存。

## v1 范围

### 做

- SwiftUI 主界面
- WidgetKit：主屏 Small / Medium
- 锁屏：Inline + Rectangular
- 内置语料：收集的啡快口令 [starbucks_now_passphrases.csv](../starbucks_now_passphrases.csv)（约 300+ 条，见 [CORPUS.md](CORPUS.md)）
- 小组件 / 共享缓存：按本地日历日稳定选句 + 色（午夜刷新）
- **App 内**：每次进入前台随机换句 + 随机色，背景叠化 + 文字渐隐渐现

### 不做（后续）

- 推送提醒
- iCloud 同步 / 账号
- 用户自定义语料
- 远程语料：静态 manifest 热更新（可选 CDN），见 [CORPUS_REMOTE.md](CORPUS_REMOTE.md)
- iPad 专属布局

## 语料策略

- **当前**：真实收集样本 → `scripts/embed_corpus.py` → `phrases.json`（见 [CORPUS.md](CORPUS.md)）
- **原则**：不生成、不改写；随收集 CSV 增删同步嵌入
- **换句规则**：`hash(yyyy-MM-dd) % 语料数`（Widget）；App 摇一摇/回前台全库随机

## 技术架构

```
Oraculo.app          主应用（SwiftUI）
OraculoWidget.appex  Widget 扩展（WidgetKit）
Shared/              共享：PhraseStore、选句算法、JSON
App Group            group.ai.oraculo.shared
```

## 命名与品牌（待定）

工作目录名 Oraculo；上架名称、图标、中文名可后续定为「今日一句」「日签」等。
