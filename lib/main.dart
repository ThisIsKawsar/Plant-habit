import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/habit_store.dart';
import 'data/settings_store.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final habits = HabitStore(prefs);
  final settings = SettingsStore(prefs);

  // Keep scheduled reminders in sync with habits and settings.
  Timer? debounce;
  void sync() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      NotificationService.instance.reschedule(settings.value, habits.habits);
    });
  }

  habits.addListener(sync);
  settings.addListener(sync);
  unawaited(NotificationService.instance.init().then((_) => sync()));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: habits),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const PlantHabitApp(),
    ),
  );
}
