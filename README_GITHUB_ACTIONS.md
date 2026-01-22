# 使用 GitHub Actions 自动构建 Windows 版本

## 快速开始

### 方法 1：使用自动化脚本（推荐）

```bash
cd /home/lemon/桌面/docs/plans/flutter
./setup_github_actions.sh
```

脚本会引导您完成：
1. Git 仓库初始化
2. 配置远程仓库
3. 提交代码
4. 推送到 GitHub

### 方法 2：手动设置

#### 步骤 1：在 GitHub 上创建仓库

1. 访问 https://github.com/new
2. 仓库名称：`programming_card_host`
3. 选择 Public 或 Private
4. **不要**勾选 "Initialize this repository with a README"
5. 点击 "Create repository"

#### 步骤 2：推送代码到 GitHub

```bash
cd /home/lemon/桌面/docs/plans/flutter

# 初始化 Git（如果还没有）
git init

# 添加所有文件
git add .

# 创建提交
git commit -m "Initial commit with GitHub Actions"

# 添加远程仓库（替换 YOUR_USERNAME）
git remote add origin https://github.com/YOUR_USERNAME/programming_card_host.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

#### 步骤 3：查看自动构建

1. 访问您的仓库：`https://github.com/YOUR_USERNAME/programming_card_host`
2. 点击 "Actions" 标签
3. 您会看到 "Build Multi-Platform" 工作流正在运行
4. 等待约 20 分钟构建完成

#### 步骤 4：下载构建产物

**选项 A：从 Actions 下载**

1. 在 Actions 页面，点击最新的工作流运行
2. 滚动到底部的 "Artifacts" 部分
3. 下载：
   - `windows-release-zip` - Windows 压缩包
   - `android-release` - Android APK
   - `linux-release-tar` - Linux 压缩包

**选项 B：创建 Release（推荐）**

```bash
# 创建版本标签
git tag v1.0.0

# 推送标签
git push origin v1.0.0
```

然后访问：`https://github.com/YOUR_USERNAME/programming_card_host/releases`

## 工作流说明

### 已配置的工作流

1. **build-windows.yml**
   - 仅构建 Windows 版本
   - 适合快速测试

2. **build-multi-platform.yml**（推荐）
   - 同时构建 Windows、Android、Linux
   - 适合正式发布

### 触发条件

自动触发：
- 推送到 main/master 分支
- 创建 Pull Request
- 创建版本标签（v*）

手动触发：
- 在 Actions 页面点击 "Run workflow"

## 构建产物

### Windows 版本
- **文件**：`ProgrammingCardHost_v1.0.0_Windows_x64.zip`
- **大小**：约 23 MB
- **使用**：解压后运行 `programming_card_host.exe`

### Android 版本
- **文件**：`ProgrammingCardHost_v1.0.0_Android.apk`
- **大小**：约 23 MB
- **使用**：直接安装到 Android 设备

### Linux 版本
- **文件**：`ProgrammingCardHost_v1.0.0_Linux_x64.tar.gz`
- **大小**：约 25 MB
- **使用**：解压后运行 `programming_card_host`

## 发布新版本

```bash
# 1. 更新版本号
# 编辑 pubspec.yaml
# version: 1.0.1+2

# 2. 提交更改
git add pubspec.yaml
git commit -m "Bump version to 1.0.1"

# 3. 创建标签
git tag v1.0.1

# 4. 推送
git push origin main
git push origin v1.0.1

# 5. 等待构建完成

# 6. 访问 Releases 页面
# https://github.com/YOUR_USERNAME/programming_card_host/releases
```

## 常见问题

### Q: 构建失败怎么办？

A:
1. 进入 Actions 页面
2. 点击失败的工作流
3. 查看红色步骤的日志
4. 根据错误信息修复代码
5. 重新推送

### Q: 如何只构建 Windows 版本？

A:
1. 进入 Actions 页面
2. 选择 "Build Windows Release" 工作流
3. 点击 "Run workflow"
4. 选择分支并运行

### Q: 产物保留多久？

A:
- Artifacts：30 天
- Releases：永久保留

建议：重要版本创建 Release

### Q: 如何加快构建速度？

A:
- 已启用 Flutter 缓存
- 使用 `workflow_dispatch` 手动触发
- 只构建需要的平台

### Q: 需要付费吗？

A:
- 公开仓库：完全免费
- 私有仓库：每月 2000 分钟免费额度

## 目录结构

```
.github/
└── workflows/
    ├── build-windows.yml          # Windows 单独构建
    └── build-multi-platform.yml   # 多平台构建

GITHUB_ACTIONS_GUIDE.md            # 详细使用指南
setup_github_actions.sh            # 自动化设置脚本
README_GITHUB_ACTIONS.md           # 本文件
```

## 下一步

1. **测试构建**
   ```bash
   ./setup_github_actions.sh
   ```

2. **查看构建状态**
   - 访问 Actions 页面
   - 等待构建完成

3. **下载产物**
   - 从 Artifacts 下载
   - 或创建 Release

4. **分发应用**
   - 将构建产物分发给用户
   - 提供下载链接

## 相关文档

- `GITHUB_ACTIONS_GUIDE.md` - 详细使用指南
- `WINDOWS_BUILD_GUIDE.md` - Windows 本地构建指南
- `USB_SERIAL_FIX.md` - Android USB 串口修复说明
- `COMMUNICATION_REPOSITORY_FIX.md` - 通信仓库修复说明

## 支持

如有问题，请查看：
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- 项目 Issues 页面
