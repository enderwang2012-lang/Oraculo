# 情境标签与加权下发

> **产品定案（已实现 v1）**
>
> 1. **通用库**：`dispatch.universal: true` 的语料全年进入候选池，保证长期可随机抽到。  
> 2. **季节硬排除**：字面绑定某一季的语料用 `onlyWhen: ["season:…"]` + `universal: false`；**非春天句在其他季节照常出现**；**明确春天的句在其他季节权重为 0（不参与抽样）**。  
> 3. **Widget 与摇一摇**：共用 `PhraseDispatchScorer` + `PhrasePicker`；仅种子不同（Widget：`dayKey|情境指纹`；摇一摇：再加 `shake|UUID`）。  
> 4. **全维度**：季节、月、星期、时段、节日、**二十四节气**（`solar_terms_cn.json`）、天气（Open-Meteo）、**GPS 精确定位**（CoreLocation → 大区/网格/海拔 + 联动天气）、Locale；Widget 读 App Group 缓存，主 App 前台拉定位与天气。

## 1. 你要解决什么

当前 App（v1 前）：**304 条口令均匀随机**（摇一摇 / 回前台），与「今天是什么日子、什么天气、在哪里」无关。

目标：

- 每条语料带**多维情境标签**；
- 下发时根据**当前情境向量**做**加权抽样**（不是硬过滤成只剩 3 条）；
- 像「岁岁常欢愉」：**全年可出**（`universal`），但**春节窗口大幅加权**；
- 像「春日暖阳」类：**春天 / 三月 / 晴日** 加权，冬天几乎不出。

一句话：**通用池保底 + 情境池加分**。

---

## 2. 标签体系（建议维度）

分三层，避免一开始维度过散。

### 2.1 时间层（必做，可全自动）

| 维度 ID | 说明 | 取值示例 |
| --- | --- | --- |
| `universal` | 无季节/节日强绑定，全年兜底 | `true` |
| `season` | 气象季（北半球） | `spring` `summer` `autumn` `winter` |
| `month` | 公历月 | `1`…`12` |
| `solar_term` | 二十四节气（可选，细于 season） | `lichun` `qingming` `dongzhi` … |
| `weekday` | 星期 | `mon`…`sun` |
| `day_part` | 时段 | `morning` `noon` `evening` `late_night` |
| `festival` | 节日（农历/公历统一映射到节日 ID） | `spring_festival` `mid_autumn` `national_day` `valentine` `christmas` … |
| `festival_window` | 节日前后缓冲 | `spring_festival:pre_7d` `spring_festival:day_0` `spring_festival:post_15d` |

节日窗口建议用**配置表**（每年公历日期不同，用农历库或国务院放假安排表换算）。

### 2.2 环境层（建议二期，部分可接 API）

| 维度 ID | 说明 | 取值示例 |
| --- | --- | --- |
| `weather` | 粗粒度天气 | `clear` `cloudy` `rain` `snow` `fog` `windy` `heat` `cold` |
| `temp_band` | 体感温度档 | `freezing` `cold` `mild` `warm` `hot` |
| `precip` | 是否降水 | `none` `light` `heavy` |

数据源：WeatherKit / 用户手动城市 + 缓存（无需精确到街道）。

### 2.3 空间层（三期或「粗粒度」）

| 维度 ID | 说明 | 取值示例 |
| --- | --- | --- |
| `geo_region` | 大区（不存精确 GPS） | `north` `south` `east` `west` `coastal` `inland` |
| `geo_climate` | 气候带 | `humid_subtropical` `continental` `plateau` `tropical` |
| `altitude_band` | 海拔档（粗） | `sea_level` `low_hill` `plateau_1000+` `high_3000+` |

说明：海拔/精确位置敏感，建议默认**不用 GPS**，仅用：

- 用户可选「常驻城市」→ 查表得 `geo_region` + `altitude_band`；或
- 系统 `Locale` / 时区作极粗 fallback。

### 2.4 内容层（与现有字段衔接）

| 维度 ID | 说明 | 来源 |
| --- | --- | --- |
| `emotion` | 情绪功能（已有 `theme` / `emotionTheme`） | CSV `theme` → slug |
| `tone` | 玩梗 / 文艺 / 励志 / 治愈… | 标注或规则 |
| `ip` | 联名/IP | `哈利波特` `mayday` `jaychou` `marvel` … |
| `lang` | 语言形态 | `zh` `en` `mixed` |
| `length_band` | 字数档（UI 换行） | `short_4_6` `medium_7_9` `long_10+` |

### 2.5 下发策略层（每条语料必有）

