import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.paletteIndex = 0,
    this.notificationsEnabled = false,
    this.dailyReminderEnabled = true,
    this.dailyReminderMinutes = 9 * 60,
    this.weeklySummaryEnabled = true,
    this.weeklySummaryWeekday = DateTime.sunday,
    this.habitRemindersEnabled = true,
    this.developerMode = false,
  });

  final ThemeMode themeMode;
  final int paletteIndex;
  final bool notificationsEnabled;
  final bool dailyReminderEnabled;
  final int dailyReminderMinutes;
  final bool weeklySummaryEnabled;
  final int weeklySummaryWeekday;
  final bool habitRemindersEnabled;

  /// Unlocked by tapping the version on the About screen three times.
  final bool developerMode;

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? paletteIndex,
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderMinutes,
    bool? weeklySummaryEnabled,
    int? weeklySummaryWeekday,
    bool? habitRemindersEnabled,
    bool? developerMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      paletteIndex: paletteIndex ?? this.paletteIndex,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderMinutes: dailyReminderMinutes ?? this.dailyReminderMinutes,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      weeklySummaryWeekday: weeklySummaryWeekday ?? this.weeklySummaryWeekday,
      habitRemindersEnabled:
          habitRemindersEnabled ?? this.habitRemindersEnabled,
      developerMode: developerMode ?? this.developerMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'paletteIndex': paletteIndex,
    'notificationsEnabled': notificationsEnabled,
    'dailyReminderEnabled': dailyReminderEnabled,
    'dailyReminderMinutes': dailyReminderMinutes,
    'weeklySummaryEnabled': weeklySummaryEnabled,
    'weeklySummaryWeekday': weeklySummaryWeekday,
    'habitRemindersEnabled': habitRemindersEnabled,
    'developerMode': developerMode,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == j['themeMode'],
        orElse: () => d.themeMode,
      ),
      paletteIndex: (j['paletteIndex'] as int?) ?? d.paletteIndex,
      notificationsEnabled:
          (j['notificationsEnabled'] as bool?) ?? d.notificationsEnabled,
      dailyReminderEnabled:
          (j['dailyReminderEnabled'] as bool?) ?? d.dailyReminderEnabled,
      dailyReminderMinutes:
          (j['dailyReminderMinutes'] as int?) ?? d.dailyReminderMinutes,
      weeklySummaryEnabled:
          (j['weeklySummaryEnabled'] as bool?) ?? d.weeklySummaryEnabled,
      weeklySummaryWeekday:
          (j['weeklySummaryWeekday'] as int?) ?? d.weeklySummaryWeekday,
      habitRemindersEnabled:
          (j['habitRemindersEnabled'] as bool?) ?? d.habitRemindersEnabled,
      developerMode: (j['developerMode'] as bool?) ?? d.developerMode,
    );
  }
}
