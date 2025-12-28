# Clipboard4CC

剪贴板图片守护进程 - 自动保存剪贴板中的图片并转换为文件路径。

## 功能

- 监控系统剪贴板，检测图片内容
- 自动将截图/复制的图片保存为 JPG 文件
- 将剪贴板内容替换为图片文件路径
- 在终端中粘贴时直接粘贴文件路径
- 支持开机自启动

## 使用场景

当你需要在命令行或聊天工具中分享截图路径时：

1. 按 `Win+Shift+S` 截图（或复制任意图片）
2. 图片自动保存到 `F:\workspace\image` 目录
3. 按 `Ctrl+V` 粘贴的是文件路径，而不是图片本身

## 安装

### 前置要求

- Windows 10/11
- [AutoHotkey v2.0+](https://www.autohotkey.com/)

### 安装步骤

1. 克隆仓库：
   ```bash
   git clone git@github.com:wukangcheng2944/clipboard4cc.git
   ```

2. 修改配置（可选）：
   编辑 `ClipboardImageDaemon.ahk`，修改图片保存路径：
   ```autohotkey
   global ImageSavePath := "F:\workspace\image"
   ```

3. 运行脚本：
   双击 `ClipboardImageDaemon.ahk`

4. 设置开机自启动：
   ```powershell
   powershell -ExecutionPolicy Bypass -File setup_autostart.ps1
   ```

## 文件说明

| 文件 | 说明 |
|------|------|
| `ClipboardImageDaemon.ahk` | 主程序脚本 |
| `setup_autostart.ps1` | 开机自启动配置脚本 |

## 托盘菜单

运行后会在系统托盘显示图标，右键菜单：
- **打开图片目录** - 打开图片保存目录
- **退出** - 关闭程序

## 项目来源

本项目基于 [AutoHotkey](https://github.com/AutoHotkey/AutoHotkey) 开发，使用 AutoHotkey v2 语法。

核心功能参考了 AutoHotkey 的剪贴板 API 和 GDI+ 图像处理接口。

## License

MIT License
