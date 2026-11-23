import 'package:flutter_test/flutter_test.dart';
import 'package:plant_habit/core/dates.dart';
import 'package:plant_habit/data/habit_stats.dart';
import 'package:plant_habit/models/habit.dart';

Habit habit(
  String id,
  DateTime created, {
  List<int> weekdays = const [],
  bool enabled = true,
}) => Habit(
  id: id,
  name: id,
  iconKey: 'book',
  category: 'Learning',
  colorValue: 0xFF2E9B3F,
  weekdays: weekdays,
  enabled: enabled,
  createdAt: created,
);

Set<String> keys(List<DateTime> days) => days.map(dayKey).toSet();

void main() {
  // Wednesday, 18 Nov 2026.
  final now = DateTime(2026, 11, 18, 10);
  final t = dateOnly(now);
  DateTime ago(int n) => addDays(t, -n);

  group('streaks', () {
    test('counts back from yesterday while today is still pending', () {
      final a = habit('a', ago(10));
      final s = HabitStats(
        [a],
        {
          'a': keys([ago(1), ago(2), ago(3), ago(5)]),
        },
        now: now,
      );
      expect(s.statusOn(t), DayStatus.pending);
      expect(s.currentStreak(), 3);
      expect(s.longestStreak(), 3);
    });

    test('includes today once completed', () {
      final a = habit('a', ago(10));
      final s = HabitStats(
        [a],
        {
          'a': keys([t, ago(1)]),
        },
        now: now,
      );
      expect(s.currentStreak(), 2);
    });

    test('days with nothing scheduled do not break a streak', () {
      // Scheduled on Mon (16th) and Wed (18th) only.
      final a = habit(
        'a',
        ago(14),
        weekdays: [DateTime.monday, DateTime.wednesday],
      );
      final s = HabitStats(
        [a],
        {
          'a': keys([t, ago(2), ago(7), ago(9)]),
        },
        now: now,
      );
      expect(s.statusOn(ago(1)), DayStatus.none);
      expect(s.currentStreak(), 4);
    });

    test('a day is only done when every habit is done', () {
      final a = habit('a', ago(5));
      final b = habit('b', ago(5));
      final s = HabitStats(
        [a, b],
        {
          'a': keys([ago(1), ago(2)]),
          'b': keys([ago(1)]),
        },
        now: now,
      );
      expect(s.statusOn(ago(2)), DayStatus.missed);
      expect(s.currentStreak(), 1);
      expect(s.currentStreak(only: a), 2);
    });

    test('paused habits are ignored', () {
      final a = habit('a', ago(5));
      final b = habit('b', ago(5), enabled: false);
      final s = HabitStats(
        [a, b],
        {
          'a': keys([ago(1), ago(2)]),
        },
        now: now,
      );
      expect(s.currentStreak(), 2);
    });
  });

  group('summaries', () {
    test('today is never counted as missed', () {
      final a = habit('a', ago(3));
      final s = HabitStats(
        [a],
        {
          'a': keys([ago(1)]),
        },
        now: now,
      );
      final sum = s.summarize(ago(3), t);
      expect(sum.completed, 1);
      expect(sum.missed, 2); // ago(3), ago(2)
      expect(sum.trackedDays, 4);
      expect(sum.rate, closeTo(1 / 3, 1e-9));
    });

    test('days before a habit was created are not scheduled', () {
      final a = habit('a', ago(1));
      final s = HabitStats([a], {}, now: now);
      expect(s.progressOn(ago(2)).scheduled, 0);
      expect(s.summarize(ago(30), t).missed, 1);
    });

    test('month chart has one bucket per day with future flagged', () {
      final s = HabitStats([habit('a', ago(3))], {}, now: now);
      final chart = s.chartFor(StatsPeriod.month);
      expect(chart.length, 30);
      expect(chart.where((b) => b.isFuture).length, 12);
    });

    test('three-month chart is weekly', () {
      final s = HabitStats([habit('a', ago(3))], {}, now: now);
      final chart = s.chartFor(StatsPeriod.threeMonths);
      expect(chart.length, inInclusiveRange(12, 14));
    });

    test('performance is sorted best first', () {
      final a = habit('a', ago(3));
      final b = habit('b', ago(3));
      final s = HabitStats(
        [a, b],
        {
          'a': keys([ago(1)]),
          'b': keys([ago(1), ago(2), ago(3)]),
        },
        now: now,
      );
      expect(s.performance(StatsPeriod.week).map((p) => p.habit.id), [
        'b',
        'a',
      ]);
    });
  });

  test('habit json round-trip', () {
    final h = habit('x', DateTime(2026, 1, 2), weekdays: [1, 3]);
    final back = Habit.fromJson(h.toJson());
    expect(back.weekdays, [1, 3]);
    expect(back.createdAt, DateTime(2026, 1, 2));
    expect(back.frequencyLabel, 'Mon, Wed');
  });
}
