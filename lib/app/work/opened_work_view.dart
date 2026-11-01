import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit/app/work/open_works.dart';
import 'package:r_edit/app/work/work_file_identity.dart';
import 'package:r_edit_workflow/r_edit_workflow.dart';

part 'opened_work_view.freezed.dart';

/// 열린 작업의 읽기 전용 투영이다. 세션 객체나 현재 상태 설치 API가 아니다.
@Freezed(
  copyWith: false,
  fromJson: false,
  toJson: false,
  toStringOverride: false,
)
final class OpenedWorkView with _$OpenedWorkView {
  /// 명령 소유자가 최신 세션에서 읽은 불변 관찰값을 연결한다.
  OpenedWorkView({
    required this.workId,
    required this.fileIdentity,
    required this.displayName,
    required this.editState,
  });

  /// 열기 한 번의 실행 ID다. 표시명·파일 키와 독립적이다.
  final OpenedWorkId workId;

  /// 등록 시 보존한 비교 키와 원래 접근 정보다.
  final WorkFileIdentity fileIdentity;

  /// 빈 값·중복이 허용되는 화면 표시명이다. 조회 키가 아니다.
  final String displayName;

  /// 게시 시점의 workflow 상태다. 이후 더 최신 상태를 덮어쓰는 입력이 아니다.
  final ProductDesignEditState editState;
}

/// ProviderScope가 소유한 열린 작업들의 불변 관찰 목록이다.
@Freezed(
  copyWith: false,
  fromJson: false,
  toJson: false,
  toStringOverride: false,
)
final class OpenWorksView with _$OpenWorksView {
  /// 작업 순서는 등록 순서이며 목록을 방어 복사한다.
  OpenWorksView({
    required List<OpenedWorkView> works,
    required this.activeWorkId,
  }) : works = List.unmodifiable(works);

  /// 원문/구성은 각 workflow 상태를 통해 관찰하며 별도 정본으로 복제하지 않는다.
  final List<OpenedWorkView> works;

  /// 선택된 작업 ID다. 작업이 있어도 선택 해제 상태일 수 있다.
  final OpenedWorkId? activeWorkId;
}
