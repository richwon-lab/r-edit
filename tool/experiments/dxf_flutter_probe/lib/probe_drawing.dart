import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dxf/dxf.dart';

/// 이 실험의 위치를 포함한 미지원/손상 입력. 정상 표시로 보정하지 않는다.
class ProbeFailure implements Exception {
  ProbeFailure(this.code, this.location, this.reason);
  final String code, location, reason;
  @override
  String toString() => '$code [$location]: $reason';
}

class DxfRecord {
  DxfRecord(this.type, this.groups, this.index);
  final String type;
  final List<(int, String)> groups;
  final int index;
  String? optional(int code) {
    for (final pair in groups) {
      if (pair.$1 == code) return pair.$2;
    }
    return null;
  }

  String get location => '$type handle=${optional(5) ?? "?"} record=$index';
  String requiredValue(int code) =>
      optional(code) ??
      (throw ProbeFailure('missingGroup', location, 'group $code 누락'));
  double number(int code, [double? defaultValue]) {
    final raw = optional(code);
    final value = raw == null ? defaultValue : double.tryParse(raw);
    if (value == null || !value.isFinite) {
      throw ProbeFailure('invalidNumber', location, 'group $code: $raw');
    }
    return value;
  }

  Offset point(int x, int y) => Offset(number(x), number(y));
}

class ProbeStyle {
  ProbeStyle(this.record);
  final DxfRecord record;
  String get name => record.requiredValue(2);
  String get font => record.requiredValue(3);
  double get width => record.number(41, 1);
}

class ProbeText {
  ProbeText(this.record, this.style) {
    if (height <= 0 || width <= 0) {
      throw ProbeFailure('invalidTextSize', record.location, '높이/자폭은 양수');
    }
    if (record.number(72, 0) != horizontal ||
        record.number(73, 0) != vertical ||
        !{0, 1, 2}.contains(horizontal) ||
        vertical != 0) {
      throw ProbeFailure(
        'unsupportedAlignment',
        record.location,
        '72=$horizontal, 73=$vertical. baseline 좌/중/우만 지원',
      );
    }
    if (record.number(51, 0) != 0 || record.number(71, 0) != 0) {
      throw ProbeFailure('unsupportedTextTransform', record.location, '기울임/반전');
    }
    if (style.record.number(40, 0) != 0 ||
        style.record.number(50, 0) != 0 ||
        style.record.number(70, 0) != 0 ||
        style.record.number(71, 0) != 0 ||
        (style.record.optional(4) ?? '').isNotEmpty) {
      throw ProbeFailure(
        'unsupportedStyle',
        record.location,
        '고정 높이/기울임/세로/반전/bigfont STYLE은 미지원',
      );
    }
    if (horizontal != 0 &&
        (record.optional(11) == null || record.optional(21) == null)) {
      throw ProbeFailure(
        'missingAlignmentPoint',
        record.location,
        'group 11/21 필요',
      );
    }
    rotation;
    if (text.contains('\n') || text.contains('\r') || text.contains('%%')) {
      throw ProbeFailure(
        'unsupportedTextSyntax',
        record.location,
        '다중 줄/%% 제어문',
      );
    }
  }
  final DxfRecord record;
  final ProbeStyle style;
  String get rawText => record.requiredValue(1);
  String get text => decodeDxfUnicode(rawText);
  double get height => record.number(40);
  double get width => record.number(41, 1) * style.width;
  double get rotation => record.number(50, 0);
  int get horizontal => record.number(72, 0).toInt();
  int get vertical => record.number(73, 0).toInt();
  Offset get insertion => record.point(10, 20);
  Offset? get alignment =>
      record.optional(11) == null ? null : record.point(11, 21);
  Offset get anchor => horizontal == 0 ? insertion : alignment!;
}

