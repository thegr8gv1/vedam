import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../state/sadhana_state.dart';

/// Modal bottom sheet allowing devotees to customize which practices appear in their
/// daily routine, reorder items, or add additional practices from the catalog.
class CustomizeRoutineModal extends StatefulWidget {
  final SadhanaState sadhanaState;

  const CustomizeRoutineModal({
    super.key,
    required this.sadhanaState,
  });

  static Future<void> show({
    required BuildContext context,
    required SadhanaState sadhanaState,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomizeRoutineModal(sadhanaState: sadhanaState),
    );
  }

  @override
  State<CustomizeRoutineModal> createState() => _CustomizeRoutineModalState();
}

class _CustomizeRoutineModalState extends State<CustomizeRoutineModal> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = widget.sadhanaState;
    final routine = state.activeRoutine;
    final catalog = state.allCatalogPractices;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize Daily Routine',
                      style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 18),
                    ),
                    Text(
                      'Select and reorder your daily practices',
                      style: AppTextStyles.caption(isDark),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Done',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body: Catalog selection list with reorder capability
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Active Routine Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE IN ROUTINE (${routine.length})',
                      style: AppTextStyles.metadataTag(isDark).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                      ),
                    ),
                    Text(
                      'Drag handle to reorder',
                      style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routine.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      state.reorderRoutine(oldIndex, newIndex);
                    });
                  },
                  itemBuilder: (context, index) {
                    final practice = routine[index];
                    return Card(
                      key: ValueKey(practice.id),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(practice.category.icon, color: AppColors.saffronPrimary, size: 22),
                        title: Text(
                          practice.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${practice.category.displayName} • ~${practice.estimatedMinutes} min',
                          style: AppTextStyles.caption(isDark),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                              tooltip: 'Remove from routine',
                              onPressed: () {
                                setState(() {
                                  state.removePracticeFromRoutine(practice.id);
                                });
                              },
                            ),
                            const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Available Catalog Practices to add
                Text(
                  'ALL AVAILABLE PRACTICES',
                  style: AppTextStyles.metadataTag(isDark).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                  ),
                ),
                const SizedBox(height: 8),

                ...catalog.map((practice) {
                  final isInRoutine = routine.any((p) => p.id == practice.id);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isInRoutine ? AppColors.goldPrimary.withAlpha(120) : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(practice.category.icon, color: AppColors.goldPrimary, size: 22),
                      title: Text(
                        practice.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${practice.category.displayName} • ~${practice.estimatedMinutes} min',
                        style: AppTextStyles.caption(isDark),
                      ),
                      trailing: Checkbox(
                        value: isInRoutine,
                        activeColor: AppColors.saffronPrimary,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              state.addPracticeToRoutine(practice.id);
                            } else {
                              state.removePracticeFromRoutine(practice.id);
                            }
                          });
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Bottom Close / Confirm button
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
                child: const Text('SAVE & RETURN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
