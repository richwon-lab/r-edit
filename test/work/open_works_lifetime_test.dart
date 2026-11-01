import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:r_edit/app/work/open_works.dart';
import 'package:r_edit/app/work/opened_work_view.dart';
import 'package:r_edit/app/work/work_file_identity.dart';
import 'package:r_edit_workflow/r_edit_workflow.dart';

import '../support/work_configurations.dart';

void main() {
  OpenedWorkId register(OpenWorks owner) => owner.registerLoadedWork(
    fileIdentity: WorkFileIdentity(
      comparisonKey: 'A',
      originalAccessPath: 'A.work',
    ),
    displayName: 'A',
    configuration: twoProductsSharingGeometry(),
  );

  test('닫기·같은 파일 재등록은 새 실행 ID/세션을 만들고 옛 핸들을 무효화한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final owner = container.read(openWorksProvider.notifier);
    final first = register(owner);
    final oldView = container.read(openWorksProvider);
    final ticket = owner.prepareGeometryChange(
      workId: first,
      request: reviseSharedGeometry(),
    ) as GeometryChangeNeedsConfirmation;
    expect(owner.closeWorkAfterDecision(first), WorkCommandOutcome.closed);
    expect(container.read(openWorksProvider).activeWorkId, isNull);
    expect(owner.activateWork(first), WorkCommandOutcome.workNoLongerOpen);
    expect(
      owner.prepareGeometryChange(
        workId: first,
        request: reviseSharedGeometry(),
      ),
      isA<GeometryChangeWorkNotOpen>(),
    );
    expect(
      owner.closeWorkAfterDecision(first),
      WorkCommandOutcome.workNoLongerOpen,
    );
    final reopened = register(owner);
    final current = container.read(openWorksProvider);
    expect(reopened, isNot(same(first)));
    expect(
      current.works.single.editState.sessionId,
      isNot(same(oldView.works.single.editState.sessionId)),
    );
    expect(
      (owner.confirmGeometryChange(
        ticket.confirmationId,
      ) as GeometryChangeConfirmationUnavailable).reason,
      WorkCommandOutcome.confirmationNotPending,
    );
    expect(current.works.single.editState.revision, 0);
    expect(oldView.works.single.editState.isClosed, isFalse);
  });

  test('구독 해제·재구독은 동일 작업과 세션을 유지하고 반영 전체 값을 통지한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final owner = container.read(openWorksProvider.notifier);
    final id = register(owner);
    final before = container.read(openWorksProvider);
    final subscription = container.listen(openWorksProvider, (_, _) {});
    subscription.close();
    final observed = <OpenWorksView>[];
    container.listen(
      openWorksProvider,
      (_, next) => observed.add(next),
      fireImmediately: true,
    );
    final ticket = owner.prepareGeometryChange(
      workId: id,
      request: reviseSharedGeometry(),
    ) as GeometryChangeNeedsConfirmation;
    final outcome = owner.confirmGeometryChange(
      ticket.confirmationId,
    ) as GeometryChangeApplied;
    expect(observed.first, same(before));
    expect(
      observed.last.works.single.editState.configuration,
      outcome.editState.configuration,
    );
    expect(observed.last.works.single.editState.revision, 1);
    expect(
      observed.last.works.single.editState.sessionId,
      same(before.works.single.editState.sessionId),
    );
    expect(before.works.single.editState.revision, 0);
  });

  test('게시 listener가 후속 변경을 반영해도 과거 outcome으로 최신 관찰값을 덮어쓰지 않는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final owner = container.read(openWorksProvider.notifier);
    final id = register(owner);
    var entered = false;
    container.listen(openWorksProvider, (_, next) {
      if (entered || next.works.single.editState.revision != 1) return;
      entered = true;
      // 기존 미사용 스냅샷으로 명시 교체한다. 현재 도안에서 모든 영역을 대응한다.
      final ticket = owner.prepareGeometryChange(
        workId: id,
        request: ReplaceAppliedGeometry(
          proposedGeometry:
              next.works.single.editState.configuration.appliedGeometries[1],
          targets: [
            ProductGeometryTarget(
              productId: 'A',
              areaMappings: [
                const TextAreaInputMapping(
                  fromAreaId: 'first',
                  toAreaId: 'first',
                ),
                const TextAreaInputMapping(
                  fromAreaId: 'second',
                  toAreaId: 'second',
                ),
              ],
              newTextInputs: [],
              removedInputAreaIds: [],
            ),
          ],
        ),
      ) as GeometryChangeNeedsConfirmation;
      owner.confirmGeometryChange(ticket.confirmationId);
    });
    final first = owner.prepareGeometryChange(
      workId: id,
      request: reviseSharedGeometry(),
    ) as GeometryChangeNeedsConfirmation;
    final outcome = owner.confirmGeometryChange(
      first.confirmationId,
    ) as GeometryChangeApplied;
    expect(entered, isTrue);
    expect(outcome.editState.revision, 1);
    final latest = container.read(openWorksProvider).works.single.editState;
    expect(latest.revision, 2);
    final baseline = twoProductsSharingGeometry();
    expect(
      latest.configuration,
      baseline.copyWith(
        appliedGeometries: [
          ...baseline.appliedGeometries,
          reviseSharedGeometry().proposedGeometry,
        ],
        products: [
          baseline.products[0].copyWith(appliedGeometryId: 'unused'),
          baseline.products[1],
        ],
      ),
    );
  });

  test('컨테이너는 작업·토큰·확인 대기를 공유하지 않으며 최종 폐기 후 명령을 거부한다', () {
    final firstContainer = ProviderContainer();
    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    final firstOwner = firstContainer.read(openWorksProvider.notifier);
    final secondOwner = secondContainer.read(openWorksProvider.notifier);
    final firstId = register(firstOwner);
    final secondId = register(secondOwner);
    final old = firstContainer.read(openWorksProvider);
    expect(secondId, isNot(same(firstId)));
    expect(
      secondContainer.read(openWorksProvider).works.single.editState.sessionId,
      isNot(same(old.works.single.editState.sessionId)),
    );
    final ticket = firstOwner.prepareGeometryChange(
      workId: firstId,
      request: reviseSharedGeometry(),
    ) as GeometryChangeNeedsConfirmation;
    expect(
      (secondOwner.confirmGeometryChange(
        ticket.confirmationId,
      ) as GeometryChangeConfirmationUnavailable).reason,
      WorkCommandOutcome.confirmationNotPending,
    );
    firstContainer.dispose();
    expect(
      () => firstOwner.confirmGeometryChange(ticket.confirmationId),
      throwsStateError,
    );
    expect(() => firstOwner.activateWork(firstId), throwsStateError);
    expect(
      secondContainer.read(openWorksProvider).works.single.editState.revision,
      0,
    );
    expect(old.works.single.editState.revision, 0);
  });
}