| 字段 | 含义 |
| --- | --- |
| `dispatch_mode` | `universal`：全年均匀参与；`boost`：匹配则加权，不匹配仍可出现；`exclusive`：仅匹配时出现 |
| `boost_tags` | 匹配时乘数作用的标签列表 |
| `boost_weight` | 建议 2.0–8.0，春节强相关可用 5+ |

**默认原则（已定案）**：约 292/304 条为 `universal: true`；12 条季节字面句 `onlyWhen` 硬门槛（见 `scripts/phrase_dispatch.json`）。节日/天气多为 `boost`，不阻止其他季节出现。

### 实现映射（代码）

| 概念 | JSON 字段 | Swift |
| --- | --- | --- |
| 通用库 | `universal: true` | `PhraseDispatchScorer.universalBaseWeight` |
| 季节独占 | `onlyWhen: ["season:spring"]` | 不匹配 → `score == 0` |
| 情境加分 | `boost: [{tag, weight}]` | 命中 `activeTags` 时累加 |
| 情境快照 | — | `ContextSnapshotBuilder.snapshot` |
| 天气 | Open-Meteo | `OpenMeteoWeatherService` → `WeatherContextCache` |
| 节日表 | `festivals_cn.json` | `FestivalCalendar` |
| 打标流水线 | `scripts/tag_phrases_rules.py` | 嵌入 `embed_corpus.py` → `phrases.json` |

---

## 3. 单条语料数据结构（建议）

在 `phrases.json` 增加 `contextTags`（或旁路 `phrase_tags.json` 按 id 关联，便于脚本维护）：

```json
{
  "id": "sb_51",
  "text": "岁岁常欢愉",
  "textEn": "Joy every year",
  "dispatch": {
    "mode": "boost",
    "universal": true,
    "boost": [
      { "tag": "festival:spring_festival", "weight": 6.0 },
      { "tag": "festival:lantern_festival", "weight": 3.0 },
      { "tag": "festival:new_year", "weight": 4.0 }
    ],
    "affinity": {
      "season": ["winter", "spring"],
      "month": [1, 2, 12],
      "emotion": ["luck_blessing", "long_blessing"]
    },
    "negative": []
  }
}
```

示例：假设句「春日暖阳」（若入库）：

```json
{
  "dispatch": {
    "mode": "boost",
    "universal": false,
    "boost": [
      { "tag": "season:spring", "weight": 5.0 },
      { "tag": "month:3", "weight": 4.0 },
      { "tag": "weather:clear", "weight": 3.0 },
      { "tag": "weather:warm", "weight": 2.5 }
    ],
    "affinity": { "season": ["spring"], "month": [3, 4] },
    "negative": { "season": ["winter"], "weather": ["snow", "cold"] }
  }
}
```

`negative`：匹配则权重 ×0.1 或直接排除（可配置）。

---

## 4. 当前情境：ContextSnapshot

下发前构造（Swift 或离线模拟同一结构）：

```text
ContextSnapshot
├── calendar
│   ├── date, month, season
│   ├── solar_term?
│   ├── festival_active[]      // 今日命中节日
│   └── festival_window[]      // 今日命中窗口标签
├── time
│   └── day_part
├── weather?                   // 可选
│   ├── condition, temp_band
├── geo?                       // 可选
│   ├── region, altitude_band
└── device
    └── locale, timezone
```

**Widget「今日一句」**：同一 `dayKey` 应**稳定** → 用 `hash(dayKey + context_fingerprint)` 固定种子，其中 `context_fingerprint` 至少包含 `month + festival_active`，避免今天和明天春节权重不同却抽到完全无关句。

**摇一摇**：同一日内可用同一套权重池，但种子加入 `shake_nonce` 保证可换句。

---

## 5. 打分算法（核心）

对候选语料 \(i\)，情境 \(c\)：

### 5.1 基础分

\[
base_i = \begin{cases}
1.0 & universal_i = true \\
0.35 & universal_i = false \text{（非通用句平时也能出，但概率低）}
\end{cases}
\]

### 5.2 匹配加分（boost）

对每个标签 \(t \in boost_i\)：

\[
match(t, c) = \begin{cases}
1 & \text{若 } c \text{ 命中 } t \\
0 & \text{否则}
\end{cases}
\]

\[
boost_i = \sum_{t} match(t,c) \cdot weight_t
\]

### 5.3 亲和分（affinity，弱匹配）

季节/月份/天气等在 `affinity` 里但未写进 `boost` 时：

\[
affinity_i = \sum_{dim} \mathbb{1}[\text{overlap}(phrase[dim], c[dim])] \cdot w_{dim}
\]

建议 \(w_{season}=0.5, w_{month}=0.3, w_{weather}=0.4\)。

### 5.4 负向

\[
penalty_i = \prod_{t \in negative_i} \begin{cases} 0.05 & match(t,c) \\ 1 & \text{else} \end{cases}
\]

### 5.5 总分与抽样

