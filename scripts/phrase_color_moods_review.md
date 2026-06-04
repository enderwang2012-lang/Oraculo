# 句的 colorMoods / colorBan 建议初值

**这是 AI 跑规则给出的建议**，需要你扫一眼接受/否决/改写。

判定优先级：`colorBan` 硬剔除 > `colorMoods` 加权 ×2。
绝大多数句子不需要标——只标真正需要色情绪约束的。

**操作**：你认可的，把 colorMoods/colorBan 字段合并到 `phrase_dispatch.json`；
不认可的直接忽略。重跑 embed_corpus.py 把改动嵌入 phrases.json。

---

### sb_1 — 今日锦鲤
- theme: 好运祝福
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['dark']`
- 原因: theme=好运祝福→喜庆 warm，ban dark

### sb_13 — 喜欢夏天
- theme: 季节心情
- 当前 onlyWhen: ['season:summer']
- 建议 colorMoods: `['warm']`
- 原因: 夏→warm

### sb_26 — 他夏了夏天
- theme: 歌曲与季节
- 当前 onlyWhen: ['season:summer']
- 建议 colorMoods: `['warm']`
- 原因: 夏→warm

### sb_39 — 最是一年春好处
- theme: 春季诗意
- 当前 onlyWhen: ['season:spring']
- 建议 colorMoods: `['warm', 'light']`
- 原因: 春→warm+light（樱粉系）

### sb_41 — 冬日暖阳
- theme: 冬季温暖
- 当前 onlyWhen: ['season:winter']
- 建议 colorMoods: `['warm']`
- 原因: 冬日暖阳→warm

### sb_42 — 月是秋夜明
- theme: 秋夜诗意
- 当前 onlyWhen: ['season:autumn']
- 建议 colorMoods: `['warm']`
- 原因: 秋→warm（无 earthy 桶，落 warm）

### sb_43 — 秋天开始喝暖饮
- theme: 秋季饮品
- 当前 onlyWhen: ['season:autumn']
- 建议 colorMoods: `['warm']`
- 原因: 秋→warm（无 earthy 桶，落 warm）

### sb_61 — 是最喜欢的秋天啊
- theme: 秋季心情
- 当前 onlyWhen: ['season:autumn']
- 建议 colorMoods: `['warm']`
- 原因: 秋→warm（无 earthy 桶，落 warm）

### sb_68 — 诸事皆宜
- theme: 好运祝福
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['dark']`
- 原因: theme=好运祝福→喜庆 warm，ban dark

### sb_109 — 为热爱 敢上场
- theme: 热爱鼓励
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['cool']`
- 原因: 字面热→ban cool

### sb_141 — 热烈自由
- theme: 自由鼓励
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['cool']`
- 原因: 字面热→ban cool

### sb_162 — 夏天拍了拍你
- theme: 季节画面
- 当前 onlyWhen: ['season:summer']
- 建议 colorMoods: `['warm']`
- 原因: 夏→warm

### sb_173 — 万物热情开朗
- theme: 生活浪漫
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['cool']`
- 原因: 字面热→ban cool

### sb_194 — 被礼物包围
- theme: 节日祝福
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['dark']`
- 原因: theme=节日祝福→喜庆 warm，ban dark

### sb_196 — 春天在路上
- theme: 季节画面
- 当前 onlyWhen: ['season:spring']
- 建议 colorMoods: `['warm', 'light']`
- 原因: 春→warm+light（樱粉系）

### sb_204 — 热爱是生活解药
- theme: 生活鼓励
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['cool']`
- 原因: 字面热→ban cool

### sb_231 — 五月天盛夏
- theme: 联名主题
- 当前 onlyWhen: ['season:summer']
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['cool']`
- 原因: 夏→warm; 字面热→ban cool

### sb_244 — 抓住夏天
- theme: 联名主题
- 当前 onlyWhen: ['season:summer']
- 建议 colorMoods: `['warm']`
- 原因: 夏→warm

### sb_255 — 桃气启新芳
- theme: 节日祝福
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['dark']`
- 原因: theme=节日祝福→喜庆 warm，ban dark

### sb_260 — 兔里兔气
- theme: 节日祝福
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['dark']`
- 原因: theme=节日祝福→喜庆 warm，ban dark

### sb_263 — 苹苹安安
- theme: 节日祝福
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['dark']`
- 原因: theme=节日祝福→喜庆 warm，ban dark

### sb_275 — 热爱经久不息
- theme: 生活鼓励
- 当前 onlyWhen: []
- 建议 colorMoods: `['warm']`
- 建议 colorBan: `['cool']`
- 原因: 字面热→ban cool

### sb_280 — 逐梦可乘凉
- theme: 行动鼓励
- 当前 onlyWhen: ['season:summer']
- 建议 colorMoods: `['warm']`
- 原因: 夏→warm
