import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/guided_sadhana.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/core/theme/text_styles.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';
import '../japa/japa_practice_screen.dart';

/// Step-by-step guided devotional Sadhana practice experience.
/// Supports sequential step progression, transparent scriptural provenance,
/// deep integration with the Phase 21A daily Japa engine without duplicate counting,
/// safe pause/resume persistence, and serene completion.
class GuidedSadhanaScreen extends StatefulWidget {
  final GuidedSadhanaPlan plan;
  final SadhanaState sadhanaState;
  final AudioState? audioState;
  final MantraRepository? mantraRepository;

  const GuidedSadhanaScreen({
    super.key,
    required this.plan,
    required this.sadhanaState,
    this.audioState,
    this.mantraRepository,
  });

  @override
  State<GuidedSadhanaScreen> createState() => _GuidedSadhanaScreenState();
}

class _GuidedSadhanaScreenState extends State<GuidedSadhanaScreen> {
  @override
  void initState() {
    super.initState();
    widget.sadhanaState.addListener(_onStateChange);
    widget.audioState?.addListener(_onStateChange);

    // If there is no active session matching this plan, start it
    if (widget.sadhanaState.activeSadhanaPlan?.id != widget.plan.id ||
        widget.sadhanaState.activeSadhanaSession == null) {
      widget.sadhanaState.startSadhana(widget.plan);
    }
  }

