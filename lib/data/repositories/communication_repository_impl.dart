import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/hex_parser.dart';
import '../../domain/entities/parameter_group_entity.dart';
import '../../domain/repositories/communication_repository.dart';
import '../../presentation/providers/log_provider.dart';
import '../datasources/bluetooth_datasource.dart';
import '../datasources/cross_platform_bluetooth_datasource.dart';
import '../datasources/serial_port_datasource.dart';
import '../datasources/cross_platform_serial_datasource.dart';
import '../models/flash_progress.dart';
import '../protocol/frame_builder.dart';
import '../protocol/frame_parser.dart';
import '../protocol/protocol_config.dart';
import '../services/flash_worker.dart';

/// 通信仓库实现
class CommunicationRepositoryImpl implements CommunicationRepository {
  final BluetoothDatasource? _bluetoothDatasource;
  final CrossPlatformBluetoothDatasource? _crossPlatformBluetoothDatasource;
  final SerialPortDatasource? _serialPortDatasource;
  final CrossPlatformSerialDatasource? _crossPlatformSerialDatasource;
  final ProtocolConfig _protocolConfig;
  final Ref _ref; // 添加Ref以访问Provider
  late final FrameBuilder _frameBuilder;
  late final FrameParser _frameParser;

  StreamSubscription? _dataSubscription;
  List<int> _buffer = [];

  // 缓冲区大小限制 - 调整为512字节以支持烧录功能
  static const int _maxBufferSize = 512;

  // FlashWorker 相关
  FlashWorker? _flashWorker;
  bool _isFlashing = false;

  // 用于等待响应的Completer
  Completer<ParsedParameterData>? _parameterCompleter;
  Completer<ParsedFlashResponse>? _flashCompleter;
  Completer<bool>? _writeParameterCompleter;

  // 日志流控制器
  final _logController = StreamController<String>.broadcast();

  /// 构造函数 - 支持蓝牙或串口
  CommunicationRepositoryImpl.bluetooth(
    BluetoothDatasource bluetoothDatasource,
    this._protocolConfig,
    this._ref,
  )   : _bluetoothDatasource = bluetoothDatasource,
        _crossPlatformBluetoothDatasource = null,
        _serialPortDatasource = null,
        _crossPlatformSerialDatasource = null {
    _frameBuilder = FrameBuilder(_protocolConfig);
    _frameParser = FrameParser(_protocolConfig);

    // 监听数据流
    _dataSubscription = bluetoothDatasource.dataStream.listen(_handleData);
  }

  /// 构造函数 - 跨平台蓝牙（Windows + 其他平台）
  CommunicationRepositoryImpl.crossPlatformBluetooth(
    CrossPlatformBluetoothDatasource crossPlatformBluetoothDatasource,
    this._protocolConfig,
    this._ref,
  )   : _bluetoothDatasource = null,
        _crossPlatformBluetoothDatasource = crossPlatformBluetoothDatasource,
        _serialPortDatasource = null,
        _crossPlatformSerialDatasource = null {
    _frameBuilder = FrameBuilder(_protocolConfig);
    _frameParser = FrameParser(_protocolConfig);

    // 监听数据流
    _dataSubscription = crossPlatformBluetoothDatasource.dataStream.listen(_handleData);
  }

  /// 构造函数 - 串口（桌面平台）
  CommunicationRepositoryImpl.serialPort(
    SerialPortDatasource serialPortDatasource,
    this._protocolConfig,
    this._ref,
  )   : _bluetoothDatasource = null,
        _crossPlatformBluetoothDatasource = null,
        _serialPortDatasource = serialPortDatasource,
        _crossPlatformSerialDatasource = null {
    _frameBuilder = FrameBuilder(_protocolConfig);
    _frameParser = FrameParser(_protocolConfig);

    // 监听数据流
    _dataSubscription = serialPortDatasource.dataStream.listen(_handleData);
  }

  /// 构造函数 - 跨平台串口（Android + 桌面）
  CommunicationRepositoryImpl.crossPlatformSerial(
    CrossPlatformSerialDatasource crossPlatformSerialDatasource,
    this._protocolConfig,
    this._ref,
  )   : _bluetoothDatasource = null,
        _crossPlatformBluetoothDatasource = null,
        _serialPortDatasource = null,
        _crossPlatformSerialDatasource = crossPlatformSerialDatasource {
    _frameBuilder = FrameBuilder(_protocolConfig);
    _frameParser = FrameParser(_protocolConfig);

    // 监听数据流
    _dataSubscription = crossPlatformSerialDatasource.dataStream.listen(_handleData);
  }

  @override
  Stream<String> get logStream => _logController.stream;

  /// 写入数据到当前数据源
  Future<void> _writeData(List<int> data) async {
    if (_bluetoothDatasource != null) {
      await _bluetoothDatasource.write(data);
    } else if (_crossPlatformBluetoothDatasource != null) {
      await _crossPlatformBluetoothDatasource.write(data);
    } else if (_serialPortDatasource != null) {
      await _serialPortDatasource.write(data);
    } else if (_crossPlatformSerialDatasource != null) {
      await _crossPlatformSerialDatasource.write(data);
    } else {
      throw Exception('没有可用的数据源');
    }
  }

