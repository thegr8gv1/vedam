import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/devotional_journal_entry.dart';
import 'package:vedam_app/core/models/orchestrator_session.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/practice_sequence.dart';
import 'package:vedam_app/core/services/practice_orchestrator_service.dart';
import 'package:vedam_app/state/orchestrator_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PracticeSequence Models and Serialization', () {
    test('Default Morning Sequence has valid initial steps and positive duration', () {
      final morning = PracticeSequence.defaultMorning();
      expect(morning.id, equals('seq_morning_default'));
      expect(morning.type, equals(PracticeSequenceType.morning));
      expect(morning.steps.length, greaterThanOrEqualTo(4));
      expect(morning.totalEstimatedMinutes, greaterThan(0));
      expect(morning.enabledStepCount, equals(morning.steps.length));

      // First step should be Sankalpa
      expect(morning.steps.first.stepType, equals(PracticeStepType.sankalpa));
    });

    test('Default Evening Sequence has valid initial steps and positive duration', () {
      final evening = PracticeSequence.defaultEvening();
      expect(evening.id, equals('seq_evening_default'));
      expect(evening.type, equals(PracticeSequenceType.evening));
      expect(evening.steps.length, greaterThanOrEqualTo(3));
      expect(evening.totalEstimatedMinutes, greaterThan(0));
    });

    test('PracticeSequence JSON roundtrip preserves all fields', () {
      final morning = PracticeSequence.defaultMorning();
      final json = morning.toJson();
      final restored = PracticeSequence.fromJson(json);

      expect(restored.id, equals(morning.id));
      expect(restored.name, equals(morning.name));
      expect(restored.type, equals(morning.type));
      expect(restored.steps.length, equals(morning.steps.length));
      expect(restored.steps[0].title, equals(morning.steps[0].title));
      expect(restored.steps[0].stepType, equals(morning.steps[0].stepType));
      expect(restored.steps[0].estimatedMinutes, equals(morning.steps[0].estimatedMinutes));
      expect(restored.steps[0].isOptional, equals(morning.steps[0].isOptional));
    });

    test('OrchestratorSession JSON roundtrip preserves all fields', () {
      final session = OrchestratorSession(
        sessionId: 'test_session_1',
        sequenceId: 'morning_sadhana',
        sequenceName: 'Morning Sadhana',
        startedAt: DateTime(2026, 11, 10, 6, 30),
        lastUpdatedAt: DateTime(2026, 11, 10, 6, 45),
        completedAt: DateTime(2026, 11, 10, 7, 0),
        currentStepIndex: 2,
        stepStatuses: {
          '0': StepExecutionStatus.completed,
          '1': StepExecutionStatus.skipped,
          '2': StepExecutionStatus.inProgress,
        },
        isPaused: true,
        isCompleted: false,
        isAbandoned: false,
      );

      final json = session.toJson();
      final restored = OrchestratorSession.fromJson(json);

      expect(restored.sessionId, equals(session.sessionId));
      expect(restored.sequenceId, equals(session.sequenceId));
      expect(restored.currentStepIndex, equals(session.currentStepIndex));
      expect(restored.isPaused, isTrue);
      expect(restored.isCompleted, isFalse);
      expect(restored.isAbandoned, isFalse);
      expect(restored.stepStatuses['0'], equals(StepExecutionStatus.completed));
      expect(restored.stepStatuses['1'], equals(StepExecutionStatus.skipped));
      expect(restored.stepStatuses['2'], equals(StepExecutionStatus.inProgress));
    });

    test('DevotionalJournalEntry JSON roundtrip preserves all fields', () {
      final entry = DevotionalJournalEntry(
        id: 'journal_1',
        sessionId: 'sess_1',
        sequenceId: 'morning_sadhana',
        sequenceName: 'Morning Sadhana',
        localDate: '2026-11-10',
        completedAt: DateTime(2026, 11, 10, 7, 15),
        completedStepCount: 4,
        totalStepCount: 5,
        completedStepTitles: ['Vedic Sankalpa', 'Mantra Japa', 'Scripture Reading'],
        durationMinutes: 25,
      );

      final json = entry.toJson();
      final restored = DevotionalJournalEntry.fromJson(json);

      expect(restored.id, equals(entry.id));
      expect(restored.localDate, equals('2026-11-10'));
      expect(restored.completedStepCount, equals(4));
      expect(restored.totalStepCount, equals(5));
      expect(restored.durationMinutes, equals(25));
      expect(restored.completedStepTitles.length, equals(3));
    });
  });

  group('PracticeOrchestratorService CRUD & Storage', () {
    late PracticeOrchestratorService service;

    setUp(() {
      service = PracticeOrchestratorService();
    });

    test('loadSequences seeds default morning and evening sequences when empty', () async {
      final sequences = await service.loadSequences();
      expect(sequences.length, equals(2));
      expect(sequences.any((s) => s.type == PracticeSequenceType.morning), isTrue);
      expect(sequences.any((s) => s.type == PracticeSequenceType.evening), isTrue);
    });

    test('saveSequence adds and updates sequence', () async {
      final custom = PracticeSequence(
        id: 'custom_1',
        name: 'My Custom Practice',
        type: PracticeSequenceType.custom,
        steps: [
          const PracticeStep(
            id: 's1',
            title: 'Chanting',
            description: 'Chant mantras',
            stepType: PracticeStepType.japa,
            estimatedMinutes: 10,
          ),
        ],
      );

      await service.saveSequence(custom);
      final list = await service.loadSequences();
      expect(list.length, equals(3));
      expect(list.any((s) => s.id == 'custom_1'), isTrue);

      // Update name
      final updated = custom.copyWith(name: 'Updated Practice');
      await service.saveSequence(updated);
      final listAfterUpdate = await service.loadSequences();
      expect(listAfterUpdate.length, equals(3));
      expect(listAfterUpdate.firstWhere((s) => s.id == 'custom_1').name, equals('Updated Practice'));
    });

    test('deleteSequence removes target sequence', () async {
      final custom = PracticeSequence(
        id: 'to_delete',
        name: 'Temporary',
        type: PracticeSequenceType.custom,
        steps: [],
      );
      await service.saveSequence(custom);
      expect((await service.loadSequences()).length, equals(3));

      await service.deleteSequence('to_delete');
      final remaining = await service.loadSequences();
      expect(remaining.length, equals(2));
      expect(remaining.any((s) => s.id == 'to_delete'), isFalse);
    });

    test('active session save, load, and clear lifecycle', () async {
      expect(await service.loadActiveSession(), isNull);

      final session = OrchestratorSession(
        sessionId: 'active_1',
        sequenceId: 'morning_sadhana',
        sequenceName: 'Morning Sadhana',
        startedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        currentStepIndex: 1,
        stepStatuses: {'0': StepExecutionStatus.completed, '1': StepExecutionStatus.inProgress},
        isPaused: true,
        isCompleted: false,
        isAbandoned: false,
      );

      await service.saveActiveSession(session);
      final loaded = await service.loadActiveSession();
      expect(loaded, isNotNull);
      expect(loaded!.sessionId, equals('active_1'));
      expect(loaded.isPaused, isTrue);

      await service.clearActiveSession();
      expect(await service.loadActiveSession(), isNull);
    });
  });

  group('Devotional Streak Calculation & Journal Invariants', () {
    late PracticeOrchestratorService service;

    setUp(() {
      service = PracticeOrchestratorService();
    });

    test('Empty journal yields zero streak and zero practice days', () {
      final streak = service.calculateStreak(<DevotionalJournalEntry>[], now: DateTime(2026, 11, 10));
      expect(streak.currentStreak, equals(0));
      expect(streak.longestStreak, equals(0));
      expect(streak.totalPracticeDays, equals(0));
      expect(streak.lastPracticeDate, isNull);
    });

    test('Single practice today yields 1 day streak', () {
      final entries = [
        DevotionalJournalEntry(
          id: '1',
          sessionId: 's1',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 20,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.currentStreak, equals(1));
      expect(streak.longestStreak, equals(1));
      expect(streak.totalPracticeDays, equals(1));
      expect(streak.lastPracticeDate, equals(DateTime(2026, 11, 10)));
    });

    test('Multiple practices on SAME calendar day count as ONE practice day (no inflation)', () {
      final entries = [
        DevotionalJournalEntry(
          id: '1',
          sessionId: 's1',
          sequenceId: 'm',
          sequenceName: 'Morning Sadhana',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 7, 0),
          completedStepCount: 4,
          totalStepCount: 4,
          durationMinutes: 20,
        ),
        DevotionalJournalEntry(
          id: '2',
          sessionId: 's2',
          sequenceId: 'e',
          sequenceName: 'Evening Sadhana',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 19, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.currentStreak, equals(1)); // NOT 2!
      expect(streak.longestStreak, equals(1));
      expect(streak.totalPracticeDays, equals(1)); // Distinct day count
    });

    test('Consecutive daily practices increment streak correctly', () {
      final entries = [
        DevotionalJournalEntry(
          id: '3',
          sessionId: 's3',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
        DevotionalJournalEntry(
          id: '2',
          sessionId: 's2',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-09',
          completedAt: DateTime(2026, 11, 9, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
        DevotionalJournalEntry(
          id: '1',
          sessionId: 's1',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-08',
          completedAt: DateTime(2026, 11, 8, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.currentStreak, equals(3));
      expect(streak.longestStreak, equals(3));
      expect(streak.totalPracticeDays, equals(3));
    });

    test('Missed calendar day breaks current streak but preserves longest streak', () {
      final entries = [
        // Today
        DevotionalJournalEntry(
          id: '4',
          sessionId: 's4',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
        // Missed Nov 9! Past run: Nov 6, 7, 8 (3 days)
        DevotionalJournalEntry(
          id: '3',
          sessionId: 's3',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-08',
          completedAt: DateTime(2026, 11, 8, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
        DevotionalJournalEntry(
          id: '2',
          sessionId: 's2',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-07',
          completedAt: DateTime(2026, 11, 7, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
        DevotionalJournalEntry(
          id: '1',
          sessionId: 's1',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-06',
          completedAt: DateTime(2026, 11, 6, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.currentStreak, equals(1)); // Reset after missed Nov 9
      expect(streak.longestStreak, equals(3)); // Nov 6-8 retained
      expect(streak.totalPracticeDays, equals(4));
    });

    test('Practice yesterday without practice yet today maintains streak as alive', () {
      final entries = [
        DevotionalJournalEntry(
          id: '1',
          sessionId: 's1',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-09',
          completedAt: DateTime(2026, 11, 9, 7, 0),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
      ];

      // It's midday Nov 10, devotee hasn't practiced yet today
      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10, 14, 0));
      expect(streak.currentStreak, equals(1)); // Still valid today until tomorrow
      expect(streak.totalPracticeDays, equals(1));
    });

    test('clearJournal wipes journal without throwing', () async {
      final session = OrchestratorSession(
        sessionId: 'sess_done',
        sequenceId: 'morning_sadhana',
        sequenceName: 'Morning Sadhana',
        startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        lastUpdatedAt: DateTime.now(),
        completedAt: DateTime.now(),
        currentStepIndex: 3,
        stepStatuses: {'0': StepExecutionStatus.completed, '1': StepExecutionStatus.completed},
        isPaused: false,
        isCompleted: true,
        isAbandoned: false,
      );

      await service.recordCompletedSession(
        session: session,
        sequence: PracticeSequence.defaultMorning(),
      );

      expect((await service.loadJournalEntries()).length, equals(1));
      await service.clearJournal();
      expect((await service.loadJournalEntries()).isEmpty, isTrue);
    });
  });

  group('Panchangam Recommendations & Dismissal', () {
    late PracticeOrchestratorService service;

    setUp(() {
      service = PracticeOrchestratorService();
    });

    test('Generates live recommendation when Panchangam data provided', () async {
      final panchangam = DailyPanchangamData(
        calculationTimestampUtc: DateTime(2026, 11, 10, 6, 0),
        requestedDate: DateTime(2026, 11, 10),
        location: PanchangamLocation.varanasi,
        vara: const PanchaAngaElement(number: 1, name: 'Somavara', sanskritName: 'सोमवासर', meaning: 'Monday'),
        sunMoon: const SunMoonEvents(
          sunriseFormatted: '06:12 AM',
          sunsetFormatted: '05:30 PM',
          dayLengthHours: 11.3,
          dayLengthFormatted: '11h 18m',
          moonIlluminationPercent: 50.0,
        ),
        tithi: const PanchaAngaElement(number: 11, name: 'Ekadashi', sanskritName: 'एकादशी', meaning: '11th Lunar Day'),
        nakshatra: const PanchaAngaElement(number: 8, name: 'Pushya', sanskritName: 'पुष्य', meaning: 'Nourishing'),
        yoga: const PanchaAngaElement(number: 1, name: 'Siddha', sanskritName: 'सिद्ध', meaning: 'Accomplished'),
        karana: const PanchaAngaElement(number: 1, name: 'Bava', sanskritName: 'बव', meaning: 'Auspicious'),
        paksha: 'Shukla Paksha',
        rahuKalam: TimePeriod(
          name: 'Rahu Kalam',
          sanskritName: 'राहुकाल',
          formatted: '07:30 AM - 09:00 AM',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          isAuspicious: false,
          description: 'Inauspicious',
        ),
        yamagandam: TimePeriod(
          name: 'Yamagandam',
          sanskritName: 'यमगण्ड',
          formatted: '10:30 AM - 12:00 PM',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          isAuspicious: false,
          description: 'Inauspicious',
        ),
        gulikaKalam: TimePeriod(
          name: 'Gulika Kalam',
          sanskritName: 'गुलिक काल',
          formatted: '01:30 PM - 03:00 PM',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          isAuspicious: true,
          description: 'Auspicious',
        ),
        observances: const [
          Observance(
            name: 'Utpanna Ekadashi',
            sanskritName: 'उत्पन्ना एकादशी',
            category: 'Vrat',
            description: 'Sacred fast dedicated to Lord Vishnu and spiritual purification.',
          ),
        ],
        conventions: const CalculationConventions(
          ayanamsaUsed: 'Lahiri',
          ayanamsaValueDegrees: 24.1,
          ayanamsaValueFormatted: '24° 06\' 00"',
          ephemerisEngine: 'Swiss Ephemeris',
          coordinateSystem: 'Geocentric',
          sunriseConvention: 'Geometric Center',
          timeScale: 'UTC',
          udayaTithiRule: 'Standard Sunrise',
        ),
      );

      final rec = await service.getRecommendation(panchangam: panchangam);
      expect(rec, isNotNull);
      expect(rec!.isOfflineFallback, isFalse);
      expect(rec.title, contains('Utpanna Ekadashi'));
      expect(rec.description, contains('Vishnu'));
    });

    test('Falls back to conservative offline recommendation when panchangam is null', () async {
      final rec = await service.getRecommendation(panchangam: null);
      expect(rec, isNotNull);
      expect(rec!.isOfflineFallback, isTrue);
      expect(rec.suggestedPractice.isNotEmpty, isTrue);
    });

    test('Dismissing recommendation suppresses it for the remainder of that day', () async {
      final recBefore = await service.getRecommendation();
      expect(recBefore, isNotNull);

      await service.dismissRecommendation();

      final recAfter = await service.getRecommendation();
      expect(recAfter, isNull);
    });
  });

  group('OrchestratorState State Management Flow', () {
    test('State initializes and manages step-by-step practice session', () async {
      final state = OrchestratorState();
      // Allow async _init to settle
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(state.isLoading, isFalse);
      expect(state.sequences.length, equals(2));
      expect(state.hasActiveSession, isFalse);

      final morning = state.morningSequence!;
      final session = await state.startSequence(morning);

      expect(state.hasActiveSession, isTrue);
      expect(state.activeSession?.sessionId, equals(session.sessionId));
      expect(state.activeSession?.currentStepIndex, equals(0));

      // Advance step 0
      await state.completeStep(0, sequence: morning);
      expect(state.activeSession?.currentStepIndex, equals(1));
      expect(
        state.activeSession?.stepStatuses['0'],
        equals(StepExecutionStatus.completed),
      );

      // Pause session
      await state.pauseSession();
      expect(state.activeSession?.isPaused, isTrue);

      // Resume session
      await state.resumeSession();
      expect(state.activeSession?.isPaused, isFalse);

      // Skip step 1 (if optional)
      await state.skipStep(1, sequence: morning);
      expect(state.activeSession?.currentStepIndex, equals(2));
      expect(
        state.activeSession?.stepStatuses['1'],
        equals(StepExecutionStatus.skipped),
      );

      // Complete remaining steps until sequence concludes
      for (int i = 2; i < morning.steps.length; i++) {
        await state.completeStep(i, sequence: morning);
      }

      // Session should now be concluded, cleared, and recorded into journal
      expect(state.hasActiveSession, isFalse);
      expect(state.journalEntries.length, equals(1));
      expect(state.journalEntries.first.sequenceId, equals(morning.id));
      expect(state.streakReport.currentStreak, equals(1));
    });

    test('Abandoning session does not record incomplete practice to journal', () async {
      final state = OrchestratorState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final evening = state.eveningSequence!;
      await state.startSequence(evening);
      expect(state.hasActiveSession, isTrue);

      // Abandon immediately
      await state.abandonSession();
      expect(state.hasActiveSession, isFalse);
      expect(state.journalEntries.isEmpty, isTrue);
      expect(state.streakReport.totalPracticeDays, equals(0));
    });
  });
}
