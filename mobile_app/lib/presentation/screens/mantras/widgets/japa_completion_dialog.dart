import 'package:flutter/material.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/state/audio_state.dart';

/// Sacred completion dialog displayed when the devotee reaches their chosen Japa target.
///
/// Features:
/// - Sacred invocation: "॥ जप पूर्णम् ॥" (Japa Completed)
/// - Total repetitions completed
/// - Clear devotional explanation
/// - Option to "Finish Session" (preserves count, records completion, stops audio)
/// - Option to "Continue Chanting" (preserves count, enables continuing beyond target)
/// - Strictly never auto-resets the counter.
class JapaCompletionDialog extends StatelessWidget {
  final AudioState audioState;
  final VoidCallback? onFinish;
  final VoidCallback? onContinue;

  const JapaCompletionDialog({
    super.key,
    required this.audioState,
    this.onFinish,
    this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    required AudioState audioState,
    VoidCallback? onFinish,
    VoidCallback? onContinue,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => JapaCompletionDialog(
        audioState: audioState,
        onFinish: onFinish,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = audioState.completedRepetitions;
    final target = audioState.targetRepetitions;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sacred Emblem / Lotus Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.saffronPrimary, AppColors.saffronDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.saffronPrimary.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'ॐ',
                  style: TextStyle(
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Sacred Completion Title
            const Text(
              '॥ जप पूर्णम् ॥',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.saffronPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Japa Sadhana Completed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.goldLight : AppColors.goldDark,
              ),
            ),
            const SizedBox(height: 16),

            // Repetition Count Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : AppColors.creamBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'TARGET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLightMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$target',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                  Column(
                    children: [
                      const Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffronPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completed',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffronPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Devotional Blessing message
            Text(
              'You have faithfully offered $completed repetitions of this sacred mantra. May this practice bring peace, purity of intellect, and spiritual upliftment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons: Finish Session vs. Continue Chanting
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Finish Session (Primary)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    'Finish Session',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    audioState.finishSession();
                    Navigator.of(context).pop();
                    onFinish?.call();
                  },
                ),
                const SizedBox(height: 10),

                // Continue Chanting (Secondary)
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    'Continue Chanting',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.goldLight : AppColors.saffronPrimary,
                    side: BorderSide(
                      color: isDark ? AppColors.goldLight : AppColors.saffronPrimary,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    audioState.continueChanting();
                    Navigator.of(context).pop();
                    onContinue?.call();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
