#!/bin/bash

# 串口诊断脚本
# 用于排查串口连接问题

echo "=========================================="
echo "串口设备诊断工具"
echo "=========================================="
echo ""

# 1. 检查串口设备
echo "[1/7] 检查串口设备..."
if ls /dev/ttyUSB* 2>/dev/null; then
    echo "✓ 找到USB串口设备"
else
    echo "✗ 未找到USB串口设备 (/dev/ttyUSB*)"
fi

if ls /dev/ttyACM* 2>/dev/null; then
    echo "✓ 找到ACM串口设备"
fi
echo ""

# 2. 检查用户权限
echo "[2/7] 检查用户权限..."
if groups | grep -q dialout; then
    echo "✓ 用户在 dialout 组中"
else
    echo "✗ 用户不在 dialout 组中"
    echo "  解决方法: sudo usermod -a -G dialout $USER"
    echo "  然后重新登录"
fi
echo ""

# 3. 检查设备权限
echo "[3/7] 检查设备权限..."
for device in /dev/ttyUSB* /dev/ttyACM*; do
    if [ -e "$device" ]; then
        ls -l "$device"
    fi
done
echo ""

# 4. 检查设备占用
echo "[4/7] 检查设备占用..."
for device in /dev/ttyUSB* /dev/ttyACM*; do
    if [ -e "$device" ]; then
        if sudo fuser "$device" 2>/dev/null; then
            echo "✗ $device 被占用"
        else
            echo "✓ $device 未被占用"
        fi
    fi
done
echo ""

# 5. 查看USB设备
echo "[5/7] USB设备列表..."
lsusb | grep -i "serial\|uart\|usb\|ch340\|cp210\|ftdi" || lsusb
echo ""

# 6. 查看内核消息
echo "[6/7] 最近的串口相关内核消息..."
dmesg | grep -i "tty\|usb\|serial" | tail -10
echo ""

# 7. 测试建议
echo "[7/7] 测试建议..."
echo ""
echo "如果设备存在但无法使用，尝试："
echo "1. 重新插拔USB设备"
echo "2. 使用 minicom 测试："
echo "   sudo apt install minicom"
echo "   sudo minicom -D /dev/ttyUSB0 -b 115200"
echo ""
echo "3. 降低波特率："
echo "   修改代码中的波特率从 2000000 降到 115200"
echo ""
echo "4. 检查USB线缆质量"
echo "   使用质量好的USB线缆，避免延长线"
echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
