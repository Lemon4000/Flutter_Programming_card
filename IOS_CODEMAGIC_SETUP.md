# iOS 调试配置指南 - 使用 Codemagic

本指南说明如何在没有 Mac 的情况下，使用 Codemagic 云服务来构建和测试 iOS 应用。

## 前提条件

1. GitHub、GitLab 或 Bitbucket 账号
2. Codemagic 账号（免费）
3. Apple Developer 账号（可选，用于真机测试和发布）

## 步骤 1: 创建 Git 远程仓库

### 1.1 在 GitHub 上创建仓库

1. 访问 https://github.com/new
2. 创建新仓库（例如：`programming-card-host`）
3. 不要初始化 README、.gitignore 或 license

### 1.2 推送代码到远程仓库

```bash
cd /home/lemon/桌面/docs/plans/flutter

# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/programming-card-host.git

# 推送代码
git add .
git commit -m "Add Codemagic configuration and iOS permissions"
git branch -M main
git push -u origin main
```

## 步骤 2: 配置 Codemagic

### 2.1 注册 Codemagic 账号

1. 访问 https://codemagic.io/signup
2. 使用 GitHub/GitLab/Bitbucket 账号登录
3. 授权 Codemagic 访问您的仓库

### 2.2 添加应用

1. 在 Codemagic 控制台点击 "Add application"
2. 选择您的 Git 提供商（GitHub/GitLab/Bitbucket）
3. 选择 `programming-card-host` 仓库
4. 选择 "Flutter App" 作为项目类型
5. 点击 "Finish: Add application"

### 2.3 配置工作流

Codemagic 会自动检测项目根目录的 `codemagic.yaml` 文件。

我们已经创建了两个工作流：

1. **ios-workflow**: 完整的发布构建（需要代码签名）
2. **ios-debug-workflow**: 调试构建（不需要代码签名，推荐用于测试）

## 步骤 3: 运行构建

### 3.1 运行调试构建（推荐开始使用）

1. 在 Codemagic 控制台选择您的应用
2. 点击 "Start new build"
3. 选择 `ios-debug-workflow`
4. 选择分支（main）
5. 点击 "Start new build"

构建过程大约需要 10-20 分钟。

### 3.2 查看构建结果

构建完成后，您可以：
- 查看构建日志
- 下载构建产物（.app 文件）
- 查看测试结果
- 接收邮件通知

## 步骤 4: 配置代码签名（可选，用于真机测试）

如果您想在真实 iOS 设备上测试，需要配置代码签名：

### 4.1 准备证书和配置文件

您需要：
1. Apple Developer 账号（$99/年）
2. iOS 开发证书（Development Certificate）
3. 配置文件（Provisioning Profile）

### 4.2 在 Codemagic 中配置

1. 在 Codemagic 控制台，进入 "Teams" → "Integrations"
2. 点击 "App Store Connect"
3. 按照指引添加 Apple Developer 凭据
4. 上传证书和配置文件

### 4.3 更新 codemagic.yaml

修改 `codemagic.yaml` 中的 `bundle_identifier`：

```yaml
environment:
  ios_signing:
    distribution_type: development
    bundle_identifier: com.yourcompany.programmingCardHost  # 修改为您的 Bundle ID
```

## 步骤 5: 测试应用

### 5.1 在模拟器上测试

Codemagic 可以在云端 iOS 模拟器上运行测试：

```yaml
scripts:
  - name: Run integration tests
    script: |
      flutter drive --target=test_driver/app.dart
```

### 5.2 下载并安装到真机

1. 从 Codemagic 下载 .ipa 文件
2. 使用 TestFlight 或 Xcode 安装到设备
3. 或使用 Codemagic 的自动分发功能

## 配置说明

### codemagic.yaml 文件结构

```yaml
workflows:
  ios-debug-workflow:
    name: iOS Debug Build
    max_build_duration: 60              # 最大构建时间（分钟）
    instance_type: mac_mini_m1          # 使用 M1 Mac（更快）
    environment:
      flutter: stable                    # Flutter 版本
      xcode: latest                      # Xcode 版本
      cocoapods: default                 # CocoaPods 版本
    scripts:
      - name: Get Flutter packages       # 获取依赖
        script: flutter packages pub get
      - name: Install pods               # 安装 iOS 依赖
        script: find . -name "Podfile" -execdir pod install \;
      - name: Flutter analyze            # 代码分析
        script: flutter analyze
      - name: Build iOS app              # 构建应用
        script: flutter build ios --debug --no-codesign
    artifacts:
      - build/ios/iphoneos/*.app         # 构建产物
    publishing:
      email:
        recipients:
          - your-email@example.com       # 修改为您的邮箱
```

### iOS 权限配置

已在 `ios/Runner/Info.plist` 中添加了必要的权限：

- **NSBluetoothAlwaysUsageDescription**: 蓝牙权限
- **NSBluetoothPeripheralUsageDescription**: 蓝牙外设权限
- **NSLocationWhenInUseUsageDescription**: 位置权限（iOS 蓝牙要求）
- **NSLocationAlwaysUsageDescription**: 后台位置权限

## 免费额度

Codemagic 免费套餐包括：
- 每月 500 分钟构建时间
- 无限制的团队成员
- 所有核心功能

对于个人项目和小团队来说完全够用。

## 故障排除

### 构建失败

1. 检查构建日志中的错误信息
2. 确保 `pubspec.yaml` 中的依赖版本兼容
3. 检查 iOS 最低版本要求

### Pod 安装失败

在 `codemagic.yaml` 中添加：

```yaml
scripts:
  - name: Update CocoaPods repo
    script: pod repo update
  - name: Install pods
    script: cd ios && pod install
```

### 权限问题

确保 `Info.plist` 中包含所有必要的权限描述。

## 下一步

1. 提交代码到 Git 仓库
2. 在 Codemagic 上配置项目
3. 运行第一次构建
4. 根据需要调整配置

## 有用的链接

- Codemagic 文档: https://docs.codemagic.io/
- Flutter iOS 部署: https://docs.flutter.dev/deployment/ios
- Apple Developer: https://developer.apple.com/

## 联系支持

如果遇到问题：
- Codemagic 支持: support@codemagic.io
- Codemagic 社区: https://github.com/codemagic-ci-cd/codemagic-docs
