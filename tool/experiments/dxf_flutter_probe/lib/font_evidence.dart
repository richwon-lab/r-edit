import 'dart:typed_data';
import 'dart:ui';

import 'package:crypto/crypto.dart';

import 'probe_drawing.dart';

/// 지정 파일의 sfnt 메트릭/cmap/원본 bbox만 읽는 실험용 경계. 글꼴을 변환하지 않는다.
class FontEvidence {
  FontEvidence(Uint8List bytes)
    : data = ByteData.sublistView(bytes),
      hash = sha256.convert(bytes).toString() {
    if (u32(0) != 0x00010000) {
      throw ProbeFailure('unsupportedFont', 'font', '단독 TrueType glyf 파일만 지원');
    }
    for (var i = 0; i < u16(4); i++) {
      final p = 12 + 16 * i;
      final tag = String.fromCharCodes(bytes.sublist(p, p + 4));
      tables[tag] = u32(p + 8);
    }
    for (final name in [
      'head',
      'hhea',
      'hmtx',
      'maxp',
      'cmap',
      'loca',
      'glyf',
      'name',
      'OS/2',
    ]) {
      if (!tables.containsKey(name)) {
        throw ProbeFailure('missingFontTable', 'font.$name', '테이블 없음');
      }
    }
    if (tables.containsKey('fvar')) {
      throw ProbeFailure('unsupportedFont', 'font', 'variable font 미지원');
    }
    unitsPerEm = u16(tables['head']! + 18);
    final cmap = tables['cmap']!;
    for (var i = 0; i < u16(cmap + 2); i++) {
      final p = cmap + 4 + i * 8;
      if (u16(p) == 3 && u16(p + 2) == 1) {
        final candidate = cmap + u32(p + 4);
        if (u16(candidate) == 4) cmap4 = candidate;
      }
    }
    if (cmap4 == null) {
      throw ProbeFailure(
        'unsupportedCmap',
        'font.cmap',
        'Windows BMP format4 필요',
      );
    }
    final name = tables['name']!;
    final values = <String>[];
    for (var i = 0; i < u16(name + 2); i++) {
      final p = name + 6 + i * 12;
      if (u16(p) != 3 || ![1, 2, 4, 5, 6].contains(u16(p + 6))) continue;
      final start = name + u16(name + 4) + u16(p + 10);
      final text = String.fromCharCodes([
        for (var j = 0; j < u16(p + 8); j += 2) u16(start + j),
      ]);
      values.add(text);
    }
    names = values.toSet().toList(growable: false);
    // 사용자가 명시한 H2GTRE.TTF의 실제 내부 이름도 함께 확인한다.
    if (!names.contains('HYGothic-Extra') || !names.contains('H2gtrE')) {
      throw ProbeFailure(
        'fontIdentityMismatch',
        'font.name',
        'HYGothic-Extra / H2gtrE 필요',
      );
    }
    final os2 = tables['OS/2']!;
    if (u16(os2) >= 2 && i16(os2 + 88) > 0) {
      capHeight = i16(os2 + 88).toDouble();
      capSource = 'OS/2.sCapHeight';
    } else {
      // ezdxf의 TrueType cap-height 규약을 명시적으로 적용한다. CAD 정밀 일치의 증명은 아니다.
      capHeight = glyphBounds(65)!.bottom - glyphBounds(120)!.top;
      capSource = 'A.yMax - x.yMin (OS/2 cap-height 없음, ezdxf 방식)';
    }
    if (unitsPerEm <= 0 || capHeight <= 0) {
      throw ProbeFailure('invalidFontMetric', 'font', '양수 UPEM/cap height 필요');
    }
  }
  final ByteData data;
  final String hash;
  final tables = <String, int>{};
  late final int unitsPerEm;
  late final double capHeight;
  late final String capSource;
  late final List<String> names;
  int? cmap4;
  int u16(int p) => data.getUint16(p, Endian.big);
  int i16(int p) => data.getInt16(p, Endian.big);
  int u32(int p) => data.getUint32(p, Endian.big);

  int glyphId(int scalar) {
    if (scalar > 0xffff || (scalar >= 0xd800 && scalar <= 0xdfff)) return 0;
    final p = cmap4!;
    final count = u16(p + 6) ~/ 2;
    final end = p + 14, start = end + 2 * count + 2;
    final delta = start + 2 * count, range = delta + 2 * count;
    for (var i = 0; i < count; i++) {
      if (scalar > u16(end + 2 * i)) continue;
      if (scalar < u16(start + 2 * i)) return 0;
      final offset = u16(range + 2 * i);
      if (offset == 0) return (scalar + i16(delta + 2 * i)) & 0xffff;
      final glyph = u16(
        range + 2 * i + offset + 2 * (scalar - u16(start + 2 * i)),
      );
      return glyph == 0 ? 0 : (glyph + i16(delta + 2 * i)) & 0xffff;
    }
    return 0;
  }

  double advance(int scalar) {
    final id = glyphId(scalar);
    final count = u16(tables['hhea']! + 34);
    return u16(tables['hmtx']! + 4 * (id < count ? id : count - 1)).toDouble();
  }

  /// Rect의 top/bottom을 수학 좌표 minY/maxY로 사용한다. 제어점 포함 glyf bbox다.
  Rect? glyphBounds(int scalar) {
    final id = glyphId(scalar);
    if (id == 0) {
      throw ProbeFailure(
        'missingGlyph',
        'font.cmap',
        'U+${scalar.toRadixString(16)}',
      );
    }
    final short = i16(tables['head']! + 50) == 0;
    final loca = tables['loca']!;
    final begin = short ? 2 * u16(loca + 2 * id) : u32(loca + 4 * id);
    final end = short ? 2 * u16(loca + 2 * (id + 1)) : u32(loca + 4 * (id + 1));
    if (begin == end) return null;
    final p = tables['glyf']! + begin;
    return Rect.fromLTRB(
      i16(p + 2).toDouble(),
      i16(p + 4).toDouble(),
      i16(p + 6).toDouble(),
      i16(p + 8).toDouble(),
    );
  }

  void checkCoverage(ProbeText text) {
    for (final scalar in text.text.runes) {
      if (glyphId(scalar) == 0) {
        throw ProbeFailure(
          'missingGlyph',
          text.record.location,
          'U+${scalar.toRadixString(16)}',
        );
      }
      if (!(scalar >= 32 && scalar <= 126 ||
          scalar >= 0xac00 && scalar <= 0xd7a3)) {
        throw ProbeFailure(
          'unsupportedShaping',
          text.record.location,
          'ASCII/완성형 한글만 시험',
        );
      }
    }
  }
}
