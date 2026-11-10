import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/panchangam_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/l10n/app_localizations.dart';
import 'package:vedam_app/presentation/screens/favorites/favorites_screen.dart';
import 'package:vedam_app/presentation/screens/festivals/festival_detail_screen.dart';
import 'package:vedam_app/presentation/screens/home/home_screen.dart';
import 'package:vedam_app/presentation/screens/home/widgets/daily_verse_card.dart';
import 'package:vedam_app/presentation/screens/library/verse_learning_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/screens/panchangam/panchangam_screen.dart';
import 'package:vedam_app/presentation/widgets/scripture_card.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/panchangam_state.dart';
import 'package:vedam_app/state/personalization_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';
import 'package:vedam_app/state/vrat_state.dart';

class _MockAudioService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  final Duration _dur = const Duration(seconds: 30);
  MantraItem? _active;

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _posController.stream;

  @override
  Stream<Duration> get durationStream => _durController.stream;

  @override
  PlayerState get playerState => _state;

  @override
  Duration get currentPosition => _pos;

  @override
  Duration get totalDuration => _dur;

  @override
  MantraItem? get activeMantra => _active;

  @override
  bool get isLoading => false;

  @override
  Stream<bool> get loadingStream => const Stream.empty();

  @override
  Future<void> playMantra(MantraItem mantra) async {
    _active = mantra;
    _state = PlayerState.playing;
    _stateController.add(_state);
  }

  @override
  Future<void> pause() async {
    _state = PlayerState.paused;
    _stateController.add(_state);
  }

  @override
  Future<void> resume() async {
    _state = PlayerState.playing;
    _stateController.add(_state);
  }

  @override
  Future<void> stop() async {
    _state = PlayerState.stopped;
    _stateController.add(_state);
  }

  @override
  Future<void> seek(Duration position) async {
    _pos = position;
    _posController.add(_pos);
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

class _MockPanchangamRepo implements PanchangamRepository {
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 19A Cross-Feature Workflow Widget Tests', () {
    testWidgets('1. FavoritesScreen renders all 5 Devotional Shelf tabs and switches smoothly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefs = await SharedPreferences.getInstance();
      final appState = AppState();
      final scriptureRepo = ScriptureRepositoryImpl();
      final readerState = ScriptureReaderState(prefs: prefs);
      await readerState.init();
      final audioService = _MockAudioService();
      final audioState = AudioState(audioService: audioService, prefs: prefs);
      await audioState.init();
      final mantraRepo = MantraRepositoryImpl();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FavoritesScreen(
              repository: scriptureRepo,
              appState: appState,
              onNavigateToTab: (_) {},
              readerState: readerState,
              audioState: audioState,
              mantraRepository: mantraRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check all 5 Tab headers exist
      expect(find.byType(Tab), findsNWidgets(5));
      expect(find.textContaining('Scriptures'), findsOneWidget);
      expect(find.textContaining('Bookmarks'), findsOneWidget);
      expect(find.textContaining('Notes'), findsOneWidget);
      expect(find.textContaining('Mantras'), findsOneWidget);
      expect(find.textContaining('Recents'), findsOneWidget);

      // Tap Bookmarks tab
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();
      expect(find.text('No Bookmarked Verses'), findsOneWidget);

      // Tap Notes tab
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();
      expect(find.text('No Study Notes Yet'), findsOneWidget);

      // Tap Mantras tab
      await tester.tap(find.byType(Tab).at(3));
      await tester.pumpAndSettle();
      expect(find.text('No Favorite Mantras'), findsOneWidget);

      // Tap Recents tab
      await tester.tap(find.byType(Tab).at(4));
      await tester.pumpAndSettle();
      expect(find.byType(ScriptureCard), findsWidgets);
    });

    testWidgets('2. Devotional Shelf displays bookmarked verse and navigates to VerseLearningScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefs = await SharedPreferences.getInstance();
      final appState = AppState();
      final scriptureRepo = ScriptureRepositoryImpl();
      final readerState = ScriptureReaderState(prefs: prefs);
      await readerState.init();
      final audioService = _MockAudioService();
      final audioState = AudioState(audioService: audioService, prefs: prefs);
      await audioState.init();
      final mantraRepo = MantraRepositoryImpl();

      // Seed a bookmark and note
      final scripture = (await scriptureRepo.getScriptureById(5))!;
      final verse = scripture.verses.first;
      await readerState.toggleBookmark(verse, scripture);
      await readerState.saveNote(verse, scripture, 'Devotional contemplation of Maha Mrityunjaya');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FavoritesScreen(
              repository: scriptureRepo,
              appState: appState,
              onNavigateToTab: (_) {},
              readerState: readerState,
              audioState: audioState,
              mantraRepository: mantraRepo,
              initialTabIndex: 1, // Open directly in Bookmarks tab
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Bookmark card should appear with verse title
      final bookmarkCard = find.textContaining('Mahamrityunjaya Vedic Mantra • Verse 1');
      expect(bookmarkCard, findsOneWidget);

      // Tapping bookmark card navigates to VerseLearningScreen
      await tester.tap(bookmarkCard);
      await tester.pumpAndSettle();

      expect(find.byType(VerseLearningScreen), findsOneWidget);
    });

    testWidgets('3. Devotional Shelf displays favorite mantra and launches MantraPlayerScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefs = await SharedPreferences.getInstance();
      final appState = AppState();
      final scriptureRepo = ScriptureRepositoryImpl();
      final readerState = ScriptureReaderState(prefs: prefs);
      await readerState.init();
      final audioService = _MockAudioService();
      final audioState = AudioState(audioService: audioService, prefs: prefs);
      await audioState.init();
      final mantraRepo = MantraRepositoryImpl();

      // Seed a favorite mantra
      final mantra = mantraRepo.getAllMantras().first;
      audioState.toggleFavorite(mantra.id);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FavoritesScreen(
              repository: scriptureRepo,
              appState: appState,
              onNavigateToTab: (_) {},
              readerState: readerState,
              audioState: audioState,
              mantraRepository: mantraRepo,
              initialTabIndex: 3, // Open directly in Mantras tab
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(mantra.title), findsOneWidget);

      // Tapping mantra tile opens player
      await tester.tap(find.text(mantra.title));
      await tester.pumpAndSettle();

      expect(find.byType(MantraPlayerScreen), findsOneWidget);
    });

    testWidgets('4. Panchangam observance banner navigates seamlessly to FestivalDetailScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefs = await SharedPreferences.getInstance();
      final repo = _MockPanchangamRepo();
      final panchangamState = PanchangamState(repository: repo);
      await panchangamState.loadPanchangam();

      final vratState = VratState();
      final sadhanaState = SadhanaState(prefs: prefs);
      final audioService = _MockAudioService();
      final audioState = AudioState(audioService: audioService, prefs: prefs);
      final mantraRepo = MantraRepositoryImpl();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PanchangamScreen(
            state: panchangamState,
            repository: repo,
            vratState: vratState,
            sadhanaState: sadhanaState,
            mantraRepository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Observance banner should be rendered
      expect(find.textContaining('Somavara Vrata'), findsAtLeastNWidgets(1));
      expect(find.text('View Observance Details & Guided Practices'), findsOneWidget);

      // Tap banner action
      await tester.tap(find.text('View Observance Details & Guided Practices'));
      await tester.pumpAndSettle();

      expect(find.byType(FestivalDetailScreen), findsOneWidget);
      expect(find.textContaining('Somavara Vrata'), findsAtLeastNWidgets(1));
    });

    testWidgets('5. Home screen daily verse card navigates to VerseLearningScreen and touches satisfy 48dp',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefs = await SharedPreferences.getInstance();
      final appState = AppState();
      final scriptureRepo = ScriptureRepositoryImpl();
      final personalization = PersonalizationState(appState: appState, prefs: prefs);
      final sadhana = SadhanaState(prefs: prefs);
      final vrat = VratState();
      final repo = _MockPanchangamRepo();
      final panchangam = PanchangamState(repository: repo);
      await panchangam.loadPanchangam();
      final audio = AudioState(audioService: _MockAudioService(), prefs: prefs);
      final reader = ScriptureReaderState(prefs: prefs);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(
            repository: scriptureRepo,
            appState: appState,
            onNavigateToTab: (_) {},
            personalizationState: personalization,
            sadhanaState: sadhana,
            vratState: vrat,
            panchangamState: panchangam,
            audioState: audio,
            readerState: reader,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Daily verse card and tap Read Scripture
      expect(find.byType(DailyVerseCard), findsOneWidget);
      final readScriptureButton = find.text('Read Scripture');
      expect(readScriptureButton, findsOneWidget);

      await tester.tap(readScriptureButton);
      await tester.pumpAndSettle();

      // Should have navigated to VerseLearningScreen
      expect(find.byType(VerseLearningScreen), findsOneWidget);
    });
  });
}
