import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:r_edit/app/logging/app_logging.dart';
import 'package:r_edit/app/r_edit_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureAppLogging();
  Logger('r_edit.bootstrap').info('R-edit 시작');
  runApp(const ProviderScope(child: REditApp()));
}
