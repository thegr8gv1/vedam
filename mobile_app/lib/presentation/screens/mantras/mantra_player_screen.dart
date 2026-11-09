import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_completion_dialog.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_target_modal.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_target_selector_widget.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';

class MantraPlayerScreen extends StatefulWidget {
  final MantraItem mantra;
  final AudioState audioState;
  final List<MantraItem>? playlist;

  const MantraPlayerScreen({
    super.key,
    required this.mantra,
    required this.audioState,
    this.playlist,
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

    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      widget.audioState.setPlaylist(widget.playlist!);
    }

    if (widget.audioState.activeMantra?.id != widget.mantra.id) {
      if (widget.mantra.isBundled) {
        widget.audioState.playMantra(widget.mantra, resetSessionCount: true);
      } else {
        // Set active mantra in state without triggering audio playback
        // to maintain clean manual Japa mode
        widget.audioState.stop();
      }
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

  void _cyclePlaybackSpeed() {
    final speeds = [0.75, 1.0, 1.25, 1.5];
    final current = widget.audioState.playbackSpeed;
    final nextIndex = (speeds.indexOf(current) + 1) % speeds.length;
    final nextSpeed = speeds[nextIndex];
    widget.audioState.setPlaybackSpeed(nextSpeed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playback speed set to ${nextSpeed}x'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSleepTimerModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime, color: AppColors.saffronPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Sleep Timer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Playback pauses automatically when the timer expires.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Off'),
                    selected: !widget.audioState.isSleepTimerActive,
                    onSelected: (val) {
                      widget.audioState.cancelSleepTimer();
                      Navigator.pop(ctx);
                    },
                  ),
                  for (final mins in [5, 10, 15, 30, 60])
                    ChoiceChip(
                      label: Text('$mins min'),
                      selected: widget.audioState.isSleepTimerActive &&
                          widget.audioState.sleepTimerRemaining?.inMinutes == mins,
                      onSelected: (val) {
                        widget.audioState.setSleepTimer(Duration(minutes: mins));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sleep timer set for $mins minutes')),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined, color: AppColors.saffronPrimary),
                title: const Text('Stop at Japa Target Completion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Pauses audio as soon as the chosen mala count is reached.', style: TextStyle(fontSize: 11)),
                onTap: () {
                  widget.audioState.setAutoPauseAtTarget(true);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Audio will pause when Japa target is completed')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUnavailableRecordingDialog(BuildContext context, MantraItem mantra) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Vault Archive Recording')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recording: ${mantra.filename}\nDuration: ${mantra.formattedDuration} (1 repetition, 48 kHz)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              'This master recording is preserved in the desktop vault (C:\\ttv youtube premium\\Mantras\\). To keep the mobile app size compact (<100MB), it is not bundled for offline audio playback in this release.\n\nYou can chant using the interactive Japa Mala counter in Manual Chanting mode.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffronPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Use Manual Counter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.audioState,
      builder: (context, _) {
        final state = widget.audioState;
        // Use active mantra from state if available (for next/previous navigation), else initial mantra
        final currentMantra = state.activeMantra ?? widget.mantra;
        final isFav = state.isFavorite(currentMantra.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(currentMantra.title),
            actions: [
              IconButton(
                icon: Icon(
                  widget.audioState.isSleepTimerActive ? Icons.bedtime : Icons.bedtime_outlined,
                  color: widget.audioState.isSleepTimerActive ? AppColors.saffronPrimary : null,
                ),
                tooltip: 'Sleep Timer',
                onPressed: () => _showSleepTimerModal(context),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                tooltip: isFav ? 'Remove Favorite' : 'Save Favorite',
                onPressed: () => state.toggleFavorite(currentMantra.id),
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
                        currentMantra.deity.toUpperCase(),
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
                        color: currentMantra.isBundled
                            ? Colors.green.withAlpha(30)
                            : Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentMantra.isBundled ? Colors.green : Colors.orange,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            currentMantra.isBundled ? Icons.offline_pin : Icons.storage,
                            size: 14,
                            color: currentMantra.isBundled ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentMantra.isBundled ? 'Offline Bundled' : 'Vault Archive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: currentMantra.isBundled ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Vault Archive Notice if unbundled
                if (!currentMantra.isBundled) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.amber),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VAULT ARCHIVE • MANUAL JAPA MODE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.amber,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Audio recording (${currentMantra.filename}) is archived in the desktop vault. The digital Japa Mala counter is fully functional in Manual Chanting mode.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

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
                        currentMantra.mantraText,
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
                const SizedBox(height: 14),

                // Explicit Counting Mode Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: state.isAudioChantingMode
                        ? AppColors.saffronPrimary.withAlpha(20)
                        : (isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.isAudioChantingMode
                          ? AppColors.saffronPrimary
                          : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        state.isAudioChantingMode ? Icons.volume_up : Icons.touch_app,
                        size: 15,
                        color: state.isAudioChantingMode ? AppColors.saffronPrimary : AppColors.goldDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isAudioChantingMode
                            ? 'COUNTING MODE: Audio-Assisted (+1 on completed recording)'
                            : 'COUNTING MODE: Manual Touch (+1 on bead tap)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: state.isAudioChantingMode
                              ? AppColors.saffronPrimary
                              : (isDark ? AppColors.goldLight : AppColors.goldDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Offline Audio Availability Indicator
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: currentMantra.isBundled
                        ? (isDark ? const Color(0xFF1B2E1D) : const Color(0xFFEDF7ED))
                        : (isDark ? const Color(0xFF2E2415) : const Color(0xFFFFF8EC)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: currentMantra.isBundled
                          ? (isDark ? Colors.green.shade700 : Colors.green.shade300)
                          : (isDark ? Colors.orange.shade700 : Colors.orange.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentMantra.isBundled ? Icons.offline_pin_outlined : Icons.cloud_outlined,
                        size: 16,
                        color: currentMantra.isBundled ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentMantra.isBundled
                              ? 'Offline Ready • Bundled Authentic Audio'
                              : 'Online Master Vault • Manual Japa Available Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: currentMantra.isBundled
                                ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                                : (isDark ? Colors.orange.shade300 : Colors.orange.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                      const Icon(
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

                // Audio Progress Bar (Active for bundled recordings)
                if (currentMantra.isBundled) ...[
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
                ],

                // Playback & Playlist Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Repeat Mode Toggle
                    IconButton(
                      icon: Icon(
                        state.repeatMode == DevotionalRepeatMode.repeatOne
                            ? Icons.repeat_one
                            : (state.repeatMode == DevotionalRepeatMode.sequential
                                ? Icons.playlist_play
                                : Icons.repeat),
                        color: state.repeatMode != DevotionalRepeatMode.repeatOff
                            ? AppColors.saffronPrimary
                            : null,
                      ),
                      tooltip: 'Repeat: ${state.repeatMode.name}',
                      onPressed: () => state.cycleRepeatMode(),
                    ),
                    const SizedBox(width: 8),

                    // Previous Mantra in Playlist
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 28),
                      tooltip: 'Previous Mantra',
                      onPressed: state.hasPreviousMantra
                          ? () => state.playPreviousMantra()
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Primary Play/Pause Button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentMantra.isBundled ? AppColors.saffronPrimary : Colors.grey,
                      ),
                      child: IconButton(
                        iconSize: 42,
                        color: Colors.white,
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (!currentMantra.isBundled) {
                            _showUnavailableRecordingDialog(context, currentMantra);
                            return;
                          }

                          if (state.isPlaying) {
                            state.pause();
                          } else if (state.isPaused) {
                            state.resume();
                          } else {
                            state.playMantra(currentMantra, resetSessionCount: false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Next Mantra in Playlist
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 28),
                      tooltip: 'Next Mantra',
                      onPressed: state.hasNextMantra
                          ? () => state.playNextMantra()
                          : null,
                    ),
                    const SizedBox(width: 8),

                    // Playback Speed Toggle
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _cyclePlaybackSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                          ),
                        ),
                        child: Text(
                          '${state.playbackSpeed}x',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.saffronPrimary,
                          ),
                        ),
                      ),
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

                // Dedicated Japa Target Selection Interface (Phase 16B.1)
                JapaTargetSelectorWidget(
                  audioState: widget.audioState,
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 20),

                // Reset Session Button
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset Japa Session'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                    ),
                    onPressed: () => state.resetSession(),
                  ),
                ),
                const SizedBox(height: 16),

                // Spiritual Significance Container
                if (currentMantra.significance.isNotEmpty)
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
                          currentMantra.significance,
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
