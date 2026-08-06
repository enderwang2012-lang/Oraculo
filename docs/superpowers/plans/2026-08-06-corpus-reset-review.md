# 248 条语料全量重置与审核计划

## 目标

- 为源台账 248 条语料建立逐条、可追溯的编辑审核记录。
- 重新决定每条语料的保留、降级或退出状态，避免只依赖缺省 lifecycle。
- 重新整理编辑主题、语义簇、句式组和情境派发标签。
- 修正当前审核发现的英文副标题、情境门槛、freshness 过度分组和文档口径问题。
- 生成本地 v9 候选并完成验证，不在本次工作中直接发布 CDN。

## 非目标

- 不修改用户已有的 Xcode 工程脏改动。
- 不自动扩展到新的月度候选批次。
- 不把本地 v9 候选视为已发布，不执行 push、Vercel 部署或生产切换。
- 不把内容来源审查记录改写成法律授权证明。

## 约定

- `starbucks_now_passphrases.csv` 继续保留原始来源台账；原始 `theme` 和 `evidence` 不删除。
- 新增审核台账作为逐条编辑决策源，记录 `decision`、`editorialTheme`、`semanticCluster`、`cadenceGroup`、`englishStatus`、`dispatchStatus`、`reviewReason`。
- 248 条按从未曝光的初始候选重新审核，不读取旧 lifecycle 作为内容证据。
- 内容决定使用 `keep`、`needs_rewrite`、`retire`；只有 `keep` 进入本地候选。
- 所有保留项 lifecycle 统一为 `active`；`needs_rewrite` 与 `retire` 暂用 `retired` 排除出候选，不使用 `cooling`、`new` 或 `anchor` 权重。
- 生成后的英文、dispatch、freshness 均必须覆盖 248 个源 ID，即使条目最终 retired。

## 实施顺序

1. 从当前 248 条源台账和 v8 产物生成完整审核台账，补齐 248 条显式决策。
2. 将审核台账中的编辑主题、语义簇、句式组和生命周期写入生成所需配置。
3. 修正英文副标题；优先处理明显不自然、主客体反转和含义漂移的条目。
4. 修正 dispatch 硬门槛，重点覆盖霜降、小满、六月过半和其它字面季节/节气句。
5. 重做 cadence 分组，使用可解释的结构桶，不再用首尾字把几乎每条句子拆成独立组。
6. 更新审核文档和运行文档，使 248 条源台账、v9 本地候选和生产 v8 状态不再混写。
7. 运行重建、结构校验、派发校验、新鲜度校验、测试和本地产物 SHA 校验。

## 验证

- `python3 scripts/validate_corpus.py`
- `python3 scripts/validate_dispatch.py`
- `python3 scripts/validate_phrase_freshness.py`
- `python3 scripts/validate_release_readiness.py --allow-unpublished-candidate`
- `python3 -m unittest discover -s tests`
- 核对源台账 248 条、审核台账 248 条、freshness/dispatch/英文配置各 248 条。
- 核对本地 v9 payload 数量、SHA256、manifest 和生产 v8 未发生变更。

## 发布边界

本次只生成本地 v9 候选。只有用户明确确认最终条目和发布意图后，才执行版本递增、静态发布和生产 CDN 回读。

## 已知风险

- 248 条中包含 observed、generated 和 user-provided 三类来源；编辑质量决策不能替代来源权利判断。
- 改变 payload 会改变抽取分布，必须用 freshness 模拟和真实体验复核，而不能只看结构测试。
- 英文是诗意 paraphrase，仍需保证自然、无明显语义反转，不能以逐字直译为唯一标准。
