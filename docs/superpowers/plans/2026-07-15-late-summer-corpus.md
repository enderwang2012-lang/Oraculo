# Late-Summer Corpus Candidate Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a researched, source-aware review batch of 90 Chinese Oraculo phrases for August 2026 without changing or publishing the production corpus.

**Architecture:** The work has three owned repository artifacts: a reference-mechanism ledger, a structured CSV that is the candidate source of truth, and a shuffled Markdown review view derived from that CSV. Draft generation and destructive filtering happen in a temporary CSV outside the repository; production corpus, translations, dispatch, freshness, version, bundle, and public assets remain untouched until the user completes review in a later phase.

**Tech Stack:** Markdown, UTF-8 CSV, Ruby standard-library `CSV` for read-only structured checks, existing Oraculo corpus files and Git.

---

## Scope Boundary

This plan implements only the approved design in `docs/superpowers/specs/2026-07-14-late-summer-corpus-design.md` through delivery of the candidate review files. It does not implement the separate monthly automation design in `docs/superpowers/specs/2026-07-14-monthly-corpus-automation-design.md`.

Stop after handing the 90 candidates to the user. Do not create `review/corpus_candidates_2026_08_accepted.csv`, run `scripts/promote_corpus_candidates.py`, modify production corpus data, bump a corpus version, rebuild assets, push, or deploy before the user supplies a final selection and explicitly opens the later release gate.

The checkout currently contains an unrelated modification to `ios/Oraculo.xcodeproj/project.pbxproj`. Preserve it exactly and never stage it in this plan.

## File Structure

- Create: `review/corpus_references_2026_08.md` - source-attributed research ledger containing only work metadata and extracted writing mechanisms, never full lyrics.
- Create: `review/corpus_candidates_2026_08_late_summer.csv` - canonical 90-row candidate dataset and all internal review metadata.
- Create: `review/corpus_candidates_2026_08_late_summer.md` - shuffled, minimal user review view generated from the CSV order.
- Temporary: `/tmp/oraculo-corpus-2026-08-raw.csv` - at least 150 original drafts used during curation; do not commit it.
- Read: `starbucks_now_passphrases.csv` - current 244-row corpus used for duplicate and language-distribution checks.
- Read: `review/corpus_candidates_2026_07_accepted.csv` and `review/corpus_candidates_2026_07_summer*.md` - prior acceptance evidence and known failure patterns.
- Read: `starbucks_now_style_notes.md` and `docs/current-corpus-by-theme.md` - current voice and coverage baseline.

## Task 1: Build The Reference-Mechanism Ledger

**Files:**
- Create: `review/corpus_references_2026_08.md`
- Read: `docs/superpowers/specs/2026-07-14-late-summer-corpus-design.md`
- Read: `review/corpus_candidates_2026_07_accepted.csv`
- Read: `starbucks_now_style_notes.md`

- [ ] **Step 1: Re-read the approved editorial constraints**

Run:

```bash
sed -n '1,260p' docs/superpowers/specs/2026-07-14-late-summer-corpus-design.md
sed -n '1,80p' review/corpus_candidates_2026_07_accepted.csv
```

Expected: the design fixes the batch at 90 candidates with a 63/27 seasonal-evergreen split, preserves the three user seeds, and forbids production mutations during candidate review.

- [ ] **Step 2: Research the fixed song reference set**

Use a browser only for read-only research. Verify work and creator metadata from official artist, publisher, streaming-service, library, or reputable editorial pages. Study at least the following 24 songs across more than eight creators; do not copy complete lyrics into notes:

```text
万能青年旅店 / 姬赓: 秦皇岛; 揪心的玩笑与漫长的白日梦; 山雀; 郊眠寺
朴树: 白桦林; 生如夏花; 清白之年
张悬: 城市; 喜欢; 关于我爱你
雷光夏: 逝; 黑暗之光
罗大佑: 鹿港小镇; 恋曲1980
李宗盛: 山丘; 新写的旧歌
苏打绿 / 吴青峰: 小情歌; 无与伦比的美丽
周杰伦 / 方文山: 七里香; 东风破
my little airport: 浪漫九龙塘; 西西弗斯之歌
赵雷: 成都; 鼓楼
```

