import 'package:flutter/material.dart';
import '../../../../core/models/scripture_user_data.dart';
import '../../../../core/models/verse.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../state/scripture_reader_state.dart';

/// Modal bottom sheet allowing devotees to customize reading typography,
/// font sizes, line spacing, and script preferences.
class ReadingPreferencesModal extends StatefulWidget {
  final ScriptureReaderState readerState;

  const ReadingPreferencesModal({
    super.key,
    required this.readerState,
  });

  static Future<void> show(BuildContext context, ScriptureReaderState readerState) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReadingPreferencesModal(readerState: readerState),
    );
  }

  @override
  State<ReadingPreferencesModal> createState() => _ReadingPreferencesModalState();
}

class _ReadingPreferencesModalState extends State<ReadingPreferencesModal> {
  late double _sanskritSize;
  late double _transliterationSize;
  late double _translationSize;
  late double _lineSpacing;
  late ScriptOption _preferredScript;
  late bool _showTransliteration;
  late bool _showTranslation;

  @override
  void initState() {
    super.initState();
    final p = widget.readerState.preferences;
    _sanskritSize = p.sanskritFontSize;
    _transliterationSize = p.transliterationFontSize;
    _translationSize = p.translationFontSize;
    _lineSpacing = p.lineSpacing;
    _preferredScript = p.preferredScript;
    _showTransliteration = p.showTransliteration;
    _showTranslation = p.showTranslation;
  }

  void _save() {
    widget.readerState.updatePreferences(
      ReadingPreferences(
        sanskritFontSize: _sanskritSize,
        transliterationFontSize: _transliterationSize,
        translationFontSize: _translationSize,
        lineSpacing: _lineSpacing,
        preferredScript: _preferredScript,
        showTransliteration: _showTransliteration,
        showTranslation: _showTranslation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reading Preferences',
                      style: AppTextStyles.titleMedium(isDark),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    widget.readerState.resetPreferences();
                    final p = const ReadingPreferences();
                    setState(() {
                      _sanskritSize = p.sanskritFontSize;
                      _transliterationSize = p.transliterationFontSize;
                      _translationSize = p.translationFontSize;
                      _lineSpacing = p.lineSpacing;
                      _preferredScript = p.preferredScript;
                      _showTransliteration = p.showTransliteration;
                      _showTranslation = p.showTranslation;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const Divider(height: 16),

            // 1. Script Selection
            Text(
              'SCRIPT PREFERENCE',
              style: AppTextStyles.caption(isDark).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ScriptOption.values.map((script) {
                final isSelected = _preferredScript == script;
                return ChoiceChip(
                  label: Text('${script.label} (${script.nativeLabel})'),
                  selected: isSelected,
                  selectedColor: AppColors.saffronPrimary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _preferredScript = script);
                      _save();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 2. Sanskrit Text Size Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sanskrit Text Size',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                  ),
                ),
                Text(
                  '${_sanskritSize.toInt()} pt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                  ),
                ),
              ],
            ),
            Slider(
              value: _sanskritSize,
              min: 16.0,
              max: 32.0,
              divisions: 8,
              activeColor: AppColors.saffronPrimary,
              onChanged: (val) {
                setState(() => _sanskritSize = val);
                _save();
              },
            ),

            // 3. Transliteration Text Size Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transliteration Text Size',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                  ),
                ),
                Text(
                  '${_transliterationSize.toInt()} pt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                  ),
                ),
              ],
            ),
            Slider(
              value: _transliterationSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              activeColor: AppColors.goldDark,
              onChanged: (val) {
                setState(() => _transliterationSize = val);
                _save();
              },
            ),

            // 4. Translation Text Size Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Translation Text Size',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                  ),
                ),
                Text(
                  '${_translationSize.toInt()} pt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                  ),
                ),
              ],
            ),
            Slider(
              value: _translationSize,
              min: 12.0,
              max: 22.0,
              divisions: 5,
              activeColor: AppColors.saffronDark,
              onChanged: (val) {
                setState(() => _translationSize = val);
                _save();
              },
            ),

            // 5. Line Spacing Choice
            Text(
              'LINE SPACING',
              style: AppTextStyles.caption(isDark).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SpacingOption(
                  label: 'Compact',
                  spacing: 1.3,
                  current: _lineSpacing,
                  onSelect: (val) {
                    setState(() => _lineSpacing = val);
                    _save();
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _SpacingOption(
                  label: 'Normal',
                  spacing: 1.6,
                  current: _lineSpacing,
                  onSelect: (val) {
                    setState(() => _lineSpacing = val);
                    _save();
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _SpacingOption(
                  label: 'Spacious',
                  spacing: 2.0,
                  current: _lineSpacing,
                  onSelect: (val) {
                    setState(() => _lineSpacing = val);
                    _save();
                  },
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Toggles
            SwitchListTile.adaptive(
              title: const Text('Show Transliteration (IAST / Roman)'),
              value: _showTransliteration,
              activeTrackColor: AppColors.saffronPrimary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _showTransliteration = val);
                _save();
              },
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Meaning / Translation (Section 8 Draft)'),
              subtitle: const Text(
                'Displays preliminary study meanings under scholarly peer review',
                style: TextStyle(fontSize: 11),
              ),
              value: _showTranslation,
              activeTrackColor: AppColors.saffronPrimary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _showTranslation = val);
                _save();
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('APPLY PREFERENCES'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpacingOption extends StatelessWidget {
  final String label;
  final double spacing;
  final double current;
  final ValueChanged<double> onSelect;
  final bool isDark;

  const _SpacingOption({
    required this.label,
    required this.spacing,
    required this.current,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = (current - spacing).abs() < 0.05;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => onSelect(spacing),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? (isDark ? AppColors.goldGlow.withValues(alpha: 0.2) : AppColors.saffronPrimary.withValues(alpha: 0.15))
              : Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? AppColors.saffronPrimary
                : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? AppColors.goldGlow : AppColors.saffronDark)
                : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
          ),
        ),
      ),
    );
  }
}
