import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:r_edit/app/logging/app_log_event.dart';

void main() {
  group('스택의 소스 위치와 경로 보호', () {
    for (final (location, expected) in [
      ('package:r_edit/main.dart:12:3', 'package:r_edit/main.dart:12:3'),
      (
        'package:third_party/src/a.dart:2:11',
        'package:third_party/src/a.dart:2:11',
      ),
      ('dart:async/future_impl.dart:3:4', 'dart:async/future_impl.dart:3:4'),
      ('package:third_party/a.dart:7', 'package:third_party/a.dart:7'),
      (
        'file:///C:/Users/private_user/project/lib/main.dart:8:2',
        'file:main.dart:8:2',
      ),
      (
        r'C:\Users\private_user\project\lib\main.dart:8:2',
        'file:main.dart:8:2',
      ),
      ('/home/private_user/project/lib/main.dart:8:2', 'file:main.dart:8:2'),
      ('file:///root.dart:8:2', 'file:root.dart:8:2'),
    ]) {
      test('$location 위치에서 승인된 URI 또는 파일명·줄·열만 남긴다', () {
        expect(
          safeStack(StackTrace.fromString('#0 비공개 함수 ($location)')),
          expected,
        );
      });
    }

    test('지원하지 않는 스택도 원문 없이 제한된 대체 표현을 제공한다', () {
      expect(
        safeStack(
          StackTrace.fromString(
            '비공개 외부 메시지\n#0 unknown\n<asynchronous suspension>',
          ),
        ),
        'unparsed-frame\nunparsed-frame\nasync-gap',
      );
    });

    test('긴 스택은 입력 4096자와 출력 16행 제한을 유지한다', () {
      final stack = List.generate(
        1000,
        (i) => '#$i function (package:other/src/a.dart:1:2)',
      ).join('\n');
      final output = safeStack(StackTrace.fromString(stack));
      expect(output.split('\n'), hasLength(16));
      expect(output.length, lessThanOrEqualTo(4096));
      expect(safeStack(StackTrace.fromString('비공개' * 10000)), 'unparsed-frame');
    });
  });

  test('알 수 없는 오류는 toString을 평가하거나 진단을 추측하지 않는다', () {
    final encoded = encodeAppRecord(
      LogRecord(
        Level.SEVERE,
        'platformError',
        'r_edit.errors',
        _MessageMustNotBeRead(),
        StackTrace.fromString('외부 메시지'),
        null,
        const AppLogEvent(AppEvent.platformError),
      ),
      12,
    )!;
    final record = jsonDecode(encoded) as Map<String, dynamic>;
    expect(record['errorType'], '_MessageMustNotBeRead');
    expect(record.containsKey('diagnostic'), isFalse);
    expect(record['stack'], 'unparsed-frame');
  });
}

final class _MessageMustNotBeRead implements Exception {
  @override
  String toString() => throw StateError('오류 메시지를 평가하면 안 됨');
}
