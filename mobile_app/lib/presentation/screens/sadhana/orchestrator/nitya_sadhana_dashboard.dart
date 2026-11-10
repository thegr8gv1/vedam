import 'package:flutter/material.dart';
import '../../../../core/models/practice_sequence.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/mantra_repository.dart';
import '../../../../state/app_state.dart';
import '../../../../state/audio_state.dart';
import '../../../../state/orchestrator_state.dart';
import '../../../../state/panchangam_state.dart';
import '../../../../state/sadhana_state.dart';
import '../../../../state/scripture_reader_state.dart';
import '../../../../state/vrat_state.dart';
import 'journal_history_modal.dart';
import 'sequence_editor_modal.dart';
import 'sequence_execution_modal.dart';

/// The central Nitya Sadhana Dashboard widget.
/// Orchestrates morning, evening, and custom devotional flows, provides
/// active session continuity, gentle habit tracking, and conservative
/// Panchangam recommendations.
class NityaSadhanaDashboard extends StatefulWidget {
  final OrchestratorState orchestratorState;
  final AppState appState;
  final SadhanaState? sadhanaState;
  final AudioState? audioState;
  final PanchangamState? panchangamState;
  final VratState? vratState;
  final MantraRepository? mantraRepository;
  final ScriptureReaderState? scriptureReaderState;

  const NityaSadhanaDashboard({
    super.key,
    required this.orchestratorState,
    required this.appState,
    this.sadhanaState,
    this.audioState,
    this.panchangamState,
    this.vratState,
    this.mantraRepository,
    this.scriptureReaderState,
  });

  @override
  State<NityaSadhanaDashboard> createState() => _NityaSadhanaDashboardState();
}

class _NityaSadhanaDashboardState extends State<NityaSadhanaDashboard> {
  @override
  void initState() {
    super.initState();
    widget.orchestratorState.addListener(_onStateChange);
    // Trigger check for today's panchangam recommendation
    widget.orchestratorState.checkRecommendation(
      panchangam: widget.panchangamState?.data,
    );
  }

