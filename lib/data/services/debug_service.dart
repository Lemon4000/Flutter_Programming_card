import 'dart:async';
import 'dart:async';
import '../models/debug_response.dart';
import '../protocol/frame_builder.dart';
import '../protocol/frame_parser.dart';
import '../datasources/bluetooth_datasource.dart';

/// 调试服务
///
/// 负责处理调试模式下的指令发送和响应接收
class DebugService {
  final BluetoothDatasource bluetoothDatasource;
  final FrameBuilder frameBuilder;
  final FrameParser frameParser;
  final void Function(String) onLog;

  Timer? _timeoutTimer;
  Completer<DebugResponse>? _responseCompleter;
  DateTime? _sendTime;
  StreamSubscription? _dataSubscription;

  DebugService({
    required this.bluetoothDatasource,
    required this.frameBuilder,
    required this.frameParser,
    required this.onLog,
  }) {
    // 监听蓝牙数据流
    _dataSubscription = bluetoothDatasource.dataStream.listen(_handleReceivedData);
  }

  /// 发送握手指令
  ///
  /// 格式: !HEX;
  Future<DebugResponse> sendHandshake({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final startTime = DateTime.now();
    _sendTime = startTime;
    _responseCompleter = Completer<DebugResponse>();

    try {
      // 构建握手帧
      final frame = frameBuilder.buildInitFrame();

      // 发送
      onLog('发送握手指令: !HEX;');
      await bluetoothDatasource.write(frame);

      // 设置超时
      _startTimeout(timeout, () {
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(DebugResponse.timeout(
            message: '握手超时',
            elapsed: DateTime.now().difference(startTime),
            sendTime: _sendTime,
          ));
        }
      });

      return await _responseCompleter!.future;
    } catch (e) {
      return DebugResponse.error(
        message: '发送失败: $e',
        elapsed: DateTime.now().difference(startTime),
        sendTime: _sendTime,
      );
    }
  }

  /// 发送擦除指令
  ///
  /// 格式: !HEX:ESIZE[块数];
  Future<DebugResponse> sendErase({
    required int blockCount,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final startTime = DateTime.now();
    _sendTime = startTime;
    _responseCompleter = Completer<DebugResponse>();

    try {
      // 构建擦除帧
      final frame = frameBuilder.buildEraseFrame(blockCount);

      // 发送
      onLog('发送擦除指令: !HEX:ESIZE$blockCount;');
      await bluetoothDatasource.write(frame);

      // 设置超时
      _startTimeout(timeout, () {
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(DebugResponse.timeout(
            message: '擦除超时',
            elapsed: DateTime.now().difference(startTime),
            sendTime: _sendTime,
          ));
        }
      });

      return await _responseCompleter!.future;
    } catch (e) {
      return DebugResponse.error(
        message: '发送失败: $e',
        elapsed: DateTime.now().difference(startTime),
        sendTime: _sendTime,
      );
    }
  }

  /// 发送数据帧
  ///
  /// 格式: !HEX:START[地址],SIZE[大小],DATA[数据];
  Future<DebugResponse> sendDataFrame({
    required int address,
    required List<int> data,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final startTime = DateTime.now();
    _sendTime = startTime;
    _responseCompleter = Completer<DebugResponse>();

    try {
      // 构建数据帧
      final frame = frameBuilder.buildFlashDataFrame(address, data);

      // 发送
      final addressHex = address.toRadixString(16).toUpperCase().padLeft(8, '0');
      onLog('发送数据帧: START$addressHex, SIZE${data.length}');
      await bluetoothDatasource.write(frame);

      // 设置超时
      _startTimeout(timeout, () {
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(DebugResponse.timeout(
            message: '数据帧超时',
            elapsed: DateTime.now().difference(startTime),
            sendTime: _sendTime,
          ));
        }
      });

      return await _responseCompleter!.future;
    } catch (e) {
      return DebugResponse.error(
        message: '发送失败: $e',
        elapsed: DateTime.now().difference(startTime),
        sendTime: _sendTime,
      );
    }
  }

  /// 发送验证指令
  ///
  /// 格式: !HEX:ENDCRC[2字节CRC];
  Future<DebugResponse> sendVerify({
    required int totalCrc,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final startTime = DateTime.now();
    _sendTime = startTime;
    _responseCompleter = Completer<DebugResponse>();

    try {
      // 构建验证帧
      final frame = frameBuilder.buildFlashVerifyFrame(totalCrc);

      // 发送
      final crcHex = totalCrc.toRadixString(16).toUpperCase().padLeft(4, '0');
      onLog('发送验证指令: !HEX:ENDCRC$crcHex;');
      await bluetoothDatasource.write(frame);

      // 设置超时
      _startTimeout(timeout, () {
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(DebugResponse.timeout(
            message: '验证超时',
            elapsed: DateTime.now().difference(startTime),
            sendTime: _sendTime,
          ));
        }
      });

      return await _responseCompleter!.future;
    } catch (e) {
      return DebugResponse.error(
        message: '发送失败: $e',
        elapsed: DateTime.now().difference(startTime),
        sendTime: _sendTime,
      );
    }
  }

