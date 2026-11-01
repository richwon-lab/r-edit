import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dxf_flutter_probe/main.dart';
import 'package:dxf_flutter_probe/probe_scene.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('실제 Windows에서 파일·지정 글꼴·도면·확대/이동·오류와 보존을 확인한다', (tester) async {
    await tester.pumpWidget(const ProbeApp());
    Future<void> waitFor(String value) async {
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        if (find.textContaining(value).evaluate().isNotEmpty) return;
      }
      fail('Windows UI did not display: $value');
    }

    Future<void> saveScreen() async {
      await tester.tap(find.text('화면·입력 근거 저장'));
      await waitFor('저장 완료');
    }

    ProbePainter currentPainter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<ProbePainter>()
        .single;
    final originalDxf = File('fixtures/r_edit_flutter_text_probe.dxf')
        .absolute
        .path;
    const originalFont = r'C:\Windows\Fonts\H2GTRE.TTF';
    await tester.tap(find.text('불러오기'));
    await waitFor('LINE 16 / TEXT 10/10');
    await tester.pumpAndSettle();
    final initial = currentPainter().scene;
    expect(initial.issues, isEmpty);
    expect(initial.texts, hasLength(10));
    expect(
      initial.font.hash,
      '820d3212f688b546a327ea43a7202e3379cdbbd767ebac9753997e3f3d285171',
    );
    expect(
      initial.texts[1].input.text,
      'h=2  w=1.0 | H x g PUMP 123 한글  A  B ',
    );
    expect(initial.texts[8].input.anchor, const Offset(120, 12));
    expect(initial.texts[8].left, -initial.texts[8].painter.width / 2);
    expect(initial.texts[9].left, -initial.texts[9].painter.width);
    expect(
      initial.texts.every((text) => !text.painter.didExceedMaxLines),
      isTrue,
    );
    await saveScreen();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final beforeZoom = viewer.transformationController!.value.clone();
    await tester.tap(find.byTooltip('확대'));
    await tester.pumpAndSettle();
    expect(
      viewer.transformationController!.value.storage[0],
      closeTo(beforeZoom.storage[0] * 1.25, 1e-9),
    );
    await tester.drag(find.byType(InteractiveViewer), const Offset(-80, 35));
    await tester.pumpAndSettle();
    expect(
      viewer.transformationController!.value.getTranslation(),
      isNot(beforeZoom.getTranslation()),
    );
    expect(identical(currentPainter().scene, initial), isTrue);
    await saveScreen();
    await tester.tap(find.text('전체 보기'));
    await tester.pumpAndSettle();
    expect(
      viewer.transformationController!.value.storage[0],
      closeTo(beforeZoom.storage[0], 1e-9),
    );
    // 잘못된 경로는 실제 도면을 바꾸지 않고 별도 실패로 표시한다.
    await tester.enterText(
      find.byType(TextField).at(1),
      r'C:\no-such-font-probe\missing.ttf',
    );
    await tester.tap(find.text('불러오기'));
    await waitFor('fileAccessFailure');
    expect(identical(currentPainter().scene, initial), isTrue);
    await saveScreen();
    // 샘플 복사본만 변경해 지원 밖 정렬을 실제 UI에서도 확인한다.
    final temp = await Directory.systemTemp.createTemp(
      'r-edit-unsupported-dxf-',
    );
    final unsupported = File('${temp.path}/unsupported-aligned.dxf');
    await unsupported.writeAsString(
      (await File(
        originalDxf,
      ).readAsString()).replaceFirst(RegExp(r' 72\r?\n1\r?\n'), ' 72\n3\n'),
    );
    await tester.enterText(find.byType(TextField).at(0), unsupported.path);
    await tester.enterText(find.byType(TextField).at(1), originalFont);
    await tester.tap(find.text('불러오기'));
    await waitFor('LINE 16 / TEXT 9/9');
    await tester.pumpAndSettle();
    expect(currentPainter().scene.issues.single.code, 'unsupportedAlignment');
    await saveScreen();
    // 원본 샘플을 다시 읽어 최종 정상 표시를 남긴다. 원본 파일은 쓰지 않는다.
    await tester.enterText(find.byType(TextField).at(0), originalDxf);
    await tester.tap(find.text('불러오기'));
    await waitFor('LINE 16 / TEXT 10/10');
    await tester.pumpAndSettle();
    await saveScreen();
  });
}
