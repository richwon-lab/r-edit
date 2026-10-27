import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:r_edit/app/start_page.dart';

part 'app_routes.g.dart';

/// 현재 시작 경로의 유일한 선언이다. Router 수명은 Provider가 소유한다.
@TypedGoRoute<StartRoute>(path: '/')
class StartRoute extends GoRouteData with $StartRoute {
  const StartRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const StartPage();
}
