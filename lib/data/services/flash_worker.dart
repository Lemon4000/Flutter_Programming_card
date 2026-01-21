import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/hex_parser.dart';
import '../../core/utils/crc_calculator.dart';

import '../protocol/frame_builder.dart';
import '../protocol/frame_parser.dart';
import '../protocol/protocol_config.dart';
import '../models/flash_progress.dart';

/// 烧录状态枚举
enum FlashState {
  idle,
  init,           // 发送 !HEX;
  waitInit,       // 等待 #HEX;
  erase,          // 发送 !HEX:ESIZE[n];
  waitErase,      // 等待 #HEX:ERASE;
  program,        // 发送数据块
  waitProgram,    // 等待 #HEX:REPLY[CRC];
  verify,         // 发送 !HEX:ENDCRC[total];
  waitVerify,     // 等待 #HEX:REPLY[total];
  success,
  failed,
}

/// 烧录工作器
///
/// 负责管理完整的固件烧录状态机
class FlashWorker {
  final Future<void> Function(List<int>) writeData;  // 写入数据函数
  final FrameBuilder frameBuilder;
  final FrameParser frameParser;
  final ProtocolConfig protocolConfig;
  final void Function(String) onLog;
  final void Function(List<int>)? onTxData;  // 发送数据回调
  final int initTimeout;  // 初始化超时时间（毫秒）
  final int initMaxRetries;  // 初始化最大重试次数
  final int programRetryDelay;  // 编程阶段重试延迟（毫秒）

  FlashState _state = FlashState.idle;
  Timer? _timeoutTimer;
  int _retryCount = 0;

  // 烧录数据
  List<FlashBlock> _blocks = [];
  int _currentBlockIndex = 0;
  int _totalCrc = 0;

  // 进度回调
  void Function(FlashProgress)? _onProgress;

  // 完成回调
  Completer<Either<Failure, bool>>? _completer;

  // 开始时间
  DateTime? _startTime;

  FlashWorker({
    required this.writeData,
    required this.frameBuilder,
    required this.frameParser,
    required this.protocolConfig,
    required this.onLog,
    this.onTxData,
    this.initTimeout = 50,
    this.initMaxRetries = 100,
    this.programRetryDelay = 50,
  });

  /// 开始烧录（传入已解析的数据块）
  Future<Either<Failure, bool>> startFlashWithBlocks(
    List<FlashBlock> blocks,
    void Function(FlashProgress) onProgress,
  ) async {
    if (_state != FlashState.idle) {
      return const Left(FlashFailure('烧录已在进行中'));
    }

    _onProgress = onProgress;
    _completer = Completer<Either<Failure, bool>>();
    _startTime = DateTime.now();
    _blocks = blocks;

    try {
      onLog('开始烧录: ${_blocks.length} 个数据块');

      // 开始状态机
      _transitionTo(FlashState.init);

      return await _completer!.future;
    } catch (e) {
      onLog('烧录启动失败: $e');
      return Left(FlashFailure('烧录启动失败: $e'));
    }
  }

  /// 开始烧录（传入 HEX 文件路径）
  @Deprecated('使用 startFlashWithBlocks 代替')
  Future<Either<Failure, bool>> startFlash(
    String hexFilePath,
    void Function(FlashProgress) onProgress,
  ) async {
    if (_state != FlashState.idle) {
      return const Left(FlashFailure('烧录已在进行中'));
    }

    _onProgress = onProgress;
    _completer = Completer<Either<Failure, bool>>();
    _startTime = DateTime.now();

    try {
      // 1. 解析 HEX 文件
      onProgress(FlashProgress.preparing('解析 HEX 文件...'));

      final parser = HexParser();
      final hexContent = await _loadHexFile(hexFilePath);

      if (!parser.parseContent(hexContent)) {
        return const Left(FileFailure('HEX 文件解析失败'));
      }

      _blocks = parser.getDataBlocks(blockSize: 256);  // 使用256字节以适应BLE MTU限制
      onLog('HEX 文件解析成功: ${_blocks.length} 个数据块');

      // 2. 开始状态机
      _transitionTo(FlashState.init);

      return await _completer!.future;
    } catch (e) {
      onLog('烧录启动失败: $e');
      return Left(FlashFailure('烧录启动失败: $e'));
    }
  }