For every work, record only metadata, a source URL, and a one-sentence mechanism note. Acceptable mechanism notes identify such things as an ordinary object gaining emotional weight, a named place becoming a memory container, concrete narration turning abstract, or semantically distant nouns forming tension.

- [ ] **Step 3: Research the fixed poetry reference set**

Verify metadata for at least these six modern poems and four classical works. Do not store full copyrighted modern poems:

```text
顾城: 一代人; 远和近
北岛: 回答; 波兰来客
海子: 九月; 日记
陶渊明: 饮酒·其五
王维: 山居秋暝
李商隐: 夜雨寄北
刘禹锡: 秋词·其一
```

For the classical works, note how season and time are implied through scene rather than named as labels. For the modern poems, record only a mechanism summary and source URL.

- [ ] **Step 4: Create the research ledger**

Create `review/corpus_references_2026_08.md` with this exact top-level structure:

```markdown
# 2026-08 语料参考研究

## 研究边界

- 只记录作品信息与语言机制，不保存整段歌词或现代诗正文。
- 参考用于拆解写法，不按单一作者仿写。
- 直接进入候选池的截断致敬必须另行记录来源与风险。

## 华人创作歌词

| 创作者 | 作品 | 来源 | 语言机制 | 可借鉴边界 |
| --- | --- | --- | --- | --- |

## 现代诗

| 作者 | 作品 | 来源 | 语言机制 | 可借鉴边界 |
| --- | --- | --- | --- | --- |

## 古典诗词意象

| 作者 | 作品 | 来源 | 语言机制 | 可借鉴边界 |
| --- | --- | --- | --- | --- |

## 本批写作结论

1. 具体物件先于抽象情绪。
2. 陌生关系必须可以感知，不能只剩晦涩。
3. 时令优先由声音、光线、身体和物候暗示。
4. 句子保留谜面，但朗读和基本语义必须成立。
```

Populate at least 24 song rows, six modern-poem rows, and four classical-work rows. Keep quoted source text out of mechanism notes.

- [ ] **Step 5: Verify reference coverage and forbidden full-text risk**

Run:

```bash
rg -n '^\| [^ -].*\| https?://' review/corpus_references_2026_08.md
wc -l review/corpus_references_2026_08.md
git diff --check -- review/corpus_references_2026_08.md
```

Expected: every populated table row has a source URL, the file has more than 45 lines, and `git diff --check` emits no output. Manually inspect any paragraph longer than two sentences and remove copied source wording.

- [ ] **Step 6: Commit the research ledger**

Run:

```bash
git add review/corpus_references_2026_08.md
git diff --cached --check
git diff --cached --stat
git commit -m "docs(corpus): research August phrase references"
```

Expected: one commit containing only `review/corpus_references_2026_08.md`; `ios/Oraculo.xcodeproj/project.pbxproj` remains modified but unstaged.

## Task 2: Generate And Audit The Raw Original Pool

**Files:**
- Create temporarily: `/tmp/oraculo-corpus-2026-08-raw.csv`
- Read: `review/corpus_references_2026_08.md`
- Read: `starbucks_now_passphrases.csv`
- Read: `review/corpus_candidates_2026_07_accepted.csv`

- [ ] **Step 1: Create the temporary raw-draft schema**

Use `apply_patch` to create `/tmp/oraculo-corpus-2026-08-raw.csv` with this exact header:

```csv
draft_id,phrase,content_window,mechanism,tone_shade,source_note,keep,review_note
```

Use `content_window=late_summer` or `evergreen`, `mechanism=life_slice`, `strange_compound`, or `abstract_compression`, and `tone_shade=light` or `dark`. Initialize `keep` as empty.

- [ ] **Step 2: Write at least 150 original drafts**

