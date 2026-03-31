import 'dart:async';

import 'package:common/model/dto/file_dto.dart';
import 'package:common/model/file_status.dart';
import 'package:common/model/file_type.dart';
import 'package:common/model/session_status.dart';
import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/model/state/server/receive_session_state.dart';
import 'package:linkdrop_app/pages/home_page.dart';
import 'package:linkdrop_app/pages/home_page_controller.dart';
import 'package:linkdrop_app/provider/network/send_provider.dart';
import 'package:linkdrop_app/provider/network/server/server_provider.dart';
import 'package:linkdrop_app/provider/progress_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/file_size_helper.dart';
import 'package:linkdrop_app/util/native/open_folder.dart';
import 'package:linkdrop_app/widget/custom_progress_bar.dart';
import 'package:linkdrop_app/widget/transfer_animation_widget.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class ProgressPage extends StatefulWidget {
  final bool showAppBar;
  final bool closeSessionOnClose;
  final String sessionId;

  const ProgressPage({
    this.showAppBar = true,
    this.closeSessionOnClose = true,
    required this.sessionId,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with Refena {
  int _finishCounter = 3;
  Timer? _finishTimer;
  bool _advanced = false;

  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBytesTotal();
    });
  }

  void _initBytesTotal() {
    final serverState = ref.read(serverProvider);
    final sendSession = ref.read(sendProvider)[widget.sessionId];
    final receiveSession = serverState?.session;

    if (receiveSession != null && receiveSession.sessionId == widget.sessionId) {
      setState(() {
        _totalBytes = receiveSession.files.values.fold(
          0,
          (prev, curr) => prev + curr.file.size,
        );
      });
    } else if (sendSession != null) {
      setState(() {
        _totalBytes = sendSession.files.values.fold(
          0,
          (prev, curr) => prev + curr.file.size,
        );
      });
    }
  }

  /// 启动完成倒计时
  ///
  /// 【参数说明】
  /// - seconds: 倒计时秒数，默认3秒
  ///   - 正常完成/失败：3秒
  ///   - 取消/拒绝：1秒（快速返回）
  ///
  /// 【注意事项】
  /// - 倒计时结束时调用 _exit(closeSession: true) 关闭 session 并返回首页
  /// - _finishCounter 初始值由 seconds 参数设置，每次 tick 减1
  ///
  /// 【修改记录】
  /// - 2026-03-30：添加 seconds 参数，支持不同状态的倒计时时长
  void _startFinishTimer({int seconds = 3}) {
    _finishTimer?.cancel();
    _finishCounter = seconds;
    _finishTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_finishCounter <= 1) {
        _exit(closeSession: true);
      } else {
        setState(() {
          _finishCounter--;
        });
      }
    });
  }

  /// 退出传输页面
  ///
  /// 【关键实现说明 - BugID: TAB_SYNC_001 / CANCEL_SYNC_002 / WHITE_SCREEN_001】
  ///
  /// 问题描述：
  /// 当传输完成或取消时，需要返回到首页。但之前的实现使用 pushAndRemoveUntil 创建新的
  /// LinkDropHomePage，导致全局的 homePageControllerProvider（PageController）状态不同步，
  /// 表现为 tabbar 选中【发送】但页面显示【接收】。
  ///
  /// 原因分析：
  /// - homePageControllerProvider 是全局单例，PageController 被创建后不会重新创建
  /// - PageController 的 initialPage 在创建时设置，之后不会改变
  /// - pushAndRemoveUntil 会创建新的 LinkDropHomePage，但其 initState 中的 setInitialPage
  ///   由于 ensureRef 异步执行，可能在 build 之前没有生效
  ///
  /// 解决方案：
  /// 1. 使用 Routerino.context.popUntilRoot() 回到已有的首页（不创建新页面）
  /// 2. 直接 dispatch ChangeTabAction 切换 tab（利用已有的 PageController）
  /// 3. 对发送端等待/传输中状态使用 cancelSession（需要通知接收端），不能只 closeSession
  /// 4. 保留导航兜底：如果 popUntilRoot 后页面仍 mounted，强制重建首页栈以避免白屏
  ///
  /// 【修改记录】
  /// - 2026-03-30：修复传输完成/取消后返回首页时 tabbar 与页面不同步的问题
  /// - 2026-03-30：修复发送端在传输页取消时未同步关闭接收端的问题
  /// - 2026-03-30：修复文件传输完成倒计时后发送端/接收端偶发白屏问题
  ///
  /// 【维护警告】
  /// 该方法同时承担“会话关闭 + 跨端同步 + 导航返回”三类职责。
  /// 若后续改动这里，请至少手工回归以下场景：
  /// - 发送端点取消（接收端等待页应同步关闭）
  /// - 接收端点拒绝（发送端应同步结束）
  /// - 文件传输完成倒计时自动返回（双方不白屏）
  /// - 文本消息发送完成自动返回（发送端回发送页）
  void _exit({bool? closeSession}) {
    _finishTimer?.cancel();

    // 先判断是否是接收端（在关闭 session 之前），避免 session 被移除后无法判断
    final serverState = ref.read(serverProvider);
    final sendSession = ref.read(sendProvider)[widget.sessionId];
    final receiveSession = serverState?.session;
    final isReceiver = receiveSession != null && receiveSession.sessionId == widget.sessionId;

    final shouldClose = closeSession ?? widget.closeSessionOnClose;
    if (shouldClose) {
      // 保存 isReceiver 的值，因为在关闭 session 后仍然需要用到
      final shouldReturnToReceive = isReceiver;
      if (receiveSession != null && receiveSession.sessionId == widget.sessionId) {
        ref.notifier(serverProvider).closeSession();
      } else if (sendSession != null) {
        final status = sendSession.status;
        final shouldNotifyReceiver = status == SessionStatus.waiting || status == SessionStatus.sending;

        // Guardrail: sender-side cancel must notify receiver during active/waiting session,
        // otherwise receiver can be stuck on the accept/decline page.
        // Do NOT replace this with closeSession for waiting/sending.
        if (shouldNotifyReceiver) {
          ref.notifier(sendProvider).cancelSession(widget.sessionId);
        } else {
          ref.notifier(sendProvider).closeSession(widget.sessionId);
        }
      }
      // 使用保存的值，而不是在 session 关闭后重新读取
      final targetTab = shouldReturnToReceive ? HomeTab.receive : HomeTab.send;

      // 先同步目标 tab，再尝试回到已有首页。
      // Guardrail: some navigation stacks may not pop back correctly after async auto-finish,
      // which can leave this page mounted and render as a blank screen.
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(targetTab, animate: false));

      // 返回到主页，优先使用 popUntilRoot 回到已有的首页（避免 PageController 问题）
      if (context.mounted) {
        Routerino.context.popUntilRoot();
      }

      // Fallback: if this page is still mounted, force-reset navigation stack to home.
      // This fallback is intentional. Removing it may re-introduce WHITE_SCREEN_001.
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LinkDropHomePage(initialTab: targetTab, appStart: false),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressNotifier = ref.watch(progressProvider);
    final serverState = ref.watch(serverProvider);
    final sendSession = ref.watch(sendProvider.select((state) => state[widget.sessionId]));
    final receiveSession = serverState?.session?.sessionId == widget.sessionId ? serverState?.session : null;

    final SessionStatus status;
    final List<FileDto> files;
    final int finishedCount;

    if (receiveSession != null) {
      status = receiveSession.status;
      files = receiveSession.files.values.map((f) => f.file).toList();
      finishedCount = receiveSession.files.values.where((f) => f.status == FileStatus.finished).length;
    } else if (sendSession != null) {
      status = sendSession.status;
      files = sendSession.files.values.map((f) => f.file).toList();
      finishedCount = sendSession.files.values.where((f) => f.status == FileStatus.finished).length;
    } else {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 计算当前进度（基于 progressProvider）
    double totalProgress = 0;
    int receivedBytes = 0;
    for (final file in files) {
      final fileProgress = progressNotifier.getProgress(sessionId: widget.sessionId, fileId: file.id);
      totalProgress += fileProgress;
      receivedBytes += (file.size * fileProgress).round();
    }

    final isReceiver = receiveSession != null;
    // 判断是否为纯文本消息
    final isTextMessage = files.length == 1 && files.first.fileType == FileType.text && files.first.preview != null;

    // 对于文本消息，发送端在 sending 状态时就视为已完成（因为文本已经随请求发送）
    final isTextMessageFinished = isTextMessage && !isReceiver && (status == SessionStatus.sending || status == SessionStatus.finished);

    /// 【关键修改 - BugID: FINISH_STATUS_001】
    /// isFinished 用于判断传输是否处于终止状态，包括：
    /// - finished：传输成功完成
    /// - finishedWithErrors：传输完成但有错误
    /// - canceledBySender：发送端取消
    /// - canceledByReceiver：接收端取消
    /// - declined：接收端拒绝
    /// - isTextMessageFinished：文本消息在发送端眼中已完成（文本已发送）
    ///
    /// 【修改记录】
    /// - 2026-03-30：添加取消和拒绝状态的判断，确保这些状态下也能显示"完成"按钮并倒计时返回
    final isFinished =
        status == SessionStatus.finished ||
        status == SessionStatus.finishedWithErrors ||
        status == SessionStatus.canceledBySender ||
        status == SessionStatus.canceledByReceiver ||
        status == SessionStatus.declined ||
        isTextMessageFinished;

    // 传输完成时启动计时器（包括文本消息完成的情况）
    // 拒绝/取消状态倒计时1.5秒，其他状态倒计时3秒
    // 【修改记录】
    // - 2026-03-30：拒绝/取消状态快速倒计时返回，提升用户体验
    if (isFinished && _finishTimer == null) {
      final isQuickFinish =
          status == SessionStatus.declined || status == SessionStatus.canceledBySender || status == SessionStatus.canceledByReceiver;
      _startFinishTimer(seconds: isQuickFinish ? 1 : 3);
    }

    // 对于文本消息，如果是发送端且状态为 sending 或 finished，直接显示 100%
    final progress = isTextMessageFinished ? 1.0 : (files.isEmpty ? 0.0 : totalProgress / files.length);

    // 获取设备别名 - 与扫描列表保持一致
    // 接收端使用 senderAlias（可能已被收藏夹覆盖），发送端使用 target.alias
    final senderDisplayName = isReceiver ? receiveSession.senderAlias : '本机';
    final receiverDisplayName = isReceiver ? '本机' : (sendSession?.target.alias ?? '目标设备');

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(isReceiver ? t.progressPage.titleReceiving : t.progressPage.titleSending),
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 动画卡片垂直居中
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TransferAnimationWidget(
                        senderName: senderDisplayName,
                        receiverName: receiverDisplayName,
                        isSending: status == SessionStatus.sending && !isTextMessageFinished,
                        progress: progress,
                        isFinished: isFinished,
                        isReceiver: isReceiver,
                        isWaiting: status == SessionStatus.waiting && !isTextMessage,
                      ),
                      // 等待状态提示（仅对文件传输显示，文本消息不显示）
                      if (status == SessionStatus.waiting && !isTextMessage) ...[
                        const SizedBox(height: 24),
                        _buildWaitingTip(context),
                      ],
                    ],
                  ),
                ),
              ),

              // 卡片2：总进度卡片在底部
              _buildProgressCard(
                context: context,
                status: status,
                receivedBytes: isTextMessageFinished ? files.first.size : receivedBytes,
                totalBytes: isTextMessageFinished ? files.first.size : _totalBytes,
                progress: progress,
                finishedCount: isTextMessageFinished ? 1 : finishedCount,
                totalCount: files.length,
                isAdvanced: _advanced,
                onToggleAdvanced: () {
                  setState(() {
                    _advanced = !_advanced;
                  });
                },
                onCancel: () => _exit(closeSession: true),
                isFinished: isFinished,
                finishCounter: _finishCounter,
                isTextMessage: isTextMessage,
              ),

              const SizedBox(height: 12),

              // 底部操作按钮
              _buildActionButtons(
                context: context,
                status: status,
                isReceiver: isReceiver,
                receiveSession: receiveSession,
                onOpenFolder: () async {
                  if (receiveSession?.destinationDirectory != null) {
                    await openFolder(folderPath: receiveSession!.destinationDirectory);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建总进度卡片
  Widget _buildProgressCard({
    required BuildContext context,
    required SessionStatus status,
    required int receivedBytes,
    required int totalBytes,
    required double progress,
    required int finishedCount,
    required int totalCount,
    required bool isAdvanced,
    required VoidCallback onToggleAdvanced,
    required VoidCallback onCancel,
    required bool isFinished,
    required int finishCounter,
    required bool isTextMessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 状态标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getStatusLabel(status, isTextMessage: isTextMessage),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : LinkDropColors.textPrimary,
                  ),
                ),
              ),
              if (isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.general.finished,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // 进度条
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return CustomProgressBar(
                progress: value,
                borderRadius: 8,
                isWaiting: status == SessionStatus.waiting,
              );
            },
          ),

          const SizedBox(height: 12),

          // 进度百分比
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : LinkDropColors.textPrimary,
                ),
              ),
              Text(
                '${receivedBytes.asReadableFileSize} / ${totalBytes == 0 ? '-' : totalBytes.asReadableFileSize}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : LinkDropColors.textSecondary,
                ),
              ),
            ],
          ),

          // 高级信息（可展开）
          AnimatedCrossFade(
            crossFadeState: isAdvanced ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? LinkDropColors.zinc900 : LinkDropColors.zinc100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.insert_drive_file,
                      label: t.progressPage.total.count(curr: finishedCount, n: totalCount),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.storage,
                      label: t.progressPage.total.size(
                        curr: receivedBytes.asReadableFileSize,
                        n: totalBytes == 0 ? '-' : totalBytes.asReadableFileSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 操作按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onToggleAdvanced,
                icon: Icon(
                  isAdvanced ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(isAdvanced ? t.general.hide : t.general.advanced),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white60 : LinkDropColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              FilledButton.icon(
                onPressed: onCancel,
                icon: Icon(isFinished ? Icons.check : Icons.close),
                label: Text(
                  isFinished ? '${t.general.done} (${finishCounter}s)' : t.general.cancel,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isFinished ? const Color(0xFF10B981) : Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow({required IconData icon, required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white38 : LinkDropColors.textTertiary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建底部操作按钮
  Widget _buildActionButtons({
    required BuildContext context,
    required SessionStatus status,
    required bool isReceiver,
    required ReceiveSessionState? receiveSession,
    required VoidCallback onOpenFolder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 只有在接收完成且不是保存到相册的情况下才显示打开文件夹按钮
    final showOpenFolder =
        isReceiver &&
        (status == SessionStatus.finished || status == SessionStatus.finishedWithErrors) &&
        receiveSession?.destinationDirectory != null;

    if (!showOpenFolder) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.progressPage.savedToGallery,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : LinkDropColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenFolder,
            icon: const Icon(Icons.folder_open),
            label: Text(t.general.open),
            style: FilledButton.styleFrom(
              backgroundColor: LinkDropColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取状态标签
  String _getStatusLabel(SessionStatus status, {bool isTextMessage = false}) {
    switch (status) {
      case SessionStatus.waiting:
        return t.sendPage.waiting;
      case SessionStatus.sending:
        // 文本消息显示"已发送"，文件传输显示"发送中"
        return isTextMessage ? '已发送' : t.progressPage.total.title.sending(time: '-');
      case SessionStatus.finished:
        return t.general.finished;
      case SessionStatus.finishedWithErrors:
        return t.progressPage.total.title.finishedError;
      case SessionStatus.canceledBySender:
        return t.progressPage.total.title.canceledSender;
      case SessionStatus.canceledByReceiver:
        return t.progressPage.total.title.canceledReceiver;
      case SessionStatus.declined:
        return '对方已拒绝';
      case SessionStatus.recipientBusy:
        return '对方设备正忙';
      case SessionStatus.tooManyAttempts:
        return 'PIN 尝试次数过多';
      default:
        return '';
    }
  }

  /// 构建等待状态提示卡片
  Widget _buildWaitingTip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.primary.withOpacity(0.15) : LinkDropColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? LinkDropColors.primary.withOpacity(0.3) : LinkDropColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: LinkDropColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              '对方设备未开启自动接收，\n需要手动确认后才能开始传输',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
