import 'package:flutter/material.dart';

/// Selectable habit icons, keyed by a stable string stored with each habit.
const habitIcons = <String, IconData>{
  'book': Icons.menu_book_rounded,
  'fitness': Icons.fitness_center_rounded,
  'water': Icons.water_drop_rounded,
  'food': Icons.restaurant_rounded,
  'sleep': Icons.bedtime_rounded,
  'plant': Icons.eco_rounded,
  'tea': Icons.emoji_food_beverage_rounded,
  'bike': Icons.directions_bike_rounded,
  'run': Icons.directions_run_rounded,
  'meditate': Icons.self_improvement_rounded,
  'walk': Icons.directions_walk_rounded,
  'write': Icons.edit_note_rounded,
  'code': Icons.code_rounded,
  'music': Icons.music_note_rounded,
  'savings': Icons.savings_rounded,
  'medicine': Icons.medication_rounded,
};

IconData iconFor(String key) => habitIcons[key] ?? Icons.eco_rounded;

class HabitCategory {
  const HabitCategory(this.name, this.icon);
  final String name;
  final IconData icon;
}

const habitCategories = [
  HabitCategory('Learning', Icons.menu_book_rounded),
  HabitCategory('Health', Icons.favorite_rounded),
  HabitCategory('Fitness', Icons.fitness_center_rounded),
  HabitCategory('Mindfulness', Icons.self_improvement_rounded),
  HabitCategory('Nutrition', Icons.restaurant_rounded),
  HabitCategory('Productivity', Icons.task_alt_rounded),
  HabitCategory('Lifestyle', Icons.wb_sunny_rounded),
  HabitCategory('Other', Icons.category_rounded),
];

IconData categoryIcon(String name) => habitCategories
    .firstWhere((c) => c.name == name, orElse: () => habitCategories.last)
    .icon;

class PaletteColor {
  const PaletteColor(this.name, this.color);
  final String name;
  final Color color;
}

/// Shared by the app accent palette and habit colors.
const palette = [
  PaletteColor('Green', Color(0xFF2E9B3F)),
  PaletteColor('Blue', Color(0xFF2F80ED)),
  PaletteColor('Purple', Color(0xFF8B5CF6)),
  PaletteColor('Orange', Color(0xFFF2994A)),
  PaletteColor('Red', Color(0xFFEB5757)),
  PaletteColor('Teal', Color(0xFF14B8A6)),
];

const goalPresets = [
  '15 minutes',
  '30 minutes',
  '1 hour',
  '8 glasses',
  '10 pages',
  '5,000 steps',
  '1 time',
];

const motivationalQuotes = [
  'Small steps. Big changes.',
  'Keep going, grow more.',
  'Consistency builds growth.',
  'Water your habits daily.',
  'Progress, not perfection.',
  'Every day is a fresh seed.',
  'Roots grow before blooms.',
];
