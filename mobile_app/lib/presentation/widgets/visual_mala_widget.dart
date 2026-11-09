import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Renders a sacred, adaptive Japa Mala counter.
/// Supports traditional presets (11, 21, 27, 54, 108, 111, 1008) and custom targets.
/// For targets <= 108, displays an authentic bead garland with Sumeru Guru bead.
/// For large targets (> 108), renders an adaptive mala cycle indicator with milestones
/// to avoid rendering thousands of simultaneous dots.
class VisualMalaWidget extends StatelessWidget {
  final int completedCount;
  final int targetCount;
  final bool isPlaying;

  const VisualMalaWidget({
    super.key,
    required this.completedCount,
    required this.targetCount,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLargeTarget = targetCount > 108;
    final isTargetReached = targetCount > 0 && completedCount >= targetCount;
    final extraChants = completedCount > targetCount ? completedCount - targetCount : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Sacred Stats Header
        Semantics(
          label: 'Japa Mala Chanting Counter',
          value: '$completedCount of $targetCount chants completed',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTargetReached
                  ? AppColors.goldPrimary
                  : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
              width: isTargetReached ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                label: 'COMPLETED',
                value: extraChants > 0 ? '$completedCount (+$extraChants)' : '$completedCount',
                color: AppColors.saffronPrimary,
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              ),
              _buildStatColumn(
                context,
                label: 'TARGET',
                value: '$targetCount',
                color: isDark ? AppColors.goldLight : AppColors.goldDark,
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              ),
              _buildStatColumn(
                context,
                label: 'REMAINING',
                value: '${targetCount > completedCount ? targetCount - completedCount : 0}',
                color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
              ),
            ],
          ),
        ),
        ),

        // 2. Target Completed Sacred Badge (if target reached)
        if (isTargetReached) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E1C0A) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, size: 16, color: AppColors.goldPrimary),
                const SizedBox(width: 8),
                Text(
                  extraChants > 0
                      ? '॥ जप पूर्णम् ॥ Target Reached (+$extraChants continuing)'
                      : '॥ जप पूर्णम् ॥ Sacred Target Reached ($completedCount Completed)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // 3. Adaptive Visualization Area
        if (!isLargeTarget)
          _buildBeadGarland(context, isDark)
        else
          _buildLargeTargetVisualization(context, isDark),
      ],
    );
  }

  // --- Case A: Bead Garland for Targets <= 108 ---
  Widget _buildBeadGarland(BuildContext context, bool isDark) {
    final totalBeads = targetCount.clamp(1, 108);
    final activeBeadIndex = completedCount < totalBeads ? completedCount : -1;
    final progressPct = ((completedCount / (targetCount > 0 ? targetCount : 1)) * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);

    String malaTitle;
    if (targetCount == 108) {
      malaTitle = '108-Bead Japa Mala';
    } else if (targetCount == 54) {
      malaTitle = 'Half Mala (54 Beads)';
    } else if (targetCount == 27) {
      malaTitle = 'Quarter Mala (27 Beads)';
    } else if (targetCount == 21) {
      malaTitle = '21-Repetition Mala';
    } else if (targetCount == 11) {
      malaTitle = '11-Repetition Mala';
    } else {
      malaTitle = '$targetCount-Bead Chanting Mala';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                malaTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.goldLight : AppColors.goldDark,
                ),
              ),
              Text(
                '$progressPct%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.saffronPrimary,
                ),
              ),
            ],
          ),

          // Sacred Sumeru (Guru Bead) indicator for 108-bead Mala
          if (targetCount == 108) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ॐ Sumeru (Guru Bead) — Classical 108 Count',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          SizedBox(
            height: 130,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: totalBeads,
              itemBuilder: (context, index) {
                final isCompleted = index < completedCount;
                final isActive = index == activeBeadIndex && isPlaying;

                Color beadColor;
                if (isCompleted) {
                  beadColor = AppColors.saffronPrimary;
                } else if (isActive) {
                  beadColor = isDark ? AppColors.goldLight : AppColors.goldDark;
                } else {
                  beadColor = isDark
                      ? AppColors.nightBorder.withAlpha(150)
                      : AppColors.chandanBorder;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: beadColor,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.saffronPrimary.withAlpha(180),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                    border: Border.all(
                      color: isCompleted
                          ? (isDark ? AppColors.goldLight : AppColors.saffronDark)
                          : (isActive
                              ? Colors.white
                              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder)),
                      width: isActive ? 2.0 : 1.0,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Case B: Adaptive Visualization for Targets > 108 (111, 1008, Large Custom) ---
  Widget _buildLargeTargetVisualization(BuildContext context, bool isDark) {
    final progressFraction = targetCount > 0 ? (completedCount / targetCount).clamp(0.0, 1.0) : 0.0;
    final progressPct = (progressFraction * 100).toStringAsFixed(1);

    // Mala Cycle Breakdown (e.g. for 1008 repetitions, each Mala is 108 beads)
    final cycleIndex = completedCount ~/ 108;
    final totalMalas = (targetCount / 108).ceil();
    final currentCycleBeads = completedCount % 108;

    String largeTitle;
    if (targetCount == 1008) {
      largeTitle = '1008 Repetitions • Sahasra Japa Mahotsava';
    } else if (targetCount == 111) {
      largeTitle = '111 Repetitions • Shubha Sankalpa';
    } else {
      largeTitle = '$targetCount Repetitions Target';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                largeTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.goldLight : AppColors.goldDark,
                ),
              ),
              Text(
                '$progressPct%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.saffronPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mala Cycle Indicators
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.saffronPrimary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.saffronPrimary.withAlpha(80),
                  ),
                ),
                child: Text(
                  'Mala ${cycleIndex + 1} of $totalMalas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.nightSurface : const Color(0xFFF1E7D8)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: Text(
                  'Bead $currentCycleBeads of 108',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Continuous Progress Bar with Milestones
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 12,
              backgroundColor: isDark ? AppColors.nightSurface : const Color(0xFFE5DDD0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.saffronPrimary),
            ),
          ),
          const SizedBox(height: 8),

          // Milestone markers (25%, 50%, 75%, 100%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMilestone(context, '0', isDark),
              _buildMilestone(context, '${(targetCount * 0.25).round()}', isDark),
              _buildMilestone(context, '${(targetCount * 0.50).round()} (50%)', isDark),
              _buildMilestone(context, '${(targetCount * 0.75).round()}', isDark),
              _buildMilestone(context, '$targetCount (100%)', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestone(BuildContext context, String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9.5,
        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
