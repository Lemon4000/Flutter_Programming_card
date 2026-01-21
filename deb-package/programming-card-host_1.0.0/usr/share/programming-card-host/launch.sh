#!/bin/bash

# 编程卡上位机启动脚本
# 通过 Waydroid 运行 Android 应用

APP_DIR="/usr/share/programming-card-host"
APK_FILE="$APP_DIR/programming-card-host.apk"
PACKAGE_NAME="com.programmingcard.programming_card_host"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "编程卡上位机 v1.0.0"
echo "=================================="
echo ""

# 检查 Waydroid 是否安装
if ! command -v waydroid &> /dev/null; then
    echo -e "${RED}错误: 未找到 Waydroid${NC}"
    echo ""
    echo "请先安装 Waydroid:"
    echo "  sudo apt install waydroid"
    echo ""
    echo "或访问: https://waydro.id/"
    exit 1
fi

# 检查 Waydroid 是否已初始化
if [ ! -d "/var/lib/waydroid" ] && [ ! -d "$HOME/.local/share/waydroid" ]; then
    echo -e "${YELLOW}Waydroid 尚未初始化${NC}"
    echo ""
    read -p "是否现在初始化 Waydroid? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "正在初始化 Waydroid..."
        waydroid init
    else
        echo "请手动运行: waydroid init"
        exit 1
    fi
fi

# 检查 Waydroid 会话是否运行
if ! waydroid status | grep -q "Session.*RUNNING"; then
    echo "启动 Waydroid 会话..."
    waydroid session start &
    sleep 3
fi

# 检查应用是否已安装
if ! waydroid app list | grep -q "$PACKAGE_NAME"; then
    echo "首次运行，正在安装应用..."
    if [ -f "$APK_FILE" ]; then
        waydroid app install "$APK_FILE"
        echo -e "${GREEN}应用安装成功！${NC}"
    else
        echo -e "${RED}错误: 找不到 APK 文件: $APK_FILE${NC}"
        exit 1
    fi
fi

# 启动应用
echo "启动编程卡上位机..."
waydroid app launch "$PACKAGE_NAME"

echo ""
echo -e "${GREEN}应用已启动！${NC}"
echo ""
echo "提示:"
echo "  - 首次运行可能需要一些时间"
echo "  - 如果应用未显示，请检查 Waydroid 窗口"
echo "  - 使用 'waydroid session stop' 停止 Waydroid"
