# 语料静态热更新

无需自建后端：把 `manifest.json` + `phrases.json` 放到 HTTPS 静态托管，App 启动时按需拉取。

本仓库默认使用 **Vercel** + GitHub：[enderwang2012-lang/Oraculo](https://github.com/enderwang2012-lang/Oraculo)。

## 加载顺序

1. **App Group 缓存**（上次热更新成功的 `phrases.json`）
2. **Bundle 内置** `phrases.json`（发版兜底）

Widget 与主 App 共用 App Group，**不单独请求网络**。

## Vercel 部署（一次性）

1. 打开 [vercel.com/new](https://vercel.com/new)，用 GitHub 导入 **Oraculo** 仓库。
2. **Framework Preset**：Other（纯静态即可）。
3. **Root Directory**：仓库根目录（默认 `.`）。
4. **Project Name**：建议设为 `oraculo`，Production 域名为 `https://oraculo.vercel.app`。
5. 无需 Build Command；`public/` 下文件会按路径发布。
6. Deploy 完成后在浏览器验证：
   - `https://oraculo.vercel.app/oraculo/manifest.json`
   - `https://oraculo.vercel.app/oraculo/phrases.json`

若 Vercel 分配的域名不是 `oraculo.vercel.app`，请把实际 Production URL 写进 `ios/Shared/AppConstants.swift` 的 `corpusManifestURLString`（路径仍为 `/oraculo/manifest.json`）。

缓存策略见仓库根目录 `vercel.json`（manifest 短缓存、phrases 较长）。

## 发布流程（改语料后）

```bash
# 1. 递增版本号（必须大于已上线版本）
echo 2 > config/corpus_version.txt

# 2. 生成 App 内置兜底 + 静态包
python3 scripts/starbucks_phrases_en.py   # 若改过译文
python3 scripts/tag_phrases_rules.py
python3 scripts/embed_corpus.py

# 3. 生成 dist/ 并同步到 public/oraculo/（供 Vercel）
python3 scripts/publish_corpus_static.py \
  --base-url https://oraculo.vercel.app/oraculo

# 4. 提交并 push（Vercel 会自动重新部署）
git add public/oraculo config/corpus_version.txt ios/Shared/Resources/
git commit -m "chore(corpus): bump to v2"
git push
```

`publish_corpus_static.py` 默认会把 `dist/corpus/` 复制到 `public/oraculo/`；仅本地试跑可加 `--no-sync-public`。

## 启用 / 关闭热更新

`ios/Shared/AppConstants.swift`：

```swift
static let corpusManifestURLString = "https://oraculo.vercel.app/oraculo/manifest.json"
```

留空 `""` 则完全关闭热更新，仅使用 Bundle 语料。

## manifest 格式

```json
{
  "corpusVersion": 2,
  "publishedAt": "2026-05-04T12:00:00Z",
  "minAppVersion": "0.1.0",
  "releaseNotes": "新增 12 条口令，修正春节打标",
  "phrases": {
    "url": "https://oraculo.vercel.app/oraculo/phrases.json",
    "sha256": "全文件小写 hex"
  }
}
```

- `corpusVersion`：整数，**必须**大于用户设备上「内置版本」与「已应用热更新版本」才会下载。
- `phrases.sha256`：与 `embed_corpus.py` 输出的 `corpus_bundled_meta.json` 中一致。
- `minAppVersion`：可选保护，旧 App 不拉新格式语料。

## 版本号约定

| 文件 | 作用 |
| --- | --- |
| `config/corpus_version.txt` | 人工递增，写入 bundle meta 与远程 manifest |
| `corpus_bundled_meta.json` | 打进 App，含 `phrasesSHA256` |
| App Group `applied_meta.json` | 热更新成功后写入 |
| `public/oraculo/*.json` | 提交到 Git，由 Vercel 发布 |

**仅改打标、不改句数**：也要递增 `corpus_version.txt`，否则客户端不会拉取。

## 安全与回滚

- 仅 HTTPS；下载后校验 SHA256，校验失败不替换缓存。
- 校验失败或网络错误时继续使用旧缓存 / Bundle，不影响离线使用。
- 回滚：发布更低 `corpusVersion` 的 manifest 无效；应发布新 manifest 指回旧 `phrases.json` 并**递增**版本号。

## 与 App Store 发版的关系

| 场景 | 建议 |
| --- | --- |
| 新增/修改句子、打标 | 热更新即可，不必等为发版 |
| 改 `Phrase` 字段结构、选句算法 | 必须发 App |
| 新用户首装无网 | 依赖 Bundle 内置语料 |

发版时仍运行 `embed_corpus.py`，保证内置版本与 CDN 版本策略一致（通常内置 ≤ 远程）。

## 后续可扩展（仍无需后端）

在 manifest 中增加可选字段即可，例如：

- `festivals.url` + `festivals.sha256`
- `solarTerms.url` + `solarTerms.sha256`

App 侧按同样模式写入 App Group 并热加载。
