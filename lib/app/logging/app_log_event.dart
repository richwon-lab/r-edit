import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

/// 현재 앱의 실제 실행/표시/오류 경계다. 업무 명령을 가정하지 않는다.
enum AppEvent {
  /// 초기화 완료다.
  started,

  /// 정상 종료 요청을 처리한다.
  stopping,

  /// 테마 표시 설정 변경이다.
  themeChanged,

  /// 등록 경로 확인이다.
  routeChecked,

  /// Flutter가 잡은 미처리 결함이다.
  flutterError,

  /// root isolate의 미처리 오류다.
  platformError,

  /// Provider가 보관/전달한 예상 밖 실패다.
  providerError,
}

/// 파일로 허용한 고정 이벤트다. 임의 문구/JSON/Provider 상태를 받지 않는다.
final class AppLogEvent {
  /// 고정 이벤트만 기록한다.
  const AppLogEvent(this.event);

  /// 실행 경계의 이벤트 종류다.
  final AppEvent event;
  @override
  String toString() => event.name;
}

/// 외부 오류 메시지를 평가하지 않고 크기 제한한 개발자 스택 프레임만 남긴다.
String safeStack(StackTrace stack) {
  final raw = stack.toString();
  final bounded = raw.substring(0, raw.length > 4096 ? 4096 : raw.length);
  return bounded
      .split('\n')
      .where((line) => line.startsWith('#'))
      .take(16)
      .map((line) {
        // 임의 스택의 메시지/함수 표현을 복사하지 않고 소스 위치만 허용한다.
        final source = RegExp(
          r'\((package:r_edit/[A-Za-z0-9_./-]+:\d+:\d+|dart:[A-Za-z0-9_./-]+:\d+:\d+)\)\s*$',
        ).firstMatch(line);
        if (source != null) return source.group(1)!;
        final local = RegExp(r'\(file:///[^)]+:(\d+):(\d+)\)\s*$')
            .firstMatch(line);
        return local == null
            ? 'external-frame'
            : 'local-source:${local.group(1)}:${local.group(2)}';
      })
      .join('\n');
}

/// 구조화 레코드로 바꾼다. 임의 String 메시지와 알려지지 않은 로거는 영속 기록하지 않는다.
String? encodeAppRecord(LogRecord record, int elapsedMicroseconds) {
  final object = record.object;
  if (object is! AppLogEvent) return null;
  const names = {'r_edit.app', 'r_edit.bootstrap', 'r_edit.errors'};
  if (!names.contains(record.loggerName)) return null;
  return jsonEncode({
    'time': record.time.toUtc().toIso8601String(),
    'event': object.event.name,
    'level': record.level.name,
    'logger': record.loggerName,
    'pid': pid,
    'elapsedMicroseconds': elapsedMicroseconds,
    if (record.error != null) 'errorType': record.error.runtimeType.toString(),
    if (record.stackTrace case final stack?) 'stack': safeStack(stack),
  });
}