  /// 加载 HEX 文件
  Future<String> _loadHexFile(String hexFilePath) async {
    // 这里简化处理，实际应该根据路径类型选择加载方式
    // 在实际集成时，这部分逻辑应该在 CommunicationRepositoryImpl 中处理
    throw UnimplementedError('HEX 文件加载应在 Repository 层实现');
  }

  /// 处理接收到的帧
  void handleReceivedFrame(List<int> frame) {
    switch (_state) {
      case FlashState.waitInit:
        _handleInitResponse(frame);
        break;
      case FlashState.waitErase:
        _handleEraseResponse(frame);
        break;
      case FlashState.waitProgram:
        _handleProgramResponse(frame);
        break;
      case FlashState.waitVerify:
        _handleVerifyResponse(frame);
        break;
      default:
        // 忽略其他状态的帧
        break;
    }
  }

  /// 状态转换
  void _transitionTo(FlashState newState) {
    // 如果已经处于终止状态（idle, success, failed），不允许转换到其他状态
    if ((_state == FlashState.idle || _state == FlashState.success || _state == FlashState.failed) &&
        newState != FlashState.init) {
      onLog('状态转换被阻止: 当前状态=$_state, 目标状态=$newState');
      return;
    }

    _state = newState;
    _cancelTimeout();

    switch (newState) {
      case FlashState.init:
        _sendInitCommand();
        break;
      case FlashState.erase:
        _sendEraseCommand();
        break;
      case FlashState.program:
        _sendProgramData();
        break;
      case FlashState.verify:
        _sendVerifyCommand();
        break;
      case FlashState.success:
        _handleSuccess();
        break;
      case FlashState.failed:
        _handleFailure('烧录失败');
        break;
      default:
        break;
    }
  }

  /// 发送初始化命令
  void _sendInitCommand({bool isRetry = false}) {
    try {
      if (!isRetry) {
        _retryCount = 0;
        _onProgress?.call(FlashProgress.initializing('初始化设备...'));
      }

      final frame = frameBuilder.buildInitFrame();
      onTxData?.call(frame);  // 记录发送数据
      writeData(frame);

      // 只在第一次发送时转换状态
      if (!isRetry) {
        _state = FlashState.waitInit;
      }

      // 设置短超时，快速重试
      _startTimeout(Duration(milliseconds: initTimeout), _onInitTimeout);
    } catch (e) {
      onLog('发送初始化命令失败: $e');
      _cancelTimeout();
      _completer?.complete(const Left(FlashFailure('设备连接已断开')));
      _transitionTo(FlashState.failed);
    }
  }

  /// 处理初始化响应
  void _handleInitResponse(List<int> frame) {
    final response = frameParser.parseInitResponse(frame);

    if (response != null && response.success) {
      onLog('初始化成功');
      _cancelTimeout();
      _retryCount = 0;
      _transitionTo(FlashState.erase);
    }
  }

  /// 初始化超时处理
  void _onInitTimeout() {
    _retryCount++;
    if (_retryCount < initMaxRetries) {
      // 快速重试
      _sendInitCommand(isRetry: true);
    } else {
      final totalTime = (initMaxRetries * initTimeout) / 1000;
      onLog('初始化超时，已重试 $initMaxRetries 次（总计 ${totalTime.toStringAsFixed(1)} 秒）');
      _completer?.complete(const Left(FlashInitFailure('初始化超时')));
      _transitionTo(FlashState.failed);
    }
  }

  /// 发送擦除命令
  void _sendEraseCommand() {
    // 计算固件总字节数
    final totalBytes = _blocks.fold<int>(0, (sum, block) => sum + block.data.length);
    // 计算需要擦除的块数（每块2048字节，向上取整）
    final eraseBlocks = (totalBytes + 2047) ~/ 2048;

    onLog('发送擦除命令: $eraseBlocks 个块 (总字节: $totalBytes)');
    _onProgress?.call(FlashProgress.erasing('擦除 Flash...'));
    _retryCount = 0;

    final frame = frameBuilder.buildEraseFrame(eraseBlocks);
    onTxData?.call(frame);  // 记录发送数据
    writeData(frame);

    _transitionTo(FlashState.waitErase);
    // 激进优化：擦除操作减少超时到2秒
    _startTimeout(const Duration(milliseconds: 2000), _onEraseTimeout);
  }

