// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_works.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ProviderScope 안에서 열린 작업·세션·확인 대기를 소유한다.
/// 화면 구독 수명과 작업 수명은 독립적이며 raw 세션/상태 설치 경로를 공개하지 않는다.

@ProviderFor(OpenWorks)
final openWorksProvider = OpenWorksProvider._();

/// ProviderScope 안에서 열린 작업·세션·확인 대기를 소유한다.
/// 화면 구독 수명과 작업 수명은 독립적이며 raw 세션/상태 설치 경로를 공개하지 않는다.
final class OpenWorksProvider
    extends $NotifierProvider<OpenWorks, OpenWorksView> {
  /// ProviderScope 안에서 열린 작업·세션·확인 대기를 소유한다.
  /// 화면 구독 수명과 작업 수명은 독립적이며 raw 세션/상태 설치 경로를 공개하지 않는다.
  OpenWorksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openWorksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openWorksHash();

  @$internal
  @override
  OpenWorks create() => OpenWorks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpenWorksView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpenWorksView>(value),
    );
  }
}

String _$openWorksHash() => r'58c2ec6eed25e60d51867ef526154c05fe303e84';

/// ProviderScope 안에서 열린 작업·세션·확인 대기를 소유한다.
/// 화면 구독 수명과 작업 수명은 독립적이며 raw 세션/상태 설치 경로를 공개하지 않는다.

abstract class _$OpenWorks extends $Notifier<OpenWorksView> {
  OpenWorksView build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OpenWorksView, OpenWorksView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OpenWorksView, OpenWorksView>,
              OpenWorksView,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
