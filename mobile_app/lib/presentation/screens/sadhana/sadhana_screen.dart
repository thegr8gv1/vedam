import 'package:flutter/material.dart';
import '../../../core/models/puja_guide.dart';
import '../../../core/models/sadhana_practice.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/fixtures/authentic_puja_guides_data.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../state/app_state.dart';
import '../../../state/audio_state.dart';
import '../../../state/panchangam_state.dart';
import '../../../state/sadhana_state.dart';
import '../../../state/vrat_state.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/section_header.dart';

import 'package:vedam_app/presentation/screens/japa/widgets/japa_history_modal.dart';
import '../mantras/widgets/japa_target_modal.dart';
import '../vrat/reminders_settings_screen.dart';
import '../vrat/vrat_calendar_screen.dart';
import 'guided_puja_screen.dart';
import '../../../core/models/guided_sadhana.dart';
import '../../../data/fixtures/authentic_sadhana_plans_data.dart';
import 'guided_sadhana_screen.dart';
import 'widgets/sadhana_history_modal.dart';
import '../japa/japa_practice_screen.dart';
import 'widgets/customize_routine_modal.dart';
import 'widgets/puja_guide_overview_modal.dart';
import 'widgets/puja_history_modal.dart';

class SadhanaScreen extends StatefulWidget {
  final AppState appState;
  final SadhanaState? sadhanaState;
  final VratState? vratState;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;
  final PanchangamState? panchangamState;
  final VoidCallback? onOpenMantras;
  final VoidCallback? onOpenPanchangam;
  final VoidCallback? onOpenLibrary;

  const SadhanaScreen({
    super.key,
    required this.appState,
    this.sadhanaState,
    this.vratState,
    this.mantraRepository,
    this.audioState,
    this.panchangamState,
    this.onOpenMantras,
    this.onOpenPanchangam,
    this.onOpenLibrary,
  });

  @override
  State<SadhanaScreen> createState() => _SadhanaScreenState();
}

class _SadhanaScreenState extends State<SadhanaScreen> with WidgetsBindingObserver {
  late final SadhanaState _state;
  late final VratState _vratState;
  int _manualJapaCount = 0;
  final int _targetJapa = 108;

  int get _currentJapaCount {
    if (widget.audioState != null) {
      return widget.audioState!.completedRepetitions;
    }
    return _manualJapaCount;
  }

  int get _targetJapaCount {
    if (widget.audioState != null) {
      return widget.audioState!.targetRepetitions;
    }
    return _targetJapa;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = widget.sadhanaState ?? SadhanaState();
    _vratState = widget.vratState ?? VratState();
    _state.addListener(_onStateChange);
    widget.audioState?.addListener(_onStateChange);
    _state.checkDateRollOver();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.removeListener(_onStateChange);
    widget.audioState?.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _state.checkDateRollOver();
      if (mounted) setState(() {});
    }
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _incrementJapa() {
    if (widget.audioState != null) {
      widget.audioState!.incrementManualRepetition();
    } else {
      setState(() {
        if (_manualJapaCount < _targetJapa) {
          _manualJapaCount++;
        }
      });
    }
  }

  void _resetManualJapa() {
    if (widget.audioState != null) {
      widget.audioState!.resetSession();
    } else {
      setState(() {
        _manualJapaCount = 0;
      });
    }
  }

