import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/generated_sources.dart';

void main() {
  late Directory root;
  late File generated;

  Future<void> git(List<String> args) async {
    final result = await Process.run('git', ['-C', root.path, ...args]);
    if (result.exitCode != 0) throw StateError('Git 준비 실패: ${result.stderr}');
  }

  Future<void> commitFixture() async {
    await git(['add', '.']);
    await git([
      '-c',
      'user.name=Generated source test',
      '-c',
      'user.email=generated-test@example.invalid',
      'commit',
      '-qm',
      'fixture',
    ]);
  }

  Matcher gitFailure(String path) => throwsA(
    isA<StateError>().having((error) => error.message, '오류 경로', contains(path)),
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('r-edit-generated-');
    generated = File('${root.path}/lib/nested/value.g.dart');
    await generated.create(recursive: true);
    await generated.writeAsString('// generated baseline\n');
    await git(['init', '-q']);
    await commitFixture();
  });

  tearDown(() async {
    final parent = root.parent.resolveSymbolicLinksSync();
    final temporary = Directory.systemTemp.resolveSymbolicLinksSync();
    if (parent != temporary ||
        !root.path
            .split(Platform.pathSeparator)
            .last
            .startsWith('r-edit-generated-')) {
      throw StateError('임시 저장소 삭제 범위 불일치');
    }
    await root.delete(recursive: true);
  });

  group('생성 소스 시작 상태와 재생성 결과', () {
    test('같은 경로와 바이트이면 통과한다', () {
      final before = snapshotGeneratedSources(root);
      checkGeneratedSourcesUnchanged(
        before,
        snapshotGeneratedSources(root),
        phase: '첫 생성',
      );
    });

    test('로컬 생성 소스가 HEAD와 달라도 생성 전후가 같으면 통과한다', () {
      generated.writeAsStringSync('// valid new generated value\n');
      final before = snapshotGeneratedSources(root);
      checkGeneratedSourcesUnchanged(
        before,
        snapshotGeneratedSources(root),
        phase: '첫 생성',
      );
    });

    for (final change in ['수정', '추가', '삭제']) {
      test('$change 발생 시 단계·파일 경로·재생성 명령과 함께 실패한다', () {
        final before = snapshotGeneratedSources(root);
        var path = 'lib/nested/value.g.dart';
        if (change == '수정') {
          generated.writeAsStringSync('// regenerated\n');
        } else if (change == '추가') {
          path = 'lib/nested/value.freezed.dart';
          File('${root.path}/$path').writeAsStringSync('// new\n');
        } else {
          generated.deleteSync();
        }
        expect(
          () => checkGeneratedSourcesUnchanged(
            before,
            snapshotGeneratedSources(root),
            phase: '첫 생성',
          ),
          throwsA(
            isA<StateError>()
                .having((error) => error.message, '단계', contains('첫 생성'))
                .having((error) => error.message, '경로', contains(path))
                .having(
                  (error) => error.message,
                  '복구 명령',
                  contains('fvm dart run build_runner build'),
                ),
          ),
        );
      });
    }

    test('반복 생성에서 내용이 바뀌면 안정성 실패로 구분한다', () {
      final before = snapshotGeneratedSources(root);
      generated.writeAsStringSync('// unstable\n');
      expect(
        () => checkGeneratedSourcesUnchanged(
          before,
          snapshotGeneratedSources(root),
          phase: '반복 생성 안정성',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            '단계',
            contains('반복 생성 안정성'),
          ),
        ),
      );
    });
  });

  group('CI 생성 소스 Git 포함 검사', () {
    test('추적된 정상 생성 소스는 관계없는 변경·lock과 무관하게 통과한다', () async {
      File('${root.path}/pubspec.lock').writeAsStringSync('unrelated');
      File('${root.path}/lib/hand_written.dart')
          .writeAsStringSync('// unrelated');
      await checkGeneratedSourcesInGit(root);
    });

    test('추적 중인 생성 소스의 내용 변경을 거부한다', () async {
      generated.writeAsStringSync('// modified\n');
      await expectLater(
        checkGeneratedSourcesInGit(root),
        gitFailure('lib/nested/value.g.dart'),
      );
    });

    test('추적 중인 생성 소스의 삭제를 거부한다', () async {
      generated.deleteSync();
      await expectLater(
        checkGeneratedSourcesInGit(root),
        gitFailure('lib/nested/value.g.dart'),
      );
    });

    test('무시되지 않은 미추적 생성 소스를 거부한다', () async {
      File('${root.path}/lib/new.g.dart').writeAsStringSync('// new\n');
      await expectLater(
        checkGeneratedSourcesInGit(root),
        gitFailure('lib/new.g.dart'),
      );
    });

    test('gitignore에 숨겨진 미추적 생성 소스도 거부한다', () async {
      File('${root.path}/.gitignore').writeAsStringSync('*.freezed.dart\n');
      File('${root.path}/lib/hidden.freezed.dart')
          .writeAsStringSync('// ignored\n');
      await expectLater(
        checkGeneratedSourcesInGit(root),
        gitFailure('lib/hidden.freezed.dart'),
      );
    });

    test('stage만 된 생성 소스도 HEAD에 없으면 CI에서 거부한다', () async {
      File('${root.path}/lib/staged.g.dart').writeAsStringSync('// staged\n');
      await git(['add', 'lib/staged.g.dart']);
      await expectLater(
        checkGeneratedSourcesInGit(root),
        gitFailure('lib/staged.g.dart'),
      );
    });
  });
}
