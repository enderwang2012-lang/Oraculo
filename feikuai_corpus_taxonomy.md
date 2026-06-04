# 啡快式情绪语库标签体系

## 目标

这份标签体系用于管理真实样本、训练生成模型、筛选候选句，以及未来在产品中按情境调用。

原则：

- 标签要服务生成，不只是服务归档
- 标签要能区分“句子为什么有效”
- 标签数量适中，避免过细导致无法稳定标注

## 一级标签

每条语料至少应标注以下一级字段：

- `id`
- `text`
- `source_type`
- `era`
- `emotion_theme`
- `intent`
- `tone`
- `scene`
- `imagery`
- `energy_level`
- `openness_score`
- `confidence`
- `notes`

## 字段定义

### `id`

唯一标识符。

建议格式：

`gen_000001`

真实样本与 AI 生成样本不要共用同一前缀。

### `text`

短语正文。

规则：

- 保留最终展示文本
- 不含解释语
- 不含引号

### `source_type`

语料来源。

可选值：

- `real_official`
- `real_social_verified`
- `real_social_text`
- `generated_candidate`
- `generated_selected`
- `generated_rejected`

用途：
区分“真实世界证据”和“AI 生产阶段位置”。

### `era`

语气年代层。

可选值：

- `early_playful`
- `dramatic_comfort`
- `lucky_signature`
- `daily_softness`
- `ip_lyric_pool`

说明：

- `early_playful`：2019 前后的人设感、玩梗感
- `dramatic_comfort`：2020-2021 的轻社死和戏剧化安慰
- `lucky_signature`：2022-2024 的好运签风格
- `daily_softness`：2025-2026 的轻柔日常动作句
- `ip_lyric_pool`：联名、歌词、主题词池

### `emotion_theme`

句子主要承接的情绪母题。

可选值：

- `light_comfort`
- `soft_hope`
- `daily_romance`
- `self_affirmation`
- `gentle_departure`
- `playful_identity`
- `festival_blessing`
- `lyric_resonance`

说明：

- `light_comfort`：轻安慰
- `soft_hope`：微光、等待、向好靠近
- `daily_romance`：日常诗意与生活画面
- `self_affirmation`：自我确认与自我站稳
- `gentle_departure`：轻推向前、重新开始
- `playful_identity`：人设、轻玩笑、轻标签
- `festival_blessing`：节日、新年、节点祝愿
- `lyric_resonance`：联名、歌词、共同记忆

### `intent`

句子的首要功能。

可选值：

- `soothe`
- `hold`
- `nudge`
- `bless`
- `mirror`
- `delight`

说明：

- `soothe`：缓和焦虑
- `hold`：承接此刻情绪
- `nudge`：往前轻推
- `bless`：轻祝福
- `mirror`：把心境照出来
- `delight`：制造一点小惊喜

### `tone`

句子的说话气质。

可选值：

- `warm`
- `light`
- `playful`
- `calm`
- `bright`
- `tender`
- `cool`

说明：

- `warm`：温暖但不腻
- `light`：轻巧不压人
- `playful`：带一点机灵或梗感
- `calm`：稳、松、放缓
- `bright`：有光感和生长感
- `tender`：更柔，更贴近心事
- `cool`：更克制、更少表态

### `scene`

最适合出现的生活场景。

可多选，建议从以下词表中取：

- `commute`
- `work_pause`
- `late_night`
- `decision_wait`
- `meeting_friend`
- `travel`
- `rainy_day`
- `restart`
- `holiday`
- `self_time`
- `after_setback`
- `love_resonance`
- `festival`
- `season_change`

### `imagery`

句子主要依靠什么意象成立。

可选值：

- `wind_light`
- `road_distance`
- `season_weather`
- `daily_life`
- `inner_state`
- `gift_luck`
- `lyric_ip`
- `none_minimal`

说明：

- `wind_light`：风、光、云、晴、曙光
- `road_distance`：路上、远方、出发、抵达
- `season_weather`：春天、夏天、霜、暖阳
- `daily_life`：见面、烟火、世界、留白
- `inner_state`：心缓、从容、坦荡
- `gift_luck`：好运、惊喜、礼物、加满
- `lyric_ip`：歌词或联名主题
- `none_minimal`：几乎不靠画面，靠语气成立

### `energy_level`

句子的推动能量。

可选值：

- `low`
- `mid`
- `high`

说明：

- `low`：安静、松弛、停一下
- `mid`：柔和地继续
- `high`：更明显地鼓劲

默认优先 `low` 和 `mid`，慎用 `high`。

### `openness_score`

句子的投射空间，1 到 5 分。

定义：

- `1`：意义很死，几乎没有投射空间
- `2`：方向明确，余地较少
- `3`：有一定开放性
- `4`：开放度高，容易代入
- `5`：极强留白，几乎人人可投射

建议：

- 正式语库优先保留 `3-5`
- `1-2` 通常更像功能文案，不宜作为核心资产

### `confidence`

这句是否稳。

可选值：

- `core`
- `good`
- `borderline`
- `reject`

说明：

- `core`：非常稳，适合做风格锚点
- `good`：合格且可用
- `borderline`：可留待复审
- `reject`：不进正式语库

### `notes`

补充判断。

记录内容可包括：

- 为什么打动人
- 哪个词用得特别准
- 哪一处接近鸡汤边缘
- 与已有句子是否语义过近

## 推荐的二级词表

当需要更细分类时，可用以下二级标签补充：

- `micro_emotion`
  - `tired`
  - `hesitating`
  - `waiting`
  - `starting_over`
  - `missing_someone`
  - `quiet_happiness`
  - `self_doubt`
  - `need_space`

- `movement_shape`
  - `arriving`
  - `opening`
  - `softening`
  - `growing`
  - `clearing`
  - `staying`

- `social_shareability`
  - `private_only`
  - `shareable`
  - `highly_shareable`

## 标注示例

### 示例 1

`心缓自有答案`

- `emotion_theme`: `light_comfort`
- `intent`: `soothe`
- `tone`: `calm`
- `scene`: `decision_wait`
- `imagery`: `inner_state`
- `energy_level`: `low`
- `openness_score`: `4`
- `confidence`: `core`

### 示例 2

`给生活一点留白`

- `emotion_theme`: `daily_romance`
- `intent`: `hold`
- `tone`: `tender`
- `scene`: `self_time`
- `imagery`: `daily_life`
- `energy_level`: `low`
- `openness_score`: `5`
- `confidence`: `core`

### 示例 3

`重要的是出发`

- `emotion_theme`: `gentle_departure`
- `intent`: `nudge`
- `tone`: `warm`
- `scene`: `restart`
- `imagery`: `road_distance`
- `energy_level`: `mid`
- `openness_score`: `4`
- `confidence`: `core`

### 示例 4

`家是唯一城堡`

- `emotion_theme`: `lyric_resonance`
- `intent`: `mirror`
- `tone`: `playful`
- `scene`: `love_resonance`
- `imagery`: `lyric_ip`
- `energy_level`: `mid`
- `openness_score`: `3`
- `confidence`: `good`

## 语库分层建议

正式产品语库建议分三层：

- `anchor`
  风格锚点句。数量少，但决定产品灵魂。
- `active`
  日常可投放主力句。
- `lab`
  边缘但有趣的实验句，持续观察。

不要把所有合格句一股脑放进主库。触感要靠筛选密度维持。
