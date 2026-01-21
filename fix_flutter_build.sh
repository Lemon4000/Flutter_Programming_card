#!/bin/bash

# Flutter Linux 构建修复脚本
# 解决 snap 版本找不到 ld 链接器的问题

echo "=== Flutter Linux 构建修复脚本 ==="
echo ""

# 检查是否需要 sudo 权限
if [ ! -w /snap/flutter/149/usr/lib/llvm-10/bin/ ]; then
    echo "需要 sudo 权限来创建符号链接"
    echo ""
    echo "请执行以下命令："
    echo ""
    echo "sudo mkdir -p /snap/flutter/149/usr/lib/llvm-10/bin"
    echo "sudo ln -sf /snap/flutter/149/usr/lib/compat-ld/ld /snap/flutter/149/usr/lib/llvm-10/bin/ld"
    echo ""
    echo "或者："
    echo ""
    echo "sudo ln -sf /usr/bin/ld /snap/flutter/149/usr/lib/llvm-10/bin/ld"
    echo ""
    echo "执行完成后，再次运行: flutter run -d linux"
    echo ""
else
    echo "正在创建符号链接..."
    mkdir -p /snap/flutter/149/usr/lib/llvm-10/bin
    ln -sf /snap/flutter/149/usr/lib/compat-ld/ld /snap/flutter/149/usr/lib/llvm-10/bin/ld
    echo "修复完成！"
    echo ""
    echo "现在可以运行: flutter run -d linux"
fi

echo ""
echo "=== 替代方案 ==="
echo ""
echo "如果上述方法不起作用，您可以："
echo ""
echo "1. 使用 Web 平台测试:"
echo "   flutter run -d chrome"
echo ""
echo "2. 使用 Android 平台测试:"
echo "   flutter run -d android"
echo ""
echo "3. 仅验证代码质量:"
echo "   flutter analyze"
echo ""
