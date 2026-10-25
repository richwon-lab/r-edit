import 'dart:convert';
import 'dart:io';

/// lib의 관리 대상 생성 소스를 상대 경로와 원본 바이트로 기록한다.
Map<String, String> snapshotGeneratedSources(Directory root) {
  final base = root.absolute;
  return {
    for (final file in Directory(
      '${base.path}/lib',
    ).listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.g.dart') || file.path.endsWith('.freezed.dart'))
        file.path.substring(base.path.length + 1).replaceAll(r'\', '/'):
            base64Encode(file.readAsBytesSync()),
  };
}

/// 추가·삭제·내용 변경을 구분한다. 생성기가 파일을 고쳐도 검사는 실패한다.
void checkGeneratedSourcesUnchanged(
  Map<String, String> before,
  Map<String, String> after, {
  required String phase,
}) {
  final paths = {...before.keys, ...after.keys}.toList()..sort();
  final changes = <String>[
    for (final path in paths)
      if (!before.containsKey(path))
        '추가: $path'
      else if (!after.containsKey(path))
        '삭제: $path'
      else if (before[path] != after[path])
        '내용 변경: $path',
  ];
  if (changes.isEmpty) return;
  throw StateError(
    '$phase 실패\n${changes.join('\n')}\n'
    '생성기가 작업 파일을 갱신했을 수 있지만 검증 통과는 아닙니다.\n'
    '재생성: fvm dart run build_runner build\n'
    '생성 결과를 검토한 뒤 fvm dart tool/verify.dart를 다시 실행하세요.',
  );
}

/// CI 전용으로 생성 소스의 HEAD 대비 차이와 미추적 파일을 검사한다.
///
/// 무시된 생성 파일도 검사하며, 다른 소스와 라이브러리 lock은 제외한다.
/// 읽기 전용 Git 명령만 사용한다. 로컬 기본 검증에서는 호출하지 않는다.
Future<void> checkGeneratedSourcesInGit(Directory root) async {
  const paths = [':(glob)lib/**/*.g.dart', ':(glob)lib/**/*.freezed.dart'];
  Future<Set<String>> gitPaths(List<String> arguments) async {
    final result = await Process.run('git', [
      '-C',
      root.absolute.path,
      ...arguments,
    ]);
    if (result.exitCode != 0) {
      throw StateError('생성 소스 Git 검사 실패: ${result.stderr}');
    }
    return (result.stdout as String)
        .split('\u0000')
        .where((path) => path.isNotEmpty)
        .toSet();
  }

  final changed = await gitPaths([
    'diff',
    '--name-only',
    '-z',
    'HEAD',
    '--',
    ...paths,
  ]);
  final tracked = await gitPaths([
    'ls-files',
    '--cached',
    '-z',
    '--',
    ...paths,
  ]);
  final untracked = snapshotGeneratedSources(root).keys
      .toSet()
      .difference(tracked);
  final details = [
    for (final path in changed.toList()..sort()) 'HEAD 대비 변경·추가·삭제: $path',
    for (final path in untracked.toList()..sort()) 'Git 미포함 생성 소스: $path',
  ];
  if (details.isEmpty) return;
  throw StateError(
    'CI 생성 소스 Git 포함 검사 실패\n${details.join('\n')}\n'
    '재생성: fvm dart run build_runner build\n'
    '결과를 검토하고 필요한 생성 소스를 Git에 포함한 뒤 CI를 다시 실행하세요.\n'
    '검사 도구는 stage·commit·복구·삭제를 수행하지 않습니다.',
  );
}
