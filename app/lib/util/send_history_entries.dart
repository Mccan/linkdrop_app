import 'dart:convert';

import 'package:common/model/file_status.dart';
import 'package:linkdrop_app/model/persistence/send_history_entry.dart';
import 'package:linkdrop_app/model/state/send/send_session_state.dart';
import 'package:linkdrop_app/model/state/send/sending_file.dart';

List<SendHistoryEntry> buildSendHistoryEntries({
  required SendSessionState sessionState,
  required DateTime timestamp,
  required String receiverAlias,
  required String Function(SendingFile file) entryIdBuilder,
  bool allowDeliveredMessagesWithoutUpload = false,
}) {
  final receiverIp = sessionState.target.ip ?? 'unknown';

  return sessionState.files.values
      .where(
        (file) => file.status == FileStatus.finished || (allowDeliveredMessagesWithoutUpload && file.isMessage),
      )
      .map(
        (file) => SendHistoryEntry(
          id: entryIdBuilder(file),
          fileName: _resolveHistoryFileName(file),
          fileType: file.file.fileType,
          path: file.path,
          isMessage: file.isMessage,
          fileSize: file.file.size,
          receiverAlias: receiverAlias,
          receiverIp: receiverIp,
          timestamp: timestamp,
        ),
      )
      .toList(growable: false);
}

String _resolveHistoryFileName(SendingFile file) {
  if (!file.isMessage) {
    return file.file.fileName;
  }

  final preview = file.file.preview;
  if (preview != null && preview.isNotEmpty) {
    return preview;
  }

  final bytes = file.bytes;
  if (bytes != null && bytes.isNotEmpty) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  return file.file.fileName;
}