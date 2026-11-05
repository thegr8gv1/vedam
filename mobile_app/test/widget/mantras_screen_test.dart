import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/presentation/screens/mantras/mantras_screen.dart';
import 'package:vedam_app/state/audio_state.dart';

import '../unit/audio_state_and_japa_test.dart';

void main() {
  group('MantrasScreen Widget Tests', () {
    late MantraRepository repository;
    late MockAudioPlaybackService mockAudio;
    late AudioState audioState;

    setUp(() {
      repository = MantraRepositoryImpl();
      mockAudio = MockAudioPlaybackService();
      audioState = AudioState(audioService: mockAudio);
    });

    tearDown(() {
      audioState.dispose();
    });

    testWidgets('Renders search bar, filter chips, and 455 mantra cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantrasScreen(
            repository: repository,
            audioState: audioState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mantra Library & Japa'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Offline Ready'), findsOneWidget);
      expect(find.text('455 Sacred Mantras Available'), findsOneWidget);

      // Search functionality
      await tester.enterText(find.byType(TextField), 'Mrityunjaya');
      await tester.pumpAndSettle();

      expect(find.textContaining('Mrityunjaya'), findsWidgets);
    });

    testWidgets('Offline Ready toggle filters to 31 bundled audio recordings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantrasScreen(
            repository: repository,
            audioState: audioState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Offline Ready chip
      await tester.tap(find.text('Offline Ready'));
      await tester.pumpAndSettle();

      expect(find.text('31 Sacred Mantras Available'), findsOneWidget);
    });
  });
}
