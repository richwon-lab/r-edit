import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:r_edit/app/logging/app_log_event.dart';
import 'package:r_edit/app/providers/app_logger.dart';
import 'package:r_edit/app/start_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// 화면 이동 객체의 소유권은 앱 Provider에 있다. 업무 패키지는 라우터를 모른다.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final logger = ref.watch(appLoggerProvider);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartPage()),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('페이지를 찾을 수 없습니다.'))),
    redirect: (context, state) {
      logger.fine(const AppLogEvent(AppEvent.routeChecked));
      return null;
    },
  );
  ref.onDispose(router.dispose);
  return router;
}