  /// 处理接收到的数据
  void _handleData(List<int> data) {
    // 异步处理整个数据接收流程，避免阻塞事件循环
    Future.microtask(() => _handleDataAsync(data));
  }

  /// 异步处理数据（保持帧处理的顺序性）
  void _handleDataAsync(List<int> data) {
    final startTime = DateTime.now();
    try {
      // 临时禁用日志记录以测试性能
      // _ref.read(logProvider.notifier).addRxLog(data);

      // 添加到缓冲区
      _buffer.addAll(data);
      final bufferTime = DateTime.now().difference(startTime).inMicroseconds;
      print('[PERF] 缓冲区操作: ${bufferTime}μs');

      // 检查缓冲区大小，如果超过限制则截断
      if (_buffer.length > _maxBufferSize) {
        _buffer = _buffer.sublist(_buffer.length - _maxBufferSize);
        _addLog('接收缓冲区溢出，已截断至最新${_maxBufferSize}字节');
      }

      // 尝试提取完整帧
      while (true) {
        final parseStart = DateTime.now();
        final (frame, remaining) = _frameParser.findCompleteFrame(_buffer);
        final parseTime = DateTime.now().difference(parseStart).inMicroseconds;
        print('[PERF] 帧解析: ${parseTime}μs');

        if (frame == null) {
          _buffer = remaining;
          break;
        }

        _buffer = remaining;

        // 路由到 FlashWorker 或参数处理（同步，保持顺序）
        if (_isFlashing && _flashWorker != null) {
          final workerStart = DateTime.now();
          _flashWorker!.handleReceivedFrame(frame);
          final workerTime = DateTime.now().difference(workerStart).inMicroseconds;
          print('[PERF] Worker处理: ${workerTime}μs');
        } else {
          _processFrame(frame);
        }
      }

      final totalTime = DateTime.now().difference(startTime).inMicroseconds;
      print('[PERF] ⚠️ _handleData总耗时: ${totalTime}μs');
    } catch (e) {
      _addLog('处理数据错误: $e');
    }
  }

  /// 处理完整的帧
  void _processFrame(List<int> frame) {
    // 尝试解析为参数读取响应
    final paramData = _frameParser.parseParameterResponse(frame);
    if (paramData != null && _parameterCompleter != null && !_parameterCompleter!.isCompleted) {
      _parameterCompleter!.complete(paramData);
      return;
    }
    
    // 如果解析失败且有错误信息，完成 completer 并返回错误
    if (_parameterCompleter != null && !_parameterCompleter!.isCompleted && _frameParser.lastError != null) {
      _addLog('读取参数失败: ${_frameParser.lastError}');
      _parameterCompleter!.completeError(ProtocolFailure(_frameParser.lastError!));
      _parameterCompleter = null;
      return;
    }

    // 尝试解析为参数写入响应
    final writeResult = _frameParser.parseWriteParameterResponse(frame);
    if (writeResult != null && _writeParameterCompleter != null && !_writeParameterCompleter!.isCompleted) {
      _writeParameterCompleter!.complete(writeResult);
      return;
    }
    
    // 如果解析失败且有错误信息，完成 completer 并返回错误
    if (_writeParameterCompleter != null && !_writeParameterCompleter!.isCompleted && _frameParser.lastError != null) {
      _addLog('写入参数失败: ${_frameParser.lastError}');
      _writeParameterCompleter!.completeError(ProtocolFailure(_frameParser.lastError!));
      _writeParameterCompleter = null;
      return;
    }

    // 尝试解析为烧录响应
    final flashData = _frameParser.parseFlashResponse(frame);
    if (flashData != null && _flashCompleter != null && !_flashCompleter!.isCompleted) {
      _flashCompleter!.complete(flashData);
      return;
    }
  }

