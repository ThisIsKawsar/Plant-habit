import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/catalog.dart';
import '../core/theme.dart';
import '../data/habit_stats.dart';
import '../data/habit_store.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/progress_ring.dart';
import '../widgets/sheets.dart';
import 'heatmap_screen.dart';

enum _StatsTab {
  habits('Habits'),
  overview('Overview'),
  heatmap('Heatmap');

  const _StatsTab(this.label);
  final String label;
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _StatsTab _tab = _StatsTab.habits;
  StatsPeriod _period = StatsPeriod.month;

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HabitStore>().stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          _PeriodButton(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          PillSelector<_StatsTab>(
            values: _StatsTab.values,
            selected: _tab,
            labelOf: (t) => t.label,
            onChanged: (t) => setState(() => _tab = t),
            filled: true,
          ),
          const SizedBox(height: 16),
          if (stats.habits.isEmpty)
            const EncouragementCard(
              title: 'No statistics yet',
              subtitle:
                  'Add a habit and check it off to see your progress here.',
            )
          else
            switch (_tab) {
              _StatsTab.habits => _HabitsTab(stats: stats, period: _period),
              _StatsTab.overview => _OverviewTab(stats: stats, period: _period),
              _StatsTab.heatmap => HeatmapView(period: _period),
            },
        ],
      ),
    );
  }
}

/// Compact "This Month ▾" period picker in the app bar.
class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.period, required this.onChanged});
  final StatsPeriod period;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PopupMenuButton<StatsPeriod>(
      tooltip: 'Time period',
      initialValue: period,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (final p in StatsPeriod.values)
          PopupMenuItem(value: p, child: Text(p.label)),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: AppColors.soft(context, primary),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              period == StatsPeriod.threeMonths ? '3 Months' : period.label,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _HabitsTab extends StatelessWidget {
  const _HabitsTab({required this.stats, required this.period});
  final HabitStats stats;
  final StatsPeriod period;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final summary = stats.summarizePeriod(period);
    final performance = stats.performance(period);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(caption: 'Completion rate', summary: summary),
        const SizedBox(height: 12),
        MiniStatsCard(
          stats: [
            MiniStat(
              Icons.local_fire_department_rounded,
              '${stats.currentStreak()}',
              'Current streak',
              colors.streak,
            ),
            MiniStat(
              Icons.emoji_events_rounded,
              '${stats.longestStreak()}',
              'Longest streak',
              colors.gold,
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionTitle(
          period == StatsPeriod.threeMonths
              ? 'Weekly Progress'
              : 'Daily Progress',
        ),
        SurfaceCard(
          child: CompletionBarChart(
            buckets: stats.chartFor(period),
            height: 130,
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Habit Performance'),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: performance.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No data for this period yet.',
                    style: TextStyle(color: colors.muted),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < performance.length; i++) ...[
                      if (i > 0) const Divider(),
                      _PerformanceRow(
                        performance: performance[i],
                        onTap: () =>
                            showHabitDetails(context, performance[i].habit.id),
                      ),
                    ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Tap a habit for its streaks and history',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.muted),
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.stats, required this.period});
  final HabitStats stats;
  final StatsPeriod period;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final summary = stats.summarizePeriod(period);
    final performance = stats.performance(period);
    final best = performance.isEmpty ? null : performance.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(caption: 'Overall completion', summary: summary),
        const SizedBox(height: 12),
        MiniStatsCard(
          stats: [
            MiniStat(
              Icons.local_fire_department_rounded,
              '${stats.currentStreak()}',
              'Overall streak',
              colors.streak,
            ),
            MiniStat(
              Icons.star_rounded,
              '${summary.perfectDays}',
              'Perfect days',
              colors.gold,
            ),
            MiniStat(
              Icons.calendar_month_rounded,
              '${summary.trackedDays}',
              'Days tracked',
              Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        if (best != null) ...[
          const SizedBox(height: 22),
          const SectionTitle('Best Habit'),
          SurfaceCard(
            onTap: () => showHabitDetails(context, best.habit.id),
            child: Row(
              children: [
                HabitAvatar(
                  icon: iconFor(best.habit.iconKey),
                  color: Color(best.habit.colorValue),
                  size: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        best.habit.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${best.summary.completed} check-ins',
                        style: TextStyle(fontSize: 12.5, color: colors.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.emoji_events_rounded, color: colors.gold),
                const SizedBox(width: 6),
                Text(
                  '${(best.summary.rate * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SectionTitle('Progress Trend'),
        SurfaceCard(
          child: TrendLineChart(buckets: stats.chartFor(period), height: 140),
        ),
      ],
    );
  }
}

/// Ring + headline + done/missed counts in one card.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.caption, required this.summary});
  final String caption;
  final RangeSummary summary;

  static String headline(double rate, int total) {
    if (total == 0) return "Let's get started";
    if (rate >= 0.8) return 'Excellent consistency';
    if (rate >= 0.6) return 'Great progress';
    if (rate >= 0.4) return 'Keep it growing';
    return 'Every day counts';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final rate = summary.rate;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ProgressRing(
            value: rate,
            size: 96,
            stroke: 10,
            child: Text(
              '${(rate * 100).round()}%',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  headline(rate, summary.completed + summary.missed),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    LegendDot(
                      color: colors.success,
                      label: '${summary.completed} done',
                    ),
                    LegendDot(
                      color: colors.missed,
                      label: '${summary.missed} missed',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.performance, required this.onTap});
  final HabitPerformance performance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = performance.habit;
    final color = Color(h.colorValue);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            HabitAvatar(icon: iconFor(h.iconKey), color: color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ThinProgressBar(
                    value: performance.summary.rate,
                    color: color,
                    height: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              child: Text(
                '${(performance.summary.rate * 100).round()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
