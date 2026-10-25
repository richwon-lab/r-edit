import 'package:flutter/material.dart';

/// 앱 공통 테마다. 화면 좌표·업무 모델의 단위와 관계없다.
ThemeData buildREditTheme({Brightness brightness = Brightness.light}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF285C64),
      brightness: brightness,
    ),
    useMaterial3: true,
    fontFamily: 'Malgun Gothic',
  );
}
