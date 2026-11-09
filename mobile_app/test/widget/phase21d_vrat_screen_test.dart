import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/fixtures/default_vrat_templates_data.dart';
import 'package:vedam_app/presentation/screens/vrat/add_edit_vrat_modal.dart';
import 'package:vedam_app/presentation/screens/vrat/vrat_calendar_screen.dart';
import 'package:vedam_app/presentation/screens/vrat/vrat_detail_screen.dart';
import 'package:vedam_app/state/vrat_state.dart';

class MockReminderService implements ReminderService {
  final List<DevotionalReminder> scheduledReminders = [];
  final List<String> cancelledIds = [];
  ReminderPermissionStatus currentStatus = ReminderPermissionStatus.granted;

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async => currentStatus;

  @override
  Future<ReminderPermissionStatus> requestPermission() async => currentStatus;

  @override
  Future<int> getOrCreateNotificationId(String id) async => id.hashCode.abs() % 2147483647;

  @override
  Future<void> releaseReminderId(String reminderId) async {
    cancelledIds.add(reminderId);
  }

  @override
  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<bool> scheduleReminder(DevotionalReminder reminder) async {
    scheduledReminders.removeWhere((r) => r.id == reminder.id);
    scheduledReminders.add(reminder);
    return true;
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    cancelledIds.add(reminderId);
    scheduledReminders.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<void> cancelAllReminders() async {
    scheduledReminders.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async => [];

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MockReminderService mockReminderService;
  late VratState vratState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockReminderService = MockReminderService();
    vratState = VratState(prefs: prefs, reminderService: mockReminderService);
    await pumpEventQueue();
  });

