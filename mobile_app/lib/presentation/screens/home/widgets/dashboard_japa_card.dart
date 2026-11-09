import '../../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/mantra_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/repositories/mantra_repository.dart';
import '../../../../state/audio_state.dart';
import '../../mantras/mantra_player_screen.dart';

/// Japa & Mantra Practice card on the Devotee Home Dashboard.
///
/// Features:
/// - Connects directly to the shared AudioState without duplicating Japa state.
/// - Displays current active mantra (or default Om Namah Shivaya).
/// - Displays current target repetitions (supports 11, 21, 27, 54, 108, 111, 1008,
///   and custom targets up to 100,000).
/// - Displays completed repetitions, remaining count, and real-time progress bar.
/// - Provides accessible Tap-to-Chant (+1) bead button directly on dashboard.
/// - Start / Continue Chanting button opening the full MantraPlayerScreen.
/// - Never resets active chanting session on navigation or app reload.
class DashboardJapaCard extends StatelessWidget {
  final AudioState audioState;
  final MantraRepository? mantraRepository;
  final VoidCallback? onOpenMantras;

  const DashboardJapaCard({
    super.key,
    required this.audioState,
    this.mantraRepository,
    this.onOpenMantras,
  });

  MantraItem _resolveActiveMantra() {
    if (audioState.activeMantra != null) {
      return audioState.activeMantra!;
    }
    if (mantraRepository != null) {
      final all = mantraRepository!.getAllMantras();
      if (all.isNotEmpty) return all.first;
    }
    // Safe canonical fallback
    return const MantraItem(
      id: 'VEDA-MTR-0001',
      collection: 'Shiva',
      deity: 'Shiva',
      title: 'Om Namah Shivaya',
      filename: 'Om Namah Shivaya.wav',
      mantraText: 'ॐ नमः शिवाय',
      significance: 'Purifies the mind and leads to inner stillness.',
      form: '',
      durationSeconds: 4.5,
      sampleRate: 48000,
      bitDepth: 16,
      channels: 2,
      fileSizeBytes: 877484,
      sha256: 'abc1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      sourceTxt: 'Assorted Shiva Chants.txt',
      isBundled: true,
      bundledAssetPath: 'assets/audio/bundled/om_namah_shivaya.mp3',
    );
  }

  void _openMantraPlayer(BuildContext context, MantraItem mantra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MantraPlayerScreen(
          mantra: mantra,
          audioState: audioState,
          playlist: mantraRepository?.getAllMantras(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mantra = _resolveActiveMantra();
    final target = audioState.targetRepetitions;
    final completed = audioState.completedRepetitions;
    final remaining = target > completed ? target - completed : 0;
    final progress = audioState.progressFraction;
    final isTargetReached = target > 0 && completed >= target;
    final isPlaying = audioState.isPlaying;

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
                        Icons.graphic_eq,
                        size: 18,
                        color: AppColors.saffronPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(
                              (l10n?.homeJapaPractice ?? 'DAILY JAPA PRACTICE').toUpperCase(),
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _openMantraPlayer(context, mantra),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mantra Player',
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

            // Active Mantra Summary Container
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.saffronPrimary.withAlpha(isDark ? 35 : 20),
                      border: Border.all(color: AppColors.saffronPrimary, width: 1.0),
                    ),
                    child: const Center(
                      child: Text(
                        'ॐ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffronPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mantra.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.saffronPrimary.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                mantra.deity.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.saffronPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mantra.mantraText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.goldLight : AppColors.goldDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Target Stats Row (Completed, Target, Remaining)
            Row(
              children: [
                Expanded(
                  child: _buildCountStat(
                    context,
                    label: 'COMPLETED',
                    value: '$completed',
                    color: AppColors.saffronPrimary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCountStat(
                    context,
                    label: 'TARGET',
                    value: '$target',
                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCountStat(
                    context,
                    label: 'REMAINING',
                    value: '$remaining',
                    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Bar & Percentage
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark ? AppColors.nightBorder : const Color(0xFFE5DDD0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isTargetReached ? AppColors.verifiedGreen : AppColors.saffronPrimary,
                ),
              ),
            ),

            // Target Reached Banner if applicable
            if (isTargetReached) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E1C0A) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.goldPrimary, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, size: 14, color: AppColors.goldPrimary),
                    const SizedBox(width: 6),
                    Text(
                      '॥ जप पूर्णम् ॥ Target Reached ($completed Chants)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Actions: Tap-to-Chant (+1) and Start/Continue Chanting Player
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                final beadLabel = l10n?.japaTapToCount ?? 'Count Bead (+1)';
                final playLabel = completed > 0
                    ? (l10n?.audioResume ?? 'Continue Chanting')
                    : (l10n?.japaStartChanting ?? 'Start Chanting');

                return Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Count Japa bead, increment chant count',
                        value: '$completed of $target completed',
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.touch_app, size: 18),
                            label: Text(beadLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.saffronPrimary,
                              side: const BorderSide(color: AppColors.saffronPrimary, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              audioState.incrementManualRepetition();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: isPlaying ? 'Pause mantra chanting' : playLabel,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 20),
                            label: Text(
                              playLabel,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.saffronPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _openMantraPlayer(context, mantra),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
