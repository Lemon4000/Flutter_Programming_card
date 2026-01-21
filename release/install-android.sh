#!/bin/bash

# 编程卡上位机 Android 安装脚本
# 版本: v1.0.0
# 日期: 2026-01-21

set -e

echo "=================================="
echo "编程卡上位机 v1.0.0 安装脚本"
echo "=================================="
echo ""

APK_FILE="programming-card-host-v1.0.0-android.apk"
SHA256_FILE="programming-card-host-v1.0.0-android.apk.sha256"

# 检查文件是否存在
if [ ! -f "$APK_FILE" ]; then
    echo "❌ 错误: 找不到 APK 文件: $APK_FILE"
    exit 1
fi

# 验证校验和
if [ -f "$SHA256_FILE" ]; then
    echo "🔍 验证文件完整性..."
    if sha256sum -c "$SHA256_FILE" > /dev/null 2>&1; then
        echo "✅ 文件完整性验证通过"
    else
        echo "❌ 警告: 文件完整性验证失败！"
        read -p "是否继续安装? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo "⚠️  警告: 未找到校验和文件，跳过完整性验证"
fi

# 检查 adb 是否安装
if ! command -v adb &> /dev/null; then
    echo ""
    echo "❌ 错误: 未找到 adb 命令"
    echo ""
    echo "请先安装 Android Debug Bridge (adb):"
    echo "  Ubuntu/Debian: sudo apt-get install adb"
    echo "  或下载 Android Platform Tools"
    echo ""
    exit 1
fi

# 检查设备连接
echo ""
echo "🔌 检查 Android 设备连接..."
DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [ "$DEVICES" -eq 0 ]; then
    echo ""
    echo "❌ 未检测到 Android 设备"
    echo ""
    echo "请确保:"
    echo "  1. 设备已通过 USB 连接到电脑"
    echo "  2. 设备已开启 USB 调试模式"
    echo "  3. 已授权此电脑进行调试"
    echo ""
    echo "然后重新运行此脚本"
    exit 1
elif [ "$DEVICES" -gt 1 ]; then
    echo ""
    echo "⚠️  检测到多个设备，请选择一个:"
    adb devices -l
    echo ""
    read -p "请输入设备序列号: " DEVICE_SERIAL
    ADB_DEVICE="-s $DEVICE_SERIAL"
else
    echo "✅ 检测到 1 个设备"
    ADB_DEVICE=""
fi

# 显示设备信息
echo ""
echo "📱 设备信息:"
adb $ADB_DEVICE shell getprop ro.product.model
adb $ADB_DEVICE shell getprop ro.build.version.release | sed 's/^/   Android /'

# 安装 APK
echo ""
echo "📦 开始安装应用..."
if adb $ADB_DEVICE install -r "$APK_FILE"; then
    echo ""
    echo "✅ 安装成功！"
    echo ""
    echo "📱 应用已安装到您的设备"
    echo "   您可以在应用列表中找到 '编程卡上位机'"
    echo ""
    echo "⚠️  首次运行时请授予以下权限:"
    echo "   - 蓝牙权限"
    echo "   - 位置权限 (用于蓝牙扫描)"
    echo "   - 存储权限 (用于选择固件文件)"
    echo ""
else
    echo ""
    echo "❌ 安装失败"
    echo ""
    echo "可能的原因:"
    echo "  1. 设备存储空间不足"
    echo "  2. 已安装的版本签名不匹配"
    echo "  3. 设备不支持此应用"
    echo ""
    echo "建议:"
    echo "  - 先卸载旧版本再安装"
    echo "  - 检查设备存储空间"
    exit 1
fi

# 询问是否启动应用
echo ""
read -p "是否立即启动应用? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "🚀 启动应用..."
    adb $ADB_DEVICE shell am start -n com.programmingcard.programming_card_host/.MainActivity
    echo ""
    echo "✅ 应用已启动"
fi

echo ""
echo "=================================="
echo "安装完成！"
echo "=================================="
