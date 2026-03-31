// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'send_history_entry.dart';

class SendHistoryEntryMapper extends ClassMapperBase<SendHistoryEntry> {
  SendHistoryEntryMapper._();

  static SendHistoryEntryMapper? _instance;
  static SendHistoryEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SendHistoryEntryMapper._());
      FileTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SendHistoryEntry';

  static String _$id(SendHistoryEntry v) => v.id;
  static const Field<SendHistoryEntry, String> _f$id = Field('id', _$id);
  static String _$fileName(SendHistoryEntry v) => v.fileName;
  static const Field<SendHistoryEntry, String> _f$fileName = Field(
    'fileName',
    _$fileName,
  );
  static FileType _$fileType(SendHistoryEntry v) => v.fileType;
  static const Field<SendHistoryEntry, FileType> _f$fileType = Field(
    'fileType',
    _$fileType,
  );
  static String? _$path(SendHistoryEntry v) => v.path;
  static const Field<SendHistoryEntry, String> _f$path = Field('path', _$path);
  static bool _$isMessage(SendHistoryEntry v) => v.isMessage;
  static const Field<SendHistoryEntry, bool> _f$isMessage = Field(
    'isMessage',
    _$isMessage,
    hook: IsMessageHook(),
  );
  static int _$fileSize(SendHistoryEntry v) => v.fileSize;
  static const Field<SendHistoryEntry, int> _f$fileSize = Field(
    'fileSize',
    _$fileSize,
  );
  static String _$receiverAlias(SendHistoryEntry v) => v.receiverAlias;
  static const Field<SendHistoryEntry, String> _f$receiverAlias = Field(
    'receiverAlias',
    _$receiverAlias,
  );
  static String _$receiverIp(SendHistoryEntry v) => v.receiverIp;
  static const Field<SendHistoryEntry, String> _f$receiverIp = Field(
    'receiverIp',
    _$receiverIp,
  );
  static DateTime _$timestamp(SendHistoryEntry v) => v.timestamp;
  static const Field<SendHistoryEntry, DateTime> _f$timestamp = Field(
    'timestamp',
    _$timestamp,
  );
  static String _$timestampString(SendHistoryEntry v) => v.timestampString;
  static const Field<SendHistoryEntry, String> _f$timestampString = Field(
    'timestampString',
    _$timestampString,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<SendHistoryEntry> fields = const {
    #id: _f$id,
    #fileName: _f$fileName,
    #fileType: _f$fileType,
    #path: _f$path,
    #isMessage: _f$isMessage,
    #fileSize: _f$fileSize,
    #receiverAlias: _f$receiverAlias,
    #receiverIp: _f$receiverIp,
    #timestamp: _f$timestamp,
    #timestampString: _f$timestampString,
  };

  static SendHistoryEntry _instantiate(DecodingData data) {
    return SendHistoryEntry(
      id: data.dec(_f$id),
      fileName: data.dec(_f$fileName),
      fileType: data.dec(_f$fileType),
      path: data.dec(_f$path),
      isMessage: data.dec(_f$isMessage),
      fileSize: data.dec(_f$fileSize),
      receiverAlias: data.dec(_f$receiverAlias),
      receiverIp: data.dec(_f$receiverIp),
      timestamp: data.dec(_f$timestamp),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SendHistoryEntry fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SendHistoryEntry>(map);
  }

  static SendHistoryEntry deserialize(String json) {
    return ensureInitialized().decodeJson<SendHistoryEntry>(json);
  }
}

mixin SendHistoryEntryMappable {
  String serialize() {
    return SendHistoryEntryMapper.ensureInitialized()
        .encodeJson<SendHistoryEntry>(this as SendHistoryEntry);
  }

  Map<String, dynamic> toJson() {
    return SendHistoryEntryMapper.ensureInitialized()
        .encodeMap<SendHistoryEntry>(this as SendHistoryEntry);
  }

  SendHistoryEntryCopyWith<SendHistoryEntry, SendHistoryEntry, SendHistoryEntry>
  get copyWith =>
      _SendHistoryEntryCopyWithImpl<SendHistoryEntry, SendHistoryEntry>(
        this as SendHistoryEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SendHistoryEntryMapper.ensureInitialized().stringifyValue(
      this as SendHistoryEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return SendHistoryEntryMapper.ensureInitialized().equalsValue(
      this as SendHistoryEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return SendHistoryEntryMapper.ensureInitialized().hashValue(
      this as SendHistoryEntry,
    );
  }
}

extension SendHistoryEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SendHistoryEntry, $Out> {
  SendHistoryEntryCopyWith<$R, SendHistoryEntry, $Out>
  get $asSendHistoryEntry =>
      $base.as((v, t, t2) => _SendHistoryEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SendHistoryEntryCopyWith<$R, $In extends SendHistoryEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? fileName,
    FileType? fileType,
    String? path,
    bool? isMessage,
    int? fileSize,
    String? receiverAlias,
    String? receiverIp,
    DateTime? timestamp,
  });
  SendHistoryEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SendHistoryEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SendHistoryEntry, $Out>
    implements SendHistoryEntryCopyWith<$R, SendHistoryEntry, $Out> {
  _SendHistoryEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SendHistoryEntry> $mapper =
      SendHistoryEntryMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? fileName,
    FileType? fileType,
    Object? path = $none,
    bool? isMessage,
    int? fileSize,
    String? receiverAlias,
    String? receiverIp,
    DateTime? timestamp,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (fileName != null) #fileName: fileName,
      if (fileType != null) #fileType: fileType,
      if (path != $none) #path: path,
      if (isMessage != null) #isMessage: isMessage,
      if (fileSize != null) #fileSize: fileSize,
      if (receiverAlias != null) #receiverAlias: receiverAlias,
      if (receiverIp != null) #receiverIp: receiverIp,
      if (timestamp != null) #timestamp: timestamp,
    }),
  );
  @override
  SendHistoryEntry $make(CopyWithData data) => SendHistoryEntry(
    id: data.get(#id, or: $value.id),
    fileName: data.get(#fileName, or: $value.fileName),
    fileType: data.get(#fileType, or: $value.fileType),
    path: data.get(#path, or: $value.path),
    isMessage: data.get(#isMessage, or: $value.isMessage),
    fileSize: data.get(#fileSize, or: $value.fileSize),
    receiverAlias: data.get(#receiverAlias, or: $value.receiverAlias),
    receiverIp: data.get(#receiverIp, or: $value.receiverIp),
    timestamp: data.get(#timestamp, or: $value.timestamp),
  );

  @override
  SendHistoryEntryCopyWith<$R2, SendHistoryEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SendHistoryEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

