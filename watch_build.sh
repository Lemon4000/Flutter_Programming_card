#!/bin/bash

echo "=========================================="
echo "  GitHub Actions 构建监控"
echo "=========================================="
echo ""

# 获取最新的构建
echo "正在获取最新构建状态..."
RUN_ID=$(gh run list --workflow="build-multi-platform.yml" --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
  echo "❌ 未找到构建"
  exit 1
fi

echo "构建 ID: $RUN_ID"
echo ""

# 实时监控
echo "开始监控构建进度..."
echo "（按 Ctrl+C 停止监控）"
echo ""

gh run watch $RUN_ID

# 构建完成后显示结果
echo ""
echo "=========================================="
echo "  构建完成"
echo "=========================================="
echo ""

# 显示构建结果
gh run view $RUN_ID

# 检查是否成功
STATUS=$(gh run view $RUN_ID --json conclusion --jq '.conclusion')

if [ "$STATUS" = "success" ]; then
  echo ""
  echo "✅ 构建成功！"
  echo ""
  echo "查看 Release："
  echo "  https://github.com/Lemon4000/Flutter_Programming_card/releases"
  echo ""
else
  echo ""
  echo "❌ 构建失败"
  echo ""
  echo "查看失败日志："
  echo "  gh run view $RUN_ID --log-failed"
  echo ""
fi
