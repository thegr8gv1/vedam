import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/models/orchestrator_session.dart';
import '../../../../core/models/practice_sequence.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/fixtures/authentic_puja_guides_data.dart';
import '../../../../data/fixtures/authentic_scriptures_data.dart';
import '../../../../data/repositories/mantra_repository.dart';
import '../../../../state/app_state.dart';
import '../../../../state/audio_state.dart';
import '../../../../state/orchestrator_state.dart';
import '../../../../state/panchangam_state.dart';
import '../../../../state/sadhana_state.dart';
import '../../../../state/scripture_reader_state.dart';
import '../../../../state/vrat_state.dart';
import '../../japa/japa_practice_screen.dart';
import '../../library/verse_learning_screen.dart';
import '../../mantras/mantra_player_screen.dart';
import '../../vrat/vrat_calendar_screen.dart';
import '../guided_puja_screen.dart';
import '../widgets/sankalpa_generator_modal.dart';

/// Modal dialog / runner for guided step-by-step devotional practice sequences.
/// Devotees can advance sequentially through steps, open specialized practice tools,
/// skip optional steps, pause and resume at any time, or conclude with sacred quietude.
class SequenceExecutionModal extends StatefulWidget {
  final OrchestratorState orchestratorState;
  final PracticeSequence sequence;
  final AppState? appState;
  final SadhanaState? sadhanaState;
  final AudioState? audioState;
  final PanchangamState? panchangamState;
  final VratState? vratState;
  final MantraRepository? mantraRepository;
  final ScriptureReaderState? scriptureReaderState;

  const SequenceExecutionModal({
    super.key,
    required this.orchestratorState,
    required this.sequence,
    this.appState,
    this.sadhanaState,
    this.audioState,
    this.panchangamState,
    this.vratState,
    this.mantraRepository,
    this.scriptureReaderState,
  });

  static Future<void> show(
    BuildContext context, {
    required OrchestratorState orchestratorState,
    required PracticeSequence sequence,
    AppState? appState,
    SadhanaState? sadhanaState,
    AudioState? audioState,
    PanchangamState? panchangamState,
    VratState? vratState,
    MantraRepository? mantraRepository,
    ScriptureReaderState? scriptureReaderState,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => SequenceExecutionModal(
        orchestratorState: orchestratorState,
        sequence: sequence,
        appState: appState,
        sadhanaState: sadhanaState,
        audioState: audioState,
        panchangamState: panchangamState,
        vratState: vratState,
        mantraRepository: mantraRepository,
        scriptureReaderState: scriptureReaderState,
      ),
    );
  }

  @override
  State<SequenceExecutionModal> createState() => _SequenceExecutionModalState();
}

class _SequenceExecutionModalState extends State<SequenceExecutionModal> {
  bool _isCompletedView = false;
  Timer? _contemplationTimer;
  int _contemplationSecondsRemaining = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    widget.orchestratorState.addListener(_onStateChange);

