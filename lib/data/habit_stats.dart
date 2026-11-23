import '../core/dates.dart';
import '../models/habit.dart';

enum DayStatus {
  /// No habits scheduled that day.
  none,

  /// Every scheduled habit was completed.
  done,

  /// A past day where at least one scheduled habit was not completed.
  missed,

  /// Today (not yet complete) or a future day.
  pending,
}

enum StatsPeriod {
  week('Week'),
  month('This Month'),
  threeMonths('Last 3 Months');

  const StatsPeriod(this.label);
  final String label;
}

class DayProgress {
  const DayProgress(this.day, this.done, this.scheduled);
  final DateTime day;
  final int done;
  final int scheduled;
  double get ratio => scheduled == 0 ? 0 : done / scheduled;
}

class RangeSummary {
  const RangeSummary({
    required this.completed,
    required this.missed,
    required this.perfectDays,
    required this.trackedDays,
  });

  /// Completed check-ins.
  final int completed;

  /// Scheduled check-ins on past days that were not completed.
  final int missed;

  /// Days on which every scheduled habit was done.
  final int perfectDays;

  /// Days up to today that had at least one habit scheduled.
  final int trackedDays;

  double get rate =>
      completed + missed == 0 ? 0 : completed / (completed + missed);
}

class ChartBucket {
  const ChartBucket(this.label, this.value, {this.isFuture = false});
  final String label;

  /// 0..1 completion ratio.
  final double value;
  final bool isFuture;
}

class HabitPerformance {
  const HabitPerformance(this.habit, this.summary);
  final Habit habit;
  final RangeSummary summary;
}

/// Read-only calculations over habits and their completion history.
///
/// Only enabled habits are taken into account. [completions] maps a habit id
/// to the set of [dayKey]s on which it was completed.
class HabitStats {
  HabitStats(List<Habit> habits, this.completions, {DateTime? now})
    : habits = habits.where((h) => h.enabled).toList(),
      today = dateOnly(now ?? DateTime.now());

  final List<Habit> habits;
  final Map<String, Set<String>> completions;
  final DateTime today;

  bool isDone(Habit h, DateTime day) =>
      completions[h.id]?.contains(dayKey(day)) ?? false;

  List<Habit> scheduledOn(DateTime day, {Habit? only}) =>
      (only == null ? habits : habits.where((h) => h.id == only.id))
          .where((h) => h.isScheduledOn(day))
          .toList();

  DayProgress progressOn(DateTime day, {Habit? only}) {
    final list = scheduledOn(day, only: only);
    final done = list.where((h) => isDone(h, day)).length;
    return DayProgress(dateOnly(day), done, list.length);
  }

  DayStatus statusOn(DateTime day, {Habit? only}) {
    final d = dateOnly(day);
    final p = progressOn(d, only: only);
    if (p.scheduled == 0) return DayStatus.none;
    if (p.done == p.scheduled) return DayStatus.done;
    if (d.isBefore(today)) return DayStatus.missed;
    return DayStatus.pending;
  }

  DateTime? get earliestStart {
    if (habits.isEmpty) return null;
    return habits
        .map((h) => h.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Consecutive fully-completed days ending today (or yesterday, if today is
  /// still in progress). Days with nothing scheduled neither count nor break.
  int currentStreak({Habit? only}) {
    final start = only?.createdAt ?? earliestStart;
    if (start == null) return 0;
    var streak = 0;
    var d = today;
    if (statusOn(d, only: only) == DayStatus.pending) d = addDays(d, -1);
    for (; !d.isBefore(start); d = addDays(d, -1)) {
      final s = statusOn(d, only: only);
      if (s == DayStatus.done) {
        streak++;
      } else if (s == DayStatus.missed || s == DayStatus.pending) {
        break;
      }
    }
    return streak;
  }

  int longestStreak({Habit? only}) {
    final start = only?.createdAt ?? earliestStart;
    if (start == null) return 0;
    var best = 0;
    var run = 0;
    for (var d = start; !d.isAfter(today); d = addDays(d, 1)) {
      final s = statusOn(d, only: only);
      if (s == DayStatus.done) {
        run++;
        if (run > best) best = run;
      } else if (s == DayStatus.missed) {
        run = 0;
      }
    }
    return best;
  }

  int get totalCompleted {
    var total = 0;
    for (final h in habits) {
      total += completions[h.id]?.length ?? 0;
    }
    return total;
  }

  /// Summary for [start]..[end], clipped to today. Today's unfinished habits
  /// are not counted as missed yet.
  RangeSummary summarize(DateTime start, DateTime end, {Habit? only}) {
    var completed = 0, missed = 0, perfect = 0, tracked = 0;
    final last = end.isAfter(today) ? today : dateOnly(end);
    for (var d = dateOnly(start); !d.isAfter(last); d = addDays(d, 1)) {
      final p = progressOn(d, only: only);
      if (p.scheduled == 0) continue;
      tracked++;
      completed += p.done;
      if (d.isBefore(today)) missed += p.scheduled - p.done;
      if (p.done == p.scheduled) perfect++;
    }
    return RangeSummary(
      completed: completed,
      missed: missed,
      perfectDays: perfect,
      trackedDays: tracked,
    );
  }

  (DateTime, DateTime) rangeFor(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return (addDays(today, -6), today);
      case StatsPeriod.month:
        return (
          firstOfMonth(today),
          DateTime(
            today.year,
            today.month,
            daysInMonth(today.year, today.month),
          ),
        );
      case StatsPeriod.threeMonths:
        return (DateTime(today.year, today.month - 2), today);
    }
  }

  RangeSummary summarizePeriod(StatsPeriod period, {Habit? only}) {
    final (s, e) = rangeFor(period);
    return summarize(s, e, only: only);
  }

  /// Daily ratios for week/month; weekly ratios for three months.
  List<ChartBucket> chartFor(StatsPeriod period, {Habit? only}) {
    final (start, end) = rangeFor(period);
    if (period == StatsPeriod.threeMonths) {
      final buckets = <ChartBucket>[];
      for (var s = start; !s.isAfter(end); s = addDays(s, 7)) {
        final e = addDays(s, 6);
        final sum = summarize(s, e, only: only);
        final denom = sum.completed + sum.missed;
        buckets.add(
          ChartBucket(
            '${monthShort[s.month - 1]} ${s.day}',
            denom == 0 ? 0 : sum.completed / denom,
          ),
        );
      }
      return buckets;
    }
    return daysBetween(start, end).map((d) {
      final label = period == StatsPeriod.week
          ? weekdayShort[d.weekday - 1]
          : '${d.day}';
      return ChartBucket(
        label,
        progressOn(d, only: only).ratio,
        isFuture: d.isAfter(today),
      );
    }).toList();
  }

  List<HabitPerformance> performance(StatsPeriod period) {
    final list =
        habits
            .map((h) => HabitPerformance(h, summarizePeriod(period, only: h)))
            .where((p) => p.summary.trackedDays > 0)
            .toList()
          ..sort((a, b) => b.summary.rate.compareTo(a.summary.rate));
    return list;
  }

  /// 0 = nothing scheduled/done, 1..4 = increasing completion.
  int intensityOn(DateTime day) {
    final p = progressOn(day);
    if (p.scheduled == 0 || p.done == 0) return 0;
    final r = p.ratio;
    if (r >= 1) return 4;
    if (r >= 0.66) return 3;
    if (r >= 0.33) return 2;
    return 1;
  }
}
