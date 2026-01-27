import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'scan_screen.dart';
import 'parameter_screen.dart';
import 'flash_screen.dart';
import 'log_screen.dart';
import 'debug_screen.dart';
import '../providers/providers.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';

/// 主界面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _connectionStateSubscription;
  bool _isInitialConnection = true; // 标记是否是初始连接

  final List<Widget> _screens = [
    const ScanScreen(), // 使用真实蓝牙扫描页面
    const ParameterScreen(), // 参数读写页面
    const FlashScreen(), // 烧录页面
    const LogScreen(), // 通信日志页面
    const DebugScreen(), // 调试页面
  ];

  @override
  void initState() {
    super.initState();
    _setupConnectionStateListener();
  }

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    super.dispose();
  }

  /// 设置连接状态监听
  void _setupConnectionStateListener() {
    // 延迟获取 datasource，确保 provider 已初始化
    Future.microtask(() {
      try {
        final bluetoothDatasource = ref.read(bluetoothDatasourceProvider);
        _connectionStateSubscription = bluetoothDatasource.connectionStateStream.listen(
          (isConnected) {
            AppLogger.info('连接状态变化: $isConnected', 'HomeScreen');

            // 如果是初始连接且状态为断开，忽略（这是初始状态）
            if (_isInitialConnection && !isConnected) {
              _isInitialConnection = false;
              return;
            }

            // 标记已经不是初始连接了
            _isInitialConnection = false;

            if (!isConnected && mounted) {
              // 连接断开，更新状态
              ref.read(connectionStateProvider.notifier).state = false;
              ref.read(connectedDeviceIdProvider.notifier).state = null;
              ref.read(connectedDeviceNameProvider.notifier).state = null;

              // 显示提示（缩短时间）
              SnackBarHelper.showError(context, '设备连接已断开');
            } else if (isConnected && mounted) {
              // 连接成功，重置初始连接标志
              _isInitialConnection = false;
            }
          },
          onError: (error) {
            AppLogger.error('连接状态监听错误', 'HomeScreen', error);
          },
        );
      } catch (e) {
        AppLogger.error('设置连接状态监听失败', 'HomeScreen', e);
      }
    });
  }

  Future<void> _disconnectDevice() async {
    // 调用断开连接
    final deviceRepo = ref.read(deviceRepositoryProvider);
    await deviceRepo.disconnect();

    // 更新状态
    ref.read(connectionStateProvider.notifier).state = false;
    ref.read(connectedDeviceIdProvider.notifier).state = null;
    ref.read(connectedDeviceNameProvider.notifier).state = null;

    // 重置初始连接标志，为下次连接做准备
    _isInitialConnection = true;

    if (mounted) {
      SnackBarHelper.showWarning(context, '已断开连接');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStateProvider);
    final deviceName = ref.watch(connectedDeviceNameProvider);

    AppLogger.debug('build - isConnected: $isConnected, deviceName: $deviceName', 'HomeScreen');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // 应用标题带渐变效果
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: const Text(
                '编程卡上位机',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isConnected)
              Flexible(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 脉冲动画的蓝牙图标
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        tween: Tween(begin: 0.8, end: 1.2),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: const Icon(Icons.bluetooth_connected, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          deviceName ?? '已连接',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: '断开连接',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _disconnectDevice,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          elevation: 0,
          height: 70,
          animationDuration: const Duration(milliseconds: 400),
          destinations: [
            NavigationDestination(
              icon: _buildNavIcon(Icons.bluetooth_searching, false, 0),
              selectedIcon: _buildNavIcon(Icons.bluetooth_connected, true, 0),
              label: '设备',
            ),
            NavigationDestination(
              icon: _buildNavIcon(Icons.settings_outlined, false, 1),
              selectedIcon: _buildNavIcon(Icons.settings, true, 1),
              label: '参数',
            ),
            NavigationDestination(
              icon: _buildNavIcon(Icons.upload_file_outlined, false, 2),
              selectedIcon: _buildNavIcon(Icons.upload_file, true, 2),
              label: '烧录',
            ),
            NavigationDestination(
              icon: _buildNavIcon(Icons.list_alt_outlined, false, 3),
              selectedIcon: _buildNavIcon(Icons.list_alt, true, 3),
              label: '日志',
            ),
            NavigationDestination(
              icon: _buildNavIcon(Icons.bug_report_outlined, false, 4),
              selectedIcon: _buildNavIcon(Icons.bug_report, true, 4),
              label: '调试',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导航图标（带动画效果）
  Widget _buildNavIcon(IconData icon, bool isSelected, int index) {
    final isCurrentTab = _selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentTab && isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: isCurrentTab && isSelected ? 1.1 : 1.0,
        child: Icon(
          icon,
          size: 24,
        ),
      ),
    );
  }
}

