# Oraculo 1.0.0 审核说明

Oraculo 不需要账号，不包含登录、购买或订阅流程。App 首次启动不会自动请求位置权限。

## 核心流程

1. 打开 App 后会显示一条中英短签、一种纯色背景和实时时钟。
2. 长按底部 Oraculo 印记，蓄力完成后会更换短签与颜色。
3. 主屏提供 Small 和 Medium Widget；锁屏提供 Inline 和 Rectangular Widget。
4. App 与 Widget 使用 App Group 共享当天显示状态。

## 可选位置情境

1. 点击右上角位置图标。
2. App 会先显示用途说明；点击“继续”后才会调用 iOS 位置权限弹窗。
3. 允许“使用 App 时”位置后，App 会将坐标取整为近似位置，并发送给 Open-Meteo 查询天气或海拔。
4. 再次点击位置图标会关闭位置情境，并清除本地位置、天气、区域、海拔和地理网格缓存。
5. 拒绝位置权限不会影响 App、长按换句或 Widget 的核心功能。

## 网络与离线行为

- App 会从 `https://oraculo-corpus.vercel.app/oraculo/` 检查静态语料更新。
- 位置情境开启时会连接 `https://api.open-meteo.com/`。
- 无网络时会继续使用内置语料和色板，不阻塞启动。

如审核中需要协助，请联系 `enderwang2012@gmail.com`。
