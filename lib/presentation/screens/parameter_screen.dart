import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/parameter.dart';
import '../../domain/entities/parameter_group.dart';
import '../providers/providers.dart';

/// 参数读写页面
class ParameterScreen extends ConsumerStatefulWidget {
  const ParameterScreen({super.key});

  @override
  ConsumerState<ParameterScreen> createState() => _ParameterScreenState();
}

class _ParameterScreenState extends ConsumerState<ParameterScreen> {
  ParameterGroup? _parameterGroup;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadParameterGroup();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadParameterGroup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final configRepo = ref.read(configRepositoryProvider);
    final result = await configRepo.loadParameterGroup('A');

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _errorMessage = failure.toUserMessage();
            _isLoading = false;
          });
        }
      },
      (group) {
        if (mounted) {
          setState(() {
            _parameterGroup = group;
            _isLoading = false;
            
            // 初始化控制器
            for (var param in group.parameters) {
              _controllers[param.key] = TextEditingController(
                text: param.defaultValue.toStringAsFixed(param.precision),
              );
            }
          });
        }
      },
    );
  }

  Future<void> _readParameters() async {
    final isConnected = ref.read(connectionStateProvider);
    if (!isConnected) {
      _showMessage('请先连接设备', isError: true);
      return;
    }

    if (_parameterGroup == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 调用通信仓储读取参数
      final commRepo = await ref.read(communicationRepositoryProvider.future);
      final result = await commRepo.readParameters(_parameterGroup!.groupId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        result.fold(
          (failure) {
            _showMessage(failure.toUserMessage(), isError: true);
          },
          (parameterGroup) {
            // 更新控制器的值
            for (var param in parameterGroup.parameters) {
              if (_controllers.containsKey(param.key)) {
                _controllers[param.key]?.text = param.value.toStringAsFixed(
                  _parameterGroup!.parameters
                      .firstWhere((p) => p.key == param.key)
                      .precision,
                );
              }
            }
            _showMessage('读取参数成功');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showMessage('读取失败: $e', isError: true);
      }
    }
  }

  Future<void> _writeParameters() async {
    final isConnected = ref.read(connectionStateProvider);
    if (!isConnected) {
      _showMessage('请先连接设备', isError: true);
      return;
    }

    if (_parameterGroup == null) return;

    // 收集所有参数值
    final values = <String, double>{};

    // 验证所有参数
    for (var param in _parameterGroup!.parameters) {
      final text = _controllers[param.key]?.text ?? '';
      final value = double.tryParse(text);

      if (value == null) {
        _showMessage('${param.name} 的值无效', isError: true);
        return;
      }

      if (!param.isValid(value)) {
        _showMessage(
          '${param.name} 的值超出范围 (${param.min}-${param.max})',
          isError: true,
        );
        return;
      }

      values[param.key] = value;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 调用通信仓储写入参数
      final commRepo = await ref.read(communicationRepositoryProvider.future);
      final result = await commRepo.writeParameters(
        _parameterGroup!.groupId,
        values,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        result.fold(
          (failure) {
            _showMessage(failure.toUserMessage(), isError: true);
          },
          (success) {
            _showMessage('写入参数成功');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showMessage('写入失败: $e', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStateProvider);

    return Scaffold(
      body: Column(
        children: [
          // 顶部提示栏
          if (!isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade100, Colors.orange.shade50],
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.orange.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '请先连接设备后再进行参数读写操作',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 操作按钮
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _readParameters,
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text(
                      '读取参数',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _writeParameters,
                    icon: const Icon(Icons.upload_rounded, size: 20),
                    label: const Text(
                      '写入参数',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 错误信息
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 参数列表
          Expanded(
            child: _isLoading && _parameterGroup == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '正在加载参数配置...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _parameterGroup == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: Colors.red.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _errorMessage ?? '加载配置失败',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadParameterGroup,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('重试'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _parameterGroup!.parameters.length,
                        itemBuilder: (context, index) {
                          final param = _parameterGroup!.parameters[index];
                          return _buildParameterCard(param);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(Parameter param) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      param.key,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      param.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[param.key],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '值',
                        suffixText: param.unit,
                        helperText: '范围: ${param.min} - ${param.max}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
