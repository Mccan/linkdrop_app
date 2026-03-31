import 'package:common/model/file_type.dart';
import 'package:linkdrop_app/model/persistence/send_history_entry.dart';
import 'package:linkdrop_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

const _maxHistoryEntries = 30;

/// 发送历史记录提供者
///
/// 存储已发送文件的历史记录，自动持久化到本地存储
final sendHistoryProvider = ReduxProvider<SendHistoryService, List<SendHistoryEntry>>((ref) {
  return SendHistoryService(ref.read(persistenceProvider));
});

class SendHistoryService extends ReduxNotifier<List<SendHistoryEntry>> {
  final PersistenceService _persistence;

  SendHistoryService(this._persistence);

  @override
  List<SendHistoryEntry> init() => _persistence.getSendHistory();
}

/// 添加发送历史记录
class AddSendHistoryEntryAction extends AsyncReduxAction<SendHistoryService, List<SendHistoryEntry>> {
  final String entryId;
  final String fileName;
  final FileType fileType;
  final String? path;
  final bool isMessage;
  final int fileSize;
  final String receiverAlias;
  final String receiverIp;
  final DateTime timestamp;

  AddSendHistoryEntryAction({
    required this.entryId,
    required this.fileName,
    required this.fileType,
    required this.path,
    required this.isMessage,
    required this.fileSize,
    required this.receiverAlias,
    required this.receiverIp,
    required this.timestamp,
  });

  @override
  Future<List<SendHistoryEntry>> reduce() async {
    if (!notifier._persistence.isSaveToHistory()) {
      return state;
    }

    final updated = [
      SendHistoryEntry(
        id: entryId,
        fileName: fileName,
        fileType: fileType,
        path: path,
        isMessage: isMessage,
        fileSize: fileSize,
        receiverAlias: receiverAlias,
        receiverIp: receiverIp,
        timestamp: timestamp,
      ),
      ...state,
    ].take(_maxHistoryEntries).toList();
    await notifier._persistence.setSendHistory(updated);
    return updated;
  }
}

/// 删除单条发送历史记录
class RemoveSendHistoryEntryAction extends AsyncReduxAction<SendHistoryService, List<SendHistoryEntry>> {
  final String entryId;

  RemoveSendHistoryEntryAction(this.entryId);

  @override
  Future<List<SendHistoryEntry>> reduce() async {
    final index = state.indexWhere((e) => e.id == entryId);
    if (index == -1) {
      return state;
    }
    final updated = [...state]..removeAt(index);
    await notifier._persistence.setSendHistory(updated);
    return updated;
  }
}

/// 清空所有发送历史记录
class RemoveAllSendHistoryEntriesAction extends AsyncReduxAction<SendHistoryService, List<SendHistoryEntry>> {
  @override
  Future<List<SendHistoryEntry>> reduce() async {
    await notifier._persistence.setSendHistory([]);
    return [];
  }
}