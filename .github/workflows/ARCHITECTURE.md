# AstralNext CI/CD 架构说明

## 📋 设计理念

基于**缓存复用**和**并行执行**思想,将构建流程优化为:

1. **Rust Core 层** - `astral_rust_core` 作为底层核心库
   - ✅ 只在代码变更时重新编译
   - ✅ 产物打包为 cache artifact (保留90天)
   - ✅ 应用构建时直接下载解压,无需等待

2. **Flutter App 层** - 上层应用(astral, astral_game)
   - ✅ 智能检测哪些应用被修改
   - ✅ 从缓存恢复核心库,跳过 Rust 编译
   - ✅ 多应用、多平台完全并行构建

## 🏗️ Workflow 结构

### 1. `build-rust-core.yml` - Rust 核心构建

**触发条件:**
- 手动触发 (workflow_dispatch)
- `packages/astral_rust_core/**` 路径变更
- PR 到 main/develop 分支

**构建矩阵:**
```
Android: arm64, armv7, x86_64
Linux:   x86_64
Windows: x86_64
macOS:   x86_64
iOS:     aarch64
```

**输出:**
- 每个平台的编译产物合并为 `astral-rust-core-cache.tar.gz`
- 作为 artifact 缓存 90 天
- 应用构建时可直接下载使用

**优势:**
- ✅ 核心库独立构建,缓存友好
- ✅ 只在核心代码变更时重新构建
- ✅ 支持增量构建和缓存优化

---

### 2. `build-apps.yml` - Flutter 应用构建

**触发条件:**
- 手动触发 (可选择构建哪个应用)
- `apps/**` 路径变更(排除 astral_car, astral_tv)
- PR 到 main/develop 分支

**智能检测:**
- 自动检测哪些应用被修改
- 只构建受影响的应用
- 支持手动选择构建特定应用

**构建矩阵示例:**

**Astral App:**
```
- Android (arm64, universal)
- Linux x64
- Windows x64
- macOS x64
```

**Astral Game:**
```
- Windows x64
- Linux x64
```

**关键特性:**
- 🔄 **自动下载 core cache** - 从 artifact 恢复编译好的核心库
- ⚡ **跳过 Rust 编译** - 直接使用缓存,大幅缩短构建时间
- 🎯 **智能变更检测** - 只构建被修改的应用
- 🚀 **完全并行** - 多个应用同时编译,互不阻塞

---

### 3. `release.yml` - 完整发布流水线

**触发条件:**
- 推送 tag (如 `v1.0.0`)
- 手动触发(可指定版本号和预发布状态)

**并行执行:**
```
Tag Push / Manual Trigger
    │
    ├─→ build-rust-core.yml (仅 tag push 时执行)
    │   └─→ 编译核心库并缓存
    │
    └─→ build-apps.yml (始终执行)
        ├─→ 下载 core cache
        ├─→ Astral (multi-platform parallel)
        └─→ Astral Game (multi-platform parallel)
            │
            └─→ create-release (收集所有产物,创建 Release)
```

**特点:**
- 🎬 顺序执行,确保依赖关系
- 📦 自动收集所有 artifacts
- 🏷️ 自动生成 release notes
- 🚀 一键发布到 GitHub Releases

---

## 🔄 工作流程图

```
Code Change
    │
    ├─→ packages/astral_rust_core/**  →  build-rust-core.yml
    │                                       │
    │                                       ├─→ Build all platforms
    │                                       └─→ Upload: astral-rust-core-cache.tar.gz (90 days)
    │
    └─→ apps/astral/** or apps/astral_game/**  →  build-apps.yml
                                                    │
                                                    ├─→ Download core cache (if exists)
                                                    ├─→ Extract to cached-libs/
                                                    │
                                                    ├─→ Detect changed apps
                                                    │   ├─→ Only build modified apps
                                                    │   └─→ Skip unchanged apps
                                                    │
                                                    ├─→ Astral (if changed)
                                                    │   ├─→ Android (parallel)
                                                    │   ├─→ Linux (parallel)
                                                    │   ├─→ Windows (parallel)
                                                    │   └─→ macOS (parallel)
                                                    │
                                                    └─→ Astral Game (if changed)
                                                        ├─→ Windows (parallel)
                                                        └─→ Linux (parallel)
                                                    │
                                                    └─→ Upload: all-apps-build

Tag Push (v*)
    │
    ├─→ build-rust-core.yml (conditional)
    │   └─→ Rebuild core if needed
    │
    └─→ build-apps.yml
        └─→ create-release
```

---

## 💡 相比旧架构的优势

### 旧架构问题 (`c:\Users\baika\Documents\GitHub\astral`)
❌ 每个平台独立的 workflow 文件  
❌ 重复的环境配置和依赖安装  
❌ 无法共享构建产物  
❌ 每次都要重新编译 Rust 核心  
❌ 维护成本高(11个 workflow 文件)  

