import 'dart:convert';
import 'dart:io';

import 'generated_sources.dart';

/// 고정 SDK로 생성·분석·테스트·소비자를 검사한다. 인덱스는 변경하지 않는다.
Future<void> main(List<String> arguments) async {
  final root = File.fromUri(Platform.script).parent.parent;
  Directory.current = root;
  final app = const LineSplitter()
      .convert(File('pubspec.yaml').readAsStringSync())
      .contains('name: r_edit');
  final windows = Platform.isWindows;
  final extension = windows ? '.exe' : '';
  final sdk = Directory('.fvm/flutter_sdk');
  if (!sdk.existsSync()) {
    throw StateError('먼저 FVM으로 .fvmrc의 SDK를 연결하세요.');
  }
  final sdkPath = sdk.absolute.path;
  final rootPath = root.path;
  final dart = '$sdkPath/bin/cache/dart-sdk/bin/dart$extension';
  final flutterExtension = windows ? '.bat' : '';
  final flutter = '$sdkPath/bin/flutter$flutterExtension';
  final environment = <String, String>{
    'PUB_CACHE':
        Platform.environment['PUB_CACHE'] ?? '$rootPath/.tooling/pub-cache',
  };
  Future<void> run(
    String executable,
    List<String> args, {
    String? directory,
  }) async {
    final command = args.join(' ');
    stdout.writeln('> $executable $command');
    final process = await Process.start(
      executable,
      args,
      workingDirectory: directory ?? root.path,
      environment: environment,
      runInShell: windows && executable.endsWith('.bat'),
      mode: ProcessStartMode.inheritStdio,
    );
    final result = await process.exitCode;
    if (result != 0) throw StateError('검증 실패(exit=$result): $args');
  }

  final initialGenerated = snapshotGeneratedSources(root);

  final pub = app ? flutter : dart;
  await run(pub, ['pub', 'get']);
  await run(dart, ['run', 'build_runner', 'build']);
  checkGeneratedSourcesUnchanged(
    initialGenerated,
    snapshotGeneratedSources(root),
    phase: '검증 시작 상태와 첫 생성 결과의 일치 검사',
  );
  final formatPaths = <String>[
    'lib',
    'test',
    'tool/verify.dart',
    'tool/generated_sources.dart',
    if (Directory('example').existsSync()) 'example',
    for (final file in Directory('tool').listSync().whereType<File>())
      if (file.path.endsWith('_release.dart')) file.path,
  ];
  await run(dart, [
    'format',
    '--output=none',
    '--set-exit-if-changed',
    ...formatPaths,
  ]);
  final before = snapshotGeneratedSources(root);
  await run(dart, ['run', 'build_runner', 'build']);
  checkGeneratedSourcesUnchanged(
    before,
    snapshotGeneratedSources(root),
    phase: '반복 생성 안정성 검사',
  );
  if (arguments.contains('--ci') ||
      Platform.environment['GITHUB_ACTIONS'] == 'true') {
    await checkGeneratedSourcesInGit(root);
  }
  await run(pub, ['analyze']);
  await run(pub, ['test']);
  if (app) {
    if (arguments.contains('--windows')) {
      if (!windows) throw StateError('Windows 빌드는 Windows에서 실행하세요.');
      await run(flutter, ['build', 'windows', '--debug']);
    }
  } else {
    Directory('build').createSync();
    for (final file in Directory('tool').listSync().whereType<File>()) {
      if (!file.path.endsWith('_release.dart')) continue;
      final name = file.uri.pathSegments.last.replaceAll('.dart', '');
      final output = 'build/$name$extension';
      await run(dart, ['compile', 'exe', file.path, '-o', output]);
      await run(File(output).absolute.path, []);
    }
    final consumer = Directory('build/foundation_consumer')
      ..createSync(recursive: true);
    final consumerPath = consumer.path;
    Directory('$consumerPath/bin').createSync();
    File('$consumerPath/pubspec.yaml').writeAsStringSync(
      'name: foundation_consumer\n'
      'environment:\n  sdk: ^3.13.5\n'
      'dependencies:\n  r_edit_workflow:\n    path: ../..\n',
    );
    File('example/product_configuration.dart')
        .copySync('$consumerPath/bin/main.dart');
    await run(dart, ['pub', 'get'], directory: consumer.absolute.path);
    final config = jsonDecode(
      File('$consumerPath/.dart_tool/package_config.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final packages = config['packages']! as List<Object?>;
    const generators = {'build_runner', 'freezed', 'json_serializable'};
    if (packages.any(
      (p) => generators.contains((p! as Map<String, Object?>)['name']),
    )) {
      throw StateError('소비자에 생성 도구가 전파됐습니다.');
    }
    final output = 'consumer$extension';
    await run(dart, [
      'compile',
      'exe',
      'bin/main.dart',
      '-o',
      output,
    ], directory: consumer.absolute.path);
    await run(File('$consumerPath/$output').absolute.path, []);
  }
  stdout.writeln('로컬 검증 완료. 원격 CI·배치·제작 검증은 별도입니다.');
}
