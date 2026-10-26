import 'dart:convert';
import 'dart:io';

import 'package:r_edit/app/logging/rotating_file_log.dart';

/// OS lock을 별도 프로세스에서 검증하는 테스트 전용 진입점이다.
Future<void> main(List<String> arguments) async {
  RotatingFileLog? sink;
  try {
    sink = await RotatingFileLog.open(Directory(arguments.single));
    sink.add(jsonEncode({'event': 'process.test', 'pid': pid}));
    await sink.flush();
    stdout.writeln(sink.slot);
  } on FileSystemException {
    stdout.writeln('unavailable');
  }
  await stdin.first;
  await sink?.close();
}
