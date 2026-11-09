import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/guided_sadhana_session.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/state/sadhana_state.dart';

/// Modal bottom sheet displaying the devotee's local, offline history of
/// completed and concluded guided Sadhana sessions.
class SadhanaHistoryModal extends StatelessWidget {
  final SadhanaState sadhanaState;

  const SadhanaHistoryModal({
    super.key,
    required this.sadhanaState,
  });

  static Future<void> show(BuildContext context, SadhanaState sadhanaState) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SadhanaHistoryModal(sadhanaState: sadhanaState),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m ${dt.day}, ${dt.year} • $h:$min';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Sadhana History?'),
        content: const Text(
          'This will delete your local record of past guided Sadhana sessions. '
          'Your active routine and saved preferences will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await sadhanaState.clearSadhanaHistory();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sadhana history cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = sadhanaState.sadhanaHistory;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Modal Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu, color: AppColors.saffronPrimary, size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sadhana History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${history.length} sessions recorded locally',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (history.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    ),
                    onPressed: () => _confirmClearHistory(context),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),

          // History Session List
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.self_improvement,
                            size: 48,
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Guided Sadhana History Yet',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'When you complete or conclude a guided Sadhana practice flow, your session details will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: history.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isCompleted = item.status == SadhanaSessionStatus.completed;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isCompleted
                                ? Colors.green.withAlpha(100)
                                : isDark
                                    ? AppColors.nightBorder
                                    : AppColors.chandanBorder,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.sadhanaTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? Colors.green.withAlpha(30)
                                          : Colors.amber.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCompleted ? Colors.green : Colors.amber,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      item.status.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted ? Colors.green : Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 13,
                                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(item.startTime),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Duration: ${_formatDuration(item.durationSeconds)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item.completedStepIds.length} steps completed'
                                '${item.skippedStepIds.isNotEmpty ? " • ${item.skippedStepIds.length} optional skipped" : ""}'
                                '${item.japaSessionId != null ? " • Japa integrated" : ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