Create at least 105 `late_summer` drafts and 45 `evergreen` drafts. Across the raw pool, target a 4:3:2 ratio for `life_slice:strange_compound:abstract_compression` without using weak filler to hit the ratio.

Apply these content rules while drafting:

```text
late_summer: sparse cicadas, short rain, retained heat, later dusk, cooling fabric,
             fruit, return journeys, street sound, windows, body sensation
evergreen: solitude, city night, ordinary objects, slight absurdity,
           incomplete emotion, low-intensity human connection
```

Do not include the three user seeds in the original draft count. Do not copy fragments from the research works into rows marked as original.

- [ ] **Step 3: Run the raw structural check**

Run:

```bash
ruby -rcsv -e 'r=CSV.read("/tmp/oraculo-corpus-2026-08-raw.csv",headers:true); abort "need >=150 drafts" if r.size<150; w=r.group_by{|x|x["content_window"]}.transform_values(&:size); abort "need >=105 late_summer" if w.fetch("late_summer",0)<105; abort "need >=45 evergreen" if w.fetch("evergreen",0)<45; allowed_w=%w[late_summer evergreen]; allowed_m=%w[life_slice strange_compound abstract_compression]; allowed_t=%w[light dark]; abort "bad enum" unless r.all?{|x|allowed_w.include?(x["content_window"])&&allowed_m.include?(x["mechanism"])&&allowed_t.include?(x["tone_shade"])}; puts({rows:r.size,windows:w,mechanisms:r.group_by{|x|x["mechanism"]}.transform_values(&:size),tones:r.group_by{|x|x["tone_shade"]}.transform_values(&:size)})'
```

Expected: output reports at least 150 rows, at least 105 `late_summer`, at least 45 `evergreen`, and no abort message.

- [ ] **Step 4: Mark first-pass rejections in the temporary file**

Read every row and set `keep=no` plus a concrete `review_note` for drafts with any of these defects:

```text
slogan_or_blessing
therapy_copy
ai_syntax
empty_nature_stack
forced_four_character_symmetry
meaningless_strangeness
too_close_to_reference
duplicate_structure
awkward_reading
```

Set `keep=yes` only when the line has a concrete anchor or a defensible unfamiliar relationship and survives an aloud reading.

- [ ] **Step 5: Check exact duplicates against the current corpus and within the raw pool**

Run:

```bash
ruby -rcsv -e 'norm=->(s){s.to_s.gsub(/[[:space:]，。！？、,.!?]/,"")}; corpus=CSV.read("starbucks_now_passphrases.csv",headers:true).map{|x|norm[x["phrase"]]}.to_h{|x|[x,true]}; rows=CSV.read("/tmp/oraculo-corpus-2026-08-raw.csv",headers:true); seen={}; dup=[]; rows.each{|x|n=norm[x["phrase"]]; dup<<[x["draft_id"],x["phrase"],corpus[n] ? "main" : "batch"] if corpus[n]||seen[n]; seen[n]=true}; puts dup.map{|x|x.join("|")}; abort "exact duplicates remain" unless dup.empty?'
```

Expected: no duplicate lines and no abort. If duplicates appear, keep the strongest version, remove the others from the raw file, then add new original drafts so the raw pool remains at least 150 rows.

- [ ] **Step 6: Inspect AI-associated vocabulary and sentence frames**

Run:

```bash
rg -n '微光|奔赴|答案|治愈|慢慢|终会|热爱|好事正在路上|把.+交给|也温柔' /tmp/oraculo-corpus-2026-08-raw.csv
```

Expected: every match has a written, phrase-specific reason to survive; otherwise mark it `keep=no`. Do not treat the words as an automatic ban, but do not allow repeated uses in the survivor pool.

## Task 3: Add And Source The Homage Candidates

**Files:**
- Read: `review/corpus_references_2026_08.md`
- Modify temporarily: `/tmp/oraculo-corpus-2026-08-raw.csv`

