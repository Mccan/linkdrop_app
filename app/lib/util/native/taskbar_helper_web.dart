import 'package:common/model/session_status.dart';

enum TaskbarIcon { regular, error, success }

class TaskbarHelper {
  static Future<void> clearProgressBar() async {}

  static Future<void> setProgressBar(int progress, int total) async {}

  static Future<void> setProgressBarMode(int mode) async {}

  static Future<void> setTaskbarIcon(TaskbarIcon icon) async {}

  static Future<void> visualizeStatus(SessionStatus? status) async {}
}
