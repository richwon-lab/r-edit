import 'dart:async';
import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// 앱 진입점만 루트 수신기를 소유한다. 라이브러리는 전역 수신기를 설치하지 않는다.
/// 원문·작업 JSON을 기록하지 않으며 파일/원격 로그 전송은 제공하지 않는다.
StreamSubscription<LogRecord> configureAppLogging() {
  Logger.root.level = Level.INFO;
  return Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      time: record.time,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}
