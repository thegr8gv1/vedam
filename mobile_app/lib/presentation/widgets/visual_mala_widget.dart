import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Renders a sacred 108-bead Japa Mala counter.
/// Highlights completed, active, and remaining beads with zero competitive gamification.
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
    final totalBeads = targetCount.clamp(1, 108);
    final activeBeadIndex = completedCount < totalBeads ? completedCount : -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sacred Sumeru (Guru Bead) indicator & Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                label: 'COMPLETED',
                value: '$completedCount',
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
        const SizedBox(height: 16),

        // Visual 108 Beads Grid / Garland
        Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.nightSurfaceElevated
                : AppColors.creamBackground,
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
                    '108-Bead Japa Mala',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    ),
                  ),
                  Text(
                    '${((completedCount / (targetCount > 0 ? targetCount : 1)) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.saffronPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 108,
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
        ),
      ],
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