- [ ] **Step 1: Add the three fixed user seeds**

Append these exact rows to the temporary pool with unique `draft_id` values and `keep=yes`:

```csv
seed_001,窗外的麻雀,evergreen,life_slice,light,用户提供；截断致敬《七里香》；作词方文山,yes,固定种子
seed_002,孤独海怪,evergreen,strange_compound,dark,用户提供；截断致敬万能青年旅店《秦皇岛》,yes,固定种子
seed_003,囿于昼夜,evergreen,abstract_compression,dark,用户提供；截断致敬万能青年旅店《揪心的玩笑与漫长的白日梦》,yes,固定种子
```

- [ ] **Step 2: Evaluate zero to six additional homage excerpts**

Choose an additional excerpt only when all conditions are true:

```text
the excerpt is short enough to stand alone;
its source work and creator are verified;
it fits Oraculo without relying on the full lyric;
an original candidate cannot preserve the same force;
the final homage count stays at or below nine.
```

Add accepted excerpts to the temporary file with `draft_id=homage_NNN`, an accurate mechanism and tone, `keep=yes`, and a source note naming the work and creator. Do not force six excerpts; unused homage slots become original slots in the final 90.

- [ ] **Step 3: Verify the homage ceiling and seed preservation**

Run:

```bash
ruby -rcsv -e 'r=CSV.read("/tmp/oraculo-corpus-2026-08-raw.csv",headers:true); h=r.select{|x|x["draft_id"].start_with?("seed_","homage_")}; abort "too many homages" if h.size>9; seeds=%w[窗外的麻雀 孤独海怪 囿于昼夜]; abort "missing seed" unless seeds.all?{|s|h.any?{|x|x["phrase"]==s&&x["keep"]=="yes"}}; puts({homage_count:h.size,seeds:seeds})'
```

Expected: `homage_count` is between three and nine and all three exact seeds are printed.

## Task 4: Curate The Canonical 90-Row CSV

**Files:**
- Create: `review/corpus_candidates_2026_08_late_summer.csv`
- Read: `/tmp/oraculo-corpus-2026-08-raw.csv`
- Read: `starbucks_now_passphrases.csv`

- [ ] **Step 1: Select the strongest 90 survivors**

From rows with `keep=yes`, select exactly 63 `late_summer` and 27 `evergreen` candidates. Preserve all three user seeds. Choose the final set by image specificity, semantic tension, aloud rhythm, distinctiveness from the existing corpus, and diversity from other finalists.

At least 70% of finalists must be four to six Chinese characters. All finalists must be three to nine characters; no more than three may be nine characters. Select 18-27 `dark` rows so the final dark ratio is 20%-30%.

- [ ] **Step 2: Create the canonical CSV**

Use `apply_patch` to create `review/corpus_candidates_2026_08_late_summer.csv` with this exact header and 90 rows:

```csv
candidate_no,phrase,content_window,mechanism,tone_shade,source_type,source_work,source_creator,source_url,risk_note,status,review_note
```

Apply these field rules:

```text
candidate_no: 1 through 90 with no gap
content_window: late_summer or evergreen
mechanism: life_slice, strange_compound, or abstract_compression
tone_shade: light or dark
source_type: original, user_seed, or homage_excerpt
source_work/source_creator/source_url: empty for original; complete for user_seed and homage_excerpt
risk_note: empty for original; concise attribution/commercial-review note for non-original
status: pending for every row
review_note: empty at delivery
```

The three user seeds use `source_type=user_seed`. Every other direct excerpt uses `source_type=homage_excerpt`; never label a direct excerpt `original`.

- [ ] **Step 3: Run the full CSV acceptance check**

Run:

