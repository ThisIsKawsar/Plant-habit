import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/catalog.dart';
import '../core/dates.dart';
import '../core/theme.dart';
import '../data/habit_stats.dart';
import '../data/habit_store.dart';
import '../models/habit.dart';
import '../screens/add_habit_screen.dart';
import 'charts.dart';
import 'common.dart';

/// Habits scheduled on [day] with their status; past/today can be toggled.
Future<void> showDayDetails(BuildContext context, DateTime day) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DayDetailsSheet(day: dateOnly(day)),
  );
}

class _DayDetailsSheet extends StatelessWidget {
  const _DayDetailsSheet({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final stats = store.stats;
    final habits = stats.scheduledOn(day);
    final progress = stats.progressOn(day);
    final status = stats.statusOn(day);
    final colors = AppColors.of(context);
    final isFuture = day.isAfter(today());

    final (statusLabel, statusColor) = switch (status) {
      DayStatus.done => ('Completed', colors.success),
      DayStatus.missed => ('Missed', colors.missed),
      DayStatus.pending => (
        isFuture ? 'Upcoming' : 'In progress',
        colors.muted,
      ),
      DayStatus.none => ('No habits', colors.muted),
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSameDay(day, today()) ? 'Today' : formatLongDate(day),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.soft(context, statusColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            if (habits.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ThinProgressBar(value: progress.ratio)),
                  const SizedBox(width: 12),
                  Text(
                    '${progress.done} / ${progress.scheduled}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (habits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No habits were scheduled for this day.',
                    style: TextStyle(color: colors.muted),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final h in habits)
                      HabitListTile(
                        habit: h,
                        done: store.isDone(h, day),
                        onTap: isFuture
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                store.toggle(h, day);
                              },
                      ),
                  ],
                ),
              ),
            if (isFuture && habits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Future days can be checked off when they arrive.',
                  style: TextStyle(fontSize: 12.5, color: colors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A habit row with icon, name, goal and check circle.
class HabitListTile extends StatelessWidget {
  const HabitListTile({
    super.key,
    required this.habit,
    required this.done,
    this.onTap,
    this.onLongPress,
  });

  final Habit habit;
  final bool done;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final muted = AppColors.of(context).muted;
    final subtitle = [
      if (habit.goal.isNotEmpty) habit.goal,
      if (!habit.isEveryDay) habit.frequencyLabel,
    ].join(' · ');
    return Semantics(
      checked: done,
      label: habit.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              CheckCircle(
                checked: done,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                  ],
                ),
              ),
              HabitAvatar(icon: iconFor(habit.iconKey), color: color, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

/// View Details / Edit Habit / Delete Habit action sheet.
Future<void> showHabitActions(BuildContext context, Habit habit) {
  final missed = AppColors.of(context).missed;
  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                HabitAvatar(
                  icon: iconFor(habit.iconKey),
                  color: Color(habit.colorValue),
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(sheetContext);
                showHabitDetails(context, habit.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Habit'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddHabitScreen(existing: habit),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: missed),
              title: Text('Delete Habit', style: TextStyle(color: missed)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await confirmDeleteHabit(context, habit);
              },
            ),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> confirmDeleteHabit(BuildContext context, Habit habit) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete habit?'),
      content: Text('"${habit.name}" and all of its history will be removed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.of(ctx).missed,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    context.read<HabitStore>().delete(habit);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('"${habit.name}" deleted')));
    return true;
  }
  return false;
}

/// Per-habit stats sheet.
Future<void> showHabitDetails(BuildContext context, String habitId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HabitDetailsSheet(habitId: habitId),
  );
}

class _HabitDetailsSheet extends StatelessWidget {
  const _HabitDetailsSheet({required this.habitId});
  final String habitId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final habit = store.byId(habitId);
    if (habit == null) return const SizedBox(height: 120);
    final colors = AppColors.of(context);
    final color = Color(habit.colorValue);
    // Paused habits are excluded from store-wide stats, so compute directly.
    final stats = HabitStats(
      [habit.copyWith(enabled: true)],
      {
        habit.id: {
          for (final d in daysBetween(habit.createdAt, today()))
            if (store.isDone(habit, d)) dayKey(d),
        },
      },
    );
    final all = stats.summarize(habit.createdAt, today());
    final recent = daysBetween(addDays(today(), -27), today());

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HabitAvatar(
                  icon: iconFor(habit.iconKey),
                  color: color,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          habit.category,
                          habit.frequencyLabel,
                          if (habit.goal.isNotEmpty) habit.goal,
                        ].join(' · '),
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (habit.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(habit.description, style: TextStyle(color: colors.muted)),
            ],
            if (!habit.enabled) ...[
              const SizedBox(height: 12),
              Text(
                'This habit is paused.',
                style: TextStyle(
                  color: colors.streak,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.local_fire_department_rounded,
                    value: '${stats.currentStreak()}',
                    label: 'Streak',
                    color: colors.streak,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.emoji_events_rounded,
                    value: '${stats.longestStreak()}',
                    label: 'Best',
                    color: colors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.check_circle_rounded,
                    value: '${all.completed}',
                    label: 'Done',
                    color: colors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Completion rate',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${(all.rate * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ThinProgressBar(value: all.rate, color: color),
            const SizedBox(height: 18),
            const Text(
              'Last 4 weeks',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final d in recent)
                  Tooltip(
                    message: formatLongDate(d),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: !habit.isScheduledOn(d)
                            ? colors.track.withValues(alpha: 0.4)
                            : store.isDone(habit, d)
                            ? color
                            : colors.track,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: store.isDone(habit, d)
                              ? Colors.white
                              : colors.muted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
