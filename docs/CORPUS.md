# Oraculo 语料（第一版）

## 数据源

App 内置句库**仅**来自收集的真实啡快口令：

- 文件：[starbucks_now_passphrases.csv](../starbucks_now_passphrases.csv)
- 来源说明：[starbucks_now_sources.md](../starbucks_now_sources.md)
- 风格观察：[starbucks_now_style_notes.md](../starbucks_now_style_notes.md)

**不**使用 AI 生成句、`feikuai_corpus_v1` / `lab`、或 `oraculo_corpus_v2`。

## 生成进 App

```bash
python3 scripts/starbucks_phrases_en.py   # 更新 phrases_en.json（改译文时）
python3 scripts/tag_phrases_rules.py      # 更新 phrase_dispatch.json（情境打标）
python3 scripts/embed_corpus.py           # 合并 dispatch → 写入 App
```

情境下发说明见 [CONTEXTUAL_PHRASE_DISPATCH.md](CONTEXTUAL_PHRASE_DISPATCH.md)。

静态热更新（CDN manifest，无需后端）见 [CORPUS_REMOTE.md](CORPUS_REMOTE.md)。

输出：

- `ios/Shared/Resources/phrases.json`
- `ios/Shared/Resources/corpus_bundled_meta.json`（版本号 + SHA256）

## 字段映射

| CSV | JSON |
| --- | --- |
| `id` | `sb_{id}` |
| `phrase` | `text` |
| `theme` | `emotionTheme`（主题 → 稳定 slug，便于后续统计） |
| `evidence` | `layer`：`official_text` / `image_verified` → `anchor`，其余 → `active` |
| — | `textEn` 来自 `scripts/phrases_en.json`（诗意 paraphrase，非直译；由 `starbucks_phrases_en.py` 维护） |
| — | `dispatch` 来自 `scripts/phrase_dispatch.json`（`universal` / `onlyWhen` / `boost`） |

## 使用规则

- **Widget 今日句**：`hash(yyyy-MM-dd) % 语料数`
- **App 摇一摇 / 回前台**：从全库随机，避开当前句+色

## 研究资产（不进 App）

- `feikuai_corpus_v1.csv`、`feikuai_corpus_v1_lab.csv` — 仿写实验
- `oraculo_corpus_v2.csv` — 已弃用的生成尝试
- `feikuai_corpus_constitution.md` — 仍可作后续人工增删的参考，**不**覆盖真实样本