\[
score_i = (base_i + boost_i + affinity_i) \cdot penalty_i
\]

- `exclusive` 且无任何 boost 命中 → \(score_i = 0\)（不参与）。
- 抽样：**加权随机**（`score` 为权重），不是永远取 top1，避免春节 30 条来回重复。
- 可选：对 top-80 分位截断后再抽样，控制长尾。

### 5.6 与「换一句」配合

`SessionOracleService.randomMoment` 改为：

1. 构建 `ContextSnapshot`；
2. `scores = phrases.map { score($0, context) }`；
3. 排除当前句 id；
4. `weightedRandom(phrases, scores)`；
5. 色板仍独立随机（或未来做 phrase–color 弱关联，另议）。

---

## 6. 打标流水线（304 条怎么标）

分三步，不要一次手工标完。

### Step A — 规则自动标（覆盖 40–60%）

| 规则 | 示例 |
| --- | --- |
| 字面含「春/夏/秋/冬」 | 风里有春天 → `season:*` |
| 字面含「圣诞/中秋/元宵」 | → `festival:*` + 常设 `exclusive` |
| 英文句 | `lang:en` |
| CSV `theme` | 映射到 `emotion:*` |
| 字数 | 自动 `length_band` |
| 哈利波特/五月天/周杰伦 | 关键词 → `ip:*` |

### Step B — LLM 批量建议 + 人工抽检

输入：phrase + theme + notes  
输出：严格 JSON `dispatch` 块（temperature 低），批量 20 条/轮。  
人工只审：`boost_weight` 是否过猛、`exclusive` 是否误杀。

### Step C — 黄金样本校准

先手工标 30 条「标杆句」，作为 few-shot，再跑全库。

产出文件建议：

- `phrase_context_tags.json`（id → dispatch）
- `config/festivals_cn.json`（节日 → 公历窗口）
- `config/tag_vocabulary.json`（合法 tag 枚举，防幻觉）

`embed_corpus.py` 合并进 `phrases.json`。

---

## 7. 与现有逻辑的关系

| 场景 | 现逻辑 | 新逻辑 |
| --- | --- | --- |
| Widget 今日句 | `hash(dayKey) % N` | `hash(dayKey + festival + month) % N` **或** 加权后在固定种子下选 index |
| App 首屏 | `todayBaseline()` 同上 | 同上，与 Widget 一致 |
| 摇一摇 / 回前台 | 均匀随机 | **Context 加权随机** |
| 色 | 独立随机 | 暂不改 |

---

## 8. 实施阶段建议

| 阶段 | 交付 | 依赖 |
| --- | --- | --- |
| P0 | 标签 schema + `festivals_cn.json` + 规则打标 50 条试点 | 无 |
| P1 | `ContextSnapshot`（仅 calendar）+ `PhraseScoring` + 摇一摇加权 | P0 |
| P2 | 全库 LLM 辅助打标 + 人工抽检 | P0 schema |
| P3 | WeatherKit 加权 | 用户授权 / 城市设置 |
| P4 | 地理/海拔粗粒度 | 常驻城市可选 |

---

## 9. 示例对照表

| 口令 | universal | 主要 boost | 说明 |
| --- | --- | --- | --- |
| 岁岁常欢愉 | ✓ | 春节 6×、元旦 4×、元宵 3× | 全年可出，年节更有感 |
| 冬日暖阳 | ✗ | `season:winter` 5×、`weather:cold` 3× | 冬天加权，夏天降权 |
| 春天在路上 | ✗ | `season:spring` 6×、`month:3-4` | 春季主导 |
| 今日锦鲤 | ✓ | 无特殊 | 通用好运 |
| 霍格沃茨永不毕业 | ✗ | `ip:harry_potter` exclusive | 仅联名期/营销期 |
| 记得微笑 | ✓ | `day_part:morning` 2×（可选） | 通用，早晨略加权 |

---

## 10. 需要你拍板的 3 件事

1. **非匹配时非通用句是否还能出现？**  
   建议：`boost` 模式保留底噪（`base=0.35`），避免三月只有 5 句春天话；你若要「三月几乎全是春天」，把底噪降到 0.1。

2. **Widget 是否与摇一摇同一套权重？**  
   建议：同一 `ContextSnapshot`，Widget 用固定种子，摇一摇用新种子。

3. **天气/海拔一期要不要？**  
   建议：文档先定 schema，**P1 只做 calendar+festival**，天气三期再接。

---

## 11. 下一步（实现时）

1. 在 `Shared/` 增加 `PhraseContextTags.swift` + `ContextSnapshotBuilder.swift` + `PhraseDispatchScorer.swift`  
2. 扩展 `Phrase` 模型 `contextDispatch: PhraseDispatch?`  
3. `scripts/tag_phrases_rules.py` + `phrase_context_tags.json`  
4. 改 `SessionOracleService.pickPhrase` 为加权抽样  

