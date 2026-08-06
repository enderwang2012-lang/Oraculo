# Oraculo

**Oraculo 1.0**（iOS 17+）：每日一句 + 每日一色，纯色铺满、居中一句、无导航。色系借鉴日本传统色，但不展示色名、不绑定其文化语义。语料源台账含 248 条审查记录，生成 payload 只纳入内容审核为 `keep` 的条目。

## 仓库结构

| 部分 | 说明 |
| --- | --- |
| [docs/PRODUCT.md](docs/PRODUCT.md) | 产品目标与 v1 范围 |
| [starbucks_now_passphrases.csv](starbucks_now_passphrases.csv) | 248 条来源台账 |
| [config/phrase_editorial_review.json](config/phrase_editorial_review.json) | 248 条生产取舍与编辑标签的机器可读审核源 |
| [review/corpus_review_2026_08_full.csv](review/corpus_review_2026_08_full.csv) | 逐条审核表 |
| [ios/](ios/) | SwiftUI App + Widget 源码 |
| [scripts/embed_corpus.py](scripts/embed_corpus.py) | 口令 CSV → `phrases.json` |
| [feikuai_corpus_v1.csv](feikuai_corpus_v1.csv) | 仿写实验（不进 App） |

## 快速开始（iOS）

```bash
./scripts/bootstrap_ios.sh   # 同步语料 + 生成/打开 Xcode 工程
open ios/Oraculo.xcodeproj   # 在 Xcode 中选 Team 后 Run
```

详见 [ios/README.md](ios/README.md)。

## 语料（第一版）

语料源台账先经过显式编辑审核，再由 `scripts/embed_corpus.py` 生成 `phrases.json`。当前 payload 数量、生产版本和本地候选边界见 [docs/CORPUS.md](docs/CORPUS.md)。