    // If no active session or different sequence, start fresh
    final active = widget.orchestratorState.activeSession;
    if (active == null || active.sequenceId != widget.sequence.id) {
      widget.orchestratorState.startSequence(widget.sequence);
    } else if (active.isPaused) {
      widget.orchestratorState.resumeSession();
    }
  }

  @override
  void dispose() {
    _contemplationTimer?.cancel();
    widget.orchestratorState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    final active = widget.orchestratorState.activeSession;
    if (active == null && !_isCompletedView) {
      // Completed or abandoned externally
      setState(() {});
    } else {
      setState(() {});
    }
  }

  void _startContemplationTimer(int minutes) {
    _contemplationTimer?.cancel();
    setState(() {
      _contemplationSecondsRemaining = minutes * 60;
      _isTimerRunning = true;
    });

    _contemplationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_contemplationSecondsRemaining > 0) {
          _contemplationSecondsRemaining--;
        } else {
          _isTimerRunning = false;
          timer.cancel();
        }
      });
    });
  }

  void _pauseContemplationTimer() {
    _contemplationTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  Future<void> _handleCompleteStep(int stepIndex) async {
    _contemplationTimer?.cancel();
    _isTimerRunning = false;

    final session = widget.orchestratorState.activeSession;
    if (session == null) return;

    // Check if this is the last enabled step
    int nextEnabled = -1;
    for (int i = stepIndex + 1; i < widget.sequence.steps.length; i++) {
      if (widget.sequence.steps[i].isEnabled) {
        nextEnabled = i;
        break;
      }
    }

    if (nextEnabled == -1) {
      // Session completing! Show warm completion screen
      setState(() {
        _isCompletedView = true;
      });
      await widget.orchestratorState.completeStep(stepIndex, sequence: widget.sequence);
    } else {
      await widget.orchestratorState.completeStep(stepIndex, sequence: widget.sequence);
    }
  }

  Future<void> _handleSkipStep(int stepIndex) async {
    _contemplationTimer?.cancel();
    _isTimerRunning = false;

    final session = widget.orchestratorState.activeSession;
    if (session == null) return;

    int nextEnabled = -1;
    for (int i = stepIndex + 1; i < widget.sequence.steps.length; i++) {
      if (widget.sequence.steps[i].isEnabled) {
        nextEnabled = i;
        break;
      }
    }

    if (nextEnabled == -1) {
      setState(() {
        _isCompletedView = true;
      });
      await widget.orchestratorState.skipStep(stepIndex, sequence: widget.sequence);
    } else {
      await widget.orchestratorState.skipStep(stepIndex, sequence: widget.sequence);
    }
  }

  Future<void> _pauseAndClose() async {
    await widget.orchestratorState.pauseSession();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Practice session paused. You can resume anytime.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmAbandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conclude or Exit Practice?'),
        content: const Text(
          'Would you like to pause and save your progress to resume later, or conclude this practice?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Pause & Save'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Conclude Without Saving'),
          ),
        ],
      ),
    );

    if (confirmed == null) return;

    if (confirmed) {
      await widget.orchestratorState.abandonSession();
      if (mounted) Navigator.pop(context);
    } else {
      await _pauseAndClose();
    }
  }

  void _launchPracticeActivity(PracticeStep step) {
    switch (step.stepType) {
      case PracticeStepType.sankalpa:
        SankalpaGeneratorModal.show(
          context: context,
          panchangam: widget.panchangamState?.data,
        );
        break;

      case PracticeStepType.guidedPuja:
        // Pick authentic puja guide matching resourceId or default Shiva/Ganesha
        final guide = AuthenticPujaGuidesData.allGuides.firstWhere(
          (g) => g.id == step.resourceId,
          orElse: () => AuthenticPujaGuidesData.allGuides.first,
        );
        final sadhanaState = widget.sadhanaState ?? SadhanaState();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GuidedPujaScreen(
              guide: guide,
              sadhanaState: sadhanaState,
              mantraRepository: widget.mantraRepository,
              audioState: widget.audioState,
            ),
          ),
        );
        break;

      case PracticeStepType.japa:
        if (widget.audioState != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JapaPracticeScreen(
                audioState: widget.audioState!,
                mantraRepository: widget.mantraRepository,
              ),
            ),
          );
        }
        break;

      case PracticeStepType.mantraAudio:
        if (widget.audioState != null && widget.mantraRepository != null) {
          final mantra = widget.mantraRepository!.getAllMantras().firstWhere(
            (m) => m.id == step.resourceId,
            orElse: () => widget.mantraRepository!.getAllMantras().first,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MantraPlayerScreen(
                mantra: mantra,
                audioState: widget.audioState!,
                autoPlay: false, // Strict zero autoplay
              ),
            ),
          );
        }
        break;

      case PracticeStepType.scriptureStudy:
        final scripture = kAuthenticScriptures.firstWhere(
          (s) => s.id == (int.tryParse(step.resourceId ?? '') ?? 1),
          orElse: () => kAuthenticScriptures.first,
        );
        final readerState = widget.scriptureReaderState ?? ScriptureReaderState();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerseLearningScreen(
              scripture: scripture,
              readerState: readerState,
              audioState: widget.audioState,
              appState: widget.appState,
            ),
          ),
        );
        break;

      case PracticeStepType.vratObservance:
        final vratState = widget.vratState ?? VratState();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VratCalendarScreen(
              vratState: vratState,
              sadhanaState: widget.sadhanaState,
              panchangamState: widget.panchangamState,
              mantraRepository: widget.mantraRepository,
              audioState: widget.audioState,
            ),
          ),
        );
        break;

      case PracticeStepType.personalContemplation:
        // Handled directly inline via timer controls
        if (!_isTimerRunning) {
          _startContemplationTimer(step.estimatedMinutes);
        }
        break;
    }
  }

  String _formatTimerTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
  }

  IconData _stepTypeIcon(PracticeStepType type) {
    switch (type) {
      case PracticeStepType.sankalpa:
        return Icons.auto_stories;
      case PracticeStepType.guidedPuja:
        return Icons.flare;
      case PracticeStepType.japa:
        return Icons.radio_button_checked;
      case PracticeStepType.mantraAudio:
        return Icons.volume_up_outlined;
      case PracticeStepType.scriptureStudy:
        return Icons.menu_book;
      case PracticeStepType.vratObservance:
        return Icons.calendar_month;
      case PracticeStepType.personalContemplation:
        return Icons.self_improvement;
    }
  }

  String _actionButtonLabel(PracticeStepType type) {
    switch (type) {
      case PracticeStepType.sankalpa:
        return 'Open Sankalpa Generator';
      case PracticeStepType.guidedPuja:
        return 'Open Guided Puja';
      case PracticeStepType.japa:
        return 'Open Japa Practice';
      case PracticeStepType.mantraAudio:
        return 'Open Audio Chanting';
      case PracticeStepType.scriptureStudy:
        return 'Open Scripture Reading';
      case PracticeStepType.vratObservance:
        return 'Open Vrat Calendar';
      case PracticeStepType.personalContemplation:
        return _isTimerRunning ? 'Timer In Progress' : 'Start Contemplation Timer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = widget.orchestratorState.activeSession;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _isCompletedView
              ? _buildCompletedView(context, isDark, theme)
              : _buildProgressionView(context, isDark, theme, session, scrollController),
        );
      },
    );
  }

  Widget _buildProgressionView(
    BuildContext context,
    bool isDark,
    ThemeData theme,
    OrchestratorSession? session,
    ScrollController scrollController,
  ) {
    final steps = widget.sequence.steps;
    final enabledSteps = steps.where((s) => s.isEnabled).toList();
    final currentIndex = session?.currentStepIndex ?? 0;
    final currentStep = (currentIndex >= 0 && currentIndex < steps.length)
        ? steps[currentIndex]
        : (enabledSteps.isNotEmpty ? enabledSteps.first : null);

    // Calculate progression metrics
    final totalEnabled = enabledSteps.length;
    final completedCount = session?.stepStatuses.values
            .where((s) => s == StepExecutionStatus.completed)
            .length ??
        0;
    final currentStepNumber = enabledSteps.indexWhere((s) => s.id == currentStep?.id) + 1;
    final progress = totalEnabled > 0 ? (completedCount / totalEnabled).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // Top Drag Handle & Controls
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.pause_circle_outline, color: AppColors.goldPrimary),
                tooltip: 'Pause & Resume Later',
                onPressed: _pauseAndClose,
              ),
              Expanded(
                child: Text(
                  widget.sequence.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Exit Practice',
                onPressed: _confirmAbandon,
              ),
            ],
          ),
        ),

        // Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step $currentStepNumber of $totalEnabled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% completed',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 16),

        // Current Step Content
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: currentStep == null
                ? const Center(child: Text('No active steps found in this sequence.'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Step Type & Status Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.goldPrimary.withAlpha(38),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _stepTypeIcon(currentStep.stepType),
                              color: AppColors.goldPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: currentStep.isOptional
                                            ? Colors.blue.withAlpha(38)
                                            : Colors.orange.withAlpha(38),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        currentStep.isOptional ? 'Optional Step' : 'Required Step',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: currentStep.isOptional ? Colors.blue : Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '~${currentStep.estimatedMinutes} min',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentStep.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262638) : const Color(0xFFF9F9FC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStep.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            if (currentStep.targetRepetitions != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.repeat, size: 16, color: AppColors.goldPrimary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Recommended target: ${currentStep.targetRepetitions} repetitions',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.goldPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Contemplation timer if applicable
                      if (currentStep.stepType == PracticeStepType.personalContemplation) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E2E42) : const Color(0xFFEDEDF4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _isTimerRunning || _contemplationSecondsRemaining > 0
                                    ? _formatTimerTime(_contemplationSecondsRemaining)
                                    : '${currentStep.estimatedMinutes}:00',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: AppColors.goldPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!_isTimerRunning)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Start Quiet Timer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.goldPrimary,
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: () => _startContemplationTimer(currentStep.estimatedMinutes),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.pause),
                                      label: const Text('Pause Timer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _pauseContemplationTimer,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Primary Launch Button
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          icon: Icon(_stepTypeIcon(currentStep.stepType), color: AppColors.goldPrimary),
                          label: Text(
                            _actionButtonLabel(currentStep.stepType),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _launchPracticeActivity(currentStep),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Opens the focused practice screen. Autoplay is strictly disabled.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Bottom Progression Controls
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              // Skip step button (if optional)
              if (currentStep?.isOptional ?? true)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleSkipStep(currentIndex),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Skip Step'),
                  ),
                ),
              if (currentStep?.isOptional ?? true) const SizedBox(width: 12),
              // Complete step button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _handleCompleteStep(currentIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    currentIndex >= steps.length - 1 || currentStepNumber == totalEnabled
                        ? 'Complete Sadhana'
                        : 'Mark Complete & Next',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView(BuildContext context, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.goldPrimary,
              size: 64,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Practice Concluded',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ॐ शान्तिः शान्तिः शान्तिः',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.goldPrimary,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your practice sequence has concluded with reverent peace. '
            'It has been recorded privately in your local devotional journal.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Return to Sadhana',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
