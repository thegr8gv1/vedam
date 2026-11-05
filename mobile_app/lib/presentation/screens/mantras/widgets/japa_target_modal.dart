import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vedam_app/core/models/japa_target_preset.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/state/audio_state.dart';

/// Modal bottom sheet for choosing or customizing the devotee's Japa target count.
///
/// Features:
/// - 7 Traditional presets: 11, 21, 27, 54, 108, 111, 1008 with authentic labels.
/// - Custom positive whole integer input up to 100,000 with real-time validation.
/// - Auto-pause at target toggle switch.
/// - Session safety confirmation: If changing target while completedRepetitions > 0,
///   prompts for confirmation and strictly preserves completed count.
class JapaTargetModal extends StatefulWidget {
  final AudioState audioState;

  const JapaTargetModal({
    super.key,
    required this.audioState,
  });

  static Future<void> show(BuildContext context, AudioState audioState) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JapaTargetModal(audioState: audioState),
    );
  }

  @override
  State<JapaTargetModal> createState() => _JapaTargetModalState();
}

class _JapaTargetModalState extends State<JapaTargetModal> {
  late final TextEditingController _customController;
  String? _customError;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    final currentTarget = widget.audioState.targetRepetitions;
    final isPreset = kJapaTraditionalPresets.any((p) => p.count == currentTarget);
    _isCustomMode = !isPreset;
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
    if (newTarget == currentTarget) {
      Navigator.of(context).pop();
      return;
    }

    final completed = widget.audioState.completedRepetitions;

    // If session is already in progress, ask for confirmation to be respectful & transparent
    if (completed > 0) {
      final confirmed = await _showTargetChangeConfirmation(
        currentCompleted: completed,
        oldTarget: currentTarget,
        newTarget: newTarget,
      );
      if (!confirmed || !mounted) {
        return;
      }
    }

    widget.audioState.setTargetRepetitions(newTarget);
    if (mounted) {
      Navigator.of(context).pop();
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

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightBorder : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Subtitle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chanting Target (Japa Target)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a traditional Mala count or enter a custom target',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.saffronPrimary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.saffronPrimary),
                  ),
                  child: Text(
                    'Active: $currentTarget',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.saffronPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section 1: Traditional Presets Grid
            const Text(
              'TRADITIONAL PRESETS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.saffronPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in kJapaTraditionalPresets)
                  _buildPresetChip(
                    preset: preset,
                    isSelected: !_isCustomMode && currentTarget == preset.count,
                    isDark: isDark,
                  ),
                // Custom toggle button
                ChoiceChip(
                  label: const Text('Custom Count'),
                  avatar: const Icon(Icons.edit, size: 14),
                  selected: _isCustomMode,
                  selectedColor: AppColors.saffronPrimary.withAlpha(45),
                  onSelected: (selected) {
                    setState(() {
                      _isCustomMode = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section 2: Custom Count Input (visible when Custom is selected)
            if (_isCustomMode) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightSurface : AppColors.creamBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _customError != null
                        ? Colors.red
                        : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Custom Target Count',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter any positive whole number up to $kMaxPracticalJapaTarget repetitions for purashcharana sadhana.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: 'e.g. 1008, 1250, 5000',
                              errorText: _customError,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _submitCustomTarget(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.saffronPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitCustomTarget,
                          child: const Text('Set Target'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Section 3: Audio Auto-Pause setting
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Auto-pause audio at target completion',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Automatically pauses chanting playback when the chosen count is completed.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                ),
              ),
              value: widget.audioState.autoPauseAtTarget,
              activeTrackColor: AppColors.saffronPrimary,
              onChanged: (val) {
                setState(() {
                  widget.audioState.setAutoPauseAtTarget(val);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required JapaPreset preset,
    required bool isSelected,
    required bool isDark,
  }) {
    return FilterChip(
      selected: isSelected,
      selectedColor: AppColors.saffronPrimary.withAlpha(50),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${preset.count}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? AppColors.saffronPrimary : null,
            ),
          ),
          Text(
            preset.label,
            style: TextStyle(
              fontSize: 9.5,
              color: isSelected
                  ? AppColors.saffronPrimary
                  : (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
            ),
          ),
        ],
      ),
      onSelected: (_) {
        setState(() {
          _isCustomMode = false;
        });
        _attemptSetTarget(preset.count);
      },
    );
  }
}
