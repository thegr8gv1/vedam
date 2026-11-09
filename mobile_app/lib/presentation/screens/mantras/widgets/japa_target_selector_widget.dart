import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/japa_target_preset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../state/audio_state.dart';

/// Dedicated target-selection area for Japa Mala chanting.
///
/// Features:
/// - Prominently displays all 7 traditional presets (11, 21, 27, 54, 108, 111, 1008)
///   as rich selectable cards with authentic Sanskrit labels and spiritual significance.
/// - Visually highlights the active target with saffron border, golden glow, and checkmark.
/// - Inline Custom Count card with dedicated text field, digits-only formatter, real-time
///   validation feedback, and "Apply Target" button (accepting 1 through 100,000).
/// - Active Session Safety: prompts for explicit confirmation if changing target mid-session
///   (completedRepetitions > 0) and strictly preserves completed count.
/// - Responsive layout adapting gracefully to mobile phones and Web/desktop.
class JapaTargetSelectorWidget extends StatefulWidget {
  final AudioState audioState;
  final VoidCallback? onTargetChanged;

  const JapaTargetSelectorWidget({
    super.key,
    required this.audioState,
    this.onTargetChanged,
  });

  @override
  State<JapaTargetSelectorWidget> createState() => _JapaTargetSelectorWidgetState();
}

class _JapaTargetSelectorWidgetState extends State<JapaTargetSelectorWidget> {
  late final TextEditingController _customController;
  String? _customError;

  @override
  void initState() {
    super.initState();
    final currentTarget = widget.audioState.targetRepetitions;
    final isPreset = kJapaTraditionalPresets.any((p) => p.count == currentTarget);
    _customController = TextEditingController(
      text: isPreset ? '' : '$currentTarget',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _attemptSetTarget(int newTarget) async {
    final currentTarget = widget.audioState.targetRepetitions;
    if (newTarget == currentTarget) return;

    final completed = widget.audioState.completedRepetitions;

    // Active session guard: if chanting is in progress, require explicit confirmation
    if (completed > 0) {
      final confirmed = await _showTargetChangeConfirmation(
        currentCompleted: completed,
        oldTarget: currentTarget,
        newTarget: newTarget,
      );
      if (!confirmed || !mounted) return;
    }

    widget.audioState.setTargetRepetitions(newTarget);
    widget.onTargetChanged?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completed > 0
                ? 'Target updated to $newTarget repetitions. $completed completed preserved.'
                : 'Target set to $newTarget repetitions.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _showTargetChangeConfirmation({
    required int currentCompleted,
    required int oldTarget,
    required int newTarget,
  }) async {
    final isExceededOrReached = newTarget <= currentCompleted;

    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                    isExceededOrReached ? Icons.info_outline : Icons.change_circle_outlined,
                    color: AppColors.saffronPrimary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Adjust Japa Target?'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isExceededOrReached) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Text(
                        'You have already completed $currentCompleted repetitions. Setting the target to $newTarget means this target is already achieved!',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Current target: $oldTarget repetitions\n'
                    'New target: $newTarget repetitions\n'
                    'Completed so far: $currentCompleted repetitions',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your completed count will NOT be reset or altered.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.saffronPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Keep Current Target'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Update Target'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _validateLiveCustomInput(String raw) {
    if (raw.isEmpty) {
      setState(() => _customError = null);
      return;
    }
    final validation = validateCustomJapaTarget(raw);
    setState(() {
      _customError = validation.isValid ? null : validation.errorMessage;
    });
  }

  void _submitCustomTarget() {
    final validation = validateCustomJapaTarget(_customController.text);
    if (!validation.isValid) {
      setState(() {
        _customError = validation.errorMessage;
      });
      return;
    }

    setState(() {
      _customError = null;
    });

    _attemptSetTarget(validation.parsedValue!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTarget = widget.audioState.targetRepetitions;
    final isCustomTarget = !kJapaTraditionalPresets.any((p) => p.count == currentTarget);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header with Active Target summary
          Row(
            children: [
              const Icon(
                Icons.trip_origin,
                size: 20,
                color: AppColors.saffronPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHANTING TARGET & JAPA PRESETS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.saffronPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select a sacred traditional count or enter a custom target',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.saffronPrimary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.saffronPrimary, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 13, color: AppColors.saffronPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'Target: $currentTarget',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.saffronPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. The 7 Traditional Preset Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kJapaTraditionalPresets.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: constraints.maxWidth > 500 ? 2.2 : 1.9,
                ),
                itemBuilder: (context, index) {
                  final preset = kJapaTraditionalPresets[index];
                  final isSelected = currentTarget == preset.count;

                  return _buildPresetCard(
                    preset: preset,
                    isSelected: isSelected,
                    isDark: isDark,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),

          // 3. Dedicated Custom Count Entry Card
          _buildCustomCountCard(
            currentTarget: currentTarget,
            isCustomActive: isCustomTarget,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard({
    required JapaPreset preset,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      key: ValueKey('preset_card_${preset.count}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => _attemptSetTarget(preset.count),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.saffronPrimary.withAlpha(isDark ? 45 : 30)
              : (isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.saffronPrimary
                : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.saffronPrimary.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${preset.count}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.saffronPrimary
                          : (isDark ? AppColors.goldLight : AppColors.goldDark),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.saffronPrimary,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              preset.traditionalLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              _extractSignificanceKeyword(preset),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCountCard({
    required int currentTarget,
    required bool isCustomActive,
    required bool isDark,
  }) {
    return Container(
      key: const ValueKey('custom_target_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCustomActive
            ? AppColors.saffronPrimary.withAlpha(isDark ? 35 : 20)
            : (isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCustomActive
              ? AppColors.saffronPrimary
              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
          width: isCustomActive ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, size: 18, color: AppColors.saffronPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Custom Chanting Target',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              if (isCustomActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.saffronPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Active: $currentTarget',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enter any positive whole number from 1 to $kMaxPracticalJapaTarget repetitions.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 48,
                      child: TextField(
                        key: const ValueKey('custom_target_input'),
                        controller: _customController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'e.g. 35, 500, 100000',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.saffronPrimary,
                              width: 1.8,
                            ),
                          ),
                        ),
                        onChanged: _validateLiveCustomInput,
                        onSubmitted: (_) => _submitCustomTarget(),
                      ),
                    ),
                    if (_customError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 2),
                        child: Text(
                          _customError!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const ValueKey('apply_custom_target_btn'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Set Target'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submitCustomTarget,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _extractSignificanceKeyword(JapaPreset preset) {
    switch (preset.count) {
      case 11:
        return 'Ekadasha • 11 Rudras';
      case 21:
        return 'Ekavimshati • Ganesha';
      case 27:
        return 'Quarter • 27 Nakshatras';
      case 54:
        return 'Ardha Mala • Half Mala';
      case 108:
        return 'Purna Mala • Classical';
      case 111:
        return 'Shubha Sankalpa • Vrata';
      case 1008:
        return 'Sahasra Japa • Mahotsava';
      default:
        return 'Traditional count';
    }
  }
}
