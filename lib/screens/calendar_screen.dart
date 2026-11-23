import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../core/theme.dart';
import '../data/habit_stats.dart';
import '../data/habit_store.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/plant_art.dart';
import '../widgets/sheets.dart';
import 'heatmap_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = firstOfMonth(today());

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HabitStore>().stats;
    final colors = AppColors.of(context);
    final now = today();
    final count = daysInMonth(_month.year, _month.month);
    final leading = calendarWeekdays.indexOf(_month.weekday);
    final days = [
      for (var i = 1; i <= count; i++) DateTime(_month.year, _month.month, i),
    ];
    final doneDays = days
        .where((d) => stats.statusOn(d) == DayStatus.done)
        .length;
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Heatmap',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HeatmapScreen())),
          ),
        ],
      ),
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
              SurfaceCard(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => _shift(-1),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: isCurrentMonth
                            ? null
                            : () => setState(() => _month = firstOfMonth(now)),
                        child: Text(
                          '${monthNames[_month.month - 1]} ${_month.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => _shift(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final wd in calendarWeekdays)
                    Expanded(
                      child: Text(
                        weekdayShort[wd - 1],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.muted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leading + count,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, i) {
                  if (i < leading) return const SizedBox.shrink();
                  final d = days[i - leading];
                  return _DayCell(
                    day: d,
                    status: stats.statusOn(d),
                    ratio: stats.progressOn(d).ratio,
                    isToday: isSameDay(d, now),
                    onTap: () => showDayDetails(context, d),
                  );
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                children: [
                  LegendDot(color: colors.success, label: 'Done'),
                  LegendDot(color: colors.missed, label: 'Missed'),
                  LegendDot(
                    color: colors.muted,
                    label: 'Pending',
                    hollow: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                color: AppColors.soft(
                  context,
                  Theme.of(context).colorScheme.primary,
                ),
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 44,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCurrentMonth
                                    ? 'This Month'
                                    : monthNames[_month.month - 1],
                                style: TextStyle(color: colors.muted),
                              ),
                              Text(
                                '$doneDays / $count',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'perfect days',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(doneDays / count * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ThinProgressBar(value: doneDays / count),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.status,
    required this.ratio,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final DayStatus status;
  final double ratio;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final Color bg = switch (status) {
      DayStatus.done =>
        isToday ? primary : AppColors.soft(context, colors.success),
      DayStatus.missed => AppColors.soft(context, colors.missed),
      DayStatus.pending || DayStatus.none => Colors.transparent,
    };
    final Color? fg = switch (status) {
      DayStatus.done when isToday => Colors.white,
      DayStatus.none => colors.muted.withValues(alpha: 0.7),
      _ => null,
    };
    return Semantics(
      button: true,
      label: '${formatLongDate(day)}, ${status.name}',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: isToday && status != DayStatus.done
                ? Border.all(color: primary, width: 2)
                : status == DayStatus.pending
                ? Border.all(color: colors.border, width: 1.5)
                : null,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
