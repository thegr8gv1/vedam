import 'package:flutter/material.dart';
import '../../../core/models/festival_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/fixtures/authentic_festival_catalog_data.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../data/repositories/panchangam_repository.dart';
import '../../../state/audio_state.dart';
import '../../../state/panchangam_state.dart';
import '../../../state/sadhana_state.dart';
import '../../../state/vrat_state.dart';
import '../panchangam/panchangam_screen.dart';
import 'festival_detail_screen.dart';

/// Dedicated Hindu Festival & Regional Observance Calendar screen.
///
/// Features:
/// - Interactive monthly calendar grid with month navigation and "Today" shortcut.
/// - Clear event badges and multiple-observance indicators per calendar cell.
/// - Category filtering (Major Festivals, Ekadashi, Pradosham, Purnima/Amavasya, Sankashti, Regional).
/// - Location-aware presentation respecting devotee's configured Panchangam location.
/// - Selected-day event inspection and chronological upcoming holy days.
/// - Seamless integration with personal Vrat tracking and related Puja/Mantra practices.
/// - Fully responsive single-column (<700dp) and dual-column ($\ge 700$dp) layouts.
class FestivalCalendarScreen extends StatefulWidget {
  final VratState vratState;
  final PanchangamState? panchangamState;
  final PanchangamRepository? panchangamRepository;
  final SadhanaState? sadhanaState;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;
  final DateTime? initialDate;

  const FestivalCalendarScreen({
    super.key,
    required this.vratState,
    this.panchangamState,
    this.panchangamRepository,
    this.sadhanaState,
    this.mantraRepository,
    this.audioState,
    this.initialDate,
  });

  @override
  State<FestivalCalendarScreen> createState() => _FestivalCalendarScreenState();
}

