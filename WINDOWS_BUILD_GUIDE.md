# Windows 构建指南

## 前提条件

1. **Windows 10/11 系统**
2. **安装 Flutter SDK**
   - 下载：https://docs.flutter.dev/get-started/install/windows
   - 配置环境变量

3. **安装 Visual Studio 2022**
   - 下载：https://visualstudio.microsoft.com/downloads/
   - 必须安装 "Desktop development with C++" 工作负载
   - 包含以下组件：
     - MSVC v142 或更高版本
     - Windows 10 SDK

## 构建步骤

### 1. 克隆或复制项目到 Windows 机器

```bash
# 如果使用 Git
git clone <your-repo-url>
cd programming_card_host

# 或者直接复制整个项目文件夹
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 检查 Windows 构建环境

```bash
flutter doctor -v
```

确保 Windows 工具链显示为绿色 ✓

### 4. 构建 Windows 版本

```bash
# 构建 Release 版本
flutter build windows --release

# 构建完成后，可执行文件位于：
# build/windows/x64/runner/Release/
```

### 5. 打包分发

构建完成后，需要将以下文件一起打包：

```
build/windows/x64/runner/Release/
├── programming_card_host.exe          # 主程序
├── flutter_windows.dll                # Flutter 运行时
├── data/                              # 资源文件
│   ├── icudtl.dat
│   └── flutter_assets/
└── *.dll                              # 其他依赖的 DLL 文件
```

**重要**：必须将整个 `Release` 文件夹打包，不能只复制 `.exe` 文件！

### 6. 创建安装包（可选）

#### 方法 A：使用 Inno Setup（推荐）

1. 下载并安装 Inno Setup：https://jrsoftware.org/isdl.php

2. 创建安装脚本 `installer.iss`：

```iss
[Setup]
AppName=Programming Card Host
AppVersion=1.0.0
DefaultDirName={pf}\ProgrammingCardHost
DefaultGroupName=Programming Card Host
OutputDir=installer_output
OutputBaseFilename=ProgrammingCardHost_Setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Programming Card Host"; Filename: "{app}\programming_card_host.exe"
Name: "{commondesktop}\Programming Card Host"; Filename: "{app}\programming_card_host.exe"

[Run]
Filename: "{app}\programming_card_host.exe"; Description: "Launch Programming Card Host"; Flags: postinstall nowait skipifsilent
```

3. 编译安装包：
```bash
iscc installer.iss
```

#### 方法 B：使用 7-Zip 压缩

最简单的方法，直接压缩 Release 文件夹：

```bash
# 使用 7-Zip 压缩
7z a ProgrammingCardHost_v1.0.0_Windows.7z build/windows/x64/runner/Release/*
```

## 故障排除

### 问题 1：flutter_libserialport 构建失败

如果遇到串口库构建问题，确保：
- Visual Studio 已正确安装 C++ 工具链
- Windows SDK 版本兼容

### 问题 2：缺少 DLL 文件

运行时如果提示缺少 DLL，可能需要安装：
- Visual C++ Redistributable
- 下载：https://aka.ms/vs/17/release/vc_redist.x64.exe

### 问题 3：串口权限问题

Windows 上访问串口不需要特殊权限，但需要：
- 安装正确的 USB 转串口驱动（CH340、FTDI 等）
- 确保设备在设备管理器中正常识别

## 测试

1. 在 Windows 机器上运行：
```bash
build/windows/x64/runner/Release/programming_card_host.exe
```

2. 测试功能：
   - 串口设备扫描
   - 参数读取
   - 固件烧录
   - 调试功能

## 分发

### 选项 1：ZIP 压缩包
- 压缩整个 Release 文件夹
- 提供解压即用的绿色版本

### 选项 2：安装程序
- 使用 Inno Setup 创建安装包
- 提供开始菜单快捷方式
- 支持卸载

### 选项 3：便携版
- 将 Release 文件夹重命名为应用名称
- 添加 README.txt 说明文件
- 直接分发文件夹

## 注意事项

1. **串口驱动**：提醒用户安装 USB 转串口驱动
2. **防火墙**：首次运行可能需要允许防火墙访问
3. **杀毒软件**：某些杀毒软件可能误报，需要添加信任
4. **系统要求**：Windows 10 1809 或更高版本

## 自动化构建（可选）

创建批处理脚本 `build_windows.bat`：

```batch
@echo off
echo Building Windows Release...
flutter clean
flutter pub get
flutter build windows --release

echo.
echo Build completed!
echo Output: build\windows\x64\runner\Release\
echo.
pause
```

运行脚本即可自动构建。
