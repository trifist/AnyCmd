# AnyCmd

AnyCmd 是一个 macOS 菜单栏应用，用来保存和快速复制常用 AI command。

## 功能

- 只显示菜单栏图标，不显示 Dock 图标。
- 菜单栏提供 Enable、Settings 和 Quit。
- 默认全局快捷键为 `Option + Q`。
- 快捷键呼出 command 选择面板。
- 点击 command 后将内容复制到系统剪贴板。
- 设置窗口支持新增、编辑、删除 command，并配置快捷键。
- 设置窗口支持导入/导出 `.anycmd.json` 备份文件。
- 自带 macOS app icon。

## 导入导出

Settings 里可以导出当前配置到 `.anycmd.json` 文件，也可以在另一台 Mac 上导入这个文件恢复 command、enable 状态和快捷键。

导出文件是带版本号的 JSON，方便人工检查，也方便后续格式升级。

## 开发运行

```bash
swift run
```

## 打包为菜单栏 App

默认构建无日志发布包：

```bash
chmod +x Scripts/build-app.sh
./Scripts/build-app.sh
open .build/AnyCmd.app
```

构建带日志诊断包：

```bash
./Scripts/build-app.sh --with-logs
open .build/AnyCmd-Logs.app
```

带日志包会写入：

```bash
~/Library/Logs/AnyCmd.log
```

当前仓库使用 Swift Package 管理源码；打包脚本会生成带 `LSUIElement=true` 的 `.app`，因此正式运行时不会显示 Dock 图标。

## 发布签名

分发给别人时，建议使用 Apple Developer Program 的 `Developer ID Application` 证书签名，并提交 Apple notarization。签名证明 app 来自你的 Developer ID；notarization 会让 Gatekeeper 更信任这个包。

查看本机可用签名身份：

```bash
security find-identity -v -p codesigning
```

签名但不公证：

```bash
chmod +x Scripts/sign-and-notarize.sh
Scripts/sign-and-notarize.sh \
  --app .build/AnyCmd.app \
  --identity "Developer ID Application: Your Name (TEAMID)" \
  --team-id TEAMID
```

首次公证前保存 notarytool 凭据：

```bash
xcrun notarytool store-credentials anycmd-notary \
  --apple-id you@example.com \
  --team-id TEAMID \
  --password APP_SPECIFIC_PASSWORD
```

签名并公证：

```bash
Scripts/sign-and-notarize.sh \
  --app .build/AnyCmd.app \
  --identity "Developer ID Application: Your Name (TEAMID)" \
  --team-id TEAMID \
  --notary-profile anycmd-notary
```

公证脚本会生成 zip、提交 Apple notary service、等待结果并 staple ticket 到 app。
