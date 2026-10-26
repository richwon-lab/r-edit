import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:r_edit/app/logging/rotating_file_log.dart';

void main() {
  late Directory directory;
  final sinks = <RotatingFileLog>[];
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('r_edit_log_test_');
  });
  tearDown(() async {
    for (final sink in sinks) {
      await sink.close();
    }
    sinks.clear();
    // createTemp가 반환한 단일 격리 디렉터리만 정리한다.
    expect(directory.parent.absolute.path, Directory.systemTemp.absolute.path);
    await directory.delete(recursive: true);
  });

  group('파일 로그의 보관 한도', () {
    test('회전 후 활성 파일을 포함한 파일 수와 각 크기를 제한한다', () async {
      final sink = await RotatingFileLog.open(
        directory,
        maxFileBytes: 256,
        maxRecordBytes: 128,
      );
      sinks.add(sink);
      for (var i = 0; i < 80; i++) {
        sink.add(jsonEncode({'event': 'test', 'index': i}));
        await sink.flush();
      }
      final files = directory.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.jsonl'),
      );
      expect(files.length, 3);
      expect(
        files.map((file) => file.lengthSync()),
        everyElement(lessThanOrEqualTo(256)),
      );
      expect(
        files.fold<int>(0, (total, file) => total + file.lengthSync()),
        lessThanOrEqualTo(768),
      );
      for (final file in files) {
        for (final line in await file.readAsLines()) {
          expect(jsonDecode(line), isA<Map<String, dynamic>>());
        }
      }
    });

    test('큰 다중 바이트 기록은 내용 없이 제한된 요약으로 대체한다', () async {
      final sink = await RotatingFileLog.open(
        directory,
        maxFileBytes: 256,
        maxRecordBytes: 128,
      );
      sinks.add(sink);
      sink.add('한글' * 10000);
      await sink.flush();
      final file = File(sink.activeFilePath!);
      expect(await file.length(), lessThanOrEqualTo(128));
      expect(jsonDecode((await file.readAsString()).trim()), {
        'event': 'log.record_truncated',
      });
    });

    test('지연된 쓰기 중 대기열 초과 기록을 버리고 정상 종료는 남은 큐를 배출한다', () async {
      final gate = Completer<void>();
      final sink = await RotatingFileLog.open(
        directory,
        maxPendingRecords: 2,
        writeBytes: (file, bytes) async {
          await gate.future;
          await file.writeFrom(bytes);
        },
      );
      sinks.add(sink);
      for (var i = 0; i < 100; i++) {
        sink.add('{"event":"test"}');
      }
      expect(sink.droppedCount, greaterThan(0));
      final path = sink.activeFilePath!;
      gate.complete();
      await sink.close();
      expect((await File(path).readAsLines()).length, lessThanOrEqualTo(3));
      final size = await File(path).length();
      sink.add('after.close');
      await sink.close();
      expect(await File(path).length(), size);
    });

    test('파일 쓰기 실패는 한 번만 대체 보고하고 후속 호출과 종료를 실패시키지 않는다', () async {
      var fallbacks = 0;
      var writes = 0;
      final sink = await RotatingFileLog.open(
        directory,
        onUnavailable: () => fallbacks++,
        writeBytes: (_, _) async {
          writes++;
          throw const FileSystemException('비공개 외부 오류');
        },
      );
      sinks.add(sink);
      sink.add('{"event":"test"}');
      await sink.flush();
      sink.add('{"event":"next"}');
      await sink.close();
      expect(fallbacks, 1);
      expect(writes, 1);
    });
  });

  test('동시 프로세스는 서로 다른 슬롯을 잠그고 네 번째 파일을 만들지 않는다', () async {
    final processes = <Process>[];
    try {
      final slots = <String>[];
      final dart = File(
        '.fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}',
      ).absolute.path;
      for (var i = 0; i < 4; i++) {
        final process = await Process.start(dart, [
          'test/support/log_writer_process.dart',
          directory.path,
        ]);
        processes.add(process);
        slots.add(
          await process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .first
              .timeout(const Duration(seconds: 20)),
        );
      }
      expect(slots.take(3).toSet().length, 3);
      expect(slots.take(3), everyElement(isNot('unavailable')));
      expect(slots.last, 'unavailable');
      expect(
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.jsonl'))
            .length,
        3,
      );
    } finally {
      for (final process in processes) {
        process.stdin.writeln('close');
        await process.stdin.close();
        expect(await process.exitCode.timeout(const Duration(seconds: 20)), 0);
      }
    }
  });
}
