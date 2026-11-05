import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';

import '../unit/audio_state_and_japa_test.dart';

void main() {
  group('MantraPlayerScreen & VisualMala Widget Tests', () {
    late MockAudioPlaybackService mockAudio;
    late AudioState audioState;
    late MantraItem sampleMantra;

    setUp(() {
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
      tester.view.physicalSize = const Size(800, 1200);
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

      // Repeat mode chips exist
      expect(find.widgetWithText(ChoiceChip, '1'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '11'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '108'), findsOneWidget);

      // Play/Pause button
      expect(find.byIcon(Icons.pause), findsOneWidget); // Plays automatically on entry
    });

    testWidgets('Tapping repeat mode chip updates target repetitions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
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
  });
}