```bash
ruby -rcsv -e 'p="review/corpus_candidates_2026_08_late_summer.csv"; r=CSV.read(p,headers:true); exp=%w[candidate_no phrase content_window mechanism tone_shade source_type source_work source_creator source_url risk_note status review_note]; abort "bad header" unless r.headers==exp; abort "need 90" unless r.size==90; abort "bad numbering" unless r.map{|x|x["candidate_no"].to_i}==(1..90).to_a; w=r.group_by{|x|x["content_window"]}.transform_values(&:size); abort "bad window split" unless w=={"late_summer"=>63,"evergreen"=>27}; seeds=%w[窗外的麻雀 孤独海怪 囿于昼夜]; abort "missing seeds" unless seeds.all?{|s|r.any?{|x|x["phrase"]==s&&x["source_type"]=="user_seed"}}; h=r.count{|x|x["source_type"]!="original"}; abort "homage ceiling" if h>9; abort "missing homage source" unless r.select{|x|x["source_type"]!="original"}.all?{|x|%w[source_work source_creator source_url risk_note].all?{|k|!x[k].to_s.strip.empty?}}; lens=r.map{|x|x["phrase"].length}; abort "bad lengths" unless lens.all?{|n|(3..9).include?(n)}&&lens.count{|n|(4..6).include?(n)}>=63&&lens.count(9)<=3; dark=r.count{|x|x["tone_shade"]=="dark"}; abort "bad dark ratio" unless (18..27).include?(dark); abort "bad status" unless r.all?{|x|x["status"]=="pending"}; puts({rows:r.size,windows:w,homages:h,dark:dark,lengths:lens.tally})'
```

Expected: one summary hash showing `rows=>90`, the exact window split, homage count at most nine, dark count between 18 and 27, and a compliant length distribution.

- [ ] **Step 4: Check exact duplicates and repeated final text**

Run:

```bash
ruby -rcsv -e 'norm=->(s){s.to_s.gsub(/[[:space:]，。！？、,.!?]/,"")}; main=CSV.read("starbucks_now_passphrases.csv",headers:true).map{|x|norm[x["phrase"]]}.to_h{|x|[x,true]}; r=CSV.read("review/corpus_candidates_2026_08_late_summer.csv",headers:true); seen={}; dup=[]; r.each{|x|n=norm[x["phrase"]]; dup<<[x["candidate_no"],x["phrase"],main[n] ? "main" : "batch"] if main[n]||seen[n]; seen[n]=true}; puts dup.map{|x|x.join("|")}; abort "duplicates remain" unless dup.empty?'
```

Expected: no output and no abort. Replace any duplicate with the strongest unused, already-audited original draft, then rerun Tasks 4 Steps 3-4.

- [ ] **Step 5: Audit repeated words and sentence skeletons manually**

Run:

```bash
ruby -rcsv -e 'r=CSV.read("review/corpus_candidates_2026_08_late_summer.csv",headers:true); chars=Hash.new(0); r.each{|x|x["phrase"].chars.each{|c|chars[c]+=1}}; puts chars.sort_by{|k,v|[-v,k]}.first(25).map{|k,v|"#{k}:#{v}"}'
rg -n '微光|奔赴|答案|治愈|慢慢|终会|热爱|好事正在路上|把.+交给|也温柔' review/corpus_candidates_2026_08_late_summer.csv
```

Expected: no unexplained concentration in one image family or high-frequency model frame. Read all matches in context; replace weak matches rather than defending them by rule exception.

## Task 5: Create The Shuffled Markdown Review View

**Files:**
- Create: `review/corpus_candidates_2026_08_late_summer.md`
- Read: `review/corpus_candidates_2026_08_late_summer.csv`

- [ ] **Step 1: Freeze a deterministic shuffled order in the CSV**

Reorder the 90 CSV rows into a visually mixed sequence so adjacent rows do not share the same mechanism, central image, or tone where avoidable. Renumber `candidate_no` from 1 to 90 after reordering. The CSV order is now the canonical review order; do not independently shuffle the Markdown.

- [ ] **Step 2: Re-run the CSV acceptance and duplicate checks**

Run Task 4 Steps 3 and 4 again after reordering.

Expected: the exact same acceptance summary and no duplicate output.