/// ASCII 전송 안의 UTF-16 DXF escape만 해석하며 공백을 trim하지 않는다.
String decodeDxfUnicode(String value) {
  final decoded = value.replaceAllMapped(
    RegExp(r'\\U\+([0-9A-Fa-f]{4})'),
    (match) => String.fromCharCode(int.parse(match[1]!, radix: 16)),
  );
  if (decoded.contains(r'\U+') || decoded.contains(r'\')) {
    throw ProbeFailure('unsupportedEscape', 'TEXT.group1', '미지원/손상된 escape');
  }
  return decoded;
}

class ProbeDrawing {
  ProbeDrawing(this.lines, this.texts, this.issues, this.codePage);
  final List<DxfRecord> lines;
  final List<ProbeText> texts;
  final List<ProbeFailure> issues;
  final String codePage;

  factory ProbeDrawing.read(Uint8List bytes) {
    // 이번 ASCII DXF의 실제 인코딩 경계. 다른 코드페이지를 잘못 decode하지 않는다.
    if (bytes.any((b) => b > 127)) {
      throw ProbeFailure(
        'unsupportedEncoding',
        'file',
        '이번 실험은 ASCII 전송+Unicode escape만 지원',
      );
    }
    final source = ascii.decode(bytes);
    final rows = const LineSplitter().convert(source);
    if (rows.length.isOdd) {
      throw ProbeFailure('invalidDxfPairs', 'file', 'group/value 쌍 누락');
    }
    for (var i = 0; i < rows.length; i += 2) {
      if (int.tryParse(rows[i]) == null) {
        throw ProbeFailure('invalidGroupCode', 'line ${i + 1}', '정수 group 필요');
      }
    }
    // 기존 파서의 공개 groupCodes를 재사용한다. 내부 src/쓰기/변환 API는 사용하지 않는다.
    final codes = DXF.fromString(source).groupCodes;
    final records = <DxfRecord>[];
    var type = '';
    var pairs = <(int, String)>[];
    for (final code in codes) {
      if (code.code == 0) {
        if (pairs.isNotEmpty) {
          records.add(DxfRecord(type, pairs, records.length));
        }
        type = code.value.toString();
        pairs = [];
      }
      pairs.add((code.code!, code.value.toString()));
    }
    if (pairs.isNotEmpty) records.add(DxfRecord(type, pairs, records.length));
    String header(String key) {
      final at = codes.indexWhere((g) => g.code == 9 && g.value == key);
      if (at < 0 || at + 1 >= codes.length) {
        throw ProbeFailure('missingHeader', key, '헤더 값 누락');
      }
      return codes[at + 1].value.toString();
    }

    if (header(r'$INSUNITS') != '4') {
      throw ProbeFailure('unsupportedUnit', r'$INSUNITS', 'mm(4)만 지원');
    }
    final styles = <String, ProbeStyle>{};
    for (final record in records.where((r) => r.type == 'STYLE')) {
      final style = ProbeStyle(record);
      if (styles.containsKey(style.name)) {
        throw ProbeFailure('duplicateStyle', record.location, style.name);
      }
      styles[style.name] = style;
    }
    var inEntities = false;
    final lines = <DxfRecord>[],
        texts = <ProbeText>[],
        issues = <ProbeFailure>[];
    for (final record in records) {
      if (record.type == 'SECTION') {
        inEntities = record.optional(2) == 'ENTITIES';
        continue;
      }
      if (record.type == 'ENDSEC') {
        inEntities = false;
        continue;
      }
      if (!inEntities) continue;
      try {
        for (final code in [30, 31, 38, 39, 210, 220]) {
          if (record.number(code, 0) != 0) {
            throw ProbeFailure('unsupported3D', record.location, 'group $code');
          }
        }
        if (record.number(230, 1) != 1) {
          throw ProbeFailure(
            'unsupportedExtrusion',
            record.location,
            'group 230',
          );
        }
        switch (record.type) {
          case 'LINE':
            record.point(10, 20);
            record.point(11, 21);
            lines.add(record);
          case 'TEXT':
            final styleName = record.optional(7) ?? 'Standard';
            final style = styles[styleName];
            if (style == null) {
              throw ProbeFailure('unknownStyle', record.location, styleName);
            }
            texts.add(ProbeText(record, style));
          default:
            throw ProbeFailure(
              'unsupportedEntity',
              record.location,
              record.type,
            );
        }
      } on ProbeFailure catch (issue) {
        issues.add(issue);
      }
    }
    return ProbeDrawing(
      List.unmodifiable(lines),
      List.unmodifiable(texts),
      List.unmodifiable(issues),
      header(r'$DWGCODEPAGE'),
    );
  }
}