### 新架构优势 (`d:\AstralNext`)
✅ **分层构建** - 核心库和应用分离  
✅ **智能缓存** - 核心库只在变更时重新构建  
✅ **并行执行** - 多平台同时编译,缩短总时间  
✅ **Artifact 传递** - 阶段间通过 artifacts 共享产物  
✅ **统一管理** - 仅 3 个 workflow 文件,清晰易维护  
✅ **灵活触发** - 支持手动选择、路径检测、tag 触发  
✅ **可扩展性** - 新增应用只需在 matrix 中添加配置  

---

## 📊 性能对比

假设场景:修改了 `apps/astral` 的代码

**旧架构:**
```
- 重新编译 Rust Core: ~15分钟
- 编译 Android: ~10分钟
- 编译 Windows: ~8分钟
- 编译 Linux: ~7分钟
──────────────────────
总计: ~40分钟 (串行或部分并行)
```

**新架构 (有缓存):**
```
- 跳过 Rust Core (使用cache): 0分钟
- 下载并解压 cache: ~1分钟
- 智能检测: 只构建 astral,跳过 astral_game
- 并行编译所有平台:
  ├─ Android: ~10分钟
  ├─ Windows: ~8分钟
  ├─ Linux: ~7分钟
  └─ macOS: ~9分钟
──────────────────────
总计: ~11分钟 (取决于最慢的平台)
```

**性能提升: ~72%** ⚡

**核心库变更场景:**
```
- 编译 Rust Core: ~15分钟 (并行所有平台)
- 上传 cache: ~2分钟
- 应用构建 (并行):
  └─ ~10分钟 (使用新cache)
──────────────────────
总计: ~15分钟 (core 和 apps 并行)
```

---

## 🛠️ 使用指南

### 日常开发
```bash
# 推送到 develop 分支
# - 如果只改了应用代码 → 直接下载 core cache,快速构建
# - 如果只改了核心库 → 触发 build-rust-core.yml,重建 cache
# - 如果都改了 → 两个 workflow 并行执行
git push origin develop
```

### 手动构建
```
Actions Tab → 
  - Build Rust Core (手动触发核心构建)
  - Build Flutter Apps (选择要构建的应用)
  - Complete Release Pipeline (完整发布流程)
```

### 发布新版本
```bash
# 1. 更新版本号
# 2. 打 tag
git tag v1.0.0
git push origin v1.0.0

# 3. 自动触发 release.yml
#    - build-rust-core.yml (条件执行,仅在 tag push 时)
#    - build-apps.yml (始终执行,下载 cache)
#    - create-release (收集产物并发布)
```

---

## 🔧 自定义配置

### 添加新应用
在 `build-apps.yml` 的 matrix 中添加:

```yaml
- app: your_new_app
  platform: windows-x64
  os: windows-2022
  flutter_platform: windows
  build_cmd: flutter build windows --release
  artifact_path: build/windows/x64/runner/Release
  artifact_name: your-app-windows-x64
```

### 添加新平台
在 `build-rust-core.yml` 的 matrix 中添加:

```yaml
- platform: linux-arm64
  os: ubuntu-22.04-arm
  rust_target: aarch64-unknown-linux-gnu
  flutter_platform: linux
  artifact_name: astral-rust-core-linux-arm64
```

### 调整缓存策略
修改 `retention-days` 参数控制 artifact 保留时间:
- 开发分支: 7天
- 发布构建: 30天或更久

---

## 📝 注意事项

1. **首次构建较慢** - 需要编译所有平台的核心库并上传 cache
2. **后续构建快速** - 核心库未变更时直接下载 cache (~1分钟)
3. **Cache 有效期** - Core artifacts 保留 90 天,足够覆盖大部分开发周期
4. **智能跳过** - 应用构建时自动检测变更,只构建修改的应用
5. **存储空间** - artifacts 会占用 GitHub 存储,定期清理旧版本
6. **并发限制** - GitHub Actions 有并发 job 数量限制
7. **网络依赖** - 需要稳定的网络下载依赖和 artifacts

## 🎯 最佳实践

1. **合理拆分提交** - 核心库和应用代码分开提交,避免不必要的重新编译
2. **使用 develop 分支** - 日常开发在 develop,稳定后合并到 main
3. **语义化版本** - 使用 `vMAJOR.MINOR.PATCH` 格式打 tag
4. **监控构建时间** - 定期检查并优化慢的步骤
5. **清理旧 artifacts** - 设置合理的 retention-days (core: 90天, apps: 14天)
6. **优先使用 cache** - 确保 core cache 存在后再构建应用,获得最佳性能

---

## 🚀 未来优化方向

1. **分布式缓存** - 使用 S3/GCS 存储编译产物
2. **增量编译** - 只编译变更的模块
3. **构建队列** - 管理并发构建任务
4. **通知集成** - Discord/Slack 构建状态通知
5. **性能分析** - 构建时间趋势分析和告警
