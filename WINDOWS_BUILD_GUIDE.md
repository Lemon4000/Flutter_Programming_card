# Flutter Windows 打包指南

## 当前环境

- 操作系统：Linux (Ubuntu 24.04)
- Flutter版本：3.24.5
- 当前支持：Linux桌面应用

## 问题

Flutter **不支持**从Linux交叉编译到Windows。必须在Windows环境下构建Windows应用。

## 解决方案

### 方案 1：在Windows机器上构建（推荐）⭐

#### 前置要求

1. **Windows 10/11** 系统
2. **Visual Studio 2022** 或更高版本
   - 必须安装"使用C++的桌面开发"工作负载
3. **Flutter SDK** 已安装并配置

#### 构建步骤

1. **将项目复制到Windows机器**

   ```bash
   # 方法1：使用Git
   git clone <your-repo-url>
   cd programming_card_host

   # 方法2：直接复制项目文件夹
   ```

2. **安装依赖**

   ```bash
   flutter pub get
   ```

3. **构建Windows应用**

   ```bash
   flutter build windows --release
   ```

4. **查找构建产物**

   构建完成后，可执行文件位于：
   ```
   build/windows/x64/runner/Release/
   ```

   包含：
   - `programming_card_host.exe` - 主程序
   - 各种 `.dll` 文件 - 依赖库
   - `data/` 文件夹 - 资源文件

5. **打包分发**

   需要将整个 `Release` 文件夹打包，因为exe依赖其他文件。

   ```bash
   # 创建压缩包
   cd build/windows/x64/runner
   tar -czf programming_card_host_windows.zip Release/
   ```

### 方案 2：使用GitHub Actions自动构建

创建 `.github/workflows/build-windows.yml`：

```yaml
name: Build Windows

on:
  push:
    branches: [ master ]
  workflow_dispatch:

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

    - name: Create ZIP
      run: |
        cd build/windows/x64/runner
        Compress-Archive -Path Release/* -DestinationPath ../../../../programming_card_host_windows.zip

    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: windows-build
        path: programming_card_host_windows.zip
```

提交后，GitHub会自动在Windows环境构建并提供下载。

### 方案 3：使用Codemagic（云端构建）

1. 注册 [Codemagic](https://codemagic.io/)
2. 连接您的Git仓库
3. 配置构建：
   - 选择Flutter项目
   - 选择Windows平台
   - 点击"Start new build"

## Windows构建脚本

创建 `build-windows.bat`（在Windows上使用）：

```batch
@echo off
echo ========================================
echo Flutter Windows 构建脚本
echo ========================================

echo.
echo [1/4] 清理旧构建...
flutter clean

echo.
echo [2/4] 获取依赖...
flutter pub get

echo.
echo [3/4] 构建Windows应用...
flutter build windows --release

echo.
echo [4/4] 创建分发包...
cd build\\windows\\x64\\runner
powershell Compress-Archive -Path Release\\* -DestinationPath ..\\..\\..\\..\\programming_card_host_windows.zip -Force
cd ..\\..\\..\\..

echo.
echo ========================================
echo 构建完成！
echo ========================================
echo.
echo 可执行文件位置：
echo   build\\windows\\x64\\runner\\Release\\programming_card_host.exe
echo.
echo 分发包位置：
echo   programming_card_host_windows.zip
echo.
pause
```

## 创建安装程序（可选）

使用 [Inno Setup](https://jrsoftware.org/isinfo.php) 创建Windows安装程序：

1. 下载并安装Inno Setup
2. 创建 `installer.iss`：

```iss
[Setup]
AppName=编程卡上位机
AppVersion=1.0.0
DefaultDirName={pf}\\ProgrammingCardHost
DefaultGroupName=编程卡上位机
OutputDir=installer
OutputBaseFilename=programming_card_host_setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "build\\windows\\x64\\runner\\Release\\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\\编程卡上位机"; Filename: "{app}\\programming_card_host.exe"
Name: "{commondesktop}\\编程卡上位机"; Filename: "{app}\\programming_card_host.exe"

[Run]
Filename: "{app}\\programming_card_host.exe"; Description: "启动应用"; Flags: postinstall nowait skipifsilent
```

3. 编译安装程序：
   ```bash
   iscc installer.iss
   ```

## 常见问题

### Q: 为什么不能在Linux上构建Windows应用？

A: Flutter的Windows支持依赖于Windows特定的工具链（Visual Studio、Windows SDK等），这些工具只能在Windows上运行。

### Q: 构建后的exe能在其他Windows电脑上运行吗？

A: 可以，但需要：
1. 包含所有依赖的DLL文件
2. 包含data文件夹（资源文件）
3. 目标电脑需要安装Visual C++ Redistributable

### Q: 如何减小exe文件大小？

A:
1. 使用 `--split-debug-info` 分离调试信息
2. 使用 `--obfuscate` 混淆代码
3. 移除未使用的资源

```bash
flutter build windows --release --split-debug-info=debug-info --obfuscate
```

### Q: 如何添加应用图标？

A: 修改 `windows/runner/resources/app_icon.ico`

## 当前项目的构建命令

```bash
# 在Windows机器上执行
cd /path/to/programming_card_host
flutter clean
flutter pub get
flutter build windows --release

# 构建产物位于
# build/windows/x64/runner/Release/
```

## 分发清单

打包时需要包含：
- ✅ `programming_card_host.exe` - 主程序
- ✅ 所有 `.dll` 文件 - 依赖库
- ✅ `data/` 文件夹 - 包含 `assets/config/protocol.json` 等资源
- ✅ `flutter_windows.dll` - Flutter引擎
- ✅ `flutter_blue_plus_windows_plugin.dll` - 蓝牙插件

## 下一步

1. **如果您有Windows机器**：
   - 将项目复制到Windows
   - 运行上面的构建命令

2. **如果没有Windows机器**：
   - 使用GitHub Actions自动构建
   - 或使用Codemagic云端构建

3. **需要帮助**：
   - 我可以帮您创建GitHub Actions配置
   - 或创建详细的Windows构建文档

## 总结

- ❌ 不能在Linux上直接构建Windows exe
- ✅ 需要在Windows环境或使用CI/CD
- ✅ 构建命令：`flutter build windows --release`
- ✅ 产物位置：`build/windows/x64/runner/Release/`
