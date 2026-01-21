# 编程卡上位机 DEB 包安装指南

**版本**: v1.0.0
**包名**: programming-card-host_1.0.0.deb
**大小**: 19MB
**日期**: 2026-01-21

## 📦 包说明

本 DEB 包包含编程卡上位机的 Android 应用和自动启动脚本，通过 Waydroid 在 Ubuntu 上运行。

### 包含内容
- Android APK (47MB)
- 自动启动脚本
- 桌面快捷方式
- 完整文档

## 🚀 安装步骤

### 1. 安装 Waydroid（必需）

```bash
# 添加 Waydroid 仓库
sudo apt install curl ca-certificates -y
curl https://repo.waydro.id | sudo bash

# 安装 Waydroid
sudo apt install waydroid -y

# 初始化 Waydroid
waydroid init
```

### 2. 安装 DEB 包

#### 方法 1: 使用 dpkg（推荐）

```bash
# 安装包
sudo dpkg -i programming-card-host_1.0.0.deb

# 如果有依赖问题，运行：
sudo apt-get install -f
```

#### 方法 2: 使用 apt

```bash
sudo apt install ./programming-card-host_1.0.0.deb
```

#### 方法 3: 使用 gdebi（图形界面）

```bash
# 安装 gdebi
sudo apt install gdebi

# 双击 deb 文件，或运行：
sudo gdebi programming-card-host_1.0.0.deb
```

### 3. 启动应用

#### 方法 1: 命令行启动

```bash
programming-card-host
```

#### 方法 2: 应用菜单启动

1. 打开应用菜单
2. 搜索"编程卡上位机"
3. 点击图标启动

## 📋 系统要求

### 最低要求
- **系统**: Ubuntu 20.04+ 或其他基于 Debian 的发行版
- **内核**: Linux 5.4+
- **内存**: 2GB RAM
- **存储**: 500MB 可用空间

### 推荐配置
- **系统**: Ubuntu 22.04+
- **内核**: Linux 5.15+
- **内存**: 4GB RAM
- **存储**: 1GB 可用空间

### 依赖项
- **必需**: waydroid 或 anbox
- **推荐**: waydroid

## 🔧 首次运行

### 1. 启动 Waydroid 会话

```bash
# 启动 Waydroid（如果未自动启动）
waydroid session start
```

### 2. 运行应用

```bash
programming-card-host
```

首次运行时，脚本会自动：
1. 检查 Waydroid 是否运行
2. 安装 Android APK
3. 启动应用

### 3. 授予权限

应用首次运行时需要授予以下权限：
- ✅ 蓝牙权限
- ✅ 位置权限（用于蓝牙扫描）
- ✅ 存储权限（用于选择固件文件）

## 📝 使用说明

### 基本操作

1. **设备连接**
   - 打开应用
   - 点击"设备"标签
   - 扫描并连接蓝牙设备

2. **参数配置**
   - 切换到"参数"标签
   - 读取/写入参数

3. **固件烧录**
   - 切换到"烧录"标签
   - 选择固件文件
   - 调整烧录设置
   - 开始烧录

### 烧录设置

在烧录页面点击设置图标，可以调整：
- **初始化超时**: 10-200ms (默认 50ms)
- **初始化重试**: 10-500次 (默认 100次)
- **编程重试延迟**: 10-500ms (默认 50ms) ⭐ 新功能

## 🔍 故障排除

### Waydroid 未启动

```bash
# 检查 Waydroid 状态
waydroid status

# 启动 Waydroid
waydroid session start

# 如果失败，重新初始化
waydroid init -f
```

### 应用未安装

```bash
# 手动安装 APK
waydroid app install /usr/share/programming-card-host/programming-card-host.apk

# 查看已安装应用
waydroid app list
```

### 应用无法启动

```bash
# 查看 Waydroid 日志
waydroid log

# 重启 Waydroid
waydroid session stop
waydroid session start
```

### 蓝牙不工作

Waydroid 中的蓝牙功能可能受限，建议：
1. 确保主机蓝牙已开启
2. 检查 Waydroid 蓝牙权限
3. 或使用真实 Android 设备

## 🗑️ 卸载

### 卸载应用

```bash
# 卸载 DEB 包
sudo apt remove programming-card-host

# 或使用 dpkg
sudo dpkg -r programming-card-host
```

### 清理 Waydroid（可选）

```bash
# 停止 Waydroid
waydroid session stop

# 卸载 Waydroid
sudo apt remove waydroid

# 删除数据（可选）
sudo rm -rf /var/lib/waydroid
rm -rf ~/.local/share/waydroid
```

## 📚 相关文档

- `/usr/share/doc/programming-card-host/README.md` - 详细使用说明
- `/usr/share/doc/programming-card-host/LINUX_BUILD_GUIDE.md` - 构建指南
- `/usr/share/doc/programming-card-host/VERSION.txt` - 版本信息

## 🆘 获取帮助

### 查看文档

```bash
# 查看安装的文档
cd /usr/share/doc/programming-card-host
ls -la
```

### 查看日志

```bash
# Waydroid 日志
waydroid log

# 系统日志
journalctl -xe
```

## 🎯 高级选项

### 手动启动脚本

```bash
# 直接运行启动脚本
/usr/share/programming-card-host/launch.sh
```

### 查看包信息

```bash
# 查看已安装包信息
dpkg -l | grep programming-card-host

# 查看包文件列表
dpkg -L programming-card-host
```

### 验证包完整性

```bash
# 验证包
dpkg-deb --info programming-card-host_1.0.0.deb

# 查看包内容
dpkg-deb --contents programming-card-host_1.0.0.deb
```

## ✨ 功能特性

### v1.0.0 新增
- ✅ 编程阶段重试延迟可配置 (10-500ms)
- ✅ 修复烧录中止后仍发送命令的问题
- ✅ UI 优化和改进
- ✅ 完整的 DEB 包支持

### 核心功能
- ✅ 蓝牙设备扫描和连接
- ✅ 参数读取和写入
- ✅ 固件烧录
- ✅ 通信日志查看

## 📊 包信息

```
Package: programming-card-host
Version: 1.0.0
Architecture: all
Depends: waydroid | anbox
Size: 19MB
Installed-Size: 47MB
```

## 🔐 安全说明

- 本包需要 sudo 权限安装
- 安装后的应用运行在 Waydroid 沙箱中
- 蓝牙权限仅用于设备通信
- 存储权限仅用于读取固件文件

---

**安装时间**: 约 1-2 分钟
**首次运行**: 约 30 秒（包含 APK 安装）
**后续启动**: 约 5-10 秒