  Widget buildTestApp(Widget child, {double textScaleFactor = 1.0, Size? surfaceSize}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize ?? const Size(800, 1200),
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: child,
      ),
    );
  }

  group('Phase 21D: Vrat Observance UI & Screen Widget Tests', () {
    testWidgets('1. VratCalendarScreen renders fasting safety guidance, all 8 category chips, and badges',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(VratCalendarScreen(vratState: vratState)));
      await tester.pumpAndSettle();

      // Verify Header & Fasting Safety Banner
      expect(find.text('Personal Vrat & Observances'), findsOneWidget);
      expect(find.text('DEVOTIONAL PLANNING & FASTING GUIDANCE'), findsOneWidget);
      expect(find.textContaining('Personal Devotional Planner:'), findsOneWidget);
      expect(find.textContaining('strictly optional'), findsOneWidget);

      // Verify Category Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Ekadashi'), findsOneWidget);
      expect(find.text('Pradosham'), findsOneWidget);
      expect(find.text('Purnima'), findsOneWidget);
      expect(find.text('Amavasya'), findsOneWidget);
      expect(find.text('Sankashti'), findsOneWidget);
      expect(find.text('Shivaratri'), findsOneWidget);
      expect(find.text('Navaratri'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Verify seed observance card with provenance badge
      expect(find.text('Ekadashi Devotional Vrat'), findsOneWidget);
      expect(find.text('TRADITIONAL CALENDAR'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);
    });

    testWidgets('2. VratCalendarScreen filter chips switch visible categories and handles empty states',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(VratCalendarScreen(vratState: vratState)));
      await tester.pumpAndSettle();

      // Seed observance is Ekadashi, so selecting Pradosham filter shows empty state
      await tester.tap(find.text('Pradosham'));
      await tester.pumpAndSettle();

      expect(find.text('Ekadashi Devotional Vrat'), findsNothing);
      expect(find.text('No upcoming observances planned.'), findsOneWidget);

      // Selecting All restores the card
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Ekadashi Devotional Vrat'), findsOneWidget);
    });

    testWidgets('3. VratCalendarScreen displays past history and clears history with confirmation',
        (WidgetTester tester) async {
      // Add a completed past observance using tester.runAsync
      final pastObs = DefaultVratTemplatesData.createTemplate(
        VratType.purnima,
        targetDate: '2026-10-15',
        location: 'Varanasi',
      ).copyWith(status: ObservanceStatus.completed, completedAt: '2026-10-15T20:00:00Z');
      await tester.runAsync(() async {
        await vratState.addObservance(pastObs);
      });

      await tester.pumpWidget(buildTestApp(VratCalendarScreen(vratState: vratState)));
      await tester.pumpAndSettle();

      expect(find.textContaining('PAST DEVOTIONAL HISTORY'), findsOneWidget);
      expect(find.text('Clear History'), findsOneWidget);
      expect(find.text('Purnima Gratitude & Adoration'), findsOneWidget);

      // Tap Clear History button
      final clearBtn = find.text('Clear History');
      await tester.ensureVisible(clearBtn);
      await tester.pumpAndSettle();
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('Clear Observance History?'), findsOneWidget);

      // Confirm dialog
      await tester.tap(find.text('CLEAR HISTORY'));
      await tester.pumpAndSettle();

      // Past history section is gone, but active Ekadashi remains
      expect(find.textContaining('PAST DEVOTIONAL HISTORY'), findsNothing);
      expect(find.text('Purnima Gratitude & Adoration'), findsNothing);
      expect(find.text('Ekadashi Devotional Vrat'), findsOneWidget);
    });

    testWidgets('4. VratDetailScreen renders health advisory, choice chips, and compassionate skip note',
        (WidgetTester tester) async {
      final obs = vratState.observances.first;

      await tester.pumpWidget(
        buildTestApp(VratDetailScreen(
          observanceId: obs.id,
          vratState: vratState,
        )),
      );
      await tester.pumpAndSettle();

      // 1. Fasting health advisory banner
      expect(find.text('TRADITIONAL FASTING & HEALTH ADVISORY'), findsOneWidget);
      expect(find.text(obs.fastingNotice), findsOneWidget);

      // 2. Choice chips
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);

      // 3. Tap 'Skipped' choice chip
      await tester.tap(find.text('Skipped'));
      await tester.pumpAndSettle();

      expect(vratState.getObservanceById(obs.id)!.status, ObservanceStatus.skipped);
      expect(find.textContaining('Devotee Comfort Note: Skipping or postponing'), findsOneWidget);

      // 4. Tap 'Completed' choice chip
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(vratState.getObservanceById(obs.id)!.status, ObservanceStatus.completed);
      expect(vratState.getObservanceById(obs.id)!.completedAt, isNotNull);
    });

    testWidgets('5. AddEditVratModal shows all types and saves personal observance as isManuallyCreated',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AddEditVratModal.show(
                  context: ctx,
                  vratState: vratState,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Plan Personal Observance'), findsOneWidget);
      expect(find.text('Shivaratri'), findsOneWidget);
      expect(find.text('Navaratri'), findsOneWidget);

      // Select Shivaratri
      await tester.tap(find.text('Shivaratri'));
      await tester.pumpAndSettle();

      expect(find.text('Masa Shivaratri Adoration'), findsOneWidget);

      // Save observance
      final saveBtn = find.text('SAVE OBSERVANCE');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      final added = vratState.observances.firstWhere((o) => o.type == VratType.monthlyShivaratri);
      expect(added.isManuallyCreated, true);
      expect(added.title, 'Masa Shivaratri Adoration');
    });

    testWidgets('6. Compact 360x640dp viewport with 1.35x font scaling renders without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Test Calendar Screen at 1.35x scale
      await tester.pumpWidget(
        buildTestApp(
          VratCalendarScreen(vratState: vratState),
          textScaleFactor: 1.35,
          surfaceSize: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      final ex1 = tester.takeException();
      expect(ex1, isNull);
      expect(find.text('Personal Vrat & Observances'), findsOneWidget);

      // Test Detail Screen at 1.35x scale
      final obs = vratState.observances.first;
      await tester.pumpWidget(
        buildTestApp(
          VratDetailScreen(observanceId: obs.id, vratState: vratState),
          textScaleFactor: 1.35,
          surfaceSize: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      final ex = tester.takeException();
      expect(ex, isNull);
      expect(find.text('Observance Details'), findsOneWidget);
    });
  });
}
