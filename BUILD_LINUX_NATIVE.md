# Linux 原生应用构建指南（手动操作）

**目标**: 在 Linux 上直接运行 Flutter 上位机，而不是通过 APK

## 🎯 快速开始

运行自动化脚本：
```bash
cd /home/lemon/桌面/docs/plans/flutter
./build-linux-native.sh
```

脚本会提示您在需要 sudo 权限时手动执行命令。

## 📋 手动操作步骤

如果您想完全手动操作，请按以下步骤进行：

### 步骤 1: 卸载 snap 版本的 Flutter

```bash
sudo snap remove flutter
```

### 步骤 2: 下载官方 Flutter SDK

```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
```

### 步骤 3: 配置环境变量

```bash
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### 步骤 4: 安装 Linux 构建依赖

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

### 步骤 5: 检查 Flutter 环境

```bash
flutter doctor
```

确保显示：
- ✓ Flutter (Channel stable)
- ✓ Linux toolchain

### 步骤 6: 启用 Linux 桌面支持

```bash
flutter config --enable-linux-desktop
```

### 步骤 7: 构建应用

```bash
cd /home/lemon/桌面/docs/plans/flutter

# 清理之前的构建
flutter clean

# 获取依赖
flutter pub get

# 构建 Linux Release 应用
flutter build linux --release
```

### 步骤 8: 运行应用

```bash
cd build/linux/x64/release/bundle
./programming_card_host
```

## 🚀 构建成功后

### 应用位置
```
build/linux/x64/release/bundle/
├── programming_card_host          (可执行文件)
├── lib/                           (依赖库)
└── data/                          (资源文件)
```

### 运行方式

#### 方法 1: 直接运行
```bash
cd /home/lemon/桌面/docs/plans/flutter/build/linux/x64/release/bundle
./programming_card_host
```

#### 方法 2: 使用启动脚本
```bash
cd /home/lemon/桌面/docs/plans/flutter
./run-linux.sh
```

#### 方法 3: 创建桌面快捷方式

创建文件 `~/.local/share/applications/programming-card-host.desktop`:

```desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=编程卡上位机
Comment=Flutter 编程卡上位机
Exec=/home/lemon/桌面/docs/plans/flutter/build/linux/x64/release/bundle/programming_card_host
Icon=utilities-terminal
Terminal=false
Categories=Utility;Development;
```

然后：
```bash
chmod +x ~/.local/share/applications/programming-card-host.desktop
```

## 📦 打包为可分发的应用

### 创建 tar.gz 包

```bash
cd /home/lemon/桌面/docs/plans/flutter/build/linux/x64/release
tar -czf programming-card-host-linux-x64.tar.gz bundle/
```

### 创建 AppImage（推荐）

1. 下载 appimagetool:
```bash
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
```

2. 创建 AppDir 结构:
```bash
mkdir -p AppDir/usr/bin
cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/

# 创建 AppRun
cat > AppDir/AppRun <<'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib/:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/programming_card_host" "$@"
EOF
chmod +x AppDir/AppRun

# 创建 desktop 文件
cat > AppDir/programming-card-host.desktop <<'EOF'
[Desktop Entry]
Name=编程卡上位机
Exec=programming_card_host
Icon=programming-card-host
Type=Application
Categories=Utility;
EOF
```

3. 生成 AppImage:
```bash
./appimagetool-x86_64.AppImage AppDir programming-card-host-x86_64.AppImage
```

## 🔧 故障排除

### 问题 1: flutter 命令未找到

**解决方案**:
```bash
source ~/.bashrc
# 或
export PATH="$PATH:$HOME/flutter/bin"
```

### 问题 2: 缺少依赖库

**解决方案**:
```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

### 问题 3: 构建失败

**解决方案**:
```bash
# 清理并重试
flutter clean
flutter pub get
flutter build linux --release -v
```

### 问题 4: 运行时缺少库

**解决方案**:
```bash
# 检查缺少的库
ldd build/linux/x64/release/bundle/programming_card_host

# 安装缺少的库
sudo apt-get install -y libgtk-3-0 libblkid1 liblzma5
```

## 📊 构建信息

### 构建产物大小
- 可执行文件: ~50MB
- 完整 bundle: ~100MB
- 压缩后: ~30MB

### 系统要求
- **操作系统**: Ubuntu 20.04+ 或其他 Linux 发行版
- **架构**: x86_64
- **依赖**: GTK 3.0+, GLib 2.0+

## 🎯 开发模式运行

如果只是想测试，不需要构建 release 版本：

```bash
cd /home/lemon/桌面/docs/plans/flutter
flutter run -d linux
```

这会在 debug 模式下运行，启动更快，但性能较低。

## 📝 重新构建

如果修改了代码，重新构建：

```bash
cd /home/lemon/桌面/docs/plans/flutter
flutter build linux --release
```

## ✨ 优势

相比 Waydroid 方案：
- ✅ 原生性能，无虚拟化开销
- ✅ 更好的系统集成
- ✅ 更小的内存占用
- ✅ 更快的启动速度
- ✅ 完整的 Linux 桌面体验

## 📚 相关命令

```bash
# 查看 Flutter 版本
flutter --version

# 查看可用设备
flutter devices

# 清理构建
flutter clean

# 更新 Flutter
cd ~/flutter
git pull

# 查看构建日志
flutter build linux --release -v
```

## 🔗 参考链接

- [Flutter Linux 桌面支持](https://docs.flutter.dev/platform-integration/linux/building)
- [Flutter 安装指南](https://docs.flutter.dev/get-started/install/linux)
- [AppImage 文档](https://appimage.org/)

---

**提示**: 首次构建可能需要 5-10 分钟，后续构建会更快。