  /// 处理擦除响应
  void _handleEraseResponse(List<int> frame) {
    final response = frameParser.parseEraseResponse(frame);

    if (response != null && response.success) {
      onLog('擦除成功');
      _cancelTimeout();
      _retryCount = 0;
      _currentBlockIndex = 0;
      _totalCrc = 0;
      _transitionTo(FlashState.program);
    }
  }

  /// 擦除超时处理
  void _onEraseTimeout() {
    _retryCount++;
    if (_retryCount < 5) {
      _transitionTo(FlashState.erase);
    } else {
      onLog('擦除超时，已重试 5 次');
      _completer?.complete(const Left(FlashEraseFailure('擦除超时')));
      _transitionTo(FlashState.failed);
    }
  }

  /// 发送编程数据
  void _sendProgramData({bool isRetry = false}) {
    if (_currentBlockIndex >= _blocks.length) {
      // 所有块发送完成，进入验证阶段
      _transitionTo(FlashState.verify);
      return;
    }

    final block = _blocks[_currentBlockIndex];

    if (!isRetry) {
      _retryCount = 0;
    }

    final frame = frameBuilder.buildFlashDataFrame(block.address, block.data);
    writeData(frame);

    _transitionTo(FlashState.waitProgram);
    // 优化：256字节数据块传输快，超时时间设为20ms
    _startTimeout(const Duration(milliseconds: 20), _onProgramTimeout);
  }

  /// 处理编程响应
  void _handleProgramResponse(List<int> frame) {
    final response = frameParser.parseProgramResponse(frame);

    if (response == null || !response.success) {
      return;
    }

    _cancelTimeout();

    // 计算当前块的帧 CRC
    final block = _blocks[_currentBlockIndex];
    final header = '!HEX:START${block.address.toRadixString(16).toUpperCase().padLeft(8, '0')},SIZE${block.data.length},DATA';
    final payloadBytes = <int>[
      ...header.codeUnits,
      ...block.data,
      ';'.codeUnitAt(0),
    ];
    final frameCrc = CrcCalculator.crc16Modbus(payloadBytes);

    // 验证设备返回的 CRC（小端序）
    final replyCrcValue = response.replyCrc[0] | (response.replyCrc[1] << 8);

    if (replyCrcValue != frameCrc) {
      _retryOrFail();
      return;
    }

    // 累加帧 CRC
    _totalCrc = (_totalCrc + frameCrc) & 0xFFFF;

    // 移动到下一块
    _currentBlockIndex++;
    _retryCount = 0;

    // 更新烧录进度
    _onProgress?.call(FlashProgress.flashing(
      completedBlocks: _currentBlockIndex,
      totalBlocks: _blocks.length,
      completedBytes: _currentBlockIndex * 256,  // 假设每块256字节
      totalBytes: _blocks.length * 256,
      message: '烧录中 $_currentBlockIndex/${_blocks.length}',
    ));

    _transitionTo(FlashState.program);
  }

  /// 编程超时处理
  void _onProgramTimeout() {
    _retryOrFail();
  }

  /// 重试或失败
  void _retryOrFail({bool immediate = false}) {
    _retryCount++;
    if (_retryCount < 20) {
      if (!immediate) {
        // 使用配置的重试延迟
        Future.delayed(Duration(milliseconds: programRetryDelay), () {
          // 检查状态是否仍然有效（未被中止或失败）
          if (_state == FlashState.waitProgram) {
            _transitionTo(FlashState.program);
            // _transitionTo 已经会调用 _sendProgramData，不需要重复调用
          }
        });
      } else {
        // 立即重试前也检查状态
        if (_state == FlashState.waitProgram) {
          _transitionTo(FlashState.program);
          // _transitionTo 已经会调用 _sendProgramData，不需要重复调用
        }
      }
    } else {
      onLog('编程失败，已重试 20 次');
      _completer?.complete(const Left(FlashProgramFailure('编程失败，重试次数过多')));
      _transitionTo(FlashState.failed);
    }
  }

