#!/bin/bash

# iOS 构建完整流程脚本
# 此脚本将帮助您完成从安装 GitHub CLI 到启动 Codemagic 构建的全部流程

set -e  # 遇到错误立即退出

echo "=========================================="
echo "iOS 构建配置流程"
echo "=========================================="
echo ""

# 步骤 1: 安装 GitHub CLI
echo "步骤 1: 安装 GitHub CLI"
echo "----------------------------------------"
if ! command -v gh &> /dev/null; then
    echo "正在安装 GitHub CLI..."
    sudo apt update
    sudo apt install -y gh
    echo "✓ GitHub CLI 安装完成"
else
    echo "✓ GitHub CLI 已安装"
fi
echo ""

# 步骤 2: 登录 GitHub
echo "步骤 2: 登录 GitHub"
echo "----------------------------------------"
echo "请按照提示登录 GitHub..."
echo "建议选择："
echo "  - 登录方式: Login with a web browser (推荐)"
echo "  - 协议: HTTPS"
echo ""
gh auth login
echo "✓ GitHub 登录完成"
echo ""

# 步骤 3: 创建仓库并推送
echo "步骤 3: 创建 GitHub 仓库并推送代码"
echo "----------------------------------------"
cd /home/lemon/桌面/docs/plans/flutter

# 检查是否已有远程仓库
if git remote get-url origin &> /dev/null; then
    echo "检测到已有远程仓库，跳过创建..."
else
    echo "正在创建 GitHub 仓库..."
    gh repo create programming-card-host --public --source=. --remote=origin
    echo "✓ 仓库创建完成"
fi

# 推送代码
echo "正在推送代码到 GitHub..."
git branch -M main
git push -u origin main
echo "✓ 代码推送完成"
echo ""

# 步骤 4: 显示后续步骤
echo "=========================================="
echo "✓ GitHub 配置完成！"
echo "=========================================="
echo ""
echo "接下来请按照以下步骤配置 Codemagic："
echo ""
echo "1. 访问 Codemagic 网站："
echo "   https://codemagic.io/signup"
echo ""
echo "2. 使用 GitHub 账号登录"
echo ""
echo "3. 添加应用："
echo "   - 点击 'Add application'"
echo "   - 选择 'GitHub'"
echo "   - 找到 'programming-card-host' 仓库"
echo "   - 选择 'Flutter App'"
echo ""
echo "4. 启动构建："
echo "   - 选择工作流: ios-debug-workflow"
echo "   - 选择分支: main"
echo "   - 点击 'Start new build'"
echo ""
echo "5. 等待构建完成（约 10-20 分钟）"
echo ""
echo "您的仓库地址："
gh repo view --web --json url -q .url || echo "https://github.com/$(gh api user -q .login)/programming-card-host"
echo ""
echo "详细文档请查看："
echo "  - IOS_CODEMAGIC_SETUP.md"
echo "  - QUICK_START_IOS_BUILD.md"
echo ""
