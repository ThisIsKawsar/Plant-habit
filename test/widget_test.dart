import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_habit/app.dart';
import 'package:plant_habit/data/habit_store.dart';
import 'package:plant_habit/data/settings_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<HabitStore> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final habits = HabitStore(prefs);
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: habits),
        ChangeNotifierProvider.value(value: SettingsStore(prefs)),
      ],
      child: const PlantHabitApp(),
    ),
  );
  await tester.pumpAndSettle();
  return habits;
}

void main() {
  testWidgets('add a habit and complete it from Home', (tester) async {
    final store = await pumpApp(tester);
    expect(find.text('No habits yet'), findsOneWidget);

    await tester.ensureVisible(find.text('Add Habit').first);
    await tester.tap(find.text('Add Habit').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Read Book');
    await tester.ensureVisible(find.text('Save Habit'));
    await tester.tap(find.text('Save Habit'));
    await tester.pumpAndSettle();

    expect(store.habits.single.name, 'Read Book');
    expect(find.text('0 / 1'), findsOneWidget);

    await tester.tap(find.text('Read Book'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('every tab renders with data', (tester) async {
    final store = await pumpApp(tester);
    await tester.ensureVisible(find.text('Add Habit').first);
    await tester.tap(find.text('Add Habit').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Drink Water');
    await tester.ensureVisible(find.text('Save Habit'));
    await tester.tap(find.text('Save Habit'));
    await tester.pumpAndSettle();
    store.toggle(store.habits.single, DateTime.now());

    for (final tab in ['Stats', 'Calendar', 'Settings', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }

    await tester.tap(find.text('Stats').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    expect(find.text('Best Habit'), findsOneWidget);

    // Heatmap is a Stats tab and is no longer listed in Settings.
    await tester.tap(find.text('Heatmap'));
    await tester.pumpAndSettle();
    // Heatmap follows the Week / This Month / Last 3 Months period menu.
    for (final period in ['Week', 'Last 3 Months']) {
      await tester.tap(find.byTooltip('Time period'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(period).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: period);
    }
    expect(find.text('3 Months'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Heatmap'), findsNothing);
    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('Terms of Service'), findsNothing);
  });

  testWidgets('3 taps on version enables developer mode with demo data; '
      'switching it off removes only the demo data', (tester) async {
    final store = await pumpApp(tester);
    await tester.ensureVisible(find.text('Add Habit').first);
    await tester.tap(find.text('Add Habit').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'My Real Habit');
    await tester.ensureVisible(find.text('Save Habit'));
    await tester.tap(find.text('Save Habit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('About App'));
    await tester.pumpAndSettle();
    expect(find.text('Developer mode'), findsNothing);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('v1.0.0'));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    final settings = tester
        .element(find.byType(Scaffold).last)
        .read<SettingsStore>();
    expect(settings.value.developerMode, isTrue);
    expect(store.hasDemoData, isTrue);
    expect(store.habits.length, greaterThan(1));
    expect(find.text('Developer mode'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(settings.value.developerMode, isFalse);
    expect(store.hasDemoData, isFalse);
    expect(store.habits.map((h) => h.name), ['My Real Habit']);
    expect(find.text('Developer mode'), findsNothing);
  });
}
