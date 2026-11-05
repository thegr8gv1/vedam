import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/vrat/reminders_settings_screen.dart';
import 'package:vedam_app/presentation/screens/vrat/vrat_calendar_screen.dart';
import 'package:vedam_app/presentation/screens/vrat/vrat_detail_screen.dart';
import 'package:vedam_app/state/vrat_state.dart';

void main() {
  group('Vrat & Observance Screens Widget Tests', () {
    late SharedPreferences prefs;
    late MockReminderService mockReminderService;
    late VratState vratState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockReminderService = MockReminderService();
      vratState = VratState(prefs: prefs, reminderService: mockReminderService);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    testWidgets('VratCalendarScreen renders informational banner, filter chips, and observances',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VratCalendarScreen(
            vratState: vratState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Header & Informational Banner
      expect(find.text('Personal Vrat & Observances'), findsOneWidget);
      expect(find.textContaining('Personal Devotional Planner:'), findsOneWidget);

      // 2. Verify Filter Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Ekadashi'), findsOneWidget);
      expect(find.text('Pradosham'), findsOneWidget);
      expect(find.text('Purnima'), findsOneWidget);

      // 3. Verify Seed Observance Card
      expect(find.text('Ekadashi Devotional Vrat'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);

      // 4. Verify Plan Observance FAB
      expect(find.text('Plan Observance'), findsOneWidget);
    });

    testWidgets('VratDetailScreen renders details, checklist, and allows status changes',
        (WidgetTester tester) async {
      final obs = vratState.observances.first;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VratDetailScreen(
            observanceId: obs.id,
            vratState: vratState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Title and Details
      expect(find.text('Observance Details'), findsOneWidget);
      expect(find.text('Ekadashi Devotional Vrat'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);

      // 2. Verify Panchangam Information or Fallback
      expect(find.text('ASTRONOMICAL PANCHANGAM'), findsOneWidget);

      // 3. Verify Preparation Checklist
      expect(find.textContaining('PREPARATION CHECKLIST'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsWidgets);

      // Tap first checklist checkbox
      final firstCheckbox = find.byType(CheckboxListTile).first;
      await tester.ensureVisible(firstCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      // 4. Verify Associated Guided Puja Card
      expect(find.text('ASSOCIATED GUIDED PUJA'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
    });

    testWidgets('RemindersSettingsScreen renders permission card, list, and switch',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: RemindersSettingsScreen(
            vratState: vratState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify App Bar & Privacy Notice
      expect(find.text('Devotional Reminders'), findsOneWidget);
      expect(find.textContaining('strictly locally'), findsOneWidget);

      // 2. Verify Configured Reminders Header
      expect(find.text('CONFIGURED REMINDERS'), findsOneWidget);
      expect(find.text('Prātah Sadhana'), findsOneWidget);
      expect(find.text('Sandhyā Dīpa Prayer'), findsOneWidget);

      // 3. Verify Switches
      expect(find.byType(Switch), findsWidgets);
    });
  });
}
