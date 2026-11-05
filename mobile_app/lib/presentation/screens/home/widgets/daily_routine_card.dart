import 'package:flutter/material.dart';
import '../../../../core/models/puja_guide.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/fixtures/authentic_puja_guides_data.dart';
import '../../../../state/app_state.dart';
import '../../../../state/sadhana_state.dart';
import '../../sadhana/guided_puja_screen.dart';

/// Daily Spiritual Routine card on the Devotee Home Dashboard.
///
/// Features:
/// - Reuses existing SadhanaState without creating duplicate routine storage.
/// - Displays today's configured routines, completed vs remaining count, and progress bar.
/// - Clear completion indicator when all routines are completed.
/// - Toggleable routine checklist items directly on dashboard.
/// - Active Puja Guide resume banner if a session is currently in progress.
/// - Direct shortcuts to start a guided puja or open the full Sadhana screen.
class DailyRoutineCard extends StatelessWidget {
  final SadhanaState sadhanaState;
  final AppState appState;
  final VoidCallback onOpenSadhana;

  const DailyRoutineCard({
    super.key,
    required this.sadhanaState,
    required this.appState,
    required this.onOpenSadhana,
  });

  void _startOrResumePuja(BuildContext context, PujaGuide guide) {
    sadhanaState.startGuide(guide);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedPujaScreen(
          guide: guide,
          sadhanaState: sadhanaState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = sadhanaState.totalRoutineCount;
    final completed = sadhanaState.completedRoutineCount;
    final progress = sadhanaState.completionProgress;
    final isAllCompleted = total > 0 && completed >= total;
    final hasActivePuja = sadhanaState.hasActiveGuideSession;

    // Primary default guide: Ganesha Puja or Daily Nitya Puja
    final defaultGuide = AuthenticPujaGuidesData.allGuides.isNotEmpty
        ? AuthenticPujaGuidesData.allGuides.first
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.self_improvement,
                        size: 18,
                        color: AppColors.saffronPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'DAILY SPIRITUAL ROUTINE',
                          style: AppTextStyles.metadataTag(isDark).copyWith(
                            color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onOpenSadhana,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Sadhana',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.saffronPrimary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFBF8F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isAllCompleted
                              ? '॥ साधना पूर्णम् ॥ All Practices Complete'
                              : '$completed of $total Practices Completed',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isAllCompleted
                                ? (isDark ? AppColors.goldGlow : AppColors.verifiedGreen)
                                : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffronPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark ? AppColors.nightBorder : const Color(0xFFE5DDD0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAllCompleted ? AppColors.verifiedGreen : AppColors.saffronPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Active Guided Puja Session Resume Banner (if active)
            if (hasActivePuja && sadhanaState.activeGuide != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.saffronPrimary.withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.saffronPrimary, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill, size: 20, color: AppColors.saffronPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PUJA SESSION IN PROGRESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              color: AppColors.saffronPrimary,
                            ),
                          ),
                          Text(
                            '${sadhanaState.activeGuide!.title} • Step ${sadhanaState.activeGuideStepIndex + 1} of ${sadhanaState.activeGuide!.steps.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffronPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _startOrResumePuja(context, sadhanaState.activeGuide!),
                      child: const Text('Resume', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Active Routines Preview (up to 3 items)
            if (sadhanaState.activeRoutine.isNotEmpty) ...[
              ...sadhanaState.activeRoutine.take(3).map((practice) {
                final isDone = sadhanaState.completedPracticeIds.contains(practice.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => sadhanaState.togglePracticeCompletion(practice.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.nightSurfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDone
                              ? (isDark ? AppColors.verifiedGreen.withAlpha(120) : Colors.green.shade300)
                              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 18,
                            color: isDone ? AppColors.verifiedGreen : AppColors.textLightMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              practice.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                color: isDone
                                    ? (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted)
                                    : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                              ),
                            ),
                          ),
                          Text(
                            '${practice.estimatedMinutes} min',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 8),

            // Action Buttons Row: Start Guided Puja & Customize Routine
            Row(
              children: [
                if (defaultGuide != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.wb_sunny_outlined, size: 15),
                      label: const Text('Start Guided Puja', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.saffronPrimary,
                        side: const BorderSide(color: AppColors.saffronPrimary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _startOrResumePuja(context, defaultGuide),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.format_list_bulleted, size: 15),
                    label: const Text('Full Routine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                      foregroundColor: isDark ? AppColors.goldLight : AppColors.goldDark,
                      side: BorderSide(
                        color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onOpenSadhana,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
