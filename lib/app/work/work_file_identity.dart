import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_file_identity.freezed.dart';

/// 호출 경계가 확인한 비교 키와 원래 접근 정보를 보관한다.
/// OS 경로 해석·대소문자/Unicode 정규화·물리 파일 동일성 검사는 하지 않는다.
@Freezed(
  copyWith: false,
  fromJson: false,
  toJson: false,
  toStringOverride: false,
)
final class WorkFileIdentity with _$WorkFileIdentity {
  /// 두 문자열은 비어 있지 않아야 하며 전달한 표기를 그대로 보존한다.
  WorkFileIdentity({
    required this.comparisonKey,
    required this.originalAccessPath,
  }) {
    if (comparisonKey.isEmpty) {
      throw ArgumentError.value(
        comparisonKey,
        'comparisonKey',
        '빈 비교 키는 사용할 수 없습니다.',
      );
    }
    if (originalAccessPath.isEmpty) {
      throw ArgumentError.value(
        originalAccessPath,
        'originalAccessPath',
        '원래 접근 정보가 필요합니다.',
      );
    }
  }

  /// 같은 열린 작업을 찾을 때 정확한 문자열 동등성으로만 비교하는 키다.
  final String comparisonKey;

  /// 후속 파일 경계에 전달할 원래 접근 정보다. 파일 읽기를 수행하지 않는다.
  final String originalAccessPath;
}
