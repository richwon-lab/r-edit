import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:r_edit/app/logging/app_log_diagnostic.dart';
import 'package:r_edit/app/logging/app_log_event.dart';
import 'package:r_edit/app/logging/app_logging.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  AppLogging? runtime;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('r_edit_runtime_test_');
  });
  tearDown(() async {
    await runtime?.close();
    runtime = null;
    expect(directory.parent.absolute.path, Directory.systemTemp.absolute.path);
    await directory.delete(recursive: true);
  });

  test('스택은 허용한 소스 위치만 남기고 임의 메시지와 로컬 경로를 제거한다', () {
    final text = safeStack(
      StackTrace.fromString(
        '비공개 외부 오류\n#0 비공개 함수 (package:r_edit/main.dart:12:3)\n'
        '#1 비공개 값\n#2 method (file:///C:/private/company/file.dart:45:6)',
      ),
    );
    expect(text, contains('package:r_edit/main.dart:12:3'));
    expect(text, contains('file:file.dart:45:6'));
    expect(text, isNot(contains('비공개')));
    expect(text, isNot(contains('private')));
  });

  test('명시적으로 선택한 진단과 다른 패키지의 소스 위치를 실제 JSONL에 보존한다', () async {
    runtime = await AppLogging.start(
      debug: false,
      directory: () async => directory,
    );
    const error = FormatException('비공개 외부 메시지', '비공개 원문 전체 JSON');
    final stack = StackTrace.fromString(
      '#0 비공개 함수 (package:other_package/src/reader.dart:28:9)\n'
      '#1 method (file:///C:/Users/private_user/project/lib/main.dart:45:6)',
    );
    // 로그 투영 계약의 테스트 자료다. workflow 연결/업무 명령을 가정하지 않는다.
    runtime!.reportUnexpected(
      error,
      stack,
      AppEvent.platformError,
      diagnostic: const AppLogDiagnostic(
        code: 'invalidType',
        fieldPath: 'items[1].value',
        type: AppLogTypeDiagnostic(expectedType: 'String', actualType: 'int'),
        operation: 'readValue',
      ),
    );
    await runtime!.flush();
    final text = await File(runtime!.filePath!).readAsString();
    final record = const LineSplitter()
        .convert(text)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .singleWhere((record) => record['event'] == 'platformError');
    expect(record['diagnostic'], {
      'code': 'invalidType',
      'fieldPath': 'items[1].value',
      'expectedType': 'String',
      'actualType': 'int',
      'operation': 'readValue',
    });
    expect(record['errorType'], 'FormatException');
    expect(record.containsKey('wrapperTypes'), isFalse);
    expect(
      record['stack'],
      'package:other_package/src/reader.dart:28:9\nfile:main.dart:45:6',
    );
    expect(text, isNot(contains('비공개')));
    expect(text, isNot(contains('private_user')));
    expect(text, isNot(contains('C:/Users')));
  });

  test('Riverpod wrapper가 먼저 도달해도 원래 실패 타입·스택과 선택한 진단을 파일에 보존한다', () async {
    runtime = await AppLogging.start(
      debug: false,
      directory: () async => directory,
    );
    const failure = FormatException('비공개 외부 메시지', '비공개 전체 상태');
    final originalStack = StackTrace.fromString(
      '#0 parse (package:third_party/parser.dart:8:2)',
    );
    // observer 없는 컨테이너에서 실제 Riverpod wrapper를 얻는다.
    final provider = Provider<int>(
      (ref) => Error.throwWithStackTrace(failure, originalStack),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    try {
      container.read(provider);
      fail('Provider 실패가 정상값으로 바뀜');
    } on ProviderException catch (wrapper, wrapperStack) {
      expect(wrapper.exception, same(failure));
      runtime!.reportUnexpected(
        wrapper,
        wrapperStack,
        AppEvent.flutterError,
        diagnostic: const AppLogDiagnostic(
          code: 'invalidType',
          fieldPath: 'value',
          type: AppLogTypeDiagnostic(expectedType: 'String', actualType: 'int'),
        ),
      );
      // 원인이 뒤에 다시 도달해도 기존 중복 방지 정책을 유지한다.
      runtime!.reportUnexpected(failure, originalStack, AppEvent.providerError);
    }
    await runtime!.flush();
    final text = await File(runtime!.filePath!).readAsString();
    final errors = const LineSplitter()
        .convert(text)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .where((record) => record.containsKey('errorType'))
        .toList();
    expect(errors, hasLength(1));
    expect(errors.single['errorType'], 'FormatException');
    expect(errors.single['wrapperTypes'], ['ProviderException']);
    expect(errors.single['stack'], 'package:third_party/parser.dart:8:2');
    expect(errors.single['diagnostic'], {
      'code': 'invalidType',
      'fieldPath': 'value',
      'expectedType': 'String',
      'actualType': 'int',
    });
    expect(text, isNot(contains('비공개')));
  });

  test('배포 레벨은 FINE의 지연 메시지를 평가하지 않고 고정 이벤트만 파일에 기록한다', () async {
    runtime = await AppLogging.start(
      debug: false,
      directory: () async => directory,
    );
    var evaluations = 0;
    Logger('r_edit.app').fine(() {
      evaluations++;
      return const AppLogEvent(AppEvent.routeChecked);
    });
    Logger('r_edit.app').info('비공개 원문/전체 JSON');
    Logger('other').info(const AppLogEvent(AppEvent.themeChanged));
    Logger('r_edit.app').info(const AppLogEvent(AppEvent.themeChanged));
    final path = runtime!.filePath!;
    await runtime!.flush();
    final text = await File(path).readAsString();
    final records = const LineSplitter()
        .convert(text)
        .map((line) => jsonDecode(line) as Map<String, dynamic>);
    expect(evaluations, 0);
    expect(records.map((record) => record['event']), [
      'started',
      'themeChanged',
    ]);
    expect(text, isNot(contains('비공개')));
    expect(
      records.every((record) => record['elapsedMicroseconds'] is int),
      isTrue,
    );
  });

  test('개발 레벨은 FINE 이벤트를 기록하고 동일 오류의 전역 전달을 중복 기록하지 않는다', () async {
    final records = <String>[];
    final previousFlutter = FlutterError.onError;
    final previousPlatform = PlatformDispatcher.instance.onError;
    var frameworkCalls = 0;
    var platformCalls = 0;
    FlutterError.onError = (_) => frameworkCalls++;
    PlatformDispatcher.instance.onError = (_, _) {
      platformCalls++;
      return false;
    };
    final expectedFlutter = FlutterError.onError;
    final expectedPlatform = PlatformDispatcher.instance.onError;
    try {
      runtime = await AppLogging.start(
        directory: () async => directory,
        onRecord: records.add,
      );
      Logger('r_edit.app').fine(const AppLogEvent(AppEvent.routeChecked));
      final error = StateError('비공개 원문');
      final stack = StackTrace.fromString(
        '외부 비공개 메시지\n#0 function (package:r_edit/main.dart:12:3)',
      );
      runtime!.reportUnexpected(error, stack, AppEvent.providerError);
      FlutterError.onError!(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      expect(PlatformDispatcher.instance.onError!(error, stack), isFalse);
      expect(frameworkCalls, 1);
      expect(platformCalls, 1);
      expect(records.where((line) => line.contains('"errorType"')).length, 1);
      expect(records.join(), isNot(contains('비공개')));
      expect(records.join(), contains('routeChecked'));
      expect(records.join(), contains('StateError'));
      await runtime!.close();
      expect(FlutterError.onError, same(expectedFlutter));
      expect(PlatformDispatcher.instance.onError, same(expectedPlatform));
    } finally {
      FlutterError.onError = previousFlutter;
      PlatformDispatcher.instance.onError = previousPlatform;
    }
  });

  test('Riverpod가 보관하는 실패는 원래 실패를 유지하고 상태 전체를 기록하지 않는다', () async {
    final records = <String>[];
    runtime = await AppLogging.start(
      debug: false,
      directory: () async => directory,
      onRecord: records.add,
    );
    final failure = StateError('비공개 Provider 상태');
    final provider = Provider<int>((ref) => throw failure);
    final container = ProviderContainer(observers: [runtime!.providerObserver]);
    addTearDown(container.dispose);
    try {
      container.read(provider);
      fail('Provider 실패가 정상값으로 바뀜');
    } on ProviderException catch (error, stack) {
      expect(error.exception, same(failure));
      // 프레임워크로 전달된 실제 wrapper도 원인과 같은 실패로 식별한다.
      runtime!.reportUnexpected(error, stack, AppEvent.flutterError);
    }
    expect(records.where((line) => line.contains('providerError')).length, 1);
    expect(records.join(), isNot(contains('비공개')));
  });

  test('FutureProvider 실패의 원래 예외와 비동기 스택을 유지한다', () async {
    final records = <String>[];
    runtime = await AppLogging.start(
      debug: false,
      directory: () async => directory,
      onRecord: records.add,
    );
    final failure = StateError('비공개 비동기 상태');
    final provider = FutureProvider<int>((ref) async => throw failure);
    final container = ProviderContainer(
      observers: [runtime!.providerObserver],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    await expectLater(container.read(provider.future), throwsA(same(failure)));
    final record = jsonDecode(
      records.singleWhere((line) => line.contains('providerError')),
    ) as Map<String, dynamic>;
    expect(record['errorType'], 'StateError');
    expect(record['stack'], isA<String>());
    expect(records.join(), isNot(contains('비공개')));
  });

  test('경로 실패는 한 번만 대체 보고하며 원래 결함은 정상 결과로 바꾸지 않는다', () async {
    var fallbacks = 0;
    runtime = await AppLogging.start(
      debug: false,
      directory: () async => throw const FileSystemException('비공개 경로'),
      onUnavailable: () => fallbacks++,
    );
    final error = StateError('업무 결함');
    runtime!.reportUnexpected(
      error,
      StackTrace.current,
      AppEvent.platformError,
    );
    await runtime!.flush();
    expect(fallbacks, 1);
    expect(runtime!.filePath, isNull);
    await runtime!.close();
    expect(fallbacks, 1);
  });

  test('반복 초기화는 이전 구독을 닫고 해제 시 원래 로그 레벨을 복구한다', () async {
    final originalLevel = Logger.root.level;
    final oldRecords = <String>[];
    final newRecords = <String>[];
    final old = await AppLogging.start(
      directory: () async => directory,
      onRecord: oldRecords.add,
    );
    runtime = await AppLogging.start(
      debug: false,
      directory: () async => directory,
      onRecord: newRecords.add,
    );
    final oldLength = oldRecords.length;
    Logger('r_edit.app').info(const AppLogEvent(AppEvent.themeChanged));
    expect(oldRecords.length, oldLength);
    expect(newRecords.where((line) => line.contains('themeChanged')).length, 1);
    await old.close();
    await runtime!.close();
    expect(Logger.root.level, originalLevel);
  });
}
