// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$startRoute];

RouteBase get $startRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $StartRoute._fromState,
);

mixin $StartRoute on GoRouteData {
  static StartRoute _fromState(GoRouterState state) => const StartRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
