import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/dates.dart';
import '../models/habit.dart';
import 'habit_stats.dart';

/// Holds all habits and their completion history, persisted locally.
class HabitStore extends ChangeNotifier {
  HabitStore(this._prefs) {
    _load();
  }

  static const _habitsKey = 'habits_v1';
  static const _completionsKey = 'completions_v1';

  final SharedPreferences _prefs;
  final List<Habit> _habits = [];
  final Map<String, Set<String>> _completions = {};
  HabitStats? _stats;

  List<Habit> get habits => List.unmodifiable(_habits);
  List<Habit> get activeHabits => _habits.where((h) => h.enabled).toList();
  List<Habit> get pausedHabits => _habits.where((h) => !h.enabled).toList();

  /// Statistics snapshot; rebuilt lazily after every change or day rollover.
  HabitStats get stats {
    final s = _stats;
    if (s != null && isSameDay(s.today, DateTime.now())) return s;
    return _stats = HabitStats(_habits, _completions);
  }

  Habit? byId(String id) {
    for (final h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  bool isDone(Habit h, DateTime day) =>
      _completions[h.id]?.contains(dayKey(day)) ?? false;

  /// Toggles completion. Future days cannot be checked off.
  void toggle(Habit h, DateTime day) {
    if (dateOnly(day).isAfter(today())) return;
    final set = _completions.putIfAbsent(h.id, () => <String>{});
    final key = dayKey(day);
    if (!set.remove(key)) set.add(key);
    _changed();
  }

  void add(Habit h) {
    _habits.add(h);
    _changed();
  }

  void update(Habit h) {
    final i = _habits.indexWhere((x) => x.id == h.id);
    if (i == -1) return;
    _habits[i] = h;
    _changed();
  }

  void delete(Habit h) {
    _habits.removeWhere((x) => x.id == h.id);
    _completions.remove(h.id);
    _changed();
  }

  // ---- Developer mode demo data -------------------------------------------

  static const demoPrefix = 'demo_';

  static bool isDemo(Habit h) => h.id.startsWith(demoPrefix);

  bool get hasDemoData => _habits.any(isDemo);

  /// Adds sample habits with ~4 months of plausible history. Real habits are
  /// left untouched. Any previous demo data is replaced.
  void seedDemoData() {
    _removeDemo();
    final now = today();
    final start = addDays(now, -120);
    // (key, name, icon, category, color, goal, weekdays, success %)
    const specs = [
      (
        'read',
        'Read Book',
        'book',
        'Learning',
        0xFF2F80ED,
        '30 minutes',
        <int>[],
        90,
      ),
      (
        'water',
        'Drink Water',
        'water',
        'Health',
        0xFF14B8A6,
        '8 glasses',
        <int>[],
        80,
      ),
      (
        'run',
        'Exercise',
        'run',
        'Fitness',
        0xFF2E9B3F,
        '20 minutes',
        [1, 2, 3, 4, 5],
        65,
      ),
      ('food', 'Eat Healthy', 'food', 'Nutrition', 0xFFEB5757, '', <int>[], 70),
      (
        'meditate',
        'Meditate',
        'meditate',
        'Mindfulness',
        0xFF8B5CF6,
        '10 minutes',
        <int>[],
        55,
      ),
      (
        'sleep',
        'Sleep Early',
        'sleep',
        'Lifestyle',
        0xFFF2994A,
        'Before 11 PM',
        [7, 1, 2, 3, 4],
        60,
      ),
    ];
    final rnd = Random(42);
    for (final (key, name, icon, category, color, goal, weekdays, rate)
        in specs) {
      final h = Habit(
        id: '$demoPrefix$key',
        name: name,
        iconKey: icon,
        category: category,
        colorValue: color,
        goal: goal,
        weekdays: weekdays,
        createdAt: start,
      );
      _habits.add(h);
      final done = _completions[h.id] = <String>{};
      for (var d = start; d.isBefore(now); d = addDays(d, 1)) {
        // Consistency improves over time so the trends look meaningful.
        final progress = d.difference(start).inDays / 120;
        final chance = rate - 20 + (25 * progress);
        if (h.isScheduledOn(d) && rnd.nextInt(100) < chance) {
          done.add(dayKey(d));
        }
      }
      // A clean recent streak, and part of today already done.
      for (var i = 1; i <= 6; i++) {
        final d = addDays(now, -i);
        if (h.isScheduledOn(d)) done.add(dayKey(d));
      }
      if (key == 'read' || key == 'water') done.add(dayKey(now));
    }
    _changed();
  }

  /// Removes every demo habit and its history.
  void clearDemoData() {
    _removeDemo();
    _changed();
  }

  void _removeDemo() {
    _completions.removeWhere((id, _) => id.startsWith(demoPrefix));
    _habits.removeWhere(isDemo);
  }

  static String newId() {
    final r = Random();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${r.nextInt(1 << 20).toRadixString(36)}';
  }

  void _changed() {
    _stats = null;
    notifyListeners();
    _save();
  }

  void _load() {
    try {
      final rawHabits = _prefs.getString(_habitsKey);
      if (rawHabits != null) {
        _habits.addAll(
          (jsonDecode(rawHabits) as List).map(
            (e) => Habit.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
      final rawDone = _prefs.getString(_completionsKey);
      if (rawDone != null) {
        (jsonDecode(rawDone) as Map<String, dynamic>).forEach((id, days) {
          _completions[id] = (days as List).cast<String>().toSet();
        });
      }
    } catch (e) {
      debugPrint('HabitStore: failed to load saved data: $e');
    }
  }

  Future<void> _save() async {
    await _prefs.setString(
      _habitsKey,
      jsonEncode(_habits.map((h) => h.toJson()).toList()),
    );
    await _prefs.setString(
      _completionsKey,
      jsonEncode(_completions.map((k, v) => MapEntry(k, v.toList()))),
    );
  }
}
