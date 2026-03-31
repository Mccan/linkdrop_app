import 'dart:io';
import 'dart:ui';

import 'package:common/model/file_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/model/persistence/receive_history_entry.dart';
import 'package:linkdrop_app/model/persistence/send_history_entry.dart';
import 'package:linkdrop_app/provider/receive_history_provider.dart';
import 'package:linkdrop_app/provider/send_history_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/file_size_helper.dart';
import 'package:linkdrop_app/util/file_type_ext.dart';
import 'package:linkdrop_app/util/native/open_file.dart';
import 'package:linkdrop_app/util/native/open_folder.dart';
import 'package:linkdrop_app/widget/dialogs/file_info_dialog.dart';
import 'package:linkdrop_app/widget/dialogs/history_clear_dialog.dart';
import 'package:linkdrop_app/widget/file_thumbnail.dart';
import 'package:path/path.dart' as path;
import 'package:refena_flutter/refena_flutter.dart';
import 'package:uri_content/uri_content.dart';

/// 历史记录页面
///
/// 显示发送和接收的历史记录，支持 Tab 切换
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.initialTab = 0});

  /// 初始 Tab 索引：0 = 接收页，1 = 发送页
  final int initialTab;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // 顶部标题栏
          Padding(
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '历史记录',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab 栏
          Container(
            margin: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            decoration: BoxDecoration(
              color: isDark ? LinkDropColors.zinc900 : LinkDropColors.zinc100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: LinkDropColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white70 : LinkDropColors.zinc600,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: '接收'),
                Tab(text: '发送'),
              ],
            ),
          ),

          // Tab 内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ReceiveHistoryList(),
                _SendHistoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 接收历史列表
class _ReceiveHistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch(receiveHistoryProvider);
    final settings = context.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGridView = settings.historyViewMode;

    return Column(
      children: [
        // 工具栏
        if (entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () async {
                    await context.ref.notifier(settingsProvider).setHistoryViewMode(!isGridView);
                  },
                  icon: Icon(
                    isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  ),
                  tooltip: isGridView ? '列表视图' : '宫格视图',
                  color: LinkDropColors.zinc500,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (_) => const HistoryClearDialog(),
                    );
                    if (result == true) {
                      await context.redux(receiveHistoryProvider).dispatchAsync(RemoveAllHistoryEntriesAction());
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: t.receiveHistoryPage.deleteHistory,
                  color: LinkDropColors.red500,
                ),
              ],
            ),
          ),

        // 列表内容
        Expanded(
          child: entries.isEmpty
              ? _EmptyState(isDark: isDark, icon: Icons.download_rounded, message: '暂无接收记录')
              : isGridView
              ? _ReceiveGridView(entries: entries, isDark: isDark)
              : _ReceiveListView(entries: entries, isDark: isDark),
        ),
      ],
    );
  }
}

/// 发送历史列表
class _SendHistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch(sendHistoryProvider);
    final settings = context.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGridView = settings.historyViewMode;

    return Column(
      children: [
        // 工具栏
        if (entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () async {
                    await context.ref.notifier(settingsProvider).setHistoryViewMode(!isGridView);
                  },
                  icon: Icon(
                    isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  ),
                  tooltip: isGridView ? '列表视图' : '宫格视图',
                  color: LinkDropColors.zinc500,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (_) => const HistoryClearDialog(),
                    );
                    if (result == true) {
                      await context.redux(sendHistoryProvider).dispatchAsync(RemoveAllSendHistoryEntriesAction());
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: '清空历史',
                  color: LinkDropColors.red500,
                ),
              ],
            ),
          ),

        // 列表内容
        Expanded(
          child: entries.isEmpty
              ? _EmptyState(isDark: isDark, icon: Icons.upload_rounded, message: '暂无发送记录')
              : isGridView
              ? _SendGridView(entries: entries, isDark: isDark)
              : _SendListView(entries: entries, isDark: isDark),
        ),
      ],
    );
  }
}

/// 空状态组件
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.isDark,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? Colors.white70 : LinkDropColors.zinc500,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : LinkDropColors.zinc500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 接收历史宫格视图
class _ReceiveGridView extends StatelessWidget {
  final List<ReceiveHistoryEntry> entries;
  final bool isDark;

  const _ReceiveGridView({required this.entries, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 根据屏幕宽度动态调整列数
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 360 ? 2 : (screenWidth < 600 ? 3 : 4);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9, // 调整宽高比，给文字更多空间
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _ReceiveGridCard(entry: entry, isDark: isDark);
      },
    );
  }
}

/// 接收历史列表视图
class _ReceiveListView extends StatelessWidget {
  final List<ReceiveHistoryEntry> entries;
  final bool isDark;

  const _ReceiveListView({required this.entries, required this.isDark});