  /// 处理接收到的数据
  void _handleReceivedData(List<int> frame) {
    if (_responseCompleter == null || _responseCompleter!.isCompleted) {
      return;
    }

    _cancelTimeout();

    final receiveTime = DateTime.now();
    final elapsed = _sendTime != null ? receiveTime.difference(_sendTime!) : Duration.zero;

    try {
      // 尝试解析为初始化响应
      final initResponse = frameParser.parseInitResponse(frame);
      if (initResponse != null) {
        _completeResponse(
          success: initResponse.success,
          message: initResponse.success ? '握手成功' : '握手失败',
          rawData: frame,
          parsedData: {'type': 'init', 'success': initResponse.success},
          elapsed: elapsed,
          receiveTime: receiveTime,
        );
        return;
      }

      // 尝试解析为擦除响应
      final eraseResponse = frameParser.parseEraseResponse(frame);
      if (eraseResponse != null) {
        _completeResponse(
          success: eraseResponse.success,
          message: eraseResponse.success ? '擦除成功' : '擦除失败',
          rawData: frame,
          parsedData: {'type': 'erase', 'success': eraseResponse.success},
          elapsed: elapsed,
          receiveTime: receiveTime,
        );
        return;
      }

      // 尝试解析为编程响应
      final programResponse = frameParser.parseProgramResponse(frame);
      if (programResponse != null) {
        final crcValue = (programResponse.replyCrc[0] << 8) | programResponse.replyCrc[1];
        _completeResponse(
          success: programResponse.success,
          message: programResponse.success ? '数据帧成功' : '数据帧失败',
          rawData: frame,
          parsedData: {
            'type': 'program',
            'success': programResponse.success,
            'crc': crcValue,
          },
          elapsed: elapsed,
          receiveTime: receiveTime,
        );
        return;
      }

      // 尝试解析为验证响应
      final verifyResponse = frameParser.parseVerifyResponse(frame);
      if (verifyResponse != null) {
        final crcValue = (verifyResponse.replyCrc[0] << 8) | verifyResponse.replyCrc[1];
        _completeResponse(
          success: verifyResponse.success,
          message: verifyResponse.success ? '验证成功' : '验证失败',
          rawData: frame,
          parsedData: {
            'type': 'verify',
            'success': verifyResponse.success,
            'crc': crcValue,
          },
          elapsed: elapsed,
          receiveTime: receiveTime,
        );
        return;
      }

      // 无法解析
      _completeResponse(
        success: false,
        message: '响应解析失败',
        rawData: frame,
        parsedData: null,
        elapsed: elapsed,
        receiveTime: receiveTime,
      );
    } catch (e) {
      _completeResponse(
        success: false,
        message: '响应处理异常: $e',
        rawData: frame,
        parsedData: null,
        elapsed: elapsed,
        receiveTime: receiveTime,
      );
    }
  }

  /// 完成响应
  void _completeResponse({
    required bool success,
    required String message,
    required List<int>? rawData,
    required Map<String, dynamic>? parsedData,
    required Duration elapsed,
    required DateTime receiveTime,
  }) {
    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      if (success) {
        _responseCompleter!.complete(DebugResponse.success(
          message: message,
          rawData: rawData,
          parsedData: parsedData,
          elapsed: elapsed,
          sendTime: _sendTime,
          receiveTime: receiveTime,
        ));
      } else {
        _responseCompleter!.complete(DebugResponse.error(
          message: message,
          rawData: rawData,
          elapsed: elapsed,
          sendTime: _sendTime,
        ));
      }
    }
  }

  /// 启动超时定时器
  void _startTimeout(Duration timeout, void Function() onTimeout) {
    _cancelTimeout();
    _timeoutTimer = Timer(timeout, onTimeout);
  }

  /// 取消超时定时器
  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// 只发送数据帧，不等待响应
  ///
  /// 用于连续发送模式，只等待数据写入蓝牙缓冲区
  Future<void> sendDataFrameOnly({
    required int address,
    required List<int> data,
  }) async {
    try {
      // 构建数据帧
      final frame = frameBuilder.buildFlashDataFrame(address, data);

      // 发送（等待写入蓝牙缓冲区完成）
      await bluetoothDatasource.write(frame);
    } catch (e) {
      onLog('发送数据帧失败: $e');
      rethrow;
    }
  }

  /// 释放资源
  void dispose() {
    _cancelTimeout();
    _dataSubscription?.cancel();
    _dataSubscription = null;
    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      _responseCompleter!.completeError('Service disposed');
    }
    _responseCompleter = null;
  }
}
