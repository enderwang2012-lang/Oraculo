# Current Corpus Full Tag Table

- Source: `dist/corpus/phrases.json` + `config/phrase_context_tags.json` + `starbucks_now_passphrases.csv`
- One row per phrase; includes runtime dispatch and archival semantic tags.

| ID | 中文 | 英文 | CSV Theme | Emotion Theme | Layer | Meta Emotion | Tone | Scenes | Universal | Only When | Boost Tags | Negative | Color Moods | Color Ban | Color Families |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sb_1 | 今日锦鲤 | Lucky koi, today | 好运祝福 | luck_blessing | anchor | luck_blessing | bright |  | True |  | festival:spring_festival:3.0<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_2 | 文艺青年 | Artsy soul | 身份标签 | playful_meme | anchor | playful_meme | playful |  | True |  |  |  | cool | warm |  |
| sb_3 | 都挺好 | All's well enough | 流行文化与安慰 | playful_meme | anchor | playful_meme | playful |  | True |  |  |  | light | dark |  |
| sb_4 | 小天使啊 | Little angel | 亲昵身份 | playful_meme | active | playful_meme | tender |  | True |  |  |  | light | dark |  |
| sb_5 | 能力不嫌多 | Skills never hurt | 鼓励 | gentle_departure | active | gentle_departure | warm | restart | True |  | scene:restart:1.0 |  | warm | dark |  |
| sb_6 | 锦鲤本鲤 | Koi incarnate | 好运身份 | luck_blessing | active | luck_blessing | bright |  | True |  | festival:spring_festival:3.0 |  | warm | dark |  |
| sb_7 | 凌波微步 | Light on water | 武侠玩梗 | playful_meme | active | playful_meme | playful |  | True |  |  |  | light | dark |  |
| sb_8 | 魅力四射 | Radiant charm | 自我肯定 | self_affirmation | active | self_affirmation | bright |  | True |  |  |  | warm | dark |  |
| sb_9 | 这么优秀 | So brilliant | 自我肯定 | self_affirmation | active | self_affirmation | bright |  | True |  |  |  | warm | dark |  |
| sb_10 | 鸟语蝉鸣 | Birdsong, cicada hum | 季节景象 | daily_romance | active | daily_romance | tender |  | True |  |  |  | light | dark |  |
| sb_11 | 别人家孩子 | That golden child | 身份玩梗 | playful_meme | active | playful_meme | playful |  | True |  |  |  | light | dark |  |
| sb_12 | 突然开心 | Sudden joy | 即时心情 | daily_romance | active | daily_romance | bright |  | True |  | daypart:afternoon:0.6 |  | light | dark |  |
| sb_13 | 喜欢夏天 | Summer's favorite | 季节心情 | daily_romance | active | daily_romance | tender |  | False | season:summer |  |  | warm | dark |  |
| sb_17 | 屠龙刀 | Dragon-slaying blade | 武侠玩梗 | playful_meme | active | playful_meme | playful |  | True |  |  |  | light | dark |  |
| sb_20 | 蔚蓝海面 | Azure sea | 夏日景象 | daily_romance | active | daily_romance | cool | travel | True |  | season:summer:2.0<br>weather:clear:1.5<br>scene:travel:1.2 |  | cool | warm | blue |
| sb_21 | 去潜水吧 | Go dive | 夏日行动 | gentle_departure | active | gentle_departure | warm | travel | True |  | scene:travel:1.2 |  | cool | warm |  |
| sb_22 | 万物生长 | Everything grows | 自然季节 | daily_romance | active | daily_romance | tender | season_change | True |  | season:spring:2.0<br>solar_term:jingzhe:1.5 |  | cool<br>light | dark | green |
| sb_23 | 水上乐园 | Water park dreams | 夏日场景 | daily_romance | active | daily_romance | tender |  | True |  |  |  | cool | warm |  |
| sb_25 | 唯快不破 | Speed wins all | 速度与武侠 | playful_meme | active | playful_meme | playful | commute | True |  | scene:commute:1.0 |  | cool | warm |  |
| sb_26 | 他夏了夏天 | He summered summer | 歌曲与季节 | daily_romance | active | daily_romance | playful | season_change | False | season:summer | season:summer:2.0 |  | warm<br>light | dark |  |
| sb_29 | 乌云散开 | Clouds disperse | 治愈鼓励 | light_comfort | active | light_comfort | bright | after_setback | True |  | weather:overcast:1.2<br>weather:clear:2.5<br>scene:after_setback:1.5 |  | light | dark |  |
| sb_31 | 烦恼退散 | Worries scatter | 治愈祝福 | light_comfort | active | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_32 | 人间值得 | The world still holds you | 治愈肯定 | light_comfort | active | light_comfort | tender | after_setback | True |  | scene:after_setback:1.5 |  | light | dark |  |
| sb_33 | 奥利给 | Let's go! | 网络流行语 | playful_meme | active | playful_meme | playful | work_pause | True |  | scene:work_pause:1.0 |  | warm | dark |  |
| sb_34 | 妙啊妙啊 | Nice, so nice | 网络口语 | playful_meme | active | playful_meme | playful |  | True |  |  |  | light | dark |  |
| sb_37 | 重启试试 | Reboot and try | 日常玩梗 | playful_meme | active | playful_meme | playful | restart | True |  | scene:restart:1.2 |  | light | dark |  |
| sb_39 | 最是一年春好处 | Spring at its best | 春季诗意 | daily_romance | active | daily_romance | tender | season_change | False | season:spring | season:spring:2.0<br>solar_term:yushui:1.5 |  | light<br>warm | dark |  |
| sb_40 | 新一年总晴天 | Sunny year ahead | 新年祝福 | luck_blessing | active | luck_blessing | bright | restart | False | festival:spring_festival | weather:clear:2.0<br>festival:spring_festival:2.5<br>festival:new_year:1.5<br>scene:restart:1.2 |  | warm<br>light | dark |  |
| sb_41 | 冬日暖阳 | Winter sun warmth | 冬季温暖 | daily_romance | active | daily_romance | warm |  | False | season:winter | weather:clear:2.0<br>temp:cold:1.5 |  | warm | cool |  |
| sb_42 | 月是秋夜明 | Autumn moon, bright night | 秋夜诗意 | lyric_image | active | lyric_image | calm |  | False | season:autumn | daypart:late_night:1.2<br>festival:mid_autumn:2.5 |  | dark | light |  |
| sb_43 | 秋天开始喝暖饮 | Warm drinks, autumn starts | 秋季饮品 | daily_romance | active | daily_romance | tender |  | False | season:autumn |  |  | warm | dark |  |
| sb_45 | 美好拉开帷幕 | Beauty takes the stage | 希望鼓励 | soft_hope | active | soft_hope | bright | restart | True |  | scene:restart:1.2 |  | light | dark |  |
| sb_49 | 平安喜乐 | Peace and quiet joy | 平安祝福 | luck_blessing | active | luck_blessing | bright |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_50 | 财神到家 | Fortune at the door | 财运祝福 | luck_blessing | active | luck_blessing | bright |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_51 | 岁岁常欢愉 | Joy every year | 长久祝福 | luck_blessing | active | luck_blessing | bright | festival | False | festival:spring_festival | festival:new_year:4.0<br>festival:lantern_festival:3.0 |  | warm | dark |  |
| sb_52 | 年年皆胜意 | Winning years ahead | 长久祝福 | luck_blessing | active | luck_blessing | bright |  | False | festival:spring_festival | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_53 | 暴富暴瘦暴酷 | Rich, lean, cool | 夸张祝福 | playful_meme | active | playful_meme | playful |  | True |  |  |  | warm | dark |  |
| sb_58 | 笑出强大 | Laugh with power | 鼓励玩梗 | playful_meme | active | playful_meme | playful | after_setback | True |  | scene:after_setback:1.0 |  | warm | dark |  |
| sb_59 | 最靓的仔 | Coolest one around | 身份自夸 | self_affirmation | active | self_affirmation | playful |  | True |  |  |  | warm | dark |  |
| sb_60 | Hi走啦 | Hi, I'm off | 口语玩梗 | playful_meme | active | playful_meme | playful | commute | True |  | scene:commute:1.0 |  | light | dark |  |
| sb_61 | 是最喜欢的秋天啊 | Favorite season: fall | 秋季心情 | daily_romance | active | daily_romance | tender |  | False | season:autumn |  |  | warm | dark |  |
| sb_64 | 天选之子 | Chosen one | 好运身份 | luck_blessing | active | luck_blessing | bright |  | True |  | festival:new_year:1.5 |  | warm | dark |  |
| sb_65 | 全能小天才 | Little prodigy | 身份自夸 | self_affirmation | active | self_affirmation | playful |  | True |  |  |  | warm | dark |  |
| sb_66 | 甩碗米线 | Tossed bowl noodles | 食物奇趣 | playful_meme | active | playful_meme | playful | work_pause | True |  | scene:work_pause:0.8 |  | warm | dark |  |
| sb_67 | 冲鸭冲鸭 | Go go duck! | 网络鼓励 | playful_meme | active | playful_meme | playful | restart | True |  | scene:restart:1.2 |  | warm | dark |  |
| sb_68 | 诸事皆宜 | All things auspicious | 好运祝福 | luck_blessing | active | luck_blessing | bright |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_69 | 水逆绕行 | Mercury, step aside | 转运祝福 | light_comfort | active | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_70 | 快乐一夏 | Summer of joy | 夏日祝福 | luck_blessing | active | luck_blessing | bright | season_change | True |  | season:summer:2.0 |  | warm<br>light | dark |  |
| sb_71 | 赐予你力量 | Power granted you | 鼓励祝福 | soft_hope | active | soft_hope | bright | restart | True |  | scene:restart:1.2 |  | warm | dark |  |
| sb_73 | 美式发生 | Americano happens | 咖啡谐音与好运 | playful_meme | active | playful_meme | playful |  | True |  |  |  | light | dark |  |
| sb_74 | 莫愁前路无知己 | Friends await ahead | 前路安慰 | light_comfort | active | light_comfort | calm | after_setback<br>travel | True |  | scene:travel:1.2<br>scene:after_setback:1.2 |  | light | dark |  |
| sb_76 | 浪漫不止 | Romance unending | 浪漫祝福 | daily_romance | active | daily_romance | tender | travel | True |  | scene:travel:1.2 |  | cool | warm |  |
| sb_77 | 好事将至 | Grace still on its way | 好运预告 | soft_hope | active | soft_hope | bright |  | True |  | festival:new_year:1.5 |  | light<br>warm | dark |  |
| sb_78 | 新年有新意 | Fresh year, fresh spark | 新年祝福 | luck_blessing | active | luck_blessing | bright |  | False | festival:spring_festival | festival:spring_festival:3.0<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_80 | 五月被期待填满 | May, full of hope | 月份希望 | soft_hope | active | soft_hope | tender | season_change | False | month:5 | month:5:2.0 |  | light | dark |  |
| sb_81 | 厉害了爹地们 | Dads on fire | 称呼玩梗 | playful_meme | active | playful_meme | playful |  | True |  |  |  | warm | dark |  |
| sb_83 | 悄悄惊艳大家 | Quietly dazzling all | 学习鼓励 | gentle_departure | active | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_91 | 自由是终极魔法 | Freedom, final magic | 哈利波特联名 | ip_collab | anchor | ip_collab | playful | travel | True |  | theme:ip:1.5<br>scene:travel:1.2 |  | cool | warm |  |
| sb_93 | 向上生长 | Grow upward | 成长鼓励 | gentle_departure | active | gentle_departure | warm | restart | True |  | scene:restart:1.2 |  | warm<br>light | dark |  |
| sb_94 | 今天的你赞赞赞 | Triple thumbs-up today | 夸赞鼓励 | self_affirmation | anchor | self_affirmation | bright |  | True |  |  |  | light | dark |  |
| sb_95 | 万事皆合时宜 | All in season | 顺遂祝福 | soft_hope | anchor | soft_hope | bright | festival | True |  | festival:spring_festival:2.0<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_96 | 赤诚亦勇敢 | Fierce and sincere | 人格鼓励 | self_affirmation | anchor | self_affirmation | bright |  | True |  |  |  | warm | dark | red |
| sb_99 | 新年万事定称心 | New year, heart's desire | 新年祝福 | luck_blessing | anchor | luck_blessing | bright |  | False | festival:spring_festival | festival:spring_festival:3.0<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_100 | 挂霜予你 | Frost for you | 秋季温柔 | daily_romance | anchor | daily_romance | tender |  | True |  | weather:snow:1.5<br>temp:cold:2.0<br>solar_term:shuangjiang:2.0 |  | light<br>cool | dark |  |
| sb_101 | 新春开门红 | Spring opens red-hot | 新年祝福 | luck_blessing | active | luck_blessing | bright |  | False | festival:spring_festival | festival:spring_festival:3.0<br>festival:new_year:1.5 |  | warm | dark | red |
| sb_102 | 诸事皆顺 | All flows smooth | 顺遂祝福 | soft_hope | active | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | light | dark |  |
| sb_103 | take it easy. | Take it easy. | 英文鼓励 | latin_phrase | active | latin_phrase | bright |  | True |  |  |  | light | dark |  |
| sb_104 | be real. | Be real. | 英文鼓励 | latin_phrase | active | latin_phrase | bright |  | True |  |  |  | light | dark |  |
| sb_105 | good vibes. | Good vibes. | 英文祝福 | latin_phrase | active | latin_phrase | bright |  | True |  |  |  | light | dark |  |
| sb_106 | dare to dream. | Dare to dream. | 英文鼓励 | latin_phrase | active | latin_phrase | bright |  | True |  |  |  | light | dark |  |
| sb_107 | 每一次全力以赴 | Every effort, whole heart | 努力鼓励 | gentle_departure | active | gentle_departure | warm | restart<br>work_pause | True |  | scene:restart:1.2<br>scene:work_pause:0.8 |  | warm | dark |  |
| sb_108 | 愿将来胜过往 | May tomorrow outshine yesterday | 未来祝福 | soft_hope | active | soft_hope | tender |  | True |  |  |  | light | dark |  |
| sb_109 | 为热爱 敢上场 | For love, take the field | 热爱鼓励 | gentle_departure | active | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_111 | 硕果累累 | Heavy with fruit | 收获祝福 | luck_blessing | active | luck_blessing | bright | season_change | True |  | season:autumn:1.8 |  | warm | dark | yellow |
| sb_112 | 记得微笑 | Let the smile come | 日常提醒 | daily_romance | active | daily_romance | tender |  | True |  | daypart:morning:0.8 |  | light | dark |  |
| sb_113 | 事缓则圆 | Haste softens into roundness | 从容劝慰 | light_comfort | active | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_116 | 适时转弯 | Turn in good time | 从容劝慰 | light_comfort | anchor | light_comfort | calm |  | True |  |  |  | light | dark |  |
| sb_117 | 远方很美 | Far places shine | 远方浪漫 | daily_romance | anchor | daily_romance | tender | travel | True |  | scene:travel:1.2 |  | cool | warm |  |
| sb_118 | 烦恼消除术 | Worry-dissolving spell | 治愈劝慰 | light_comfort | anchor | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_121 | 做你自己就很好 | As you are, enough | 自我肯定 | self_affirmation | active | self_affirmation | bright |  | True |  |  |  | warm | dark |  |
| sb_122 | 清风为我翻书 | Breeze reads for me | 文艺治愈 | light_comfort | active | light_comfort | calm | self_time | True |  | weather:windy:2.5<br>weather:clear:1.5<br>scene:self_time:1.2 |  | cool<br>light | dark |  |
| sb_123 | 心宽路则宽 | Wide heart, wide road | 从容劝慰 | light_comfort | active | light_comfort | calm |  | True |  |  |  | light | dark |  |
| sb_124 | 天高任鸟飞 | Sky high, birds roam | 自由鼓励 | gentle_departure | active | gentle_departure | cool | travel | True |  | scene:travel:1.2<br>weather:clear:1.5 |  | cool | warm | blue |
| sb_125 | 重要的是出发 | What matters: leaving | 行动鼓励 | gentle_departure | active | gentle_departure | warm | travel | True |  | scene:travel:1.2 |  | warm | dark |  |
| sb_128 | 见面是最棒的事 | Meeting beats all | 相见温情 | daily_romance | active | daily_romance | tender | meeting_friend | True |  | scene:meeting_friend:1.2 |  | light | dark |  |
| sb_129 | 新序章 | New chapter | 新起点 | gentle_departure | active | gentle_departure | warm | restart | True |  | scene:restart:1.2 |  | warm | dark |  |
| sb_130 | 宜相见 | Meet today | 相见温情 | daily_romance | active | daily_romance | tender | meeting_friend | True |  | scene:meeting_friend:1.2 |  | light | dark |  |
| sb_131 | 轻松自在 | Easy and free | 从容治愈 | light_comfort | active | light_comfort | calm | self_time | True |  | scene:self_time:1.0 |  | light | dark |  |
| sb_132 | 惬意个登儿 | Blissfully laid-back | 方言口语 | playful_meme | active | playful_meme | playful |  | True |  |  |  | light | dark |  |
| sb_133 | 一路风光一路诗 | Scenic road, verse road | 旅途浪漫 | daily_romance | active | daily_romance | tender |  | True |  | weather:windy:2.0 |  | cool<br>light | dark<br>warm |  |
| sb_138 | 大有可为 | Much to accomplish | 未来鼓励 | soft_hope | active | soft_hope | bright | restart | True |  | scene:restart:1.2 |  | warm | dark |  |
| sb_140 | 自由在风里 | Freedom in the wind | 自由浪漫 | daily_romance | active | daily_romance | tender |  | True |  | weather:windy:2.0 |  | cool | warm |  |
| sb_141 | 热烈自由 | Fierce and free | 自由鼓励 | gentle_departure | active | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_142 | 所行皆坦途 | Smooth every path | 前路祝福 | soft_hope | active | soft_hope | tender | travel | True |  | scene:travel:1.2 |  | light | dark |  |
| sb_143 | 美好常在 | Beauty stays near | 美好祝福 | soft_hope | active | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_144 | 有趣有盼无忧虑 | Fun, hope, no frets | 生活祝福 | soft_hope | active | soft_hope | bright | self_time | True |  | scene:self_time:1.0 |  | light | dark |  |
| sb_146 | 大声称赞自己 | Praise yourself aloud | 自我肯定 | self_affirmation | anchor | self_affirmation | bright |  | True |  |  |  | light | dark |  |
| sb_147 | 卓然前行 | Walk with distinction | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm | travel | True |  | scene:travel:1.2 |  | warm | dark |  |
| sb_148 | 思路清晰 | Mind, crystal clear | 状态鼓励 | soft_hope | anchor | soft_hope | tender |  | True |  |  |  | light | dark |  |
| sb_149 | 愿前程可奔赴 | May paths be runnable | 前路祝福 | soft_hope | anchor | soft_hope | tender | travel | True |  | scene:travel:1.2 |  | light | dark |  |
| sb_150 | 爱人间烟火 | Love street-life glow | 生活浪漫 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | warm | dark |  |
| sb_151 | 状态不掉线 | Never drop offline | 状态鼓励 | soft_hope | anchor | soft_hope | tender |  | True |  |  |  | light | dark |  |
| sb_152 | 生活向美而生 | Life grows toward beauty | 生活浪漫 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | light | dark |  |
| sb_153 | 所念皆所愿 | Wishes thought, granted | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_154 | 有诗有远方 | Verse and far horizons | 生活浪漫 | daily_romance | anchor | daily_romance | tender | travel | True |  | scene:travel:1.2 |  | cool | warm |  |
| sb_155 | 无往而不胜 | Victorious wherever | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_156 | 开启高光模式 | Highlight mode on | 状态鼓励 | soft_hope | anchor | soft_hope | tender |  | True |  |  |  | warm<br>light | dark |  |
| sb_157 | 总有人正年轻 | Someone's always young | 人生感怀 | quiet_mirror | anchor | quiet_mirror | calm |  | True |  |  |  | cool | warm |  |
| sb_158 | 每一刻充满可能 | Each moment, possibility | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_160 | 努力的样子很酷 | Trying looks cool | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_161 | 只记欢喜不记忧 | Joy remembered, not sorrow | 治愈劝慰 | light_comfort | anchor | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | warm | dark |  |
| sb_162 | 夏天拍了拍你 | Summer tapped your shoulder | 季节画面 | daily_romance | anchor | daily_romance | tender |  | False | season:summer |  |  | light | dark |  |
| sb_163 | 心之所愿定如愿 | Heart's wish, fulfilled | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_164 | 鸟语花香 | Birdsong, floral air | 季节画面 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | light | dark |  |
| sb_165 | 前行有曙光 | Dawn ahead on the road | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm | travel | True |  | weather:clear:2.0<br>scene:travel:1.2 |  | warm<br>light | dark |  |
| sb_166 | 大笑是困难解药 | Laughter, hardship's cure | 治愈劝慰 | light_comfort | anchor | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_169 | 去踏千重浪 | Wade thousand waves | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm | travel | True |  | scene:travel:1.2 |  | cool | warm |  |
| sb_171 | 心动由己 | Heart moves by you | 自我肯定 | self_affirmation | anchor | self_affirmation | bright |  | True |  | festival:valentine:2.0 |  | warm | dark |  |
| sb_172 | 不留憾 | Leave no what-ifs | 生活态度 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | light | dark |  |
| sb_174 | 爱，不止此刻 | Love beyond this moment | 情感表达 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | warm | dark |  |
| sb_175 | 心向旷野 | Heart toward wild plains | 自由浪漫 | daily_romance | anchor | daily_romance | tender | travel | True |  | scene:travel:1.2 |  | cool | warm |  |
| sb_176 | 恰到好处 | Just enough, just right | 生活态度 | daily_romance | anchor | daily_romance | tender | self_time | True |  | scene:self_time:1.0 |  | light | dark |  |
| sb_177 | 喝着咖啡吹着风 | Coffee, wind in hair | 生活浪漫 | daily_romance | anchor | daily_romance | tender |  | True |  | weather:windy:2.0 |  | cool | warm |  |
| sb_181 | 抬头望天接好运 | Look up, catch luck | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5<br>weather:clear:2.0 |  | cool | dark<br>warm |  |
| sb_183 | 期待新的故事 | New story awaited | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_184 | 今日最佳 | Today's finest | 自我肯定 | self_affirmation | anchor | self_affirmation | bright |  | True |  |  |  | warm | dark |  |
| sb_186 | 忙有度 闲有趣 | Busy bounded, leisure lit | 生活态度 | daily_romance | anchor | daily_romance | tender | self_time | True |  | scene:self_time:1.0 |  | light | dark |  |
| sb_187 | 去有风的地方 | Where the wind lives | 自由浪漫 | daily_romance | anchor | daily_romance | tender | travel | True |  | weather:windy:2.0<br>scene:travel:1.2 |  | cool | warm |  |
| sb_188 | 小满胜万全 | Almost full beats perfect | 生活态度 | daily_romance | anchor | daily_romance | tender |  | True |  | solar_term:xiaoman:2.0 |  | light | dark |  |
| sb_189 | 恰逢好事 | Good thing, right time | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_190 | 你值得玫瑰 | Roses owed to you | 自我肯定 | self_affirmation | anchor | self_affirmation | tender | love_resonance | True |  | festival:valentine:3.0 |  | warm | dark | red<br>pink |
| sb_194 | 被礼物包围 | Wrapped in gifts | 节日祝福 | luck_blessing | anchor | luck_blessing | bright | festival | True |  | festival:christmas:4.0<br>festival:spring_festival:2.0 |  | warm | dark |  |
| sb_195 | 慢下来看世界 | Slow down, see world | 生活态度 | daily_romance | anchor | daily_romance | tender | self_time | True |  | scene:self_time:1.0 |  | light | dark |  |
| sb_197 | 你亦是风景 | You are scenery too | 生活浪漫 | daily_romance | anchor | daily_romance | tender |  | True |  | weather:windy:2.0 |  | cool | warm |  |
| sb_198 | 曙光在前 | Dawn up ahead | 前路祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | weather:clear:2.0 |  | warm<br>light | dark |  |
| sb_199 | 新起点 | Fresh starting line | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm | restart | True |  | scene:restart:1.2 |  | warm | dark |  |
| sb_200 | 家是唯一城堡 | Home, only castle | 联名主题 | ip_collab | anchor | ip_collab | playful |  | True |  | theme:ip:1.5 |  | light | dark |  |
| sb_201 | 手牵手 | Hand in hand | 联名主题 | ip_collab | anchor | ip_collab | playful | meeting_friend | True |  | theme:ip:1.5<br>festival:valentine:2.0<br>scene:meeting_friend:1.2 |  | light | dark |  |
| sb_205 | 心缓自有答案 | Unhurried heart, quiet knowing | 治愈劝慰 | light_comfort | active | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_206 | 前路漫漫亦灿灿 | Long road, still glittering | 前路祝福 | soft_hope | active | soft_hope | tender | travel | True |  | scene:travel:1.2 |  | light | dark |  |
| sb_207 | 好运挡不住 | Luck unstoppable | 美好祝福 | soft_hope | active | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_208 | 无忧亦无惧 | Carefree, unafraid | 生活态度 | daily_romance | active | daily_romance | tender |  | True |  |  |  | light | dark |  |
| sb_209 | 向前看 | Eyes forward | 行动鼓励 | gentle_departure | active | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_210 | 好心情正发芽 | Good mood sprouting | 治愈劝慰 | light_comfort | active | light_comfort | calm |  | True |  |  |  | light | dark |  |
| sb_212 | 注入满满元气 | Infuse full vitality | 状态鼓励 | soft_hope | active | soft_hope | tender |  | True |  | daypart:morning:0.8 |  | warm | dark |  |
| sb_213 | 追光的人会发光 | Light-chasers glow | 行动鼓励 | gentle_departure | active | gentle_departure | warm |  | True |  |  |  | warm<br>light | dark |  |
| sb_214 | 你自信又坦荡 | You, bold and open | 自我肯定 | self_affirmation | active | self_affirmation | bright |  | True |  |  |  | warm | dark |  |
| sb_215 | 人生无限可能 | Life, infinite maybe | 未来祝福 | soft_hope | active | soft_hope | tender |  | True |  |  |  | light | dark |  |
| sb_216 | 保持出发的心情 | Keep the leaving mood | 行动鼓励 | gentle_departure | active | gentle_departure | warm | travel | True |  | scene:travel:1.2 |  | warm | dark |  |
| sb_217 | 美好不期而至 | Beauty arrives unplanned | 美好祝福 | soft_hope | active | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_218 | 心动不如行动 | Heartbeat to motion | 行动鼓励 | gentle_departure | active | gentle_departure | warm |  | True |  | festival:valentine:2.0 |  | warm | dark |  |
| sb_219 | 自有明月照山河 | Moon lights hills and rivers | 诗性意象 | lyric_image | active | lyric_image | calm | travel | True |  | daypart:late_night:1.0<br>scene:travel:1.2 |  | cool<br>dark | warm |  |
| sb_220 | 将来胜过往 | Tomorrow beats yesterday | 未来祝福 | soft_hope | active | soft_hope | tender |  | True |  |  |  | light | dark |  |
| sb_221 | 成为自己的宇宙 | A cosmos of your own | 自我肯定 | self_affirmation | active | self_affirmation | bright |  | True |  |  |  | warm | dark |  |
| sb_222 | 新一年多爱自己 | New year, more self-love | 自我肯定 | self_affirmation | active | self_affirmation | bright | restart | True |  | scene:restart:1.2 |  | warm | dark |  |
| sb_227 | 与万事言和 | At peace with all things | 治愈劝慰 | light_comfort | active | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_228 | 执手天涯 | Hands held, world's end | 情感表达 | daily_romance | active | daily_romance | tender | meeting_friend<br>travel | True |  | festival:valentine:2.0<br>scene:travel:1.2<br>scene:meeting_friend:1.2 |  | light | dark |  |
| sb_236 | 去疯去爱 | Run wild, love hard | 联名主题 | ip_collab | anchor | ip_collab | playful |  | True |  | theme:ip:1.5 |  | warm | dark |  |
| sb_237 | 有失有得 | Lose some, gain some | 联名主题 | ip_collab | anchor | ip_collab | playful |  | True |  | theme:ip:1.5 |  | light | dark |  |
| sb_238 | 此刻纯真 | This moment, pure | 联名主题 | ip_collab | anchor | ip_collab | playful |  | True |  | theme:ip:1.5 |  | light | dark |  |
| sb_239 | 丢掉烦恼 | Drop the worries | 联名主题 | ip_collab | anchor | ip_collab | playful | after_setback | True |  | theme:ip:1.5<br>scene:after_setback:1.2 |  | light | dark |  |
| sb_240 | 知足此刻 | Enough, right now | 联名主题 | ip_collab | anchor | ip_collab | playful |  | True |  | theme:ip:1.5 |  | light | dark |  |
| sb_241 | 一起走吧 | Walk on together | 联名主题 | ip_collab | anchor | ip_collab | playful | meeting_friend | True |  | theme:ip:1.5<br>scene:meeting_friend:1.2 |  | light | dark |  |
| sb_242 | 勾勾手 | Pinky promise | 联名主题 | ip_collab | anchor | ip_collab | playful | meeting_friend | True |  | theme:ip:1.5<br>festival:valentine:2.0<br>scene:meeting_friend:1.2 |  | light | dark |  |
| sb_243 | 逆风飞翔 | Fly against wind | 联名主题 | ip_collab | anchor | ip_collab | playful |  | True |  | weather:windy:2.0<br>theme:ip:1.5 |  | cool | warm |  |
| sb_244 | 抓住夏天 | Catch the summer | 联名主题 | ip_collab | anchor | ip_collab | playful |  | False | season:summer | theme:ip:1.5 |  | light | dark |  |
| sb_245 | 宜见面 | Good day to meet | 情感表达 | daily_romance | active | daily_romance | tender | meeting_friend | True |  | scene:meeting_friend:1.2 |  | light | dark |  |
| sb_246 | 答案在路上 | Answers still en route | 治愈劝慰 | light_comfort | active | light_comfort | calm | travel | True |  | scene:travel:1.2 |  | light | dark |  |
| sb_247 | 好消息加载中 | Good news, buffering | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_248 | 不追风时吹吹风 | When still, feel breeze | 治愈劝慰 | light_comfort | anchor | light_comfort | calm | self_time | True |  | weather:windy:2.5<br>scene:self_time:1.2 |  | cool | warm |  |
| sb_249 | 把快乐加满 | Fill joy to brim | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_250 | 每天明媚媚 | Bright every day | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5<br>daypart:morning:0.8 |  | warm<br>light | dark |  |
| sb_251 | 允许一切发生 | Let all unfold | 治愈劝慰 | light_comfort | anchor | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_252 | 心愿得偿 | Wishes come true | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_254 | 可爱第一名 | Cutest rank one | 自我肯定 | self_affirmation | anchor | self_affirmation | bright |  | True |  |  |  | warm | dark |  |
| sb_255 | 桃气启新芳 | Peach scent, fresh bloom | 节日祝福 | luck_blessing | anchor | luck_blessing | bright |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm<br>light | dark | pink |
| sb_256 | 家人健康 | Family in health | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_257 | 新一年蓄力向上 | New year, charge upward | 新年祝福 | luck_blessing | anchor | luck_blessing | bright | restart | False | festival:spring_festival | festival:spring_festival:2.5<br>festival:new_year:1.5<br>scene:restart:1.2 |  | warm | dark |  |
| sb_258 | 向快乐出发 | Toward joy, depart | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm | travel | True |  | scene:travel:1.2<br>daypart:morning:0.8 |  | warm | dark |  |
| sb_259 | 咖啡自由 | Coffee freedom | 生活态度 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | cool | warm |  |
| sb_260 | 兔里兔气 | A bit bunny-ish | 节日祝福 | luck_blessing | anchor | luck_blessing | bright |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_261 | 给你所有好运 | All luck to you | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_262 | 十全十美 | Ten of ten perfect | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_263 | 苹苹安安 | Peace, apple-blessed | 节日祝福 | luck_blessing | anchor | luck_blessing | bright |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_264 | 有梦可期 | Dreams within reach | 未来祝福 | soft_hope | anchor | soft_hope | tender |  | True |  |  |  | light | dark |  |
| sb_265 | 听从内心 | Listen inside | 生活态度 | daily_romance | anchor | daily_romance | tender | self_time | True |  | scene:self_time:1.0 |  | light | dark |  |
| sb_266 | 总有远方可奔赴 | Always a far place to go | 前路祝福 | soft_hope | anchor | soft_hope | tender | travel | True |  | scene:travel:1.2 |  | cool | warm |  |
| sb_267 | 眉目舒展 | Brows unfurrowed | 治愈劝慰 | light_comfort | anchor | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_268 | 随心随性 | Heart-led, free-spirited | 生活态度 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | light | dark |  |
| sb_269 | 但行前路不辜负 | Walk on, don't betray road | 前路祝福 | soft_hope | anchor | soft_hope | tender | travel | True |  | scene:travel:1.2 |  | light | dark |  |
| sb_270 | 开心做自己 | Happy being you | 自我肯定 | self_affirmation | anchor | self_affirmation | bright |  | True |  |  |  | warm | dark |  |
| sb_271 | 有动力，有方向 | Drive and direction | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_272 | 努力沉淀 | Earn your depth | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_273 | 新年暴富 | New year, sudden wealth | 新年祝福 | luck_blessing | anchor | luck_blessing | bright |  | False | festival:spring_festival | festival:spring_festival:3.0<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_274 | 美好正在路上 | Beauty still inbound | 美好祝福 | soft_hope | anchor | soft_hope | tender | travel | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5<br>scene:travel:1.2 |  | warm | dark |  |
| sb_275 | 热爱经久不息 | Passion long-burning | 生活鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_276 | 今天起 新开始 | From today, restart | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm | restart | True |  | scene:restart:1.2<br>daypart:morning:0.8 |  | warm | dark |  |
| sb_277 | 时光清浅 | Time shallow-clear | 诗性意象 | lyric_image | anchor | lyric_image | calm |  | True |  |  |  | light | dark |  |
| sb_278 | 明媚的日子奔来 | Bright days rushing in | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm<br>light | dark |  |
| sb_279 | 所愿皆成真 | All wished-for, real | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_280 | 逐梦可乘凉 | Chase dreams in shade | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | False | season:summer |  |  | warm | dark |  |
| sb_281 | 云朵也自由 | Clouds roam free too | 自由浪漫 | daily_romance | anchor | daily_romance | tender |  | True |  | weather:clear:2.0 |  | cool | warm |  |
| sb_282 | 远方自明朗 | Far shores self-brighten | 前路祝福 | soft_hope | anchor | soft_hope | tender | travel | True |  | weather:clear:2.0<br>scene:travel:1.2 |  | cool<br>light | dark<br>warm |  |
| sb_286 | 昂首前瞻 | Head high, look on | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_287 | 自然会相逢 | You'll meet naturally | 情感表达 | daily_romance | anchor | daily_romance | tender | meeting_friend | True |  | scene:meeting_friend:1.2 |  | light | dark |  |
| sb_288 | 过滤烦恼 | Filter the frets | 治愈劝慰 | light_comfort | anchor | light_comfort | calm | after_setback | True |  | scene:after_setback:1.2 |  | light | dark |  |
| sb_289 | 保持好奇心 | Keep curiosity alive | 生活态度 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | light | dark |  |
| sb_290 | 风动心也动 | Wind moves, heart too | 情感表达 | daily_romance | anchor | daily_romance | tender |  | True |  | weather:windy:2.0 |  | cool | warm |  |
| sb_291 | 心情明媚 | Mood sunlit | 状态鼓励 | soft_hope | anchor | soft_hope | tender |  | True |  |  |  | warm<br>light | dark |  |
| sb_292 | 循梦而行 | Walk the dream line | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_293 | 美好不期而遇 | Beauty meets by chance | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_294 | 万象更新 | Ten thousand things renew | 新年祝福 | luck_blessing | anchor | luck_blessing | bright |  | False | festival:spring_festival | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_295 | 无限好运 | Luck without limit | 美好祝福 | soft_hope | anchor | soft_hope | tender |  | True |  | festival:spring_festival:2.5<br>festival:new_year:1.5 |  | warm | dark |  |
| sb_297 | 值得记录 | Worth the jotting down | 生活态度 | daily_romance | anchor | daily_romance | tender | self_time | True |  | scene:self_time:1.0 |  | light | dark |  |
| sb_299 | 无所不达 | Nothing out of reach | 前路祝福 | soft_hope | anchor | soft_hope | tender | travel | True |  | scene:travel:1.2 |  | light | dark |  |
| sb_300 | 慢慢懂得 | Slowly understood | 生活态度 | daily_romance | active | daily_romance | tender | self_time | True |  | scene:self_time:1.0 |  | light | dark |  |
| sb_302 | 保持好奇 | Stay curious | 生活态度 | daily_romance | anchor | daily_romance | tender |  | True |  |  |  | light | dark |  |
| sb_304 | 解锁新成就 | New achievement unlocked | 行动鼓励 | gentle_departure | anchor | gentle_departure | warm |  | True |  |  |  | warm | dark |  |
| sb_2001 | 来杯冰美式 | An iced americano, please | 季节心情 | daily_romance | active | daily_romance | cool | work_pause | False | season:summer | season:summer:2.5<br>temp:hot:2.0<br>daypart:afternoon:1.0 |  | cool | warm |  |
| sb_2002 | 第一口冰咖啡最上头 | First sip of iced coffee hits | 季节心情 | daily_romance | active | daily_romance | cool | work_pause | False | season:summer | season:summer:2.5<br>temp:hot:2.0<br>daypart:morning:0.8 |  | cool | warm |  |
| sb_2003 | 空调和西瓜不能少 | AC and watermelon, non-negotiable | 季节心情 | daily_romance | active | daily_romance | cool | self_time | False | season:summer | season:summer:2.5<br>temp:hot:2.0 |  | cool | warm |  |
| sb_2004 | 今天又想吃冰的了 | Craving something icy again | 季节心情 | daily_romance | active | daily_romance | playful | work_pause | False | season:summer | season:summer:2.5<br>temp:hot:2.0 |  | cool | warm |  |
| sb_2005 | 傍晚的风总算凉了 | Evening breeze finally cooled | 季节心情 | daily_romance | active | daily_romance | cool | self_time | False | season:summer | weather:windy:1.5<br>season:summer:2.0<br>daypart:evening:1.2 |  | cool<br>light | dark |  |
| sb_2006 | 楼下的青蛙好聒噪 | Frogs downstairs won't hush | 季节心情 | daily_romance | active | daily_romance | playful |  | False | season:summer | season:summer:2.0<br>daypart:late_night:1.0 |  | cool<br>dark | warm |  |
| sb_2021 | 妈妈包的粽子最好吃 | Mom's zongzi taste the best | 节日祝福 | luck_blessing | active | luck_blessing | warm | festival | False | festival:dragon_boat | festival:dragon_boat:4.0 |  | warm | dark |  |
| sb_2022 | 甜粽还是咸粽你站哪边 | Sweet or savory zongzi? | 节日祝福 | luck_blessing | active | luck_blessing | playful | festival | False | festival:dragon_boat | festival:dragon_boat:4.0 |  | warm | dark |  |
| sb_2023 | 月亮今晚好像特别圆 | Moon looks extra full tonight | 节日祝福 | luck_blessing | active | luck_blessing | calm | festival | False | festival:mid_autumn | festival:mid_autumn:4.0<br>daypart:evening:1.0 |  | light<br>dark | warm |  |
| sb_2035 | 一年已经过半了 | Half the year already gone | 人生感怀 | quiet_mirror | active | quiet_mirror | calm |  | False | month:6 | month:6:1.5 |  | cool | warm |  |
| sb_2041 | 下雨天最适合赖床 | Rainy days are made for sleeping in | 季节画面 | daily_romance | active | daily_romance | calm | rainy_day | False | weather:rain | weather:rain:3.0<br>scene:rainy_day:1.5 |  | cool<br>light | warm |  |
| sb_2042 | 站在能分割世界的桥 | Standing on a bridge that divides the world | 诗性意象 | lyric_image | active | lyric_image | calm | decision_wait<br>travel | True |  | scene:decision_wait:1.5<br>scene:travel:1.0 |  | cool<br>dark | warm |  |
