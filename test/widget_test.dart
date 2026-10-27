import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:r_edit/app/providers/app_logger.dart';
import 'package:r_edit/app/providers/app_router.dart';
import 'package:r_edit/app/providers/app_theme_mode.dart';
import 'package:r_edit/app/r_edit_app.dart';
import 'package:r_edit/app/routing/app_routes.dart';

void main() {
  testWidgets('루트 경로에서 R-edit 시작 안내를 표시한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: REditApp()));
    await tester.pumpAndSettle();
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

  testWidgets('한국어 단일 언어와 Material·Cupertino 기본 문구를 제공한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: REditApp()));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('R-edit'));
    expect(Localizations.localeOf(context), const Locale('ko'));
    expect(MaterialLocalizations.of(context).cancelButtonLabel, '취소');
    expect(CupertinoLocalizations.of(context).copyButtonLabel, '복사');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).supportedLocales,
      [const Locale('ko')],
    );
  });

  testWidgets('표시 상태 변경은 앱에 연결되고 새 컨테이너와 격리된다', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const REditApp()),
    );
    container.read(appThemeModeProvider.notifier).select(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    final independent = ProviderContainer();
    addTearDown(independent.dispose);
    expect(independent.read(appThemeModeProvider), ThemeMode.system);
  });

  testWidgets('등록되지 않은 경로는 안내하고 루트로 이동할 수 있다', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const REditApp()),
    );
    final router = container.read(appRouterProvider);
    router.go('/missing');
    await tester.pumpAndSettle();
    expect(find.text('페이지를 찾을 수 없습니다.'), findsOneWidget);
    const StartRoute().go(tester.element(find.text('페이지를 찾을 수 없습니다.')));
    await tester.pumpAndSettle();
    expect(find.text('R-edit'), findsOneWidget);
  });

  test('주입한 로거로 표시 설정 변경을 기록하며 원문은 기록하지 않는다', () {
    final logger = Logger('r_edit.foundation.test');
    final records = <LogRecord>[];
    final subscription = logger.onRecord.listen(records.add);
    addTearDown(subscription.cancel);
    final container = ProviderContainer(
      overrides: [appLoggerProvider.overrideWithValue(logger)],
    );
    addTearDown(container.dispose);
    container.read(appThemeModeProvider.notifier).select(ThemeMode.dark);
    expect(records.map((record) => record.message), ['themeChanged']);
  });
}
