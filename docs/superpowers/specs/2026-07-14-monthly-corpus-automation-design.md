# Oraculo Monthly Corpus Automation Design

**Date:** 2026-07-14

**Status:** Approved in conversation; awaiting written-spec review

**Owner:** Oraculo corpus workflow

## Objective

Create a recurring Codex task that starts at 10:00 Asia/Shanghai on the first day of every month. The task produces 80-100 Chinese corpus candidates informed by that month's season, time, solar terms, and holidays, then stops for human review. After the user explicitly approves the final selection and authorizes publication, the same task promotes the accepted phrases, generates all required metadata, validates the corpus, publishes the static hot update, and verifies production.

The workflow must improve from month to month by storing explicit, auditable editorial feedback in the repository. It must not depend on a model informally remembering previous conversations.

## Success Criteria

- A new isolated monthly task starts at 10:00 Asia/Shanghai on day 1 of every month.
- Each task produces 80-100 reviewable candidates and does not modify production corpus data before approval.
- The user can accept, reject, or rewrite candidates using stable candidate IDs.
- A message that contains both a final selection and an explicit publish instruction opens the release gate.
- Only accepted final text is promoted to the primary corpus.
- Accepted phrases receive English paraphrases, dispatch tags, freshness tags, and generated static assets without `TODO` values or unknown tags.
- The task never force-pushes or publishes after a failed pre-push gate.
- A successful release is reported only after the production corpus version and SHA match the local release.
- Monthly review decisions update a transparent editorial profile used by subsequent runs.

## Scope

The automation covers:

- Monthly candidate generation and review artifacts.
- Editorial feedback capture and cumulative preference learning.
- Promotion of accepted candidates into the existing corpus source.
- English poetic paraphrases required by the bilingual corpus.
- Existing dispatch, semantic, and freshness tagging pipelines.
- Corpus version bump, static build, Git publication, and production verification.

The automation does not cover:

- App code or corpus schema changes.
- App Store or TestFlight releases.
- Model fine-tuning or uploading editorial data to a training service.
- Automatic publication without an explicit per-month human approval.
- Force pushes, destructive conflict resolution, or automatic production rollback.

## Chosen Approach

Use one recurring Codex automation with a standalone task and isolated Git worktree for each monthly run. Candidate generation, discussion, revisions, approval, release, and verification remain in the same task so that IDs, feedback, and release state share one audit trail.

The monthly task should be named with its period, for example `Oraculo 月度语料更新 · 2026-08`. Its working branch should follow `codex/corpus-YYYY-MM` or the equivalent worktree branch supplied by Codex.

An isolated worktree prevents candidate files and generated corpus artifacts from colliding with uncommitted changes in the user's primary checkout. The automation must commit only files owned by the monthly corpus workflow.

## Schedule

- Frequency: monthly.
- Day: first day of the month.
- Time: 10:00.
- Time zone: Asia/Shanghai.
- Candidate volume: 80-100.
- Expected accepted volume: 12-20, treated as a target rather than a quota.

Quality takes precedence over the expected accepted count. A smaller explicitly approved set may be released.

## Monthly Task Lifecycle

1. Create an isolated task and worktree for the current month.
2. Read the latest corpus, tag vocabulary, calendar configuration, recent review history, cumulative editorial profile, and production manifest.
3. Generate the monthly candidate CSV and Markdown review document.
4. Stop before any production corpus, version, or public asset mutation.
5. Accept review discussion, rejection reasons, and rewrites in the same task.
6. Continue only after receiving an unambiguous final selection and publish instruction.
7. Freeze the structured review state used by both promotion and editorial learning.
8. Refresh `origin/main`; resolve only conflict-free updates and stop on ambiguous conflicts.
9. Promote accepted text, generate required English text and tags, rebuild, and run all release gates.
10. Commit only monthly corpus workflow changes.
11. Recheck `origin/main`, then fast-forward push the validated commit to `origin/main` without force.
12. Poll and verify production deployment.
13. Report release evidence and the editorial-profile changes that will influence the next run.

