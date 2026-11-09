import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/models/scripture.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/l10n/app_localizations.dart';
import 'package:vedam_app/presentation/screens/favorites/favorites_screen.dart';
import 'package:vedam_app/presentation/screens/library/library_screen.dart';
import 'package:vedam_app/presentation/screens/library/scripture_detail_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/mantras_screen.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';

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
  Future<void> playMantra(MantraItem mantra) async {
    _active = mantra;
    _state = PlayerState.playing;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> pause() async {
    _state = PlayerState.paused;
    _stateController.add(PlayerState.paused);
  }

  @override
  Future<void> resume() async {
    _state = PlayerState.playing;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> stop() async {
    _state = PlayerState.stopped;
    _stateController.add(PlayerState.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    _pos = position;
    _posController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPlaybackRate(double rate) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
  }
}

Widget _buildTestApp({required Widget child, AppState? appState}) {
  final state = appState ?? AppState();
  return MaterialApp(
    locale: state.locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 19B Widget Tests: Devotional Feature Completeness', () {
    late AppState appState;
    late ScriptureRepositoryImpl scriptureRepo;
    late MantraRepository mantraRepo;
    late ScriptureReaderState readerState;
    late AudioState audioState;
    late _MockAudioService mockAudioService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
      scriptureRepo = ScriptureRepositoryImpl();
      mantraRepo = MantraRepositoryImpl();
      readerState = ScriptureReaderState();
      mockAudioService = _MockAudioService();
      audioState = AudioState(audioService: mockAudioService);
    });

    tearDown(() {
      mockAudioService.dispose();
    });

    testWidgets('1. LibraryScreen renders Audio Availability filter chips and combined filters',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: LibraryScreen(
            repository: scriptureRepo,
            appState: appState,
            readerState: readerState,
            audioState: audioState,
          ),
          appState: appState,
        ),
      );
      await tester.pumpAndSettle();

      // Verify search bar and filter chips
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All Formats'), findsOneWidget);
      expect(find.text('Chanting Audio'), findsOneWidget);
      expect(find.text('Text Study'), findsOneWidget);

      // Tap Chanting Audio filter chip
      await tester.tap(find.text('Chanting Audio'));
      await tester.pumpAndSettle();

      // Verify filtered results contain scripture with mapped audio (e.g. Mahamrityunjaya or Shiva Tandava)
      expect(find.text('Shiva Tandava Stotram'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      // Tap Reset Filters
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      // After reset, all scriptures should be shown
      expect(find.text('Ganesha Pancharatnam'), findsOneWidget);
    });

    testWidgets('2. ScriptureDetailScreen displays Chanting Audio pill and honest metadata',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Scripture 5: Mahamrityunjaya Vedic Mantra (mapped to VEDA-MTR-0413)
      final scripture = (await scriptureRepo.getScriptureById(5))!;

      await tester.pumpWidget(
        _buildTestApp(
          child: ScriptureDetailScreen(
            scripture: scripture,
            appState: appState,
            readerState: readerState,
            audioState: audioState,
          ),
          appState: appState,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header Hero Card contains Chanting Audio Available pill
      expect(find.text('Chanting Audio Available'), findsOneWidget);
      expect(find.text('Mahamrityunjaya Vedic Mantra'), findsWidgets);

      // Verify Section 8 Draft Governance is displayed
      expect(find.text('Section 8 Draft (0 Approved, Under Peer Review)'), findsOneWidget);
      expect(find.text('CONTENT COVERAGE & SCHOLARLY INTEGRITY'), findsOneWidget);
      expect(find.text('TRADITIONAL ATTRIBUTION & PROVENANCE'), findsOneWidget);
    });

    testWidgets('3. ScriptureDetailScreen shows Unspecified in canonical record when fields are empty',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const emptyMetadataScripture = Scripture(
        id: 999,
        contentId: 'VEDA-TXT-TEST',
        canonicalTitle: 'Anonymous Ancient Hymn',
        devanagariTitle: 'प्राचीन स्तोत्रम्',
        category: 'Stotra',
        deity: 'Lord Shiva',
        composer: '', // Unspecified
        rishi: '',    // Unspecified
        chandas: '',  // Unspecified
        devata: 'Lord Shiva',
        sourceScripture: '',
        traditionalUsage: '',
        verseCount: 1,
        verses: [
          Verse(
            verseNumber: 1,
            devanagariText: 'ॐ नमः शिवाय',
            iastText: 'oṃ namaḥ śivāya',
            draftTranslation: 'Draft translation for testing honesty.',
          ),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: ScriptureDetailScreen(
            scripture: emptyMetadataScripture,
            appState: appState,
            readerState: readerState,
            audioState: audioState,
          ),
          appState: appState,
        ),
      );
      await tester.pumpAndSettle();

      // Verify honest unspecified presentation instead of fabricated attribution
      expect(find.text('Unspecified in canonical record'), findsWidgets);
      // Verify text study pill
      expect(find.text('Text Study'), findsOneWidget);
    });

    testWidgets('4. MantrasScreen renders Deity filter chips and clear offline/vault badges',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: MantrasScreen(
            repository: mantraRepo,
            audioState: audioState,
          ),
          appState: appState,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Deity selection chips and quick filters
      expect(find.text('Offline Ready'), findsOneWidget);
      expect(find.textContaining('Favorites (0)'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsWidgets);

      // Verify badge text displays
      expect(find.text('Offline Audio'), findsWidgets);

      // Filter by tapping 'Offline Ready'
      await tester.tap(find.widgetWithText(FilterChip, 'Offline Ready'));
      await tester.pumpAndSettle();

      // Verify Reset Filters appears
      expect(find.text('Reset Filters'), findsOneWidget);

      // Reset filters
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      expect(find.textContaining('455 Sacred Mantras Available'), findsOneWidget);
    });

    testWidgets('5. FavoritesScreen Devotional Shelf provides responsive tabs and instant state updates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: FavoritesScreen(
            repository: scriptureRepo,
            appState: appState,
            onNavigateToTab: (_) {},
            readerState: readerState,
            audioState: audioState,
            mantraRepository: mantraRepo,
          ),
          appState: appState,
        ),
      );
      await tester.pumpAndSettle();

      // Check all 5 Devotional Shelf tabs
      expect(find.textContaining('Scriptures'), findsOneWidget);
      expect(find.textContaining('Bookmarks'), findsOneWidget);
      expect(find.textContaining('Notes'), findsOneWidget);
      expect(find.textContaining('Mantras'), findsOneWidget);
      expect(find.textContaining('Recents'), findsOneWidget);

      // Switch to Mantras tab
      await tester.tap(find.textContaining('Mantras'));
      await tester.pumpAndSettle();

      // Initially 0 favorites -> empty state
      expect(find.text('No Favorite Mantras'), findsOneWidget);

      // Add a favorite mantra dynamically
      audioState.toggleFavoriteMantra('VEDA-MTR-0413');
      await tester.pumpAndSettle();

      // Should immediately update without reloading screen
      expect(find.text('No Favorite Mantras'), findsNothing);
      expect(find.text('OFFLINE'), findsOneWidget);
    });
  });
}
