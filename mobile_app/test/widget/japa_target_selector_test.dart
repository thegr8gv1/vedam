import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_target_selector_widget.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';

import '../unit/audio_state_and_japa_test.dart';

void main() {
  group('JapaTargetSelectorWidget & Flexible Target UI Widget Tests', () {
    late MockAudioPlaybackService mockAudio;
    late AudioState audioState;
    const sampleMantra = MantraItem(
      id: 'VEDA-MTR-TEST',
      collection: 'Shiva',
      deity: 'Shiva',
      title: 'Om Namah Shivaya',
      filename: 'Om Namah Shivaya.wav',
      mantraText: 'ॐ नमः शिवाय',
      significance: 'Sacred Panchakshari Mantra.',
      form: '',
      durationSeconds: 4.5,
      sampleRate: 48000,
      bitDepth: 16,
      channels: 2,
      fileSizeBytes: 877484,
      sha256: 'abc1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
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

    testWidgets('1. All seven traditional preset cards are visible with labels and spiritual subtitles',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: JapaTargetSelectorWidget(audioState: audioState),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('CHANTING TARGET & JAPA PRESETS'), findsOneWidget);
      expect(find.text('Target: 108'), findsOneWidget); // Default initial target

      // Check all 7 preset cards
      expect(find.byKey(const ValueKey('preset_card_11')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_card_21')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_card_27')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_card_54')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_card_108')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_card_111')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_card_1008')), findsOneWidget);

      // Check traditional labels and subtitles
      expect(find.text('11 repetitions'), findsOneWidget);
      expect(find.text('21 repetitions'), findsOneWidget);
      expect(find.text('27 repetitions'), findsOneWidget);
      expect(find.text('Half Mala'), findsOneWidget);
      expect(find.text('One Mala'), findsOneWidget);
      expect(find.text('111 repetitions'), findsOneWidget);
      expect(find.text('1008 repetitions'), findsOneWidget);

      // Custom card exists
      expect(find.byKey(const ValueKey('custom_target_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('custom_target_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('apply_custom_target_btn')), findsOneWidget);
    });

    testWidgets('2. Tapping preset card updates target directly when session is unstarted',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: JapaTargetSelectorWidget(audioState: audioState),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 54 preset card
      await tester.tap(find.byKey(const ValueKey('preset_card_54')));
      await tester.pumpAndSettle();
      expect(audioState.targetRepetitions, equals(54));

      // Tap 1008 preset card
      await tester.tap(find.byKey(const ValueKey('preset_card_1008')));
      await tester.pumpAndSettle();
      expect(audioState.targetRepetitions, equals(1008));
    });

    testWidgets('3. Custom count input accepts valid values (e.g. 500) and updates target',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: JapaTargetSelectorWidget(audioState: audioState),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inputField = find.byKey(const ValueKey('custom_target_input'));
      await tester.enterText(inputField, '500');
      await tester.pumpAndSettle();

      final applyBtn = find.byKey(const ValueKey('apply_custom_target_btn'));
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(audioState.targetRepetitions, equals(500));
    });

    testWidgets('4. Custom count input validates in real-time and rejects invalid values (0, >100000)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: JapaTargetSelectorWidget(audioState: audioState),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inputField = find.byKey(const ValueKey('custom_target_input'));

      // Test zero
      await tester.enterText(inputField, '0');
      await tester.pumpAndSettle();
      expect(find.textContaining('greater than zero'), findsOneWidget);

      // Try tapping apply: target should NOT change to 0
      final applyBtn = find.byKey(const ValueKey('apply_custom_target_btn'));
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();
      expect(audioState.targetRepetitions, equals(108)); // preserved!

      // Test >100000
      await tester.enterText(inputField, '100001');
      await tester.pumpAndSettle();
      expect(find.textContaining('Maximum practical target is 100000 repetitions'), findsOneWidget);

      await tester.tap(applyBtn);
      await tester.pumpAndSettle();
      expect(audioState.targetRepetitions, equals(108)); // still preserved!
    });

    testWidgets('5. Changing target during active session prompts confirmation and preserves completed repetitions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Start with completed count = 15
      audioState.setTargetRepetitions(108);
      for (int i = 0; i < 15; i++) {
        audioState.incrementManualRepetition();
      }
      expect(audioState.completedRepetitions, equals(15));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: JapaTargetSelectorWidget(audioState: audioState),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 54 preset card
      await tester.tap(find.byKey(const ValueKey('preset_card_54')));
      await tester.pumpAndSettle();

      // Confirmation dialog must be shown
      expect(find.text('Adjust Japa Target?'), findsOneWidget);
      expect(find.textContaining('Completed so far: 15 repetitions'), findsOneWidget);
      expect(find.textContaining('completed count will NOT be reset or altered'), findsOneWidget);

      // Confirm target change
      final updateBtn = find.widgetWithText(ElevatedButton, 'Update Target');
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      expect(audioState.targetRepetitions, equals(54));
      expect(audioState.completedRepetitions, equals(15)); // strictly preserved!
    });

    testWidgets('6. VisualMalaWidget renders correctly for 54-repetition session',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: VisualMalaWidget(
              completedCount: 27,
              targetCount: 54,
              isPlaying: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Half Mala (54 Beads)'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('27'), findsWidgets);
      expect(find.text('54'), findsWidgets);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('7. VisualMalaWidget renders correctly for 1008-repetition session with Mala cycle progress',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: VisualMalaWidget(
              completedCount: 216,
              targetCount: 1008,
              isPlaying: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1008 Repetitions • Sahasra Japa Mahotsava'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('216'), findsWidgets);
      expect(find.text('1008'), findsWidgets);
      expect(find.text('Mala 3 of 10'), findsOneWidget);
    });

    testWidgets('8. MantraPlayerScreen integrates JapaTargetSelectorWidget seamlessly with playback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantraPlayerScreen(
            mantra: sampleMantra,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(JapaTargetSelectorWidget), findsOneWidget);
      expect(find.text('CHANTING TARGET & JAPA PRESETS'), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_card_108')), findsOneWidget);
    });
  });
}