## Candidate Inputs

Each monthly run reads:

- `starbucks_now_passphrases.csv` and the embedded/current corpus outputs.
- Existing dispatch and freshness metadata.
- `config/solar_terms_cn.json`.
- `config/festivals_cn.json`.
- The current tag vocabulary and overrides.
- Recent monthly candidate decisions, including accepted, rejected, rewritten, and promoted entries.
- The cumulative editorial profile.
- The production manifest, for baseline version and SHA awareness.

Calendar scope defaults to mainland China's 24 solar terms, statutory holidays, and traditional festivals. Seasonal language should remain broadly applicable across China and should not present one city's current weather as a national fact. Overseas or commercial holidays are excluded unless they clearly fit Oraculo's editorial character.

Solar terms and holidays are creative context, not mandatory literal words. The task should prefer an image that implies the time of year when naming the solar term or holiday would weaken the phrase.

## Candidate Composition

Use flexible ranges rather than hard quotas:

- 45-55% seasonal and temporal experience: temperature, wind, rain, vegetation, light, day length, bodily feeling, and changing life rhythm.
- 15-20% solar-term and holiday context, usually expressed indirectly.
- 20-25% human monthly life: commuting, resting, gathering, solitude, departure, waiting, and similar lived scenes.
- 10-15% weakly seasonal or evergreen phrases, preventing the batch from having an unnecessarily narrow display window.

Generation uses a controlled exploration balance:

- 70% extends directions validated by prior acceptance and rewrites.
- 20% explores adjacent imagery, scenes, and rhythms while retaining the established voice.
- 10% explores less expected directions that still satisfy hard quality constraints.

These percentages guide coverage and diversity; they must not justify weak filler.

## Editorial Constraints

- Prefer 3-8 Chinese characters, centered on 4-6 characters with natural variance.
- Favor imagery, action, bodily feeling, warmth, poetry, and interpretive space.
- Avoid slogans, motivational cliches, commands, marketing language, and overly explanatory colloquial text.
- Do not turn style principles such as `留白` into emitted categories or tags.
- Avoid overconcentration in one length, opening word, image family, or cadence.
- Do not force direct solar-term, festival, or date names into a phrase for coverage.
- Treat explicitly stated user preferences as hard editorial guidance until the user changes them.

## Duplicate And Diversity Checks

Before presenting candidates:

1. Remove exact duplicates of the primary corpus and the current batch.
2. Compare against historical candidates for close text and repeated core imagery.
3. Inspect semantic-cluster and cadence distribution to avoid a structurally repetitive batch.
4. Flag residual similarity risk in the review output instead of silently presenting near-copies as novel work.

## Review Artifacts

Each monthly task produces:

- A concise direction and historical-feedback summary in the task.
- `review/monthly/YYYY-MM/candidates.md`, grouped into early-month, mid-month, late-month, and evergreen sections.
- `review/monthly/YYYY-MM/candidates.csv`, the structured source of truth for review and promotion.
- `review/monthly/YYYY-MM/retrospective.md`, written after the review is finalized.
- `review/editorial_profile.json`, the cumulative machine-readable editorial profile.

Each candidate receives a stable ID such as `202608-C001`. The structured record includes:

- Candidate ID.
- Chinese phrase.
- Inspiration and intended time window.
- Brief creative rationale.
- Suggested context tags.
- Similarity risk.
- Status: `candidate`, `accepted`, `rejected`, `needs_rewrite`, or `promoted`.
- Optional rejection or rewrite note.
- Final text when it differs from the original candidate.

Candidate-stage tags are suggestions only. They do not mutate formal tag configuration.

