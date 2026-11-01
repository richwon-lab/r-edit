import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dxf_flutter_probe/font_evidence.dart';
import 'package:dxf_flutter_probe/main.dart';
import 'package:dxf_flutter_probe/probe_drawing.dart';
import 'package:dxf_flutter_probe/probe_scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = File('fixtures/r_edit_flutter_text_probe.dxf')
      .readAsBytesSync();
  final source = String.fromCharCodes(bytes);
  final fontBytes = File(r'C:\Windows\Fonts\H2GTRE.TTF').readAsBytesSync();
  final font = FontEvidence(fontBytes);
  final drawing = ProbeDrawing.read(bytes);
  setUpAll(() async {
    final loader = FontLoader('test_actual_h2gtre')
      ..addFont(Future.value(ByteData.sublistView(fontBytes)));
    await loader.load();
  });

  test('이동한 합성 DXF의 원본 바이트가 보존된다', () {
    expect(
      sha256.convert(bytes).toString(),
      '5a731d652c82d3ea46ebac5dfb14c56397dcefb0dd028ca2cc31fdf21c3eddc7',
    );
  });
  test('실제 샘플의 mm·STYLE·16선·10텍스트를 읽는다', () {
    expect(drawing.codePage, 'ANSI_1252');
    expect(drawing.lines, hasLength(16));
    expect(drawing.texts, hasLength(10));
    expect(drawing.issues, isEmpty);
    expect(drawing.lines.first.point(10, 20), Offset.zero);
    expect(drawing.lines.first.point(11, 21), const Offset(240, 0));
    expect(drawing.texts.map((e) => e.style.font).toSet(), {'H2GTRE.TTF'});
    expect(drawing.texts.map((e) => e.style.name).toSet(), {'PROBE_HY_GOTHIC'});
  });
  final samples = [
    ('38', 2.0, 1.0, 112.0),
    ('3A', 2.0, 0.8, 96.0),
    ('3C', 3.0, 1.0, 80.0),
    ('3E', 3.0, 0.8, 64.0),
    ('40', 5.0, 1.0, 48.0),
    ('42', 5.0, 0.8, 32.0),
  ];
  for (final sample in samples) {
    test('TEXT ${sample.$1}의 한글·반복/끝 공백·높이·자폭·좌표를 고정 기대값과 대조한다', () {
      final input = drawing.texts.singleWhere(
        (e) => e.record.optional(5) == sample.$1,
      );
      expect(
        input.text,
        'h=${sample.$2.toInt()}  w=${sample.$3.toStringAsFixed(1)} | H x g PUMP 123 한글  A  B ',
      );
      expect(input.rawText, contains(r'\U+D55C\U+AE00'));
      expect(input.height, sample.$2);
      expect(input.width, sample.$3);
      expect(input.anchor, Offset(12, sample.$4));
      expect(input.rotation, 0);
      font.checkCoverage(input);
    });
  }
  test('명시 파일의 내부 이름·UPEM·cmap·기준 메트릭을 확인한다', () {
    expect(
      font.hash,
      '820d3212f688b546a327ea43a7202e3379cdbbd767ebac9753997e3f3d285171',
    );
    expect(
      font.names,
      containsAll(['HY견고딕', 'HYGothic-Extra', 'H2gtrE', 'Version 1.00']),
    );
    expect(font.unitsPerEm, 1024);
    expect(font.capHeight, 784);
    expect(font.glyphId(72), 75);
    expect(font.advance(32), 341);
    expect(font.glyphBounds(72), const Rect.fromLTRB(93, 1, 715, 785));
    expect(font.glyphBounds(32), isNull);
    expect(font.glyphId(0x10ffff), 0);
  });
  test('누락 glyph와 잘못된 글꼴 데이터를 기본 글꼴로 보정하지 않는다', () {
    final input = ProbeText(
      DxfRecord('TEXT', [
        (5, 'missing'),
        (1, '😀'),
        (40, '3'),
        (10, '0'),
        (20, '0'),
      ], 0),
      drawing.texts.first.style,
    );
    expect(
      () => font.checkCoverage(input),
      throwsA(
        isA<ProbeFailure>().having((e) => e.code, 'code', 'missingGlyph'),
      ),
    );
    expect(
      () => FontEvidence(Uint8List(12)),
      throwsA(
        isA<ProbeFailure>().having((e) => e.code, 'code', 'unsupportedFont'),
      ),
    );
  });
  for (final pair in [
    (7, 'LEFT 한글', 0, 20.0),
    (8, 'CENTER 한글', 1, 120.0),
    (9, 'RIGHT 한글', 2, 220.0),
  ]) {
    test('${pair.$2}은 baseline과 DXF 좌/중/우 정렬점을 적용한다', () {
      final input = drawing.texts[pair.$1];
      final placed = PlacedText(input, font, 'test_actual_h2gtre');
      addTearDown(placed.dispose);
      expect(input.text, pair.$2);
      expect(input.horizontal, pair.$3);
      expect(placed.anchor, Offset(pair.$4, 12));
      expect(placed.scale, closeTo(3 / 784, 1e-12));
      expect(placed.left, -placed.painter.width * pair.$3 / 2);
      expect(placed.baseline, greaterThan(0));
    });
  }
  test('같은 문구의 자폭 0.8은 X 진행폭만 줄이고 기준선과 높이는 유지한다', () {
    final text = drawing.texts[3];
    final narrow = ProbeText(
      DxfRecord('TEXT', [
        ...text.record.groups.where((g) => g.$1 != 41),
        (41, '0.8'),
      ], 0),
      text.style,
    );
    final full = PlacedText(text, font, 'test_actual_h2gtre');
    final compressed = PlacedText(narrow, font, 'test_actual_h2gtre');
    addTearDown(full.dispose);
    addTearDown(compressed.dispose);
    expect(compressed.advanceMm, closeTo(full.advanceMm * 0.8, 1e-8));
    expect(compressed.logicalBox.height, full.logicalBox.height);
    expect(compressed.anchor, full.anchor);
    expect(compressed.baseline, full.baseline);
  });
  test('회전 각도를 보존하고 Y 위쪽 도면을 화면으로 한 번만 뒤집는다', () {
    final text = drawing.texts.first;
    final rotated = ProbeText(
      DxfRecord('TEXT', [...text.record.groups, (50, '30')], 0),
      text.style,
    );
    final placed = PlacedText(rotated, font, 'test_actual_h2gtre');
    addTearDown(placed.dispose);
    expect(placed.radians, closeTo(math.pi / 6, 1e-12));
    expect(ProbePainter.project(const Offset(10, 20)), const Offset(120, 540));
    expect(
      ProbePainter.project(const Offset(10, 21)).dy,
      lessThan(ProbePainter.project(const Offset(10, 20)).dy),
    );
  });
  test('ALIGNED는 부분 미지원 진단을 남기며 다른 텍스트는 계속 읽는다', () {
    final modified = source.replaceFirst(RegExp(r' 72\r?\n1\r?\n'), ' 72\n3\n');
    expect(modified, isNot(source));
    final result = ProbeDrawing.read(Uint8List.fromList(modified.codeUnits));
    expect(result.texts, hasLength(9));
    expect(result.issues.single.code, 'unsupportedAlignment');
    expect(result.issues.single.location, contains('handle=47'));
  });
  test('지원하지 않는 도형은 handle과 함께 보고하고 다른 요소를 보존한다', () {
    final modified = source.replaceFirst(
      RegExp(r'[ ]{2}0\r?\nLINE\r?\n'),
      '  0\nPOINT\n',
    );
    expect(modified, isNot(source));
    final result = ProbeDrawing.read(Uint8List.fromList(modified.codeUnits));
    expect(result.lines, hasLength(15));
    expect(result.texts, hasLength(10));
    expect(result.issues.single.code, 'unsupportedEntity');
    expect(result.issues.single.location, contains('handle=33'));
  });
  test('깨진 group 쌍과 미지원 인코딩을 정상 도면으로 보정하지 않는다', () {
    expect(
      () => ProbeDrawing.read(Uint8List.fromList([0xff])),
      throwsA(
        isA<ProbeFailure>().having(
          (e) => e.code,
          'code',
          'unsupportedEncoding',
        ),
      ),
    );
    expect(
      () => ProbeDrawing.read(Uint8List.fromList('0\nSECTION\n2'.codeUnits)),
      throwsA(
        isA<ProbeFailure>().having((e) => e.code, 'code', 'invalidDxfPairs'),
      ),
    );
  });
  test('Unicode escape 해석은 반복·끝 공백을 보존한다', () {
    expect(decodeDxfUnicode(r' A  \U+D55C\U+AE00 '), ' A  한글 ');
    expect(() => decodeDxfUnicode(r'\U+ZZZZ'), throwsA(isA<ProbeFailure>()));
  });
  testWidgets('실험 화면은 입력 경로·불러오기·확대·보조 표시를 제공한다', (tester) async {
    await tester.pumpWidget(const ProbeApp());
    expect(find.text('불러오기'), findsOneWidget);
    expect(find.text('전체 보기'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byTooltip('확대'), findsOneWidget);
    expect(find.text('DXF cap-height 해석'), findsOneWidget);
  });
}
