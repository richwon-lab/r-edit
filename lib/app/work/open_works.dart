import 'package:r_edit/app/work/opened_work_view.dart';
import 'package:r_edit/app/work/work_file_identity.dart';
import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_works.g.dart';
part 'work_execution_ids.dart';
part 'geometry_change_confirmation.dart';

/// ProviderScope 안에서 열린 작업·세션·확인 대기를 소유한다.
/// 화면 구독 수명과 작업 수명은 독립적이며 raw 세션/상태 설치 경로를 공개하지 않는다.
@Riverpod(keepAlive: true)
class OpenWorks extends _$OpenWorks {
  final _works = <OpenedWorkId, _OwnedWork>{};
  final _fileKeys = <String, OpenedWorkId>{};
  final _pending = <GeometryChangeConfirmationId, _PendingGeometryChange>{};
  OpenedWorkId? _activeWorkId;
  bool _disposed = false;

  @override
  OpenWorksView build() {
    ref.onDispose(_closeOwnedSessions);
    return _observeCurrentWorks();
  }

  /// 유효 구성을 등록하고 선택한다. 같은 비교 키이면 기존 수명/표시명/구성을 유지한다.
  /// 파일 읽기·경로 검증은 수행하지 않는다. 이미 폐기된 소유자 호출은 StateError다.
  OpenedWorkId registerLoadedWork({
    required WorkFileIdentity fileIdentity,
    required String displayName,
    required ProductDesignConfiguration configuration,
  }) {
    _checkActiveOwner();
    final existing = _fileKeys[fileIdentity.comparisonKey];
    if (existing != null) {
      _activeWorkId = existing;
      _publishCurrentWorks();
      return existing;
    }
    final workId = OpenedWorkId._();
    final owned = _OwnedWork(
      fileIdentity,
      displayName,
      ProductDesignEditSession.open(configuration: configuration),
    );
    _works[workId] = owned;
    _fileKeys[fileIdentity.comparisonKey] = workId;
    _activeWorkId = workId;
    _publishCurrentWorks();
    return workId;
  }

  /// 선택만 변경한다. 없는 ID는 정상 거부하며 구성/개정을 바꾸지 않는다.
  WorkCommandOutcome activateWork(OpenedWorkId workId) {
    _checkActiveOwner();
    if (!_works.containsKey(workId)) return WorkCommandOutcome.workNoLongerOpen;
    _activeWorkId = workId;
    _publishCurrentWorks();
    return WorkCommandOutcome.activated;
  }

  /// 특정 private 세션에서 준비한다. Ready만 확인 대기에 보관하며 자동 반영하지 않는다.
  WorkGeometryPreparation prepareGeometryChange({
    required OpenedWorkId workId,
    required ProductGeometryChangeRequest request,
  }) {
    _checkActiveOwner();
    final work = _works[workId];
    if (work == null) return GeometryChangeWorkNotOpen._(workId);
    final preparation = work.session.prepareGeometryChange(request);
    switch (preparation) {
      case ReadyProductGeometryChange():
        final id = GeometryChangeConfirmationId._();
        _pending[id] = _PendingGeometryChange(workId, preparation);
        return GeometryChangeNeedsConfirmation._(
          workId,
          id,
          work.displayName,
          work.fileIdentity,
          preparation.summary,
        );
      case BlockedProductGeometryChange():
        return GeometryChangeBlocked._(workId, preparation.issues);
      case UnchangedProductGeometryChange():
        return GeometryChangeUnchanged._(workId, preparation.summary);
    }
  }

  /// 핸들 선소비→원래 작업 조회→동기 apply→최신 뷰 게시를 한 호출에서 완료한다.
  /// 기준 검사는 workflow가 수행한다. 예상 밖 실패는 catch/로깅/성공 변환하지 않는다.
  WorkGeometryConfirmation confirmGeometryChange(
    GeometryChangeConfirmationId id,
  ) {
    _checkActiveOwner();
    final pending = _pending.remove(id);
    if (pending == null) {
      return GeometryChangeConfirmationUnavailable._(
        WorkCommandOutcome.confirmationNotPending,
      );
    }
    final work = _works[pending.workId];
    if (work == null) {
      return GeometryChangeConfirmationUnavailable._(
        WorkCommandOutcome.workNoLongerOpen,
      );
    }
    final outcome = work.session.applyPreparedGeometryChange(pending.ready);
    final result = switch (outcome) {
      AppliedProductGeometryChange() => GeometryChangeApplied._(
        pending.workId,
        outcome.state,
        outcome.summary,
      ),
      RejectedProductGeometryChange() => GeometryChangeRejected._(
        pending.workId,
        outcome.issues,
      ),
    };
    _publishCurrentWorks();
    // 게시 listener가 재진입해도 이후 과거 state를 다시 대입하지 않는다.
    return result;
  }

  /// 대기만 한 번 제거한다. 선택·구성·개정은 변경하지 않는다.
  WorkCommandOutcome cancelGeometryChange(GeometryChangeConfirmationId id) {
    _checkActiveOwner();
    return _pending.remove(id) == null
        ? WorkCommandOutcome.confirmationNotPending
        : WorkCommandOutcome.cancelled;
  }

  /// 저장/닫기 판단이 최종 수락된 뒤 호출한다. 해당 실행 ID만 닫고 대기를 제거한다.
  /// 닫힌 작업이 선택돼 있었다면 선택을 해제한다. 파일 저장/종료 정책은 제공하지 않는다.
  WorkCommandOutcome closeWorkAfterDecision(OpenedWorkId workId) {
    _checkActiveOwner();
    final work = _works[workId];
    if (work == null) return WorkCommandOutcome.workNoLongerOpen;
    work.session.close();
    _works.remove(workId);
    _fileKeys.remove(work.fileIdentity.comparisonKey);
    _pending.removeWhere((_, pending) => identical(pending.workId, workId));
    if (identical(_activeWorkId, workId)) _activeWorkId = null;
    _publishCurrentWorks();
    return WorkCommandOutcome.closed;
  }

  OpenWorksView _observeCurrentWorks() => OpenWorksView(
    works: [
      for (final entry in _works.entries)
        OpenedWorkView(
          workId: entry.key,
          fileIdentity: entry.value.fileIdentity,
          displayName: entry.value.displayName,
          editState: entry.value.session.state,
        ),
    ],
    activeWorkId: _activeWorkId,
  );

  void _publishCurrentWorks() {
    state = _observeCurrentWorks();
  }

  void _checkActiveOwner() {
    if (_disposed) throw StateError('폐기된 열린 작업 소유자입니다.');
  }

  void _closeOwnedSessions() {
    _disposed = true;
    for (final work in _works.values) {
      work.session.close();
    }
    _pending.clear();
    _fileKeys.clear();
    _works.clear();
    _activeWorkId = null;
  }
}

final class _OwnedWork {
  _OwnedWork(this.fileIdentity, this.displayName, this.session);
  final WorkFileIdentity fileIdentity;
  final String displayName;
  final ProductDesignEditSession session;
}
