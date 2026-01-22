# GitHub Actions 自动构建指南

## 概述

已配置 GitHub Actions 自动构建 Windows、Android 和 Linux 版本。每次推送代码或创建标签时，会自动构建并上传产物。

## 工作流文件

### 1. build-windows.yml
仅构建 Windows 版本

### 2. build-multi-platform.yml（推荐）
同时构建 Windows、Android 和 Linux 版本

## 使用步骤

### 第一步：推送代码到 GitHub

```bash
# 1. 初始化 Git 仓库（如果还没有）
cd /home/lemon/桌面/docs/plans/flutter
git init

# 2. 添加所有文件
git add .

# 3. 创建初始提交
git commit -m "Initial commit with GitHub Actions"

# 4. 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/programming_card_host.git

# 5. 推送到 GitHub
git push -u origin main
```

### 第二步：查看构建状态

1. 访问您的 GitHub 仓库
2. 点击 "Actions" 标签
3. 查看正在运行的工作流

![GitHub Actions](https://docs.github.com/assets/cb-27528/images/help/repository/actions-tab.png)

### 第三步：下载构建产物

#### 方法 A：从 Actions 页面下载

1. 进入 "Actions" 标签
2. 点击最新的工作流运行
3. 滚动到底部的 "Artifacts" 部分
4. 下载需要的产物：
   - `windows-release-zip` - Windows 压缩包
   - `android-release` - Android APK
   - `linux-release-tar` - Linux 压缩包

#### 方法 B：创建 Release（推荐）

```bash
# 1. 创建版本标签
git tag v1.0.0

# 2. 推送标签到 GitHub
git push origin v1.0.0
```

这会自动：
- 触发构建
- 创建 GitHub Release
- 上传所有平台的安装包

然后访问：`https://github.com/YOUR_USERNAME/programming_card_host/releases`

## 触发构建的方式

### 1. 自动触发

- **推送到 main/master 分支**
  ```bash
  git push origin main
  ```

- **创建 Pull Request**
  ```bash
  git checkout -b feature-branch
  git push origin feature-branch
  # 然后在 GitHub 上创建 PR
  ```

- **创建版本标签**
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```

### 2. 手动触发

1. 访问 GitHub 仓库的 "Actions" 标签
2. 选择工作流（如 "Build Multi-Platform"）
3. 点击 "Run workflow" 按钮
4. 选择分支
5. 点击 "Run workflow"

## 构建产物说明

### Windows 版本
- **文件名**：`ProgrammingCardHost_v1.0.0_Windows_x64.zip`
- **内容**：完整的可执行程序和依赖文件
- **使用**：解压后直接运行 `programming_card_host.exe`

### Android 版本
- **文件名**：`ProgrammingCardHost_v1.0.0_Android.apk`
- **内容**：Android 安装包
- **使用**：直接安装到 Android 设备

### Linux 版本
- **文件名**：`ProgrammingCardHost_v1.0.0_Linux_x64.tar.gz`
- **内容**：Linux 可执行程序和依赖文件
- **使用**：解压后运行 `programming_card_host`

## 配置选项

### 修改 Flutter 版本

编辑 `.github/workflows/build-multi-platform.yml`：

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.5'  # 修改这里
    channel: 'stable'
```

### 修改触发条件

```yaml
on:
  push:
    branches: [ main, master, develop ]  # 添加更多分支
    tags:
      - 'v*'
      - 'release-*'  # 添加更多标签模式
```

### 添加构建通知

在工作流末尾添加：

```yaml
- name: Send notification
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 查看构建日志

1. 进入 "Actions" 标签
2. 点击工作流运行
3. 点击具体的 job（如 "build-windows"）
4. 展开步骤查看详细日志

## 故障排除

### 问题 1：构建失败

**检查日志**：
1. 进入 Actions 页面
2. 点击失败的工作流
3. 查看红色 ❌ 的步骤
4. 展开查看错误信息

**常见原因**：
- 依赖版本不兼容
- 代码语法错误
- 缺少必要文件

### 问题 2：无法下载产物

**原因**：产物保留期限（默认 30 天）

**解决**：
- 及时下载产物
- 或创建 Release 永久保存

### 问题 3：构建时间过长

**优化方法**：
1. 启用缓存（已配置）
2. 减少不必要的步骤
3. 使用更快的 runner

## 高级功能

### 1. 矩阵构建

同时构建多个版本：

```yaml
strategy:
  matrix:
    flutter-version: ['3.24.5', '3.22.0']
    os: [windows-latest, ubuntu-latest]
```

### 2. 条件构建

只在特定条件下构建：

```yaml
- name: Build Windows
  if: contains(github.event.head_commit.message, '[windows]')
  run: flutter build windows --release
```

### 3. 定时构建

每天自动构建：

```yaml
on:
  schedule:
    - cron: '0 0 * * *'  # 每天 UTC 0:00
```

## 成本说明

- **GitHub Actions 免费额度**：
  - 公开仓库：无限制
  - 私有仓库：每月 2000 分钟

- **本项目预估**：
  - Windows 构建：~10 分钟
  - Android 构建：~5 分钟
  - Linux 构建：~5 分钟
  - 总计：~20 分钟/次

## 示例：发布新版本

```bash
# 1. 更新版本号
# 编辑 pubspec.yaml，修改 version: 1.0.1+2

# 2. 提交更改
git add pubspec.yaml
git commit -m "Bump version to 1.0.1"

# 3. 创建标签
git tag v1.0.1

# 4. 推送
git push origin main
git push origin v1.0.1

# 5. 等待构建完成（约 20 分钟）

# 6. 访问 Releases 页面下载
# https://github.com/YOUR_USERNAME/programming_card_host/releases/tag/v1.0.1
```

## 徽章（可选）

在 README.md 中添加构建状态徽章：

```markdown
![Build Status](https://github.com/YOUR_USERNAME/programming_card_host/workflows/Build%20Multi-Platform/badge.svg)
```

## 参考资料

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
