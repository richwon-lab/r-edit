part of 'open_works.dart';

// 원래 실행 ID와 원래 Ready를 함께 소유한다. 최신 기준 재결합 경로는 없다.
final class _PendingGeometryChange {
  _PendingGeometryChange(this.workId, this.ready);
  final OpenedWorkId workId;
  final ReadyProductGeometryChange ready;
}

/// 특정 작업의 준비 호출 결과다. 정상 거부는 예외/AsyncError가 아니다.
sealed class WorkGeometryPreparation {
  WorkGeometryPreparation._(this.workId);

  /// 준비를 요청한 원래 작업의 실행 ID다.
  final OpenedWorkId workId;
}

/// 후보/기준 대신 확인 핸들과 표시 정보·요약만 공개한다.
final class GeometryChangeNeedsConfirmation extends WorkGeometryPreparation {
  GeometryChangeNeedsConfirmation._(
    super.workId,
    this.confirmationId,
    this.displayName,
    this.fileIdentity,
    this.summary,
  ) : super._();

  /// 확인/취소 중 한 번 소비할 수 있는 핸들이다.
  final GeometryChangeConfirmationId confirmationId;

  /// 준비 시점의 표시명이다. 실제 대상 조회에는 사용하지 않는다.
  final String displayName;

  /// 원래 접근 정보이며 실제 대상은 workId로만 찾는다.
  final WorkFileIdentity fileIdentity;

  /// 원문/후보를 포함하지 않는 workflow의 불변 요약이다.
  final ProductGeometryChangeSummary summary;
}

/// 호출자가 요청을 수정해야 하는 정상 준비 거부다.
final class GeometryChangeBlocked extends WorkGeometryPreparation {
  GeometryChangeBlocked._(super.workId, List<ProductGeometryChangeIssue> issues)
    : issues = List.unmodifiable(issues),
      super._();

  /// 하위 코드·경로·상세를 그대로 보존하는 수정 불가 진단이다.
  final List<ProductGeometryChangeIssue> issues;
}

/// 준비 당시의 무변경이다. 나중에 baseline을 현재 상태에 설치하지 않는다.
final class GeometryChangeUnchanged extends WorkGeometryPreparation {
  GeometryChangeUnchanged._(super.workId, this.summary) : super._();

  /// 준비 당시 해석한 불변 요약이다.
  final ProductGeometryChangeSummary summary;
}

/// 닫혔거나 다른 컨테이너에 속한 실행 ID로 준비를 요청했다.
final class GeometryChangeWorkNotOpen extends WorkGeometryPreparation {
  GeometryChangeWorkNotOpen._(super.workId) : super._();
}

/// 확인 한 번의 정상 결과다. UI 연결/파일 저장 성공을 뜻하지 않는다.
sealed class WorkGeometryConfirmation {
  WorkGeometryConfirmation._();
}

/// 원래 작업의 세션이 준비된 후보를 수락했다.
final class GeometryChangeApplied extends WorkGeometryConfirmation {
  GeometryChangeApplied._(this.workId, this.editState, this.summary)
    : super._();

  /// 실제 반영 대상이다. 현재 선택 작업과 다를 수 있다.
  final OpenedWorkId workId;

  /// 이 호출에서 확정한 관찰값이다. 화면의 최신 정본으로 재설치하지 않는다.
  final ProductDesignEditState editState;

  /// 준비 때 검토한 요약이다.
  final ProductGeometryChangeSummary summary;
}

/// workflow가 오래된 기준 등의 이유로 반영을 거부했다.
final class GeometryChangeRejected extends WorkGeometryConfirmation {
  GeometryChangeRejected._(
    this.workId,
    List<ProductGeometryChangeApplicationIssue> issues,
  ) : issues = List.unmodifiable(issues),
      super._();

  /// 거부한 원래 작업이다.
  final OpenedWorkId workId;

  /// 앱이 재해석하지 않은 원래 반영 진단이다.
  final List<ProductGeometryChangeApplicationIssue> issues;
}

/// 이미 끝난 대기나 닫힌 작업을 확인하려 한 정상 결과다.
final class GeometryChangeConfirmationUnavailable
    extends WorkGeometryConfirmation {
  GeometryChangeConfirmationUnavailable._(this.reason) : super._();

  /// 호출자가 대화를 종료할 수 있는 기계적 사유다.
  final WorkCommandOutcome reason;
}

/// 선택·닫기·취소 등의 정상 명령 결과다. 업무 검증/제작 판정이 아니다.
enum WorkCommandOutcome {
  /// 해당 작업을 선택했다. 세션과 개정은 유지한다.
  activated,

  /// 호출자가 닫기를 수락한 작업의 수명을 종료했다.
  closed,

  /// 대기만 제거했으며 구성/개정/선택은 유지했다.
  cancelled,

  /// 해당 실행 ID가 이 소유자에게 열려 있지 않다.
  workNoLongerOpen,

  /// 이미 소비·취소됐거나 이 소유자에게 없는 핸들이다.
  confirmationNotPending,
}
