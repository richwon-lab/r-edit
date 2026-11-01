import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:r_edit/app/work/open_works.dart';
import 'package:r_edit/app/work/work_file_identity.dart';
import 'package:r_edit_workflow/r_edit_workflow.dart';

import '../support/work_configurations.dart';

void main() {
  late ProviderContainer container;
  late OpenWorks commands;
  late OpenedWorkId workId;
  setUp(() {
    container = ProviderContainer();
    commands = container.read(openWorksProvider.notifier);
    workId = commands.registerLoadedWork(
      fileIdentity: WorkFileIdentity(
        comparisonKey: 'A',
        originalAccessPath: 'A.work',
      ),
      displayName: 'A',
      configuration: twoProductsSharingGeometry(),
    );
  });
  tearDown(() => container.dispose());

  GeometryChangeNeedsConfirmation prepare({String proposedId = 'revised'}) =>
      commands.prepareGeometryChange(
        workId: workId,
        request: reviseSharedGeometry(proposedId: proposedId),
      ) as GeometryChangeNeedsConfirmation;

  test('B 선택 중 A의 확인은 A의 전체 구성만 변경하고 선택 B와 비대상 원문을 보존한다', () {
    final baseline = twoProductsSharingGeometry();
    final ticket = prepare();
    final otherId = commands.registerLoadedWork(
      fileIdentity: WorkFileIdentity(
        comparisonKey: 'B',
        originalAccessPath: 'B.work',
      ),
      displayName: 'B',
      configuration: baseline,
    );
    final outcome = commands.confirmGeometryChange(ticket.confirmationId);
    final view = container.read(openWorksProvider);
    final expected = ProductDesignConfiguration(
      appliedGeometries: [
        ...baseline.appliedGeometries,
        AppliedDesignGeometry(
          appliedGeometryId: 'revised',
          geometry: circularGeometryWithTextAreas(radius: 25),
        ),
      ],
      products: [
        baseline.products[0].copyWith(appliedGeometryId: 'revised'),
        baseline.products[1],
      ],
    );
    expect(outcome, isA<GeometryChangeApplied>());
    expect(view.activeWorkId, same(otherId));
    expect(view.works[0].editState.configuration, expected);
    expect(view.works[0].editState.revision, 1);
    expect(view.works[1].editState.configuration, baseline);
    expect(view.works[1].editState.revision, 0);
    expect(
      (outcome as GeometryChangeApplied).editState.configuration,
      expected,
    );
  });

  test('같은 기준의 두 핸들 중 두 번째는 workflow 진단으로 거부하고 구성·개정을 유지한다', () {
    final first = prepare();
    final second = prepare(proposedId: 'other');
    expect(first.confirmationId, isNot(same(second.confirmationId)));
    commands.confirmGeometryChange(first.confirmationId);
    final before = container.read(openWorksProvider);
    final rejected = commands.confirmGeometryChange(
      second.confirmationId,
    ) as GeometryChangeRejected;
    expect(
      rejected.issues.map((i) => i.code),
      unorderedEquals([
        ProductGeometryChangeApplicationCode.staleEditRevision,
        ProductGeometryChangeApplicationCode.baselineConfigurationMismatch,
      ]),
    );
    expect(container.read(openWorksProvider), before);
    expect(() => rejected.issues.clear(), throwsUnsupportedError);
  });

  test('같은 핸들은 한 번만 반영하고 중복 확인은 정상 종료한다', () {
    final ticket = prepare();
    commands.confirmGeometryChange(ticket.confirmationId);
    final before = container.read(openWorksProvider);
    final repeated = commands.confirmGeometryChange(
      ticket.confirmationId,
    ) as GeometryChangeConfirmationUnavailable;
    expect(repeated.reason, WorkCommandOutcome.confirmationNotPending);
    expect(container.read(openWorksProvider), before);
  });

  test('취소는 대기만 제거하고 구성·개정·선택을 보존한다', () {
    final before = container.read(openWorksProvider);
    final ticket = prepare();
    expect(
      commands.cancelGeometryChange(ticket.confirmationId),
      WorkCommandOutcome.cancelled,
    );
    expect(container.read(openWorksProvider), same(before));
    expect(
      commands.cancelGeometryChange(ticket.confirmationId),
      WorkCommandOutcome.confirmationNotPending,
    );
    expect(
      (commands.confirmGeometryChange(
        ticket.confirmationId,
      ) as GeometryChangeConfirmationUnavailable).reason,
      WorkCommandOutcome.confirmationNotPending,
    );
  });

  test('Blocked는 원래 코드·경로·상세를 보존하고 유효 구성을 교체하지 않는다', () {
    final before = container.read(openWorksProvider);
    final blocked = commands.prepareGeometryChange(
      workId: workId,
      request: reviseSharedGeometry(productIds: ['없는 제품']),
    ) as GeometryChangeBlocked;
    expect(blocked.issues.single.fieldPath, 'request.targets[0].productId');
    expect(blocked.issues.single.details, isA<ChangeTargetDetails>());
    expect(() => blocked.issues.clear(), throwsUnsupportedError);
    expect(container.read(openWorksProvider), same(before));
  });

  test('동일한 유효 변경 요청은 Unchanged이며 후속 확인 대기를 만들지 않는다', () {
    final before = container.read(openWorksProvider);
    final unchanged = commands.prepareGeometryChange(
      workId: workId,
      request: ReviseAppliedGeometry(
        sourceAppliedGeometryId: 'original',
        proposedGeometry:
            before.works.single.editState.configuration.appliedGeometries.first,
        targets: [
          ProductGeometryTarget(
            productId: 'A',
            areaMappings: [],
            newTextInputs: [],
            removedInputAreaIds: [],
          ),
        ],
      ),
    );
    expect(unchanged, isA<GeometryChangeUnchanged>());
    expect(container.read(openWorksProvider), same(before));
  });

  test('복수 제품 변경은 하나의 새 스냅샷을 공유하며 각 원문과 지정 줄을 보존한다', () {
    final baseline = twoProductsSharingGeometry();
    final ready = commands.prepareGeometryChange(
      workId: workId,
      request: reviseSharedGeometry(productIds: ['B', 'A']),
    ) as GeometryChangeNeedsConfirmation;
    commands.confirmGeometryChange(ready.confirmationId);
    final expected = ProductDesignConfiguration(
      appliedGeometries: [
        ...baseline.appliedGeometries,
        AppliedDesignGeometry(
          appliedGeometryId: 'revised',
          geometry: circularGeometryWithTextAreas(radius: 25),
        ),
      ],
      products: [
        baseline.products[0].copyWith(appliedGeometryId: 'revised'),
        baseline.products[1].copyWith(appliedGeometryId: 'revised'),
      ],
    );
    expect(
      container.read(openWorksProvider).works.single.editState.configuration,
      expected,
    );
    expect(
      baseline.products.first.textInputs.first.sourceText,
      ' A e\u0301🙂 ',
    );
  });

  test('기존 스냅샷 교체는 슬롯을 재사용하고 명시 대응 순서로 입력을 재정렬하지 않는다', () {
    final baseline = twoProductsSharingGeometry();
    final ticket = commands.prepareGeometryChange(
      workId: workId,
      request: ReplaceAppliedGeometry(
        proposedGeometry: baseline.appliedGeometries[1],
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
    commands.confirmGeometryChange(ticket.confirmationId);
    expect(
      container.read(openWorksProvider).works.single.editState.configuration,
      ProductDesignConfiguration(
        appliedGeometries: baseline.appliedGeometries,
        products: [
          baseline.products[0].copyWith(appliedGeometryId: 'unused'),
          baseline.products[1],
        ],
      ),
    );
  });

  test('새 영역 입력은 유지 입력 뒤에 요청 순서로 붙고 외부 목록 변경이 준비 요약을 바꾸지 않는다', () {
    final baseline = twoProductsSharingGeometry();
    final geometry = circularGeometryWithTextAreas(radius: 25);
    final proposed = AppliedDesignGeometry(
      appliedGeometryId: 'new-areas',
      geometry: geometry.copyWith(
        textAreas: [
          ...geometry.textAreas,
          TextAreaDefinition(
            areaId: 'new-1',
            label: '',
            region: geometry.textAreas.first.region,
          ),
          TextAreaDefinition(
            areaId: 'new-2',
            label: '',
            region: geometry.textAreas.first.region,
          ),
        ],
      ),
    );
    final newSecond = TextAreaInput(
      areaId: 'new-2',
      sourceText: 'NEW 2',
      lineBreak: const AutomaticLineBreak(),
    );
    final newFirst = TextAreaInput(
      areaId: 'new-1',
      sourceText: ' 새 입력 ',
      lineBreak: SpecifiedLineBreak([' 새 입력 ']),
    );
    final inputs = [newSecond, newFirst];
    final targets = [
      ProductGeometryTarget(
        productId: 'A',
        areaMappings: [],
        newTextInputs: inputs,
        removedInputAreaIds: [],
      ),
    ];
    final request = ReviseAppliedGeometry(
      sourceAppliedGeometryId: 'original',
      proposedGeometry: proposed,
      targets: targets,
    );
    final ticket = commands.prepareGeometryChange(
      workId: workId,
      request: request,
    ) as GeometryChangeNeedsConfirmation;
    inputs.clear();
    targets.clear();
    expect(ticket.summary.products.single.newInputAreaIds, ['new-2', 'new-1']);
    expect(() => ticket.summary.products.clear(), throwsUnsupportedError);
    commands.confirmGeometryChange(ticket.confirmationId);
    expect(
      container.read(openWorksProvider).works.single.editState.configuration,
      ProductDesignConfiguration(
        appliedGeometries: [...baseline.appliedGeometries, proposed],
        products: [
          baseline.products[0].copyWith(
            appliedGeometryId: 'new-areas',
            textInputs: [
              ...baseline.products[0].textInputs,
              newSecond,
              newFirst,
            ],
          ),
          baseline.products[1],
        ],
      ),
    );
  });
}
