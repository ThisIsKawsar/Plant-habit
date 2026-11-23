import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../core/theme.dart';
import '../data/habit_stats.dart';
import '../data/habit_store.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

/// Cell color for an intensity level 0..4.
Color heatmapLevelColor(BuildContext context, int level) {
  if (level == 0) return AppColors.of(context).track;
  return Theme.of(context).colorScheme.primary.withValues(
    alpha: const <double>[0, 0.3, 0.5, 0.75, 1.0][level],
  );
}

/// Full-screen heatmap (opened from the Calendar).
class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  StatsPeriod _period = StatsPeriod.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          PillSelector<StatsPeriod>(
            values: StatsPeriod.values,
            selected: _period,
            labelOf: (p) => p.label,
            onChanged: (p) => setState(() => _period = p),
            filled: true,
          ),
          const SizedBox(height: 16),
          HeatmapView(period: _period),
        ],
      ),
    );
  }
}

/// Activity heatmap for a [StatsPeriod]: a 7-day strip for a week, otherwise
/// one calendar-shaped block per month.
class HeatmapView extends StatelessWidget {
  const HeatmapView({super.key, required this.period});
  final StatsPeriod period;

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HabitStore>().stats;
    final colors = AppColors.of(context);
    final now = today();
    final (start, _) = stats.rangeFor(period);
    final summary = stats.summarize(start, now);
    Color cellColor(DateTime d) => d.isAfter(now)
        ? colors.track.withValues(alpha: 0.35)
        : heatmapLevelColor(context, stats.intensityOn(d));

    final months = switch (period) {
      StatsPeriod.week => const <DateTime>[],
      StatsPeriod.month => [firstOfMonth(now)],
      StatsPeriod.threeMonths => [
        for (var i = 0; i < 3; i++) DateTime(now.year, now.month - i),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiniStatsCard(
          stats: [
            MiniStat(
              Icons.calendar_month_rounded,
              '${summary.trackedDays}',
              'Days tracked',
              Theme.of(context).colorScheme.primary,
            ),
            MiniStat(
              Icons.star_rounded,
              '${summary.perfectDays}',
              'Perfect days',
              colors.gold,
            ),
            MiniStat(
              Icons.check_circle_rounded,
              '${summary.completed}',
              'Check-ins',
              colors.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              if (period == StatsPeriod.week)
                _WeekStrip(
                  days: daysBetween(start, now),
                  colorFor: cellColor,
                  levelFor: stats.intensityOn,
                  onTap: (d) => showDayDetails(context, d),
                )
              else
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      children: [
                        _WeekdayHeader(
                          indent: months.length > 1 ? 44 : 0,
                          color: colors.muted,
                        ),
                        const SizedBox(height: 6),
                        for (final m in months) ...[
                          _MonthBlock(
                            month: m,
                            showLabel: months.length > 1,
                            colorFor: cellColor,
                            isToday: (d) => isSameDay(d, now),
                            onTap: (d) => showDayDetails(context, d),
                          ),
                          if (m != months.last) const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _Legend(color: colors.muted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const EncouragementCard(
          title: 'Consistency Builds Growth',
          subtitle: "Every green square is a step forward. You're doing great!",
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.colorFor,
    required this.levelFor,
    required this.onTap,
  });

  final List<DateTime> days;
  final Color Function(DateTime) colorFor;
  final int Function(DateTime) levelFor;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).muted;
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Text(
                    weekdayShort[d.weekday - 1],
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 0.75,
                    child: GestureDetector(
                      onTap: () => onTap(d),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorFor(d),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${d.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: levelFor(d) >= 3 ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.indent, required this.color});
  final double indent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: indent),
        for (final wd in calendarWeekdays)
          Expanded(
            child: Text(
              weekdayShort[wd - 1].substring(0, 1),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Low', style: TextStyle(fontSize: 12, color: color)),
        const SizedBox(width: 8),
        for (var l = 0; l <= 4; l++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: heatmapLevelColor(context, l),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        const SizedBox(width: 8),
        Text('High', style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _MonthBlock extends StatelessWidget {
  const _MonthBlock({
    required this.month,
    required this.showLabel,
    required this.colorFor,
    required this.isToday,
    required this.onTap,
  });

  final DateTime month;
  final bool showLabel;
  final Color Function(DateTime) colorFor;
  final bool Function(DateTime) isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final count = daysInMonth(month.year, month.month);
    final leading = calendarWeekdays.indexOf(month.weekday);
    final primary = Theme.of(context).colorScheme.primary;
    final grid = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leading + count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemBuilder: (context, i) {
        if (i < leading) return const SizedBox.shrink();
        final d = DateTime(month.year, month.month, i - leading + 1);
        return Tooltip(
          message: formatLongDate(d),
          child: GestureDetector(
            onTap: () => onTap(d),
            child: Container(
              decoration: BoxDecoration(
                color: colorFor(d),
                borderRadius: BorderRadius.circular(6),
                border: isToday(d)
                    ? Border.all(color: primary, width: 2)
                    : null,
              ),
            ),
          ),
        );
      },
    );
    if (!showLabel) return grid;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              monthShort[month.month - 1],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Expanded(child: grid),
      ],
    );
  }
}
