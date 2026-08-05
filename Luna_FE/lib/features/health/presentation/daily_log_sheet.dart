import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_modal.dart';
import '../../mood/domain/mood.dart';
import '../../symptom/domain/symptom.dart';
import '../domain/health_models.dart';

typedef SaveDailyLog =
    Future<void> Function(
      Mood mood,
      Set<Symptom> symptoms,
      int discomfortLevel,
      String note,
    );

class DailyLogSheet extends StatefulWidget {
  const DailyLogSheet({
    required this.date,
    required this.initial,
    required this.onSave,
    required this.onDeleteNote,
    this.errorMessage,
    super.key,
  });
  final DateTime date;
  final DailyLog initial;
  final SaveDailyLog onSave;
  final Future<void> Function() onDeleteNote;
  final String? errorMessage;

  @override
  State<DailyLogSheet> createState() => _DailyLogSheetState();
}

class _DailyLogSheetState extends State<DailyLogSheet> {
  late Mood _mood = widget.initial.mood ?? Mood.neutral;
  late final Set<Symptom> _symptoms = widget.initial.symptoms.toSet();
  late double _discomfort = (widget.initial.discomfortLevel ?? 0).toDouble();
  late final TextEditingController _note = TextEditingController(
    text: widget.initial.note,
  );
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhật ký ngày ${DateFormat('dd/MM/yyyy').format(widget.date)}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Tâm trạng', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: Mood.values
              .map(
                (mood) => Semantics(
                  label: 'Tâm trạng ${mood.label}',
                  selected: _mood == mood,
                  child: ChoiceChip(
                    avatar: Text(mood.emoji),
                    label: Text(mood.label),
                    selected: _mood == mood,
                    onSelected: (_) => setState(() => _mood = mood),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Triệu chứng', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: AppSpacing.xs,
          children: Symptom.values
              .map(
                (symptom) => FilterChip(
                  label: Text(symptom.label),
                  selected: _symptoms.contains(symptom),
                  onSelected: (selected) => setState(() {
                    selected
                        ? _symptoms.add(symptom)
                        : _symptoms.remove(symptom);
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Mức khó chịu: ${_discomfort.round()}/5'),
        Semantics(
          label: 'Mức khó chịu từ 0 đến 5',
          value: '${_discomfort.round()}',
          child: Slider(
            value: _discomfort,
            min: 0,
            max: 5,
            divisions: 5,
            label: '${_discomfort.round()}',
            onChanged: (value) => setState(() => _discomfort = value),
          ),
        ),
        TextField(
          controller: _note,
          maxLength: 4000,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Ghi chú sức khỏe'),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        if (widget.initial.note != null)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Xóa ghi chú',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        AppButton(label: 'Lưu nhật ký', isLoading: _saving, onPressed: _save),
      ],
    ),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_mood, _symptoms, _discomfort.round(), _note.text);
    } catch (_) {
      // The parent renders typed mutation feedback while this sheet resets.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await AppModal.confirm(
      context,
      title: 'Xóa ghi chú?',
      message: 'Tâm trạng và triệu chứng vẫn được giữ lại.',
      confirmLabel: 'Xóa',
    );
    if (!mounted) return;
    if (confirmed) await widget.onDeleteNote();
  }
}
