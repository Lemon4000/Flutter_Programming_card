# 协议配置文件修复说明

## 问题

运行应用时出现错误：
```
握手异常:Exception:协议配置未加载
擦除异常:Exception:协议配置未加载
```

## 原因

`assets/config/protocol.json` 配置文件中的字段名称错误：
- 错误：`"checksumType": "CRC16_MODBUS"`
- 正确：`"checksum": "CRC16_MODBUS"`

代码中使用的是 `checksum` 字段（见 `lib/data/protocol/protocol_config.dart:54`），但配置文件中写的是 `checksumType`，导致解析失败。

## 已修复

✅ 修改了 `assets/config/protocol.json`，将 `checksumType` 改为 `checksum`
✅ 重新构建了应用

## 修复后的配置文件

```json
{
  "preamble": "FC",
  "checksum": "CRC16_MODBUS",
  "baudRate": 2000000,
  "txStart": "!",
  "rxStart": "#"
}
```

## 测试

现在重新运行应用：
```bash
./run-linux.sh
```

应该不会再出现"协议配置未加载"的错误了。

## 注意

这个问题与 BLE 扫描无关，是应用配置文件的问题。BLE 扫描修复仍然有效。
