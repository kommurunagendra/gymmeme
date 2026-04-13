import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/activity_log_model.dart';
import '../../../features/archetypes/data/archetype_data.dart';
import '../providers/activity_log_provider.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  String _selectedMood = GymMood.focused;
  String _selectedArchetype = kArchetypes.first.id;
  int _durationMinutes = 60;
  final Set<String> _exerciseTypes = {};
  final Set<String> _tags = {};
  final _notesController = TextEditingController();
  bool _saving = false;

  static const _exerciseOptions = [
    ('Upper Body', 'upper'),
    ('Lower Body', 'lower'),
    ('Cardio', 'cardio'),
    ('Full Body', 'full_body'),
    ('Core', 'core'),
    ('Stretching', 'stretching'),
  ];

  static const _tagOptions = [
    '#PersonalRecord',
    '#FormFail',
    '#GymEtiquette',
    '#SkippedLegDay',
    '#Gains',
    '#CrunchTime',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(logNotifierProvider).addLog(
            mood: _selectedMood,
            selfTagArchetype: _selectedArchetype,
            durationMinutes: _durationMinutes,
            exerciseTypes: _exerciseTypes.toList(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            tags: _tags.toList(),
          );
      // Refresh providers
      ref.invalidate(allLogsProvider);
      ref.invalidate(recentLogsProvider);
      ref.invalidate(weeklyReportProvider);
      ref.invalidate(hasTodayLogProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session logged! 💪'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Session")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood
            _SectionHeader(title: 'How was your session?'),
            const SizedBox(height: 12),
            _MoodSelector(
              selected: _selectedMood,
              onChanged: (m) => setState(() => _selectedMood = m),
            ),
            const SizedBox(height: 24),

            // Duration
            _SectionHeader(title: 'Duration'),
            const SizedBox(height: 8),
            _DurationSlider(
              minutes: _durationMinutes,
              onChanged: (v) => setState(() => _durationMinutes = v),
            ),
            const SizedBox(height: 24),

            // Archetype self-tag
            _SectionHeader(title: 'Today I was a...'),
            const SizedBox(height: 8),
            _ArchetypeDropdown(
              selected: _selectedArchetype,
              onChanged: (v) => setState(() => _selectedArchetype = v),
            ),
            const SizedBox(height: 24),

            // Exercise types
            _SectionHeader(title: 'What did you train?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _exerciseOptions.map((opt) {
                final selected = _exerciseTypes.contains(opt.$2);
                return FilterChip(
                  label: Text(opt.$1),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _exerciseTypes.add(opt.$2);
                    } else {
                      _exerciseTypes.remove(opt.$2);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Tags
            _SectionHeader(title: 'Tags'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tagOptions.map((tag) {
                final selected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _tags.add(tag);
                    } else {
                      _tags.remove(tag);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Notes
            _SectionHeader(title: 'Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText:
                    'What happened today? Any PRs, fails, or funny moments?',
              ),
            ),
            const SizedBox(height: 32),

            // Save
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Log Session'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
      );
}

class _MoodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MoodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: GymMood.all.map((mood) {
        final isSelected = mood == selected;
        return GestureDetector(
          onTap: () => onChanged(mood),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(GymMood.emoji(mood),
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  GymMood.label(mood),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _DurationSlider({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${minutes}min',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        Slider(
          value: minutes.toDouble(),
          min: 10,
          max: 180,
          divisions: 34,
          label: '${minutes}min',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _ArchetypeDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ArchetypeDropdown(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: kArchetypes
          .map((a) => DropdownMenuItem(
                value: a.id,
                child: Row(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(a.name),
                  ],
                ),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
