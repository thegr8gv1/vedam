import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/japa/japa_practice_screen.dart';
import 'package:vedam_app/presentation/screens/japa/widgets/japa_history_modal.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';

import '../unit/audio_state_and_japa_test.dart';

void main() {
  group('Phase 21A: JapaPracticeScreen Widget & Accessibility Tests', () {
    late MockAudioPlaybackService mockAudio;
    late AudioState audioState;
    const sampleMantra = MantraItem(
      id: 'VEDA-MTR-0001',
      collection: 'Shiva',
      deity: 'Shiva',
      title: 'Om Namah Shivaya',
      filename: 'Om Namah Shivaya.wav',
      mantraText: 'ॐ नमः शिवाय',
      significance: 'Purifies the mind and leads to inner stillness.',
      form: '',
      durationSeconds: 4.5,
      sampleRate: 48000,
      bitDepth: 16,
      channels: 2,
      fileSizeBytes: 877484,
      sha256: 'abc123',
      sourceTxt: 'Assorted Shiva Chants.txt',
      isBundled: true,
      bundledAssetPath: 'assets/audio/bundled/om_namah_shivaya.mp3',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockAudio = MockAudioPlaybackService();
      audioState = AudioState(audioService: mockAudio);
    });

    tearDown(() {
      audioState.dispose();
    });

    testWidgets('1. JapaPracticeScreen renders completely and DOES NOT autoplay audio on entry',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JapaPracticeScreen(
            audioState: audioState,
            initialMantra: sampleMantra,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no autoplay
      expect(mockAudio.playCallCount, equals(0));
      expect(audioState.isPlaying, isFalse);

      // Verify core widgets
      expect(find.text('Daily Japa Practice'), findsOneWidget);
      expect(find.text('Om Namah Shivaya'), findsOneWidget);
      expect(find.text('ॐ नमः शिवाय'), findsOneWidget);
      expect(find.byType(VisualMalaWidget), findsOneWidget);
      expect(find.text('COMPLETED'), findsWidgets);
      expect(find.text('REMAINING'), findsWidgets);
      expect(find.textContaining('COUNT BEAD (+1)'), findsOneWidget);
    });

    testWidgets('2. Tapping manual bead button increments counter with semantic feedback',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JapaPracticeScreen(
            audioState: audioState,
            initialMantra: sampleMantra,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final beadButton = find.textContaining('COUNT BEAD (+1)');
      await tester.ensureVisible(beadButton);
      await tester.tap(beadButton);
      await tester.pumpAndSettle();

      expect(audioState.completedRepetitions, equals(1));
      expect(find.text('1'), findsWidgets); // count displayed
    });

    testWidgets('3. History button opens JapaHistoryModal and displays empty state correctly',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JapaPracticeScreen(
            audioState: audioState,
            initialMantra: sampleMantra,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final historyButton = find.byIcon(Icons.history);
      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      expect(find.byType(JapaHistoryModal), findsOneWidget);
      expect(find.text('Japa Practice History'), findsOneWidget);
      expect(find.text('No Practice History Yet'), findsOneWidget);
    });

    testWidgets('4. Text scale 1.35x does not cause overflow on compact screen (360x640)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.35),
            ),
            child: JapaPracticeScreen(
              audioState: audioState,
              initialMantra: sampleMantra,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No overflow assertions failed
      expect(tester.takeException(), isNull);
    });
  });
}
