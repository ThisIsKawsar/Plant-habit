import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/catalog.dart';
import '../models/app_settings.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _settings = AppSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('SettingsStore: failed to load settings: $e');
      }
    }
  }

  static const _key = 'settings_v1';
  final SharedPreferences _prefs;
  AppSettings _settings = const AppSettings();

  AppSettings get value => _settings;

  Color get accent =>
      palette[_settings.paletteIndex.clamp(0, palette.length - 1)].color;

  void update(AppSettings Function(AppSettings s) change) {
    _settings = change(_settings);
    notifyListeners();
    _prefs.setString(_key, jsonEncode(_settings.toJson()));
  }
}
