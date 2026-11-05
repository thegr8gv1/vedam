import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/models/vrat_observance.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../state/audio_state.dart';
import '../../../state/panchangam_state.dart';
import '../../../state/sadhana_state.dart';
import '../../../state/vrat_state.dart';
import 'add_edit_vrat_modal.dart';
import 'reminders_settings_screen.dart';
import 'vrat_detail_screen.dart';

class VratCalendarScreen extends StatefulWidget {
  final VratState vratState;
  final SadhanaState? sadhanaState;
  final PanchangamState? panchangamState;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;

  const VratCalendarScreen({
    super.key,
    required this.vratState,
    this.sadhanaState,
    this.panchangamState,
    this.mantraRepository,
    this.audioState,
  });

  @override
  State<VratCalendarScreen> createState() => _VratCalendarScreenState();
}

class _VratCalendarScreenState extends State<VratCalendarScreen> {
  VratType? _filterType;

  @override
  void initState() {
    super.initState();
    widget.vratState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.vratState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Color _getStatusColor(ObservanceStatus status) {
    switch (status) {
      case ObservanceStatus.planned:
        return Colors.blue;
      case ObservanceStatus.inProgress:
        return Colors.orange;
      case ObservanceStatus.completed:
        return Colors.green;
      case ObservanceStatus.skipped:
      case ObservanceStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ObservanceStatus status) {
    switch (status) {
      case ObservanceStatus.planned:
        return 'PLANNED';
      case ObservanceStatus.inProgress:
        return 'IN PROGRESS';
      case ObservanceStatus.completed:
        return 'COMPLETED';
      case ObservanceStatus.skipped:
        return 'SKIPPED';
      case ObservanceStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Widget _buildObservanceCard(
    BuildContext context,
    VratObservance obs,
    bool isDark,
  ) {
    final completedCount = obs.checklist.where((c) => c.isDone).length;
    final totalCount = obs.checklist.length;
    final statusColor = _getStatusColor(obs.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: obs.status == ObservanceStatus.completed
              ? Colors.green.withAlpha(120)
              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
          width: obs.status == ObservanceStatus.completed ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VratDetailScreen(
                observanceId: obs.id,
                vratState: widget.vratState,
                sadhanaState: widget.sadhanaState,
                mantraRepository: widget.mantraRepository,
                audioState: widget.audioState,
                panchangamState: widget.panchangamState,
              ),
            ),
          ).then((_) => setState(() {}));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Date & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.saffronPrimary),
                      const SizedBox(width: 6),
                      Text(
                        obs.targetDate,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withAlpha(120), width: 0.8),
                    ),
                    child: Text(
                      _getStatusLabel(obs.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title and Sanskrit Title
              if (obs.sanskritTitle.isNotEmpty)
                Text(
                  obs.sanskritTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.textDarkPrimary,
                  ),
                ),
              Text(
                obs.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              // Tradition & Convention
              Wrap(
                spacing: 6,
                children: [
                  Text(
                    '${obs.tradition} • ${obs.calendarConvention.name}',
                    style: AppTextStyles.caption(isDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Panchangam calculated snippet if available
              if (obs.panchangamSnapshot != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurface : const Color(0xFFF9F5EF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 12, color: AppColors.saffronPrimary),
                      const SizedBox(width: 5),
                      Text(
                        'Panchangam: ${obs.panchangamSnapshot!.tithiName} (${obs.panchangamSnapshot!.paksha})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Checklist progress
              if (totalCount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount of $totalCount preparation steps ready',
                      style: AppTextStyles.caption(isDark),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allObs = widget.vratState.observances;

    final filtered = _filterType == null
        ? allObs
        : allObs.where((o) => o.type == _filterType).toList();

    final activeList = filtered
        .where((o) =>
            o.status == ObservanceStatus.planned ||
            o.status == ObservanceStatus.inProgress)
        .toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    final pastList = filtered
        .where((o) =>
            o.status == ObservanceStatus.completed ||
            o.status == ObservanceStatus.skipped ||
            o.status == ObservanceStatus.cancelled)
        .toList()
      ..sort((a, b) => b.targetDate.compareTo(a.targetDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Vrat & Observances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Devotional Reminders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RemindersSettingsScreen(
                    vratState: widget.vratState,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.saffronPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Plan Observance', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          AddEditVratModal.show(
            context: context,
            vratState: widget.vratState,
            panchangamState: widget.panchangamState,
          );
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Non-authoritative Informational Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFFF9ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withAlpha(120),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppColors.saffronPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Personal Devotional Planner: Fasting rules, Parana times, and auspicious dates differ by sampradaya and regional lineage. This tool helps you organize your own practice without declaring universal mandates.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.amber[200] : const Color(0xFF7A4F01),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterType == null,
                    onSelected: (_) => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Ekadashi'),
                    selected: _filterType == VratType.ekadashi,
                    onSelected: (_) => setState(() => _filterType = VratType.ekadashi),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pradosham'),
                    selected: _filterType == VratType.pradosham,
                    onSelected: (_) => setState(() => _filterType = VratType.pradosham),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Purnima'),
                    selected: _filterType == VratType.purnima,
                    onSelected: (_) => setState(() => _filterType = VratType.purnima),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Amavasya'),
                    selected: _filterType == VratType.amavasya,
                    onSelected: (_) => setState(() => _filterType = VratType.amavasya),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Sankashti'),
                    selected: _filterType == VratType.sankashtiChaturthi,
                    onSelected: (_) => setState(() => _filterType = VratType.sankashtiChaturthi),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Custom'),
                    selected: _filterType == VratType.custom,
                    onSelected: (_) => setState(() => _filterType = VratType.custom),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Active & Upcoming Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'UPCOMING & ACTIVE OBSERVANCES (${activeList.length})',
                style: AppTextStyles.metadataTag(isDark),
              ),
            ),
            const SizedBox(height: 6),

            if (activeList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.event_note, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'No upcoming observances planned.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Plan Observance" below to add an Ekadashi, Pradosham, or custom spiritual practice.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(isDark),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activeList.map((obs) => _buildObservanceCard(context, obs, isDark)),

            const SizedBox(height: 20),

            // 4. Past Observances History
            if (pastList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'PAST DEVOTIONAL HISTORY (${pastList.length})',
                  style: AppTextStyles.metadataTag(isDark),
                ),
              ),
              const SizedBox(height: 6),
              ...pastList.map((obs) => _buildObservanceCard(context, obs, isDark)),
            ],

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}
