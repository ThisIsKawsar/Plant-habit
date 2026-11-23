import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_info.dart';
import '../core/catalog.dart';
import '../core/dates.dart';
import '../core/theme.dart';
import '../data/habit_store.dart';
import '../models/habit.dart';
import '../widgets/common.dart';
import '../widgets/plant_art.dart';
import '../widgets/progress_ring.dart';
import '../widgets/sheets.dart';
import 'add_habit_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 5) return 'Good Night!';
    if (h < 12) return 'Good Morning!';
    if (h < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  static String motivation(int done, int total, DateTime day) {
    if (total == 0) return 'Plant your first habit and watch it grow.';
    if (done == total) return 'All done today. Your garden is thriving!';
    if (done == 0) return 'Every journey starts with a single step.';
    if (done / total >= 0.5) return 'Over halfway there, keep growing!';
    return motivationalQuotes[day.difference(DateTime(day.year)).inDays %
        motivationalQuotes.length];
  }

  void _openAdd(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AddHabitScreen()));

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final stats = store.stats;
    final day = today();
    final todays = stats.scheduledOn(day);
    final progress = stats.progressOn(day);
    final colors = AppColors.of(context);
    final paused = store.pausedHabits;
    final notToday = store.activeHabits
        .where((h) => !h.isScheduledOn(day))
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(
          greeting: greeting(DateTime.now()),
          message: motivation(progress.done, progress.scheduled, day),
          ratio: progress.ratio,
          hasHabits: progress.scheduled > 0,
          streak: stats.currentStreak(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                "Today's Habits",
                trailing: todays.isEmpty
                    ? null
                    : Text(
                        '${progress.done} / ${progress.scheduled}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              if (store.habits.isEmpty)
                _EmptyState(onAdd: () => _openAdd(context))
              else ...[
                if (todays.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Nothing scheduled today. Enjoy your rest day! 🌿',
                      style: TextStyle(color: colors.muted),
                    ),
                  ),
                for (var i = 0; i < todays.length; i++) ...[
                  if (i > 0) const Divider(),
                  HabitListTile(
                    habit: todays[i],
                    done: store.isDone(todays[i], day),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      store.toggle(todays[i], day);
                    },
                    onLongPress: () => showHabitActions(context, todays[i]),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _openAdd(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Habit'),
                ),
                if (todays.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Tap to complete · Long-press for options',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: colors.muted),
                    ),
                  ),
                if (notToday.isNotEmpty)
                  _OtherHabits(title: 'Not scheduled today', habits: notToday),
                if (paused.isNotEmpty)
                  _OtherHabits(title: 'Paused', habits: paused),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Leafy header with a large plant sitting on the progress / streak card.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.greeting,
    required this.message,
    required this.ratio,
    required this.hasHabits,
    required this.streak,
  });

  final String greeting;
  final String message;
  final double ratio;
  final bool hasHabits;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final primary = Theme.of(context).colorScheme.primary;
    final colors = AppColors.of(context);
    const backdropHeight = 290.0;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: backdropHeight + top,
          child: const LeafBackdrop(),
        ),
        Positioned(
          right: 4,
          top: top + 56,
          child: PlantIllustration(
            size: 210,
            growth: hasHabits ? 0.55 + 0.45 * ratio : 0.55,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AppLogo(size: 34),
                  const SizedBox(width: 8),
                  Text(
                    AppInfo.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _titleColor(context, primary),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 20, 0, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.55,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Small Steps.\nBig Changes.',
                        style: TextStyle(
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(fontSize: 13, color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              _ProgressCard(ratio: ratio, streak: streak),
            ],
          ),
        ),
      ],
    );
  }

  static Color _titleColor(BuildContext context, Color primary) =>
      Theme.of(context).brightness == Brightness.dark
      ? primary
      : Color.lerp(primary, Colors.black, 0.35)!;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.ratio, required this.streak});
  final double ratio;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.soft(context, primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Today's Goal",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ProgressRing(
                      value: ratio,
                      size: 118,
                      stroke: 12,
                      child: Text(
                        '${(ratio * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 28, color: colors.border),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.soft(context, colors.streak),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: colors.streak,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Day Streak',
                    style: TextStyle(fontSize: 13, color: colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SproutBadge(size: 84),
          const SizedBox(height: 14),
          const Text(
            'No habits yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Plant your first habit to start growing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).muted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Habit'),
          ),
        ],
      ),
    );
  }
}

class _OtherHabits extends StatelessWidget {
  const _OtherHabits({required this.title, required this.habits});
  final String title;
  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 6),
          for (final h in habits)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Opacity(
                opacity: 0.6,
                child: HabitAvatar(
                  icon: iconFor(h.iconKey),
                  color: Color(h.colorValue),
                ),
              ),
              title: Text(h.name, style: TextStyle(color: colors.muted)),
              subtitle: Text(
                h.enabled ? h.frequencyLabel : 'Paused',
                style: TextStyle(fontSize: 12, color: colors.muted),
              ),
              trailing: Icon(Icons.more_horiz_rounded, color: colors.muted),
              onTap: () => showHabitActions(context, h),
            ),
        ],
      ),
    );
  }
}
