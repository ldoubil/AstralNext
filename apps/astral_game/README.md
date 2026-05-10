# Astral Game

基于 P2P 网络（EasyTier）的游戏社交客户端，支持创建/加入虚拟网络房间、管理中继服务器、在线状态显示、WebDAV 数据备份。

## 功能特性

- P2P 虚拟网络房间创建与加入
- 中继服务器管理
- 实时在线状态显示
- WebDAV 数据备份与恢复
- 跨平台支持（Windows、macOS、Linux、Android、iOS、Web）

## 技术栈

- **框架**: Flutter 3.8+
- **状态管理**: Signals
- **依赖注入**: GetIt
- **事件总线**: EventBus
- **网络**: EasyTier P2P (Rust FFI)
- **持久化**: SharedPreferences + JSON 文件 + WebDAV

## 项目结构

```
lib/
├── config/          # 常量、主题配置
├── data/
│   ├── models/      # 数据模型
│   ├── services/    # 业务逻辑服务
│   └── state/       # 响应式状态
├── ui/
│   ├── shell/       # 应用外壳
│   ├── pages/       # 页面组件
│   └── widgets/     # 可复用组件
├── utils/           # 工具类
├── di.dart          # 依赖注入配置
└── main.dart        # 入口文件
```

## 开发环境要求

- Flutter SDK 3.8+
- Dart SDK 3.0+
- Rust (用于 astral_rust_core)

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/ldoubil/astral.git

# 进入项目目录
cd apps/astral_game

# 安装依赖
flutter pub get

# 运行项目
flutter run
```

## 构建

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux

# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## 相关链接

- [GitHub 仓库](https://github.com/ldoubil/astral)
- [问题反馈](https://github.com/ldoubil/astral/issues)
