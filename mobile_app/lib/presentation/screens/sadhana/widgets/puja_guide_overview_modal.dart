import 'package:flutter/material.dart';
import '../../../../core/models/puja_guide.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';

/// Modal bottom sheet presenting a comprehensive overview of a Guided Puja
/// before beginning the step-by-step worship experience.
class PujaGuideOverviewModal extends StatelessWidget {
  final PujaGuide guide;
  final int currentStepIndex;
  final VoidCallback onStart;

  const PujaGuideOverviewModal({
    super.key,
    required this.guide,
    this.currentStepIndex = 0,
    required this.onStart,
  });

  static Future<void> show({
    required BuildContext context,
    required PujaGuide guide,
    int currentStepIndex = 0,
    required VoidCallback onStart,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PujaGuideOverviewModal(
        guide: guide,
        currentStepIndex: currentStepIndex,
        onStart: onStart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isResume = currentStepIndex > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3A2814) : const Color(0xFFF3E7D3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              guide.editorialStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '~${guide.estimatedDurationMinutes} mins',
                            style: AppTextStyles.caption(isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        guide.title,
                        style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 18),
                      ),
                      if (guide.sanskritTitle.isNotEmpty)
                        Text(
                          guide.sanskritTitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close Overview',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Introduction & Context
                Text(
                  guide.shortIntro,
                  style: AppTextStyles.bodyMedium(isDark).copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF9F5EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.temple_hindu, size: 16, color: AppColors.goldPrimary),
                          const SizedBox(width: 6),
                          Text(
                            'PURPOSE & SIGNIFICANCE',
                            style: AppTextStyles.metadataTag(isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        guide.purposeAndContext,
                        style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Preparation Checklist
                Text(
                  'Preparation (Śaucam & Āsanam)',
                  style: AppTextStyles.titleSmall(isDark),
                ),
                const SizedBox(height: 8),
                ...guide.preparation.map(
                  (prep) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.saffronPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(prep, style: AppTextStyles.bodySmall(isDark)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Materials List
                Text(
                  'Suggested Materials (Pūjā Sāmagrī)',
                  style: AppTextStyles.titleSmall(isDark),
                ),
                const SizedBox(height: 8),
                ...guide.materialsList.map(
                  (mat) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.spa_outlined, size: 16, color: AppColors.goldPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(mat, style: AppTextStyles.bodySmall(isDark)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Ordered Steps Preview
                Text(
                  'Ordered Steps (${guide.steps.length} Steps)',
                  style: AppTextStyles.titleSmall(isDark),
                ),
                const SizedBox(height: 8),
                ...guide.steps.map(
                  (step) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E2214) : const Color(0xFFEFE6D8),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${step.stepNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.stepName,
                            style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (step.linkedMantraId != null)
                          const Icon(Icons.music_note, size: 14, color: AppColors.saffronPrimary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Regional & Sampradaya Variance Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF261D15) : const Color(0xFFFFF9F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.goldPrimary.withAlpha(100)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.goldPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRADITION & VARIANCE DISCLOSURE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              guide.regionalVarianceNote,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark ? const Color(0xFFB8A692) : const Color(0xFF6F5E4B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.nightSurfaceElevated : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onStart();
                },
                icon: Icon(isResume ? Icons.play_arrow : Icons.temple_hindu),
                label: Text(
                  isResume ? 'RESUME WORSHIP (STEP ${currentStepIndex + 1})' : 'BEGIN GUIDED WORSHIP',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
