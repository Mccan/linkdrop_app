import 'dart:io';
import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/model/cross_file.dart';
import 'package:linkdrop_app/model/send_mode.dart';
import 'package:linkdrop_app/pages/receive_history_page.dart' show HistoryPage;
import 'package:linkdrop_app/pages/selected_files_page.dart';
import 'package:linkdrop_app/pages/tabs/send_tab_vm.dart';
import 'package:linkdrop_app/pages/widget/device_node.dart';
import 'package:linkdrop_app/pages/widget/pulse_ripple.dart';
import 'package:linkdrop_app/provider/network/nearby_devices_provider.dart';
import 'package:linkdrop_app/provider/network/scan_facade.dart';
import 'package:linkdrop_app/provider/selection/selected_sending_files_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/file_size_helper.dart';
import 'package:linkdrop_app/util/native/cross_file_converters.dart';
import 'package:linkdrop_app/util/native/file_picker.dart';
import 'package:linkdrop_app/util/permission_checker.dart';
import 'package:linkdrop_app/widget/dialogs/send_mode_help_dialog.dart';
import 'package:linkdrop_app/widget/file_thumbnail.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// 发送页面
///
/// 支持文件选择、设备扫描和文件发送
/// 提供多种发送模式：单个接收者、多个接收者、通过链接分享
class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> with Refena, PermissionControlMixin {
  bool _dragAndDropIndicator = false;
  bool _isScanning = false;

  /// 发送页需要会员权限（包含登录检查）
  @override
  PermissionStatus get requiredPermission => PermissionStatus.requiresMembership;

