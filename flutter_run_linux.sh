#!/bin/bash

# Flutter Linux 构建环境变量修复
# 通过设置环境变量来解决 ld 找不到的问题

export PATH="/usr/bin:$PATH"
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

echo "正在使用修复的环境变量运行 Flutter..."
echo ""

flutter run -d linux "$@"
