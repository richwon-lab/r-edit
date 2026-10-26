import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:r_edit/app/logging/app_logging.dart';
import 'package:r_edit/app/r_edit_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logging = await AppLogging.start();
  logging.bindApplicationExit();
  runApp(
    ProviderScope(
      observers: [logging.providerObserver],
      child: const REditApp(),
    ),
  );
}
