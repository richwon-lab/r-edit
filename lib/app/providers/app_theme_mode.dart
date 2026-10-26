import 'package:flutter/material.dart';
import 'package:r_edit/app/logging/app_log_event.dart';
import 'package:r_edit/app/providers/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_theme_mode.g.dart';

/// 앱 표시 상태다. 업무 입력·결과·저장 상태와 분리한다.
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() => ThemeMode.system;

  /// 화면 설정을 변경한다. 디스크 저장은 아직 제공하지 않는다.
  void select(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
    ref.read(appLoggerProvider).info(const AppLogEvent(AppEvent.themeChanged));
  }
}