The current `scripts/promote_corpus_candidates.py` rewrites a smaller six-column candidate schema. Implementation must either extend that script backward-compatibly to preserve the richer monthly fields or generate a normalized six-column promotion input from the frozen monthly CSV. It must not pass unsupported extra columns to the current writer or let promotion discard the monthly review evidence.

## Human Review Protocol

The user may select stable IDs, reject items, request rewrites, or supply replacement text in natural language. The task maps the response into structured review state and shows any ambiguity instead of guessing.

Interpretation rules:

- `accepted`: use the original candidate text.
- Rewritten and accepted: use the user's final text and preserve the original/final pair as a high-value learning example.
- `rejected`: exclude from promotion; store a supplied reason as editorial evidence.
- `needs_rewrite`: generate a targeted revision round and remain behind the approval gate.
- Unmentioned candidates remain unresolved unless the user explicitly states that all remaining items are rejected.
- Positive but ambiguous comments are discussion, not release authorization.
- A publish run starts only when the message contains both a final selection and explicit publication intent, such as `批准这些内容并发布`.

The final structured review snapshot, not a new free-form interpretation of chat, is the sole input to promotion. This makes retries deterministic.

## Editorial Learning Model

Continuous improvement is explicit repository data, not implicit model memory. The workflow maintains:

- Monthly decision records containing all candidates and their final status.
- A monthly retrospective summarizing accepted directions, rejected patterns, rewrites, and next-month adjustments.
- A cumulative editorial profile containing hard rules, learned preferences, aversions, evidence counts, confidence, and source periods.

Signal strength follows this order:

1. Explicit user editorial instructions become high-priority constraints immediately.
2. User rewrite pairs are the strongest behavioral evidence.
3. Repeated acceptance raises a direction's weight without licensing imitation of the same phrase structure.
4. A rejection with a reason is stronger than a rejection without one.
5. A single unexplained rejection remains weak evidence.
6. Repeated evidence across multiple months may become a stable avoidance or preference rule.

The task reviews the latest three monthly records in detail for current taste and uses the full cumulative profile for established long-term rules.

Before every candidate batch, the task presents a short `本月如何应用历史反馈` summary. The user may correct it; explicit corrections override inferred preferences. All learned rules remain traceable and reversible.

## Approval Gate

Candidate generation may write only review and learning-preview artifacts. Before approval it must not:

- Promote candidates into `starbucks_now_passphrases.csv`.
- Change `scripts/phrases_en.json` or formal tag data.
- Increment `config/corpus_version.txt`.
- Regenerate committed bundle or public corpus assets.
- Commit, push, or trigger deployment.

The user's explicit message combining final selection and publication intent authorizes the remaining release flow for that month. No second approval is required unless an error or conflict changes the approved content or release scope.

## Promotion And Metadata

After approval:

1. Persist the final review snapshot and editorial-learning update.
2. Run `scripts/promote_corpus_candidates.py` against the month's accepted CSV.
3. Allocate new IDs while respecting existing and deleted IDs.
4. Generate poetic English paraphrases for every accepted phrase.
5. Fail if any accepted phrase leaves a `TODO` or missing English value.
6. Generate deterministic freshness metadata.
7. Generate rule-based and semantic dispatch metadata.
8. Use `onlyWhen` only for genuinely reliable constraints; do not hard-lock an otherwise evergreen phrase merely because it was inspired by a particular month.
9. Validate every emitted tag against `config/tag_vocabulary.json`.

## Build And Pre-Push Gates

The release uses the existing pipeline represented by `scripts/rebuild_corpus.py --publish --bump`:

```text
tag_phrase_freshness
validate_corpus
tag_phrases_rules
tag_phrases_llm
validate_dispatch
validate_phrase_freshness
embed_corpus
publish_corpus_static
```

It also runs:

```bash
python3 -m unittest tests/test_tag_phrases_rules.py tests/test_phrase_freshness_tags.py
python3 scripts/validate_release_readiness.py
```

Before commit, assert:

