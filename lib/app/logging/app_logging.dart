import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:r_edit/app/logging/app_log_diagnostic.dart';
import 'package:r_edit/app/logging/app_log_event.dart';
import 'package:r_edit/app/logging/rotating_file_log.dart';

/// 구독·전역 콜백·레벨·파일 수명의 앱 소유자다. 업무 결과를 변환하지 않는다.
final class AppLogging {
  AppLogging._(this._debug, this._fallback, this._observe);
  static AppLogging? _current;
  static Future<void> _lifecycle = Future.value();

  /// 반복/동시 초기화를 직렬화하고 이전 소유자를 닫는다. 경로 실패는 파일 출력만 중단한다.
  static Future<AppLogging> start({
    bool debug = kDebugMode,
    Future<Directory> Function()? directory,
    void Function()? onUnavailable,
    void Function(String)? onRecord,
  }) {
    final result = _lifecycle.then((_) async {
      await _current?.close();
      final logging = AppLogging._(
        debug,
        onUnavailable ?? _emergency,
        onRecord,
      );
      await logging._initialize(directory ?? getApplicationCacheDirectory);
      _current = logging;
      return logging;
    });
    _lifecycle = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  static void _emergency() {
    developer.log('앱 파일 로그를 사용할 수 없습니다.', name: 'r_edit.logging', level: 1000);
  }

  final bool _debug;
  final void Function() _fallback;
  final void Function(String)? _observe;
  final Stopwatch _elapsed = Stopwatch()..start();
  final Expando<bool> _reported = Expando('r_edit_reported_failure');
  RotatingFileLog? _file;
  StreamSubscription<LogRecord>? _subscription;
  FlutterExceptionHandler? _previousFlutter;
  bool Function(Object, StackTrace)? _previousPlatform;
  late FlutterExceptionHandler _flutter;
  late bool Function(Object, StackTrace) _platform;
  Level? _previousLevel;
  AppLifecycleListener? _exitListener;
  Future<void>? _closing;
  late bool _fallbackSent = false;

  /// 실제 선택된 슬롯 경로다. 실패 시 null이며 업무 파일 위치와 무관하다.
  String? get filePath => _file?.activeFilePath;

  /// Provider 실패만 관찰하며 상태/이름/값은 기록하지 않는다.
  ProviderObserver get providerObserver => _AppFailureObserver(this);

  void _unavailable() {
    if (_fallbackSent) return;
    _fallbackSent = true;
    _fallback();
  }

  Future<void> _initialize(Future<Directory> Function() resolve) async {
    try {
      final directory = await resolve();
      _file = await RotatingFileLog.open(
        Directory('${directory.path}/logs'),
        onUnavailable: _unavailable,
      );
    } on FileSystemException {
      _unavailable();
    } on PlatformException {
      _unavailable();
    } on MissingPluginException {
      _unavailable();
    }
    _previousLevel = Logger.root.level;
    Logger.root.level = _debug ? Level.FINE : Level.INFO;
    _subscription = Logger.root.onRecord.listen((record) {
      final encoded = encodeAppRecord(record, _elapsed.elapsedMicroseconds);
      if (encoded == null) return;
      _file?.add(encoded);
      _observe?.call(encoded);
      if (_debug) {
        developer.log(encoded, name: 'r_edit', level: record.level.value);
      }
    });
    _previousFlutter = FlutterError.onError;
    _previousPlatform = PlatformDispatcher.instance.onError;
    _flutter = (details) {
      reportUnexpected(
        details.exception,
        details.stack ?? StackTrace.current,
        AppEvent.flutterError,
      );
      _previousFlutter?.call(details);
    };
    _platform = (error, stack) {
      reportUnexpected(error, stack, AppEvent.platformError);
      return _previousPlatform?.call(error, stack) ?? false;
    };
    FlutterError.onError = _flutter;
    PlatformDispatcher.instance.onError = _platform;
    Logger('r_edit.bootstrap').info(const AppLogEvent(AppEvent.started));
  }

  /// 예상 밖 실패만 최종 경계에서 기록한다. 원래 예외/스택을 별도 인자로 전달한다.
  /// diagnostic은 해당 오류를 이해하는 경계가 선택한다. 전역 핸들러는 추측하지 않는다.
  void reportUnexpected(
    Object error,
    StackTrace stack,
    AppEvent event, {
    AppLogDiagnostic? diagnostic,
  }) {
    // Riverpod의 공개 원인 필드로만 동일성을 판단한다. 예외를 재던지거나 바꾸지 않는다.
    final identity = appFailureContext(error, stack).error;
    if (identity is Exception || identity is Error) {
      if (_reported[identity] == true) return;
      _reported[identity] = true;
    }
    Logger('r_edit.errors')
        .severe(AppLogEvent(event, diagnostic: diagnostic), error, stack);
  }

  /// 취소 가능한 정상 종료 요청에서 flush 후 exit를 응답한다.
  void bindApplicationExit() {
    _exitListener ??= AppLifecycleListener(
      onExitRequested: () async {
        await close();
        return AppExitResponse.exit;
      },
    );
  }

  /// 이미 받은 기록을 flush한다. 비정상 종료의 마지막 기록은 보장하지 않는다.
  Future<void> flush() async {
    await _file?.flush();
  }

  /// 구독/콜백/레벨을 복구하고 파일을 닫는다. 반복 호출 시 같은 완료를 반환한다.
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    Logger('r_edit.bootstrap').info(const AppLogEvent(AppEvent.stopping));
    await _subscription?.cancel();
    if (FlutterError.onError == _flutter) {
      FlutterError.onError = _previousFlutter;
    }
    if (PlatformDispatcher.instance.onError == _platform) {
      PlatformDispatcher.instance.onError = _previousPlatform;
    }
    Logger.root.level = _previousLevel;
    _exitListener?.dispose();
    await _file?.close();
    _elapsed.stop();
    if (identical(_current, this)) _current = null;
  }
}

final class _AppFailureObserver extends ProviderObserver {
  _AppFailureObserver(this.logging);
  final AppLogging logging;
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    logging.reportUnexpected(error, stackTrace, AppEvent.providerError);
  }
}
