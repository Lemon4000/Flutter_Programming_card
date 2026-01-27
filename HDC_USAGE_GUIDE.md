# HDC工具使用指南

## 安装成功！

恭喜！HDC工具已成功安装并配置。

### 安装信息

- **HDC版本**: 1.2.0a
- **安装路径**: `~/harmonyos-tools/hwsdk/hmscore/3.1.0/toolchains/`
- **已连接设备**: `33Z0224620027607`

## 使环境变量生效

在新的终端窗口中，运行以下命令：

```bash
source ~/.bashrc
```

或者直接关闭并重新打开终端。

## 基本使用

### 1. 查看HDC版本

```bash
hdc -v
```

### 2. 列出连接的设备

```bash
hdc list targets
```

输出示例：
```
33Z0224620027607
```

### 3. 连接到设备Shell

```bash
hdc shell
```

### 4. 安装应用

```bash
hdc install <应用包路径.hap>
```

### 5. 卸载应用

```bash
hdc uninstall <包名>
```

### 6. 文件传输

#### 推送文件到设备
```bash
hdc file send <本地文件路径> <设备路径>
```

示例：
```bash
hdc file send ~/test.txt /data/local/tmp/test.txt
```

#### 从设备拉取文件
```bash
hdc file recv <设备文件路径> <本地路径>
```

示例：
```bash
hdc file recv /data/local/tmp/test.txt ~/test.txt
```

### 7. 查看设备日志

```bash
hdc hilog
```

### 8. 查看设备信息

```bash
# 查看设备型号
hdc shell getprop ro.product.model

# 查看系统版本
hdc shell getprop ro.build.version.release

# 查看设备序列号
hdc shell getprop ro.serialno
```

### 9. 端口转发

```bash
# 转发本地端口到设备端口
hdc fport tcp:<本地端口> tcp:<设备端口>

# 示例：转发本地8080到设备8080
hdc fport tcp:8080 tcp:8080
```

### 10. 重启设备

```bash
hdc shell reboot
```

## 常见问题

### Q1: 提示"sdk hdc.exe version is too low"

**A:** 这是一个警告信息，不影响基本功能的使用。如果需要使用最新功能，可以：
1. 访问华为开发者网站下载最新版本的command line tools
2. 或者使用 `sdkmgr` 更新toolchains组件

### Q2: 设备未显示在列表中

**A:** 检查以下几点：
1. 确保设备已通过USB连接到电脑
2. 确保设备已开启USB调试（HDC模式）
3. 运行 `lsusb | grep Huawei` 确认设备被系统识别
4. 尝试重新插拔USB线

### Q3: 权限被拒绝

**A:** 某些操作可能需要root权限：
```bash
hdc shell
su  # 如果设备已root
```

### Q4: 如何更新HDC工具

```bash
cd ~/harmonyos-tools/command-line-tools/bin
./sdkmgr list toolchains
./sdkmgr install toolchains:9 --accept-license
```

## 关于Flutter支持

⚠️ **重要提示**：

虽然HDC工具已成功安装并可以连接您的鸿蒙设备，但是：

1. **Flutter目前不直接支持HDC协议**
2. Flutter依赖ADB协议来识别和调试Android设备
3. 因此，您无法直接使用 `flutter run` 命令通过HDC连接运行Flutter应用

### 解决方案

如果您想使用Flutter开发鸿蒙应用，有以下选择：

#### 方案A：在设备上启用ADB模式（推荐）

参考 `enable_adb_on_harmonyos.md` 文档，在设备的开发者选项中切换到ADB调试模式。

#### 方案B：使用HDC进行手动部署

1. 使用Flutter构建APK：
   ```bash
   flutter build apk
   ```

2. 使用HDC安装到设备：
   ```bash
   hdc install build/app/outputs/flutter-apk/app-release.apk
   ```

3. 手动启动应用并查看日志：
   ```bash
   hdc hilog | grep flutter
   ```

#### 方案C：使用其他开发环境

- 使用Windows或Mac系统（DevEco Studio完整版支持）
- 或者使用其他Android设备进行Flutter开发

## 更多资源

- [华为开发者文档 - HDC工具](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hdc)
- [OpenHarmony HDC文档](https://gitee.com/openharmony/developtools_hdc_standard)
- [DevEco Studio下载](https://developer.huawei.com/consumer/cn/deveco-studio/)

## 下一步

现在您可以：

1. ✅ 使用HDC工具进行基本的设备调试和文件传输
2. ✅ 安装和管理鸿蒙应用
3. ✅ 查看设备日志和系统信息

如果您需要使用Flutter开发，建议尝试在设备上启用ADB模式。
