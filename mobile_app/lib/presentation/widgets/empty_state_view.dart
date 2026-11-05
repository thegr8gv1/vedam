import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_stories_outlined,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.nightSurfaceElevated : AppColors.saffronLight,
              ),
              child: Icon(
                icon,
                size: 36,
                color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.titleMedium(isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall(isDark),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Section8GovernanceBanner extends StatelessWidget {
  const Section8GovernanceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26190B) : AppColors.draftWarningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF8C5311) : AppColors.draftWarningBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 20,
            color: isDark ? const Color(0xFFFCD34D) : AppColors.draftWarning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.section8NoticeHeader,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Original Sanskrit source and transliteration are canonical. English & regional translations remain under peer review; draft meanings are for devotional study and are not certified as final doctrinal authority.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
