#!/bin/bash

# BLE 扫描测试脚本
# 用于验证修复是否生效

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "BLE 扫描功能测试"
echo -e "==========================================${NC}"
echo ""

# 1. 检查修复是否已应用
echo -e "${YELLOW}1. 检查修复状态${NC}"
if [ -f "packages/flutter_blue_plus_linux-7.0.3/lib/flutter_blue_plus_linux.dart" ]; then
    if grep -q "transport: 'le'" "packages/flutter_blue_plus_linux-7.0.3/lib/flutter_blue_plus_linux.dart"; then
        echo -e "${GREEN}✓ BLE 修复已应用${NC}"
    else
        echo -e "${RED}✗ BLE 修复未应用${NC}"
        echo "  请运行: ./fix-ble-linux.sh"
        exit 1
    fi
else
    echo -e "${RED}✗ 本地包不存在${NC}"
    echo "  请运行: ./fix-ble-linux.sh"
    exit 1
fi
echo ""

# 2. 使用 bluetoothctl 测试 BLE 扫描
echo -e "${YELLOW}2. 使用 bluetoothctl 测试 BLE 扫描（5秒）${NC}"
echo "  正在扫描..."
BLE_DEVICES=$(timeout 5 bluetoothctl --timeout 5 scan le 2>&1 | grep -E "^\[NEW\] Device" | wc -l)
echo -e "${GREEN}✓ 发现 $BLE_DEVICES 个 BLE 设备${NC}"
echo ""

# 3. 检查应用构建状态
echo -e "${YELLOW}3. 检查应用构建状态${NC}"
if [ -f "build/linux/x64/release/bundle/programming_card_host" ]; then
    echo -e "${GREEN}✓ 应用已构建${NC}"
    BUILD_TIME=$(stat -c %y "build/linux/x64/release/bundle/programming_card_host" | cut -d'.' -f1)
    echo "  构建时间: $BUILD_TIME"
else
    echo -e "${RED}✗ 应用未构建${NC}"
    echo "  请运行: flutter build linux --release"
    exit 1
fi
echo ""

# 4. 提示测试步骤
echo -e "${BLUE}=========================================="
echo "准备测试应用"
echo -e "==========================================${NC}"
echo ""
echo -e "${YELLOW}测试步骤：${NC}"
echo "  1. 运行应用:"
echo "     ${GREEN}./run-linux.sh${NC}"
echo ""
echo "  2. 在应用中点击"开始扫描"按钮"
echo ""
echo "  3. 观察扫描结果:"
echo "     ${GREEN}✓ 应该能看到 BLE 设备${NC}"
echo "     - 设备名称会显示（如果设备广播了名称）"
echo "     - 或显示为 MAC 地址（如果设备未广播名称）"
echo "     - 信号强度（RSSI）会显示"
echo ""
echo "  4. 预期看到的 BLE 设备类型:"
echo "     - 智能手环/手表"
echo "     - 蓝牙耳机"
echo "     - BLE 传感器"
echo "     - 其他 BLE 设备"
echo ""
echo -e "${YELLOW}如果仍然看不到 BLE 设备：${NC}"
echo "  1. 确保附近有 BLE 设备在广播"
echo "  2. 运行诊断脚本: ${GREEN}./diagnose-ble.sh${NC}"
echo "  3. 查看详细日志"
echo ""
echo -e "${BLUE}当前系统状态：${NC}"
echo "  - BlueZ 版本: $(bluetoothctl --version)"
echo "  - 蓝牙适配器: $(hciconfig | grep "BD Address" | awk '{print $3}')"
echo "  - 用户组: $(groups | grep -o bluetooth || echo '未在 bluetooth 组')"
echo ""
