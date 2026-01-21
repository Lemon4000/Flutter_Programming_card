# 编程卡上位机 - 构建指南总览

## 🎯 构建选项

本项目提供三种构建方式：

### 1. ✅ Android APK（已完成）
- **状态**: ✅ 已构建
- **文件**: `release/programming-card-host-v1.0.0-android.apk` (47MB)
- **适用**: Android 5.0+ 设备
- **安装**: 直接安装到 Android 设备

### 2. ✅ DEB 包（已完成）
- **状态**: ✅ 已构建
- **文件**: `release/programming-card-host_1.0.0.deb` (19MB)
- **适用**: Ubuntu/Debian 系统
- **运行方式**: 通过 Waydroid 运行 Android 应用
- **安装**: `sudo dpkg -i programming-card-host_1.0.0.deb`

### 3. 🔧 Linux 原生应用（需手动构建）
- **状态**: 📝 需要您手动操作
- **适用**: Linux x86_64 系统
- **运行方式**: 原生 Linux 应用
- **构建指南**: 见下方

## 🚀 推荐方案

### 如果您想在 Linux 上直接运行（原生性能）

**使用自动化脚本**:
```bash
cd /home/lemon/桌面/docs/plans/flutter
./build-linux-native.sh
```

脚本会提示您执行需要 sudo 权限的命令。

**或者手动操作**:
详见 `BUILD_LINUX_NATIVE.md`

### 如果您想快速使用（推荐）

**使用 DEB 包**:
```bash
cd /home/lemon/桌面/docs/plans/flutter/release
./install-deb.sh
```

## 📋 手动构建 Linux 原生应用步骤

### 第 1 步: 卸载 snap Flutter
```bash
sudo snap remove flutter
```

### 第 2 步: 安装官方 Flutter
```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### 第 3 步: 安装依赖
```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

### 第 4 步: 构建应用
```bash
cd /home/lemon/桌面/docs/plans/flutter
flutter config --enable-linux-desktop
flutter clean
flutter pub get
flutter build linux --release
```

### 第 5 步: 运行应用
```bash
cd build/linux/x64/release/bundle
./programming_card_host
```

## 📁 文件位置

```
/home/lemon/桌面/docs/plans/flutter/
├── build-linux-native.sh          # 自动化构建脚本
├── BUILD_LINUX_NATIVE.md          # 详细构建指南
├── release/
│   ├── programming-card-host-v1.0.0-android.apk  # Android APK
│   ├── programming-card-host_1.0.0.deb           # DEB 包
│   ├── install-android.sh                        # Android 安装脚本
│   ├── install-deb.sh                            # DEB 安装脚本
│   ├── DEB_INSTALL_GUIDE.md                      # DEB 安装指南
│   └── README.md                                 # 使用说明
└── build/linux/x64/release/bundle/               # Linux 构建产物（构建后）
    └── programming_card_host                     # 可执行文件
```

## 🔍 三种方案对比

| 特性 | Android APK | DEB 包 (Waydroid) | Linux 原生 |
|------|------------|------------------|-----------|
| 安装难度 | ⭐ 简单 | ⭐⭐ 中等 | ⭐⭐⭐ 较难 |
| 运行性能 | ⭐⭐⭐ 好 | ⭐⭐ 一般 | ⭐⭐⭐⭐⭐ 最佳 |
| 内存占用 | 中等 | 较高 | 最低 |
| 启动速度 | 快 | 较慢 | 最快 |
| 系统集成 | 无 | 一般 | 最好 |
| 蓝牙支持 | 完整 | 受限 | 完整 |
| 需要 sudo | ❌ 否 | ✅ 是 | ✅ 是（仅安装时） |

## 💡 建议

### 开发测试
```bash
flutter run -d linux
```
快速启动，无需构建。

### 日常使用
- **Android 设备**: 使用 APK
- **Ubuntu 快速体验**: 使用 DEB 包
- **Ubuntu 最佳性能**: 构建 Linux 原生应用

### 分发给他人
- **Android 用户**: 分发 APK
- **Ubuntu 用户**: 分发 DEB 包或 AppImage

## 📚 详细文档

- `BUILD_LINUX_NATIVE.md` - Linux 原生应用构建详细指南
- `release/DEB_INSTALL_GUIDE.md` - DEB 包安装详细指南
- `release/README.md` - Android APK 使用说明
- `LINUX_BUILD_GUIDE.md` - Linux 构建问题说明

## 🆘 需要帮助？

### 构建失败
1. 查看 `BUILD_LINUX_NATIVE.md` 的故障排除部分
2. 运行 `flutter doctor` 检查环境
3. 查看构建日志: `flutter build linux --release -v`

### 运行问题
1. 检查依赖: `ldd build/linux/x64/release/bundle/programming_card_host`
2. 安装缺少的库
3. 查看应用日志

## ✨ 快速命令

```bash
# 构建 Linux 原生应用（自动化）
./build-linux-native.sh

# 安装 DEB 包
cd release && ./install-deb.sh

# 开发模式运行
flutter run -d linux

# 重新构建
flutter build linux --release
```

---

**提示**: 如果您不想手动操作，推荐使用 DEB 包方案，一键安装即可使用。
