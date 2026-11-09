import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/japa_practice_session.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/core/theme/text_styles.dart';
import 'package:vedam_app/state/audio_state.dart';


/// Modal bottom sheet displaying devotional Japa practice history.
///
/// Shows chronological records of completed and concluded sessions,
/// including mantra title, count, target, mode, duration, and completion status.
class JapaHistoryModal extends StatelessWidget {
  final AudioState audioState;

  const JapaHistoryModal({
    super.key,
    required this.audioState,
  });

  static Future<void> show(BuildContext context, AudioState audioState) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JapaHistoryModal(audioState: audioState),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, ${dt.year} • $hour:$minute $ampm';
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) {
      return '${d.inSeconds}s';
    } else if (d.inHours < 1) {
      return '${d.inMinutes}m';
    } else {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear Practice History?'),
          ],
        ),
        content: const Text(
          'This will remove all recorded Japa practice records from this device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await audioState.clearPracticeHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = audioState.sessionHistory;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  color: AppColors.saffronPrimary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Japa Practice History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldLight : AppColors.goldDark,
                        ),
                      ),
                      Text(
                        '${history.length} sessions recorded locally',
                        style: AppTextStyles.caption(isDark),
                      ),
                    ],
                  ),
                ),
                if (history.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear History',
                    onPressed: () => _confirmClearHistory(context),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            size: 64,
                            color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Practice History Yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Completed and concluded Japa chanting sessions will appear here with full count details.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption(isDark).copyWith(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: history.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final session = history[index];
                      final isCompleted = session.status == JapaSessionStatus.completed;

                      return Semantics(
                        label: 'Japa Session ${session.mantraTitle}, ${session.completedRepetitions} of ${session.targetRepetitions} repetitions, ${session.countingMode.displayName}, ${session.status.displayName}',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompleted
                                  ? (isDark ? Colors.green.shade800 : Colors.green.shade300)
                                  : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                              width: isCompleted ? 1.2 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Mantra & status badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session.mantraTitle,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.goldLight : AppColors.goldDark,
                                          ),
                                        ),
                                        if (session.deity != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            session.deity!.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.saffronPrimary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? Colors.green.withAlpha(30)
                                          : Colors.amber.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCompleted ? Colors.green : Colors.amber.shade700,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCompleted ? Icons.check_circle : Icons.timelapse,
                                          size: 12,
                                          color: isCompleted ? Colors.green : Colors.amber.shade800,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          session.status.displayName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted ? Colors.green : Colors.amber.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Middle row: Count metrics
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${session.completedRepetitions} / ${session.targetRepetitions} Chants',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.saffronPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: session.progressFraction,
                                          minHeight: 4,
                                          borderRadius: BorderRadius.circular(2),
                                          backgroundColor: isDark ? Colors.black26 : Colors.black12,
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            AppColors.saffronPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : Colors.white60,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      session.countingMode.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Bottom row: Time and duration
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDateTime(session.startTime),
                                    style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
                                  ),
                                  if (session.sessionDuration.inSeconds > 0)
                                    Text(
                                      'Duration: ${_formatDuration(session.sessionDuration)}',
                                      style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
                                    ),
                                ],
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