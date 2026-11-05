import 'package:flutter/material.dart';
import '../../../../core/models/vrat_observance.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/repositories/mantra_repository.dart';
import '../../../../state/audio_state.dart';
import '../../../../state/panchangam_state.dart';
import '../../../../state/sadhana_state.dart';
import '../../../../state/vrat_state.dart';
import '../../festivals/festival_calendar_screen.dart';
import '../../vrat/vrat_calendar_screen.dart';
import '../../vrat/vrat_detail_screen.dart';

/// Upcoming Vrat and Observances card on the Devotee Home Dashboard.
///
/// Features:
/// - Reuses VratState to show the next upcoming or active observance.
/// - Displays observance title, target date, fasting status, and checklist completion progress.
/// - Clearly distinguishes calculated calendar observances from user-created vrats.
/// - Handles empty state with direct pathways to both Festival Calendar and Vrat templates.
/// - Direct actions to open observance details/checklist, Festival Calendar, or Vrat Calendar.
class UpcomingVratCard extends StatelessWidget {
  final VratState vratState;
  final PanchangamState? panchangamState;
  final SadhanaState? sadhanaState;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;

  const UpcomingVratCard({
    super.key,
    required this.vratState,
    this.panchangamState,
    this.sadhanaState,
    this.mantraRepository,
    this.audioState,
  });

  void _openVratDetail(BuildContext context, VratObservance observance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VratDetailScreen(
          observanceId: observance.id,
          vratState: vratState,
          sadhanaState: sadhanaState,
          mantraRepository: mantraRepository,
          audioState: audioState,
          panchangamState: panchangamState,
        ),
      ),
    );
  }

  void _openVratCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VratCalendarScreen(
          vratState: vratState,
          panchangamState: panchangamState,
          sadhanaState: sadhanaState,
          mantraRepository: mantraRepository,
          audioState: audioState,
        ),
      ),
    );
  }

  void _openFestivalCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FestivalCalendarScreen(
          vratState: vratState,
          panchangamState: panchangamState,
          sadhanaState: sadhanaState,
          mantraRepository: mantraRepository,
          audioState: audioState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeObservances = vratState.activeObservances;
    final nextVrat = activeObservances.isNotEmpty ? activeObservances.first : null;

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
                        Icons.event_note,
                        size: 18,
                        color: AppColors.saffronPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'UPCOMING VRAT & OBSERVANCES',
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _openFestivalCalendar(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Festivals',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                          ),
                        ),
                      ),
                    ),
                    const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    InkWell(
                      onTap: () => _openVratCalendar(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'My Vrat',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.saffronPrimary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content: Active Observance vs Empty State
            if (nextVrat != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFBF8F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nextVrat.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: nextVrat.status == ObservanceStatus.inProgress
                                ? AppColors.saffronPrimary.withAlpha(25)
                                : Colors.green.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: nextVrat.status == ObservanceStatus.inProgress
                                  ? AppColors.saffronPrimary
                                  : Colors.green,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            nextVrat.status == ObservanceStatus.inProgress
                                ? 'FASTING TODAY'
                                : 'PLANNED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: nextVrat.status == ObservanceStatus.inProgress
                                  ? AppColors.saffronPrimary
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${nextVrat.targetDate} • ${nextVrat.location.split('(').first.trim()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.goldLight : AppColors.goldDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (nextVrat.personalIntention.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        nextVrat.personalIntention,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Checklist Progress Row
                    Row(
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 15,
                          color: isDark ? AppColors.goldLight : AppColors.goldDark,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Checklist: ${nextVrat.checklist.where((c) => c.isDone).length} of ${nextVrat.checklist.length} devotional steps completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action button to view details and checklist
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.menu_book, size: 16),
                  label: const Text('View Observance & Checklist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                    foregroundColor: isDark ? AppColors.goldLight : AppColors.goldDark,
                    side: BorderSide(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => _openVratDetail(context, nextVrat),
                ),
              ),
            ] else ...[
              // Empty State
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                    Icon(Icons.calendar_month_outlined, size: 28, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                    const SizedBox(height: 6),
                    Text(
                      'No Upcoming Vrat Scheduled',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Schedule Ekadashi, Pradosham, or custom vrat observances with reminders.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event, size: 14),
                            label: const Text('Festivals', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.saffronPrimary,
                              side: const BorderSide(color: AppColors.saffronPrimary, width: 1.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openFestivalCalendar(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 14),
                            label: const Text('Explore Vrat Calendar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.goldLight : AppColors.goldDark,
                              side: BorderSide(color: isDark ? AppColors.goldLight : AppColors.goldDark, width: 1.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openVratCalendar(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
