import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_completion_dialog.dart';
import 'package:vedam_app/presentation/screens/mantras/widgets/japa_target_modal.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';

import '../unit/audio_state_and_japa_test.dart';

void main() {
  group('MantraPlayerScreen & VisualMala Widget Tests', () {
    late MockAudioPlaybackService mockAudio;
    late AudioState audioState;
    late MantraItem sampleMantra;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockAudio = MockAudioPlaybackService();
      audioState = AudioState(audioService: mockAudio);
      sampleMantra = const MantraItem(
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
        sha256: 'abc1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        sourceTxt: 'Assorted Shiva Chants.txt',
        isBundled: true,
        bundledAssetPath: 'assets/audio/bundled/om_namah_shivaya.mp3',
      );
    });

    tearDown(() {
      audioState.dispose();
    });

    testWidgets('Renders mantra text, visual 108 mala, repeat chips, and controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
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

      expect(find.text('Om Namah Shivaya'), findsWidgets);
      expect(find.text('ॐ नमः शिवाय'), findsOneWidget);
      expect(find.byType(VisualMalaWidget), findsOneWidget);
      expect(find.text('108-Bead Japa Mala'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('TARGET'), findsOneWidget);
      expect(find.text('REMAINING'), findsOneWidget);

      // Repeat mode chips exist (including traditional presets)
      expect(find.widgetWithText(ChoiceChip, '1'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '11'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '27'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '54'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '108'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '111'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '1008'), findsOneWidget);

      // Play/Pause button
      expect(find.byIcon(Icons.pause), findsOneWidget); // Plays automatically on entry
    });

    testWidgets('Tapping repeat mode chip updates target repetitions when session unstarted',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
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

      final chip21 = find.widgetWithText(ChoiceChip, '21');
      await tester.ensureVisible(chip21);
      await tester.tap(chip21);
      await tester.pumpAndSettle();

      expect(audioState.targetRepetitions, equals(21));
    });

    testWidgets('Tapping target chip with active progress prompts confirmation and preserves count',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
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

      // Tap manual chant bead (+1) twice
      final tapButton = find.textContaining('TAP TO COUNT BEAD');
      await tester.ensureVisible(tapButton);
      await tester.tap(tapButton);
      await tester.pump();
      await tester.tap(tapButton);
      await tester.pump();
      expect(audioState.completedRepetitions, equals(2));

      // Tap 54 chip
      final chip54 = find.widgetWithText(ChoiceChip, '54');
      await tester.ensureVisible(chip54);
      await tester.tap(chip54);
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.text('Adjust Japa Target?'), findsOneWidget);
      expect(find.textContaining('Completed: 2 repetitions'), findsOneWidget);
      expect(find.textContaining('Completed repetitions will NOT be reset or lost.'), findsOneWidget);

      // Confirm target adjustment
      final updateBtn = find.widgetWithText(ElevatedButton, 'Update Target');
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      expect(audioState.targetRepetitions, equals(54));
      expect(audioState.completedRepetitions, equals(2)); // preserved!
    });

    testWidgets('Tapping Change Target opens JapaTargetModal with presets and auto-pause toggle',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
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

      final changeBtn = find.widgetWithText(TextButton, 'Change');
      await tester.ensureVisible(changeBtn);
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      expect(find.byType(JapaTargetModal), findsOneWidget);
      expect(find.text('Chanting Target (Japa Target)'), findsOneWidget);
      expect(find.text('TRADITIONAL PRESETS'), findsOneWidget);
      expect(find.text('Half Mala'), findsOneWidget);
      expect(find.text('One Mala'), findsOneWidget);
      expect(find.text('Auto-pause audio at target completion'), findsOneWidget);
    });

    testWidgets('VisualMalaWidget adapts accurately for 27, 108, and large target 1008',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Target 27 (Quarter Mala)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VisualMalaWidget(
              completedCount: 5,
              targetCount: 27,
              isPlaying: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Quarter Mala (27 Beads)'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('27'), findsOneWidget);

      // Target 1008 (Large Target with Mala Cycle & Milestones)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VisualMalaWidget(
              completedCount: 150,
              targetCount: 1008,
              isPlaying: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1008 Repetitions • Sahasra Japa Mahotsava'), findsOneWidget);
      expect(find.textContaining('Mala 2 of 10'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('1008'), findsOneWidget);
    });

    testWidgets('JapaCompletionDialog displays sacred completion and handles Continue Chanting',
        (WidgetTester tester) async {
      audioState.setTargetRepetitions(11);
      for (int i = 0; i < 11; i++) {
        audioState.incrementManualRepetition();
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: JapaCompletionDialog(
              audioState: audioState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('॥ जप पूर्णम् ॥'), findsOneWidget);
      expect(find.text('Japa Sadhana Completed'), findsOneWidget);
      expect(find.text('Finish Session'), findsOneWidget);
      expect(find.text('Continue Chanting'), findsOneWidget);

      // Tap Continue Chanting
      await tester.tap(find.text('Continue Chanting'));
      await tester.pumpAndSettle();

      expect(audioState.isContinuingBeyondTarget, isTrue);
      expect(audioState.completedRepetitions, equals(11));
    });
  });
}
