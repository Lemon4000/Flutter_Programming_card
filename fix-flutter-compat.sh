#!/bin/bash

# 修复 Flutter 兼容性问题
# 将 withValues(alpha: x) 替换为 withOpacity(x)

echo "修复 Flutter 兼容性问题..."
echo ""

# 查找所有使用 withValues 的文件
FILES=$(grep -r "withValues" lib/ --include="*.dart" -l)

if [ -z "$FILES" ]; then
    echo "未找到需要修复的文件"
    exit 0
fi

echo "找到以下文件需要修复:"
echo "$FILES"
echo ""

# 备份
echo "创建备份..."
tar -czf lib_backup_$(date +%Y%m%d_%H%M%S).tar.gz lib/
echo "✓ 备份已创建"
echo ""

# 修复每个文件
for file in $FILES; do
    echo "修复: $file"
    # 替换 withValues(alpha: x) 为 withOpacity(x)
    sed -i 's/\.withValues(alpha: \([^)]*\))/\.withOpacity(\1)/g' "$file"
done

echo ""
echo "✓ 修复完成！"
echo ""
echo "修复内容:"
echo "  withValues(alpha: x) → withOpacity(x)"
echo ""