你确认 P0/P1 边界后，可以从「节日配置表 + 50 条试标 + 摇一摇加权」开始写代码。

---

## 12. 已实现 v2 —— 标签扩充 + 颜色应景（本次）

在 v1（句子情境加权）基础上，本次补齐**两件事**：① 打标流水线工业化、可复现、强校验；② **颜色也应景**（季节/节日/天气命中时该色加权 + 语料可点名细色族）。

### 12.1 数据流（句子）

```
starbucks_now_passphrases.csv
  │
  ├─ scripts/tag_phrases_rules.py   规则基线（字面 → universal/onlyWhen/boost：季节、天气、时段、IP）
  │     → scripts/phrase_dispatch.json
  │
  ├─ scripts/tag_phrases_llm.py     语义层（编辑直觉 → colorMoods/colorBan/colorFamilies/boostAdd/negativeAdd + _meta）
  │     → config/phrase_context_tags.json   （overlay；含人工 OVERRIDES 锚点句）
  │     → scripts/phrase_context_tags_review.md（人工校对清单）
  │
  ├─ scripts/dispatch_overlay.py    合并逻辑（base + overlay；boost 同名取 max，颜色 overlay 优先）
  ├─ scripts/validate_dispatch.py   强校验（所有 tag 落在 config/tag_vocabulary.json；越界告警）
  │
  └─ scripts/embed_corpus.py        合并 + 清洗（strip 空字段与 _meta）→ ios/Shared/Resources/phrases.json
```

`config/tag_vocabulary.json` 是**唯一真源**：所有维度取值、权重区间、`color_moods`、`color_family` 都在此枚举，防拼错/LLM 幻觉。新增维度或取值先改它。

### 12.2 数据流（颜色应景）

```
scripts/tag_color_context.py   按 HSL + 色名汉字给 248 色打：
  · context = {season:[], festival:[], weather:[]}   情境亲和
  · family  = red|orange|…|black                      细色族（P4）
  → ios/Shared/Resources/nippon_colors.json（in-place）
  → scripts/tag_color_context_review.md（人工校对清单）
```

Swift 选色（`ColorMoodPicker.pick`）权重为乘法叠加：

| 命中 | 乘数 | 常量 |
| --- | --- | --- |
| 句 `colorMoods`（warm/cool/light/dark） | ×2 | `moodBoostMultiplier` |
| 句 `colorFamilies`（精确点名 green/blue…） | ×3 | `familyBoostMultiplier` |
| 当日 `ContextSnapshot` 命中色 `context` 亲和 | ×2 | `contextBoostMultiplier` |
| 句 `colorBan` | 硬剔除（池 <30 回落只降权） | `minPoolSize` |

调用链：`DailyOracleService.oracle` / `SessionOracleService.randomMoment` 构建一次 `ContextSnapshot`，同时喂给选句与选色——句与色共享同一情境。

> ⚠️ 对齐修复：`ContextSnapshotBuilder.dayPart` 深夜段由 `night` 改为 `late_night`，与词表/标签一致（原先 `daypart:late_night` 永不命中）。

### 12.3 通用兜底 vs 应景比例（本次实测）

- 上线目标：约 **40% 兜底 / 60% 应景**。
- 实测：218 句中 **67% 带情境信号 / 33% 纯兜底**；且 **91% 仍 `universal:true`**（仅 20 句季节硬门槛）——日常候选池基本是全库，应景只是叠加权重，**多样性不受损**。
- 调比例的旋钮：`scripts/tag_phrases_llm.py` 里的关键词表（`WARM_WORDS`/`COOL_WORDS`/各 `*_WORDS`）。想更兜底就收紧关键词，想更应景就放宽。

### 12.4 重建命令（新增/修改语料后照跑）

```bash
# 句子标签全链路（顺序不能乱）
python3 scripts/tag_phrases_rules.py      # 1. 规则基线
python3 scripts/tag_phrases_llm.py        # 2. 语义 overlay（+ 校对 md）
python3 scripts/validate_dispatch.py      # 3. 强校验（0 error 才继续）
python3 scripts/embed_corpus.py           # 4. 合并落地 phrases.json

# 颜色应景（改了色板或分类规则才需跑）
python3 scripts/tag_color_context.py      # 给 248 色打 context + family（+ 校对 md）

# 发布到 CDN / Vercel（独立的发布动作，会动线上 manifest，按需执行）
python3 scripts/publish_corpus_static.py --base-url https://oraculo-one.vercel.app/oraculo
```

校对清单（`*_review.md`）是给人扫一眼接受/改写的；分类是产品判断而非物理真值，可直接改对应 JSON 的字段。
