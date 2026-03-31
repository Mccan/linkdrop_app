import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/pages/receive_session_page.dart';
import 'package:linkdrop_app/provider/network/server/server_provider.dart';
import 'package:linkdrop_app/provider/selection/selected_receiving_files_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/file_size_helper.dart';
import 'package:linkdrop_app/util/file_type_ext.dart';
import 'package:linkdrop_app/util/native/pick_directory_path.dart';
import 'package:linkdrop_app/util/native/platform_check.dart';
import 'package:linkdrop_app/widget/dialogs/file_name_input_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// 接收选项页面
///
/// 显示接收文件的详细选项，包括保存目录、保存到相册设置、文件列表等
/// 采用现代卡片式设计，清晰的视觉层次和流畅的交互体验
class ReceiveOptionsPage extends StatelessWidget {
  final ReceivePageVm vm;

  const ReceiveOptionsPage(this.vm);

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final receiveSession = ref.watch(serverProvider.select((s) => s?.session));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (receiveSession == null) {
      return Scaffold(
        backgroundColor: isDark ? LinkDropColors.zinc900 : LinkDropColors.zinc50,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final selectState = ref.watch(selectedReceivingFilesProvider);
    final senderName = receiveSession.senderAlias ?? '未知设备';

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc900 : LinkDropColors.zinc50,
      body: Column(
        children: [
          // 顶部导航栏
          _buildAppBar(context, isDark),

          // 发送者信息卡片
          _buildSenderCard(context, senderName, isDark),

          // 保存设置区域
          _buildSaveSettingsCard(context, receiveSession, isDark, ref),

          // 文件列表标题
          _buildFilesHeader(context, isDark, selectState, ref),

          // 文件列表
          Expanded(
            child: _buildFilesList(context, selectState, isDark, ref),
          ),

          // 底部操作按钮
          _buildActionButtons(context, isDark, ref),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        16,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: isDark ? Colors.white : LinkDropColors.zinc700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '接收文件',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '确认接收设置',
                  style: TextStyle(
                    fontSize: 13,
                    color: LinkDropColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建发送者信息卡片
  Widget _buildSenderCard(BuildContext context, String senderName, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [LinkDropColors.zinc800, LinkDropColors.zinc900] : [Colors.white, const Color(0xFFF8F7F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LinkDropColors.primary.withOpacity(0.15),
                  LinkDropColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.smartphone,
              size: 28,
              color: LinkDropColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '想要发送文件给您',
                  style: TextStyle(
                    fontSize: 14,
                    color: LinkDropColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建保存设置卡片
  Widget _buildSaveSettingsCard(
    BuildContext context,
    dynamic receiveSession,
    bool isDark,
    Ref ref,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 保存目录
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 20,
                color: LinkDropColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '保存目录',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : LinkDropColors.zinc900,
                ),
              ),
              const Spacer(),
              if (checkPlatformWithFileSystem())
                InkWell(
                  onTap: () async {
                    final directory = await pickDirectoryPath();
                    if (directory != null) {
                      ref.notifier(serverProvider).setSessionDestinationDir(directory);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: LinkDropColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: LinkDropColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '修改',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: LinkDropColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? LinkDropColors.zinc900 : LinkDropColors.zinc50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 18,
                  color: LinkDropColors.zinc500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    checkPlatformWithFileSystem() ? receiveSession.destinationDirectory : t.receiveOptionsPage.appDirectory,
                    style: TextStyle(
                      fontSize: 13,
                      color: LinkDropColors.zinc600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 保存到相册开关
          if (checkPlatformWithGallery()) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 20,
                  color: LinkDropColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '保存到相册',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
                const Spacer(),
                _buildSwitch(
                  value: receiveSession.saveToGallery,
                  onChanged: (value) {
                    ref.notifier(serverProvider).setSessionSaveToGallery(value);
                  },
                ),
              ],
            ),
            if (receiveSession.containsDirectories && !receiveSession.saveToGallery)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 28),
                child: Text(
                  t.receiveOptionsPage.saveToGalleryOff,
                  style: TextStyle(
                    fontSize: 12,
                    color: LinkDropColors.zinc500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// 构建自定义开关
  Widget _buildSwitch({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          color: value ? LinkDropColors.primary : LinkDropColors.zinc400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建文件列表标题
  Widget _buildFilesHeader(
    BuildContext context,
    bool isDark,
    Map<String, String> selectState,
    Ref ref,
  ) {
    final selectedCount = selectState.length;
    final totalCount = vm.files.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LinkDropColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              size: 18,
              color: LinkDropColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '文件列表',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : LinkDropColors.zinc900,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: LinkDropColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$selectedCount/$totalCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LinkDropColors.primary,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => ref.notifier(selectedReceivingFilesProvider).setFiles(vm.files),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 14,
                    color: LinkDropColors.zinc500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '重置',
                    style: TextStyle(
                      fontSize: 12,
                      color: LinkDropColors.zinc500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文件列表
  Widget _buildFilesList(
    BuildContext context,
    Map<String, String> selectState,
    bool isDark,
    Ref ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: vm.files.length,
      itemBuilder: (context, index) {
        final file = vm.files[index];
        final isSelected = selectState.containsKey(file.id);
        final displayName = selectState[file.id] ?? file.fileName;
        final isRenamed = isSelected && selectState[file.id] != file.fileName;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? LinkDropColors.zinc800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? LinkDropColors.primary.withOpacity(0.3)
                  : isDark
                  ? LinkDropColors.zinc700
                  : LinkDropColors.zinc200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // 文件图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? LinkDropColors.primary.withOpacity(0.1)
                      : isDark
                      ? LinkDropColors.zinc700
                      : LinkDropColors.zinc100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  file.fileType.icon,
                  size: 22,
                  color: isSelected ? LinkDropColors.primary : LinkDropColors.zinc500,
                ),
              ),
              const SizedBox(width: 14),

              // 文件信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : LinkDropColors.zinc900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRenamed
                                ? Colors.orange.withOpacity(0.1)
                                : isSelected
                                ? LinkDropColors.primary.withOpacity(0.1)
                                : LinkDropColors.zinc200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            !isSelected
                                ? '已跳过'
                                : isRenamed
                                ? '已重命名'
                                : '未修改',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isRenamed
                                  ? Colors.orange
                                  : isSelected
                                  ? LinkDropColors.primary
                                  : LinkDropColors.zinc500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          file.size.asReadableFileSize,
                          style: TextStyle(
                            fontSize: 12,
                            color: LinkDropColors.zinc500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 编辑和选择按钮
              if (isSelected)
                InkWell(
                  onTap: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (_) => FileNameInputDialog(
                        originalName: file.fileName,
                        initialName: selectState[file.id]!,
                      ),
                    );
                    if (result != null) {
                      ref.notifier(selectedReceivingFilesProvider).rename(file.id, result);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: LinkDropColors.zinc500,
                    ),
                  ),
                ),

              // 复选框
              InkWell(
                onTap: () {
                  if (isSelected) {
                    ref.notifier(selectedReceivingFilesProvider).unselect(file.id);
                  } else {
                    ref.notifier(selectedReceivingFilesProvider).select(file);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? LinkDropColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? LinkDropColors.primary : LinkDropColors.zinc400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建底部操作按钮
  Widget _buildActionButtons(BuildContext context, bool isDark, Ref ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 拒绝按钮
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.white : LinkDropColors.zinc700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '拒绝',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : LinkDropColors.zinc700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 接受按钮
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(context).pop(true),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        LinkDropColors.primary,
                        LinkDropColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: LinkDropColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '接受',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
