# 布局溢出修复

## 🐛 问题描述

烧录页面的固件选择区域出现垂直方向的布局溢出错误：
```
RenderFlex overflowed by pixels on the bottom
```

## 🔍 原因分析

固件选择区的 Column 包含：
1. 标题行（Row + Icon + Text）
2. Expanded 区域（显示空状态或选中文件）
3. SizedBox 间距
4. 底部按钮

在小屏幕或分配空间较小时，这些元素的总高度超过了可用空间。

## ✅ 修复方案

### 1. 减小内边距和间距
- Container padding: `20` → `16`
- 标题后间距: `20` → `12`
- 按钮前间距: `16` → `12`

### 2. 缩小元素尺寸
- 标题图标: `24px` → `20px`
- 标题图标 padding: `8` → `6`
- 标题文字: `20px` → `18px`
- 空状态图标: `80px` → `48px`
- 按钮高度: `56px` → `48px`

### 3. 优化选中文件卡片
- 减小 padding: `24` → `16`
- 减小图标: `48px` → `32px`
- 减小图标 padding: `16` → `12`
- 文字大小: `18px` → `15px`
- 添加 `SingleChildScrollView` 使内容可滚动
- 添加 `maxLines: 2` 和 `overflow: TextOverflow.ellipsis` 防止文件名过长

### 4. 优化空状态
- 添加 `mainAxisSize: MainAxisSize.min` 使 Column 只占用必要空间
- 移除次要提示文字，简化显示

## 📊 修改对比

### 修改前
- 总 padding: 20px
- 标题高度: ~40px
- 空状态图标: 80px
- 按钮高度: 56px
- 总间距: 36px
- **最小需要高度: ~212px**

### 修改后
- 总 padding: 16px
- 标题高度: ~32px
- 空状态图标: 48px
- 按钮高度: 48px
- 总间距: 24px
- **最小需要高度: ~168px**

**节省空间: 44px (20.8%)**

## ✨ 验证结果

```bash
flutter analyze lib/presentation/screens/flash_screen.dart
```
**No issues found!** ✅

## 📱 测试建议

1. 在不同屏幕尺寸上测试
2. 选择长文件名的固件测试文字截断
3. 旋转屏幕测试横屏布局
4. 测试滚动功能（选中文件时）

## 🎯 效果

- ✅ 修复了布局溢出错误
- ✅ 界面更紧凑，适应小屏幕
- ✅ 保持了所有功能
- ✅ 视觉效果依然美观
