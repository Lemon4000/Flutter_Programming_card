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
import '../models/flash_progress.dart';
import '../protocol/frame_builder.dart';
import '../protocol/frame_parser.dart';
import '../protocol/protocol_config.dart';
import '../services/flash_worker.dart';

/// 通信仓库实现
class CommunicationRepositoryImpl implements CommunicationRepository {
  final BluetoothDatasource _bluetoothDatasource;
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

  // 日志流控制器
  final _logController = StreamController<String>.broadcast();

  CommunicationRepositoryImpl(
    this._bluetoothDatasource,
    this._protocolConfig,
    this._ref,
  ) {
    _frameBuilder = FrameBuilder(_protocolConfig);
    _frameParser = FrameParser(_protocolConfig);

    // 监听数据流
    _dataSubscription = _bluetoothDatasource.dataStream.listen(_handleData);
  }

  @override
  Stream<String> get logStream => _logController.stream;

  /// 处理接收到的数据
  void _handleData(List<int> data) {
    try {
      // 记录接收的原始数据到日志
      _ref.read(logProvider.notifier).addRxLog(data);

      // 添加到缓冲区
      _buffer.addAll(data);

      // 检查缓冲区大小，如果超过限制则截断
      if (_buffer.length > _maxBufferSize) {
        _buffer = _buffer.sublist(_buffer.length - _maxBufferSize);
        _addLog('接收缓冲区溢出，已截断至最新${_maxBufferSize}字节');
      }

      // 尝试提取完整帧
      while (true) {
        final (frame, remaining) = _frameParser.findCompleteFrame(_buffer);
        if (frame == null) {
          _buffer = remaining;
          break;
        }

        _buffer = remaining;

        // 路由到 FlashWorker 或参数处理
        if (_isFlashing && _flashWorker != null) {
          _flashWorker!.handleReceivedFrame(frame);
        } else {
          _processFrame(frame);
        }
      }
    } catch (e) {
      _addLog('处理数据错误: $e');
    }
  }

  /// 处理完整的帧
  void _processFrame(List<int> frame) {
    // 尝试解析为参数响应
    final paramData = _frameParser.parseParameterResponse(frame);
    if (paramData != null && _parameterCompleter != null && !_parameterCompleter!.isCompleted) {
      _parameterCompleter!.complete(paramData);
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
      _ref.read(logProvider.notifier).addTxLog(frame);

      // 创建Completer等待响应
      _parameterCompleter = Completer<ParsedParameterData>();

      // 发送帧
      await _bluetoothDatasource.write(frame);

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
      _ref.read(logProvider.notifier).addTxLog(frame);

      // 发送帧
      await _bluetoothDatasource.write(frame);

      // TODO: 等待写入确认响应
      await Future.delayed(const Duration(milliseconds: 500));

      _addLog('写入参数成功');
      return const Right(true);
    } catch (e) {
      _addLog('写入参数失败: $e');
      return Left(ProtocolFailure('写入参数失败: $e'));
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
        bluetoothDatasource: _bluetoothDatasource,
        frameBuilder: _frameBuilder,
        frameParser: _frameParser,
        protocolConfig: _protocolConfig,
        onLog: _addLog,
        onTxData: (data) {
          // 记录发送的数据到日志
          _ref.read(logProvider.notifier).addTxLog(data);
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
