import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/app_settings.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/data/fixtures/authentic_festival_catalog_data.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/panchangam_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/panchangam_state.dart';
import 'package:vedam_app/state/personalization_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';

class MockAudioPlaybackService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  PlayerState _currentState = PlayerState.stopped;
  Duration _currentPos = Duration.zero;
  final Duration _totalDur = const Duration(seconds: 5);
  MantraItem? _active;

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _posController.stream;

  @override
  Stream<Duration> get durationStream => _durController.stream;

  @override
  PlayerState get playerState => _currentState;

  @override
  Duration get currentPosition => _currentPos;

  @override
  Duration get totalDuration => _totalDur;

  @override
  MantraItem? get activeMantra => _active;

  @override
  bool get isLoading => false;

  @override
  Stream<bool> get loadingStream => const Stream.empty();

  @override
  Future<void> playMantra(MantraItem mantra) async {
    _active = mantra;
    _currentState = PlayerState.playing;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> pause() async {
    _currentState = PlayerState.paused;
    _stateController.add(PlayerState.paused);
  }

  @override
  Future<void> resume() async {
    _currentState = PlayerState.playing;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> stop() async {
    _currentState = PlayerState.stopped;
    _stateController.add(PlayerState.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    _currentPos = position;
    _posController.add(position);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
  }
}

class MockPanchangamRepository implements PanchangamRepository {
  @override
  Future<DailyPanchangamData> getDailyPanchangam({
    required DateTime date,
    required PanchangamLocation location,
    String ayanamsa = 'lahiri',
  }) async {
    return DailyPanchangamData(
      calculationTimestampUtc: DateTime.now(),
      requestedDate: date,
      location: location,
      vara: const PanchaAngaElement(
        number: 2,
        name: 'Somavara',
        sanskritName: 'सोमवार',
        meaning: 'Moon day',
      ),
      sunMoon: const SunMoonEvents(
        sunriseFormatted: '06:12 AM',
        sunsetFormatted: '05:35 PM',
        dayLengthHours: 11.38,
        dayLengthFormatted: '11h 23m',
        moonIlluminationPercent: 4.5,
      ),
      tithi: const PanchaAngaElement(
        number: 1,
        name: 'Shukla Pratipada',
        sanskritName: 'शुक्ल प्रतिपदा',
        endTimeFormatted: '02:30 PM',
        meaning: 'First lunar day',
      ),
      nakshatra: const PanchaAngaElement(
        number: 1,
        name: 'Ashwini',
        sanskritName: 'अश्विनी',
        endTimeFormatted: '04:45 PM',
        meaning: 'The Physician of the Gods',
      ),
      yoga: const PanchaAngaElement(
        number: 16,
        name: 'Siddha',
        sanskritName: 'सिद्ध',
        meaning: 'Accomplished',
      ),
      karana: const PanchaAngaElement(
        number: 1,
        name: 'Kimstughna',
        sanskritName: 'किंस्तुघ्न',
        meaning: 'Auspicious deed',
      ),
      paksha: 'Shukla Paksha',
      rahuKalam: TimePeriod(
        name: 'Rahu Kalam',
        sanskritName: 'राहुकाल',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        formatted: '07:30 AM - 09:00 AM',
        isAuspicious: false,
        description: 'Inauspicious',
      ),
      yamagandam: TimePeriod(
        name: 'Yamagandam',
        sanskritName: 'यमगण्ड',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        formatted: '10:30 AM - 12:00 PM',
        isAuspicious: false,
        description: 'Yama',
      ),
      gulikaKalam: TimePeriod(
        name: 'Gulika Kalam',
        sanskritName: 'गुलिक काल',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        formatted: '01:30 PM - 03:00 PM',
        isAuspicious: true,
        description: 'Gulika',
      ),
      observances: const [
        Observance(
          name: 'Somavara Vrata',
          sanskritName: 'सोमवार व्रत',
          category: 'vrat',
          description: 'Fasting and prayer dedicated to Lord Shiva.',
          disclaimer: 'Personal observance',
        ),
      ],
      conventions: const CalculationConventions(
        ayanamsaUsed: 'Lahiri (Chitra Paksha)',
        ayanamsaValueDegrees: 24.23,
        ayanamsaValueFormatted: '24° 13\' 55"',
        ephemerisEngine: 'Swiss Ephemeris 2.10',
        coordinateSystem: 'Geocentric',
        sunriseConvention: 'Tip of disc at atmospheric horizon (-50\')',
        timeScale: 'TT',
        udayaTithiRule: 'Prevalent at local civil sunrise',
      ),
    );
  }

  @override
  Future<List<PanchangamLocation>> getCuratedLocations({String? query}) async {
    return [PanchangamLocation.varanasi];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 19A: Cross-Feature State & Persistence Integration', () {
    test('1. Reading-progress and study-note persistence across restart', () async {
      final prefs = await SharedPreferences.getInstance();
      final readerState1 = ScriptureReaderState(prefs: prefs);
      await readerState1.init();

      final scripture = (await ScriptureRepositoryImpl().getScriptureById(5))!;
      final verse = scripture.verses.first;

      // Record progress and note
      await readerState1.recordReadingProgress(scripture, 1);
      await readerState1.saveNote(verse, scripture, 'Contemplating Vasishtha Gotra lineage');
      await readerState1.toggleBookmark(verse, scripture);

      // Simulate app restart by re-initializing from same SharedPreferences
      final readerState2 = ScriptureReaderState(prefs: prefs);
      await readerState2.init();

      final restoredProgress = readerState2.getProgress(5);
      expect(restoredProgress, isNotNull);
      expect(restoredProgress!.lastReadVerseNumber, equals(1));

      final restoredNote = readerState2.getNote(verse.globalId(scripture.contentId));
      expect(restoredNote, isNotNull);
      expect(restoredNote!.noteText, equals('Contemplating Vasishtha Gotra lineage'));

      final isBookmarked = readerState2.isBookmarked(verse.globalId(scripture.contentId));
      expect(isBookmarked, isTrue);
    });

    test('2. Japa target persistence and custom target safety validation', () async {
      final prefs = await SharedPreferences.getInstance();
      final mockAudioService = MockAudioPlaybackService();
      final audioState = AudioState(audioService: mockAudioService, prefs: prefs);
      await audioState.init();

      // Default target
      expect(audioState.targetRepetitions, equals(108));

      // Preset targets
      audioState.setTargetRepetitions(1008);
      expect(audioState.targetRepetitions, equals(1008));

      // Custom targets
      audioState.setTargetRepetitions(50000);
      expect(audioState.targetRepetitions, equals(50000));

      // Safety checks: reject 0, negative, or > 100,000
      audioState.setTargetRepetitions(0);
      expect(audioState.targetRepetitions, equals(50000));

      audioState.setTargetRepetitions(-10);
      expect(audioState.targetRepetitions, equals(50000));

      audioState.setTargetRepetitions(150000);
      expect(audioState.targetRepetitions, equals(50000));

      // Restart check
      final audioState2 = AudioState(audioService: mockAudioService, prefs: prefs);
      await audioState2.init();
      expect(audioState2.targetRepetitions, equals(50000));
    });

    test('3. Audio completion counting rules: pause/seek do not count; manual Japa works offline', () async {
      final mockAudio = MockAudioPlaybackService();
      final audioState = AudioState(audioService: mockAudio);

      expect(audioState.completedRepetitions, equals(0));

      // Pausing or seeking must NOT increment repetitions
      await audioState.pause();
      expect(audioState.completedRepetitions, equals(0));

      await audioState.seek(const Duration(seconds: 3));
      expect(audioState.completedRepetitions, equals(0));

      await audioState.resume();
      expect(audioState.completedRepetitions, equals(0));

      await audioState.stop();
      expect(audioState.completedRepetitions, equals(0));

      // Manual bead counting works offline and increments accurately
      audioState.incrementManualRepetition();
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(2));
      expect(audioState.countingModeLabel, contains('Manual'));
    });

    test('4. Sadhana completion, roll-over, and duplicate prevention on resume', () async {
      final prefs = await SharedPreferences.getInstance();
      final sadhana = SadhanaState(prefs: prefs);
      await Future.delayed(const Duration(milliseconds: 50));
      final activeRoutines = sadhana.activeRoutine;
      expect(activeRoutines.isNotEmpty, isTrue);

      final practiceId = activeRoutines.first.id;
      expect(sadhana.isPracticeCompleted(practiceId), isFalse);

      // Complete once
      sadhana.togglePracticeCompletion(practiceId);
      expect(sadhana.isPracticeCompleted(practiceId), isTrue);
      expect(sadhana.completedRoutineCount, equals(1));

      // Toggling again un-completes
      sadhana.togglePracticeCompletion(practiceId);
      expect(sadhana.isPracticeCompleted(practiceId), isFalse);
      expect(sadhana.completedRoutineCount, equals(0));

      // Complete and verify resume does not duplicate
      sadhana.togglePracticeCompletion(practiceId);
      expect(sadhana.completedRoutineCount, equals(1));

      sadhana.checkDateRollOver();
      expect(sadhana.completedRoutineCount, equals(1));
    });

    test('5. Decoupled settings: UI language does not alter scripture script and vice versa', () async {
      final appState = AppState();

      // Defaults
      expect(appState.interfaceLanguage, equals(InterfaceLanguage.english));
      expect(appState.activeScript, equals(ScriptOption.devanagari));

      // Changing interface language
      appState.setInterfaceLanguage(InterfaceLanguage.telugu);
      expect(appState.interfaceLanguage, equals(InterfaceLanguage.telugu));
      expect(appState.activeScript, equals(ScriptOption.devanagari)); // Unchanged!

      appState.setInterfaceLanguage(InterfaceLanguage.tamil);
      expect(appState.interfaceLanguage, equals(InterfaceLanguage.tamil));
      expect(appState.activeScript, equals(ScriptOption.devanagari)); // Unchanged!

      // Changing scripture script
      appState.setActiveScript(ScriptOption.kannada);
      expect(appState.activeScript, equals(ScriptOption.kannada));
      expect(appState.interfaceLanguage, equals(InterfaceLanguage.tamil)); // Unchanged!
    });

    test('6. Panchangam calculation runs offline via local astronomical models/repository', () async {
      final repo = MockPanchangamRepository();
      final state = PanchangamState(repository: repo);

      await state.loadPanchangam();

      expect(state.isLoading, isFalse);
      expect(state.data, isNotNull);
      expect(state.data!.tithi.name.isNotEmpty, isTrue);
      expect(state.data!.nakshatra.name.isNotEmpty, isTrue);
      expect(state.data!.vara.name.isNotEmpty, isTrue);
      expect(state.data!.conventions.ayanamsaUsed, contains('Lahiri'));
    });

    test('7. Vrat & Festival integration links to genuine Puja and Mantra associations', () async {
      final catalog = AuthenticFestivalCatalogData.allEvents;
      expect(catalog.isNotEmpty, isTrue);

      final ramaEkadashi = catalog.firstWhere((e) => e.name.contains('Rama Ekadashi'));
      expect(ramaEkadashi.associatedPujaGuideId, equals('guide_vishnu_puja'));
      expect(ramaEkadashi.associatedMantraId, equals('VEDA-MTR-0378'));
      expect(ramaEkadashi.suggestedChecklist.isNotEmpty, isTrue);
    });

    test('8. Cloud archive vs bundled offline audio status reporting', () {
      final mantraRepo = MantraRepositoryImpl();
      final allMantras = mantraRepo.getAllMantras();

      final bundled = allMantras.where((m) => m.isBundled).toList();
      final cloud = allMantras.where((m) => !m.isBundled).toList();

      expect(bundled.length, equals(31));
      expect(cloud.isNotEmpty, isTrue);

      for (final m in bundled) {
        expect(m.bundledAssetPath, isNotNull);
        expect(m.bundledAssetPath, startsWith('assets/audio/bundled/'));
      }
    });

    test('9. Devotee personalization preserves custom sadhana goals across reloads', () async {
      final prefs = await SharedPreferences.getInstance();
      final appState = AppState();
      final pState1 = PersonalizationState(appState: appState, prefs: prefs);

      await pState1.setDevotionalInterests({'shiva'});
      await pState1.setJapaTarget(1008);
      await pState1.setScriptureScript(ScriptOption.devanagari);
      await pState1.setInterfaceLanguage('te');

      // Reload from SharedPreferences
      final pState2 = PersonalizationState(appState: appState, prefs: prefs);

      expect(pState2.selectedDeityIds.contains('shiva'), isTrue);
      expect(pState2.japaTarget, equals(1008));
      expect(pState2.scriptureScript, equals(ScriptOption.devanagari));
      expect(pState2.interfaceLanguage, equals('te'));
    });
  });
}
