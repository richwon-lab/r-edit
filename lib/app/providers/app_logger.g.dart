// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_logger.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱 실행 경계의 로거를 제공한다. 업무 패키지의 전역 의존성으로 사용하지 않는다.

@ProviderFor(appLogger)
final appLoggerProvider = AppLoggerProvider._();

/// 앱 실행 경계의 로거를 제공한다. 업무 패키지의 전역 의존성으로 사용하지 않는다.

final class AppLoggerProvider
    extends $FunctionalProvider<Logger, Logger, Logger>
    with $Provider<Logger> {
  /// 앱 실행 경계의 로거를 제공한다. 업무 패키지의 전역 의존성으로 사용하지 않는다.
  AppLoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLoggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLoggerHash();

  @$internal
  @override
  $ProviderElement<Logger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Logger create(Ref ref) {
    return appLogger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Logger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Logger>(value),
    );
  }
}

String _$appLoggerHash() => r'86a1f71433843eaf25a9da3c474991b35a23aae4';
