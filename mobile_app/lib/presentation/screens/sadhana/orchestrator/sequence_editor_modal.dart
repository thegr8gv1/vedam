import 'package:flutter/material.dart';
import '../../../../core/models/practice_sequence.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../state/orchestrator_state.dart';

/// Modal bottom sheet allowing the devotee to customize, reorder,
/// enable/disable, add, and remove steps in a practice sequence.
class SequenceEditorModal extends StatefulWidget {
  final OrchestratorState orchestratorState;
  final PracticeSequence sequence;

  const SequenceEditorModal({
    super.key,
    required this.orchestratorState,
    required this.sequence,
  });

  static Future<void> show(
    BuildContext context, {
    required OrchestratorState orchestratorState,
    required PracticeSequence sequence,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SequenceEditorModal(
        orchestratorState: orchestratorState,
        sequence: sequence,
      ),
    );
  }

  @override
  State<SequenceEditorModal> createState() => _SequenceEditorModalState();
}

class _SequenceEditorModalState extends State<SequenceEditorModal> {
  late TextEditingController _nameController;
  late List<PracticeStep> _steps;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sequence.name);
    _steps = List.from(widget.sequence.steps);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
    });
  }

  void _toggleStepEnabled(int index) {
    setState(() {
      final s = _steps[index];
      _steps[index] = s.copyWith(isEnabled: !s.isEnabled);
    });
  }

  void _toggleStepOptional(int index) {
    setState(() {
      final s = _steps[index];
      _steps[index] = s.copyWith(isOptional: !s.isOptional);
    });
  }

  void _deleteStep(int index) {
    if (_steps.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A sequence must have at least one step.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _steps.removeAt(index);
    });
  }

  Future<void> _addNewStep() async {
    PracticeStepType selectedType = PracticeStepType.personalContemplation;
    final titleController = TextEditingController(text: 'Dhyana & Reflection');
    final timeController = TextEditingController(text: '5');
    bool isOptional = true;

    final added = await showDialog<PracticeStep>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Practice Step'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Step Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<PracticeStepType>(
                    initialValue: selectedType,
                    isExpanded: true,
                    items: PracticeStepType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          _stepTypeName(type),
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedType = val;
                          titleController.text = _defaultTitleForType(val);
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Step Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Estimated Minutes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: timeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    title: const Text('Optional step (can be skipped)', style: TextStyle(fontSize: 14)),
                    value: isOptional,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        isOptional = val ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final minutes = int.tryParse(timeController.text.trim()) ?? 5;
                  final step = PracticeStep(
                    id: 'step_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text.trim().isEmpty
                        ? _defaultTitleForType(selectedType)
                        : titleController.text.trim(),
                    description: 'Custom devotion step',
                    stepType: selectedType,
                    estimatedMinutes: minutes,
                    isOptional: isOptional,
                  );
                  Navigator.pop(ctx, step);
                },
                child: const Text('Add Step'),
              ),
            ],
          );
        },
      ),
    );

    if (added != null) {
      setState(() {
        _steps.add(added);
      });
    }
  }

  Future<void> _saveChanges() async {
    final updatedSeq = widget.sequence.copyWith(
      name: _nameController.text.trim().isEmpty ? widget.sequence.name : _nameController.text.trim(),
      steps: _steps,
      lastModified: DateTime.now(),
    );

    await widget.orchestratorState.saveSequence(updatedSeq);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${updatedSeq.name}" sequence.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Sequence to Defaults?'),
        content: const Text(
          'This will restore this sequence to its original traditional arrangement of steps.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      PracticeSequence defaultSeq;
      if (widget.sequence.type == PracticeSequenceType.morning) {
        defaultSeq = PracticeSequence.defaultMorning();
      } else if (widget.sequence.type == PracticeSequenceType.evening) {
        defaultSeq = PracticeSequence.defaultEvening();
      } else {
        defaultSeq = widget.sequence;
      }

      setState(() {
        _nameController.text = defaultSeq.name;
        _steps = List.from(defaultSeq.steps);
      });
    }
  }

  String _stepTypeName(PracticeStepType type) {
    switch (type) {
      case PracticeStepType.sankalpa:
        return 'Sankalpa (Sacred Resolve)';
      case PracticeStepType.guidedPuja:
        return 'Puja Worship';
      case PracticeStepType.japa:
        return 'Japa Meditation';
      case PracticeStepType.mantraAudio:
        return 'Devotional Audio Chanting';
      case PracticeStepType.scriptureStudy:
        return 'Scripture Reading & Study';
      case PracticeStepType.vratObservance:
        return 'Vrat & Upavasa Check';
      case PracticeStepType.personalContemplation:
        return 'Dhyana & Reflection';
    }
  }

  String _defaultTitleForType(PracticeStepType type) {
    switch (type) {
      case PracticeStepType.sankalpa:
        return 'Vedic Sankalpa';
      case PracticeStepType.guidedPuja:
        return 'Daily Worship Puja';
      case PracticeStepType.japa:
        return 'Mantra Japa';
      case PracticeStepType.mantraAudio:
        return 'Audio Listening';
      case PracticeStepType.scriptureStudy:
        return 'Daily Scripture Reading';
      case PracticeStepType.vratObservance:
        return 'Vrat Observance';
      case PracticeStepType.personalContemplation:
        return 'Dhyana & Reflection';
    }
  }

  IconData _stepTypeIcon(PracticeStepType type) {
    switch (type) {
      case PracticeStepType.sankalpa:
        return Icons.auto_stories;
      case PracticeStepType.guidedPuja:
        return Icons.flare;
      case PracticeStepType.japa:
        return Icons.radio_button_checked;
      case PracticeStepType.mantraAudio:
        return Icons.volume_up_outlined;
      case PracticeStepType.scriptureStudy:
        return Icons.menu_book;
      case PracticeStepType.vratObservance:
        return Icons.calendar_month;
      case PracticeStepType.personalContemplation:
        return Icons.self_improvement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.goldPrimary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customize Practice Sequence',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Reorder, enable/disable, or add steps',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Sequence Name (Editable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Sequence Name',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.edit, size: 18),
                  ),
                ),
              ),

              // Subheading & Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'Steps (${_steps.where((s) => s.isEnabled).length} active, ${_steps.fold<int>(0, (acc, s) => s.isEnabled ? acc + s.estimatedMinutes : acc)} min total)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Reset', style: TextStyle(fontSize: 12)),
                      onPressed: _confirmReset,
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Step', style: TextStyle(fontSize: 12)),
                      onPressed: _addNewStep,
                    ),
                  ],
                ),
              ),

              // Reorderable Steps List
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _steps.length,
                  onReorder: _onReorder,
                  itemBuilder: (ctx, index) {
                    final step = _steps[index];
                    return Card(
                      key: ValueKey(step.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: step.isEnabled
                              ? (isDark ? Colors.white12 : Colors.black12)
                              : Colors.grey.withAlpha(38),
                        ),
                      ),
                      color: step.isEnabled
                          ? (isDark ? const Color(0xFF262638) : const Color(0xFFF9F9FC))
                          : (isDark ? const Color(0xFF1B1B26) : const Color(0xFFF1F1F4)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            // Reorder Drag Handle
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_indicator, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            // Enable/Disable Switch
                            Switch.adaptive(
                              value: step.isEnabled,
                              activeTrackColor: AppColors.goldPrimary,
                              onChanged: (_) => _toggleStepEnabled(index),
                            ),
                            const SizedBox(width: 8),
                            // Icon
                            Icon(
                              _stepTypeIcon(step.stepType),
                              size: 20,
                              color: step.isEnabled ? AppColors.goldPrimary : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            // Step Title & Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: step.isEnabled
                                          ? null
                                          : (isDark ? Colors.white38 : Colors.black38),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '~${step.estimatedMinutes} min',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _toggleStepOptional(index),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: step.isOptional
                                                ? (isDark ? Colors.blue.withAlpha(51) : Colors.blue.withAlpha(26))
                                                : (isDark ? Colors.orange.withAlpha(51) : Colors.orange.withAlpha(26)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            step.isOptional ? 'Optional' : 'Required',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: step.isOptional ? Colors.blue : Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                              tooltip: 'Remove Step',
                              onPressed: () => _deleteStep(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Save Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Sequence',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
