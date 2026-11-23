/// Calendar-day helpers. All habit logic works on local, time-free dates.
library;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime today() => dateOnly(DateTime.now());

/// Adds whole days without being affected by DST transitions.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime firstOfMonth(DateTime d) => DateTime(d.year, d.month);

/// Inclusive list of days from [start] to [end].
List<DateTime> daysBetween(DateTime start, DateTime end) {
  final out = <DateTime>[];
  for (var d = dateOnly(start); !d.isAfter(end); d = addDays(d, 1)) {
    out.add(d);
  }
  return out;
}

const monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Indexed by [DateTime.weekday] - 1 (Monday first).
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Calendar columns, Sunday first (as in the designs).
const calendarWeekdays = [7, 1, 2, 3, 4, 5, 6];

String formatLongDate(DateTime d) =>
    '${weekdayLong[d.weekday - 1]}, ${monthShort[d.month - 1]} ${d.day}';

String formatTimeOfDayMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final period = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $period';
}
