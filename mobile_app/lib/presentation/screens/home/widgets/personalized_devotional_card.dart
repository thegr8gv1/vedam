import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/fixtures/authentic_puja_guides_data.dart';
import '../../../../data/repositories/mantra_repository.dart';
import '../../../../data/repositories/scripture_repository.dart';
import '../../../../state/app_state.dart';
import '../../../../state/audio_state.dart';
import '../../../../state/personalization_state.dart';
import '../../../../state/sadhana_state.dart';
import '../../library/scripture_detail_screen.dart';
import '../../mantras/mantra_player_screen.dart';
import '../../sadhana/guided_puja_screen.dart';

/// Personalized Devotional Focus & Daily Sadhana Goals card for the Devotee Home Dashboard.
///
/// Reflects devotee's selected deities, custom practice targets, and spiritual goals
/// without artificial gamification or intrusive pressure.
class PersonalizedDevotionalCard extends StatelessWidget {
  final PersonalizationState personalizationState;
  final AudioState audioState;
  final SadhanaState sadhanaState;
  final ScriptureRepository repository;
  final MantraRepository? mantraRepository;
  final AppState appState;

  const PersonalizedDevotionalCard({
    super.key,
    required this.personalizationState,
    required this.audioState,
    required this.sadhanaState,
    required this.repository,
    this.mantraRepository,
    required this.appState,
  });

  void _openScripture(BuildContext context, int scriptureId) async {
    final scripture = await repository.getScriptureById(scriptureId);
    if (scripture != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScriptureDetailScreen(
            scripture: scripture,
            appState: appState,
          ),
        ),
      );
    }
  }

  void _openPuja(BuildContext context, String guideId) {
    final guide = AuthenticPujaGuidesData.getGuideById(guideId);
    if (guide == null) return;
    sadhanaState.startGuide(guide);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedPujaScreen(
          guide: guide,
          sadhanaState: sadhanaState,
          mantraRepository: mantraRepository,
          audioState: audioState,
        ),
      ),
    );
  }

  void _openMantra(BuildContext context, String mantraId) {
    final repo = mantraRepository ?? MantraRepositoryImpl();
    final mantra = repo.getMantraById(mantraId);
    if (mantra != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MantraPlayerScreen(
            audioState: audioState,
            mantra: mantra,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = personalizationState.sadhanaGoals;
    final selectedDeities = personalizationState.selectedDeities;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 0.8,
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
                        Icons.temple_hindu,
                        size: 18,
                        color: AppColors.saffronPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'DEVOTIONAL FOCUS',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C1E14) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.saffronPrimary.withAlpha(80), width: 0.8),
                  ),
                  child: Text(
                    '${selectedDeities.length} Focus Deities',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Devotional Deity Focus Chips / Shortcuts
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedDeities.map((deity) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        // Open primary scripture or puja or mantra
                        if (deity.primaryScriptureId != null) {
                          _openScripture(context, deity.primaryScriptureId!);
                        } else if (deity.primaryPujaId != null) {
                          _openPuja(context, deity.primaryPujaId!);
                        } else if (deity.primaryMantraId != null) {
                          _openMantra(context, deity.primaryMantraId!);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(deity.icon, size: 16, color: AppColors.saffronPrimary),
                            const SizedBox(width: 6),
                            Text(
                              deity.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Daily Sadhana Goals Progress Summary
            Container(
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.self_improvement, size: 16, color: AppColors.goldPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Daily Sadhana Targets',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.goldLight : AppColors.goldDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Script: ${personalizationState.scriptureScript.label}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Goal 1: Japa
                  if (goals.hasJapaGoal) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Japa Repetitions',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${audioState.completedRepetitions} / ${goals.japaTarget}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: audioState.completedRepetitions >= goals.japaTarget
                                ? const Color(0xFF4CAF50)
                                : (isDark ? AppColors.goldLight : AppColors.saffronDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: goals.japaTarget > 0
                          ? (audioState.completedRepetitions / goals.japaTarget).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: isDark ? Colors.black26 : const Color(0xFFEADBCE),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        audioState.completedRepetitions >= goals.japaTarget
                            ? const Color(0xFF4CAF50)
                            : AppColors.saffronPrimary,
                      ),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Goals Badges Row (Puja, Scripture, Meditation, Vrat)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (goals.hasPujaGoal)
                        _buildGoalBadge(
                          isDark,
                          Icons.wb_twighlight,
                          'Puja: ${sadhanaState.completedRoutineCount}/${sadhanaState.totalRoutineCount}',
                          sadhanaState.completedRoutineCount >= sadhanaState.totalRoutineCount && sadhanaState.totalRoutineCount > 0,
                        ),
                      if (goals.hasScriptureGoal)
                        _buildGoalBadge(
                          isDark,
                          Icons.auto_stories,
                          '${goals.scriptureMinutes}m Reading',
                          false,
                        ),
                      if (goals.hasMeditationGoal)
                        _buildGoalBadge(
                          isDark,
                          Icons.self_improvement,
                          '${goals.meditationMinutes}m Dhyana',
                          false,
                        ),
                      if (goals.hasVratGoal)
                        _buildGoalBadge(
                          isDark,
                          Icons.calendar_month,
                          'Vrat Tracking',
                          true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalBadge(bool isDark, IconData icon, String text, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF4CAF50).withAlpha(isDark ? 50 : 25)
            : (isDark ? Colors.black26 : AppColors.creamBackground),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF4CAF50).withAlpha(120)
              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isCompleted ? const Color(0xFF4CAF50) : (isDark ? AppColors.goldLight : AppColors.saffronDark),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
