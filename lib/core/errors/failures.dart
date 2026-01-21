/// 错误类型定义
///
/// 使用sealed class实现类型安全的错误处理
sealed class Failure {
  final String message;

  const Failure(this.message);

  /// 将错误转换为用户友好的消息
  String toUserMessage() {
    return switch (this) {
      ConnectionFailure() => '连接失败：$message',
      ProtocolFailure() => '协议错误：$message',
      FlashInitFailure() => '初始化失败：$message',
      FlashEraseFailure() => '擦除失败：$message',
      FlashProgramFailure() => '编程失败：$message',
      FlashVerifyFailure() => '校验失败：$message',
      FlashFailure() => '烧录失败：$message',
      DeviceFailure() => '设备错误：$message',
      FileFailure() => '文件错误：$message',
      PermissionFailure() => '权限错误：$message',
      TimeoutFailure() => '超时错误：$message',
      ConfigFailure() => '配置错误：$message',
      UnknownFailure() => '未知错误：$message',
    };
  }
}

/// 连接失败
class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

/// 协议错误
class ProtocolFailure extends Failure {
  const ProtocolFailure(super.message);
}

/// 烧录失败
class FlashFailure extends Failure {
  const FlashFailure(super.message);
}

/// 烧录初始化失败
class FlashInitFailure extends FlashFailure {
  const FlashInitFailure(super.message);
}

/// 烧录擦除失败
class FlashEraseFailure extends FlashFailure {
  const FlashEraseFailure(super.message);
}

/// 烧录编程失败
class FlashProgramFailure extends FlashFailure {
  const FlashProgramFailure(super.message);
}

/// 烧录校验失败
class FlashVerifyFailure extends FlashFailure {
  const FlashVerifyFailure(super.message);
}

/// 设备错误
class DeviceFailure extends Failure {
  const DeviceFailure(super.message);
}

/// 文件错误
class FileFailure extends Failure {
  const FileFailure(super.message);
}

/// 权限错误
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// 超时错误
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

/// 配置错误
class ConfigFailure extends Failure {
  const ConfigFailure(super.message);
}

/// 未知错误
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
