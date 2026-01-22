#!/bin/bash

echo "=========================================="
echo "  推送到 GitHub 并触发自动构建"
echo "=========================================="
echo ""

# 显示当前状态
echo "当前 Git 状态："
git status --short

echo ""
echo "=========================================="
echo "  准备提交"
echo "=========================================="

# 添加所有更改
echo "添加所有更改..."
git add .

# 创建提交
echo ""
read -p "请输入提交信息: " commit_message
if [ -z "$commit_message" ]; then
    commit_message="Update: Add GitHub Actions auto-build"
fi

git commit -m "$commit_message"

echo ""
echo "=========================================="
echo "  推送到 GitHub"
echo "=========================================="

# 获取当前分支
current_branch=$(git branch --show-current)
echo "当前分支: $current_branch"

# 检查远程仓库
if ! git remote | grep -q "origin"; then
    echo ""
    echo "❌ 未配置远程仓库"
    echo ""
    read -p "请输入 GitHub 用户名: " github_username
    read -p "请输入仓库名称 (默认: programming_card_host): " repo_name
    repo_name=${repo_name:-programming_card_host}

    remote_url="https://github.com/${github_username}/${repo_name}.git"
    echo "添加远程仓库: $remote_url"
    git remote add origin "$remote_url"
fi

echo ""
read -p "是否推送到 GitHub？(y/n): " confirm
if [ "$confirm" = "y" ]; then
    echo "推送中..."
    git push origin "$current_branch"

    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "  ✓ 推送成功！"
        echo "=========================================="
        echo ""
        echo "GitHub Actions 将自动开始构建。"
        echo ""
        echo "查看构建状态："
        remote_url=$(git remote get-url origin)
        repo_url=${remote_url%.git}
        echo "  $repo_url/actions"
        echo ""
        echo "创建 Release（可选）："
        echo "  git tag v1.0.0"
        echo "  git push origin v1.0.0"
        echo ""
    else
        echo ""
        echo "❌ 推送失败"
        echo "请检查："
        echo "  1. GitHub 仓库是否存在"
        echo "  2. Git 凭据是否正确"
        echo "  3. 网络连接是否正常"
    fi
else
    echo "已取消推送"
fi
