# Oraculo 视觉规范

参考 [NIPPON COLORS](https://nipponcolors.com/#nakabeni)（小野寺拓美设计）：**纯色铺满 + 传统色名 + 克制动效**。

## 品牌

- 应用名：**Oraculo**
- 最低系统：**iOS 17**
- 界面：无导航、无卡片，仅颜色 + 文字

## 色彩

- 数据源：`ios/Shared/Resources/nippon_colors.json`（248 色，来自 [lcat/nippon-colors](https://github.com/lcat/nippon-colors)，与官网一致）
- 每日一色：`stableIndex(dayKey + "|color")`，与「每日一句」独立，避免同序配对
- 代表色：**中紅 nakabeni** `#DB4D6D`（官网锚点色）
- 字色：按背景自动 `light` / `dark`（对比度筛选）

## 字体

- 中文：**Songti SC Regular**（`STSongti-SC-Regular`，系统宋体-简，衬线）
- 英文与数字：**Helvetica**（按字符与中文混排）
- 实现：`OraculoTypography.styledText` / `phraseText` / `metaText`

## 动效（对齐 nipponcolors.com 气质）

| 动效 | 说明 |
| --- | --- |
| 冷启动 | 首帧文案透明 → 随机句/色 **仅淡入**（避免先显示今日句再淡出） |
| 再次进入前台 / 摇一摇 | 背景 **2s ease-in**；中文 **1.5s opacity 渐隐** → **2.5s 横向扫字出现**（自左向右，`ease-out`）；英文 **约 0.99s 淡出 → 2.5s 淡入**，同 [nipponcolors.com](https://nipponcolors.com/) |
| 午夜 | Widget / 共享缓存仍用「今日」固定句 + 色（`DailyOracleService`） |
| 背景呼吸 | 底部径向光晕约 5.2s（吸短呼长），透明度约 1%～3%，无全屏明暗 |
| 主屏布局 | **方案 A**：主句约屏高 38%、中文 **40pt** + 英文 **15pt**；**实时时钟** 按**单 digit** 上下滑 **3s**（离场快、入场缓出）、秒每 **5s** 跳格 |

App 内每次进入前台都会 `refreshOnOpen()`；**摇一摇**触发同款换句换色（`refreshOnShake`）；小组件不受随机影响。

## 组件

- 主 App：全屏 `NipponAmbienceView` + 居中短语
- 主屏 Widget：`containerBackground` 铺满当日色
- 锁屏 Inline：仅短语（系统限制）
- 锁屏 Rectangular：短语 + 色名/HEX，半透明底色

## 可选后续

- [ ] 点击屏幕 crossfade 预览「明日」色（仅 App 内）
- [ ] 自定义字体 bundle
- [ ] 深色模式下锁定 light/dark 字色逻辑复核
