# 快速开始：推送代码到 GitHub 并使用 Codemagic 构建

## 步骤 1: 在 GitHub 上创建仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - **Repository name**: `programming-card-host`
   - **Description**: Flutter编程卡上位机应用
   - **Visibility**: Public（公开）或 Private（私有，Codemagic 免费版支持）
   - **不要**勾选 "Initialize this repository with a README"
3. 点击 "Create repository"

## 步骤 2: 推送代码到 GitHub

GitHub 会显示推送命令，或者您可以使用以下命令：

```bash
cd /home/lemon/桌面/docs/plans/flutter

# 添加远程仓库（将 YOUR_USERNAME 替换为您的 GitHub 用户名）
git remote add origin https://github.com/YOUR_USERNAME/programming-card-host.git

# 推送代码
git branch -M main
git push -u origin main
```

如果遇到认证问题，您可能需要：
- 使用 Personal Access Token (PAT) 代替密码
- 或配置 SSH 密钥

### 创建 Personal Access Token (如果需要)

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 勾选 `repo` 权限
4. 生成并复制 token
5. 推送时使用 token 作为密码

## 步骤 3: 配置 Codemagic

### 3.1 注册并登录

1. 访问 https://codemagic.io/signup
2. 点击 "Sign up with GitHub"
3. 授权 Codemagic 访问您的 GitHub 账号

### 3.2 添加应用

1. 在 Codemagic 控制台点击 "Add application"
2. 选择 "GitHub" 作为 Git 提供商
3. 在仓库列表中找到 `programming-card-host`
4. 点击仓库名称旁边的 "Set up build"
5. 选择 "Flutter App" 作为项目类型
6. 点击 "Finish: Add application"

### 3.3 配置工作流

1. Codemagic 会自动检测到 `codemagic.yaml` 文件
2. 在左侧菜单选择 "Workflows"
3. 您会看到两个工作流：
   - `ios-debug-workflow` (推荐开始使用)
   - `ios-workflow` (需要代码签名)

### 3.4 修改邮箱地址

在开始构建前，建议修改 `codemagic.yaml` 中的邮箱地址：

```yaml
publishing:
  email:
    recipients:
      - your-email@example.com  # 改为您的邮箱
```

然后提交并推送：

```bash
git add codemagic.yaml
git commit -m "Update email address in Codemagic config"
git push
```

## 步骤 4: 启动构建

1. 在 Codemagic 控制台，选择您的应用
2. 点击 "Start new build"
3. 选择工作流：`ios-debug-workflow`
4. 选择分支：`main`
5. 点击 "Start new build"

构建过程大约需要 10-20 分钟。

## 步骤 5: 查看构建结果

构建完成后：
- 查看构建日志
- 下载 `.app` 文件（在 Artifacts 部分）
- 接收邮件通知

## 故障排除

### 推送失败：认证错误

使用 Personal Access Token：

```bash
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/programming-card-host.git
git push -u origin main
```

### Codemagic 找不到仓库

1. 确保仓库已成功推送到 GitHub
2. 在 Codemagic 中刷新仓库列表
3. 检查 Codemagic 的 GitHub 授权权限

### 构建失败

1. 查看构建日志中的详细错误信息
2. 检查 `pubspec.yaml` 依赖版本
3. 确保 iOS 配置正确

## 下一步

构建成功后，您可以：
1. 下载 `.app` 文件进行测试
2. 配置自动构建（每次推送自动触发）
3. 配置代码签名以支持真机测试
4. 设置 TestFlight 自动分发

## 需要帮助？

- Codemagic 文档: https://docs.codemagic.io/
- GitHub 帮助: https://docs.github.com/
