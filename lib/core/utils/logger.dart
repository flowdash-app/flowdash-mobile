import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class AppLogger {
  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint(
          '${record.loggerName}: ${record.level.name}: ${record.time}: ${record.message.toString()}');
      if (record.error != null) {
        debugPrint('Error: ${record.error?.toString()}');
      }
      if (record.stackTrace != null) {
        debugPrint('StackTrace: ${record.stackTrace?.toString()}');
      }
    });
  }

  static Logger getLogger(String name) {
    return Logger(name);
  }
}
