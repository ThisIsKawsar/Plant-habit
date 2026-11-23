import '../core/dates.dart';

class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.description = '',
    required this.iconKey,
    required this.category,
    required this.colorValue,
    this.goal = '',
    this.weekdays = const [],
    this.reminderEnabled = false,
    this.reminderMinutes = 21 * 60,
    this.enabled = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final String category;
  final int colorValue;

  /// Free-form daily goal, e.g. "30 minutes" or "8 glasses".
  final String goal;

  /// [DateTime.weekday] values the habit is scheduled on. Empty = every day.
  final List<int> weekdays;

  final bool reminderEnabled;

  /// Reminder time as minutes after midnight.
  final int reminderMinutes;

  /// Disabled (paused) habits are hidden from today's list and statistics.
  final bool enabled;

  /// The day the habit was created; it is not scheduled before this.
  final DateTime createdAt;

  bool get isEveryDay => weekdays.isEmpty || weekdays.length == 7;

  bool isScheduledOn(DateTime day) {
    final d = dateOnly(day);
    if (d.isBefore(createdAt)) return false;
    return isEveryDay || weekdays.contains(d.weekday);
  }

  String get frequencyLabel {
    if (isEveryDay) return 'Every day';
    final sorted = [...weekdays]..sort();
    if (sorted.length == 5 && !sorted.contains(6) && !sorted.contains(7)) {
      return 'Weekdays';
    }
    if (sorted.length == 2 && sorted.contains(6) && sorted.contains(7)) {
      return 'Weekends';
    }
    return sorted.map((w) => weekdayShort[w - 1]).join(', ');
  }

  Habit copyWith({
    String? name,
    String? description,
    String? iconKey,
    String? category,
    int? colorValue,
    String? goal,
    List<int>? weekdays,
    bool? reminderEnabled,
    int? reminderMinutes,
    bool? enabled,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      goal: goal ?? this.goal,
      weekdays: weekdays ?? this.weekdays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconKey': iconKey,
    'category': category,
    'colorValue': colorValue,
    'goal': goal,
    'weekdays': weekdays,
    'reminderEnabled': reminderEnabled,
    'reminderMinutes': reminderMinutes,
    'enabled': enabled,
    'createdAt': dayKey(createdAt),
  };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
    id: j['id'] as String,
    name: j['name'] as String,
    description: (j['description'] as String?) ?? '',
    iconKey: (j['iconKey'] as String?) ?? 'plant',
    category: (j['category'] as String?) ?? 'Other',
    colorValue: (j['colorValue'] as int?) ?? 0xFF2E9B3F,
    goal: (j['goal'] as String?) ?? '',
    weekdays: ((j['weekdays'] as List?) ?? const []).cast<int>(),
    reminderEnabled: (j['reminderEnabled'] as bool?) ?? false,
    reminderMinutes: (j['reminderMinutes'] as int?) ?? 21 * 60,
    enabled: (j['enabled'] as bool?) ?? true,
    createdAt: parseDayKey(j['createdAt'] as String),
  );
}