- No duplicate primary phrases.
- No missing or `TODO` English paraphrases.
- Every new phrase has valid dispatch and freshness data.
- The corpus version increased exactly once from the latest accepted baseline.
- Bundle metadata, `public/oraculo/`, and the generated manifest use one version and SHA line.
- The diff contains only monthly review/learning records, corpus source, required translation/tag metadata, version data, and generated corpus artifacts.
- No unrelated Xcode project or application source changes are included.

Any pre-push failure stops the workflow with no commit, push, or deployment. The task reports the failed command and preserves the isolated worktree for diagnosis.

## Git Publication

After all gates pass:

1. Commit with a message such as `chore(corpus): publish 2026-08 monthly phrases`.
2. Fetch `origin/main` again.
3. If it changed, synchronize the monthly branch and rerun affected validations.
4. Stop on any ambiguous conflict.
5. Push only as a fast-forward update from the validated monthly commit to `origin/main`.
6. Never force-push.

The publication path must not require switching or cleaning the user's primary checkout.

## Production Verification

After the push triggers Vercel, poll the production endpoint for up to ten minutes. Confirm:

- Production `corpusVersion` equals the local release version.
- Manifest SHA equals the locally generated phrase SHA.
- Downloaded `phrases.json` hashes to the manifest SHA.
- The JSON is valid and the phrase list is non-empty.
- Every newly promoted ID and final Chinese text appears in production.

`scripts/verify_corpus_cdn.py` may be used, but exact equality with the expected local version and SHA is mandatory even if the existing script only performs broader checks.

The task must distinguish `GitHub push succeeded` from `Vercel production deployment verified`. A verification timeout is not reported as a successful release.

## Failure And Recovery Rules

- Candidate-generation failure: report the missing input or generation issue; do not create a partial review batch as if complete.
- Ambiguous review state: remain behind the approval gate and ask for clarification.
- Pre-push validation failure: stop without external publication and preserve evidence in the worktree.
- Main-branch conflict: stop; do not auto-resolve content conflicts or overwrite upstream changes.
- Push rejection: fetch and reassess; never force-push.
- Post-push deployment timeout: report that GitHub is updated but production remains unverified.
- Post-push SHA or content mismatch: stop and report production state. Do not automatically roll back, because a valid hot-update rollback requires another version increment and a deliberate new release.

## Final Monthly Report

After a verified release, report:

- Candidate, accepted, rejected, and rewritten counts.
- Newly assigned formal IDs and final text.
- Previous and new corpus versions.
- Release commit SHA.
- Local and production phrase SHA.
- Deployment verification result.
- Editorial-profile changes learned from the month.
- Directions to expand or reduce in the next monthly run.

## Testing Strategy

Implementation verification must cover:

- Schedule and time-zone configuration.
- Worktree isolation from a dirty primary checkout.
- Candidate generation without production mutations.
- Exact approval-gate behavior for explicit, ambiguous, and rewrite-heavy review responses.
- Stable candidate IDs and deterministic retry from the frozen review snapshot.
- Editorial-profile updates from acceptance, rejection, and rewrite signals.
- No overfitting from a single unexplained rejection.
- Promotion of accepted entries only.
- English translation completeness.
- Tag vocabulary, dispatch, freshness, and primary corpus validation.
- Version and SHA consistency across local generated outputs.
- Fast-forward-only Git publication behavior.
- Exact production version, SHA, and new-ID verification.
- Accurate partial-state reporting when GitHub succeeds but Vercel verification does not.

## Implementation Notes

The Codex automation prompt should be self-contained and refer to repository scripts and files rather than embedding a second implementation of corpus logic. Where the repository lacks a deterministic operation needed by the automation, such as structured editorial-profile maintenance or exact expected-version CDN verification, implementation should add a focused script with tests rather than rely on ad hoc prompt reasoning.

The initial automation is complete only when its schedule, project binding, isolated execution environment, prompt, and enabled status have been inspected after creation.