  Future<void> _openFile(BuildContext context, ReceiveHistoryEntry entry) async {
    if (entry.isMessage) {
      await _showHistoryMessageDialog(
        context,
        message: entry.fileName,
        meta: '${entry.timestampString} - 来自 ${entry.senderAlias}',
      );
      return;
    }

    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => context.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _ReceiveListCard(
          entry: entry,
          isDark: isDark,
          onOpen: (entry.isMessage || entry.path != null) ? () => _openFile(context, entry) : null,
          onShowInFolder: entry.path != null
              ? () => openFolder(
                  folderPath: File(entry.path!).parent.path,
                  fileName: path.basename(entry.path!),
                )
              : null,
          onInfo: () => showDialog(
            context: context,
            builder: (_) => FileInfoDialog(entry: entry),
          ),
          onDelete: () => context.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id)),
        );
      },
    );
  }
}

/// 发送历史宫格视图
class _SendGridView extends StatelessWidget {
  final List<SendHistoryEntry> entries;
  final bool isDark;

  const _SendGridView({required this.entries, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 根据屏幕宽度动态调整列数
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 360 ? 2 : (screenWidth < 600 ? 3 : 4);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9, // 调整宽高比，给文字更多空间
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _SendGridCard(entry: entry, isDark: isDark);
      },
    );
  }
}

/// 发送历史列表视图
class _SendListView extends StatelessWidget {
  final List<SendHistoryEntry> entries;
  final bool isDark;

  const _SendListView({required this.entries, required this.isDark});

  Future<void> _openFile(BuildContext context, SendHistoryEntry entry) async {
    if (entry.isMessage) {
      await _showHistoryMessageDialog(
        context,
        message: entry.fileName,
        meta: '${entry.timestampString} - 发送给 ${entry.receiverAlias}',
      );
    } else if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => context.redux(sendHistoryProvider).dispatchAsync(RemoveSendHistoryEntryAction(entry.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _SendListCard(
          entry: entry,
          isDark: isDark,
          onOpen: () => _openFile(context, entry),
          onDelete: () => context.redux(sendHistoryProvider).dispatchAsync(RemoveSendHistoryEntryAction(entry.id)),
        );
      },
    );
  }
}

/// 接收历史宫格卡片
class _ReceiveGridCard extends StatelessWidget {
  final ReceiveHistoryEntry entry;
  final bool isDark;

  const _ReceiveGridCard({required this.entry, required this.isDark});

  Future<void> _openFile(BuildContext context) async {
    if (entry.isMessage) {
      await _showHistoryMessageDialog(
        context,
        message: entry.fileName,
        meta: '${entry.timestampString} - 来自 ${entry.senderAlias}',
      );
      return;
    }

    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => context.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc900 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: _GridFileThumbnail(path: entry.path, fileType: entry.fileType),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.fileName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.fileSize.asReadableFileSize,
                    style: TextStyle(fontSize: 11, color: LinkDropColors.zinc500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 宫格视图专用文件缩略图 - 填充整个可用空间
class _GridFileThumbnail extends StatelessWidget {
  final String? path;
  final FileType fileType;

  const _GridFileThumbnail({required this.path, required this.fileType});

  @override
  Widget build(BuildContext context) {
    if (path != null && fileType == FileType.image) {
      // 图片类型：填充整个容器
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[100],
          child: path!.startsWith('content://')
              ? Image(
                  image: ResizeImage.resizeIfNeeded(
                    300,
                    300,
                    _ContentUriImage(Uri.parse(path!)),
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(fileType.icon, size: 40, color: Colors.grey[400]),
                  ),
                )
              : Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  cacheHeight: 300,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(fileType.icon, size: 40, color: Colors.grey[400]),
                  ),
                ),
        ),
      );
    } else {
      // 非图片类型：显示大图标
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            fileType.icon,
            size: 48,
            color: LinkDropColors.primary,
          ),
        ),
      );
    }
  }
}

/// Content URI 图片提供器
class _ContentUriImage extends ImageProvider<Uri> {
  final Uri uri;

  _ContentUriImage(this.uri);

  @override
  Future<Uri> obtainKey(ImageConfiguration configuration) async => uri;

  @override
  ImageStreamCompleter loadImage(Uri key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<Codec> _loadAsync(Uri key, ImageDecoderCallback decode) async {
    final uriContent = UriContent();
    final bytes = await uriContent.from(key);
    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }
}

/// 接收历史列表卡片
class _ReceiveListCard extends StatelessWidget {
  final ReceiveHistoryEntry entry;
  final bool isDark;
  final VoidCallback? onOpen;
  final VoidCallback? onShowInFolder;
  final VoidCallback? onInfo;
  final VoidCallback onDelete;

