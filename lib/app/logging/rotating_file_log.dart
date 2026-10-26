import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// 앱 로그의 고정 슬롯 출력기다. 비동기 I/O·OS lock·한도만 담당한다.
final class RotatingFileLog {
  RotatingFileLog._(
    this.directory,
    this.maxFileBytes,
    this.fileCount,
    this.maxRecordBytes,
    this.maxPendingRecords,
    this._fallback,
    this._writeBytes,
  ) {
    if (maxRecordBytes < 128 ||
        maxFileBytes < maxRecordBytes ||
        fileCount < 1 ||
        fileCount > 3 ||
        maxPendingRecords < 1) {
      throw ArgumentError('로그 용량/슬롯/버퍼 설정이 잘못되었습니다.');
    }
  }

  /// 기본 활성 포함 15MiB와 64건의 유한 버퍼로 연다. 파일 실패는 호출자가 처리한다.
  static Future<RotatingFileLog> open(
    Directory directory, {
    int maxFileBytes = 5 * 1024 * 1024,
    int fileCount = 3,
    int maxRecordBytes = 16 * 1024,
    int maxPendingRecords = 64,
    void Function()? onUnavailable,
    Future<void> Function(RandomAccessFile, List<int>)? writeBytes,
  }) async {
    final sink = RotatingFileLog._(
      directory,
      maxFileBytes,
      fileCount,
      maxRecordBytes,
      maxPendingRecords,
      onUnavailable ?? () {},
      writeBytes ?? _write,
    );
    await directory.create(recursive: true);
    try {
      await sink._selectSlot();
    } on FileSystemException {
      await sink.close();
      rethrow;
    }
    return sink;
  }

  /// 실제 데이터 파일을 둔 앱 전용 로컬 디렉터리다.
  final Directory directory;

  /// 활성 파일을 포함한 슬롯당 최대 바이트다.
  final int maxFileBytes;

  /// 동시에 존재할 데이터 파일 수다. 프로세스별 증가를 허용하지 않는다.
  final int fileCount;

  /// 개별 UTF-8 기록의 최대 바이트이며 줄 끝을 포함한다.
  final int maxRecordBytes;

  /// 대기 기록 수의 최대다. 처리 중 한 건은 별도다.
  final int maxPendingRecords;
  final void Function() _fallback;
  final Future<void> Function(RandomAccessFile, List<int>) _writeBytes;
  final Queue<List<int>> _queue = Queue();
  RandomAccessFile? _file;
  RandomAccessFile? _slotLock;
  int? _index;
  int _length = 0;
  Future<void>? _pending;
  Future<void>? _closing;
  bool _accepting = true;
  bool _failed = false;
  int _dropped = 0;
  static Future<void> _selection = Future.value();
  static final Set<String> _owned = {};

  /// 버퍼 초과로 버린 기록 수다. 카운터 자체도 상한을 가진다.
  int get droppedCount => _dropped;

  /// 현재 쓰는 슬롯이다. 작업/제품 식별자가 아니다.
  int? get slot => _index;

  /// 데이터 파일 경로다. 공유 슬롯의 쓰기 소유권은 OS lock으로 보호한다.
  String? get activeFilePath => _index == null ? null : _dataFile(_index!).path;

  File _dataFile(int index) => File('${directory.path}/r_edit.$index.jsonl');

  static Future<void> _write(RandomAccessFile file, List<int> bytes) async {
    await file.writeFrom(bytes);
  }

  /// 로컬 프로세스 안에서도 POSIX lock의 프로세스 단위 의미를 보완해 직렬화한다.
  Future<void> _selectSlot() {
    final selected = _selection.then((_) => _selectSlotLocked());
    _selection = selected.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return selected;
  }