  /// 发送验证命令
  void _sendVerifyCommand() {
    onLog('发送验证命令: 总CRC=0x${_totalCrc.toRadixString(16)}');
    _onProgress?.call(FlashProgress.verifying('验证烧录结果...'));
    _retryCount = 0;

    final frame = frameBuilder.buildFlashVerifyFrame(_totalCrc);
    onTxData?.call(frame);  // 记录发送数据
    writeData(frame);

    _transitionTo(FlashState.waitVerify);
    // 激进优化：验证命令很小，超时时间减少到500ms
    _startTimeout(const Duration(milliseconds: 500), _onVerifyTimeout);
  }

  /// 处理验证响应
  void _handleVerifyResponse(List<int> frame) {
    final response = frameParser.parseVerifyResponse(frame);

    if (response == null || !response.success) {
      return;
    }

    _cancelTimeout();

    // 验证 CRC（支持大端和小端）
    final replyCrcBigEndian = (response.replyCrc[0] << 8) | response.replyCrc[1];
    final replyCrcLittleEndian = response.replyCrc[0] | (response.replyCrc[1] << 8);

    if (replyCrcBigEndian == _totalCrc || replyCrcLittleEndian == _totalCrc) {
      onLog('验证成功: CRC 匹配');
      _transitionTo(FlashState.success);
    } else {
      _retryVerifyOrFail();
    }
  }

  /// 验证超时处理
  void _onVerifyTimeout() {
    _retryVerifyOrFail();
  }

  /// 重试验证或失败
  void _retryVerifyOrFail() {
    _retryCount++;
    if (_retryCount < 30) {
      // 激进优化：验证重试延迟减少到200ms
      Future.delayed(const Duration(milliseconds: 200), () {
        // 检查状态是否仍然有效（未被中止或失败）
        if (_state == FlashState.waitVerify) {
          _transitionTo(FlashState.verify);
        }
      });
    } else {
      onLog('验证失败，已重试 30 次');
      _completer?.complete(const Left(FlashVerifyFailure('验证失败')));
      _transitionTo(FlashState.failed);
    }
  }

  /// 处理成功
  void _handleSuccess() {
    onLog('烧录成功！');
    final totalBytes = _blocks.fold<int>(
      0, (sum, block) => sum + block.data.length
    );
    _onProgress?.call(FlashProgress.completed(
      totalBlocks: _blocks.length,
      totalBytes: totalBytes,
      startTime: _startTime,
    ));
    _completer?.complete(const Right(true));
    _cleanup();
  }

  /// 处理失败
  void _handleFailure(String message) {
    onLog('烧录失败: $message');
    _onProgress?.call(FlashProgress.failed(message, startTime: _startTime));
    if (!_completer!.isCompleted) {
      _completer?.complete(Left(FlashFailure(message)));
    }
    _cleanup();
  }

  /// 中止烧录
  void abort() {
    if (_state != FlashState.idle && _state != FlashState.success && _state != FlashState.failed) {
      onLog('烧录被中止');
      _cancelTimeout();
      _onProgress?.call(FlashProgress.cancelled(startTime: _startTime));

      if (_completer != null && !_completer!.isCompleted) {
        _completer?.complete(const Left(FlashFailure('烧录被用户取消')));
      }

      _state = FlashState.failed;
      _cleanup();
    }
  }

  /// 启动超时定时器
  void _startTimeout(Duration duration, void Function() onTimeout) {
    _cancelTimeout();
    _timeoutTimer = Timer(duration, onTimeout);
  }

  /// 取消超时定时器
  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// 清理资源
  void _cleanup() {
    _cancelTimeout();
    _state = FlashState.idle;
    _blocks = [];
    _currentBlockIndex = 0;
    _totalCrc = 0;
    _retryCount = 0;
    _onProgress = null;
    _completer = null;
    _startTime = null;
  }
}
