import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../state/panchangam_state.dart';

/// Welcoming devotional header displaying time-aware greeting, current local date,
/// selected location, and sacred invocation shloka.
class DevotionalWelcomeHeader extends StatelessWidget {
  final DateTime currentDate;
  final PanchangamState? panchangamState;

  const DevotionalWelcomeHeader({
    super.key,
    required this.currentDate,
    this.panchangamState,
  });

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'शुभ प्रभातम् • Good Morning';
    } else if (hour < 17) {
      return 'शुभ मध्याह्नम् • Good Afternoon';
    } else {
      return 'शुभ संध्या • Good Evening';
    }
  }

  String _formatDate(DateTime d) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final weekday = weekdays[d.weekday - 1];
    final month = months[d.month - 1];
    return '$weekday, $month ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationName = panchangamState?.selectedLocation.name ?? 'Varanasi (Kashi), India';
    final greeting = _getGreeting(currentDate.hour);
    final formattedDate = _formatDate(currentDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1712) : const Color(0xFFF7F1E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Location Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.nightSurface : Colors.white).withAlpha(180),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 11,
                      color: AppColors.saffronPrimary,
                    ),
                    const SizedBox(width: 3),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        locationName.split(',').first,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Formatted Local Date
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Sacred Invocation Shloka Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.nightSurfaceElevated : Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                width: 0.6,
              ),
            ),
            child: Column(
              children: [
                Text(
                  AppConstants.invocationShloka,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.invocationTranslation,
                  style: AppTextStyles.caption(isDark).copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