  Future<void> _selectSlotLocked() async {
    final control = await File('${directory.path}/selection.lock')
        .open(mode: FileMode.append);
    var locked = false;
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await control.lock();
          locked = true;
          break;
        } on FileSystemException {
          if (attempt == 2) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      }
      final candidates = <(int, DateTime)>[];
      for (var i = 0; i < fileCount; i++) {
        if (!_owned.contains(_dataFile(i).path)) {
          // 파일 메타데이터도 UI isolate를 동기 I/O로 막지 않는다.
          // ignore: avoid_slow_async_io
          candidates.add((i, (await _dataFile(i).stat()).modified));
        }
      }
      candidates.sort((a, b) => a.$2.compareTo(b.$2));
      for (final (index, _) in candidates) {
        final handle = await File('${directory.path}/slot.$index.lock')
            .open(mode: FileMode.append);
        try {
          await handle.lock();
        } on FileSystemException {
          await handle.close();
          continue;
        }
        RandomAccessFile next;
        try {
          next = await _dataFile(index).open(mode: FileMode.write);
        } on FileSystemException {
          await handle.close();
          rethrow;
        }
        try {
          await _releaseHandles();
        } on FileSystemException {
          try {
            await next.close();
          } finally {
            await handle.close();
          }
          rethrow;
        }
        _file = next;
        _slotLock = handle;
        _index = index;
        _owned.add(_dataFile(index).path);
        _length = 0;
        return;
      }
      if (_file case final current?) {
        await current.truncate(0);
        await current.setPosition(0);
        _length = 0;
        return;
      }
      throw const FileSystemException('사용 가능한 로그 슬롯이 없습니다.');
    } finally {
      try {
        if (locked) await control.unlock();
      } finally {
        await control.close();
      }
    }
  }

  /// 큐가 가득 차면 버리고, 큰 한 건은 유한한 요약으로 대체한다. 재귀 로깅하지 않는다.
  void add(String record) {
    if (!_accepting || _failed) return;
    if (_queue.length >= maxPendingRecords) {
      if (_dropped < 0x7fffffff) _dropped++;
      return;
    }
    const truncated = '{"event":"log.record_truncated"}\n';
    final bounded = record.length >= maxRecordBytes ? truncated : '$record\n';
    var bytes = utf8.encode(bounded);
    if (bytes.length > maxRecordBytes) bytes = utf8.encode(truncated);
    _queue.add(bytes);
    _startDrain();
  }

  void _startDrain() {
    if (_pending != null || _failed) return;
    _pending = _drain().whenComplete(() {
      _pending = null;
      if (_queue.isNotEmpty && !_failed) _startDrain();
    });
  }

  Future<void> _drain() async {
    try {
      while (_queue.isNotEmpty) {
        final bytes = _queue.removeFirst();
        if (_length + bytes.length > maxFileBytes) await _selectSlot();
        await _writeBytes(_file!, bytes);
        _length += bytes.length;
      }
    } on FileSystemException {
      _failed = true;
      _queue.clear();
      _fallback();
      try {
        await _releaseHandles();
      } on FileSystemException {
        // 이미 중단한 출력기의 정리 실패는 반복 보고하지 않는다.
      }
    }
  }

  /// 현재 큐를 배출하고 OS에 flush한다. 비정상 종료 내구성은 보장하지 않는다.
  Future<void> flush() async {
    while (_pending != null) {
      await _pending;
    }
    try {
      await _file?.flush();
    } on FileSystemException {
      if (!_failed) _fallback();
      _failed = true;
    }
  }

  Future<void> _releaseHandles() async {
    final file = _file;
    final handle = _slotLock;
    final index = _index;
    _file = null;
    _slotLock = null;
    _index = null;
    try {
      if (file != null) {
        try {
          await file.flush();
        } finally {
          await file.close();
        }
      }
    } finally {
      try {
        if (handle != null) await handle.close();
      } finally {
        if (index != null) _owned.remove(_dataFile(index).path);
      }
    }
  }

  /// 수신을 중지하고 큐·파일·소유 lock을 닫는다. 반복 호출은 안전하다.
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _accepting = false;
    await flush();
    try {
      await _releaseHandles();
    } on FileSystemException {
      if (!_failed) _fallback();
      _failed = true;
    }
  }
}