  Future<void> _handleScan(BuildContext context) async {
    setState(() {
      _isScanning = true;
    });

    context.redux(nearbyDevicesProvider).dispatch(ClearFoundDevicesAction());

    try {
      await context.global.dispatchAsync(StartSmartScan(forceLegacy: true));
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 权限检查中显示加载界面
    if (isCheckingPermission) {
      return buildPermissionCheckingWidget();
    }

    // 无权限显示提示界面
    if (!hasPermission) {
      return buildNoPermissionWidget();
    }

    final vm = context.watch(sendTabVmProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 根据可用高度决定布局策略
          final availableHeight = constraints.maxHeight;
          final isCompactHeight = availableHeight < 600;

          // 动态调整间距和尺寸
          final titlePadding = isCompactHeight ? 12.0 : 16.0;
          final controlPadding = isCompactHeight ? 12.0 : 24.0;

          // 根据高度调整 flex 比例
          // 高屏幕：设备发现 60%，文件选择 40%
          // 矮屏幕：设备发现 50%，文件选择 50%
          final deviceFlex = isCompactHeight ? 5 : 6;
          final fileFlex = isCompactHeight ? 5 : 4;

          return Column(
            children: [
              // 顶部标题栏
              Padding(
                padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + titlePadding, 32, titlePadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                t.sendTab.title,
                                style: TextStyle(
                                  fontSize: isCompactHeight ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : LinkDropColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              // 历史记录按钮
                              IconButton(
                                onPressed: () {
                                  // ignore: discarded_futures
                                  context.push(() => const HistoryPage(initialTab: 1));
                                },
                                icon: const Icon(Icons.history),
                                tooltip: 'History',
                                color: LinkDropColors.textSecondary,
                                iconSize: isCompactHeight ? 20 : 24,
                              ),
                            ],
                          ),
                          if (!isCompactHeight) ...[
                            const SizedBox(height: 4),
                            Text(
                              t.sendTab.subtitle,
                              style: TextStyle(
                                color: LinkDropColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 设备发现区域
              Expanded(
                flex: deviceFlex,
                child: Column(
                  children: [
                    // 控制栏
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: controlPadding, vertical: isCompactHeight ? 4 : 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ControlButton(
                              icon: Icons.refresh_rounded,
                              label: t.sendTab.scan,
                              onTap: () => _handleScan(context),
                              isDark: isDark,
                              isRotating: _isScanning,
                            ),
                          ),
                          Expanded(
                            child: _ControlButton(
                              icon: Icons.keyboard_alt_rounded,
                              label: t.sendTab.manualSending,
                              onTap: () => vm.onTapAddress(context),
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _SendModeButton(
                              label: vm.sendMode.humanName,
                              isDark: isDark,
                              onSelect: (mode) => vm.onTapSendMode(context, mode),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 设备列表
                    Expanded(
                      child: vm.nearbyDevices.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          PulseRipple(
                                            color: isDark ? LinkDropColors.primary : LinkDropColors.primaryDark,
                                            shouldRotate: true,
                                            child: Icon(
                                              Icons.radar_rounded,
                                              size: isCompactHeight ? 32 : 44,
                                              color: isDark ? LinkDropColors.primary : LinkDropColors.primaryDark,
                                            ),
                                          ),
                                          SizedBox(height: isCompactHeight ? 12 : 20),
                                          Text(
                                            t.sendTab.scanning,
                                            style: TextStyle(
                                              color: LinkDropColors.textSecondary,
                                              fontSize: isCompactHeight ? 12 : 14,
                                            ),
                                          ),
                                          if (!isCompactHeight) ...[
                                            const SizedBox(height: 12),
                                            _buildHotspotTip(isDark),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: vm.nearbyDevices.length,
                              itemBuilder: (context, index) {
                                final device = vm.nearbyDevices.elementAt(index);
                                final isFavorite = vm.favoriteDevices.any((fav) => fav.fingerprint == device.fingerprint);
                                return DeviceNode(
                                  device: device,
                                  isDark: isDark,
                                  isFavorite: isFavorite,
                                  displayNameOverride: vm.deviceAliasOverrides[device.fingerprint],
                                  onTap: () => vm.onTapDevice(context, device),
                                  onEditAlias: () => vm.onEditDeviceAlias(context, device),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // 文件选择区域
              Expanded(
                flex: fileFlex,
                child: DropTarget(
                  onDragEntered: (_) => setState(() => _dragAndDropIndicator = true),
                  onDragExited: (_) => setState(() => _dragAndDropIndicator = false),
                  onDragDone: (event) async {
                    if (event.files.length == 1 && Directory(event.files.first.path).existsSync()) {
                      await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(event.files.first.path));
                    } else {
                      await ref
                          .redux(selectedSendingFilesProvider)
                          .dispatchAsync(
                            AddFilesAction(
                              files: event.files,
                              converter: CrossFileConverters.convertXFile,
                            ),
                          );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(16, isCompactHeight ? 4 : 8, 16, isCompactHeight ? 8 : 16),
                    decoration: BoxDecoration(
                      // 白色/透明背景，只在拖拽时显示浅色提示
                      color: _dragAndDropIndicator
                          ? (isDark ? LinkDropColors.zinc800 : const Color(0xFFE0F2F1)).withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: _dragAndDropIndicator
                          ? Border.all(
                              color: LinkDropColors.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: vm.selectedFiles.isEmpty
                        ? _buildSelectionOptions(context, vm, isDark, isCompactHeight)
                        : _buildSelectedFiles(context, vm, isDark, isCompactHeight),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建选择选项区域
  ///
  /// 使用扇子展开动画的文件选择器
  Widget _buildSelectionOptions(BuildContext context, SendTabVm vm, bool isDark, bool isCompactHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCompactHeight ? 8 : 16),
      child: _FanFileSelector(
        isDark: isDark,
        isCompact: isCompactHeight,
        onOptionSelected: (option) => _pickFiles(context, option),
      ),
    );
  }

  /// 构建已选文件区域
  ///
  /// 显示已选文件的预览和操作按钮
  Widget _buildSelectedFiles(BuildContext context, SendTabVm vm, bool isDark, bool isCompactHeight) {
    final totalSize = vm.selectedFiles.fold<int>(0, (prev, curr) => prev + curr.size);

    // 紧凑模式下的尺寸调整
    final titleFontSize = isCompactHeight ? 14.0 : 16.0;
    final sectionSpacing = isCompactHeight ? 8.0 : 16.0;
    final statsFontSize = isCompactHeight ? 12.0 : 13.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, isCompactHeight ? 8 : 16, 16, isCompactHeight ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Expanded(
                child: Text(
                  t.sendTab.selectedFiles,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : LinkDropColors.textPrimary,
                  ),
                ),
              ),
              // 清除按钮
              InkWell(
                onTap: () => context.ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction()),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: isCompactHeight ? 16 : 18,
                    color: LinkDropColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: sectionSpacing),

          // 文件统计信息
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: isCompactHeight ? 12 : 14,
                    color: LinkDropColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${vm.selectedFiles.length} files',
                    style: TextStyle(
                      fontSize: statsFontSize,
                      color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: isCompactHeight ? 12 : 14,
                    color: LinkDropColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    totalSize.asReadableFileSize,
                    style: TextStyle(
                      fontSize: statsFontSize,
                      color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: isCompactHeight ? 6 : sectionSpacing),

          // 文件预览区（随可用空间自适应）
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 很矮时用横向滚动，避免网格过挤；高度足够则用网格，随空间增减显示更多行/列。
                // 紧凑模式下降低阈值
                final heightThreshold = isCompactHeight ? 80.0 : 120.0;
                final useHorizontalList = constraints.maxHeight < heightThreshold;

                if (useHorizontalList) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: vm.selectedFiles.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final file = vm.selectedFiles[index];
                      return Padding(
                        padding: EdgeInsets.only(right: index == vm.selectedFiles.length - 1 ? 0 : 8),
                        child: SizedBox(
                          width: isCompactHeight ? 70 : 84,
                          child: _FileThumbnailCard(
                            file: file,
                            isDark: isDark,
                            fileNameFontSize: isCompactHeight ? 9 : 10,
                            onTap: () => _removeFile(context, index),
                          ),
                        ),
                      );
                    },
                  );
                }

                // 垂直响应式：文件较少时让卡片高度随剩余空间伸缩填充；文件较多时固定高度并滚动。
                final minTileWidth = constraints.maxWidth >= 560 ? 132.0 : 116.0;
                final estimatedColumns = (constraints.maxWidth / (minTileWidth + 12)).floor();
                final columns = math.max(2, estimatedColumns);
                final rows = (vm.selectedFiles.length / columns).ceil();

                final isDense = vm.selectedFiles.length > columns * 3;
                final minTileHeight = isCompactHeight ? 80.0 : 96.0;
                final maxTileHeight = isCompactHeight ? 120.0 : 156.0;
                final defaultTileHeight = isCompactHeight ? 96.0 : 112.0;
                final targetTileHeight = isDense
                    ? defaultTileHeight
                    : ((constraints.maxHeight - 12 * math.max(0, rows - 1)) / math.max(1, rows)).clamp(minTileHeight, maxTileHeight);

                return GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: isDense ? null : const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: targetTileHeight,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: vm.selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = vm.selectedFiles[index];
                    return _FileThumbnailCard(
                      file: file,
                      isDark: isDark,
                      fileNameFontSize: isCompactHeight ? 10 : 11,
                      onTap: () => _removeFile(context, index),
                    );
                  },
                );
              },
            ),
          ),

          SizedBox(height: isCompactHeight ? 6 : sectionSpacing),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_rounded,
                  label: t.sendTab.addMore,
                  isDark: isDark,
                  onTap: () => _pickFiles(context, FilePickerOption.file),
                  isCompact: isCompactHeight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_rounded,
                  label: t.sendTab.editList,
                  isDark: isDark,
                  onTap: () => _showFileList(context, vm),
                  isCompact: isCompactHeight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 移除文件
  ///
  /// 从选中列表中移除指定索引的文件
  void _removeFile(BuildContext context, int index) {
    context.ref.redux(selectedSendingFilesProvider).dispatch(RemoveSelectedFileAction(index));
  }

  /// 显示完整文件列表
  ///
  /// 跳转到文件列表编辑页面
  void _showFileList(BuildContext context, SendTabVm vm) {
    // ignore: discarded_futures
    context.push(() => const SelectedFilesPage());
  }

  /// 选择文件
  ///
  /// 根据指定的选项选择文件
  void _pickFiles(BuildContext context, FilePickerOption option) {
    // ignore: discarded_futures
    context.ref.global.dispatchAsync(
      PickFileAction(
        option: option,
        context: context,
      ),
    );
  }

  /// 构建热点提示
  Widget _buildHotspotTip(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryNarrow = constraints.maxWidth < 320;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: isVeryNarrow ? 16 : 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2418) : const Color(0xFFFDF8F3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF3D3220) : const Color(0xFFE8DDD0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_tethering_rounded,
                size: 16,
                color: LinkDropColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isVeryNarrow ? '开启热点后连接即可传输' : '没搜到设备？开启热点后连接即可传输',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 控制按钮组件
///
/// 用于显示操作按钮（扫描、手动输入、收藏、发送模式）
class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isRotating;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isRotating = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(_ControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRotating && !oldWidget.isRotating) {
      _controller.repeat();
    } else if (!widget.isRotating && oldWidget.isRotating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDark ? LinkDropColors.zinc800 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                ),
              ),
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.141592653589793,
                    child: Icon(widget.icon, size: 20, color: LinkDropColors.primary),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                color: LinkDropColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on SendMode {
  String get humanName {
    switch (this) {
      case SendMode.single:
        return t.sendTab.sendModes.single;
      case SendMode.multiple:
        return t.sendTab.sendModes.multiple;
      case SendMode.link:
        return t.sendTab.sendModes.link;
    }
  }
}

/// 文件缩略图卡片组件
///
/// 显示单个文件的缩略图和基本信息
class _FileThumbnailCard extends StatelessWidget {
  final CrossFile file;
  final bool isDark;
  final VoidCallback onTap;
  final double fileNameFontSize;

  const _FileThumbnailCard({
    required this.file,
    required this.isDark,
    required this.onTap,
    this.fileNameFontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Column(
          children: [
            // 缩略图区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SmartFileThumbnail.fromCrossFile(file),
              ),
            ),
            // 文件名
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fileNameFontSize,
                  color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 操作按钮组件
///
/// 用于显示添加更多、编辑列表等操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isCompact;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isCompact ? 10.0 : 12.0;
    final verticalPadding = isCompact ? 8.0 : 10.0;
    final iconSize = isCompact ? 14.0 : 16.0;
    final fontSize = isCompact ? 12.0 : 13.0;
    final spacing = isCompact ? 4.0 : 6.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: LinkDropColors.primary,
            ),
            SizedBox(width: spacing),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : LinkDropColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 发送模式按钮组件
///
/// 用于选择发送模式（单个接收者、多个接收者、通过链接分享）
class _SendModeButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final void Function(SendMode mode) onSelect;

  const _SendModeButton({
    required this.label,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: t.sendTab.sendMode,
      offset: const Offset(0, 40),
      onSelected: (mode) async {
        switch (mode) {
          case 0:
            onSelect(SendMode.single);
            break;
          case 1:
            onSelect(SendMode.multiple);
            break;
          case 2:
            onSelect(SendMode.link);
            break;
          case -1:
            await showDialog(context: context, builder: (_) => const SendModeHelpDialog());
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref) {
                  final sendMode = ref.watch(settingsProvider.select((s) => s.sendMode));
                  return Visibility(
                    visible: sendMode == SendMode.single,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Icon(Icons.check_circle, color: LinkDropColors.primary),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(t.sendTab.sendModes.single),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref) {
                  final sendMode = ref.watch(settingsProvider.select((s) => s.sendMode));
                  return Visibility(
                    visible: sendMode == SendMode.multiple,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Icon(Icons.check_circle, color: LinkDropColors.primary),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(t.sendTab.sendModes.multiple),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Icon(Icons.check_circle),
              ),
              const SizedBox(width: 10),
              Text(t.sendTab.sendModes.link),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: -1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(Icons.help),
              ),
              const SizedBox(width: 10),
              Text(t.sendTab.sendModeHelp),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc800 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                ),
              ),
              child: Icon(Icons.tune_rounded, size: 20, color: LinkDropColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: LinkDropColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 扇子展开动画文件选择器
///
/// 点击中央"+"按钮后，文件类型选项以扇子形状展开
class _FanFileSelector extends StatefulWidget {
  final bool isDark;
  final bool isCompact;
  final void Function(FilePickerOption option) onOptionSelected;

  const _FanFileSelector({
    required this.isDark,
    required this.isCompact,
    required this.onOptionSelected,
  });

  @override
  State<_FanFileSelector> createState() => _FanFileSelectorState();
}

class _FanFileSelectorState extends State<_FanFileSelector> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  // 文件选项配置 - 调整角度避免遮挡，更分散的扇形布局
  final List<_FanOption> _options = [
    _FanOption(
      icon: Icons.insert_drive_file_outlined,
      label: '文件',
      color: const Color(0xFF2DD4BF),
      angle: -80, // 左上方，更靠外避免遮挡
    ),
    _FanOption(
      icon: Icons.folder_outlined,
      label: '文件夹',
      color: const Color(0xFF8B5CF6),
      angle: -30, // 左中
    ),
    _FanOption(
      icon: Icons.text_fields,
      label: '文本',
      color: const Color(0xFF14B8A6),
      angle: 30, // 右中
    ),
    _FanOption(
      icon: Icons.content_paste,
      label: '剪贴板',
      color: const Color(0xFF7C3AED),
      angle: 80, // 右上方，更靠外避免遮挡
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _selectOption(_FanOption option) {
    // 根据选项类型创建对应的 FilePickerOption
    FilePickerOption? pickerOption;
    switch (option.label) {
      case '文件':
        pickerOption = FilePickerOption.file;
        break;
      case '文件夹':
        pickerOption = FilePickerOption.folder;
        break;
      case '文本':
        pickerOption = FilePickerOption.text;
        break;
      case '剪贴板':
        pickerOption = FilePickerOption.clipboard;
        break;
    }

    if (pickerOption != null) {
      widget.onOptionSelected(pickerOption);
    }

    // 收起扇子
    _toggleExpand();
  }

  @override
  Widget build(BuildContext context) {
    // 根据可用空间动态计算尺寸
    final availableHeight = MediaQuery.of(context).size.height;
    final isVeryCompact = availableHeight < 600;

    final centerButtonSize = widget.isCompact ? (isVeryCompact ? 56.0 : 64.0) : 96.0;
    final optionButtonSize = widget.isCompact ? (isVeryCompact ? 40.0 : 44.0) : 64.0;
    final fanRadius = widget.isCompact ? (isVeryCompact ? 70.0 : 85.0) : 140.0;
    final containerHeight = widget.isCompact ? (isVeryCompact ? 160.0 : 180.0) : 300.0;

    return Container(
      height: containerHeight,
      color: Colors.transparent, // 透明背景
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 扇子展开的选项按钮
          ...List.generate(_options.length, (index) {
            final option = _options[index];
            return AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // 计算扇形展开位置
                final angle = option.angle * (math.pi / 180) * _animation.value;
                final distance = fanRadius * _animation.value;
                final x = math.sin(angle) * distance;
                final y = -math.cos(angle) * distance * 0.5; // 稍微压扁，形成扇形

                // 使用 clamp 确保 opacity 在 0-1 范围内，避免 easeOutBack 曲线导致的越界
                final safeOpacity = _animation.value.clamp(0.0, 1.0);
                final safeScale = (0.5 + (0.5 * _animation.value)).clamp(0.0, 1.0);

                return Transform.translate(
                  offset: Offset(x, y),
                  child: Transform.scale(
                    scale: safeScale,
                    child: Opacity(
                      opacity: safeOpacity,
                      child: child,
                    ),
                  ),
                );
              },
              child: _FanOptionButton(
                icon: option.icon,
                label: option.label,
                color: option.color,
                size: optionButtonSize,
                isDark: widget.isDark,
                onTap: () => _selectOption(option),
              ),
            );
          }),

          // 中央"+"按钮
          GestureDetector(
            onTap: _toggleExpand,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: centerButtonSize,
              height: centerButtonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    LinkDropColors.primary,
                    LinkDropColors.primaryDark,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LinkDropColors.primary.withValues(alpha: 0.4),
                    blurRadius: _isExpanded ? 20 : 12,
                    spreadRadius: _isExpanded ? 4 : 2,
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _isExpanded ? 0.125 : 0, // 旋转45度变成X
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.add,
                  size: widget.isCompact ? 36 : 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 扇子选项数据类
class _FanOption {
  final IconData icon;
  final String label;
  final Color color;
  final double angle; // 角度（度）

  _FanOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.angle,
  });
}

/// 扇子选项按钮
class _FanOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final bool isDark;
  final VoidCallback onTap;

  const _FanOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark ? LinkDropColors.zinc800 : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: size * 0.4,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
