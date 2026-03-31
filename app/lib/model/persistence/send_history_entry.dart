import 'package:common/model/file_type.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:intl/intl.dart';
import 'package:linkdrop_app/gen/strings.g.dart';

part 'send_history_entry.mapper.dart';

@MappableClass()
class SendHistoryEntry with SendHistoryEntryMappable {
  final String id;

  /// 文件名
  /// 如果 [isMessage] 为 true，这是消息内容
  final String fileName;

  final FileType fileType;

  /// 原文件路径
  final String? path;

  /// 是否为消息（文本/剪贴板）
  @MappableField(hook: IsMessageHook())
  final bool isMessage;

  final int fileSize;

  /// 接收者名称
  final String receiverAlias;

  /// 接收者 IP
  final String receiverIp;

  final DateTime timestamp;

  const SendHistoryEntry({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.path,
    required this.isMessage,
    required this.fileSize,
    required this.receiverAlias,
    required this.receiverIp,
    required this.timestamp,
  });

  /// 格式化时间戳
  String get timestampString {
    final localTimestamp = timestamp.toLocal();
    final languageTag = LocaleSettings.currentLocale.languageTag;
    return '${DateFormat.yMd(languageTag).format(localTimestamp)} ${DateFormat.jm(languageTag).format(localTimestamp)}';
  }

  static const fromJson = SendHistoryEntryMapper.fromJson;
}

class IsMessageHook extends MappingHook {
  const IsMessageHook();

  @override
  Object? beforeDecode(Object? value) {
    return value == true;
  }
}
