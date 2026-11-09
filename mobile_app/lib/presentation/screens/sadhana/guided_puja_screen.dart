import 'package:flutter/material.dart';
import '../../../core/models/japa_practice_session.dart';
import '../../../core/models/puja_guide.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../state/audio_state.dart';
import '../../../state/sadhana_state.dart';
import '../japa/japa_practice_screen.dart';
import 'widgets/puja_guide_overview_modal.dart';
import 'widgets/puja_history_modal.dart';
import 'widgets/puja_preparation_modal.dart';

/// Step-by-step guided puja worship experience.
/// Presents one worship step at a time with readable Sanskrit, transliteration,
/// action instructions, optional step skipping, linked Japa practice integration,
/// pause/resume, and calm devotional completion.
class GuidedPujaScreen extends StatefulWidget {
  final PujaGuide guide;
  final SadhanaState sadhanaState;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;

  const GuidedPujaScreen({
    super.key,
    required this.guide,
    required this.sadhanaState,
    this.mantraRepository,
    this.audioState,
  });

  @override
  State<GuidedPujaScreen> createState() => _GuidedPujaScreenState();
}

class _GuidedPujaScreenState extends State<GuidedPujaScreen> {
  final Set<String> _fulfilledJapaStepIds = {};
  final Map<String, String> _stepJapaSessionBindings = {};

  @override
  void initState() {
    super.initState();
    widget.sadhanaState.addListener(_onStateChange);
    if (widget.sadhanaState.activeGuide?.id != widget.guide.id) {
      widget.sadhanaState.startPujaSession(widget.guide);
    }
    _restoreJapaStepBindings();
  }

  void _restoreJapaStepBindings() {
    final activePuja = widget.sadhanaState.activePujaSession;
    if (activePuja != null && activePuja.japaStepBindings.isNotEmpty) {
      _stepJapaSessionBindings.addAll(activePuja.japaStepBindings);
      _fulfilledJapaStepIds.addAll(activePuja.japaStepBindings.keys);
    }
  }

  @override
  void dispose() {
    widget.sadhanaState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    _restoreJapaStepBindings();
    if (mounted) setState(() {});
  }

  Future<void> _openLinkedJapa(PujaStep step) async {
    final mRepo = widget.mantraRepository ?? MantraRepositoryImpl();
    final aState = widget.audioState;

    if (step.linkedMantraId == null) return;
    final mantra = mRepo.getMantraById(step.linkedMantraId!);

    if (mantra != null && aState != null) {
      final targetRepetitions = step.targetRepetitions ?? 108;
      final baselineStartTime = DateTime.now();
      final priorActiveSessionId = aState.activeSession?.id;
      final priorHistoryCount = aState.sessionHistory.length;

      if (aState.targetRepetitions != targetRepetitions && !aState.hasActiveOrPausedSession) {
        aState.setTargetRepetitions(targetRepetitions);
      }

      // Open Phase 21A JapaPracticeScreen strictly WITHOUT autoplay
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => JapaPracticeScreen(
            audioState: aState,
            mantraRepository: mRepo,
            initialMantra: mantra,
          ),
        ),
      );

      if (!mounted) return;

      // Identify newly completed session
      JapaPracticeSession? candidateSession;
      if (aState.sessionHistory.length > priorHistoryCount) {
        final newest = aState.sessionHistory.first;
        if (newest.mantraId == step.linkedMantraId) {
          candidateSession = newest;
        }
      }
      if (candidateSession == null && aState.activeSession != null) {
        final act = aState.activeSession!;
        if (act.mantraId == step.linkedMantraId) {
          candidateSession = act;
        }
      }

      // Validate session identity and completion
      final bool isSessionValid = candidateSession != null &&
          candidateSession.mantraId == step.linkedMantraId &&
          candidateSession.completedRepetitions >= targetRepetitions &&
          candidateSession.status != JapaSessionStatus.paused &&
          candidateSession.status != JapaSessionStatus.abandoned &&
          (candidateSession.lastUpdatedTime.isAfter(baselineStartTime.subtract(const Duration(seconds: 2))) ||
              candidateSession.id != priorActiveSessionId);

