import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_info.dart';
import '../core/catalog.dart';
import '../core/dates.dart';
import '../core/theme.dart';
import '../data/habit_store.dart';
import '../data/settings_store.dart';
import '../services/notification_service.dart';
import '../widgets/common.dart';
import '../widgets/plant_art.dart';

void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

String _themeLabel(ThemeMode m) => switch (m) {
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
  ThemeMode.system => 'System',
};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>().value;
    final colors = AppColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final notifSubtitle = !s.notificationsEnabled
        ? 'Off'
        : s.dailyReminderEnabled
        ? formatTimeOfDayMinutes(s.dailyReminderMinutes)
        : 'On';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 360,
            child: LeafBackdrop(fadeTop: true),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HillsBackdrop(height: 160),
          ),
          const Positioned(
            right: -10,
            bottom: -6,
            child: CornerLeaves(size: 140),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Center(child: PlantIllustration(size: 210)),
              const SizedBox(height: 4),
              Text(
                AppInfo.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _brandText(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppInfo.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.muted),
              ),
              const SizedBox(height: 28),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SettingsTile(
                        icon: Icons.notifications_rounded,
                        color: colors.streak,
                        title: 'Notifications',
                        subtitle: notifSubtitle,
                        onTap: () =>
                            _push(context, const NotificationsScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SettingsTile(
                        icon: Icons.palette_rounded,
                        color: palette[2].color,
                        title: 'Appearance',
                        subtitle: _themeLabel(s.themeMode),
                        onTap: () => _push(context, const AppearanceScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SettingsTile(
                        icon: Icons.info_rounded,
                        color: primary,
                        title: 'About App',
                        subtitle: 'v${AppInfo.version}',
                        onTap: () => _push(context, const AboutScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ],
      ),
    );
  }
}

/// Square, center-aligned settings entry.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HabitAvatar(icon: icon, color: color, size: 52),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.of(context).muted),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _setEnabled(BuildContext context, bool value) async {
    final store = context.read<SettingsStore>();
    if (value) {
      if (!NotificationService.isSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminders are available on Android, iOS and macOS.'),
          ),
        );
        return;
      }
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission was denied. '
                'You can allow it in your device settings.',
              ),
            ),
          );
        }
        return;
      }
    }
    store.update((s) => s.copyWith(notificationsEnabled: value));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SettingsStore>();
    final s = store.value;
    final colors = AppColors.of(context);
    final on = s.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HillsBackdrop(),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Enable Notifications',
                    trailing: Switch(
                      value: on,
                      onChanged: (v) => _setEnabled(context, v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionTitle('Reminders'),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: on ? 1 : 0.45,
                child: IgnorePointer(
                  ignoring: !on,
                  child: SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: Icons.schedule_rounded,
                        title: 'Daily Reminder',
                        subtitle: s.dailyReminderEnabled
                            ? 'Every day at ${formatTimeOfDayMinutes(s.dailyReminderMinutes)}'
                            : 'Off',
                        trailing: Switch(
                          value: s.dailyReminderEnabled,
                          onChanged: (v) => store.update(
                            (s) => s.copyWith(dailyReminderEnabled: v),
                          ),
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.access_time_rounded,
                        title: 'Reminder Time',
                        trailing: Text(
                          formatTimeOfDayMinutes(s.dailyReminderMinutes),
                          style: TextStyle(
                            color: colors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: s.dailyReminderMinutes ~/ 60,
                              minute: s.dailyReminderMinutes % 60,
                            ),
                          );
                          if (t != null) {
                            store.update(
                              (s) => s.copyWith(
                                dailyReminderMinutes: t.hour * 60 + t.minute,
                              ),
                            );
                          }
                        },
                      ),
                      SettingsRow(
                        icon: Icons.calendar_today_rounded,
                        title: 'Weekly Summary',
                        subtitle: s.weeklySummaryEnabled
                            ? 'Every ${weekdayLong[s.weeklySummaryWeekday - 1]} at 6:00 PM'
                            : 'Off',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<int>(
                              tooltip: 'Summary day',
                              initialValue: s.weeklySummaryWeekday,
                              onSelected: (d) => store.update(
                                (s) => s.copyWith(weeklySummaryWeekday: d),
                              ),
                              itemBuilder: (_) => [
                                for (final d in calendarWeekdays)
                                  PopupMenuItem(
                                    value: d,
                                    child: Text(weekdayLong[d - 1]),
                                  ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  weekdayShort[s.weeklySummaryWeekday - 1],
                                  style: TextStyle(
                                    color: colors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Switch(
                              value: s.weeklySummaryEnabled,
                              onChanged: (v) => store.update(
                                (s) => s.copyWith(weeklySummaryEnabled: v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.track_changes_rounded,
                        title: 'Habit Reminders',
                        subtitle: 'Per-habit reminders set when adding a habit',
                        trailing: Switch(
                          value: s.habitRemindersEnabled,
                          onChanged: (v) => store.update(
                            (s) => s.copyWith(habitRemindersEnabled: v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const EncouragementCard(
                title: 'Stay consistent!',
                subtitle: 'A little reminder goes a long way.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late ThemeMode _mode;
  late int _palette;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsStore>().value;
    _mode = s.themeMode;
    _palette = s.paletteIndex;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<SettingsStore>();
    final changed =
        _mode != store.value.themeMode || _palette != store.value.paletteIndex;
    final preview = palette[_palette].color;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const SectionTitle('Theme Mode'),
          Row(
            children: [
              for (final (mode, icon, iconColor) in [
                (
                  ThemeMode.light,
                  Icons.wb_sunny_rounded,
                  const Color(0xFFF5A524),
                ),
                (
                  ThemeMode.dark,
                  Icons.dark_mode_rounded,
                  const Color(0xFF5B6CF0),
                ),
                (ThemeMode.system, Icons.settings_suggest_rounded, preview),
              ]) ...[
                if (mode != ThemeMode.light) const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    label: _themeLabel(mode),
                    icon: icon,
                    iconColor: iconColor,
                    selected: _mode == mode,
                    accent: preview,
                    onTap: () => setState(() => _mode = mode),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Color Palette'),
          ColorDots(
            colors: [for (final p in palette) p.color],
            selected: _palette,
            onSelected: (i) => setState(() => _palette = i),
            size: 48,
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              palette[_palette].name,
              style: TextStyle(color: AppColors.of(context).muted),
            ),
          ),
          const SizedBox(height: 24),
          const BrandCard(),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: preview),
            onPressed: changed
                ? () {
                    store.update(
                      (s) =>
                          s.copyWith(themeMode: _mode, paletteIndex: _palette),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appearance updated')),
                    );
                    setState(() {});
                  }
                : null,
            child: const Text('Apply Changes'),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? AppColors.soft(context, accent) : colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : colors.border,
              width: 2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(icon, size: 34, color: iconColor),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: -12,
                  right: 6,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _tapsToUnlock = 3;
  int _taps = 0;
  DateTime _lastTap = DateTime(0);

  void _onVersionTap() {
    final settings = context.read<SettingsStore>();
    if (settings.value.developerMode) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Developer mode is already on')),
        );
      return;
    }
    final now = DateTime.now();
    // Taps must be in quick succession.
    _taps = now.difference(_lastTap) < const Duration(seconds: 1)
        ? _taps + 1
        : 1;
    _lastTap = now;
    if (_taps < _tapsToUnlock) return;
    _taps = 0;
    _setDeveloperMode(true);
  }

  void _setDeveloperMode(bool on) {
    final habits = context.read<HabitStore>();
    context.read<SettingsStore>().update((s) => s.copyWith(developerMode: on));
    if (on) {
      habits.seedDemoData();
    } else {
      habits.clearDemoData();
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            on
                ? 'Developer mode on · demo data added'
                : 'Developer mode off · demo data removed',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final developerMode = context.watch<SettingsStore>().value.developerMode;
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About App')),
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HillsBackdrop(height: 170),
          ),
          const Positioned(
            right: -10,
            bottom: -6,
            child: CornerLeaves(size: 150),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              const Center(child: SproutBadge(size: 108)),
              const SizedBox(height: 14),
              Text(
                AppInfo.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _brandText(context),
                ),
              ),
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onVersionTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      'v${AppInfo.version}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                AppInfo.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                AppInfo.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              _Feature(
                icon: Icons.favorite_rounded,
                color: colors.success,
                title: Text.rich(
                  TextSpan(
                    text: 'Made with ',
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: colors.missed,
                        ),
                      ),
                      const TextSpan(text: ' for a greener you.'),
                    ],
                  ),
                ),
              ),
              _Feature(
                icon: Icons.check_circle_outline_rounded,
                title: const Text('Build healthy habits, one tap a day'),
              ),
              _Feature(
                icon: Icons.insights_rounded,
                title: const Text('Track streaks, stats and heatmap'),
              ),
              _Feature(
                icon: Icons.notifications_none_rounded,
                title: const Text('Gentle reminders to stay on track'),
              ),
              if (developerMode) ...[
                const SizedBox(height: 16),
                SurfaceCard(
                  borderColor: colors.streak.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.developer_mode_rounded, color: colors.streak),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Developer mode',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Demo data is loaded. Turn off to remove it.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: true,
                        onChanged: (v) => _setDeveloperMode(v),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 150),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dark green brand text in light mode, accent color in dark mode.
Color _brandText(BuildContext context) {
  final primary = Theme.of(context).colorScheme.primary;
  return Theme.of(context).brightness == Brightness.dark
      ? primary
      : Color.lerp(primary, Colors.black, 0.45)!;
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, this.color});
  final IconData icon;
  final Widget title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 18),
          Expanded(
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 16),
              child: title,
            ),
          ),
        ],
      ),
    );
  }
}
