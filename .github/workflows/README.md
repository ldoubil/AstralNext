# AstralNext CI/CD Workflows

## 📚 快速开始

### 1️⃣ 首次使用 - 构建核心库

```bash
# 推送核心库代码,触发自动构建
git add packages/astral_rust_core/**
git commit -m "Update rust core"
git push origin develop

# 或者手动触发
# Actions → Build Rust Core → Run workflow
```

这会编译所有平台的核心库并缓存 (保留90天)。

---

### 2️⃣ 日常开发 - 构建应用

```bash
# 修改应用代码后推送
git add apps/astral/**
git commit -m "Update astral app"
git push origin develop

# 自动触发 build-apps.yml
# - 下载 core cache (~1分钟)
# - 只构建修改的应用
# - 多平台并行编译
```

---

### 3️⃣ 发布新版本

```bash
# 打 tag 触发完整发布流程
git tag v1.0.0
git push origin v1.0.0

# 自动执行:
# 1. build-rust-core.yml (条件执行)
# 2. build-apps.yml (始终执行)
# 3. create-release (创建 GitHub Release)
```

---

## 🔄 Workflow 说明

### `build-rust-core.yml`
- **触发**: 核心库代码变更 / 手动触发 / tag push
- **功能**: 编译所有平台的 Rust 核心库
- **输出**: `astral-rust-core-cache.tar.gz` (缓存90天)
- **耗时**: ~15分钟 (首次),后续跳过

### `build-apps.yml`
- **触发**: 应用代码变更 / 手动触发 / tag push
- **功能**: 
  - 下载 core cache
  - 智能检测哪些应用被修改
  - 并行构建多应用、多平台
- **输出**: 各应用的构建产物 (缓存14天)
- **耗时**: ~10分钟 (有cache),~25分钟 (无cache)

### `release.yml`
- **触发**: tag push (v*) / 手动触发
- **功能**: 
  - 调用上述两个 workflow
  - 收集所有产物
  - 创建 GitHub Release
- **耗时**: 取决于子 workflow

---

## ⚡ 性能优化

| 场景 | 旧架构 | 新架构 | 提升 |
|------|--------|--------|------|
| 只改应用代码 | ~40分钟 | ~11分钟 | **72%** ⚡ |
| 只改核心库 | ~40分钟 | ~15分钟 | **62%** ⚡ |
| 都改动 | ~40分钟 | ~15分钟 (并行) | **62%** ⚡ |

**关键优化:**
- ✅ Core cache 复用 (避免重复编译 Rust)
- ✅ 智能变更检测 (只构建修改的应用)
- ✅ 完全并行执行 (多应用、多平台同时编译)

---

## 🎯 手动触发

### 构建特定应用

```
Actions → Build Flutter Apps → Run workflow
选择:
  - astral (只构建 astral)
  - astral_game (只构建 astral_game)
  - all (构建所有应用)
```

### 完整发布

```
Actions → Complete Release Pipeline → Run workflow
输入:
  - version: v1.0.0
  - is_prerelease: true/false
```

---

## 📦 产物说明

### Core Cache
- **名称**: `astral-rust-core-cache`
- **格式**: tar.gz
- **内容**: 所有平台的编译产物
- **保留**: 90天

### App Artifacts
- **Android**: `.apk` 文件
- **Linux**: `.tar.gz` 压缩包
- **Windows**: `.zip` 压缩包
- **macOS**: `.app`  bundle
- **保留**: 14天

### Release Assets
- 包含所有平台的构建产物
- 永久保存在 GitHub Releases

---

## 🔧 自定义配置

### 添加新应用

编辑 `build-apps.yml`,在 matrix 中添加:

```yaml
- app: your_new_app
  platform: windows-x64
  os: windows-2022
  flutter_platform: windows
  build_cmd: flutter build windows --release
  artifact_path: build/windows/x64/runner/Release
  artifact_name: your-app-windows-x64
  should_build: ${{ steps.detect-changes.outputs.your_app_changed }}
```

### 调整缓存时间

```yaml
# build-rust-core.yml
retention-days: 90  # 修改为核心库的预期使用周期

# build-apps.yml  
retention-days: 14  # 修改为应用产物的保留时间
```

---

## 🐛 故障排查

### Q: 提示 "Rust Core cache not found"
**A**: 这是正常的,首次构建或 cache 过期时会看到。会自动从源码编译。建议先运行 `Build Rust Core` workflow。

### Q: 某个平台构建失败
**A**: 检查该平台的依赖是否安装正确。查看具体 job 的日志定位问题。

### Q: 如何清理旧的 artifacts?
**A**: GitHub 会自动清理过期的 artifacts。也可以手动在 Actions → Artifacts 页面删除。

### Q: 构建时间还是很慢?
**A**: 
1. 确认 core cache 是否存在且未过期
2. 检查网络状况 (下载依赖和 artifacts)
3. 考虑使用 self-hosted runners

---

## 📖 详细文档

查看 [ARCHITECTURE.md](./ARCHITECTURE.md) 了解完整的架构设计和最佳实践。

---

## 🤝 贡献

欢迎提交 Issue 和 PR 来改进 CI/CD 流程!