      if (isSessionValid) {
        setState(() {
          _fulfilledJapaStepIds.add(step.id);
          _stepJapaSessionBindings[step.id] = candidateSession!.id;
        });
        widget.sadhanaState.recordJapaStepFulfillment(step.id, candidateSession.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('॥ जप पूर्णम् ॥ Japa target ($targetRepetitions chants) completed.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final completedCount = (candidateSession != null)
            ? candidateSession.completedRepetitions
            : ((aState.activeMantra?.id == step.linkedMantraId) ? aState.completedRepetitions : 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Japa in progress: $completedCount of $targetRepetitions completed. '
              'Complete target in an active session to fulfill step.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mantra "${step.linkedMantraId}" is available in manual contemplation mode.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _confirmPauseAndExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pause Worship?'),
        content: const Text(
          'Your active step will be saved in your session. You can resume this worship anytime today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Worship'),
          ),
          TextButton(
            onPressed: () {
              widget.sadhanaState.abandonPujaSession();
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Abandon'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffronPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pause & Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      widget.sadhanaState.pausePujaSession();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = widget.sadhanaState;
    final isCompleted = state.isGuideCompleted;
    final currentStep = state.currentGuideStep;

    return PopScope(
      canPop: isCompleted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmPauseAndExit();
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                widget.guide.title,
                style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 16),
              ),
              if (!isCompleted && currentStep != null)
                Text(
                  'STEP ${state.activeGuideStepIndex + 1} OF ${widget.guide.steps.length}',
                  style: AppTextStyles.metadataTag(isDark).copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                  ),
                ),
            ],
          ),
          centerTitle: true,
          actions: [
            // Preparation Checklist button
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              tooltip: 'Preparation & Materials',
              onPressed: () => PujaPreparationModal.show(
                context: context,
                guide: widget.guide,
                sadhanaState: widget.sadhanaState,
              ),
            ),
            // Steps overview
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'Steps Overview',
              onPressed: () => PujaGuideOverviewModal.show(
                context: context,
                guide: widget.guide,
                currentStepIndex: state.activeGuideStepIndex,
                onStart: () {},
              ),
            ),
            // History
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Puja History',
              onPressed: () => PujaHistoryModal.show(
                context: context,
                sadhanaState: widget.sadhanaState,
              ),
            ),
            // Pause / Resume
            if (!isCompleted)
              IconButton(
                icon: Icon(state.isGuidePaused ? Icons.play_arrow : Icons.pause),
                tooltip: state.isGuidePaused ? 'Resume Worship' : 'Pause Worship',
                onPressed: () {
                  if (state.isGuidePaused) {
                    state.resumePujaSession();
                  } else {
                    state.pausePujaSession();
                  }
                },
              ),
          ],
        ),
        body: isCompleted
            ? _buildCompletionView(isDark)
            : currentStep == null
                ? const Center(child: Text('No steps available'))
                : _buildStepView(isDark, currentStep),
        bottomNavigationBar: isCompleted ? null : _buildStepNavigationBar(isDark, currentStep),
      ),
    );
  }

  Widget _buildStepView(bool isDark, PujaStep step) {
    final isTargetReached = step.linkedMantraId == null ||
        _fulfilledJapaStepIds.contains(step.id) ||
        (widget.sadhanaState.activePujaSession?.japaStepBindings.containsKey(step.id) ?? false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        // 1. Upachara & Optional Tag & Step Title
        Row(
          children: [
            if (step.upacharaName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF332211) : const Color(0xFFF6EDE0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.goldGlow : AppColors.goldPrimary,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  step.upacharaName!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (step.isOptional) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'OPTIONAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                'Step ${step.stepNumber}',
                style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          step.stepName,
          style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 19),
        ),
        const SizedBox(height: 14),

        // 2. Action Guidance Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFAF7F0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.touch_app_outlined, color: AppColors.saffronPrimary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRAYER ACTION',
                      style: AppTextStyles.metadataTag(isDark).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.saffronPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.actionDescription,
                      style: AppTextStyles.bodyMedium(isDark).copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Sanskrit Mantra Card
        if (step.sanskritMantra != null && step.sanskritMantra!.isNotEmpty) ...[
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppColors.goldPrimary.withAlpha(120) : AppColors.goldDark.withAlpha(120),
                width: 1.2,
              ),
            ),
            color: isDark ? const Color(0xFF241A10) : const Color(0xFFFFFBF2),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.self_improvement, size: 18, color: AppColors.goldPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'SACRED SANSKRIT MANTRA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    step.sanskritMantra!,
                    style: AppTextStyles.verseDevanagari(isDark, scale: 0.95),
                    textAlign: TextAlign.center,
                  ),
                  if (step.transliteration != null && step.transliteration!.isNotEmpty) ...[
                    const Divider(height: 24),
                    SelectableText(
                      step.transliteration!,
                      style: AppTextStyles.verseTransliteration(isDark),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 4. English Meaning
        if (step.meaning != null && step.meaning!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.nightSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPIRITUAL MEANING & SIGNIFICANCE',
                  style: AppTextStyles.metadataTag(isDark).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.meaning!,
                  style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 5. Source Attribution & Provenance
        if (step.scripturalSource != null && step.scripturalSource!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF221A12) : const Color(0xFFF9F5EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.goldGlow.withAlpha(60) : AppColors.goldPrimary.withAlpha(60),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.goldPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Source: ${step.scripturalSource!}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? const Color(0xFFBCAAA4) : const Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 6. Linked Japa Practice Card
        if (step.linkedMantraId != null) ...[
          Card(
            color: isTargetReached
                ? (isDark ? const Color(0xFF162D1C) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFF2C1F14) : const Color(0xFFFFF6EA)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isTargetReached ? Colors.green : AppColors.saffronPrimary,
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () => _openLinkedJapa(step),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isTargetReached ? Colors.green : AppColors.saffronPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isTargetReached ? Icons.check_circle : Icons.music_note,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isTargetReached ? 'JAPA TARGET FULFILLED' : 'LINKED CHANTING PRACTICE',
                                style: AppTextStyles.metadataTag(isDark).copyWith(
                                  fontSize: 10,
                                  color: isTargetReached ? Colors.green : AppColors.saffronPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (isTargetReached ? Colors.green : Colors.amber).withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isTargetReached
                                      ? 'VERIFIED'
                                      : (step.targetRepetitions != null ? '${step.targetRepetitions} CHANTS' : 'JAPA'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isTargetReached ? Colors.green : (isDark ? Colors.amber[200] : Colors.amber[900]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            step.linkedMantraTitle ?? 'Chant Mantra & Count Mala',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            isTargetReached
                                ? 'Target completed. Devotee may proceed to next step.'
                                : 'Tap to open Japa practice (${step.targetRepetitions ?? 108} target) • No autoplay',
                            style: AppTextStyles.caption(isDark),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isTargetReached ? Colors.green : AppColors.saffronPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 7. Expanded Instructions
        if (step.expandedInstructions.isNotEmpty) ...[
          ExpansionTile(
            title: Text(
              'Contemplative Tips & Observations',
              style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.goldPrimary),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: step.expandedInstructions
                .map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(tip, style: AppTextStyles.bodySmall(isDark)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],

        // 8. Scholarly Verification & Curation Disclosure
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF221A12) : const Color(0xFFF9F5EC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.goldGlow.withAlpha(50) : AppColors.goldPrimary.withAlpha(50),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.goldPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Editorially curated traditional guide — awaiting independent scholarly verification.',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isDark ? const Color(0xFFBCAAA4) : const Color(0xFF5D4037),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepNavigationBar(bool isDark, PujaStep? currentStep) {
    final state = widget.sadhanaState;
    final isFirstStep = state.activeGuideStepIndex == 0;
    final isLastStep = state.activeGuideStepIndex == widget.guide.steps.length - 1;
    final progress = (state.activeGuideStepIndex + 1) / widget.guide.steps.length;
    final isOptional = currentStep?.isOptional ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? AppColors.nightSurface : const Color(0xFFF0EAE1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isFirstStep)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: state.previousPujaStep,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('PREVIOUS'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (!isFirstStep) const SizedBox(width: 8),

                // Skip optional step button if optional
                if (isOptional) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: state.skipOptionalPujaStep,
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: const Text('SKIP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                Expanded(
                  flex: isFirstStep ? 2 : 1,
                  child: ElevatedButton.icon(
                    onPressed: state.completeCurrentPujaStep,
                    icon: Icon(isLastStep ? Icons.check_circle : Icons.arrow_forward, size: 18),
                    label: Text(
                      isLastStep ? 'COMPLETE WORSHIP' : 'NEXT STEP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastStep ? Colors.green[700] : AppColors.saffronPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2214) : const Color(0xFFFFF5E6),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldPrimary, width: 2),
              ),
              child: const Icon(Icons.temple_hindu, size: 54, color: AppColors.goldPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              'Pūjā Sampanna (Worship Completed)',
              style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'सर्वं श्रीकृष्णार्पणमस्तु ।\n(All is offered unto the Supreme Divine)',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFAF7F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                ),
              ),
              child: Text(
                'May the peace, purity, and spiritual grace cultivated during this sacred practice '
                'abide with you and inspire noble actions throughout the day.\n\n'
                'Your worship record has been saved locally to your private devotional history.',
                style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 13, height: 1.45),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.sadhanaState.exitGuide();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text(
                  'RETURN TO DAILY SADHANA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
