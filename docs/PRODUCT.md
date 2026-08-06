# Oraculo — 产品说明（v1.0）

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
- 语料源台账：248 条短签 [starbucks_now_passphrases.csv](../starbucks_now_passphrases.csv)；生成 payload 排除 `retired` 内容（见 [CORPUS.md](CORPUS.md)）
- 小组件 / 共享缓存：按本地日历日稳定选句 + 色（午夜刷新）
- **App 内**：每次进入前台随机换句 + 随机色，背景叠化 + 文字渐隐渐现
- 静态语料热更新：HTTPS manifest + SHA256 校验，网络失败时回退内置语料

### 不做（后续）

- 推送提醒
- iCloud 同步 / 账号
- 用户自定义语料
- iPad 专属布局

## 语料策略

- **源台账**：外部观察样本、人工审核后的生成语料和用户提供语料统一保留来源记录。
- **编辑审核**：`config/phrase_editorial_review.json` 为生产取舍和标签的唯一机器可读来源；每个源 ID 必须有显式决定。
- **进入 App**：只嵌入 `decision=keep` 的条目；本次初始审核中所有保留项 lifecycle 统一为 `active`（见 [CORPUS.md](CORPUS.md)）。
- **原则**：来源可信度与内容质量分开判断；短、克制、具体、有关系留白优先，玩梗、口号、训诫和完整结果保证退出主库。
- **换句规则**：`hash(yyyy-MM-dd) % 语料数`（Widget）；App 摇一摇/回前台全库随机

## 技术架构

```
Oraculo.app          主应用（SwiftUI）
OraculoWidget.appex  Widget 扩展（WidgetKit）
Shared/              共享：PhraseStore、选句算法、JSON
App Group            group.ai.oraculo.shared
```

## 命名与品牌

应用名与上架品牌统一为 **Oraculo**。