  @override
  void dispose() {
    widget.orchestratorState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _openExecutionModal(PracticeSequence sequence) {
    SequenceExecutionModal.show(
      context,
      orchestratorState: widget.orchestratorState,
      sequence: sequence,
      appState: widget.appState,
      sadhanaState: widget.sadhanaState,
      audioState: widget.audioState,
      panchangamState: widget.panchangamState,
      vratState: widget.vratState,
      mantraRepository: widget.mantraRepository,
      scriptureReaderState: widget.scriptureReaderState,
    );
  }

  void _openEditorModal(PracticeSequence sequence) {
    SequenceEditorModal.show(
      context,
      orchestratorState: widget.orchestratorState,
      sequence: sequence,
    );
  }

  void _openJournalModal() {
    JournalHistoryModal.show(
      context,
      widget.orchestratorState,
    );
  }

  Future<void> _createCustomSequence() async {
    final titleController = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Custom Sequence'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Sequence Name',
            hintText: 'e.g., Shiva Aradhana, Weekend Sadhana',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, titleController.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != null && created.isNotEmpty) {
      final newSeq = PracticeSequence(
        id: 'seq_${DateTime.now().millisecondsSinceEpoch}',
        name: created,
        type: PracticeSequenceType.custom,
        steps: [
          const PracticeStep(
            id: 'step_sankalpa',
            title: 'Vedic Sankalpa',
            description: 'Begin with sacred daily intention and lineage alignment.',
            stepType: PracticeStepType.sankalpa,
            estimatedMinutes: 3,
            isOptional: false,
          ),
          const PracticeStep(
            id: 'step_japa',
            title: 'Mantra Japa',
            description: 'Silent or counted meditative chanting.',
            stepType: PracticeStepType.japa,
            targetRepetitions: 108,
            estimatedMinutes: 10,
            isOptional: false,
          ),
          const PracticeStep(
            id: 'step_dhyana',
            title: 'Quiet Reflection',
            description: 'Sit in stillness and absorb the divine contemplation.',
            stepType: PracticeStepType.personalContemplation,
            estimatedMinutes: 5,
            isOptional: true,
          ),
        ],
      );

      await widget.orchestratorState.saveSequence(newSeq);
      if (mounted) {
        _openEditorModal(newSeq);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = widget.orchestratorState;
    final morningSeq = state.morningSequence ?? PracticeSequence.defaultMorning();
    final eveningSeq = state.eveningSequence ?? PracticeSequence.defaultEvening();
    final customSeqs = state.customSequences;
    final activeSession = state.activeSession;
    final recommendation = state.currentRecommendation;
    final streak = state.streakReport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.hub_outlined, color: AppColors.goldPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Nitya Sadhana Flow',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.history_edu, size: 18),
                label: const Text('Journal', style: TextStyle(fontSize: 13)),
                onPressed: _openJournalModal,
              ),
            ],
          ),
        ),

        // Contextual Panchangam Recommendation Banner (Dismissible)
        if (recommendation != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232338) : const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.goldPrimary.withAlpha(102),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.goldPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recommendation.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: recommendation.isOfflineFallback
                                    ? Colors.grey.withAlpha(51)
                                    : Colors.green.withAlpha(38),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                recommendation.isOfflineFallback
                                    ? 'Offline Approximation'
                                    : 'Live Calculation',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: recommendation.isOfflineFallback ? Colors.grey : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${recommendation.suggestedPractice}: ${recommendation.reasoning}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: isDark ? Colors.white54 : Colors.black45,
                    tooltip: 'Dismiss for today',
                    onPressed: () => state.dismissRecommendation(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Active / Paused Practice Banner (if any)
        if (state.hasActiveSession && activeSession != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF382E1E), const Color(0xFF262016)]
                      : [const Color(0xFFFFF3D6), const Color(0xFFFFE8B0)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.goldPrimary, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_filled, color: AppColors.goldPrimary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Practice in Progress: ${activeSession.sequenceName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        activeSession.isPaused ? 'Paused' : 'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: activeSession.isPaused ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${activeSession.currentStepIndex + 1} • In progress',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Resume Practice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldPrimary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            final seq = state.activeSequence ?? morningSeq;
                            _openExecutionModal(seq);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => state.abandonSession(),
                        child: const Text('Discard', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Devotional Consistency & Streak Summary Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242436) : const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildConsistencyBadge(
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrangeAccent,
                  value: '${streak.currentStreak}',
                  label: streak.currentStreak == 1 ? 'Day Streak' : 'Days Streak',
                  theme: theme,
                ),
                Container(width: 1, height: 32, color: Colors.grey.withAlpha(51)),
                _buildConsistencyBadge(
                  icon: Icons.workspace_premium,
                  color: AppColors.goldPrimary,
                  value: '${streak.longestStreak}',
                  label: 'Best Streak',
                  theme: theme,
                ),
                Container(width: 1, height: 32, color: Colors.grey.withAlpha(51)),
                _buildConsistencyBadge(
                  icon: Icons.calendar_today_outlined,
                  color: Colors.blueAccent,
                  value: '${streak.totalPracticeDays}',
                  label: 'Practice Days',
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Sequences Section: Morning & Evening Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Morning Sadhana Card
              Expanded(
                child: _buildSequenceCard(
                  sequence: morningSeq,
                  icon: Icons.wb_sunny_outlined,
                  iconColor: Colors.amber,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              // Evening Sadhana Card
              Expanded(
                child: _buildSequenceCard(
                  sequence: eveningSeq,
                  icon: Icons.nights_stay_outlined,
                  iconColor: Colors.deepPurpleAccent,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),

        // Custom Sequences (if any)
        if (customSeqs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Custom Sequences',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          ...customSeqs.map((seq) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                elevation: 0,
                color: isDark ? const Color(0xFF262638) : const Color(0xFFF9F9FC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.self_improvement, color: AppColors.goldPrimary),
                  title: Text(seq.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    '${seq.enabledStepCount} steps • ~${seq.totalEstimatedMinutes} min',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune, size: 20),
                        tooltip: 'Customize',
                        onPressed: () => _openEditorModal(seq),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: AppColors.goldPrimary, size: 24),
                        tooltip: 'Start',
                        onPressed: () => _openExecutionModal(seq),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],

        // Create Custom Sequence Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Custom Sequence'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _createCustomSequence,
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencyBadge({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.textTheme.bodySmall?.color?.withAlpha(180),
          ),
        ),
      ],
    );
  }

  Widget _buildSequenceCard({
    required PracticeSequence sequence,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252538) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.tune, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Customize',
                onPressed: () => _openEditorModal(sequence),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sequence.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${sequence.enabledStepCount} steps • ~${sequence.totalEstimatedMinutes} min',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () => _openExecutionModal(sequence),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Start Practice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
