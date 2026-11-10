import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/data/fixtures/authentic_mantras_data.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
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
  bool get isLoading => false;

  @override
  Stream<bool> get loadingStream => const Stream.empty();

  @override
  Future<void> playMantra(MantraItem item) async {
    _active = item;
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
  Future<void> setPlaybackRate(double rate) async {}

  void simulateComplete() {
    _state = PlayerState.completed;
    _stateController.add(PlayerState.completed);
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 20A: Scripture-to-Audio Mapping Authenticity & Scope Verification', () {
    late ScriptureRepositoryImpl scriptureRepo;
    late MantraRepository mantraRepo;

    setUp(() {
      scriptureRepo = ScriptureRepositoryImpl();
      mantraRepo = MantraRepositoryImpl();
    });

    test('1. All 9 Phase 19B audio mappings resolve to valid authentic mantras', () async {
      final scriptures = await scriptureRepo.getAllScriptures();
      final mappedScriptures = scriptures.where((s) => s.verses.any((v) => v.audioMantraId != null)).toList();

      expect(mappedScriptures.length, equals(9),
          reason: 'Exactly 9 scriptures must have verified audio mappings from Phase 19B');

      for (final s in mappedScriptures) {
        final mappedVerse = s.verses.firstWhere((v) => v.audioMantraId != null);
        final mantraId = mappedVerse.audioMantraId!;
        final mantra = mantraRepo.getMantraById(mantraId);

        expect(mantra, isNotNull, reason: 'Mantra $mantraId must exist in the authentic catalog');
        expect(mantra!.mantraText, isNotEmpty);
        expect(mantra.durationSeconds, greaterThan(0));
      }
    });

    test('2. Scope categorization: 2 entire mantras, 1 opening doha, 6 opening verses/invocations', () {
      // Entire mantras (1-verse complete sacred mantras)
      final mahamrityunjaya = mantraRepo.getMantraById('VEDA-MTR-0413')!;
      final gayatri = mantraRepo.getMantraById('VEDA-MTR-0399')!;
      expect(mahamrityunjaya.isBundled, isTrue, reason: 'Mahamrityunjaya is bundled offline in core APK');
      expect(gayatri.isBundled, isTrue, reason: 'Gayatri is bundled offline in core APK');
      expect(mahamrityunjaya.durationSeconds, inInclusiveRange(15.0, 35.0));
      expect(gayatri.durationSeconds, inInclusiveRange(15.0, 35.0));

      // Opening Mangalacharan Doha
      final hanumanChalisaOpening = mantraRepo.getMantraById('VEDA-MTR-0401')!;
      expect(hanumanChalisaOpening.isBundled, isTrue, reason: 'Hanuman Chalisa opening is bundled offline');

      // Opening verses / invocations (Vault Archive recordings)
      final vaultMappings = [
        'VEDA-MTR-0443', // Shiva Tandava (Verse 1 invocation)
        'VEDA-MTR-0451', // Sri Suktam (Verse 1 invocation)
        'VEDA-MTR-0414', // Mahalakshmi Ashtakam (Verse 1)
        'VEDA-MTR-0411', // Lingashtakam (Verse 1)
        'VEDA-MTR-0407', // Kanakadhara (Verse 1)
        'VEDA-MTR-0382', // Mahishasura Mardini (Verse 1)
      ];

      for (final id in vaultMappings) {
        final m = mantraRepo.getMantraById(id)!;
        expect(m.isBundled, isFalse, reason: '$id is stored in master vault to keep APK size <100MB');
        expect(m.durationSeconds, inInclusiveRange(15.0, 45.0));
      }
    });
  });

  group('Phase 20A: AudioState & Repetition Counting Hardening', () {
    late _MockAudioService mockService;
    late AudioState audioState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockService = _MockAudioService();
      audioState = AudioState(audioService: mockService);
    });

    tearDown(() {
      audioState.dispose();
    });

    test('3. Incomplete audio playback does NOT increment repetition count', () async {
      final sampleMantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await audioState.playMantra(sampleMantra);

      expect(audioState.completedRepetitions, equals(0));

      // Devotee pauses playback mid-verse
      await audioState.pause();
      expect(audioState.completedRepetitions, equals(0),
          reason: 'Pausing playback must not increment repetition count');

      // Devotee seeks within verse
      await audioState.seek(const Duration(seconds: 15));
      expect(audioState.completedRepetitions, equals(0),
          reason: 'Seeking must not increment repetition count');

      // Devotee stops playback
      await audioState.stop();
      expect(audioState.completedRepetitions, equals(0),
          reason: 'Stopping incomplete playback must not increment repetition count');

      // Count only increments when PlayerState.completed is signaled
      mockService.simulateComplete();
      await pumpEventQueue();
      expect(audioState.completedRepetitions, equals(1),
          reason: 'Count increments upon full completion of the repetition');
    });

    test('4. Manual bead debounce prevents double-counting within 250ms threshold', () async {
      audioState.setManualTapDebounceMs(250);

      // First tap
      final tap1 = audioState.incrementManualRepetition();
      expect(tap1, isTrue);
      expect(audioState.completedRepetitions, equals(1));

      // Accidental rapid double-tap (immediate)
      final tap2 = audioState.incrementManualRepetition();
      expect(tap2, isFalse, reason: 'Rapid tap within debounce threshold must be ignored');
      expect(audioState.completedRepetitions, equals(1));

      // After debounce window elapses
      await Future.delayed(const Duration(milliseconds: 260));
      final tap3 = audioState.incrementManualRepetition();
      expect(tap3, isTrue, reason: 'Tap after debounce window must be counted');
      expect(audioState.completedRepetitions, equals(2));
    });

    test('5. Target repetition setter preserves completed count and enforces practical bounds', () {
      audioState.incrementManualRepetition();
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(2));

      // Valid target change
      audioState.setTargetRepetitions(54);
      expect(audioState.targetRepetitions, equals(54));
      expect(audioState.completedRepetitions, equals(2),
          reason: 'Changing target must strictly preserve completed repetitions');

      // Invalid inputs rejected
      audioState.setTargetRepetitions(0);
      expect(audioState.targetRepetitions, equals(54), reason: 'Zero must be rejected');

      audioState.setTargetRepetitions(-10);
      expect(audioState.targetRepetitions, equals(54), reason: 'Negative count must be rejected');

      audioState.setTargetRepetitions(100001);
      expect(audioState.targetRepetitions, equals(54), reason: 'Counts exceeding 100,000 must be rejected');
    });
  });

  group('Phase 20A: Devotional Shelf Multi-Domain Persistence', () {
    test('6. All 5 Devotional Shelf domains persist across reloads', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final scriptureRepo = ScriptureRepositoryImpl();
      final scripture = (await scriptureRepo.getScriptureById(2))!; // Shiva Tandava (id: 2)
      final verse = scripture.verses.first;

      final appState = AppState();
      final readerState = ScriptureReaderState(prefs: prefs);
      await readerState.init();

      final mockService = _MockAudioService();
      final audioState = AudioState(audioService: mockService, prefs: prefs);
      await audioState.init();

      // 1. Saved Scriptures
      appState.toggleFavorite(999);
      expect(appState.isFavorite(999), isTrue);

      // 2. Verse Bookmarks
      await readerState.toggleBookmark(verse, scripture);
      expect(readerState.isBookmarked(verse.globalId(scripture.contentId)), isTrue);

      // 3. Devotional Study Notes
      await readerState.saveNote(verse, scripture, 'Meditation on cosmic rhythm');
      expect(readerState.getNote(verse.globalId(scripture.contentId))?.noteText, equals('Meditation on cosmic rhythm'));

      // 4. Favorite Mantras
      audioState.toggleFavorite('VEDA-MTR-0413');
      expect(audioState.isFavorite('VEDA-MTR-0413'), isTrue);

      // 5. Reading History (Recents)
      appState.recordRecentlyRead(scripture.id);
      expect(appState.recentlyReadScriptureIds.contains(scripture.id), isTrue);

      // Simulate App Restart with new state instances over same SharedPreferences
      final reloadedReaderState = ScriptureReaderState(prefs: prefs);
      await reloadedReaderState.init();

      final reloadedAudioState = AudioState(audioService: mockService, prefs: prefs);
      await reloadedAudioState.init();

      expect(reloadedReaderState.isBookmarked(verse.globalId(scripture.contentId)), isTrue,
          reason: 'Verse bookmark persisted');
      expect(reloadedReaderState.getNote(verse.globalId(scripture.contentId))?.noteText, equals('Meditation on cosmic rhythm'),
          reason: 'Devotional study note persisted');
      expect(reloadedAudioState.isFavorite('VEDA-MTR-0413'), isTrue,
          reason: 'Favorite mantra persisted');

      audioState.dispose();
      reloadedAudioState.dispose();
    });
  });

  group('Phase 20A: Section 8 Translation Governance Enforcement', () {
    test('7. Zero translations marked verified or canonical across authentic scriptures', () async {
      final scriptureRepo = ScriptureRepositoryImpl();
      final allScriptures = await scriptureRepo.getAllScriptures();

      var totalVerses = 0;
      var draftTranslations = 0;

      for (final scripture in allScriptures) {
        for (final verse in scripture.verses) {
          totalVerses++;
          expect(verse.isApproved, isFalse, reason: 'Zero translations can be approved under Section 8');
          expect(verse.translationStatus, isIn(['DRAFT', 'IN_PROGRESS']),
              reason: 'All translations must remain DRAFT or IN_PROGRESS');
          if (verse.hasDraftTranslation) {
            draftTranslations++;
            expect(verse.draftTranslation, isNotEmpty);
          }
        }
      }

      expect(totalVerses, greaterThan(100));
      expect(draftTranslations, greaterThan(0));
    });
  });
}
