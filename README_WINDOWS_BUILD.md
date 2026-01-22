# Windows 构建说明

## 当前限制

您当前在 **Linux** 系统上，无法直接构建 Windows 版本。Flutter 的 Windows 构建只能在 Windows 主机上进行。

## 解决方案

### 方案 1：在 Windows 机器上构建（推荐）

1. **准备 Windows 环境**
   - Windows 10/11 系统
   - 安装 Flutter SDK
   - 安装 Visual Studio 2022（包含 C++ 工具链）

2. **复制项目到 Windows**
   - 将整个项目文件夹复制到 Windows 机器
   - 或使用 Git 克隆项目

3. **运行构建脚本**
   ```cmd
   build_windows.bat
   ```

4. **获取可执行文件**
   - 位置：`build\windows\x64\runner\Release\`
   - 包含：`programming_card_host.exe` 和所有依赖文件

详细步骤请参考：`WINDOWS_BUILD_GUIDE.md`

### 方案 2：使用虚拟机

1. **安装 Windows 虚拟机**
   - 使用 VirtualBox 或 VMware
   - 安装 Windows 10/11

2. **在虚拟机中构建**
   - 按照方案 1 的步骤操作

### 方案 3：使用 CI/CD（GitHub Actions）

如果项目托管在 GitHub，可以使用 GitHub Actions 自动构建：

创建 `.github/workflows/build-windows.yml`：

```yaml
name: Build Windows

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.5'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build Windows
      run: flutter build windows --release
    
    - name: Archive Release
      uses: actions/upload-artifact@v3
      with:
        name: windows-release
        path: build/windows/x64/runner/Release/
```

## 已准备的文件

项目中已包含以下文件，可在 Windows 上直接使用：

1. **build_windows.bat** - 自动化构建脚本
   - 清理旧构建
   - 安装依赖
   - 构建 Release 版本

2. **installer.iss** - Inno Setup 安装脚本
   - 创建专业的安装程序
   - 支持中英文界面
   - 自动创建快捷方式

3. **WINDOWS_BUILD_GUIDE.md** - 详细构建指南
   - 环境配置
   - 构建步骤
   - 打包分发
   - 故障排除

## 快速开始（在 Windows 上）

```cmd
# 1. 打开命令提示符（以管理员身份）
# 2. 进入项目目录
cd path\to\programming_card_host

# 3. 运行构建脚本
build_windows.bat

# 4. 等待构建完成
# 输出：build\windows\x64\runner\Release\programming_card_host.exe
```

## 创建安装包（在 Windows 上）

```cmd
# 1. 安装 Inno Setup
# 下载：https://jrsoftware.org/isdl.php

# 2. 编译安装脚本
iscc installer.iss

# 3. 获取安装程序
# 输出：installer_output\ProgrammingCardHost_Setup_v1.0.0.exe
```

## 注意事项

1. **串口库兼容性**
   - Windows 上使用 `flutter_libserialport`
   - 自动检测 COM 端口
   - 无需特殊权限

2. **依赖文件**
   - 必须打包整个 Release 文件夹
   - 不能只复制 .exe 文件
   - 包含所有 DLL 和资源文件

3. **驱动程序**
   - 用户需要安装 USB 转串口驱动
   - 常见：CH340、FTDI、CP2102

## 支持

如有问题，请参考：
- `WINDOWS_BUILD_GUIDE.md` - 详细构建指南
- `USB_SERIAL_FIX.md` - 串口问题解决方案
- Flutter 官方文档：https://docs.flutter.dev/platform-integration/windows/building
