# Oraculo

**Oraculo**（iOS 17+）：纯色传统色 + 每日一句；视觉参考 [nipponcolors.com](https://nipponcolors.com/#nakabeni)。含啡快式语料研究资产。

## 仓库结构

| 部分 | 说明 |
| --- | --- |
| [docs/PRODUCT.md](docs/PRODUCT.md) | 产品目标与 v1 范围 |
| [starbucks_now_passphrases.csv](starbucks_now_passphrases.csv) | 收集的啡快口令（App 语料源） |
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

App 内置收集的啡快口令：`starbucks_now_passphrases.csv` → `scripts/embed_corpus.py` → `phrases.json`。说明见 [docs/CORPUS.md](docs/CORPUS.md)。