  @override
  void dispose() {
    widget.sadhanaState.removeListener(_onStateChange);
    widget.audioState?.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<bool> _confirmPauseAndExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pause Sadhana Practice?'),
        content: const Text(
          'Your active step and legitimate progress will be preserved safely. '
          'You can resume this guided practice anytime today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Practice'),
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
      widget.sadhanaState.pauseSadhana();
      return true;
    }
    return false;
  }

  Future<void> _confirmAbandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conclude Sadhana Early?'),
        content: const Text(
          'This session will be archived into your history as concluded early. '
          'Are you sure you want to end this practice now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Practicing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('Conclude Early'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.sadhanaState.abandonSadhana();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showStepOverview() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final steps = widget.plan.steps;
        final currentIndex = widget.sadhanaState.currentSadhanaStepIndex;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sadhana Sequence Steps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                      ),
                    ),
                    Text(
                      '${steps.length} Steps Total',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: steps.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = steps[index];
                    final isCurrent = index == currentIndex;
                    final isDone = widget.sadhanaState.isSadhanaStepCompleted(s.id);
                    final isSkipped = widget.sadhanaState.isSadhanaStepSkipped(s.id);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isDone
                            ? Colors.green
                            : isCurrent
                                ? AppColors.saffronPrimary
                                : isDark
                                    ? AppColors.nightSurface
                                    : AppColors.chandanBorder,
                        foregroundColor: isDone || isCurrent ? Colors.white : Colors.grey,
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text('${index + 1}', style: const TextStyle(fontSize: 11)),
                      ),
                      title: Text(
                        s.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? (isDark ? AppColors.goldGlow : AppColors.saffronPrimary)
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        '${s.stepType.displayName}${s.isOptional ? " • Optional" : ""}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: isDone
                          ? const Icon(Icons.check_circle, size: 18, color: Colors.green)
                          : isSkipped
                              ? const Text('Skipped', style: TextStyle(fontSize: 10, color: Colors.grey))
                              : isCurrent
                                  ? const Text('Active', style: TextStyle(fontSize: 10, color: AppColors.saffronPrimary, fontWeight: FontWeight.bold))
                                  : null,
                      onTap: () {
                        widget.sadhanaState.goToSadhanaStep(index);
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

  Future<void> _launchIntegratedJapa(GuidedSadhanaStep step) async {
    final aState = widget.audioState;
    if (aState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio state not connected for Japa practice.')),
      );
      return;
    }

    // Resolve mantra item
    final mRepo = widget.mantraRepository ?? MantraRepositoryImpl();
    MantraItem? mantra;
    if (step.linkedMantraId != null) {
      mantra = mRepo.getMantraById(step.linkedMantraId!);
    }
    mantra ??= mRepo.getAllMantras().isNotEmpty ? mRepo.getAllMantras().first : null;

    final targetRepetitions = step.targetRepetitions ?? 108;
    // Configure target if not currently matching
    if (aState.targetRepetitions != targetRepetitions && !aState.hasActiveOrPausedSession) {
      aState.setTargetRepetitions(targetRepetitions);
    }

    // Navigate to Phase 21A JapaPracticeScreen WITHOUT autoplay
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

    // After returning from Japa, inspect actual authenticated completion
    if (!mounted) return;
    final completedCount = aState.completedRepetitions;
    final isTargetReached = aState.hasReachedTarget || completedCount >= targetRepetitions;

    if (isTargetReached) {
      widget.sadhanaState.recordJapaCompletionForCurrentStep(
        aState.activeSession?.id ?? 'japa-${DateTime.now().millisecondsSinceEpoch}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('॥ जप पूर्णम् ॥ Japa target ($targetRepetitions chants) completed.'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Japa was not completed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Japa in progress: $completedCount of $targetRepetitions completed. '
            'Complete target to fulfill step.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = widget.sadhanaState.activeSadhanaSession;
    final isCompleted = session?.isCompleted ?? false;
    final currentStep = widget.sadhanaState.currentSadhanaStep;
    final currentIndex = widget.sadhanaState.currentSadhanaStepIndex;
    final totalSteps = widget.plan.steps.length;

    return PopScope(
      canPop: isCompleted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmPauseAndExit();
        if (shouldExit && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.plan.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Step Sequence Overview',
              onPressed: _showStepOverview,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Conclude Early',
              onPressed: _confirmAbandon,
            ),
          ],
        ),
        body: isCompleted
            ? _buildCompletionSummary(context, isDark)
            : currentStep == null
                ? const Center(child: Text('No active step found.'))
                : _buildStepView(context, currentStep, currentIndex, totalSteps, isDark),
      ),
    );
  }

  Widget _buildStepView(
    BuildContext context,
    GuidedSadhanaStep step,
    int index,
    int totalSteps,
    bool isDark,
  ) {
    final isDone = widget.sadhanaState.isSadhanaStepCompleted(step.id);
    final completedCount = widget.sadhanaState.activeSadhanaSession?.completedStepIds.length ?? 0;
    final progress = totalSteps > 0 ? (completedCount / totalSteps).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // Progress Indicator Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: isDark ? AppColors.nightSurface : AppColors.creamBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STEP ${index + 1} OF $totalSteps',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    ),
                  ),
                  Text(
                    '$completedCount of $totalSteps Completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? AppColors.nightBorder : const Color(0xFFE5DDCE),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.saffronPrimary),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Step Details
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Category Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.saffronPrimary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.saffronPrimary, width: 0.8),
                      ),
                      child: Text(
                        step.stepType.displayName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffronPrimary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (step.isOptional)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'OPTIONAL',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Step Title & Sanskrit Subtitle
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                  ),
                ),
                if (step.sanskritTitle != null && step.sanskritTitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.sanskritTitle!,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Devanagari',
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Step Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    ),
                  ),
                  child: Text(
                    step.description,
                    style: AppTextStyles.bodyMedium(isDark).copyWith(height: 1.45, fontSize: 13.5),
                  ),
                ),

                // Materials Info (if applicable)
                if (step.materials.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: step.materials.map((m) {
                      return Chip(
                        label: Text(m, style: const TextStyle(fontSize: 11)),
                        backgroundColor: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF3ECE0),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],

                // Liturgical Content (Sanskrit, Transliteration, Meaning, Source)
                if (step.sanskritMantra != null && step.sanskritMantra!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1711) : const Color(0xFFFFFBF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.goldDark.withAlpha(120) : AppColors.goldPrimary.withAlpha(100),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          step.sanskritMantra!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.6,
                            fontFamily: 'Devanagari',
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                          ),
                        ),
                        if (step.transliteration != null && step.transliteration!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            step.transliteration!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                            ),
                          ),
                        ],
                        if (step.meaning != null && step.meaning!.isNotEmpty) ...[
                          const Divider(height: 20),
                          Text(
                            step.meaning!,
                            style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 12.5, height: 1.4),
                          ),
                        ],
                        if (step.scripturalSource != null && step.scripturalSource!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Source: ${step.scripturalSource!}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.goldLight : AppColors.goldDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Dedicated Japa Practice Card
                if (step.stepType == SadhanaStepType.japa) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDone
                            ? Colors.green
                            : isDark
                                ? AppColors.nightBorder
                                : AppColors.chandanBorder,
                        width: isDone ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.fingerprint, color: AppColors.saffronPrimary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Japa Practice Integration',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (isDone)
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Target: ${step.targetRepetitions ?? 108} Chants • Classical Mala Count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.goldLight : AppColors.goldDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Japa Launch Button (Min 48dp touch target)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: ElevatedButton.icon(
                            icon: Icon(isDone ? Icons.refresh : Icons.play_arrow, size: 18),
                            label: Text(
                              isDone
                                  ? 'CHANT AGAIN (COMPLETED)'
                                  : 'BEGIN JAPA PRACTICE (${step.targetRepetitions ?? 108} CHANTS)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDone ? Colors.green.shade700 : AppColors.saffronPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _launchIntegratedJapa(step),
                          ),
                        ),
                        if (!isDone && widget.audioState != null && widget.audioState!.completedRepetitions > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Active Progress: ${widget.audioState!.completedRepetitions} of ${step.targetRepetitions ?? 108} chants completed.',
                            style: const TextStyle(fontSize: 11, color: Colors.amber, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              // Previous Step Button
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: OutlinedButton(
                  onPressed: index > 0 ? () => widget.sadhanaState.previousSadhanaStep() : null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 16),
                      SizedBox(width: 4),
                      Text('Prev', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Optional Skip Button
              if (step.isOptional && !isDone)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: TextButton(
                    onPressed: () => widget.sadhanaState.skipOptionalSadhanaStep(),
                    child: const Text('Skip (Optional)', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ),
                ),

              const Spacer(),

              // Complete / Next Step Button
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, minHeight: 48),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone ? Colors.green.shade700 : AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () {
                    if (!isDone) {
                      // If it's a required Japa step and not completed, prompt devotee
                      if (step.stepType == SadhanaStepType.japa) {
                        _launchIntegratedJapa(step);
                        return;
                      }
                      widget.sadhanaState.completeCurrentSadhanaStep();
                    } else {
                      // If already done, proceed to next step
                      widget.sadhanaState.nextSadhanaStep();
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        !isDone
                            ? (step.stepType == SadhanaStepType.japa
                                ? 'Chant Japa'
                                : 'Complete Step')
                            : (index == totalSteps - 1 ? 'Finish Sadhana' : 'Next Step'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        !isDone
                            ? (step.stepType == SadhanaStepType.japa ? Icons.fingerprint : Icons.check)
                            : (index == totalSteps - 1 ? Icons.stars : Icons.arrow_forward),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionSummary(BuildContext context, bool isDark) {
    final session = widget.sadhanaState.activeSadhanaSession;
    final totalSteps = widget.plan.steps.length;
    final completedSteps = session?.completedStepIds.length ?? totalSteps;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldPrimary.withAlpha(30),
                border: Border.all(color: AppColors.goldPrimary, width: 2),
              ),
              child: const Icon(Icons.temple_hindu, color: AppColors.goldPrimary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              '॥ साधना पूर्णम् ॥',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Devanagari',
                color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sadhana Completed with Steadfast Reverence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'May your sincere worship cultivate deep peace, clarity of intellect, '
              'and enduring auspiciousness throughout your day.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(isDark).copyWith(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sadhana Plan:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(widget.plan.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Steps Completed:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('$completedSteps of $totalSteps', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (session?.japaSessionId != null) ...[
                    const Divider(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Japa Integration:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('Verified Authentic Count', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Return Button (Min 48dp touch target)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, minHeight: 48),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Return to Daily Sadhana',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