  /// 添加日志
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    _logController.add('[$timestamp] $message');
  }

  @override
  Future<Either<Failure, ParameterGroupEntity>> readParameters(String group) async {
    try {
      // 构建读取请求帧
      final frame = _frameBuilder.buildReadRequest(group);
      _addLog('发送读取请求: $group');

      // 记录发送的数据到日志
      // _ref.read(logProvider.notifier).addTxLog(frame);

      // 创建Completer等待响应
      _parameterCompleter = Completer<ParsedParameterData>();

      // 发送帧
      await _writeData(frame);

      // 等待响应（5秒超时）
      final response = await _parameterCompleter!.future
          .timeout(const Duration(seconds: 5));

      _addLog('收到参数响应: ${response.values.length} 个参数');

      // 转换为ParameterGroupEntity
      final parameters = response.values.entries
          .map((e) => ParameterEntity(
                key: e.key,
                name: e.key,
                unit: '',
                min: 0,
                max: 10000,
                precision: 2,
                value: e.value,
              ))
          .toList();

      return Right(ParameterGroupEntity(
        group: group,
        displayName: '参数组$group',
        parameters: parameters,
      ));
    } catch (e) {
      if (e is TimeoutException) {
        _addLog('读取参数超时');
        return const Left(TimeoutFailure('读取参数超时'));
      }
      if (e is ProtocolFailure) {
        // 已经在 _processFrame 中记录了日志
        return Left(e);
      }
      _addLog('读取参数失败: $e');
      return Left(ProtocolFailure('读取参数失败: $e'));
    } finally {
      _parameterCompleter = null;
    }
  }

  @override
  Future<Either<Failure, bool>> writeParameters(
    String group,
    Map<String, double> parameters,
  ) async {
    try {
      // 构建精度映射（默认2位小数）
      final precisionMap = <String, int>{};
      for (var key in parameters.keys) {
        precisionMap[key] = 2;
      }

      // 构建写入帧
      final frame = _frameBuilder.buildWriteFrame(group, parameters, precisionMap);
      _addLog('发送写入请求: $group, ${parameters.length} 个参数');

      // 记录发送的数据到日志
      // _ref.read(logProvider.notifier).addTxLog(frame);

      // 创建Completer等待响应
      _writeParameterCompleter = Completer<bool>();

      // 发送帧
      await _writeData(frame);

      // 等待写入确认响应（带超时）
      final result = await _writeParameterCompleter!.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          _addLog('写入参数响应超时');
          return false;
        },
      );

      if (result) {
        _addLog('写入参数成功（CRC校验通过）');
        return const Right(true);
      } else {
        _addLog('写入参数失败（设备返回错误）');
        return const Left(ProtocolFailure('写入参数失败'));
      }
    } on TimeoutException {
      _addLog('写入参数超时');
      return const Left(TimeoutFailure('写入参数超时'));
    } on ProtocolFailure catch (e) {
      // 已经在 _processFrame 中记录了日志
      return Left(e);
    } catch (e) {
      _addLog('写入参数失败: $e');
      return Left(ProtocolFailure('写入参数失败: $e'));
    } finally {
      _writeParameterCompleter = null;
    }
  }

  @override
  Future<Either<Failure, bool>> flashFirmware(
    String hexFilePath, {
    void Function(FlashProgress progress)? onProgress,
    int? initTimeout,
    int? initMaxRetries,
    int? programRetryDelay,
  }) async {
    try {
      _addLog('开始烧录固件: $hexFilePath');

      // 创建 FlashWorker
      _flashWorker = FlashWorker(
        writeData: _writeData,
        frameBuilder: _frameBuilder,
        frameParser: _frameParser,
        protocolConfig: _protocolConfig,
        onLog: _addLog,
        onTxData: (data) {
          // 记录发送的数据到日志
          // _ref.read(logProvider.notifier).addTxLog(data);
        },
        initTimeout: initTimeout ?? 50,
        initMaxRetries: initMaxRetries ?? 100,
        programRetryDelay: programRetryDelay ?? 50,
      );
      _isFlashing = true;

      // 读取 HEX 文件
      String hexContent;
      if (hexFilePath.startsWith('assets/')) {
        // 从 assets 读取
        try {
          hexContent = await rootBundle.loadString(hexFilePath);
          _addLog('从 assets 读取 HEX 文件成功');
        } catch (e) {
          return Left(FileFailure('无法读取 assets 文件: $e'));
        }
      } else {
        // 从文件系统读取
        final file = File(hexFilePath);
        if (!await file.exists()) {
          return const Left(FileFailure('HEX 文件不存在'));
        }
        hexContent = await file.readAsString();
        _addLog('从文件系统读取 HEX 文件成功');
      }

      // 解析 HEX 文件
      final parser = HexParser();
      if (!parser.parseContent(hexContent)) {
        return const Left(FileFailure('HEX 文件解析失败'));
      }

      final blocks = parser.getDataBlocks(blockSize: 256);  // 使用256字节以适应BLE MTU限制
      _addLog('HEX 文件解析成功: ${blocks.length} 个数据块');

      // 启动 FlashWorker（传入已解析的数据）
      final result = await _flashWorker!.startFlashWithBlocks(
        blocks,
        (flashProgress) {
          // 直接传递完整的 FlashProgress 对象
          onProgress?.call(flashProgress);
        },
      );

      return result;
    } catch (e) {
      _addLog('烧录固件失败: $e');
      return Left(FlashFailure('烧录固件失败: $e'));
    } finally {
      _isFlashing = false;
      _flashWorker = null;
    }
  }

  /// 停止烧录
  void abortFlashing() {
    if (_flashWorker != null && _isFlashing) {
      _addLog('用户请求停止烧录');
      _flashWorker!.abort();
    }
  }

  void dispose() {
    _dataSubscription?.cancel();
    _logController.close();
  }
}
