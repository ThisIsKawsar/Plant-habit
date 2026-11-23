import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/catalog.dart';
import '../core/dates.dart';
import '../core/theme.dart';
import '../data/habit_store.dart';
import '../models/habit.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

/// Creates a habit, or edits [existing] when provided.
class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key, this.existing});
  final Habit? existing;

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _goal;
  late String _iconKey;
  late String _category;
  late int _colorIndex;
  late bool _everyDay;
  late Set<int> _weekdays;
  late bool _reminder;
  late int _reminderMinutes;
  late bool _enabled;
  bool _showAllIcons = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _name = TextEditingController(text: h?.name ?? '');
    _description = TextEditingController(text: h?.description ?? '');
    _goal = TextEditingController(text: h?.goal ?? '');
    _iconKey = h?.iconKey ?? 'book';
    _category = h?.category ?? habitCategories.first.name;
    final ci = palette.indexWhere((p) => p.color.toARGB32() == h?.colorValue);
    _colorIndex = ci == -1 ? 0 : ci;
    _everyDay = h?.isEveryDay ?? true;
    _weekdays = {...?h?.weekdays};
    _reminder = h?.reminderEnabled ?? false;
    _reminderMinutes = h?.reminderMinutes ?? 21 * 60;
    _enabled = h?.enabled ?? true;
    // Make sure an edited habit's icon is visible without expanding.
    _showAllIcons = habitIcons.keys.toList().indexOf(_iconKey) >= 8;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _goal.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_everyDay && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day of the week')),
      );
      return;
    }
    final store = context.read<HabitStore>();
    final weekdays = _everyDay ? <int>[] : (_weekdays.toList()..sort());
    final color = palette[_colorIndex].color.toARGB32();
    final existing = widget.existing;
    if (existing != null) {
      store.update(
        existing.copyWith(
          name: _name.text.trim(),
          description: _description.text.trim(),
          iconKey: _iconKey,
          category: _category,
          colorValue: color,
          goal: _goal.text.trim(),
          weekdays: weekdays,
          reminderEnabled: _reminder,
          reminderMinutes: _reminderMinutes,
          enabled: _enabled,
        ),
      );
    } else {
      store.add(
        Habit(
          id: HabitStore.newId(),
          name: _name.text.trim(),
          description: _description.text.trim(),
          iconKey: _iconKey,
          category: _category,
          colorValue: color,
          goal: _goal.text.trim(),
          weekdays: weekdays,
          reminderEnabled: _reminder,
          reminderMinutes: _reminderMinutes,
          enabled: _enabled,
          createdAt: today(),
        ),
      );
    }
    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderMinutes ~/ 60,
        minute: _reminderMinutes % 60,
      ),
    );
    if (t != null) setState(() => _reminderMinutes = t.hour * 60 + t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = palette[_colorIndex].color;
    final icons = habitIcons.entries.toList();
    final visibleIcons = _showAllIcons ? icons : icons.take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Habit' : 'Add Habit'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete habit',
              icon: Icon(Icons.delete_outline_rounded, color: colors.missed),
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (await confirmDeleteHabit(context, widget.existing!)) {
                  navigator.pop();
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_isEdit) ...[
              Center(
                child: HabitAvatar(
                  icon: iconFor(_iconKey),
                  color: accent,
                  size: 76,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const _Label('Choose Icon'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in visibleIcons)
                  _IconChoice(
                    icon: e.value,
                    color: accent,
                    selected: e.key == _iconKey,
                    onTap: () => setState(() => _iconKey = e.key),
                  ),
                if (!_showAllIcons)
                  _IconChoice(
                    icon: Icons.more_horiz_rounded,
                    color: colors.muted,
                    selected: false,
                    tooltip: 'More icons',
                    onTap: () => setState(() => _showAllIcons = true),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _Label('Habit Name', required: true),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 40,
              decoration: const InputDecoration(
                hintText: 'e.g. Read Book',
                counterText: '',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a habit name'
                  : null,
            ),
            const SizedBox(height: 16),
            const _Label('Description (Optional)'),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'e.g. Read 20 pages daily…',
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Category'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: [
                for (final c in habitCategories)
                  DropdownMenuItem(
                    value: c.name,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 20, color: accent),
                        const SizedBox(width: 10),
                        Text(c.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            const _Label('Color'),
            ColorDots(
              colors: [for (final p in palette) p.color],
              selected: _colorIndex,
              onSelected: (i) => setState(() => _colorIndex = i),
            ),
            const SizedBox(height: 20),
            const _Label('Daily Goal'),
            TextFormField(
              controller: _goal,
              decoration: InputDecoration(
                hintText: 'e.g. 30 minutes, 8 glasses',
                prefixIcon: const Icon(Icons.schedule_rounded),
                suffixIcon: PopupMenuButton<String>(
                  tooltip: 'Choose a preset',
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onSelected: (v) => setState(() => _goal.text = v),
                  itemBuilder: (_) => [
                    for (final g in goalPresets)
                      PopupMenuItem(value: g, child: Text(g)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Frequency'),
            PillSelector<bool>(
              values: const [true, false],
              selected: _everyDay,
              labelOf: (v) => v ? 'Every Day' : 'Specific Days',
              onChanged: (v) => setState(() => _everyDay = v),
              filled: true,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _everyDay
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final wd in calendarWeekdays)
                            _DayToggle(
                              label: weekdayShort[wd - 1].substring(0, 1),
                              tooltip: weekdayLong[wd - 1],
                              selected: _weekdays.contains(wd),
                              color: accent,
                              onTap: () => setState(() {
                                if (!_weekdays.remove(wd)) _weekdays.add(wd);
                              }),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            const _Label('Reminder (Optional)'),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.notifications_none_rounded, color: colors.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _reminder ? _pickTime : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          _reminder
                              ? formatTimeOfDayMinutes(_reminderMinutes)
                              : 'Off',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _reminder ? null : colors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Switch(
                    value: _reminder,
                    onChanged: (v) => setState(() => _reminder = v),
                  ),
                ],
              ),
            ),
            if (_reminder)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Tap the time to change it. Reminders need notifications enabled in Settings.',
                  style: TextStyle(fontSize: 12, color: colors.muted),
                ),
              ),
            const SizedBox(height: 16),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.power_settings_new_rounded, color: colors.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Habit enabled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Paused habits are hidden from today and stats',
                          style: TextStyle(fontSize: 12, color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (_isEdit)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Update'),
                    ),
                  ),
                ],
              )
            else
              FilledButton(onPressed: _save, child: const Text('Save Habit')),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.of(context).missed),
              ),
          ],
        ),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.soft(context, color),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color : AppColors.of(context).track,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.of(context).muted,
            ),
          ),
        ),
      ),
    );
  }
}
