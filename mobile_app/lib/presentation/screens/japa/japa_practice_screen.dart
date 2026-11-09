import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/japa_practice_session.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/core/theme/text_styles.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_completion_dialog.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_target_selector_widget.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'widgets/japa_history_modal.dart';


/// Complete, sacred, distraction-free Daily Japa Practice Screen.
///
/// Features:
/// - Full manual and audio-assisted chanting modes.
/// - Prominent target selection (all 7 traditional presets and validated custom target).
/// - No accidental autoplay on entry: audio plays only upon explicit user command.
/// - Active session interruption recovery and local offline persistence.
/// - Pause, resume, finish, and abandon practice controls.
/// - Comprehensive practice history review.
/// - Full screen-reader accessibility (>=48dp touch targets, semantic announcements).
class JapaPracticeScreen extends StatefulWidget {
  final AudioState audioState;
  final MantraRepository? mantraRepository;
  final MantraItem? initialMantra;

  const JapaPracticeScreen({
    super.key,
    required this.audioState,
    this.mantraRepository,
    this.initialMantra,
  });

  @override
  State<JapaPracticeScreen> createState() => _JapaPracticeScreenState();
}

class _JapaPracticeScreenState extends State<JapaPracticeScreen> {
  late MantraItem _currentMantra;
  bool _isCompletionDialogShowing = false;

  @override
  void initState() {
    super.initState();
    widget.audioState.addListener(_onAudioStateChanged);

    // Resolve active mantra: initialMantra -> state.activeMantra -> repository first -> canonical fallback
    if (widget.initialMantra != null) {
      _currentMantra = widget.initialMantra!;
    } else if (widget.audioState.activeMantra != null) {
      _currentMantra = widget.audioState.activeMantra!;
    } else if (widget.mantraRepository != null &&
        widget.mantraRepository!.getAllMantras().isNotEmpty) {
      _currentMantra = widget.mantraRepository!.getAllMantras().first;
    } else {
      _currentMantra = const MantraItem(
        id: 'VEDA-MTR-0001',
        collection: 'Shiva',
        deity: 'Shiva',
        title: 'Om Namah Shivaya',
        filename: 'Om Namah Shivaya.wav',
        mantraText: 'ॐ नमः शिवाय',
        significance: 'Purifies the mind and leads to inner stillness.',
        form: '',
        durationSeconds: 4.5,
        sampleRate: 48000,
        bitDepth: 16,
        channels: 2,
        fileSizeBytes: 877484,
        sha256: 'abc1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        sourceTxt: 'Assorted Shiva Chants.txt',
        isBundled: true,
        bundledAssetPath: 'assets/audio/bundled/om_namah_shivaya.mp3',
      );
    }

    // Set mantra in state without triggering audio playback (prevents accidental autoplay)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.audioState.setActiveMantraWithoutPlaying(_currentMantra);
    });
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
    setState(() {});
  }

  void _showMantraSelector() {
    if (widget.mantraRepository == null) return;
    final allMantras = widget.mantraRepository!.getAllMantras();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: AppColors.saffronPrimary),
                    const SizedBox(width: 8),
                    const Text(
                      'Select Sacred Mantra',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: allMantras.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final mantra = allMantras[index];
                    final isSelected = mantra.id == _currentMantra.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.saffronPrimary.withAlpha(25),
                      title: Text(
                        mantra.title,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${mantra.deity} • ${mantra.isBundled ? "Offline Audio" : "Manual Mode"}',
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.saffronPrimary)
                          : null,
                      onTap: () {
                        setState(() {
                          _currentMantra = mantra;
                        });
                        widget.audioState.setActiveMantraWithoutPlaying(mantra);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAbandonSession() async {
    final completed = widget.audioState.completedRepetitions;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('End Japa Session?'),
          ],
        ),
        content: Text(
          completed > 0
              ? 'You have chanted $completed repetitions. Concluding now will archive this session into your practice history and reset the counter for a fresh round.'
              : 'Reset the counter for a fresh round?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffronPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Conclude Session'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.audioState.abandonSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.audioState;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = state.completedRepetitions;
    final target = state.targetRepetitions;
    final remaining = state.remainingRepetitions;
    final isPaused = state.isPaused ||
        (state.activeSession?.status == JapaSessionStatus.paused);
    final hasActiveSession = state.hasActiveOrPausedSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Japa Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Practice History',
            onPressed: () => JapaHistoryModal.show(context, state),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Interruption Recovery Banner (if an active/paused session was recovered)
            if (hasActiveSession && isPaused && completed > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restore, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PREVIOUS SESSION PAUSED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$completed of $target chants preserved safely.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => state.resumeSession(),
                      child: const Text('Resume'),
                    ),
                  ],
                ),
              ),

            // Mantra Card & Switcher
            Container(
              padding: const EdgeInsets.all(18),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.saffronPrimary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.saffronPrimary),
                        ),
                        child: Text(
                          _currentMantra.deity.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.saffronPrimary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (widget.mantraRepository != null)
                        TextButton.icon(
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Change Mantra', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.saffronPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onPressed: _showMantraSelector,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentMantra.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentMantra.mantraText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Counting Mode Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state.isAudioChantingMode ? Icons.volume_up : Icons.touch_app,
                    size: 16,
                    color: AppColors.saffronPrimary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      state.isAudioChantingMode
                          ? 'Audio-Assisted Mode (+1 per completed playback)'
                          : 'Manual Bead Mode (+1 per touch tap)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Visual Mala Progress
            VisualMalaWidget(
              completedCount: completed,
              targetCount: target,
              isPlaying: state.isPlaying,
            ),

            const SizedBox(height: 16),

            // Prominent Counter Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'COMPLETED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.saffronPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$completed',
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'REMAINING',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$remaining',
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target: $target repetitions',
                    style: AppTextStyles.caption(isDark).copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Large Sacred Bead Tap Button (Touch target >= 54dp)
            Semantics(
              label: 'Chant Bead +1, current count $completed of $target',
              button: true,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fingerprint, size: 26),
                  label: Text(
                    'COUNT BEAD (+1) • $completed / $target',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () {
                    state.incrementManualRepetition();
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Audio Chanting Controls (if audio is available)
            if (_currentMantra.isBundled) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.graphic_eq, color: AppColors.saffronPrimary, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Audio-Assisted Chanting',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.isPlaying ? 'Playing' : (state.isPaused ? 'Paused' : 'Ready'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: state.isPlaying ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 44,
                            color: AppColors.saffronPrimary,
                          ),
                          tooltip: state.isPlaying ? 'Pause Audio' : 'Play Audio (+1 per count)',
                          onPressed: () {
                            if (state.isPlaying) {
                              state.pause();
                            } else if (state.isPaused) {
                              state.resume();
                            } else {
                              state.playMantra(_currentMantra, resetSessionCount: false);
                            }
                          },
                        ),
                        if (state.isPlaying || state.isPaused) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.stop_circle_outlined, size: 36),
                            tooltip: 'Stop Audio',
                            onPressed: () => state.stop(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Session Flow Controls (Pause / Resume / Finish / Abandon)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 18),
                    label: Text(isPaused ? 'Resume' : 'Pause'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (isPaused) {
                        state.resumeSession();
                      } else {
                        state.pauseSession();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Finish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => state.finishSession(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'End / Reset Session',
                  onPressed: _confirmAbandonSession,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Repetition Target Selector Widget
            JapaTargetSelectorWidget(
              audioState: widget.audioState,
            ),
          ],
        ),
      ),
    );
  }
}