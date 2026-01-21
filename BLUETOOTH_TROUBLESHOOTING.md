# 蓝牙连接故障排除指南

## 🔍 问题诊断

运行诊断脚本：
```bash
./diagnose-bluetooth.sh
```

## ⚡ 快速修复

### 方法 1: 运行自动修复脚本

```bash
./fix-bluetooth-permissions.sh
```

脚本会提示您执行需要 sudo 权限的命令。

### 方法 2: 手动修复

#### 步骤 1: 添加用户到 bluetooth 组

```bash
sudo usermod -a -G bluetooth $USER
```

#### 步骤 2: 创建 DBus 策略文件

```bash
sudo tee /etc/dbus-1/system.d/flutter-bluetooth.conf > /dev/null <<'EOF'
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy user="lemon">
    <allow send_destination="org.bluez"/>
    <allow send_interface="org.bluez.Adapter1"/>
    <allow send_interface="org.bluez.Device1"/>
    <allow send_interface="org.bluez.GattService1"/>
    <allow send_interface="org.bluez.GattCharacteristic1"/>
    <allow send_interface="org.bluez.GattDescriptor1"/>
    <allow send_interface="org.freedesktop.DBus.Properties"/>
    <allow send_interface="org.freedesktop.DBus.ObjectManager"/>
  </policy>
</busconfig>
EOF
```

#### 步骤 3: 重启 DBus

```bash
sudo systemctl restart dbus
```

#### 步骤 4: 注销并重新登录

用户组更改需要重新登录才能生效。

## 🔧 常见问题

### 问题 1: 应用无法扫描蓝牙设备

**症状**: 点击扫描按钮后没有任何设备显示

**原因**:
- 用户没有蓝牙权限
- DBus 权限不足
- 蓝牙未开启

**解决方案**:
1. 确保蓝牙已开启:
   ```bash
   bluetoothctl power on
   ```

2. 运行修复脚本:
   ```bash
   ./fix-bluetooth-permissions.sh
   ```

3. 注销并重新登录

### 问题 2: DBus 权限错误

**症状**: 应用日志显示 DBus 相关错误

**解决方案**:
创建 DBus 策略文件（见上方步骤 2）

### 问题 3: flutter_blue_plus 在 Linux 上的限制

**说明**:
`flutter_blue_plus` 在 Linux 上通过 BlueZ DBus API 工作，可能存在以下限制：

- 某些 BLE 特性可能不完全支持
- 需要正确的 DBus 权限配置
- 依赖 BlueZ 版本（推荐 5.50+）

**检查 BlueZ 版本**:
```bash
bluetoothctl --version
```

### 问题 4: 设备配对但无法连接

**解决方案**:
1. 取消配对设备:
   ```bash
   bluetoothctl remove <设备MAC地址>
   ```

2. 重新扫描并连接

### 问题 5: 权限被拒绝

**症状**: 应用显示 "Permission denied" 错误

**解决方案**:
1. 检查用户组:
   ```bash
   groups
   ```
   应该包含 `bluetooth`

2. 如果不包含，添加并重新登录:
   ```bash
   sudo usermod -a -G bluetooth $USER
   ```

3. 注销并重新登录

## 🧪 测试蓝牙连接

### 使用 bluetoothctl 测试

```bash
# 启动 bluetoothctl
bluetoothctl

# 在 bluetoothctl 中执行:
power on
scan on
# 等待几秒，应该看到设备列表
devices
# 连接设备
connect <设备MAC地址>
```

如果 bluetoothctl 可以正常工作，说明系统蓝牙配置正确。

### 检查 DBus 访问

```bash
dbus-send --system --print-reply \
  --dest=org.bluez \
  / \
  org.freedesktop.DBus.Introspectable.Introspect
```

如果返回 XML 数据，说明 DBus 访问正常。

## 📊 诊断信息收集

如果问题持续，收集以下信息：

```bash
# 1. 系统信息
uname -a

# 2. BlueZ 版本
bluetoothctl --version

# 3. 蓝牙状态
bluetoothctl show

# 4. 用户组
groups

# 5. DBus 策略
ls -la /etc/dbus-1/system.d/ | grep bluetooth

# 6. 应用依赖
ldd build/linux/x64/release/bundle/programming_card_host | grep -i blue

# 7. 蓝牙服务日志
journalctl -u bluetooth -n 50
```

## 🔄 替代方案

如果 Linux 原生应用的蓝牙问题无法解决，考虑以下替代方案：

### 方案 1: 使用 Android APK（推荐）

Android 版本有完整的蓝牙支持，无需额外配置。

```bash
# 安装到 Android 设备
cd release
./install-android.sh
```

### 方案 2: 使用 DEB 包 + Waydroid

通过 Waydroid 运行 Android 应用：

```bash
cd release
./install-deb.sh
```

### 方案 3: 使用 USB 蓝牙适配器

如果内置蓝牙有问题，尝试使用外置 USB 蓝牙适配器。

## 📚 参考资料

- [flutter_blue_plus 文档](https://pub.dev/packages/flutter_blue_plus)
- [flutter_blue_plus Linux 支持](https://github.com/boskokg/flutter_blue_plus/tree/master/packages/flutter_blue_plus_linux)
- [BlueZ 文档](http://www.bluez.org/)
- [DBus 权限配置](https://dbus.freedesktop.org/doc/dbus-daemon.1.html)

## 🆘 获取帮助

如果以上方法都无法解决问题：

1. 查看 flutter_blue_plus 的 GitHub Issues
2. 检查是否是已知的 Linux 平台限制
3. 考虑使用 Android 版本（完整支持）

## ✅ 验证修复

修复后，验证蓝牙功能：

1. 运行应用:
   ```bash
   ./run-linux.sh
   ```

2. 点击"设备"标签

3. 点击"扫描设备"按钮

4. 应该能看到附近的蓝牙设备

5. 选择设备并连接

如果仍然无法连接，请运行诊断脚本并查看详细错误信息。

---

**提示**: Linux 桌面的蓝牙支持相对复杂，如果遇到困难，强烈推荐使用 Android APK 版本，它有完整且稳定的蓝牙支持。
