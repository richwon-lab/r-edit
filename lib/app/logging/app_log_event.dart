import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:logging/logging.dart';
import 'package:r_edit/app/logging/app_log_diagnostic.dart';

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
  const AppLogEvent(this.event, {this.diagnostic});

  /// 실행 경계의 이벤트 종류다.
  final AppEvent event;

  /// 오류를 해석한 경계가 명시적으로 선택한 로그용 상세다. 임의 예외를 펼치지 않는다.
  final AppLogDiagnostic? diagnostic;
  @override
  String toString() => event.name;
}

/// Riverpod wrapper의 공개 원인/스택을 해석한다. 예외의 전달/처리 결과는 바꾸지 않는다.
/// wrappers는 바깥쪽부터 안쪽 순서이며 원인 객체를 문자열로 변환하지 않는다.
({Object error, StackTrace? stack, List<String> wrappers}) appFailureContext(
  Object error,
  StackTrace? stack,
) {
  final wrappers = <String>[];
  var original = error;
  var originalStack = stack;
  while (original is ProviderException) {
    wrappers.add(original.runtimeType.toString());
    originalStack = original.stackTrace;
    original = original.exception;
  }
  return (error: original, stack: originalStack, wrappers: wrappers);
}

final _frameLocation = RegExp(r'^#\d+\s+.*\(([^()]+)\)\s*$');
final _uriLocation = RegExp(
  r'^(package:[A-Za-z_][A-Za-z0-9_]*/[A-Za-z0-9_./-]+|dart:[A-Za-z0-9_./-]+):(\d+)(?::(\d+))?$',
);
final _fileLocation = RegExp(
  r'^(?:file:/+|[A-Za-z]:[\\/]|/)(?:.*[\\/])?([A-Za-z0-9_.-]+):(\d+)(?::(\d+))?$',
);

/// 최대 4096자/16행에서 소스 위치만 남긴다. 함수 표현·절대경로·임의 메시지는 출력하지 않는다.
String safeStack(StackTrace stack) {
  final raw = stack.toString();
  final bounded = raw.substring(0, raw.length > 4096 ? 4096 : raw.length);
  return bounded
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .take(16)
      .map((line) {
        if (line.trim() == '<asynchronous suspension>') return 'async-gap';
        final location = _frameLocation.firstMatch(line)?.group(1);
        if (location == null) return 'unparsed-frame';
        final source = _uriLocation.firstMatch(location);
        if (source != null) return location;
        final local = _fileLocation.firstMatch(location);
        if (local == null) return 'unparsed-frame';
        return 'file:${local.group(1)}:${local.group(2)}'
            '${local.group(3) == null ? '' : ':${local.group(3)}'}';
      })
      .join('\n');
}

/// 구조화 레코드로 바꾼다. 임의 String 메시지와 알려지지 않은 로거는 영속 기록하지 않는다.
String? encodeAppRecord(LogRecord record, int elapsedMicroseconds) {
  final object = record.object;
  if (object is! AppLogEvent) return null;
  const names = {'r_edit.app', 'r_edit.bootstrap', 'r_edit.errors'};
  if (!names.contains(record.loggerName)) return null;
  final failure = record.error == null
      ? null
      : appFailureContext(record.error!, record.stackTrace);
  final stack = failure?.stack ?? record.stackTrace;
  return jsonEncode({
    'time': record.time.toUtc().toIso8601String(),
    'event': object.event.name,
    'level': record.level.name,
    'logger': record.loggerName,
    'pid': pid,
    'elapsedMicroseconds': elapsedMicroseconds,
    if (failure != null) 'errorType': failure.error.runtimeType.toString(),
    if (failure != null && failure.wrappers.isNotEmpty)
      'wrapperTypes': failure.wrappers,
    if (object.diagnostic case final diagnostic?)
      'diagnostic': diagnostic.toJson(),
    if (stack != null) 'stack': safeStack(stack),
  });
}
