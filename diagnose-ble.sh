#!/bin/bash

# BLE 扫描问题诊断脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "BLE 扫描问题诊断"
echo -e "==========================================${NC}"
echo ""

# 1. 检查蓝牙适配器
echo -e "${YELLOW}1. 检查蓝牙适配器${NC}"
if hciconfig -a | grep -q "UP RUNNING"; then
    echo -e "${GREEN}✓ 蓝牙适配器正常运行${NC}"
    hciconfig | grep "BD Address"
else
    echo -e "${RED}✗ 蓝牙适配器未运行${NC}"
fi
echo ""

# 2. 检查 BlueZ 版本
echo -e "${YELLOW}2. 检查 BlueZ 版本${NC}"
bluetoothctl --version
echo ""

# 3. 检查用户组
echo -e "${YELLOW}3. 检查用户组${NC}"
if groups | grep -q "bluetooth"; then
    echo -e "${GREEN}✓ 用户在 bluetooth 组中${NC}"
else
    echo -e "${RED}✗ 用户不在 bluetooth 组中${NC}"
    echo "  运行: sudo usermod -a -G bluetooth $USER"
    echo "  然后注销并重新登录"
fi
echo ""

# 4. 检查 DBus 策略
echo -e "${YELLOW}4. 检查 DBus 策略${NC}"
if [ -f /etc/dbus-1/system.d/flutter-bluetooth.conf ]; then
    echo -e "${GREEN}✓ DBus 策略文件存在${NC}"
    echo "  文件路径: /etc/dbus-1/system.d/flutter-bluetooth.conf"
else
    echo -e "${RED}✗ DBus 策略文件不存在${NC}"
    echo "  运行: ./fix-ble-scan.sh"
fi
echo ""

# 5. 测试 LE 扫描
echo -e "${YELLOW}5. 测试 LE 扫描（5秒）${NC}"
echo "  正在扫描 BLE 设备..."
timeout 5 bluetoothctl --timeout 5 scan le 2>&1 | grep -E "Device|Discovery" | head -10 || true
echo ""

# 6. 测试 BR/EDR 扫描（SPP）
echo -e "${YELLOW}6. 测试 BR/EDR 扫描（5秒）${NC}"
echo "  正在扫描 SPP 设备..."
timeout 5 bluetoothctl --timeout 5 scan bredr 2>&1 | grep -E "Device|Discovery" | head -10 || true
echo ""

# 7. 检查 BlueZ 配置
echo -e "${YELLOW}7. 检查 BlueZ 配置${NC}"
if [ -f /etc/bluetooth/main.conf ]; then
    echo "  配置文件: /etc/bluetooth/main.conf"
    cat /etc/bluetooth/main.conf | grep -v "^#" | grep -v "^$" | head -20
else
    echo -e "${RED}✗ BlueZ 配置文件不存在${NC}"
fi
echo ""

# 8. 检查蓝牙服务状态
echo -e "${YELLOW}8. 检查蓝牙服务状态${NC}"
if systemctl is-active --quiet bluetooth; then
    echo -e "${GREEN}✓ 蓝牙服务正在运行${NC}"
else
    echo -e "${RED}✗ 蓝牙服务未运行${NC}"
    echo "  运行: sudo systemctl start bluetooth"
fi
echo ""

# 9. 检查 flutter_blue_plus 权限
echo -e "${YELLOW}9. 检查应用权限${NC}"
echo "  flutter_blue_plus 在 Linux 上需要以下权限:"
echo "  - DBus 访问权限（已通过策略文件配置）"
echo "  - bluetooth 组成员资格"
echo ""

# 10. 诊断结果总结
echo -e "${BLUE}=========================================="
echo "诊断结果总结"
echo -e "==========================================${NC}"
echo ""

# 检查是否所有条件都满足
all_ok=true

if ! hciconfig -a | grep -q "UP RUNNING"; then
    all_ok=false
    echo -e "${RED}✗ 蓝牙适配器未运行${NC}"
fi

if ! groups | grep -q "bluetooth"; then
    all_ok=false
    echo -e "${RED}✗ 用户不在 bluetooth 组中${NC}"
fi

if [ ! -f /etc/dbus-1/system.d/flutter-bluetooth.conf ]; then
    all_ok=false
    echo -e "${RED}✗ DBus 策略文件不存在${NC}"
fi

if ! systemctl is-active --quiet bluetooth; then
    all_ok=false
    echo -e "${RED}✗ 蓝牙服务未运行${NC}"
fi

if [ "$all_ok" = true ]; then
    echo -e "${GREEN}✓ 所有检查通过！${NC}"
    echo ""
    echo -e "${YELLOW}如果仍然无法扫描 BLE 设备，可能的原因：${NC}"
    echo "  1. flutter_blue_plus 在 Linux 上的兼容性问题"
    echo "  2. BlueZ 版本不兼容（需要 5.50+）"
    echo "  3. 内核蓝牙驱动问题"
    echo ""
    echo -e "${BLUE}建议的解决方案：${NC}"
    echo "  1. 检查 flutter_blue_plus 的 Linux 支持状态"
    echo "  2. 尝试使用 bluetoothctl 手动扫描验证硬件功能"
    echo "  3. 查看应用运行时的详细日志"
    echo "  4. 考虑使用其他蓝牙库（如 bluez_peripheral）"
else
    echo -e "${YELLOW}请先解决上述问题，然后重新运行此脚本${NC}"
fi
echo ""
