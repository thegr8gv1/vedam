import 'package:flutter/material.dart';
import '../../../../core/models/daily_darshan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';

class DailyVerseCard extends StatelessWidget {
  final DailyDarshan darshan;
  final VoidCallback onReadFull;

  const DailyVerseCard({
    super.key,
    required this.darshan,
    required this.onReadFull,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.goldDark.withValues(alpha: 0.4) : AppColors.goldPrimary.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF221A15), const Color(0xFF181310)]
                : [const Color(0xFFFFFDF9), const Color(0xFFFBF6EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 18,
                      color: AppColors.saffronPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DAILY DEVOTIONAL DARSHAN',
                      style: AppTextStyles.metadataTag(isDark).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF332314) : AppColors.saffronLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    darshan.dateString,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              darshan.dailyVerseTitle,
              style: AppTextStyles.titleMedium(isDark).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF17120F) : const Color(0xFFFAF5ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    darshan.dailyVerseDevanagari,
                    style: AppTextStyles.verseDevanagari(isDark, scale: 0.95),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    darshan.dailyVerseIast,
                    style: AppTextStyles.verseTransliteration(isDark, scale: 0.9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bhavartha (Reflective Meaning):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              darshan.dailyVerseMeaningDraft,
              style: AppTextStyles.bodySmall(isDark),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    darshan.dailyVerseAttribution,
                    style: AppTextStyles.caption(isDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onReadFull,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Read Scripture',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                      ),
                    ],
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
