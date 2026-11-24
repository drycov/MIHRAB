import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'infrastructure/background_reminders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'app/app.dart';
import 'application/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final preferences = await SharedPreferences.getInstance();
  unawaited(initializeBackgroundReminders().catchError((Object error) {
    debugPrint('MIHRAB WorkManager registration failed: $error');
  }));
  runApp(ProviderScope(
    overrides: [preferencesProvider.overrideWithValue(preferences)],
    child: const MihrabApp(),
  ));
}
