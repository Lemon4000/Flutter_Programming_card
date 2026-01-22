#!/bin/bash

# GitHub Actions 快速设置脚本

echo "=========================================="
echo "  GitHub Actions 自动构建设置向导"
echo "=========================================="
echo ""

# 检查是否已经是 Git 仓库
if [ -d ".git" ]; then
    echo "✓ 检测到 Git 仓库"
else
    echo "初始化 Git 仓库..."
    git init
    echo "✓ Git 仓库已初始化"
fi

echo ""
echo "请输入您的 GitHub 仓库信息："
echo ""

# 获取用户名
read -p "GitHub 用户名: " github_username
if [ -z "$github_username" ]; then
    echo "❌ 用户名不能为空"
    exit 1
fi

# 获取仓库名
read -p "仓库名称 (默认: programming_card_host): " repo_name
repo_name=${repo_name:-programming_card_host}

# 构建远程仓库 URL
remote_url="https://github.com/${github_username}/${repo_name}.git"

echo ""
echo "=========================================="
echo "  配置信息"
echo "=========================================="
echo "GitHub 用户名: $github_username"
echo "仓库名称: $repo_name"
echo "远程 URL: $remote_url"
echo ""

read -p "确认以上信息正确？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "=========================================="
echo "  开始设置"
echo "=========================================="

# 检查远程仓库
if git remote | grep -q "origin"; then
    echo "检测到已存在的 origin，正在更新..."
    git remote set-url origin "$remote_url"
else
    echo "添加远程仓库..."
    git remote add origin "$remote_url"
fi
echo "✓ 远程仓库已配置"

# 添加所有文件
echo ""
echo "添加文件到 Git..."
git add .
echo "✓ 文件已添加"

# 创建提交
echo ""
echo "创建提交..."
git commit -m "Initial commit with GitHub Actions auto-build" || echo "没有需要提交的更改"

# 获取当前分支名
current_branch=$(git branch --show-current)
if [ -z "$current_branch" ]; then
    current_branch="main"
    git checkout -b main
fi

echo ""
echo "=========================================="
echo "  准备推送"
echo "=========================================="
echo "当前分支: $current_branch"
echo ""
echo "接下来将推送代码到 GitHub。"
echo "请确保："
echo "  1. 已在 GitHub 上创建仓库: $repo_name"
echo "  2. 已配置 Git 凭据（用户名和 Token）"
echo ""

read -p "是否现在推送？(y/n): " push_confirm
if [ "$push_confirm" = "y" ]; then
    echo ""
    echo "推送到 GitHub..."
    git push -u origin "$current_branch"

    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "  ✓ 设置完成！"
        echo "=========================================="
        echo ""
        echo "下一步："
        echo "  1. 访问: https://github.com/${github_username}/${repo_name}/actions"
        echo "  2. 查看自动构建状态"
        echo "  3. 构建完成后下载产物"
        echo ""
        echo "创建 Release："
        echo "  git tag v1.0.0"
        echo "  git push origin v1.0.0"
        echo ""
        echo "查看 Release："
        echo "  https://github.com/${github_username}/${repo_name}/releases"
        echo ""
    else
        echo ""
        echo "❌ 推送失败"
        echo ""
        echo "可能的原因："
        echo "  1. 仓库不存在 - 请先在 GitHub 上创建仓库"
        echo "  2. 认证失败 - 请配置 Git 凭据"
        echo "  3. 网络问题 - 请检查网络连接"
        echo ""
        echo "手动推送："
        echo "  git push -u origin $current_branch"
    fi
else
    echo ""
    echo "=========================================="
    echo "  配置已完成（未推送）"
    echo "=========================================="
    echo ""
    echo "手动推送命令："
    echo "  git push -u origin $current_branch"
    echo ""
fi

echo ""
echo "详细文档："
echo "  - GITHUB_ACTIONS_GUIDE.md"
echo "  - README_WINDOWS_BUILD.md"
echo ""
