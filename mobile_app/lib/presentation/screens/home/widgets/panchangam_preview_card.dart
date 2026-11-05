import 'package:flutter/material.dart';
import '../../../../core/models/daily_darshan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';

class PanchangamPreviewCard extends StatelessWidget {
  final DailyDarshan darshan;

  const PanchangamPreviewCard({
    super.key,
    required this.darshan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.goldPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TODAY\'S PANCHANGAM',
                      style: AppTextStyles.metadataTag(isDark).copyWith(
                        color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  darshan.dayName,
                  style: AppTextStyles.caption(isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PanchangamItem(
                    label: 'Tithi (तिथि)',
                    value: darshan.tithi,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PanchangamItem(
                    label: 'Nakshatra (नक्षत्र)',
                    value: darshan.nakshatra,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PanchangamItem(
                    label: 'Abhijit Muhurat (शुभ)',
                    value: darshan.abhijitMuhurat,
                    valueColor: isDark ? AppColors.goldGlow : AppColors.verifiedGreen,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PanchangamItem(
                    label: 'Rahu Kalam (वर्ज्य)',
                    value: darshan.rahuKalam,
                    valueColor: isDark ? const Color(0xFFFCA5A5) : AppColors.kumkumRed,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF5EFE6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.self_improvement,
                    size: 14,
                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Presiding Deity: ${darshan.presidingDeity}',
                      style: AppTextStyles.caption(isDark).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanchangamItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _PanchangamItem({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(isDark),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
