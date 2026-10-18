import 'package:flutter/material.dart';

import 'r_edit_theme.dart';
import 'start_page.dart';

class REditApp extends StatelessWidget {
  const REditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'R-edit',
      debugShowCheckedModeBanner: false,
      theme: buildREditTheme(),
      home: const StartPage(),
    );
  }
}
