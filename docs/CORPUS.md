# Oraculo 语料

## 当前口径

- 源台账：`starbucks_now_passphrases.csv`，共 248 条，保留来源、证据与历史记录。
- 编辑审核源：`config/phrase_editorial_review.json`，248 个 ID 均有显式决定和审核理由。
- 人工查看表：`review/corpus_review_2026_08_full.csv`，与审核源逐条对应。
- 本地 Bundle 候选：`corpusVersion 9`，161 条；这是待审产物，尚未同步到 `public/oraculo/` 或生产 CDN。
- 当前生产：`corpusVersion 8`，110 条；生产状态以远程 manifest 回读为准。

## 快速更新流程

常规协作方式：用户提供候选语料，助手负责候选池、入库、打标、校验、重建和同步产物。

候选池：

- 文件：`review/corpus_candidates.csv`
- 字段：`phrase, theme_hint, source_type, source_note, status, rewrite_note`
- `status`：`candidate` / `accepted` / `rejected` / `needs_rewrite` / `promoted`
- 候选池不进 App，只有 `accepted` 被提升后才入库。

手动命令（需要时）：

```bash
python3 scripts/promote_corpus_candidates.py
python3 scripts/rebuild_corpus.py --publish --bump --release-notes "本次语料调整摘要"
python3 scripts/validate_corpus.py
```

语料约束：

- 入库源仍然只有 `starbucks_now_passphrases.csv`。
- 每个源 ID 必须先存在于 `config/phrase_editorial_review.json`，否则校验失败。
- 情绪/场景标签只做分类展示或软加权，不做硬条件。
- `onlyWhen` 只放可靠上下文：季节、节日、天气、温度、月份、节气、星期、时段。
- 发布热更新时需要递增 `config/corpus_version.txt`；`rebuild_corpus.py --bump` 会自动处理。
- 人工生命周期、编辑主题、语义簇和句式组统一写入 `config/phrase_editorial_review.json`。
- `retired` 只保留在源 CSV 台账中，不进入 Bundle 或 CDN payload。
- 2026-08-06 人工全量初始审核后，161 条保留项 lifecycle 全部为 `active`，其中 13 条直接采用已确认改写稿。87 条 `retire` 保留在源台账，不进入候选。本轮不使用 `cooling`、`anchor` 或 `new` 权重。

## 数据源

源台账混合保存三类可审计来源：

- 文件：[starbucks_now_passphrases.csv](../starbucks_now_passphrases.csv)
- 来源说明：[starbucks_now_sources.md](../starbucks_now_sources.md)
- 风格观察：[starbucks_now_style_notes.md](../starbucks_now_style_notes.md)

- 外部活动、订单或社交来源记录：218 条。
- 生成后经人工审核的编辑语料：27 条。
- 用户提供并单独记录来源的语料：3 条。

来源进入台账不代表进入 App。只有审核源中 `decision=keep` 的条目才进入本地候选。`feikuai_corpus_v1`、`feikuai_corpus_v1_lab` 和 `oraculo_corpus_v2` 仍是研究资产，不参与生成。

## 生成进 App

```bash
python3 scripts/reset_corpus_review.py # 生成 248 条初始审核底稿
python3 scripts/import_corpus_review.py # 原生解析人工审核工作簿，导入最终决定和备注
python3 scripts/starbucks_phrases_en.py   # 更新 phrases_en.json（改译文时）
python3 scripts/tag_phrases_rules.py      # 更新 phrase_dispatch.json（情境打标）
python3 scripts/tag_phrase_freshness.py   # 从审核源生成 freshness
python3 scripts/embed_corpus.py           # 合并 dispatch → 写入 App
```

情境下发说明见 [CONTEXTUAL_PHRASE_DISPATCH.md](CONTEXTUAL_PHRASE_DISPATCH.md)。

静态热更新（CDN manifest，无需后端）见 [CORPUS_REMOTE.md](CORPUS_REMOTE.md)。

新鲜度下发：每条语料同时带 `freshness.semanticCluster`、`freshness.cadenceGroup`、`freshness.lifecycle`。App 与 Widget 将本机最近曝光写入 App Group，抽句时在情境权重后追加新鲜度权重，避免同一句、同一类语义、同一种句式短期反复出现。

输出：

- `ios/Shared/Resources/phrases.json`
- `ios/Shared/Resources/corpus_bundled_meta.json`（版本号 + SHA256）

## 字段映射

| CSV | JSON |
| --- | --- |
| `id` | `sb_{id}` |
| `phrase` | `text` |
| `config/phrase_editorial_review.json.editorialTheme` | `emotionTheme`（审核后的编辑主题 → 稳定 slug） |
| `evidence` | `layer`：历史兼容的来源证据层，不参与 lifecycle 加权；来源细分以审核源的 `sourceCategory` 为准 |
| — | `textEn` 来自 `scripts/phrases_en.json`（诗意 paraphrase，非直译；由 `starbucks_phrases_en.py` 维护） |
| — | `dispatch` 来自 `scripts/phrase_dispatch.json`（`universal` / `onlyWhen` / `boost`） |
| — | `freshness` 由审核源生成到 `config/phrase_freshness_tags.json`（语义簇 / 句式组 / 生命周期） |

## 使用规则

- **共享当前签**：App Group 保存当前展示的句+色。App 里换句后，桌面 / 锁屏 Widget 优先显示这次 App 当前签。
- **Widget 每日自动更新**：如果今天还没有共享当前签，Widget 在当天 timeline 里自动生成 `dailyAuto` 今日签，写入共享当前签并记录一次曝光。
- **App 摇一摇 / 回前台**：从情境加权候选池抽取，并乘以本机新鲜度权重，避开当前句+色。
- **曝光记账**：只有新 moment 被 App 或 Widget dailyAuto 生成时记录曝光；Widget 只是渲染已有共享当前签时不重复记账。

## 研究资产（不进 App）

- `feikuai_corpus_v1.csv`、`feikuai_corpus_v1_lab.csv` — 仿写实验
- `oraculo_corpus_v2.csv` — 已弃用的生成尝试
- `feikuai_corpus_constitution.md` — 仍可作后续人工增删的参考，**不**覆盖真实样本