- [ ] **Step 3: Create the Markdown review file**

Create `review/corpus_candidates_2026_08_late_summer.md` with this structure:

```markdown
# 2026-08 夏末入秋候选语料

- 候选：90 条
- 内容：夏末入秋 63 条，常青 27 条
- 说明：先凭直觉选择；回复编号即可。标注“致敬”的条目会在入库前再次确认来源风险。

| # | 候选 | 来源 |
| ---: | --- | --- |
```

Immediately after the header separator, add one table row per CSV row in identical order using `| candidate_no | phrase | source |`. For `original`, leave 来源 blank. For `user_seed` and `homage_excerpt`, show `致敬：作品 / 创作者`; do not expose internal mechanism, window, or tone fields in Markdown.

- [ ] **Step 4: Verify Markdown/CSV identity**

Run:

```bash
ruby -rcsv -e 'csv=CSV.read("review/corpus_candidates_2026_08_late_summer.csv",headers:true).map{|x|[x["candidate_no"].to_i,x["phrase"]]}; md=File.readlines("review/corpus_candidates_2026_08_late_summer.md",encoding:"UTF-8").filter_map{|l|m=l.match(/^\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|/); [m[1].to_i,m[2].strip] if m}; abort "Markdown/CSV mismatch" unless md==csv; puts "Markdown matches all #{csv.size} CSV rows"'
```

Expected: `Markdown matches all 90 CSV rows`.

## Task 6: Final Editorial Review, Commit, And User Handoff

**Files:**
- Verify: `review/corpus_references_2026_08.md`
- Verify: `review/corpus_candidates_2026_08_late_summer.csv`
- Verify: `review/corpus_candidates_2026_08_late_summer.md`

- [ ] **Step 1: Perform a fresh editorial read**

Read the Markdown from 1 through 90 without consulting mechanism labels. For every candidate, confirm:

```text
it reads naturally aloud;
it contains a concrete anchor or defensible unfamiliar relation;
it stands alone without explanation;
it does not sound like a poster, therapy prompt, or AI-generated blessing;
it is not merely a weaker variation of another finalist.
```

Replace any failure with an unused audited draft, then rerun all Task 4 and Task 5 validation commands.

- [ ] **Step 2: Review only owned file changes**

Run:

```bash
git status --short
git diff --check -- review/corpus_references_2026_08.md review/corpus_candidates_2026_08_late_summer.csv review/corpus_candidates_2026_08_late_summer.md
git diff --stat -- review/corpus_references_2026_08.md review/corpus_candidates_2026_08_late_summer.csv review/corpus_candidates_2026_08_late_summer.md
```

Expected: only the three owned review files are new or modified by this plan. `ios/Oraculo.xcodeproj/project.pbxproj` may still appear as an unrelated unstaged modification and must not be changed or staged.

- [ ] **Step 3: Commit the candidate review artifacts**

If Task 1 already committed the research ledger, stage only the two candidate files. Otherwise stage all three owned files. Never use `git add .`.

Run:

```bash
git add review/corpus_candidates_2026_08_late_summer.csv review/corpus_candidates_2026_08_late_summer.md
git diff --cached --check
git diff --cached --stat
git commit -m "docs(corpus): add August candidate review"
```

Expected: a commit containing the CSV and Markdown review artifacts only. The unrelated Xcode project file remains unstaged.

- [ ] **Step 4: Verify the final repository state**

Run:

```bash
git show --stat --oneline HEAD
git status --short
```

Expected: the latest commit lists only the two candidate review files; `ios/Oraculo.xcodeproj/project.pbxproj` remains the only unrelated working-tree modification.

- [ ] **Step 5: Hand the review batch to the user and stop**

Report the candidate-file links, exact 63/27 split, homage count, dark count, length distribution, and commit SHA. Ask the user to reply with selected candidate numbers and any rewrite instructions.

Do not create the accepted CSV or run any production command in the same turn. The next phase starts only after the user's selection is unambiguous.
