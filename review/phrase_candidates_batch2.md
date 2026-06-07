# 候选语料审阅 · phrase_candidates_batch2.csv

- 总数 **50**　通用兜底 **1**　硬锁场合 **49**
- 疑似重复 **0**（无）
- 标签校验告警 **0**（全部合法）

场合分布（硬锁 onlyWhen）：

| 维度 | 条数 |
| --- | --- |
| season | 20 |
| festival | 15 |
| month | 5 |
| weather | 5 |
| daypart | 4 |

在「取舍」列写 ✅/❌，或直接删行。

| 取舍 | id | 句子 | 出现时机 | 标签 | 备注 |
| --- | --- | --- | --- | --- | --- |
|  | sb_2001 | 来杯冰美式 | 夏天 | 仅当 season:summer | OK |
|  | sb_2002 | 第一口冰咖啡最上头 | 夏天 | 仅当 season:summer | OK |
|  | sb_2003 | 空调和西瓜不能少 | 夏天 | 仅当 season:summer | OK |
|  | sb_2004 | 今天又想吃冰的了 | 夏天 | 仅当 season:summer | OK |
|  | sb_2005 | 傍晚的风总算凉了 | 夏天 | 仅当 season:summer；加权 weather:windy×1.2 | OK |
|  | sb_2006 | 楼下的青蛙好聒噪 | 夏天 | 仅当 season:summer | OK |
|  | sb_2021 | 妈妈包的粽子最好吃 | 端午 | 仅当 festival:dragon_boat | OK |
|  | sb_2022 | 甜粽还是咸粽你站哪边 | 端午 | 仅当 festival:dragon_boat | OK |
|  | sb_2023 | 月亮今晚好像特别圆 | 中秋 | 仅当 festival:mid_autumn | OK |
|  | sb_2035 | 一年已经过半了 | 6月 | 仅当 month:6 | OK |
|  | sb_2041 | 下雨天最适合赖床 | 雨天 | 仅当 weather:rain | OK |
