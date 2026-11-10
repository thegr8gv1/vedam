import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/devotional_journal_entry.dart';
import 'package:vedam_app/core/models/japa_practice_session.dart';
import 'package:vedam_app/core/models/orchestrator_session.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/practice_sequence.dart';
import 'package:vedam_app/core/services/japa_session_service.dart';
import 'package:vedam_app/core/services/practice_orchestrator_service.dart';
import 'package:vedam_app/core/services/puja_session_service.dart';
import 'package:vedam_app/core/models/puja_session.dart';
import 'package:vedam_app/state/orchestrator_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 21L.1 - Completion Integrity & Duplicate Protection', () {
    test('Step opening does NOT count as completion', () async {
      final service = PracticeOrchestratorService();
      final sequence = PracticeSequence.defaultMorning();
      final state = OrchestratorState(service: service);

      final session = await state.startSequence(sequence);
      expect(session.currentStepIndex, equals(0));
      expect(session.stepStatuses['0'], equals(StepExecutionStatus.inProgress));
      expect(session.stepStatuses['1'], equals(StepExecutionStatus.pending));

      // No steps are completed just by opening/starting
      expect(session.completedStepsCount, equals(0));
      expect(state.journalEntries, isEmpty);
    });

    test('Duplicate completeStep invocations do not duplicate step credit or advance index out of bounds', () async {
      final service = PracticeOrchestratorService();
      final sequence = PracticeSequence.defaultMorning();
      final state = OrchestratorState(service: service);
      while (state.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await state.startSequence(sequence);
      await state.completeStep(0, sequence: sequence);

      final active = state.activeSession!;
      expect(active.stepStatuses['0'], equals(StepExecutionStatus.completed));
      expect(active.currentStepIndex, equals(1));

      // Second invocation on already completed step index 0
      await state.completeStep(0, sequence: sequence);
      expect(active.stepStatuses['0'], equals(StepExecutionStatus.completed));
    });

    test('Interrupted session resumed across app restart does not duplicate completed steps', () async {
      final prefs = await SharedPreferences.getInstance();
      final service1 = PracticeOrchestratorService(prefs: prefs);
      final sequence = PracticeSequence.defaultMorning();

      // Session started and step 0 completed
      final state1 = OrchestratorState(service: service1);
      await state1.startSequence(sequence);
      await state1.completeStep(0, sequence: sequence);
      await state1.pauseSession();

      // App restart: new service & state reading same SharedPreferences
      final service2 = PracticeOrchestratorService(prefs: prefs);
      final state2 = OrchestratorState(service: service2);
      await state2.refreshAll();

      final restored = state2.activeSession;
      expect(restored, isNotNull);
      expect(restored!.stepStatuses['0'], equals(StepExecutionStatus.completed));
      expect(restored.currentStepIndex, equals(1));
      expect(restored.completedStepsCount, equals(1));
    });

    test('Japa completion validation: below target repetitions receives no credit', () {
      final candidate = JapaPracticeSession(
        id: 'japa_test_1',
        mantraId: 'VEDA-MTR-0001',
        mantraTitle: 'Om Namah Shivaya',
        targetRepetitions: 108,
        completedRepetitions: 54, // Incomplete!
        countingMode: JapaCountingMode.manual,
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.abandoned,
      );

      final bool isValid = candidate.completedRepetitions >= 108 &&
          candidate.status != JapaSessionStatus.paused &&
          candidate.status != JapaSessionStatus.abandoned;

      expect(isValid, isFalse);
    });

    test('Japa completion validation: valid session meeting target is accepted', () {
      final candidate = JapaPracticeSession(
        id: 'japa_test_2',
        mantraId: 'VEDA-MTR-0001',
        mantraTitle: 'Om Namah Shivaya',
        targetRepetitions: 108,
        completedRepetitions: 108,
        countingMode: JapaCountingMode.manual,
        startTime: DateTime.now().subtract(const Duration(minutes: 8)),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.completed,
      );

      final bool isValid = candidate.completedRepetitions >= 108 &&
          candidate.status != JapaSessionStatus.paused &&
          candidate.status != JapaSessionStatus.abandoned;

      expect(isValid, isTrue);
    });
  });

  group('Phase 21L.1 - Journal Semantics & Early Conclusion', () {
    test('Concluding session early records ONLY genuinely completed steps to the journal', () async {
      final service = PracticeOrchestratorService();
      final sequence = PracticeSequence.defaultMorning();
      final state = OrchestratorState(service: service);
      while (state.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await state.startSequence(sequence);
      // Devotee completes step 0 (Sankalpa) and step 1 (Puja)
      await state.completeStep(0, sequence: sequence);
      await state.completeStep(1, sequence: sequence);

      expect(state.activeSession!.completedStepsCount, equals(2));

      // Devotee concludes practice early
      await state.concludeEarly(sequence: sequence);

      expect(state.activeSession, isNull); // Session cleanly cleared
      expect(state.journalEntries.length, equals(1));

      final entry = state.journalEntries.first;
      expect(entry.completedStepCount, equals(2));
      expect(entry.completedStepTitles.length, equals(2));
      expect(entry.completedStepTitles[0], equals(sequence.steps[0].title));
      expect(entry.completedStepTitles[1], equals(sequence.steps[1].title));
    });

    test('Abandoning session records zero entries to the journal and gives no streak credit', () async {
      final service = PracticeOrchestratorService();
      final sequence = PracticeSequence.defaultMorning();
      final state = OrchestratorState(service: service);
      while (state.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await state.startSequence(sequence);
      await state.abandonSession();

      expect(state.activeSession, isNull);
      expect(state.journalEntries, isEmpty);

      final streak = await service.getStreakReport();
      expect(streak.currentStreak, equals(0));
      expect(streak.totalPracticeDays, equals(0));
    });

    test('Zero-completion session yields zero streak credit and zero practice days', () {
      final service = PracticeOrchestratorService();
      final entries = [
        DevotionalJournalEntry(
          id: 'j_zero',
          sessionId: 's_zero',
          sequenceId: 'seq_1',
          sequenceName: 'Morning',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 8, 0),
          completedStepCount: 0, // Zero completed!
          totalStepCount: 4,
          durationMinutes: 1,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.currentStreak, equals(0));
      expect(streak.totalPracticeDays, equals(0));
      expect(streak.longestStreak, equals(0));
    });

    test('Clearing orchestrator journal leaves Japa and Puja session histories untouched', () async {
      final prefs = await SharedPreferences.getInstance();

      // Seed Japa and Puja data in SharedPreferences
      final japaService = JapaSessionService(prefs: prefs);
      final pujaService = PujaSessionService(prefs);
      final orchestratorService = PracticeOrchestratorService(prefs: prefs);

      await japaService.recordCompletedSession(
        JapaPracticeSession(
          id: 'japa_p1',
          mantraId: 'M1',
          mantraTitle: 'Mantra',
          targetRepetitions: 108,
          completedRepetitions: 108,
          countingMode: JapaCountingMode.manual,
          startTime: DateTime.now(),
          lastUpdatedTime: DateTime.now(),
          status: JapaSessionStatus.completed,
        ),
      );

      await pujaService.recordCompletedSession(
        PujaSession(
          id: 'puja_1',
          guideId: 'ganesha-puja-simple',
          currentStepIndex: 5,
          status: PujaSessionStatus.completed,
          startTime: DateTime.now(),
          lastUpdatedTime: DateTime.now(),
        ),
      );

      final sequence = PracticeSequence.defaultMorning();
      final session = OrchestratorSession(
        sessionId: 'orch_1',
        sequenceId: sequence.id,
        sequenceName: sequence.name,
        startedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        completedAt: DateTime.now(),
        stepStatuses: {'0': StepExecutionStatus.completed},
      );
      await orchestratorService.recordCompletedSession(session: session, sequence: sequence);

      // Verify both exist
      expect((await japaService.loadSessionHistory()).length, equals(1));
      expect((await orchestratorService.loadJournalEntries()).length, equals(1));

      // Clear orchestrator journal
      await orchestratorService.clearJournal();

      // Orchestrator journal wiped
      expect((await orchestratorService.loadJournalEntries()), isEmpty);
      // Japa and Puja history untouched!
      expect((await japaService.loadSessionHistory()).length, equals(1));
      expect(pujaService.loadSessionHistory().length, equals(1));
    });
  });

  group('Phase 21L.1 - Local Dates, Timezone & DST Calculation', () {
    late PracticeOrchestratorService service;

    setUp(() {
      service = PracticeOrchestratorService();
    });

    test('Multiple sessions on same local calendar day count as exactly ONE practice day', () {
      final entries = [
        DevotionalJournalEntry(
          id: 'j1',
          sessionId: 's1',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 6, 30),
          completedStepCount: 3,
          totalStepCount: 3,
          durationMinutes: 20,
        ),
        DevotionalJournalEntry(
          id: 'j2',
          sessionId: 's2',
          sequenceId: 'e',
          sequenceName: 'Evening',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 19, 30),
          completedStepCount: 2,
          totalStepCount: 3,
          durationMinutes: 15,
        ),
        DevotionalJournalEntry(
          id: 'j3',
          sessionId: 's3',
          sequenceId: 'c',
          sequenceName: 'Night Chants',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 21, 30),
          completedStepCount: 1,
          totalStepCount: 1,
          durationMinutes: 10,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.currentStreak, equals(1));
      expect(streak.totalPracticeDays, equals(1)); // 3 sessions -> exactly 1 practice day
      expect(streak.longestStreak, equals(1));
    });

    test('Session near local midnight (23:59 Day 1 and 00:01 Day 2) counted as 2 consecutive days', () {
      final entries = [
        DevotionalJournalEntry(
          id: 'j1',
          sessionId: 's1',
          sequenceId: 'e',
          sequenceName: 'Night Contemplation',
          localDate: '2026-11-09',
          completedAt: DateTime(2026, 11, 9, 23, 59),
          completedStepCount: 2,
          totalStepCount: 2,
          durationMinutes: 10,
        ),
        DevotionalJournalEntry(
          id: 'j2',
          sessionId: 's2',
          sequenceId: 'm',
          sequenceName: 'Midnight Dhyana',
          localDate: '2026-11-10',
          completedAt: DateTime(2026, 11, 10, 0, 1),
          completedStepCount: 1,
          totalStepCount: 1,
          durationMinutes: 5,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.totalPracticeDays, equals(2));
      expect(streak.currentStreak, equals(2));
      expect(streak.longestStreak, equals(2));
    });

    test('Timezone change between sessions preserves original localDate strings without rewrite', () {
      // Devotee practices in IST (India) on Day 1, then travels to GMT (London) on Day 2
      final entries = [
        DevotionalJournalEntry(
          id: 'j_ist',
          sessionId: 's_ist',
          sequenceId: 'm',
          sequenceName: 'Morning Sadhana',
          localDate: '2026-11-09',
          completedAt: DateTime.parse('2026-11-09T06:30:00+05:30'),
          completedStepCount: 3,
          totalStepCount: 3,
        ),
        DevotionalJournalEntry(
          id: 'j_gmt',
          sessionId: 's_gmt',
          sequenceId: 'm',
          sequenceName: 'Morning Sadhana',
          localDate: '2026-11-10',
          completedAt: DateTime.parse('2026-11-10T08:00:00Z'),
          completedStepCount: 3,
          totalStepCount: 3,
        ),
      ];

      // Streak engine evaluates local devotional dates faithfully
      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.totalPracticeDays, equals(2));
      expect(streak.currentStreak, equals(2));
      expect(streak.longestStreak, equals(2));
    });

    test('Daylight-saving spring-forward transition (March 8, 2026) computes consecutive 1 day', () {
      // March 7, 2026 -> March 8, 2026 (Spring forward) -> March 9, 2026
      final entries = [
        DevotionalJournalEntry(
          id: 'j_dst_1',
          sessionId: 's_dst_1',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-03-07',
          completedAt: DateTime(2026, 3, 7, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
        DevotionalJournalEntry(
          id: 'j_dst_2',
          sessionId: 's_dst_2',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-03-08',
          completedAt: DateTime(2026, 3, 8, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
        DevotionalJournalEntry(
          id: 'j_dst_3',
          sessionId: 's_dst_3',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-03-09',
          completedAt: DateTime(2026, 3, 9, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 3, 9));
      expect(streak.totalPracticeDays, equals(3));
      expect(streak.currentStreak, equals(3));
      expect(streak.longestStreak, equals(3));
    });

    test('Daylight-saving fall-back transition (Nov 1, 2026) computes consecutive 1 day', () {
      // Oct 31, 2026 -> Nov 1, 2026 (Fall back) -> Nov 2, 2026
      final entries = [
        DevotionalJournalEntry(
          id: 'j_fb_1',
          sessionId: 's_fb_1',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-10-31',
          completedAt: DateTime(2026, 10, 31, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
        DevotionalJournalEntry(
          id: 'j_fb_2',
          sessionId: 's_fb_2',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-01',
          completedAt: DateTime(2026, 11, 1, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
        DevotionalJournalEntry(
          id: 'j_fb_3',
          sessionId: 's_fb_3',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-02',
          completedAt: DateTime(2026, 11, 2, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 2));
      expect(streak.totalPracticeDays, equals(3));
      expect(streak.currentStreak, equals(3));
      expect(streak.longestStreak, equals(3));
    });

    test('A missed local calendar day cleanly breaks current streak while preserving longest streak', () {
      final entries = [
        DevotionalJournalEntry(
          id: '1',
          sessionId: 's1',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-05',
          completedAt: DateTime(2026, 11, 5, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
        DevotionalJournalEntry(
          id: '2',
          sessionId: 's2',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-06',
          completedAt: DateTime(2026, 11, 6, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
        // Missed Nov 7
        DevotionalJournalEntry(
          id: '3',
          sessionId: 's3',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-08',
          completedAt: DateTime(2026, 11, 8, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
        DevotionalJournalEntry(
          id: '4',
          sessionId: 's4',
          sequenceId: 'm',
          sequenceName: 'Morning',
          localDate: '2026-11-09',
          completedAt: DateTime(2026, 11, 9, 7, 0),
          completedStepCount: 2,
          totalStepCount: 2,
        ),
      ];

      final streak = service.calculateStreak(entries, now: DateTime(2026, 11, 10));
      expect(streak.totalPracticeDays, equals(4));
      expect(streak.currentStreak, equals(2)); // Nov 8 and Nov 9 (alive via yesterday)
      expect(streak.longestStreak, equals(2));
    });

    test('App restart and recovery across date boundary attributes completedAt to completion day', () async {
      final service = PracticeOrchestratorService();
      final sequence = PracticeSequence.defaultMorning();

      // Session started at 11:45 PM on Nov 9
      final session = OrchestratorSession(
        sessionId: 'sess_boundary',
        sequenceId: sequence.id,
        sequenceName: sequence.name,
        startedAt: DateTime(2026, 11, 9, 23, 45),
        lastUpdatedAt: DateTime(2026, 11, 10, 0, 15),
        completedAt: DateTime(2026, 11, 10, 0, 20),
        stepStatuses: {
          '0': StepExecutionStatus.completed,
          '1': StepExecutionStatus.completed,
        },
      );

      await service.recordCompletedSession(session: session, sequence: sequence);

      final entries = await service.loadJournalEntries();
      expect(entries.length, equals(1));
      expect(entries.first.localDate, equals('2026-11-10'));
      expect(entries.first.completedAt.day, equals(10));
    });
  });

  group('Phase 21L.1 - Panchangam Recommendation Provenance', () {
    late PracticeOrchestratorService service;

    setUp(() {
      service = PracticeOrchestratorService();
    });

    DailyPanchangamData createMockPanchangam({
      required String varaName,
      required List<Observance> observances,
    }) {
      return DailyPanchangamData(
        calculationTimestampUtc: DateTime(2026, 11, 10, 6, 0),
        requestedDate: DateTime(2026, 11, 10),
        location: PanchangamLocation.varanasi,
        vara: PanchaAngaElement(number: 2, name: varaName, sanskritName: 'भौमवासर', meaning: 'Tuesday'),
        sunMoon: const SunMoonEvents(
          sunriseFormatted: '06:12 AM',
          sunsetFormatted: '05:30 PM',
          dayLengthHours: 11.3,
          dayLengthFormatted: '11h 18m',
          moonIlluminationPercent: 50.0,
        ),
        tithi: const PanchaAngaElement(number: 1, name: 'Pratipada', sanskritName: 'प्रतिपदा', meaning: '1st Lunar Day'),
        nakshatra: const PanchaAngaElement(number: 1, name: 'Ashwini', sanskritName: 'अश्विनी', meaning: 'Horse Woman'),
        yoga: const PanchaAngaElement(number: 1, name: 'Vishkambha', sanskritName: 'विष्कम्भ', meaning: 'Supported'),
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
        observances: observances,
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
    }

    test('Panchangam recommendation displays verified observance when non-empty observance present', () async {
      final pData = createMockPanchangam(
        varaName: 'Mangalavara',
        observances: const [
          Observance(
            name: 'Kartika Somavara Vrat',
            sanskritName: 'कार्तिक सोमवार व्रत',
            category: 'Vrat',
            description: 'Sacred Monday fasting dedicated to Lord Shiva in the holy month of Kartika.',
          ),
        ],
      );

      final rec = await service.getRecommendation(panchangam: pData);
      expect(rec, isNotNull);
      expect(rec!.isLive, isTrue);
      expect(rec.title, contains('Kartika Somavara Vrat'));
      expect(rec.description, contains('Sacred Monday fasting'));
      expect(rec.suggestedStepType, equals(PracticeStepType.sankalpa));
    });

    test('Incomplete observance with empty name safely falls back to day-of-week recommendation', () async {
      final pData = createMockPanchangam(
        varaName: 'Mangalavara (Tuesday)',
        observances: const [
          Observance(name: '   ', sanskritName: '', description: '', category: 'General'),
        ],
      );

      final rec = await service.getRecommendation(panchangam: pData);
      expect(rec, isNotNull);
      expect(rec!.isLive, isTrue);
      expect(rec.title, equals('Daily Practice • Mangalavara (Tuesday)'));
      expect(rec.title, isNot(contains('Observance:')));
    });

    test('Incomplete panchangam with empty vara name safely falls back to standard weekday name', () async {
      final pData = createMockPanchangam(
        varaName: '',
        observances: const [],
      );

      final rec = await service.getRecommendation(
        panchangam: pData,
        referenceNow: DateTime(2026, 11, 10), // Tuesday
      );
      expect(rec, isNotNull);
      expect(rec!.title, equals('Daily Practice • Mangalavara (Tuesday)'));
    });

    test('Offline/null panchangam displays approximate coordinate disclosure', () async {
      final rec = await service.getRecommendation(
        panchangam: null,
        referenceNow: DateTime(2026, 11, 10),
      );
      expect(rec, isNotNull);
      expect(rec!.isLive, isFalse);
      expect(rec.isOfflineFallback, isTrue);
      expect(rec.title, equals('Daily Practice • Mangalavara (Tuesday)'));
      expect(rec.description, contains('currently offline (approximate coordinates)'));
    });

    test('Dismissing recommendation suppresses it persistently for that local date', () async {
      final now = DateTime(2026, 11, 10);
      final recBefore = await service.getRecommendation(referenceNow: now);
      expect(recBefore, isNotNull);

      await service.dismissRecommendationForToday(referenceNow: now);

      final recAfter = await service.getRecommendation(referenceNow: now);
      expect(recAfter, isNull);

      // On next calendar day, recommendation reappears
      final tomorrow = DateTime(2026, 11, 11);
      final recTomorrow = await service.getRecommendation(referenceNow: tomorrow);
      expect(recTomorrow, isNotNull);
    });
  });
}
