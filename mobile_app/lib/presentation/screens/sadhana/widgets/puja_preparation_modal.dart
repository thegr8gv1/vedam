import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/puja_guide.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/core/theme/text_styles.dart';
import 'package:vedam_app/state/sadhana_state.dart';

/// Modal bottom sheet presenting a devotee-controlled preparation checklist
/// with required and optional materials, accessible before or during Puja.
class PujaPreparationModal extends StatelessWidget {
  final PujaGuide guide;
  final SadhanaState sadhanaState;

  const PujaPreparationModal({
    super.key,
    required this.guide,
    required this.sadhanaState,
  });

  static Future<void> show({
    required BuildContext context,
    required PujaGuide guide,
    required SadhanaState sadhanaState,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PujaPreparationModal(
        guide: guide,
        sadhanaState: sadhanaState,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preparedCount = guide.requiredMaterials
        .where((m) => sadhanaState.isMaterialPrepared(m))
        .length;
    final totalRequired = guide.requiredMaterials.length;
    final isAllRequiredPrepared = totalRequired > 0 && preparedCount >= totalRequired;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.goldGlow : AppColors.goldPrimary,
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PŪJĀ SĀMAGRĪ & PREPARATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guide.title,
                          style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close Preparation Checklist',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Readiness summary banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isAllRequiredPrepared
                    ? (isDark ? const Color(0xFF14301B) : const Color(0xFFE8F5E9))
                    : (isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF6EDE0)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAllRequiredPrepared
                      ? Colors.green
                      : (isDark ? AppColors.goldGlow.withAlpha(80) : AppColors.goldPrimary.withAlpha(80)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAllRequiredPrepared ? Icons.check_circle : Icons.inventory_2_outlined,
                    color: isAllRequiredPrepared ? Colors.green : AppColors.saffronPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAllRequiredPrepared
                          ? 'All required materials prepared ($preparedCount/$totalRequired)'
                          : 'Required materials prepared: $preparedCount of $totalRequired',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isAllRequiredPrepared
                            ? (isDark ? Colors.green[300] : Colors.green[800])
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            // Checklist content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                children: [
                  // 1. Saucam & Asanam Preparation Steps
                  if (guide.preparation.isNotEmpty) ...[
                    Text(
                      'Preparation (Śaucam & Āsanam)',
                      style: AppTextStyles.titleSmall(isDark).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...guide.preparation.map(
                      (prep) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right, size: 18, color: AppColors.saffronPrimary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                prep,
                                style: AppTextStyles.bodySmall(isDark).copyWith(height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 2. Traditional Core Materials (Samagri)
                  Row(
                    children: [
                      Text(
                        'Required Materials',
                        style: AppTextStyles.titleSmall(isDark).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.saffronPrimary.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TRADITIONAL CORE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.saffronPrimary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Samagri varies across family lineage (Kulachara) and Sampradaya. Bhavana (devotion) takes precedence over physical items.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? const Color(0xFFB8A692) : const Color(0xFF6F5E4B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...guide.requiredMaterials.map((material) {
                    final isChecked = sadhanaState.isMaterialPrepared(material);
                    return Semantics(
                      label: 'Traditional core material: $material, ${isChecked ? "prepared" : "not prepared"}',
                      child: InkWell(
                        onTap: () => sadhanaState.toggleMaterialPrepared(material),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                onChanged: (_) => sadhanaState.toggleMaterialPrepared(material),
                                activeColor: AppColors.saffronPrimary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  material,
                                  style: AppTextStyles.bodyMedium(isDark).copyWith(
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                    color: isChecked
                                        ? (isDark ? Colors.white38 : Colors.black38)
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // 3. Optional Materials
                  if (guide.optionalMaterials.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Optional Materials',
                          style: AppTextStyles.titleSmall(isDark).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OPTIONAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...guide.optionalMaterials.map((material) {
                      final isChecked = sadhanaState.isMaterialPrepared(material);
                      return Semantics(
                        label: 'Optional material: $material, ${isChecked ? "prepared" : "not prepared"}',
                        child: InkWell(
                          onTap: () => sadhanaState.toggleMaterialPrepared(material),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  onChanged: (_) => sadhanaState.toggleMaterialPrepared(material),
                                  activeColor: AppColors.goldPrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    material,
                                    style: AppTextStyles.bodyMedium(isDark).copyWith(
                                      decoration: isChecked ? TextDecoration.lineThrough : null,
                                      color: isChecked
                                          ? (isDark ? Colors.white38 : Colors.black38)
                                          : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // Bottom action
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'SAVE & RETURN TO WORSHIP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
