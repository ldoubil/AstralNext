# Linux 部署指南

## 📦 依赖安装

### Ubuntu/Debian

```bash
# 基础依赖
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  libgtk-3-dev \
  libayatana-appindicator3-dev \
  libnotify-dev \
  fontconfig

# 中文字体 (防止乱码)
sudo apt-get install -y \
  fonts-noto-cjk \      # Google Noto CJK 字体
  fonts-wqy-zenhei      # 文泉驿正黑字体
```

### Arch Linux

```bash
# 基础依赖
sudo pacman -S gtk3 libayatana-appindicator libnotify fontconfig

# 中文字体
sudo pacman -S noto-fonts-cjk wqy-zenhei
```

### Fedora/RHEL

```bash
# 基础依赖
sudo dnf install gtk3-devel libayatana-appindicator-gtk3-devel libnotify-devel fontconfig

# 中文字体
sudo dnf install google-noto-cjk-fonts wqy-zenhei-fonts
```

## 🚀 运行应用

```bash
# 赋予执行权限
chmod +x astral

# 运行
./astral
```

## ⚠️ 已知问题

### 1. 系统托盘不可用

在某些 Linux 发行版上,系统托盘可能不可用。应用会自动降级为普通窗口最小化。

**症状:**
```
⚠️ Failed to initialize system tray: MissingPluginException
ℹ️ Running without system tray support
```

**解决方案:** 这是正常的,应用会继续正常运行,只是没有托盘图标。

### 2. WSL 中的额外边框

在 WSL (Windows Subsystem for Linux) 中运行时,可能会出现额外的窗口边框。

**原因:** `bitsdojo_window` 与 WSL 的图形子系统兼容性限制。

**解决方案:** 
- 使用原生 Linux 环境以获得最佳体验
- 或在 WSL 中接受此视觉差异(不影响功能)

### 3. 中文显示为方块/乱码

**原因:** 系统缺少中文字体。

**解决方案:** 安装上述中文字体包。

## 🔧 故障排查

### 检查依赖是否安装

```bash
# 检查 GTK3
ldconfig -p | grep gtk-3

# 检查字体
fc-list | grep -i "noto\|wqy"

# 检查通知库
ldconfig -p | grep notify
```

### 查看运行时日志

```bash
# 查看详细日志
./astral --verbose

# 或重定向到文件
./astral 2>&1 | tee astral.log
```

### 常见问题

**Q: 应用启动后立即崩溃?**
A: 检查是否安装了所有必需的依赖,特别是 `libgtk-3-dev`。

**Q: 窗口无法移动或调整大小?**
A: 这是 WSL 的限制,建议在原生 Linux 环境中使用。

**Q: 通知不显示?**
A: 确保桌面环境支持 DBus 通知(大多数现代桌面环境都支持)。

## 📝 环境变量

可以通过环境变量自定义行为:

```bash
# 禁用系统托盘(即使可用)
export DISABLE_TRAY=1

# 自定义配置目录
export ASTRAL_CONFIG_DIR=/path/to/config

./astral
```

## 🎨 主题支持

应用支持系统暗色/亮色主题切换,无需额外配置。

---

**需要帮助?** 提交 issue 到 GitHub 仓库。
