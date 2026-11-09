import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/presentation/screens/vrat/reminders_settings_screen.dart';
import 'package:vedam_app/presentation/screens/vrat/vrat_detail_screen.dart';
import 'package:vedam_app/state/vrat_state.dart';

void main() {
  group('Phase 20B Widget Tests: Devotional Reminders UI & Observance Integration', () {
    late MockReminderService mockReminderService;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockReminderService = MockReminderService();
    });

    testWidgets('VratDetailScreen renders Observance Reminder card and enables reminder on demand', (tester) async {
      final vratState = VratState(prefs: prefs, reminderService: mockReminderService);
      await tester.pumpAndSettle();

      final obs = VratObservance(
        id: 'vrat_test_pradosham',
        type: VratType.pradosham,
        title: 'Pradosha Vrat (Twilight Adoration)',
        sanskritTitle: 'प्रदोष व्रतम्',
        targetDate: '2026-11-20',
        location: 'Varanasi',
        tradition: 'Shaiva Grihya',
        createdAt: '2026-11-09T00:00:00Z',
        personalIntention: 'Inner peace',
      );
      await vratState.addObservance(obs);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: VratDetailScreen(
            observanceId: obs.id,
            vratState: vratState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Observance reminder card must be visible
      expect(find.text('OBSERVANCE REMINDER'), findsOneWidget);
      expect(find.text('Schedule Morning Observance Notification'), findsOneWidget);
      final setButton = find.text('SET REMINDER (6:00 AM)');
      expect(setButton, findsOneWidget);

      // Ensure button is visible before tapping
      await tester.ensureVisible(setButton);
      await tester.pumpAndSettle();
      await tester.tap(setButton);
      await tester.pumpAndSettle();

      // Reminder is now scheduled and switch is rendered
      expect(find.text('Scheduled for 6:00 AM'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(vratState.getReminderForVrat(obs.id), isNotNull);
      expect(mockReminderService.scheduledReminders.containsKey('rem_vrat_${obs.id}'), true);
    });

    testWidgets('RemindersSettingsScreen renders all 3 default reminders and custom dialog', (tester) async {
      final vratState = VratState(prefs: prefs, reminderService: mockReminderService);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: RemindersSettingsScreen(
            vratState: vratState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & permission banner
      expect(find.text('Devotional Reminders'), findsOneWidget);
      expect(find.text('Notification Permission Needed'), findsOneWidget);
      expect(find.text('CONFIGURED REMINDERS'), findsOneWidget);

      // Verify default reminder templates appear
      expect(find.text('Prātah Sadhana'), findsOneWidget);
      expect(find.text('Mantra Japa Practice'), findsOneWidget);
      expect(find.text('Sandhyā Dīpa Prayer'), findsOneWidget);

      // Tap Add Custom Reminder button
      final addCustomButton = find.text('Add Custom');
      expect(addCustomButton, findsOneWidget);
      await tester.tap(addCustomButton);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Add Custom Reminder'), findsOneWidget);
      expect(find.text('ADD REMINDER'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('Add Custom Reminder'), findsNothing);
    });
  });
}
