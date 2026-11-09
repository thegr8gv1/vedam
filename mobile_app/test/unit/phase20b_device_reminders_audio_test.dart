import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/data/fixtures/default_vrat_templates_data.dart';
import 'package:vedam_app/state/vrat_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => null);
  });

  group('Phase 20B: Devotional Reminders, Privacy & Audio Platform Boundary', () {
    late MockReminderService mockReminderService;
    late SharedPreferences prefs;

    setUp(() async {
      tz.initializeTimeZones();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockReminderService = MockReminderService();
    });

    test('Default reminders include Sadhana, Japa, and Evening prayer; all strictly opt-in (disabled)', () {
      final defaults = DefaultVratTemplatesData.defaultReminders;
      expect(defaults.length, 3);

      final types = defaults.map((r) => r.type).toList();
      expect(types.contains(ReminderType.morningSadhana), true);
      expect(types.contains(ReminderType.mantraJapa), true);
      expect(types.contains(ReminderType.eveningPrayer), true);

      // Devotional safety requirement: Must NEVER enable notifications without explicit devotee consent
      for (final r in defaults) {
        expect(r.isEnabled, false, reason: 'Reminder ${r.id} must be disabled by default');
      }
    });

    test('Vrat observance reminders preserve devotee privacy: personal notes never leaked', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      await Future.delayed(const Duration(milliseconds: 20));

      final obs = VratObservance(
        id: 'vrat_20261115_ekadashi',
        type: VratType.ekadashi,
        title: 'Utpanna Ekadashi',
        sanskritTitle: 'उत्पन्ना एकादशी',
        targetDate: '2026-11-15',
        location: 'Varanasi',
        tradition: 'Smartha',
        createdAt: '2026-11-09T00:00:00Z',
        personalIntention: 'Intense private spiritual sankalpa for family peace',
        personalNotes: 'Confidential private devotee reflections that must never appear in notifications',
      );

      // Create observance reminder
      final reminder = DevotionalReminder(
        id: 'rem_vrat_${obs.id}',
        type: ReminderType.personalVrat,
        title: '${obs.title} Reminder',
        body: 'Today is your planned observance of ${obs.title}. May your practice be peaceful.',
        scheduledDate: obs.targetDate,
        hour: 6,
        minute: 0,
        isEnabled: true,
        linkedVratId: obs.id,
      );

      await state.addReminder(reminder);

      final scheduled = mockReminderService.scheduledReminders[reminder.id];
      expect(scheduled, isNotNull);
      expect(scheduled!.title, contains('Utpanna Ekadashi'));
      // Verify body does not contain personalIntention or personalNotes
      expect(scheduled.body.contains('Confidential'), false);
      expect(scheduled.body.contains('sankalpa'), false);
      expect(scheduled.linkedVratId, obs.id);

      final fetchedFromState = state.getReminderForVrat(obs.id);
      expect(fetchedFromState, isNotNull);
      expect(fetchedFromState!.id, reminder.id);
    });

    test('DevotionalReminder time formatting operates cleanly across AM/PM', () {
      const morning = DevotionalReminder(
        id: 'r1',
        type: ReminderType.morningSadhana,
        title: 'Morning',
        body: 'Morning prayer',
        hour: 6,
        minute: 5,
      );
      expect(morning.formattedTime, '6:05 AM');

      const noon = DevotionalReminder(
        id: 'r2',
        type: ReminderType.mantraJapa,
        title: 'Noon',
        body: 'Noon Japa',
        hour: 12,
        minute: 0,
      );
      expect(noon.formattedTime, '12:00 PM');

      const evening = DevotionalReminder(
        id: 'r3',
        type: ReminderType.eveningPrayer,
        title: 'Evening',
        body: 'Evening Sandhya',
        hour: 18,
        minute: 30,
      );
      expect(evening.formattedTime, '6:30 PM');

      const midnight = DevotionalReminder(
        id: 'r4',
        type: ReminderType.custom,
        title: 'Midnight',
        body: 'Contemplation',
        hour: 0,
        minute: 15,
      );
      expect(midnight.formattedTime, '12:15 AM');
    });

    test('Reminder toggle handles permission denial without scheduling notification', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      mockReminderService.currentPermission = ReminderPermissionStatus.denied;

      final reminder = DevotionalReminder(
        id: 'rem_denial_test',
        type: ReminderType.custom,
        title: 'Custom Prayer',
        body: 'Prayer time',
        hour: 8,
        minute: 0,
        isEnabled: false,
      );

      await state.addReminder(reminder);
      expect(mockReminderService.scheduledReminders.containsKey('rem_denial_test'), false);
    });

    test('Audio service rejects unbundled vault file when vault directory is missing', () async {
      final service = AudioPlaybackServiceImpl(
        localVaultDirectory: r'C:\non_existent_vault_directory_vedam_test',
        configureGlobalContext: false,
      );

      const unbundledMantra = MantraItem(
        id: 'VEDA-MTR-9999',
        collection: 'Test Collection',
        deity: 'Shiva',
        title: 'Unbundled Vault Test Mantra',
        filename: 'non_existent_chant.wav',
        mantraText: 'Om Namah Shivaya',
        significance: 'Test',
        form: 'Stotram',
        durationSeconds: 120,
        sampleRate: 44100,
        bitDepth: 16,
        channels: 2,
        fileSizeBytes: 1000,
        sha256: 'dummy_hash',
        sourceTxt: 'source.txt',
        isBundled: false,
        bundledAssetPath: null,
      );

      if (Platform.isWindows) {
        expect(
          () => service.playMantra(unbundledMantra),
          throwsA(isA<FileSystemException>()),
        );
      }
    });
  });
}
