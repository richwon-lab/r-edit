import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:r_edit/app/work/open_works.dart';
import 'package:r_edit/app/work/work_file_identity.dart';

import '../support/work_configurations.dart';

void main() {
  group('OpenWorks 등록과 선택', () {
    late ProviderContainer container;
    late OpenWorks commands;
    setUp(() {
      container = ProviderContainer();
      commands = container.read(openWorksProvider.notifier);
    });
    tearDown(() => container.dispose());

    test('같은 키의 재등록은 반영된 구성·세션·개정과 원래 표시 정보를 유지한다', () {
      final initial = twoProductsSharingGeometry();
      final id = commands.registerLoadedWork(
        fileIdentity: WorkFileIdentity(
          comparisonKey: 'key-A',
          originalAccessPath: '원래 접근',
        ),
        displayName: '원래 이름',
        configuration: initial,
      );
      final ticket = commands.prepareGeometryChange(
        workId: id,
        request: reviseSharedGeometry(),
      ) as GeometryChangeNeedsConfirmation;
      commands.confirmGeometryChange(ticket.confirmationId);
      final before = container.read(openWorksProvider).works.single;
      final reused = commands.registerLoadedWork(
        fileIdentity: WorkFileIdentity(
          comparisonKey: 'key-A',
          originalAccessPath: '다른 접근',
        ),
        displayName: '덮어쓸 이름',
        configuration: initial,
      );
      final after = container.read(openWorksProvider).works.single;
      expect(reused, same(id));
      expect(after, before);
      expect(after.editState.revision, 1);
      expect(after.editState.sessionId, same(before.editState.sessionId));
      expect(after.displayName, '원래 이름');
      expect(after.fileIdentity.originalAccessPath, '원래 접근');
    });

    test('표시명이 같아도 서로 다른 키는 별도 작업·세션이며 선택만 바뀐다', () {
      final initial = twoProductsSharingGeometry();
      final first = commands.registerLoadedWork(
        fileIdentity: WorkFileIdentity(
          comparisonKey: 'A',
          originalAccessPath: '같은 경로',
        ),
        displayName: '동명',
        configuration: initial,
      );
      final second = commands.registerLoadedWork(
        fileIdentity: WorkFileIdentity(
          comparisonKey: 'a',
          originalAccessPath: '같은 경로',
        ),
        displayName: '동명',
        configuration: initial,
      );
      final before = container.read(openWorksProvider);
      expect(first, isNot(same(second)));
      expect(
        before.works[0].editState.sessionId,
        isNot(same(before.works[1].editState.sessionId)),
      );
      expect(commands.activateWork(first), WorkCommandOutcome.activated);
      expect(container.read(openWorksProvider).works, before.works);
      expect(container.read(openWorksProvider).activeWorkId, same(first));
    });

    test('관찰 목록을 외부에서 수정할 수 없고 이전 관찰값은 등록 후에도 변하지 않는다', () {
      final empty = container.read(openWorksProvider);
      commands.registerLoadedWork(
        fileIdentity: WorkFileIdentity(
          comparisonKey: 'A',
          originalAccessPath: 'path',
        ),
        displayName: '',
        configuration: twoProductsSharingGeometry(),
      );
      final current = container.read(openWorksProvider);
      expect(() => current.works.clear(), throwsUnsupportedError);
      expect(empty.works, isEmpty);
      expect(empty.activeWorkId, isNull);
    });
  });

  group('WorkFileIdentity의 전달 경계', () {
    for (final field in ['comparisonKey', 'originalAccessPath']) {
      test('$field 빈 값은 인자명과 문제 값을 가진 오류로 거부한다', () {
        expect(
          () => WorkFileIdentity(
            comparisonKey: field == 'comparisonKey' ? '' : 'key',
            originalAccessPath: field == 'originalAccessPath' ? '' : 'path',
          ),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, '인자명', field)
                .having((e) => e.invalidValue, '문제 값', ''),
          ),
        );
      });
    }
    test('공백·대소문자·Unicode를 정규화하거나 경로로 해석하지 않는다', () {
      final identity = WorkFileIdentity(
        comparisonKey: ' A e\u0301 ',
        originalAccessPath: ' 상대/경로 ',
      );
      expect(identity.comparisonKey, ' A e\u0301 ');
      expect(identity.originalAccessPath, ' 상대/경로 ');
    });
  });
}
