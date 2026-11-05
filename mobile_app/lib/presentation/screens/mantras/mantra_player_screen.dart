import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_completion_dialog.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_target_modal.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';

class MantraPlayerScreen extends StatefulWidget {
  final MantraItem mantra;
  final AudioState audioState;

  const MantraPlayerScreen({
    super.key,
    required this.mantra,
    required this.audioState,
  });

  @override
  State<MantraPlayerScreen> createState() => _MantraPlayerScreenState();
}

class _MantraPlayerScreenState extends State<MantraPlayerScreen> {
  bool _isCompletionDialogShowing = false;

  @override
  void initState() {
    super.initState();
    widget.audioState.addListener(_onAudioStateChanged);
    if (widget.audioState.activeMantra?.id != widget.mantra.id) {
      widget.audioState.playMantra(widget.mantra, resetSessionCount: true);
    }
  }

  @override
  void dispose() {
    widget.audioState.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (!mounted) return;
    if (widget.audioState.hasReachedTarget &&
        !widget.audioState.hasAcknowledgedCompletion &&
        !_isCompletionDialogShowing) {
      _isCompletionDialogShowing = true;
      JapaCompletionDialog.show(
        context,
        audioState: widget.audioState,
      ).then((_) {
        _isCompletionDialogShowing = false;
      });
    }
  }

  Future<void> _requestChangeTarget(int count) async {
    final state = widget.audioState;
    if (count == state.targetRepetitions) return;

    if (state.completedRepetitions > 0) {
      final confirmed = await _showTargetAdjustmentConfirmation(
        currentCompleted: state.completedRepetitions,
        oldTarget: state.targetRepetitions,
        newTarget: count,
      );
      if (!confirmed) return;
    }

    state.setTargetRepetitions(count);
  }

  Future<bool> _showTargetAdjustmentConfirmation({
    required int currentCompleted,
    required int oldTarget,
    required int newTarget,
  }) async {
    final isExceededOrReached = newTarget <= currentCompleted;

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
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
                      'You have already chanted $currentCompleted repetitions. Setting the target to $newTarget means it is already achieved!',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Current target: $oldTarget repetitions\n'
                  'New target: $newTarget repetitions\n'
                  'Completed: $currentCompleted repetitions',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Completed repetitions will NOT be reset or lost.',
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
                child: const Text('Cancel'),
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
          ),
        ) ??
        false;
  }

  void _showCustomCountDialog(BuildContext context) {
    JapaTargetModal.show(context, widget.audioState);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.audioState,
      builder: (context, _) {
        final state = widget.audioState;
        final isFav = state.isFavorite(widget.mantra.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.mantra.title),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () => state.toggleFavorite(widget.mantra.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Deity & Collection Tag Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.saffronPrimary.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.saffronPrimary),
                      ),
                      child: Text(
                        widget.mantra.deity.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffronPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.mantra.isBundled
                            ? Colors.green.withAlpha(30)
                            : Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.mantra.isBundled ? Icons.offline_pin : Icons.storage,
                            size: 14,
                            color: widget.mantra.isBundled ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.mantra.isBundled ? 'Offline Bundled' : 'Local Vault',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.mantra.isBundled ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sanskrit Mantra Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ॐ',
                        style: TextStyle(
                          fontSize: 28,
                          color: AppColors.saffronPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.mantra.mantraText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          color: isDark ? AppColors.goldLight : AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Active Target Banner & Target Selector Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.track_changes,
                        size: 20,
                        color: AppColors.saffronPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target: ${state.targetRepetitions} repetitions ${_getTargetLabel(state.targetRepetitions)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              state.autoPauseAtTarget
                                  ? 'Auto-pause enabled at target'
                                  : 'Continuous chanting mode',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Change', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showCustomCountDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Visual Mala Counter (Adaptive Bead Matrix & Cycle Bar)
                VisualMalaWidget(
                  completedCount: state.completedRepetitions,
                  targetCount: state.targetRepetitions,
                  isPlaying: state.isPlaying,
                ),
                const SizedBox(height: 16),

                // Audio Progress Bar
                Column(
                  children: [
                    Slider(
                      value: state.position.inMilliseconds
                          .clamp(0, state.duration.inMilliseconds > 0 ? state.duration.inMilliseconds : 1)
                          .toDouble(),
                      max: (state.duration.inMilliseconds > 0 ? state.duration.inMilliseconds : 1).toDouble(),
                      activeColor: AppColors.saffronPrimary,
                      onChanged: (val) {
                        state.seek(Duration(milliseconds: val.round()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(state.position),
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            _formatDuration(state.duration),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Playback Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restart_alt, size: 28),
                      tooltip: 'Reset Session',
                      onPressed: () => state.resetSession(),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.saffronPrimary,
                      ),
                      child: IconButton(
                        iconSize: 42,
                        color: Colors.white,
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (state.isPlaying) {
                            state.pause();
                          } else if (state.isPaused) {
                            state.resume();
                          } else {
                            state.playMantra(widget.mantra, resetSessionCount: false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.stop, size: 28),
                      tooltip: 'Stop',
                      onPressed: () => state.stop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Manual Tap-to-Chant Accessible Button (>=48dp touch target)
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.touch_app, size: 22),
                    label: Text(
                      'TAP TO COUNT BEAD (+1) • ${state.completedRepetitions} / ${state.targetRepetitions}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                      foregroundColor: AppColors.saffronPrimary,
                      side: const BorderSide(color: AppColors.saffronPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      state.incrementManualRepetition();
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Target Repetitions Quick Chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Target Repetitions (Mala Count):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          onTap: () => _showCustomCountDialog(context),
                          child: const Text(
                            'All Presets & Custom >',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.saffronPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Includes 1 (for testing/quick single chant) and traditional presets
                        for (final count in [1, 11, 21, 27, 54, 108, 111, 1008])
                          ChoiceChip(
                            label: Text('$count'),
                            selected: state.targetRepetitions == count,
                            selectedColor: AppColors.saffronPrimary.withAlpha(50),
                            onSelected: (selected) {
                              if (selected) {
                                _requestChangeTarget(count);
                              }
                            },
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.tune, size: 16),
                          label: Text(
                            [1, 11, 21, 27, 54, 108, 111, 1008].contains(state.targetRepetitions)
                                ? 'Custom'
                                : 'Custom (${state.targetRepetitions})',
                          ),
                          onPressed: () => _showCustomCountDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Spiritual Significance Container
                if (widget.mantra.significance.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          children: [
                            Icon(
                              Icons.spa,
                              size: 16,
                              color: isDark ? AppColors.goldLight : AppColors.goldDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SPIRITUAL SIGNIFICANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isDark ? AppColors.goldLight : AppColors.goldDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.mantra.significance,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error Banner if any
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTargetLabel(int count) {
    switch (count) {
      case 11:
        return '(11 repetitions)';
      case 21:
        return '(21 repetitions)';
      case 27:
        return '(27 repetitions)';
      case 54:
        return '(Half Mala)';
      case 108:
        return '(One Mala)';
      case 111:
        return '(111 repetitions)';
      case 1008:
        return '(1008 repetitions)';
      default:
        return '(Custom)';
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
