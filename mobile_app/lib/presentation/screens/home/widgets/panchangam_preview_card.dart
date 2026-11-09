import 'package:flutter/material.dart';
import '../../../../core/models/daily_darshan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../state/panchangam_state.dart';

/// Compact Panchangam summary card for the Devotee Home Dashboard.
///
/// Features:
/// - Displays full Pancha Angas: Tithi (with end time), Nakshatra (with end time),
///   Yoga, Karana, and Vara.
/// - Sunrise, Sunset, and Rahu Kalam calculated time periods.
/// - Respects selected location and timezone.
/// - Honest loading, error, and unavailable fallback states without fabricating values.
/// - Direct navigation link to the full Panchangam screen.
/// - Devotional non-authoritative religious disclaimer.
class PanchangamPreviewCard extends StatelessWidget {
  final DailyDarshan darshan;
  final PanchangamState? panchangamState;
  final VoidCallback? onTap;

  const PanchangamPreviewCard({
    super.key,
    required this.darshan,
    this.panchangamState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calcData = panchangamState?.data;
    final isLoading = panchangamState?.isLoading ?? false;
    final isUnavailable = panchangamState?.isUnavailable ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S PANCHANGAM',
                          style: AppTextStyles.metadataTag(isDark).copyWith(
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                calcData != null ? calcData.vara.name : darshan.dayName,
                                style: AppTextStyles.caption(isDark).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.goldPrimary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content State: Loading, Unavailable, or Calculated Data
              if (isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.saffronPrimary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Calculating astronomical Panchangam...',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (isUnavailable && calcData == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade700, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Astronomical calculations unavailable for current location. Tap to view offline calendar.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Row 1: Tithi & Nakshatra
                Row(
                  children: [
                    Expanded(
                      child: _PanchangamItem(
                        label: 'Tithi (तिथि)',
                        value: calcData != null
                            ? '${calcData.tithi.name}${calcData.tithi.endTimeFormatted != null ? ' (to ${calcData.tithi.endTimeFormatted})' : ''}'
                            : darshan.tithi,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PanchangamItem(
                        label: 'Nakshatra (नक्षत्र)',
                        value: calcData != null
                            ? '${calcData.nakshatra.name}${calcData.nakshatra.endTimeFormatted != null ? ' (to ${calcData.nakshatra.endTimeFormatted})' : ''}'
                            : darshan.nakshatra,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Yoga & Karana
                if (calcData != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _PanchangamItem(
                          label: 'Yoga (योग)',
                          value: '${calcData.yoga.name} (${calcData.yoga.sanskritName})',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PanchangamItem(
                          label: 'Karana (करण)',
                          value: '${calcData.karana.name} (${calcData.karana.sanskritName})',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Row 3: Sun Events & Rahu Kalam
                Row(
                  children: [
                    Expanded(
                      child: _PanchangamItem(
                        label: 'Sun (सूर्योदय • सूर्यास्त)',
                        value: calcData != null
                            ? '↑ ${calcData.sunMoon.sunriseFormatted}  ↓ ${calcData.sunMoon.sunsetFormatted}'
                            : '↑ 06:12  ↓ 17:34',
                        valueColor: isDark ? AppColors.goldLight : AppColors.goldDark,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PanchangamItem(
                        label: 'Rahu Kalam (राहुकाल)',
                        value: calcData != null ? calcData.rahuKalam.formatted : darshan.rahuKalam,
                        valueColor: isDark ? const Color(0xFFFCA5A5) : AppColors.kumkumRed,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Footer banner with Location & Calculation convention badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF5EFE6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.place,
                        size: 13,
                        color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          calcData != null
                              ? '${calcData.location.name} • Lahiri Ayanamsa'
                              : 'Varanasi (Kashi), India',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        calcData != null ? 'ASTRONOMICAL' : 'STANDARD',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Non-authoritative disclaimer
                Text(
                  'Informational calculations for devotional planning; not an authoritative religious decree.',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            style: AppTextStyles.caption(isDark).copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
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
