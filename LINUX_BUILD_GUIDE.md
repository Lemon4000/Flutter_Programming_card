# Linux 应用打包说明

**日期**: 2026-01-21
**项目**: Flutter编程卡上位机

## 问题说明

在使用 Flutter snap 版本构建 Linux 应用时遇到链接器问题：

```
ERROR: Target dart_build failed: Error: Failed to find any of [ld.lld, ld] in LocalDirectory: '/snap/flutter/149/usr/lib/llvm-10/bin'
```

这是 Flutter snap 版本的已知限制，snap 环境中缺少必要的链接器工具。

## 解决方案

### 方案 1: 使用非 Snap 版本的 Flutter（推荐）

1. **卸载 Snap 版本**:
   ```bash
   sudo snap remove flutter
   ```

2. **安装官方版本**:
   ```bash
   # 下载 Flutter SDK
   cd ~
   git clone https://github.com/flutter/flutter.git -b stable

   # 添加到 PATH
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
   source ~/.bashrc

   # 验证安装
   flutter doctor
   ```

3. **安装 Linux 构建依赖**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
   ```

4. **构建 Linux 应用**:
   ```bash
   cd /home/lemon/桌面/docs/plans/flutter
   flutter build linux --release
   ```

5. **打包应用**:
   构建完成后，可执行文件位于：
   ```
   build/linux/x64/release/bundle/
   ```

   将整个 `bundle` 目录打包即可分发：
   ```bash
   cd build/linux/x64/release/
   tar -czf programming-card-host-linux.tar.gz bundle/
   ```

### 方案 2: 使用 AppImage 打包（推荐用于分发）

1. **安装 AppImage 工具**:
   ```bash
   wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
   chmod +x appimagetool-x86_64.AppImage
   ```

2. **创建 AppDir 结构**:
   ```bash
   mkdir -p AppDir/usr/bin
   mkdir -p AppDir/usr/lib
   mkdir -p AppDir/usr/share/applications
   mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps

   # 复制构建产物
   cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/

   # 创建桌面文件
   cat > AppDir/usr/share/applications/programming-card-host.desktop <<EOF
   [Desktop Entry]
   Name=编程卡上位机
   Exec=programming_card_host
   Icon=programming-card-host
   Type=Application
   Categories=Utility;
   EOF

   # 创建 AppRun 脚本
   cat > AppDir/AppRun <<'EOF'
   #!/bin/bash
   SELF=$(readlink -f "$0")
   HERE=${SELF%/*}
   export PATH="${HERE}/usr/bin/:${HERE}/usr/sbin/:${HERE}/usr/games/:${HERE}/bin/:${HERE}/sbin/${PATH:+:$PATH}"
   export LD_LIBRARY_PATH="${HERE}/usr/lib/:${HERE}/usr/lib/i386-linux-gnu/:${HERE}/usr/lib/x86_64-linux-gnu/:${HERE}/usr/lib32/:${HERE}/usr/lib64/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
   EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2 | cut -d " " -f 1)
   exec "${EXEC}" "$@"
   EOF
   chmod +x AppDir/AppRun
   ```

3. **生成 AppImage**:
   ```bash
   ./appimagetool-x86_64.AppImage AppDir programming-card-host-x86_64.AppImage
   ```

### 方案 3: 使用 Flatpak 打包

1. **安装 Flatpak 工具**:
   ```bash
   sudo apt-get install flatpak flatpak-builder
   ```

2. **创建 Flatpak 清单** (需要创建 `com.programmingcard.host.yml`)

3. **构建 Flatpak**:
   ```bash
   flatpak-builder --force-clean build-dir com.programmingcard.host.yml
   ```

### 方案 4: 使用 Snap 打包（如果需要）

1. **创建 snapcraft.yaml**:
   ```yaml
   name: programming-card-host
   version: '1.0.0'
   summary: 编程卡上位机
   description: Flutter 编程卡上位机应用

   base: core22
   confinement: strict
   grade: stable

   apps:
     programming-card-host:
       command: programming_card_host
       plugs:
         - network
         - bluez
         - home

   parts:
     flutter-app:
       plugin: flutter
       source: .
       flutter-target: lib/main.dart
   ```

2. **构建 Snap**:
   ```bash
   snapcraft
   ```

## 当前可用的构建产物

### Android APK (已构建)

**位置**: `build/app/outputs/flutter-apk/app-release.apk`
**大小**: 49.3MB
**平台**: Android

**安装方法**:
1. 将 APK 文件传输到 Android 设备
2. 在设备上启用"未知来源"安装
3. 点击 APK 文件进行安装

**使用场景**:
- Android 手机/平板
- 可以在 Ubuntu 上使用 Anbox 或 Waydroid 运行

### 在 Ubuntu 上运行 Android APK

如果需要在 Ubuntu 上运行 Android 应用，可以使用：

#### 选项 1: Waydroid (推荐)

```bash
# 安装 Waydroid
sudo apt install waydroid
waydroid init
waydroid session start

# 安装 APK
waydroid app install build/app/outputs/flutter-apk/app-release.apk

# 运行应用
waydroid app launch com.programmingcard.programming_card_host
```

#### 选项 2: Anbox

```bash
# 安装 Anbox
sudo snap install --devmode --beta anbox

# 安装 APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 临时解决方案：直接运行

如果只是想在开发环境中运行，可以使用：

```bash
flutter run -d linux
```

这会在 debug 模式下运行应用，不需要完整的 release 构建。

## 推荐方案总结

1. **开发测试**: 使用 `flutter run -d linux`
2. **Android 设备**: 使用已构建的 APK
3. **Linux 分发**:
   - 首选：安装非 Snap 版本的 Flutter，然后构建 AppImage
   - 备选：使用 Flatpak 或 Snap 打包

## 文件位置

- **Android APK**: `build/app/outputs/flutter-apk/app-release.apk` (49.3MB)
- **Linux Bundle**: `build/linux/x64/release/bundle/` (需要先成功构建)

## 下一步建议

1. 如果需要 Linux 原生应用，建议安装非 Snap 版本的 Flutter
2. 如果主要在 Android 设备上使用，当前的 APK 已经可以使用
3. 如果需要在 Ubuntu 上运行，可以使用 Waydroid 运行 Android APK

## 相关链接

- [Flutter Linux 桌面支持](https://docs.flutter.dev/platform-integration/linux/building)
- [AppImage 文档](https://appimage.org/)
- [Flatpak 文档](https://docs.flatpak.org/)
- [Waydroid 文档](https://waydro.id/)