  const _ReceiveListCard({
    required this.entry,
    required this.isDark,
    this.onOpen,
    this.onShowInFolder,
    this.onInfo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilePathThumbnail(path: entry.path, fileType: entry.fileType),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.fileName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.timestampString} - ${entry.fileSize.asReadableFileSize} - 来自 ${entry.senderAlias}',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(fontSize: 13, color: LinkDropColors.zinc500),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_EntryOption>(
              onSelected: (_EntryOption item) {
                switch (item) {
                  case _EntryOption.open:
                    onOpen?.call();
                    break;
                  case _EntryOption.showInFolder:
                    onShowInFolder?.call();
                    break;
                  case _EntryOption.info:
                    onInfo?.call();
                    break;
                  case _EntryOption.delete:
                    onDelete.call();
                    break;
                }
              },
              icon: Icon(Icons.more_vert_rounded, color: LinkDropColors.zinc500),
              itemBuilder: (context) {
                final options = entry.path != null ? _EntryOption.values : [_EntryOption.info, _EntryOption.delete];
                return options.map((e) {
                  return PopupMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Icon(e.icon, size: 20, color: e == _EntryOption.delete ? LinkDropColors.red500 : null),
                        const SizedBox(width: 12),
                        Text(e.labelReceive),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 发送历史宫格卡片
class _SendGridCard extends StatelessWidget {
  final SendHistoryEntry entry;
  final bool isDark;

  const _SendGridCard({required this.entry, required this.isDark});

  Future<void> _openFile(BuildContext context) async {
    if (entry.isMessage) {
      await _showHistoryMessageDialog(
        context,
        message: entry.fileName,
        meta: '${entry.timestampString} - 发送给 ${entry.receiverAlias}',
      );
      return;
    }

    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc900 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: entry.isMessage
                      ? _MessagePreview(fileName: entry.fileName, isDark: isDark)
                      : _GridFileThumbnail(path: entry.path, fileType: entry.fileType),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.isMessage ? '文本消息' : entry.fileName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.isMessage ? '发送给 ${entry.receiverAlias}' : entry.fileSize.asReadableFileSize,
                    style: TextStyle(fontSize: 11, color: LinkDropColors.zinc500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 消息预览组件
class _MessagePreview extends StatelessWidget {
  final String fileName;
  final bool isDark;

  const _MessagePreview({required this.fileName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Text(
          fileName,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : LinkDropColors.zinc700,
          ),
          maxLines: 8,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// 消息列表图标组件
class _MessageListIcon extends StatelessWidget {
  final bool isDark;

  const _MessageListIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.subject_rounded,
        size: 28,
        color: LinkDropColors.primary,
      ),
    );
  }
}

/// 发送历史列表卡片
class _SendListCard extends StatelessWidget {
  final SendHistoryEntry entry;
  final bool isDark;
  final VoidCallback? onOpen;
  final VoidCallback onDelete;

  const _SendListCard({
    required this.entry,
    required this.isDark,
    this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            entry.isMessage ? _MessageListIcon(isDark: isDark) : FilePathThumbnail(path: entry.path, fileType: entry.fileType),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.isMessage ? '文本消息' : entry.fileName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.isMessage
                        ? '${entry.timestampString} - 发送给 ${entry.receiverAlias}'
                        : '${entry.timestampString} - ${entry.fileSize.asReadableFileSize} - 发送给 ${entry.receiverAlias}',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(fontSize: 13, color: LinkDropColors.zinc500),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_EntryOption>(
              onSelected: (_EntryOption item) {
                if (item == _EntryOption.delete) {
                  onDelete.call();
                }
              },
              icon: Icon(Icons.more_vert_rounded, color: LinkDropColors.zinc500),
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: _EntryOption.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: LinkDropColors.red500),
                        const SizedBox(width: 12),
                        const Text('删除记录'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showHistoryMessageDialog(
  BuildContext context, {
  required String message,
  String? meta,
}) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('文本消息'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meta != null) ...[
              Text(
                meta,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SelectableText(message),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: message));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制文本消息')),
              );
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('复制'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

enum _EntryOption {
  open,
  showInFolder,
  info,
  delete;

  String get labelReceive {
    return switch (this) {
      _EntryOption.open => t.receiveHistoryPage.entryActions.open,
      _EntryOption.showInFolder => t.receiveHistoryPage.entryActions.showInFolder,
      _EntryOption.info => t.receiveHistoryPage.entryActions.info,
      _EntryOption.delete => t.receiveHistoryPage.entryActions.deleteFromHistory,
    };
  }

  IconData get icon {
    return switch (this) {
      _EntryOption.open => Icons.open_in_new_rounded,
      _EntryOption.showInFolder => Icons.folder_open_rounded,
      _EntryOption.info => Icons.info_outline_rounded,
      _EntryOption.delete => Icons.delete_outline_rounded,
    };
  }
}
