import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/models/devotional_reminder.dart';
import '../../../core/services/reminder_service.dart';
import '../../../state/vrat_state.dart';

class RemindersSettingsScreen extends StatefulWidget {
  final VratState vratState;

  const RemindersSettingsScreen({
    super.key,
    required this.vratState,
  });

  @override
  State<RemindersSettingsScreen> createState() => _RemindersSettingsScreenState();
}

class _RemindersSettingsScreenState extends State<RemindersSettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.vratState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.vratState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _pickTime(DevotionalReminder reminder) async {
    final current = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );

    if (picked != null) {
      final updated = reminder.copyWith(hour: picked.hour, minute: picked.minute);
      widget.vratState.updateReminder(updated);
    }
  }

  void _showAddCustomReminderDialog() {
    final titleController = TextEditingController(text: 'Personal Contemplation');
    final bodyController = TextEditingController(text: 'Peaceful time for your spiritual practice.');
    TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(selectedTime.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: selectedTime);
                      if (t != null) {
                        setDialogState(() => selectedTime = t);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final newRem = DevotionalReminder(
                    id: 'rem_custom_${DateTime.now().millisecondsSinceEpoch}',
                    type: ReminderType.custom,
                    title: titleController.text.trim(),
                    body: bodyController.text.trim(),
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                    isEnabled: true,
                    repeatDaily: true,
                  );
                  widget.vratState.addReminder(newRem);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('ADD REMINDER'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reminders = widget.vratState.reminders;
    final permission = widget.vratState.permissionStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devotional Reminders'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Permission Status Banner
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: permission == ReminderPermissionStatus.granted
                      ? Colors.green.withAlpha(120)
                      : Colors.orange.withAlpha(120),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      permission == ReminderPermissionStatus.granted
                          ? Icons.check_circle_outline
                          : Icons.notifications_active_outlined,
                      color: permission == ReminderPermissionStatus.granted ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            permission == ReminderPermissionStatus.granted
                                ? 'Device Notifications Permitted'
                                : 'Notification Permission Needed',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            permission == ReminderPermissionStatus.granted
                                ? 'Reminders are scheduled locally in your device timezone.'
                                : 'Allow notification permission to receive gentle sadhana alerts.',
                            style: AppTextStyles.caption(isDark),
                          ),
                        ],
                      ),
                    ),
                    if (permission != ReminderPermissionStatus.granted)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => widget.vratState.requestNotificationPermission(),
                        child: const Text('ENABLE', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Devotional Respect Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : const Color(0xFFFBF8F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: AppColors.saffronPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All notifications run strictly locally on this device. No personal schedules or devotional data are uploaded remotely.',
                      style: AppTextStyles.caption(isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Reminders List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CONFIGURED REMINDERS', style: AppTextStyles.metadataTag(isDark)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Custom', style: TextStyle(fontSize: 12)),
                  onPressed: _showAddCustomReminderDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...reminders.map((r) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: r.isEnabled
                        ? (isDark ? AppColors.goldDark : AppColors.goldPrimary)
                        : Colors.grey.withAlpha(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Time button
                      InkWell(
                        onTap: () => _pickTime(r),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.nightSurface : const Color(0xFFF3ECE1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: AppColors.saffronPrimary),
                              const SizedBox(width: 5),
                              Text(
                                r.formattedTime,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & message
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              r.body,
                              style: AppTextStyles.caption(isDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Toggle switch
                      Switch(
                        value: r.isEnabled,
                        activeThumbColor: AppColors.saffronPrimary,
                        onChanged: (val) => widget.vratState.toggleReminder(r.id, val),
                      ),

                      // Delete action for custom or non-primary reminders
                      if (r.type == ReminderType.custom || r.linkedVratId != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete',
                          onPressed: () => widget.vratState.deleteReminder(r.id),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
