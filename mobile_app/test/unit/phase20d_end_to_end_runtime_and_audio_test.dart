import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/state/vrat_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => null,
    );
  });

  group('Phase 20D: Identifier Registry Concurrency, Safety & Corruption Resilience', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Concurrent overlapping allocation requests are serialized without collisions', () async {
      final service = LocalNotificationReminderService(prefs: prefs);
      await service.initialize();

      // Launch 15 concurrent allocation requests simultaneously
      final futures = List.generate(15, (index) => service.getOrCreateNotificationId('rem_concurrent_$index'));
      final results = await Future.wait(futures);

      expect(results.length, 15);
      for (final id in results) {
        expect(id, greaterThan(0), reason: 'Every allocated ID must be a positive 31-bit integer');
      }
      expect(results.toSet().length, 15, reason: 'All 15 concurrent requests must receive distinct notification IDs');

      // Check persisted registry in SharedPreferences
      final raw = prefs.getString('vedam_reminder_id_registry_v1');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded.length, 15);
    });

    test('Registry corruption or invalid JSON in SharedPreferences recovers gracefully', () async {
      // Simulate corrupted data written to prefs
      await prefs.setString('vedam_reminder_id_registry_v1', 'CORRUPTED_{INVALID_JSON}:[null]');

      final service = LocalNotificationReminderService(prefs: prefs);
      // initialize should not throw and should safely reset corrupted registry
      await service.initialize();

      final newId = await service.getOrCreateNotificationId('rem_after_corruption');
      expect(newId, greaterThan(0));

      final raw = prefs.getString('vedam_reminder_id_registry_v1');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['rem_after_corruption'], equals(newId));
    });

    test('Releasing one reminder ID preserves all other allocated mappings intact', () async {
      final service = LocalNotificationReminderService(prefs: prefs);
      await service.initialize();

      final idA = await service.getOrCreateNotificationId('rem_keep_1');
      final idB = await service.getOrCreateNotificationId('rem_delete_target');
      final idC = await service.getOrCreateNotificationId('rem_keep_2');

      expect({idA, idB, idC}.length, 3);

      await service.releaseReminderId('rem_delete_target');

      // idA and idC must remain mapped to their original values
      final idARefetch = await service.getOrCreateNotificationId('rem_keep_1');
      final idCRefetch = await service.getOrCreateNotificationId('rem_keep_2');
      expect(idARefetch, equals(idA));
      expect(idCRefetch, equals(idC));

      final raw = prefs.getString('vedam_reminder_id_registry_v1');
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded.containsKey('rem_delete_target'), false);
      expect(decoded['rem_keep_1'], equals(idA));
      expect(decoded['rem_keep_2'], equals(idC));
    });
  });

  group('Phase 20D: End-to-End Reminder Scheduling & Devotee Privacy Invariants', () {
    late SharedPreferences prefs;
    late MockReminderService mockReminderService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockReminderService = MockReminderService();
    });

    test('Permission denial strictly prevents reminder activation and scheduling', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      mockReminderService.currentPermission = ReminderPermissionStatus.denied;

      final reminder = DevotionalReminder(
        id: 'denied_rem_test',
        type: ReminderType.mantraJapa,
        title: 'Japa Reminder',
        body: 'Time for sacred chanting',
        hour: 12,
        minute: 0,
        isEnabled: false,
      );

      await state.addReminder(reminder);
      await state.toggleReminder(reminder.id, true);

      // Verify state was not enabled due to permission denial
      final stored = state.getReminderById(reminder.id);
      expect(stored!.isEnabled, false, reason: 'Reminder must remain disabled when permission is denied');
      expect(mockReminderService.scheduledReminders.containsKey(reminder.id), false);
    });

    test('Vrat-specific reminder preserves target date without leaking confidential notes', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      mockReminderService.currentPermission = ReminderPermissionStatus.granted;

      final obs = VratObservance(
        id: 'obs_pradosham_nov2026',
        type: VratType.pradosham,
        title: 'Shani Pradosham',
        sanskritTitle: 'शनि प्रदोषम्',
        targetDate: '2026-11-28',
        location: 'Varanasi',
        tradition: 'Smartha',
        createdAt: '2026-11-09T00:00:00Z',
        personalIntention: 'Confidential devotee sankalpa for inner peace',
        personalNotes: 'Private medical & dietary notes: strict water fast',
      );

      final reminder = DevotionalReminder(
        id: 'rem_obs_pradosham_nov2026',
        type: ReminderType.personalVrat,
        title: '${obs.title} Observance',
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
      expect(scheduled!.scheduledDate, '2026-11-28');
      expect(scheduled.title, 'Shani Pradosham Observance');
      // Devotee Privacy Verification:
      expect(scheduled.body.contains('Confidential'), false);
      expect(scheduled.body.contains('sankalpa'), false);
      expect(scheduled.body.contains('water fast'), false);
      expect(scheduled.body.contains('medical'), false);
    });
  });

  group('Phase 20D: Bundled Audio Inventory & Platform Boundary Enforcement', () {
    test('Assets directory contains exactly 31 bundled MP3 files and 0 WAV files', () {
      final bundledDir = Directory('assets/audio/bundled');
      expect(bundledDir.existsSync(), true, reason: 'assets/audio/bundled directory must exist');

      final files = bundledDir.listSync().whereType<File>().toList();
      expect(files.length, 31, reason: 'Bundled audio catalog must contain exactly 31 files');

      for (final f in files) {
        expect(f.path.endsWith('.mp3'), true, reason: 'All bundled audio files must be .mp3 (found: ${f.path})');
        expect(f.path.endsWith('.wav'), false, reason: 'No .wav files can be bundled in mobile assets');
      }
    });

    test('All 3 bundled scripture tracks exist on disk with valid file size (> 50KB)', () {
      final tracks = [
        'assets/audio/bundled/gayatri_mantra.mp3',
        'assets/audio/bundled/hanuman_chalisa.mp3',
        'assets/audio/bundled/maha_mrityunjaya_mantra.mp3',
      ];

      for (final track in tracks) {
        final f = File(track);
        expect(f.existsSync(), true, reason: '$track must exist on disk');
        expect(f.lengthSync(), greaterThan(50000), reason: '$track must be non-empty valid MP3');
      }
    });
  });
}
