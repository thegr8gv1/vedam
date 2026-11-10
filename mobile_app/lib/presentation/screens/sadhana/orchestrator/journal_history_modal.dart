import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../state/orchestrator_state.dart';

/// Modal bottom sheet displaying the devotee's local, offline devotional practice journal.
/// Shows completed daily practice sequences, dates, step counts, duration,
/// and calculated streak statistics. All data is strictly local and private.
class JournalHistoryModal extends StatelessWidget {
  final OrchestratorState orchestratorState;

  const JournalHistoryModal({
    super.key,
    required this.orchestratorState,
  });

  static Future<void> show(BuildContext context, OrchestratorState orchestratorState) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JournalHistoryModal(orchestratorState: orchestratorState),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthInt = int.tryParse(parts[1]) ?? 1;
        final day = parts[2];
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final monthStr = (monthInt >= 1 && monthInt <= 12) ? months[monthInt - 1] : parts[1];
        return '$monthStr $day, $year';
      }
    } catch (_) {}
    return isoDate;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Practice Journal?'),
        content: const Text(
          'This will permanently clear your local practice journal entries and streak history.\n\n'
          'Note: Your Japa counts, Guided Puja history, and Vrat records will remain untouched.',
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
            child: const Text('Clear Journal'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await orchestratorState.clearJournalHistory();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devotional practice journal cleared.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = orchestratorState.journalEntries;
    final streak = orchestratorState.streakReport;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
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
                    const Icon(
                      Icons.book_outlined,
                      color: AppColors.goldPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Devotional Practice Journal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Private local offline record',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entries.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Clear Journal History',
                        onPressed: () => _confirmClearHistory(context),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Streak stats banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.goldPrimary.withAlpha(30)
                      : AppColors.goldPrimary.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.goldPrimary.withAlpha(76),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.local_fire_department,
                      color: Colors.deepOrangeAccent,
                      label: 'Current Streak',
                      value: '${streak.currentStreak} ${streak.currentStreak == 1 ? "day" : "days"}',
                      theme: theme,
                    ),
                    Container(width: 1, height: 36, color: Colors.grey.withAlpha(76)),
                    _buildStatItem(
                      icon: Icons.emoji_events_outlined,
                      color: AppColors.goldPrimary,
                      label: 'Best Streak',
                      value: '${streak.longestStreak} ${streak.longestStreak == 1 ? "day" : "days"}',
                      theme: theme,
                    ),
                    Container(width: 1, height: 36, color: Colors.grey.withAlpha(76)),
                    _buildStatItem(
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      label: 'Total Days',
                      value: '${streak.totalPracticeDays}',
                      theme: theme,
                    ),
                  ],
                ),
              ),

              // Entries List
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.self_improvement,
                                size: 56,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No practice records yet',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete a morning or evening sadhana session to record your practice privately here.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: entries.length,
                        itemBuilder: (ctx, i) {
                          final entry = entries[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            color: isDark ? const Color(0xFF262638) : const Color(0xFFF9F9FC),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.sequenceName,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDate(entry.localDate),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.white60 : Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '${entry.completedStepCount} of ${entry.totalStepCount} steps',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.goldPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '•   ${entry.durationMinutes} min',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatTime(entry.completedAt),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.white38 : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (entry.completedStepTitles.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: entry.completedStepTitles.map((title) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            title,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontSize: 10,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
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
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withAlpha(180),
          ),
        ),
      ],
    );
  }
}
