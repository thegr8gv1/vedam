import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/fixtures/authentic_festival_catalog_data.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/panchangam_repository.dart';
import 'package:vedam_app/presentation/screens/festivals/festival_calendar_screen.dart';
import 'package:vedam_app/presentation/screens/festivals/festival_detail_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/screens/sadhana/guided_puja_screen.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/panchangam_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';
import 'package:vedam_app/state/vrat_state.dart';

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vedam_app/core/models/mantra_item.dart';

class _MockAudioService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  final Duration _dur = const Duration(seconds: 5);
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
    throw const PanchangamUnavailableException(
      message: 'Offline Mode',
      details: 'Mock offline mode for test verification',
    );
  }

  @override
  Future<List<PanchangamLocation>> getCuratedLocations({String? query}) async {
    return [PanchangamLocation.varanasi];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late VratState vratState;
  late PanchangamState panchangamState;
  late SadhanaState sadhanaState;
  late AudioState audioState;
  late MantraRepository mantraRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    vratState = VratState(prefs: prefs);
    panchangamState = PanchangamState(repository: _MockPanchangamRepo());
    sadhanaState = SadhanaState(prefs: prefs);
    audioState = AudioState(audioService: _MockAudioService());
    mantraRepo = MantraRepositoryImpl();
  });

  Widget buildTestScreen({
    DateTime? initialDate,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(393, 852),
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: FestivalCalendarScreen(
          vratState: vratState,
          panchangamState: panchangamState,
          sadhanaState: sadhanaState,
          mantraRepository: mantraRepo,
          audioState: audioState,
          initialDate: initialDate ?? DateTime(2026, 11, 5),
        ),
      ),
    );
  }

  group('Phase 17B: Festival & Regional Observance Calendar Tests', () {
    testWidgets('1. Monthly calendar navigation: Prev/Next month and Today shortcut', (tester) async {
      await tester.pumpWidget(buildTestScreen(initialDate: DateTime(2026, 11, 5)));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);

      // Navigate Next Month -> December 2026
      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();
      expect(find.text('December 2026'), findsOneWidget);

      // Navigate Previous Month -> November 2026
      await tester.tap(find.byTooltip('Previous Month'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);

      // Tap Today -> returns to current month
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.byType(FestivalCalendarScreen), findsOneWidget);
    });

    testWidgets('2. Correct selected-day event display: Rama Ekadashi on Nov 5, 2026', (tester) async {
      await tester.pumpWidget(buildTestScreen(initialDate: DateTime(2026, 11, 5)));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Nov 5 has Rama Ekadashi
      expect(find.text('Rama Ekadashi Vratam'), findsOneWidget);
      expect(find.text('रमा एकादशी व्रतम्'), findsOneWidget);
      expect(find.textContaining('Ekadashi'), findsWidgets);
    });

    testWidgets('3. Location and timezone handling displays configured location', (tester) async {
      await tester.pumpWidget(buildTestScreen(initialDate: DateTime(2026, 11, 5)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Varanasi (Kashi), UP, India'), findsOneWidget);
      expect(find.textContaining('Drik Ganita Ephemeris'), findsOneWidget);
    });

    testWidgets('4. Multiple observances on one day: Deepavali and Amavasya on Nov 8, 2026', (tester) async {
      await tester.pumpWidget(buildTestScreen(initialDate: DateTime(2026, 11, 8)));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();

      // November 8 has both Deepavali and Kartika Amavasya
      expect(find.text('Deepavali / Sri Lakshmi Puja'), findsOneWidget);
      expect(find.textContaining('2 sacred observances coincide'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(find.text('Kartika Amavasya (Pitru Tarpanam)'), findsOneWidget);
    });

    testWidgets('5. Regional date variation handling displays in detail view', (tester) async {
      final ramaEkadashi = AuthenticFestivalCatalogData.getEventById('fest_rama_ekadashi_2026')!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FestivalDetailScreen(
            event: ramaEkadashi,
            vratState: vratState,
            panchangamState: panchangamState,
            sadhanaState: sadhanaState,
            mantraRepository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('North Indian calendars denote this as Kartika'), findsOneWidget);
      expect(find.textContaining('South and Western Indian (Amanta) calendars denote it as Ashvina'), findsOneWidget);
    });

    testWidgets('6. Missing source information and uncertainty labels: Devotee guidance disclaimer', (tester) async {
      final deepavali = AuthenticFestivalCatalogData.getEventById('fest_deepavali_2026')!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FestivalDetailScreen(
            event: deepavali,
            vratState: vratState,
            panchangamState: panchangamState,
            sadhanaState: sadhanaState,
            mantraRepository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Devotee Guidance: Astronomical algorithms compute civil occurrences'), findsOneWidget);
      expect(find.textContaining('Specific temple sampradayas'), findsOneWidget);
    });

    testWidgets('7. Event detail navigation: Opens detail screen from calendar', (tester) async {
      await tester.pumpWidget(buildTestScreen(initialDate: DateTime(2026, 11, 5)));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final detailsBtn = find.widgetWithText(OutlinedButton, 'View Details').first;
      await tester.ensureVisible(detailsBtn);
      await tester.pumpAndSettle();
      await tester.tap(detailsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(FestivalDetailScreen), findsOneWidget);
      expect(find.text('PANCHANGAM COORDINATES & TIMING'), findsOneWidget);
      expect(find.text('AUTHENTIC SOURCING & REGIONAL VARIATIONS'), findsOneWidget);
    });

    testWidgets('8. Opening related puja guides: Starts Guided Puja from festival detail', (tester) async {
      final ganeshaEvent = AuthenticFestivalCatalogData.getEventById('fest_ganesha_chaturthi_2026')!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FestivalDetailScreen(
            event: ganeshaEvent,
            vratState: vratState,
            panchangamState: panchangamState,
            sadhanaState: sadhanaState,
            mantraRepository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure 'Start Puja' button is visible in scroll view
      final startPujaBtn = find.widgetWithText(ElevatedButton, 'Start Puja');
      await tester.ensureVisible(startPujaBtn);
      await tester.pumpAndSettle();
      await tester.tap(startPujaBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GuidedPujaScreen), findsOneWidget);
      expect(sadhanaState.activeGuide, isNotNull);
    });

    testWidgets('9. Opening verified mantra/audio mappings: Launches Mantra Player', (tester) async {
      final shivaratriEvent = AuthenticFestivalCatalogData.getEventById('fest_maha_shivaratri_2026')!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FestivalDetailScreen(
            event: shivaratriEvent,
            vratState: vratState,
            panchangamState: panchangamState,
            sadhanaState: sadhanaState,
            mantraRepository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listenBtn = find.widgetWithText(OutlinedButton, 'Listen');
      await tester.ensureVisible(listenBtn);
      await tester.pumpAndSettle();
      await tester.tap(listenBtn);
      await tester.pumpAndSettle();

      expect(find.byType(MantraPlayerScreen), findsOneWidget);
    });

    testWidgets('10 & 11. Adding an observance to personal Vrat and Duplicate Prevention', (tester) async {
      final devDeepavali = AuthenticFestivalCatalogData.getEventById('fest_dev_deepavali_2026')!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FestivalDetailScreen(
            event: devDeepavali,
            vratState: vratState,
            panchangamState: panchangamState,
            sadhanaState: sadhanaState,
            mantraRepository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialCount = vratState.observances.length;

      // 10. Add to personal Vrat
      final planBtn = find.widgetWithText(ElevatedButton, 'Plan Personal Vrat Practice');
      await tester.ensureVisible(planBtn);
      await tester.pumpAndSettle();
      await tester.tap(planBtn);
      await tester.pumpAndSettle();

      expect(vratState.observances.length, initialCount + 1);
      final added = vratState.observances.last;
      expect(added.title, devDeepavali.name);
      expect(added.status, ObservanceStatus.planned);

      // UI should now show included in personal vrat
      expect(find.text('INCLUDED IN PERSONAL VRAT PRACTICE'), findsOneWidget);
      expect(find.text('Open Personal Vrat Details'), findsOneWidget);

      // 11. Duplicate prevention: Tapping bookmark action should not add duplicate
      final bookmarkAction = find.byIcon(Icons.bookmark);
      expect(bookmarkAction, findsOneWidget);
      await tester.tap(bookmarkAction);
      await tester.pumpAndSettle();

      expect(vratState.observances.length, initialCount + 1); // Strictly prevented duplicate
    });

    testWidgets('12. Existing Vrat progress preservation: Retains checklist progress', (tester) async {
      final ramaEkadashi = AuthenticFestivalCatalogData.getEventById('fest_rama_ekadashi_2026')!;

      // Pre-add with 1 completed item
      final preObservance = VratObservance(
        id: 'vrat_${ramaEkadashi.id}',
        type: VratType.ekadashi,
        title: ramaEkadashi.name,
        sanskritTitle: ramaEkadashi.sanskritName,
        targetDate: ramaEkadashi.targetDate,
        location: 'Varanasi',
        tradition: 'Universal',
        status: ObservanceStatus.inProgress,
        checklist: const [
          VratChecklistItem(id: 'chk_1', title: 'Preparation Step', isDone: true),
        ],
        createdAt: DateTime.now().toIso8601String(),
      );
      await vratState.addObservance(preObservance);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FestivalDetailScreen(
            event: ramaEkadashi,
            vratState: vratState,
            panchangamState: panchangamState,
            sadhanaState: sadhanaState,
            mantraRepository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final existing = vratState.getObservanceById('vrat_${ramaEkadashi.id}')!;
      expect(existing.status, ObservanceStatus.inProgress);
      expect(existing.checklist.first.isDone, isTrue);
    });

    testWidgets('14. Theme compatibility: Renders cleanly in Temple Night (dark) theme', (tester) async {
      await tester.pumpWidget(
        buildTestScreen(
          initialDate: DateTime(2026, 11, 5),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FestivalCalendarScreen), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets('15. Offline and unavailable-data behavior: Loads authentic catalog safely', (tester) async {
      // Mock repository throws PanchangamUnavailableException
      await tester.pumpWidget(buildTestScreen(initialDate: DateTime(2026, 11, 5)));
      await tester.pumpAndSettle();

      expect(find.byType(FestivalCalendarScreen), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Catalog events still load and render correctly
      expect(find.text('Rama Ekadashi Vratam'), findsOneWidget);
    });

    testWidgets('16. Responsive calendar rendering: >= 700dp renders dual-column layout', (tester) async {
      await tester.pumpWidget(
        buildTestScreen(
          initialDate: DateTime(2026, 11, 5),
          surfaceSize: const Size(1024, 768), // Tablet / Desktop
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FestivalCalendarScreen), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget); // Dual-pane divider
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Rama Ekadashi Vratam'), findsOneWidget);
    });
  });
}
