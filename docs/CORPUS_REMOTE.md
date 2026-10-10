# 语料静态热更新

无需自建后端：把可变的 `manifest.json` 与按版本、SHA 命名的语料、日历文件放到 HTTPS 静态托管，App 启动时按需拉取。自 App 1.1.0 / release v13 起，两份资源属于同一个 release，一起校验、一起生效。

本仓库默认使用 **Vercel** + GitHub：[enderwang2012-lang/Oraculo](https://github.com/enderwang2012-lang/Oraculo)。

## 加载顺序

1. 读取 Bundle 内置版本与 App Group 的 `active_release.json`。
2. 仅当完整 release 通过两份 SHA、版本、条数和日历结构校验，且版本不低于 Bundle 时使用它。
3. 缓存较旧、损坏或缺失时，语料和日历一起回到 Bundle。
4. 1.1.0 不再应用只有 phrases 的新 manifest，也不混用旧版散文件缓存与新版日历。

Widget 与主 App 共用 App Group，**不单独请求网络**。
每次 Widget 生成时间线都会从同一 release 重读语料和日历；旧 release 的展示快照不再复用。

下载后先写 `corpus/releases/.staging-<uuid>/`，两份文件完整验证后移到
`corpus/releases/v<version>/`，最后原子更新 `active_release.json`。
失败时保留之前的 active release。发布的新 manifest 使用 `minAppVersion: 1.1.0`，旧 App 继续使用已有语料。

## Vercel 部署（一次性）

1. 打开 [vercel.com/new](https://vercel.com/new)，用 GitHub 导入 **Oraculo** 仓库。
2. **Framework Preset**：Other（纯静态即可）。
3. **Root Directory**：仓库根目录（默认 `.`）。
4. **Project Name**：当前 Production 项目为 **`oraculo-corpus`**，唯一使用的生产域名是 `https://oraculo-corpus.vercel.app`。`https://oraculo.vercel.app` 是其他站点，不要使用。
5. Framework：Other；根目录 `vercel.json` 已指定 `outputDirectory: public`，无需 Build Command。
6. Deploy 完成后在浏览器验证：
   - `https://oraculo-corpus.vercel.app/`（应看到 Oraculo 产品页）
   - `https://oraculo-corpus.vercel.app/support/`
   - `https://oraculo-corpus.vercel.app/privacy/`
   - `https://oraculo-corpus.vercel.app/oraculo/manifest.json`
   - manifest 中 `phrases.url` 指向的 `phrases-v<version>-<sha256>.json`

若 Production 域名不同，请把实际 URL 写进 `ios/Shared/AppConstants.swift` 的 `corpusManifestURLString`（路径仍为 `/oraculo/manifest.json`）。

缓存策略见仓库根目录 `vercel.json`：manifest 短缓存；不可变版本资源缓存一年。`/oraculo/phrases.json` 固定保留为 v7 兼容资源，不再被新版本发布覆盖，也不是 v8 及后续版本的发布入口。

## 发布流程（改语料后）

```bash
# 1. 完整重建、递增版本并生成不可变静态资源
python3 scripts/rebuild_corpus.py \
  --publish \
  --bump \
  --base-url https://oraculo-corpus.vercel.app/oraculo \
  --min-app-version 1.1.0 \
  --release-notes "本次语料调整摘要"

# 2. 本地验证
python3 scripts/validate_release_readiness.py

# 3. 审核 diff 后提交并 push（Vercel 会自动重新部署）
git add public/oraculo config/corpus_version.txt ios/Shared/Resources/
git commit -m "chore(corpus): publish v<version>"
git push
```

`rebuild_corpus.py --publish` 会调用 `publish_corpus_static.py`，把 `dist/corpus/` 的 manifest 与不可变资源复制到 `public/oraculo/`。直接调用发布器做本地试跑时可加 `--no-sync-public`。

本地审核候选尚未发布时，Bundle 版本可能高于现网版本。此时使用：

```bash
python3 scripts/validate_release_readiness.py --allow-unpublished-candidate
```

该模式仍校验本地 Bundle 和现有 public 资源各自完整，只跳过两者必须相同的版本与 SHA 闸门。默认不带参数的模式继续用于真正发布前检查。

push 后不要只看 HTTP 200。用预期版本、SHA、数量和关键条目做精确轮询：

```bash
EXPECTED_VERSION=8
EXPECTED_SHA=91aa5df8a57bc1fd7432142998500806856a61bf4978d79ae56f99827ea55241
EXPECTED_COUNT=110

python3 scripts/verify_corpus_cdn.py \
  --expected-version "$EXPECTED_VERSION" \
  --expected-sha "$EXPECTED_SHA" \
  --expected-count "$EXPECTED_COUNT" \
  --expect 'sb_2057=孤独海怪' \
  --attempts 12 \
  --interval 20
```

命令读取 manifest，再下载 phrases 和 calendar；只有 release 版本、两份 SHA、条数、日历结构和所有 `--expect` 条目全部一致才成功。默认期望值来自本地 bundle meta。部署前验证现网旧版本时必须显式传旧版本参数。

默认 DNS/路由失败时，可传 `--resolve-ip <已核验的 Vercel edge IP>`，仍使用原域名做 HTTPS 证书校验。不要将连接失败解释为部署构建失败。

## 启用 / 关闭热更新

`ios/Shared/AppConstants.swift`：

```swift
static let corpusManifestURLString = "https://oraculo-corpus.vercel.app/oraculo/manifest.json"
```

留空 `""` 则完全关闭热更新，仅使用 Bundle 语料。

## manifest 格式

```json
{
  "corpusVersion": 13,
  "releaseVersion": 13,
  "publishedAt": "2026-10-10T00:00:00Z",
  "minAppVersion": "1.1.0",
  "releaseNotes": "语料与节日日历统一热更新",
  "phrases": {
    "url": "https://oraculo-corpus.vercel.app/oraculo/phrases-v13-<sha256>.json",
    "sha256": "全文件小写 hex"
  },
  "calendar": {
    "url": "https://oraculo-corpus.vercel.app/oraculo/calendar-v13-<sha256>.json",
    "sha256": "全文件小写 hex"
  }
}
```

- `corpusVersion`：整数，**必须**大于用户设备上「内置版本」与「已应用热更新版本」才会下载。
- `phrases.sha256`：与 `embed_corpus.py` 输出的 `corpus_bundled_meta.json` 中一致。
- `calendar.sha256`：与 bundle meta 中 `calendarSHA256` 一致。
- `releaseVersion`、`corpusVersion`、日历中的 `version` 必须一致。
- `minAppVersion`：新版发布器要求至少 1.1.0，防止旧 App 只应用语料而遗漏日历。

## 版本号约定

| 文件 | 作用 |
| --- | --- |
| `config/corpus_version.txt` | 人工递增，写入 bundle meta 与远程 manifest |
| `corpus_bundled_meta.json` | 打进 App，含语料与日历 SHA |
| App Group `active_release.json` | 指向完整生效版本 |
| App Group `releases/vN/release_meta.json` | 版本、两份 SHA 和语料条数 |
| `public/oraculo/manifest.json` | 可变入口，提交到 Git 后由 Vercel 发布 |
| `public/oraculo/phrases-v<version>-<sha256>.json` | 不可变版本资源，禁止原位覆盖 |
| `public/oraculo/calendar-v<version>-<sha256>.json` | 同一 release 的不可变日历资源 |
| `public/oraculo/phrases.json` | 固定 v7 兼容资源，不随新版本改写 |

**仅改打标、不改句数**：也要递增 `corpus_version.txt`，否则客户端不会拉取。

## 安全与回滚

- 仅 HTTPS；下载后校验 SHA256，校验失败不替换缓存。
- 校验失败或网络错误时继续使用旧缓存 / Bundle，不影响离线使用。
- 同一版本和 SHA 对应的资源如果已存在但内容不同，发布脚本会拒绝覆盖。
- 回滚不能降低 `corpusVersion`，也不能改写旧资源。应把确认过的旧 payload 作为一个**新的更高版本**重新发布，并经过同一套 SHA、数量和关键条目验证。

## 与 App Store 发版的关系

| 场景 | 建议 |
| --- | --- |
| 新增/修改句子、打标 | 热更新即可，不必等为发版 |
| 修改节日、节气、现有日期绑定规则 | 1.1.0 起支持与语料一起热更新 |
| 改 `Phrase` 字段结构、选句算法 | 必须发 App |
| 新用户首装无网 | 依赖 Bundle 内置语料 |

发版时仍运行 `embed_corpus.py`，保证内置版本与 CDN 版本策略一致（通常内置 ≤ 远程）。

## 日期绑定

所有文化日期、日种子和 Widget 次日切换统一按公历、`Asia/Shanghai` 计算。

`dispatch.dateBinding` 支持：

- `mode: exclusive`：当日命中后，仅在最高 priority 的日期句库中随机；未命中时该句不参与普通池。
- `mode: boost`：命中后增加普通池权重，不独占。`priority` 仅用于 exclusive 冲突排序。
- `rules`：OR 关系，支持 `month_day:MM-DD`、festival、solar_term、month、season。
- `onlyWhen` 仍是额外硬门槛；重复规避和新鲜度不会让句子越过日期限制。

v13 将重阳、万圣夜、感恩节、平安夜、圣诞节和年末短签接入独占池。
“明年见”“来年可期”“旧岁再见”“明年会更好”只在 12-31 出现；
“苹果分你一半”“平安无事”只在 12-24 出现。
季节和小雪、冬至意象沿用现有节气区间，不将整个节气区间设为独占。

`config/festivals_cn.json` 和 `config/solar_terms_cn.json` 是源配置，
`embed_corpus.py` 同时生成 Bundle 的 `calendar.json` 与兼容分文件。
农历节日按年配置，不能把 2026 年日期当成以后每年的固定公历日期。
目前重阳已配置 2026 年，新增年份需走同一热更新发布流程。
