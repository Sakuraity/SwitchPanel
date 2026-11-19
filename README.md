# Switch Panel

macOS 菜单栏系统开关面板（未沙箱本地构建，bundle id `dev.kangyuan.switchpanel`）。

## 环境要求

- macOS 13.0（Ventura）或更高
- Xcode 15+（Swift 5.9）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)：`brew install xcodegen`

## 构建与运行

```bash
git clone https://github.com/Sakuraity/SwitchPanel.git
cd SwitchPanel
make generate
open SwitchPanel.xcodeproj
```

命令行构建：

```bash
xcodebuild -scheme SwitchPanel -configuration Debug -destination 'platform=macOS' build
```

单元测试：

```bash
make test
```

在 Xcode 中 Run（⌘R）。应用为 `LSUIElement`，仅显示菜单栏图标，无 Dock 图标。

生成 Xcode 工程后 `SwitchPanel.xcodeproj` 位于仓库根目录（由 XcodeGen 生成，已在 `.gitignore` 中忽略）。

**菜单栏图标：** 「堆叠卡片」— 20pt template：后层描边空卡、前层实心勾卡；任一可见状态开关为开时强调勾卡，全关时强调空卡。

## 权限与 TCC

| 功能 | 权限 | 说明 |
|------|------|------|
| 深色模式 | **自动化** → 控制「系统事件」（仅 AppleScript 回退路径） | 优先使用 WindowServer 路径切换系统外观，并同步 `AppleInterfaceStyle` 与主题广播，便于 Safari / Chrome 等跟随 |
| 锁定屏幕 | **辅助功能** | 使用公开 `CGEvent` 发送默认快捷键 ⌃⌘Q；未授权时不会锁屏并提示开启辅助功能 |
| 清空废纸篓 | **自动化** → 控制「访达」 | Finder AppleScript `empty trash`；遵循系统安全抹掉/多卷废纸篓设置 |
| 低电量模式 | **管理员密码 / Touch ID（每进程一次）** | `/usr/bin/pmset` + Security **Authorization Services** 缓存授权；非管理员用户无法免授权写入 |
| 隐藏桌面图标 / 保持唤醒 / 屏幕清洁 / 登录时打开 | 无额外 TCC | Finder 偏好、`IOKit` 亮度（可选）与全屏遮罩不需辅助功能或自动化 |

**开发提示：** 请使用固定的 Development 签名身份。ad-hoc 签名变化会导致已授予的 TCC 权限失效。

**登录时打开：** `SMAppService` 在 DerivedData 内运行时往往无法持久。安装到 `/Applications` 或 `~/Applications` 后再测。

**深色模式与 Chrome：** 系统外观为「手动」且非「自动」时，Chrome 需在 **设置 → 外观 → 设备（跟随系统）** 才会随 Switch Panel 切换；固定浅色/深色不会跟系统变。

## 功能清单

1. **深色模式** — 开关；优先 SkyLight，回退 System Events AppleScript
2. **隐藏桌面图标** — 开关，`CFPreferences` + 重启 Finder（桌面可能短暂闪烁）
3. **保持唤醒** — 开关，`ProcessInfo.beginActivity`；状态写入 `UserDefaults`，重启应用后恢复
4. **低电量模式** — 开关，读取 `pmset -g`；写入 `pmset -a lowpowermode`（见下）
5. **屏幕清洁** — **开关**：全屏纯黑遮罩（所有显示器）；**任意点击**或 **Esc** 退出
6. **清空废纸篓** — **开关行（瞬间动作）**：拨到开后执行 Finder `empty trash` 并自动回到关
7. **锁定屏幕** — **按钮**，`CGEvent` 发送 ⌃⌘Q
8. **设置** — 拖动排序、勾选显示/隐藏各开关
9. **登录时打开** — 固定在面板底部，不参与排序与隐藏

### 低电量模式

- **API：** 使用 **`/usr/bin/pmset`**。读：`pmset -g`；写：`pmset -a lowpowermode 0|1` 需管理员授权。
- **支持范围：** macOS **13+**；`pmset -g` 含 `lowpowermode` 的机型（常见 MacBook）。台式机多不支持，开关会禁用并说明。

### 屏幕清洁 vs 锁定屏幕

| | 屏幕清洁 | 锁定屏幕 |
|---|----------|----------|
| 用途 | 擦灰、清屏，不锁账户 | 离开座位，系统级锁屏 |
| 控件类型 | 开关（可再关） | 按钮（点一次即锁） |

## 架构

一个适配器对应一个系统控件，`MenuBarExtra` 样式 `.window`，`LaunchAtLogin` 不参与 `ToggleRegistry` 排序。

## 许可证

[MIT License](LICENSE) — Copyright (c) 2026 Kangyuan Chan (Sakuraity).

未使用 Swwwitch / OnlySwitch / OpenSwitch 等第三方项目的源码。SkyLight 外观 SPI 为未公开 API，公开发布版如需上架 Mac App Store 需另行评估。