class _FestivalCalendarScreenState extends State<FestivalCalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  FestivalCategory? _selectedCategory;

  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _weekdays = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    widget.vratState.addListener(_onVratStateChanged);
  }

  @override
  void dispose() {
    widget.vratState.removeListener(_onVratStateChanged);
    super.dispose();
  }

  void _onVratStateChanged() {
    if (mounted) setState(() {});
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  String _formatDateString(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Color _getCategoryColor(FestivalCategory cat) {
    switch (cat) {
      case FestivalCategory.majorFestival:
        return AppColors.saffronPrimary;
      case FestivalCategory.ekadashi:
        return Colors.indigo;
      case FestivalCategory.pradosham:
        return Colors.deepPurple;
      case FestivalCategory.purnima:
        return Colors.amber.shade700;
      case FestivalCategory.amavasya:
        return Colors.blueGrey;
      case FestivalCategory.sankashtiChaturthi:
        return Colors.deepOrange;
      case FestivalCategory.regionalObservance:
        return Colors.teal;
    }
  }

  bool _isEventInPersonalVrat(FestivalEvent event) {
    final targetId = 'vrat_${event.id}';
    return widget.vratState.observances.any(
      (o) => o.id == targetId || (o.title == event.name && o.targetDate == event.targetDate),
    );
  }

  void _openEventDetail(FestivalEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FestivalDetailScreen(
          event: event,
          vratState: widget.vratState,
          panchangamState: widget.panchangamState,
          sadhanaState: widget.sadhanaState,
          mantraRepository: widget.mantraRepository,
          audioState: widget.audioState,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openLocationSettings() {
    if (widget.panchangamState == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PanchangamScreen(
          state: widget.panchangamState!,
          repository: widget.panchangamRepository ??
              PanchangamRepositoryImpl(),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;
    final locationName = widget.panchangamState?.selectedLocation.name ??
        'Varanasi (Kashi), India';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Festival & Observance Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Configure Location',
            onPressed: _openLocationSettings,
          ),
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today, size: 16),
            label: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Location and Calculation Convention Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppColors.nightSurface : const Color(0xFFFBF8F2),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.saffronPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$locationName • Drik Ganita Ephemeris',
                      style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _openLocationSettings,
                    child: Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  _buildCategoryChip('All Categories', null, isDark),
                  _buildCategoryChip('Major Festivals', FestivalCategory.majorFestival, isDark),
                  _buildCategoryChip('Ekadashi', FestivalCategory.ekadashi, isDark),
                  _buildCategoryChip('Pradosham', FestivalCategory.pradosham, isDark),
                  _buildCategoryChip('Purnima', FestivalCategory.purnima, isDark),
                  _buildCategoryChip('Amavasya', FestivalCategory.amavasya, isDark),
                  _buildCategoryChip('Sankashti', FestivalCategory.sankashtiChaturthi, isDark),
                  _buildCategoryChip('Regional', FestivalCategory.regionalObservance, isDark),
                ],
              ),
            ),
            const Divider(height: 1),

            // Main Content: Responsive Split for Web/Tablet vs Mobile
            Expanded(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Calendar Grid & Month Nav
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildCalendarView(isDark),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        // Right Column: Selected Events & Upcoming Holy Days
                        Expanded(
                          flex: 6,
                          child: _buildEventsListPane(isDark),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _buildCalendarView(isDark),
                        const SizedBox(height: 16),
                        _buildEventsListHeader(isDark),
                        const SizedBox(height: 8),
                        ..._buildEventsCardsList(isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, FestivalCategory? cat, bool isDark) {
    final isSelected = _selectedCategory == cat;
    final activeColor = cat != null ? _getCategoryColor(cat) : AppColors.saffronPrimary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        selectedColor: activeColor,
        checkmarkColor: Colors.white,
        backgroundColor: isDark ? AppColors.nightSurface : const Color(0xFFF3EFEA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onSelected: (_) {
          setState(() {
            _selectedCategory = cat;
          });
        },
      ),
    );
  }

  Widget _buildCalendarView(bool isDark) {
    final currentMonthYearStr = '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';
    final monthEvents = AuthenticFestivalCatalogData.getEventsForMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    ).where((e) => _selectedCategory == null || e.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Navigation Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Month',
              onPressed: _goToPreviousMonth,
            ),
            Flexible(
              child: Text(
                currentMonthYearStr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldGlow : AppColors.textDarkPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Month',
              onPressed: _goToNextMonth,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekdays.map((w) {
            return Expanded(
              child: Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: w == 'Sun' ? AppColors.saffronPrimary : (isDark ? Colors.grey : Colors.grey.shade700),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Calendar Grid
        _buildCalendarGrid(monthEvents, isDark),
      ],
    );
  }

  Widget _buildCalendarGrid(List<FestivalEvent> monthEvents, bool isDark) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // Sunday is 0 (Dart weekday: Monday=1...Sunday=7 -> % 7 makes Sunday 0)
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final totalCells = ((startingWeekday + daysInMonth + 6) ~/ 7) * 7;
    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - startingWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
        final cellDateStr = _formatDateString(cellDate);

        final dayEvents = monthEvents.where((e) => e.targetDate == cellDateStr).toList();
        final hasEvents = dayEvents.isNotEmpty;
        final hasMultiple = dayEvents.length > 1;

        final isToday = cellDate.year == now.year &&
            cellDate.month == now.month &&
            cellDate.day == now.day;

        final isSelected = cellDate.year == _selectedDate.year &&
            cellDate.month == _selectedDate.month &&
            cellDate.day == _selectedDate.day;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.saffronPrimary.withAlpha(isDark ? 80 : 40)
                  : (isToday
                      ? (isDark ? AppColors.nightSurface : const Color(0xFFFAF4EA))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.saffronPrimary
                    : (isToday
                        ? (isDark ? AppColors.goldGlow : AppColors.saffronDark)
                        : Colors.transparent),
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Day number
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                    color: isToday
                        ? AppColors.saffronPrimary
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 2),

                // Event indicator dots / badge
                if (hasEvents)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasMultiple) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.saffronPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${dayEvents.length}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(dayEvents.first.category),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsListPane(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEventsListHeader(isDark),
        const SizedBox(height: 12),
        ..._buildEventsCardsList(isDark),
      ],
    );
  }

  Widget _buildEventsListHeader(bool isDark) {
    final selStr = _formatDateString(_selectedDate);
    final selectedEvents = AuthenticFestivalCatalogData.getEventsForDate(selStr)
        .where((e) => _selectedCategory == null || e.category == _selectedCategory)
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedEvents.isNotEmpty
                    ? 'Observances on ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}'
                    : 'Upcoming in ${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldGlow : AppColors.textDarkPrimary,
                ),
              ),
              if (selectedEvents.isNotEmpty && selectedEvents.length > 1)
                Text(
                  '${selectedEvents.length} sacred observances coincide on this day',
                  style: AppTextStyles.caption(isDark).copyWith(color: AppColors.saffronPrimary),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEventsCardsList(bool isDark) {
    final selStr = _formatDateString(_selectedDate);
    var eventsToShow = AuthenticFestivalCatalogData.getEventsForDate(selStr)
        .where((e) => _selectedCategory == null || e.category == _selectedCategory)
        .toList();

    // If no events on selected date, show upcoming events for the focused month
    if (eventsToShow.isEmpty) {
      final monthEvents = AuthenticFestivalCatalogData.getEventsForMonth(
        _focusedMonth.year,
        _focusedMonth.month,
      ).where((e) => _selectedCategory == null || e.category == _selectedCategory).toList();

      eventsToShow = monthEvents.where((e) => e.targetDate.compareTo(selStr) >= 0).toList();
      if (eventsToShow.isEmpty) {
        eventsToShow = monthEvents;
      }
    }

    if (eventsToShow.isEmpty) {
      return [
        Card(
          elevation: 0,
          color: isDark ? AppColors.nightSurface : const Color(0xFFF9F6F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.event_available, size: 36, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    'No observances found in this category for ${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return eventsToShow.map((event) => _buildEventCard(event, isDark)).toList();
  }

  Widget _buildEventCard(FestivalEvent event, bool isDark) {
    final catColor = _getCategoryColor(event.category);
    final inVrat = _isEventInPersonalVrat(event);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: inVrat
              ? Colors.green.withAlpha(120)
              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
          width: inVrat ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openEventDetail(event),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: catColor.withAlpha(120), width: 0.8),
                        ),
                        child: Text(
                          event.category.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.targetDate,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (inVrat)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'IN MY VRAT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title and Sanskrit Title
              if (event.sanskritName.isNotEmpty)
                Text(
                  event.sanskritName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                  ),
                ),
              Text(
                event.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              // Coordinates snippet (Tithi, Deity, Timing Rule)
              Text(
                '${event.tithi} (${event.paksha}) • ${event.deity} • ${event.timingRule}',
                style: AppTextStyles.caption(isDark).copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),

              // Significance preview
              Text(
                event.significance,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 1.35, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              ),
              const SizedBox(height: 10),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('View Details', style: TextStyle(fontSize: 12)),
                    onPressed: () => _openEventDetail(event),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