  void _openGuide(PujaGuide guide) {
    PujaGuideOverviewModal.show(
      context: context,
      guide: guide,
      currentStepIndex: _state.activeGuide?.id == guide.id ? _state.activeGuideStepIndex : 0,
      onStart: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuidedPujaScreen(
              guide: guide,
              sadhanaState: _state,
              mantraRepository: widget.mantraRepository,
              audioState: widget.audioState,
            ),
          ),
        );
      },
    );
  }

  void _openGuidedSadhana(GuidedSadhanaPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedSadhanaScreen(
          plan: plan,
          sadhanaState: _state,
          audioState: widget.audioState,
          mantraRepository: widget.mantraRepository,
        ),
      ),
    );
  }

  void _openLinkedMantra(String mantraId) {
    final mRepo = widget.mantraRepository ?? MantraRepositoryImpl();
    final aState = widget.audioState;

    final mantra = mRepo.getMantraById(mantraId);
    if (mantra != null && aState != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JapaPracticeScreen(
            initialMantra: mantra,
            audioState: aState,
            mantraRepository: mRepo,
          ),
        ),
      );
    } else if (widget.onOpenMantras != null) {
      widget.onOpenMantras!();
    }
  }

  String _formatTodayDate(DateTime d) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final w = weekdays[d.weekday - 1];
    final m = months[d.month - 1];
    return '$w, ${d.day} $m ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routine = _state.activeRoutine;
    final todayStr = _formatTodayDate(_state.currentDate);

    return Scaffold(
      appBar: SacredAppBar(
        title: 'Daily Sadhana',
        subtitle: 'नित्य पूजा एवं साधना',
        showLogo: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.temple_hindu_outlined),
            tooltip: 'Puja Practice History',
            onPressed: () => PujaHistoryModal.show(context: context, sadhanaState: _state),
          ),
          IconButton(
            icon: const Icon(Icons.history_edu),
            tooltip: 'Sadhana Practice History',
            onPressed: () => SadhanaHistoryModal.show(context, _state),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Today's Date & Portals
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.goldPrimary),
                  const SizedBox(width: 8),
                  Text(
                    todayStr.toUpperCase(),
                    style: AppTextStyles.metadataTag(isDark).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Portals to Mantras & Panchangam
            if (widget.onOpenMantras != null || widget.onOpenPanchangam != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    if (widget.onOpenMantras != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onOpenMantras,
                          icon: const Icon(Icons.music_note, size: 16, color: AppColors.saffronPrimary),
                          label: const Text('Mantra Japa', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: AppColors.saffronPrimary.withAlpha(120)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    if (widget.onOpenMantras != null && widget.onOpenPanchangam != null)
                      const SizedBox(width: 10),
                    if (widget.onOpenPanchangam != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onOpenPanchangam,
                          icon: const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.goldPrimary),
                          label: const Text('Panchangam', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: AppColors.goldPrimary.withAlpha(120)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Active Guided Puja Banner (if in progress or paused)
            if (_state.hasActiveGuideSession && _state.activeGuide != null)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.saffronPrimary, width: 1.5),
                ),
                color: isDark ? const Color(0xFF2A1C10) : const Color(0xFFFFF6E6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.saffronPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ACTIVE GUIDED PUJA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3A2814) : const Color(0xFFF3E7D3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _state.isGuidePaused ? 'PAUSED' : 'IN PROGRESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _state.activeGuide!.title,
                        style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Step ${_state.activeGuideStepIndex + 1} of ${_state.activeGuide!.steps.length}: ${_state.currentGuideStep?.stepName ?? ""}',
                        style: AppTextStyles.caption(isDark),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GuidedPujaScreen(
                                      guide: _state.activeGuide!,
                                      sadhanaState: _state,
                                      mantraRepository: widget.mantraRepository,
                                      audioState: widget.audioState,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('RESUME PUJA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.saffronPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () => _state.abandonPujaSession(),
                            child: const Text('Abandon', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Active Guided Sadhana Banner (if in progress or paused)
            if (_state.hasActiveOrPausedSadhanaSession && _state.activeSadhanaPlan != null)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.saffronPrimary, width: 1.5),
                ),
                color: isDark ? const Color(0xFF2A1C10) : const Color(0xFFFFF6E6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.saffronPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ACTIVE GUIDED SADHANA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Step ${_state.currentSadhanaStepIndex + 1} of ${_state.totalSadhanaStepsCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _state.activeSadhanaPlan!.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('RESUME PRACTICE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.saffronPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _openGuidedSadhana(_state.activeSadhanaPlan!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _state.abandonSadhana(),
                            child: const Text('Conclude Early'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Daily Routine Overview Card (Zero Pressure, Devotional)
            Card(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.goldDark.withAlpha(100) : AppColors.goldPrimary.withAlpha(100),
                  width: 1.2,
                ),
              ),
              color: isDark ? const Color(0xFF261D13) : const Color(0xFFFFFBF2),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAILY PRACTICE OVERVIEW',
                          style: AppTextStyles.metadataTag(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                          ),
                        ),
                        Text(
                          '${_state.completedRoutineCount} of ${_state.totalRoutineCount} Completed',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _state.completionProgress,
                        backgroundColor: isDark ? AppColors.nightSurface : const Color(0xFFEFE8DB),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Perform each worship discipline with shraddha (steadfast reverence) and a calm presence. '
                      'True sadhana is measured by sincerity and devotion, free of pressure.',
                      style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),

            // 2b. Personal Vrat & Observances Portal Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.goldDark.withAlpha(120) : AppColors.goldPrimary.withAlpha(120),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.saffronPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'PERSONAL VRAT & OBSERVANCES',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, size: 20),
                          tooltip: 'Devotional Reminders',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RemindersSettingsScreen(
                                  vratState: _vratState,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Plan and track Ekadashi, Pradosham, Purnima, and custom personal fasts with transparent calendar conventions.',
                      style: AppTextStyles.caption(isDark),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_note, size: 18),
                        label: const Text('OPEN VRAT CALENDAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.saffronPrimary,
                          side: const BorderSide(color: AppColors.saffronPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VratCalendarScreen(
                                vratState: _vratState,
                                sadhanaState: _state,
                                mantraRepository: widget.mantraRepository,
                                audioState: widget.audioState,
                                panchangamState: widget.panchangamState,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. My Daily Routine Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY DAILY ROUTINE',
                    style: AppTextStyles.metadataTag(isDark).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => CustomizeRoutineModal.show(
                      context: context,
                      sadhanaState: _state,
                    ),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('CUSTOMIZE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.goldGlow : AppColors.goldDark,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            if (routine.isEmpty)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.self_improvement, size: 40, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text('Your routine is empty.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Add practices from the catalog below to structure your daily worship.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => CustomizeRoutineModal.show(context: context, sadhanaState: _state),
                          child: const Text('Add Practices'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...routine.map((practice) {
                final isDone = _state.isPracticeCompleted(practice.id);
                final guide = practice.pujaGuideId != null ? AuthenticPujaGuidesData.getGuideById(practice.pujaGuideId!) : null;
                final isGuideActive = _state.activeGuide?.id == practice.pujaGuideId && !_state.isGuideCompleted;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDone
                          ? Colors.green.withAlpha(120)
                          : isDark
                              ? AppColors.nightBorder
                              : AppColors.chandanBorder,
                      width: isDone ? 1.4 : 0.8,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Completion check button
                            InkWell(
                              key: Key('toggle_${practice.id}'),
                              onTap: () => _state.togglePracticeCompletion(practice.id),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDone ? Colors.green : Colors.transparent,
                                  border: Border.all(
                                    color: isDone ? Colors.green : Colors.grey,
                                    width: 1.8,
                                  ),
                                ),
                                child: isDone
                                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    practice.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                      color: isDone ? Colors.grey : null,
                                    ),
                                  ),
                                  Text(
                                    '${practice.category.displayName} • ~${practice.estimatedMinutes} mins',
                                    style: AppTextStyles.caption(isDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (practice.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            practice.description,
                            style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Action row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (guide != null) ...[
                              OutlinedButton.icon(
                                onPressed: () => _openGuide(guide),
                                icon: Icon(
                                  isGuideActive ? Icons.play_arrow : Icons.temple_hindu,
                                  size: 15,
                                  color: AppColors.saffronPrimary,
                                ),
                                label: Text(
                                  isGuideActive ? 'RESUME GUIDE' : 'BEGIN GUIDE',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  side: const BorderSide(color: AppColors.saffronPrimary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (practice.linkedMantraId != null) ...[
                              OutlinedButton.icon(
                                onPressed: () => _openLinkedMantra(practice.linkedMantraId!),
                                icon: const Icon(Icons.music_note, size: 15, color: AppColors.goldPrimary),
                                label: const Text('CHANT JAPA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  side: const BorderSide(color: AppColors.goldPrimary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (practice.category == SadhanaCategory.scriptureReading && widget.onOpenLibrary != null)
                              OutlinedButton.icon(
                                onPressed: widget.onOpenLibrary,
                                icon: const Icon(Icons.menu_book, size: 15, color: AppColors.goldPrimary),
                                label: const Text('READ SCRIPTURE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  side: const BorderSide(color: AppColors.goldPrimary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // 3b. Guided Sadhana Practice Flows Section
            SectionHeader(
              title: 'Guided Sadhana Practice Flows',
              subtitle: 'Structured traditional sequences integrated with daily Japa',
            ),

            ...AuthenticSadhanaPlansData.allPlans.map((plan) {
              final isThisActive = _state.activeSadhanaPlan?.id == plan.id && _state.hasActiveOrPausedSadhanaSession;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isThisActive
                        ? AppColors.saffronPrimary
                        : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                    width: isThisActive ? 1.5 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF332312) : const Color(0xFFF7EEDD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plan.category.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                              ),
                            ),
                          ),
                          Text(
                            '~${plan.estimatedMinutes} mins • ${plan.steps.length} Steps',
                            style: AppTextStyles.caption(isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan.title,
                        style: AppTextStyles.titleSmall(isDark).copyWith(fontSize: 15),
                      ),
                      if (plan.sanskritTitle.isNotEmpty)
                        Text(
                          plan.sanskritTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Devanagari',
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        plan.shortDescription,
                        style: AppTextStyles.bodySmall(isDark),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          icon: Icon(isThisActive ? Icons.play_arrow : Icons.self_improvement, size: 16),
                          label: Text(
                            isThisActive ? 'RESUME PRACTICE' : 'BEGIN GUIDED PRACTICE',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isThisActive ? Colors.green.shade700 : AppColors.saffronPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openGuidedSadhana(plan),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // 4. Guided Puja Catalog Section
            SectionHeader(
              title: 'Guided Puja Catalog',
              subtitle: 'Structured step-by-step traditional domestic worship',
            ),

            ...AuthenticPujaGuidesData.allGuides.map((guide) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: InkWell(
                  onTap: () => _openGuide(guide),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF332312) : const Color(0xFFF7EEDD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                guide.deity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                                ),
                              ),
                            ),
                            Text(
                              '~${guide.estimatedDurationMinutes} mins • ${guide.steps.length} Steps',
                              style: AppTextStyles.caption(isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          guide.title,
                          style: AppTextStyles.titleSmall(isDark).copyWith(fontSize: 15),
                        ),
                        if (guide.sanskritTitle.isNotEmpty)
                          Text(
                            guide.sanskritTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          guide.shortIntro,
                          style: AppTextStyles.bodySmall(isDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_outlined, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  guide.editorialStatus,
                                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Row(
                              children: [
                                Text(
                                  'VIEW DETAILS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.saffronPrimary),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.saffronPrimary),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // 5. Digital Japa Mala Counter Card (Preserved from Phase 13B)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isDark ? AppColors.goldDark.withAlpha(120) : AppColors.goldPrimary.withAlpha(120),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle_outlined, size: 16, color: AppColors.saffronPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'MANUAL JAPA MALA COUNTER',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (widget.audioState != null)
                              IconButton(
                                icon: const Icon(Icons.history, size: 20),
                                tooltip: 'Chanting History',
                                onPressed: () => JapaHistoryModal.show(context, widget.audioState!),
                              ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              tooltip: 'Reset Counter',
                              onPressed: _resetManualJapa,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_currentJapaCount',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: widget.audioState != null
                          ? () => JapaTargetModal.show(context, widget.audioState!)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Target: $_targetJapaCount Repetitions',
                              style: AppTextStyles.caption(isDark).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.audioState != null) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 12, color: AppColors.saffronPrimary),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _targetJapaCount > 0 ? (_currentJapaCount / _targetJapaCount).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF0EAE1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.saffronPrimary),
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.fingerprint),
                        label: const Text(
                          'CHANT & COUNT BEAD',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _incrementJapa,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
