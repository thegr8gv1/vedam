import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/models/vrat_observance.dart';
import '../../../core/models/devotional_reminder.dart';
import '../../../data/fixtures/authentic_mantras_data.dart';
import '../../../data/fixtures/authentic_puja_guides_data.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../state/audio_state.dart';
import '../../../state/panchangam_state.dart';
import '../../../state/sadhana_state.dart';
import '../../../state/vrat_state.dart';
import '../mantras/mantra_player_screen.dart';
import '../sadhana/guided_puja_screen.dart';
import 'add_edit_vrat_modal.dart';

class VratDetailScreen extends StatefulWidget {
  final String observanceId;
  final VratState vratState;
  final SadhanaState? sadhanaState;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;
  final PanchangamState? panchangamState;

  const VratDetailScreen({
    super.key,
    required this.observanceId,
    required this.vratState,
    this.sadhanaState,
    this.mantraRepository,
    this.audioState,
    this.panchangamState,
  });

  @override
  State<VratDetailScreen> createState() => _VratDetailScreenState();
}

class _VratDetailScreenState extends State<VratDetailScreen> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final obs = widget.vratState.getObservanceById(widget.observanceId);
    _notesController = TextEditingController(text: obs?.personalNotes ?? '');
    widget.vratState.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.vratState.removeListener(_onStateChange);
    _notesController.dispose();
    super.dispose();
  }

  void _showAddChecklistDialog(BuildContext context, VratObservance obs) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Preparation Step'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'e.g. Prepare clean ghee lamp and flowers',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final newItem = VratChecklistItem(
                  id: 'chk_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.trim(),
                  category: 'personal',
                );
                widget.vratState.addChecklistItem(obs.id, newItem);
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, VratObservance obs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Observance?'),
        content: Text('Remove "${obs.title}" from your personal calendar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              widget.vratState.deleteObservance(obs.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Return to calendar
            },
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  void _saveNotes(VratObservance obs) {
    widget.vratState.updateObservance(
      obs.copyWith(personalNotes: _notesController.text.trim()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Personal notes saved.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildObservanceReminderCard(BuildContext context, VratObservance obs, bool isDark) {
    final reminder = widget.vratState.getReminderForVrat(obs.id);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reminder != null && reminder.isEnabled ? Icons.alarm_on : Icons.alarm,
                  size: 20,
                  color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OBSERVANCE REMINDER',
                    style: AppTextStyles.metadataTag(isDark),
                  ),
                ),
                if (reminder != null)
                  Switch(
                    value: reminder.isEnabled,
                    activeThumbColor: AppColors.saffronPrimary,
                    onChanged: (val) async {
                      await widget.vratState.toggleReminder(reminder.id, val);
                      if (mounted) setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (reminder == null) ...[
              Text(
                'Schedule Morning Observance Notification',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Receive a peaceful reminder at 6:00 AM on ${obs.targetDate} in your local device timezone.',
                style: AppTextStyles.caption(isDark),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_alarm, size: 18),
                label: const Text('SET REMINDER (6:00 AM)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                  side: BorderSide(
                    color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                  ),
                ),
                onPressed: () async {
                  final newRem = DevotionalReminder(
                    id: 'rem_vrat_${obs.id}',
                    type: ReminderType.personalVrat,
                    title: '${obs.title} Reminder',
                    body: 'Today is your planned observance of ${obs.title}. May your practice be peaceful.',
                    scheduledDate: obs.targetDate,
                    hour: 6,
                    minute: 0,
                    isEnabled: true,
                    repeatDaily: false,
                    linkedVratId: obs.id,
                  );
                  await widget.vratState.addReminder(newRem);
                  if (mounted) setState(() {});
                },
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduled for ${reminder.formattedTime}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                          ),
                        ),
                        Text(
                          reminder.isEnabled
                              ? 'Active on ${obs.targetDate} (device timezone)'
                              : 'Reminder paused (disabled)',
                          style: AppTextStyles.caption(isDark),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.access_time, size: 16),
                    label: const Text('Change Time'),
                    onPressed: () async {
                      final current = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: current,
                      );
                      if (picked != null) {
                        final updated = reminder.copyWith(hour: picked.hour, minute: picked.minute);
                        await widget.vratState.updateReminder(updated);
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ObservanceStatus status) {
    switch (status) {
      case ObservanceStatus.planned:
        return Colors.blue;
      case ObservanceStatus.inProgress:
        return Colors.orange;
      case ObservanceStatus.completed:
        return Colors.green;
      case ObservanceStatus.skipped:
      case ObservanceStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ObservanceStatus status) {
    switch (status) {
      case ObservanceStatus.planned:
        return 'PLANNED';
      case ObservanceStatus.inProgress:
        return 'IN PROGRESS';
      case ObservanceStatus.completed:
        return 'COMPLETED';
      case ObservanceStatus.skipped:
        return 'SKIPPED';
      case ObservanceStatus.cancelled:
        return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final obs = widget.vratState.getObservanceById(widget.observanceId);

    if (obs == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Observance Details')),
        body: const Center(child: Text('Observance not found or has been removed.')),
      );
    }

    final guide = obs.associatedPujaGuideId != null
        ? AuthenticPujaGuidesData.getGuideById(obs.associatedPujaGuideId!)
        : null;

    final mantra = obs.associatedMantraId != null
        ? (widget.mantraRepository?.getMantraById(obs.associatedMantraId!) ??
            AuthenticMantrasData.getMantraById(obs.associatedMantraId!))
        : null;

    final completedCount = obs.checklist.where((c) => c.isDone).length;
    final totalCount = obs.checklist.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Observance Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Observance',
            onPressed: () {
              AddEditVratModal.show(
                context: context,
                vratState: widget.vratState,
                panchangamState: widget.panchangamState,
                existingObservance: obs,
              ).then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
            onPressed: () => _showDeleteDialog(context, obs),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Fasting Safety Advisory Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF221A12) : const Color(0xFFFFF9ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade700.withAlpha(120), width: 1.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.health_and_safety_outlined, size: 20, color: AppColors.saffronPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRADITIONAL FASTING & HEALTH ADVISORY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          obs.fastingNotice,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.amber[100] : const Color(0xFF5D4037),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 1. Status Bar & Status Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFBF8F3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _getStatusColor(obs.status).withAlpha(120),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor(obs.status),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusLabel(obs.status),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(obs.status),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton<ObservanceStatus>(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CHANGE STATUS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                        onSelected: (newStatus) {
                          widget.vratState.updateObservanceStatus(obs.id, newStatus);
                          setState(() {});
                        },
                        itemBuilder: (_) => ObservanceStatus.values
                            .map((s) => PopupMenuItem(
                                  value: s,
                                  child: Text(_getStatusLabel(s)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('Planned', style: TextStyle(fontSize: 11)),
                        selected: obs.status == ObservanceStatus.planned,
                        onSelected: (val) {
                          if (val) {
                            widget.vratState.updateObservanceStatus(obs.id, ObservanceStatus.planned);
                            setState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('In Progress', style: TextStyle(fontSize: 11)),
                        selected: obs.status == ObservanceStatus.inProgress,
                        onSelected: (val) {
                          if (val) {
                            widget.vratState.markObservanceInProgress(obs.id);
                            setState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Completed', style: TextStyle(fontSize: 11)),
                        selected: obs.status == ObservanceStatus.completed,
                        onSelected: (val) {
                          if (val) {
                            widget.vratState.markObservanceCompleted(obs.id);
                            setState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Skipped', style: TextStyle(fontSize: 11)),
                        selected: obs.status == ObservanceStatus.skipped,
                        onSelected: (val) {
                          if (val) {
                            widget.vratState.markObservanceSkipped(obs.id);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (obs.status == ObservanceStatus.skipped) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 16, color: AppColors.saffronPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Devotee Comfort Note: Skipping or postponing an observance due to health, work, or family circumstances carries zero spiritual deficit or fault. Bhavana (devotion in heart) is supreme.',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 2. Observance Hero Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (obs.sanskritTitle.isNotEmpty)
                      Text(
                        obs.sanskritTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldGlow : AppColors.textDarkPrimary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      obs.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event, size: 16, color: AppColors.saffronPrimary),
                            const SizedBox(width: 6),
                            Text(
                              obs.targetDate,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: obs.isManuallyCreated
                                ? (isDark ? Colors.purple.shade900.withAlpha(100) : Colors.purple.shade50)
                                : (isDark ? AppColors.goldDark.withAlpha(50) : const Color(0xFFF3E7D3)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            obs.isManuallyCreated ? 'PERSONAL PLANNED DATE' : 'TRADITIONAL CALENDAR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                              color: obs.isManuallyCreated
                                  ? (isDark ? Colors.purple.shade200 : Colors.purple.shade800)
                                  : (isDark ? AppColors.goldGlow : AppColors.goldDark),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          tooltip: 'Reschedule Date',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final current = DateTime.tryParse(obs.targetDate) ?? DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: current,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (picked != null) {
                              final y = picked.year.toString().padLeft(4, '0');
                              final m = picked.month.toString().padLeft(2, '0');
                              final d = picked.day.toString().padLeft(2, '0');
                              await widget.vratState.rescheduleObservance(obs.id, '$y-$m-$d');
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    if (obs.timingNotes != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.schedule, size: 14, color: AppColors.goldPrimary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              obs.timingNotes!,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark ? const Color(0xFFB8A692) : const Color(0xFF6F5E4B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (obs.sourceAttribution != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.saffronPrimary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tradition Source: ${obs.sourceAttribution!}',
                              style: AppTextStyles.caption(isDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            obs.location,
                            style: AppTextStyles.caption(isDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(obs.tradition),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Chip(
                          label: Text(obs.calendarConvention.name),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.nightSurface : const Color(0xFFF7F3EE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        obs.isManuallyCreated
                            ? 'Date Source: Manually planned personal date.'
                            : 'Date Source: Curated traditional template reference date. Exact Tithi observance requires local sunrise and Sampradaya verification.',
                        style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
                      ),
                    ),
                    if (obs.personalIntention.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.nightSurface : const Color(0xFFF7F3EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INTENTION (SANKALPA)',
                              style: AppTextStyles.metadataTag(isDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              obs.personalIntention,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Panchangam Information Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.goldDark.withAlpha(100) : AppColors.goldPrimary.withAlpha(100),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.saffronPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ASTRONOMICAL PANCHANGAM',
                            style: AppTextStyles.metadataTag(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (obs.panchangamSnapshot != null) ...[
                      Text(
                        'Tithi: ${obs.panchangamSnapshot!.tithiName} (${obs.panchangamSnapshot!.paksha})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (obs.panchangamSnapshot!.nakshatraName != null)
                        Text(
                          'Nakshatra: ${obs.panchangamSnapshot!.nakshatraName}',
                          style: AppTextStyles.caption(isDark),
                        ),
                      if (obs.panchangamSnapshot!.transitionTime != null)
                        Text(
                          'Transition: ${obs.panchangamSnapshot!.transitionTime}',
                          style: AppTextStyles.caption(isDark),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.nightSurface : const Color(0xFFFFF9ED),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withAlpha(120)),
                        ),
                        child: Text(
                          obs.panchangamSnapshot!.informationalNotice,
                          style: const TextStyle(fontSize: 11, color: Colors.brown),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Panchangam Calculation Unavailable',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No live astronomical snapshot was captured for this entry. Select your observance date according to your family calendar.',
                        style: AppTextStyles.caption(isDark),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Devotional Reminder for this Observance
            _buildObservanceReminderCard(context, obs, isDark),
            const SizedBox(height: 18),

            // 4. Preparation Checklist
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'PREPARATION CHECKLIST ($completedCount of $totalCount)',
                  style: AppTextStyles.metadataTag(isDark),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Step', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showAddChecklistDialog(context, obs),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...obs.checklist.map((item) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: item.isDone ? Colors.green.withAlpha(100) : Colors.grey.withAlpha(60),
                  ),
                ),
                child: CheckboxListTile(
                  value: item.isDone,
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                      color: item.isDone ? Colors.grey : null,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.green,
                  onChanged: (_) {
                    widget.vratState.toggleChecklistItem(obs.id, item.id);
                    setState(() {});
                  },
                ),
              );
            }),
            const SizedBox(height: 18),

            // 5. Associated Guided Puja Card
            if (guide != null) ...[
              Text('ASSOCIATED GUIDED PUJA', style: AppTextStyles.metadataTag(isDark)),
              const SizedBox(height: 6),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.self_improvement, size: 36, color: AppColors.saffronPrimary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '${guide.deity} • ${guide.estimatedDurationMinutes} mins',
                              style: AppTextStyles.caption(isDark),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final sadhanaState = widget.sadhanaState ?? SadhanaState();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuidedPujaScreen(
                                guide: guide,
                                sadhanaState: sadhanaState,
                                mantraRepository: widget.mantraRepository,
                                audioState: widget.audioState,
                              ),
                            ),
                          );
                        },
                        child: const Text('START'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 6. Associated Devotional Mantra Card
            if (mantra != null) ...[
              Text('ASSOCIATED DEVOTIONAL MANTRA', style: AppTextStyles.metadataTag(isDark)),
              const SizedBox(height: 6),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, size: 36, color: AppColors.goldPrimary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mantra.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '${mantra.deity} • 108 Repetitions',
                              style: AppTextStyles.caption(isDark),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.goldDark : AppColors.goldPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (widget.audioState != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MantraPlayerScreen(
                                  mantra: mantra,
                                  audioState: widget.audioState!,
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('CHANT'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 7. Personal Notes
            Text('PERSONAL REFLECTIONS & NOTES', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Record personal reflections, diet choices, or spiritual experiences...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save Notes',
                  onPressed: () => _saveNotes(obs),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
