import 'package:common/model/device.dart';
import 'package:common/model/dto/file_dto.dart';
import 'package:common/model/file_status.dart';
import 'package:common/model/file_type.dart';
import 'package:common/model/session_status.dart';
import 'package:linkdrop_app/model/persistence/send_history_entry.dart';
import 'package:linkdrop_app/model/state/send/send_session_state.dart';
import 'package:linkdrop_app/model/state/send/sending_file.dart';
import 'package:linkdrop_app/util/send_history_entries.dart';
import 'package:test/test.dart';

void main() {
  test('Should store message content instead of temp file name in send history', () {
    final session = SendSessionState(
      sessionId: 'session-1',
      remoteSessionId: null,
      background: false,
      status: SessionStatus.finished,
      target: const Device(
        signalingId: null,
        ip: '192.168.1.88',
        version: '2.0',
        port: 53317,
        https: true,
        fingerprint: 'device-fp',
        alias: 'remote-device',
        deviceModel: 'Windows',
        deviceType: DeviceType.desktop,
        download: false,
        discoveryMethods: {},
      ),
      files: {
        'file-1': SendingFile(
          file: const FileDto(
            id: 'file-1',
            fileName: 'message.txt',
            size: 12,
            fileType: FileType.text,
            hash: null,
            preview: 'hello world',
            legacy: false,
            metadata: null,
          ),
          status: FileStatus.queue,
          token: null,
          thumbnail: null,
          asset: null,
          path: null,
          bytes: [104, 101, 108, 108, 111],
          errorMessage: null,
          isMessage: true,
        ),
      },
      startTime: null,
      endTime: null,
      sendingTasks: const [],
      errorMessage: null,
    );

    final entries = buildSendHistoryEntries(
      sessionState: session,
      timestamp: DateTime(2026, 3, 29),
      receiverAlias: 'Office-PC',
      entryIdBuilder: (file) => file.file.id,
      allowDeliveredMessagesWithoutUpload: true,
    );

    expect(entries, hasLength(1));
    expect(
      entries.single,
      isA<SendHistoryEntry>()
          .having((entry) => entry.id, 'id', 'file-1')
          .having((entry) => entry.fileName, 'fileName', 'hello world')
          .having((entry) => entry.isMessage, 'isMessage', true)
          .having((entry) => entry.receiverAlias, 'receiverAlias', 'Office-PC')
          .having((entry) => entry.receiverIp, 'receiverIp', '192.168.1.88'),
    );
  });

  test('Should decode message bytes when preview is unavailable', () {
    final session = SendSessionState(
      sessionId: 'session-1',
      remoteSessionId: null,
      background: false,
      status: SessionStatus.finished,
      target: const Device(
        signalingId: null,
        ip: '192.168.1.88',
        version: '2.0',
        port: 53317,
        https: true,
        fingerprint: 'device-fp',
        alias: 'remote-device',
        deviceModel: 'Windows',
        deviceType: DeviceType.desktop,
        download: false,
        discoveryMethods: {},
      ),
      files: {
        'file-1': SendingFile(
          file: const FileDto(
            id: 'file-1',
            fileName: '7ab9.txt',
            size: 12,
            fileType: FileType.text,
            hash: null,
            preview: null,
            legacy: false,
            metadata: null,
          ),
          status: FileStatus.queue,
          token: null,
          thumbnail: null,
          asset: null,
          path: null,
          bytes: [104, 101, 108, 108, 111],
          errorMessage: null,
          isMessage: true,
        ),
      },
      startTime: null,
      endTime: null,
      sendingTasks: const [],
      errorMessage: null,
    );

    final entries = buildSendHistoryEntries(
      sessionState: session,
      timestamp: DateTime(2026, 3, 29),
      receiverAlias: 'Office-PC',
      entryIdBuilder: (file) => file.file.id,
      allowDeliveredMessagesWithoutUpload: true,
    );

    expect(entries, hasLength(1));
    expect(entries.single.fileName, 'hello');
  });

  test('Should not generate send history for unuploaded normal files in empty selection path', () {
    final session = SendSessionState(
      sessionId: 'session-1',
      remoteSessionId: null,
      background: false,
      status: SessionStatus.finished,
      target: const Device(
        signalingId: null,
        ip: '192.168.1.88',
        version: '2.0',
        port: 53317,
        https: true,
        fingerprint: 'device-fp',
        alias: 'remote-device',
        deviceModel: 'Windows',
        deviceType: DeviceType.desktop,
        download: false,
        discoveryMethods: {},
      ),
      files: {
        'file-1': SendingFile(
          file: const FileDto(
            id: 'file-1',
            fileName: 'photo.png',
            size: 12,
            fileType: FileType.image,
            hash: null,
            preview: null,
            legacy: false,
            metadata: null,
          ),
          status: FileStatus.queue,
          token: null,
          thumbnail: null,
          asset: null,
          path: 'C:/tmp/photo.png',
          bytes: null,
          errorMessage: null,
          isMessage: false,
        ),
      },
      startTime: null,
      endTime: null,
      sendingTasks: const [],
      errorMessage: null,
    );

    final entries = buildSendHistoryEntries(
      sessionState: session,
      timestamp: DateTime(2026, 3, 29),
      receiverAlias: 'Office-PC',
      entryIdBuilder: (file) => file.file.id,
      allowDeliveredMessagesWithoutUpload: true,
    );

    expect(entries, isEmpty);
  });
}