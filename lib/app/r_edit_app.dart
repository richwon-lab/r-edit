import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:r_edit/app/providers/app_router.dart';
import 'package:r_edit/app/providers/app_theme_mode.dart';
import 'package:r_edit/app/r_edit_theme.dart';

/// 공통 표시 설정·라우터를 연결하는 앱 루트다. 업무 흐름을 구현하지 않는다.
class REditApp extends ConsumerWidget {
  const REditApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'R-edit',
      debugShowCheckedModeBanner: false,
      theme: buildREditTheme(),
      darkTheme: buildREditTheme(brightness: Brightness.dark),
      themeMode: ref.watch(appThemeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
