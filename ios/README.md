# Oraculo iOS

极简「每日一句」+ 主屏 / 锁屏小组件。语料来自 `starbucks_now_passphrases.csv`（`python3 scripts/embed_corpus.py` → `Shared/Resources/phrases.json`）。

## 环境

- **Xcode 15+**（建议 16），且须为完整 Xcode（非仅 Command Line Tools）
- **iOS 17.0+** 部署目标
- 可选：[XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`），用于从 `project.yml` 再生工程

若 `xcodebuild` 报错，请切换开发者目录：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## 一键启动

在仓库根目录：

```bash
./scripts/bootstrap_ios.sh
```

或分步：

```bash
python3 scripts/starbucks_phrases_en.py
python3 scripts/embed_corpus.py
cd ios && xcodegen generate
open Oraculo.xcodeproj
```

在 Xcode 中：

1. 选中 **Oraculo** target → **Signing & Capabilities** → 选择你的 **Team**
2. 对 **OraculoWidget** 重复；确认 App Group `group.ai.oraculo.shared` 已启用
3. 运行 **Oraculo** scheme（模拟器或真机）

命令行编译（需完整 Xcode）：

```bash
cd ios
xcodebuild -project Oraculo.xcodeproj -scheme Oraculo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## 工程结构

| 路径 | 说明 |
| --- | --- |
| `project.yml` | XcodeGen 定义（改后执行 `xcodegen generate`） |
| `Oraculo.xcodeproj` | 已生成的 Xcode 工程 |
| `Oraculo/` | 主 App SwiftUI |
| `OraculoWidget/` | Widget + 锁屏 |
| `Shared/` | 选句、配色、JSON（双 target 共享） |

## 更新语料

```bash
python3 scripts/starbucks_phrases_en.py
python3 scripts/embed_corpus.py
```

然后在 Xcode **Product → Clean Build Folder** 后重新运行。

## 行为说明

**小组件 / App Group（按日）**

- 键：本地时区 `yyyy-MM-dd`
- 句：`FNV-1a(dayKey) % 语料数`；色：`dayKey + "|color"`
- Timeline 在次日 0 点刷新

**App 主界面（每次进前台）**

- `OracleSessionModel.refreshOnOpen()`：随机句 + 色（尽量避免与当前重复）
- 背景 1.15s 叠化 + 文字淡出/淡入

详见 [docs/PRODUCT.md](../docs/PRODUCT.md)。

## 模拟器安装失败（IXErrorDomain / Invalid placeholder attributes）

多为 Widget 的 `Info.plist` 缺少 `NSExtension` → `com.apple.widgetkit-extension`。本仓库已在 `project.yml` 的 `OraculoWidget.info.properties` 中配置。若你改过工程，请：

```bash
cd ios && xcodegen generate
```

然后在 Xcode：**Product → Clean Build Folder** → **⌘R**。

## 后续可做

- [ ] 缩 Nippon 色板子集
- [ ] 内嵌 LXGW 文楷
- [ ] 锁屏 Circular 组件
- [ ] TestFlight
