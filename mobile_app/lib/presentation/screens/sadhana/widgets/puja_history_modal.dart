import 'package:flutter/material.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/core/theme/text_styles.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';
import 'package:vedam_app/state/sadhana_state.dart';

/// Modal bottom sheet presenting devotee's local, offline Puja practice history.
class PujaHistoryModal extends StatelessWidget {
  final SadhanaState sadhanaState;

  const PujaHistoryModal({
    super.key,
    required this.sadhanaState,
  });

  static Future<void> show({
    required BuildContext context,
    required SadhanaState sadhanaState,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PujaHistoryModal(sadhanaState: sadhanaState),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year • $hour:$minute $amPm';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '< 1 min';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '${secs}s';
    if (secs == 0) return '${mins}m';
    return '${mins}m ${secs}s';
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Puja History?'),
        content: const Text(
          'This will permanently remove your local records of completed Puja sessions from this device. '
          'Your daily routine status for today will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      sadhanaState.clearPujaHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: sadhanaState,
      builder: (context, _) {
        final history = sadhanaState.pujaHistory;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.goldGlow : AppColors.goldPrimary,
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, size: 16, color: AppColors.goldPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  'DEVOTIONAL HISTORY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Completed Puja Sessions',
                              style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      if (history.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _confirmClearHistory(context),
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          label: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close History',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Expanded(
                  child: history.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: history.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final session = history[index];
                            final guide = AuthenticPujaGuidesData.getGuideById(session.guideId);
                            final title = guide?.title ?? 'Puja Worship';
                            final sanskritTitle = guide?.sanskritTitle ?? '';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.nightSurfaceElevated : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF332211) : const Color(0xFFF9EFE0),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.temple_hindu,
                                          color: AppColors.saffronPrimary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: AppTextStyles.bodyMedium(isDark).copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (sanskritTitle.isNotEmpty)
                                              Text(
                                                sanskritTitle,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDateTime(session.lastUpdatedTime),
                                              style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check, size: 12, color: Colors.green),
                                            SizedBox(width: 3),
                                            Text(
                                              'SAMPANNA',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 18),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDuration(session.durationSeconds),
                                        style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.check_circle_outline, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${session.completedStepIds.length} steps completed',
                                        style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      if (session.preparedMaterials.isNotEmpty) ...[
                                        const SizedBox(width: 16),
                                        Icon(Icons.inventory_2_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${session.preparedMaterials.length} materials',
                                          style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.temple_hindu_outlined,
              size: 54,
              color: isDark ? AppColors.goldGlow.withAlpha(120) : AppColors.goldDark.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No Puja Records Yet',
              style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              'As you complete guided daily worship procedures, your local private session history will be recorded here.',
              style: AppTextStyles.caption(isDark).copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
