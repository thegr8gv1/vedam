import 'package:flutter/material.dart';
import '../../core/models/verse.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class ScriptSelectorModal extends StatelessWidget {
  final ScriptOption currentScript;
  final ValueChanged<ScriptOption> onScriptSelected;

  const ScriptSelectorModal({
    super.key,
    required this.currentScript,
    required this.onScriptSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required ScriptOption currentScript,
    required ValueChanged<ScriptOption> onScriptSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ScriptSelectorModal(
        currentScript: currentScript,
        onScriptSelected: onScriptSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Scripture Script (लिपि)',
                  style: AppTextStyles.titleMedium(isDark),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Read canonical verses in your preferred script. Transliterations preserve authentic phonetics.',
              style: AppTextStyles.bodySmall(isDark),
            ),
            const SizedBox(height: 16),
            ...ScriptOption.values.map((script) {
              final isSelected = script == currentScript;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.saffronPrimary
                        : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                tileColor: isSelected
                    ? (isDark ? const Color(0xFF2B1A12) : AppColors.saffronLight)
                    : null,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.saffronPrimary
                        : (isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF3ECE2)),
                  ),
                  child: Center(
                    child: Text(
                      script.nativeLabel.substring(0, script.nativeLabel.length > 2 ? 2 : 1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  script.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.saffronPrimary)
                    : null,
                onTap: () {
                  onScriptSelected(script);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
