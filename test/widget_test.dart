import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:r_edit/app/r_edit_app.dart';

void main() {
  testWidgets('R-edit 시작 화면을 표시한다', (tester) async {
    await tester.pumpWidget(const REditApp());

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'R-edit',
    );
    expect(find.text('R-edit'), findsOneWidget);
    expect(find.text('명판 문구 배치 및 제작 파일 작성 프로그램'), findsOneWidget);
    expect(find.text('작업 기능은 앞으로 이 화면에 연결됩니다.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
