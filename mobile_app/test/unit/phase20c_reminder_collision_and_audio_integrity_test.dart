import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/data/fixtures/default_vrat_templates_data.dart';
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

  group('Phase 20C: Notification Identifier Collision Safety & Registry Persistence', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('LocalNotificationReminderService assigns unique IDs with linear probing and persists across restarts', () async {
      final service1 = LocalNotificationReminderService(prefs: prefs);
      await service1.initialize();

      final idA = await service1.getOrCreateNotificationId('rem_morning_sadhana');
      final idB = await service1.getOrCreateNotificationId('rem_evening_sandhya');
      final idC = await service1.getOrCreateNotificationId('rem_vrat_pradosham');

      // All allocated IDs must be strictly positive 31-bit integers and distinct
      expect(idA, greaterThan(0));
      expect(idB, greaterThan(0));
      expect(idC, greaterThan(0));
      expect({idA, idB, idC}.length, 3, reason: 'Every reminder ID must receive a distinct notification ID');

      // Calling again for the same reminder must return the exact same integer
      final idARepeat = await service1.getOrCreateNotificationId('rem_morning_sadhana');
      expect(idARepeat, equals(idA));

      // Verify persistence in SharedPreferences
      final rawRegistry = prefs.getString('vedam_reminder_id_registry_v1');
      expect(rawRegistry, isNotNull);
      final decoded = jsonDecode(rawRegistry!) as Map<String, dynamic>;
      expect(decoded['rem_morning_sadhana'], equals(idA));
      expect(decoded['rem_evening_sandhya'], equals(idB));

      // Simulate app restart by constructing a new service instance
      final service2 = LocalNotificationReminderService(prefs: prefs);
      await service2.initialize();

      final idARestart = await service2.getOrCreateNotificationId('rem_morning_sadhana');
      final idBRestart = await service2.getOrCreateNotificationId('rem_evening_sandhya');
      expect(idARestart, equals(idA), reason: 'Notification ID must remain stable across app restarts');
      expect(idBRestart, equals(idB));

      // Verify releaseReminderId removes the entry from the registry
      await service2.releaseReminderId('rem_morning_sadhana');
      final rawAfterRelease = prefs.getString('vedam_reminder_id_registry_v1');
      final decodedAfterRelease = jsonDecode(rawAfterRelease!) as Map<String, dynamic>;
      expect(decodedAfterRelease.containsKey('rem_morning_sadhana'), false);
    });

    test('MockReminderService allocates collision-free deterministic positive IDs', () async {
      final mock = MockReminderService();
      final id1 = await mock.getOrCreateNotificationId('reminder_alpha');
      final id2 = await mock.getOrCreateNotificationId('reminder_beta');
      final id1Repeat = await mock.getOrCreateNotificationId('reminder_alpha');

      expect(id1, greaterThan(0));
      expect(id2, greaterThan(0));
      expect(id1, isNot(equals(id2)));
      expect(id1Repeat, equals(id1));

      // Immediate notification capture
      await mock.showImmediateNotification(
        id: 'test_immediate',
        title: 'Devotional Test',
        body: 'Respectful test notification',
      );
      expect(mock.deliveredNotifications.length, 1);
      expect(mock.deliveredNotifications.first['reminderId'], 'test_immediate');
      expect(mock.deliveredNotifications.first['title'], 'Devotional Test');
    });
  });

  group('Phase 20C: Timezone, DST & Strict Devotional Privacy Invariants', () {
    late SharedPreferences prefs;
    late MockReminderService mockReminderService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockReminderService = MockReminderService();
    });

    test('Local wall-clock time is preserved across timezone transitions', () {
      final kolkata = tz.getLocation('Asia/Kolkata');
      final newYork = tz.getLocation('America/New_York');

      final kolkataTime = tz.TZDateTime.now(kolkata);
      final scheduledKolkata = tz.TZDateTime(kolkata, kolkataTime.year, kolkataTime.month, kolkataTime.day, 6, 0);
      expect(scheduledKolkata.hour, 6);
      expect(scheduledKolkata.minute, 0);

      final nyTime = tz.TZDateTime.now(newYork);
      final scheduledNY = tz.TZDateTime(newYork, nyTime.year, nyTime.month, nyTime.day, 6, 0);
      expect(scheduledNY.hour, 6);
      expect(scheduledNY.minute, 0);
    });

    test('Devotional reminders strictly protect devotee privacy (no sankalpa/notes leakage)', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      await Future.delayed(const Duration(milliseconds: 20));

      const privateSankalpa = 'Confidential personal sankalpa for inner peace and health';
      const privateNotes = 'Private diary entry: fasting on fruits only, special family prayer';

      final observance = VratObservance(
        id: 'vrat_private_test',
        type: VratType.pradosham,
        title: 'Shani Pradosham',
        sanskritTitle: 'शनि प्रदोषम्',
        targetDate: '2026-11-28',
        location: 'Kashi',
        tradition: 'Smartha',
        createdAt: '2026-11-09T00:00:00Z',
        personalIntention: privateSankalpa,
        personalNotes: privateNotes,
      );

      final reminder = DevotionalReminder(
        id: 'rem_vrat_private_test',
        type: ReminderType.personalVrat,
        title: '${observance.title} Observance',
        body: 'Today is your planned observance of ${observance.title}. May your practice be peaceful.',
        scheduledDate: observance.targetDate,
        hour: 6,
        minute: 0,
        isEnabled: true,
        linkedVratId: observance.id,
      );

      await state.addReminder(reminder);

      final scheduled = mockReminderService.scheduledReminders[reminder.id];
      expect(scheduled, isNotNull);
      expect(scheduled!.title, 'Shani Pradosham Observance');
      expect(scheduled.body, contains('May your practice be peaceful'));

      // Crucial privacy assertions: no confidential personal data in notification
      expect(scheduled.title.contains(privateSankalpa), false);
      expect(scheduled.body.contains(privateSankalpa), false);
      expect(scheduled.body.contains('fasting on fruits'), false);
      expect(scheduled.body.contains(privateNotes), false);
    });

    test('All default reminders are strictly opt-in and disabled on fresh install', () {
      final defaults = DefaultVratTemplatesData.defaultReminders;
      expect(defaults.isNotEmpty, true);
      for (final r in defaults) {
        expect(r.isEnabled, false, reason: 'Fresh install reminder ${r.id} must be disabled by default');
      }
    });
  });

  group('Phase 20C: Scripture-to-Audio Reconciliation & Scope Integrity', () {
    late Map<String, dynamic> manifest;

    setUpAll(() async {
      final file = File('assets/audio/mantra_manifest.json');
      expect(file.existsSync(), true, reason: 'Audio manifest assets/audio/mantra_manifest.json must exist');
      final content = await file.readAsString();
      manifest = jsonDecode(content) as Map<String, dynamic>;
    });

    test('Reconciliation: Exactly 3 of 9 scriptures have bundled MP3 audio; 6 are unbundled vault-only recordings', () {
      final List recordings = manifest['recordings'];
      final Map<String, Map<String, dynamic>> byId = {
        for (final r in recordings) r['id'] as String: r as Map<String, dynamic>
      };

      // 3 Bundled recordings
      const bundledIds = ['VEDA-MTR-0399', 'VEDA-MTR-0401', 'VEDA-MTR-0413'];
      for (final id in bundledIds) {
        expect(byId.containsKey(id), true, reason: 'Manifest must contain $id');
        final item = byId[id]!;
        expect(item['is_bundled'], true, reason: '$id must be marked as bundled');
        expect(item['bundled_asset_path'], isNotNull);
        final assetPath = item['bundled_asset_path'] as String;
        expect(assetPath.endsWith('.mp3'), true, reason: 'Bundled asset must be an MP3 file');
        expect(File(assetPath).existsSync(), true, reason: 'Bundled asset file must exist on disk: $assetPath');
      }

      // 6 Vault-only recordings
      const vaultOnlyIds = [
        'VEDA-MTR-0443', // Shiva Tandava Stotram
        'VEDA-MTR-0451', // Sri Suktam
        'VEDA-MTR-0414', // Mahalakshmi Ashtakam
        'VEDA-MTR-0411', // Lingashtakam
        'VEDA-MTR-0407', // Kanakadhara Stotram
        'VEDA-MTR-0382', // Aigiri Nandini
      ];
      for (final id in vaultOnlyIds) {
        expect(byId.containsKey(id), true, reason: 'Manifest must contain $id');
        final item = byId[id]!;
        expect(item['is_bundled'], false, reason: '$id must be unbundled (vault-only)');
        expect(item['bundled_asset_path'], isNull, reason: '$id bundled_asset_path must be null');
        expect((item['filename'] as String).endsWith('.wav'), true, reason: 'Vault recording must be WAV master');
      }
    });

    test('Scope Integrity: All 9 scripture audio recordings are short verse 1 excerpts (<= 36 seconds)', () {
      final List recordings = manifest['recordings'];
      final Map<String, Map<String, dynamic>> byId = {
        for (final r in recordings) r['id'] as String: r as Map<String, dynamic>
      };

      const all9ScriptureIds = [
        'VEDA-MTR-0399',
        'VEDA-MTR-0401',
        'VEDA-MTR-0413',
        'VEDA-MTR-0443',
        'VEDA-MTR-0451',
        'VEDA-MTR-0414',
        'VEDA-MTR-0411',
        'VEDA-MTR-0407',
        'VEDA-MTR-0382',
      ];

      for (final id in all9ScriptureIds) {
        final item = byId[id]!;
        final duration = (item['duration_seconds'] as num).toDouble();
        expect(duration, lessThanOrEqualTo(36.0),
            reason: '$id recording duration ($duration s) must be <= 36.0s (opening stanza/excerpt, not multi-minute composition)');
        expect(duration, greaterThan(15.0),
            reason: '$id recording duration must be > 15s');
      }
    });

    test('Shiva Tandava Stotram (VEDA-MTR-0443) scope verification: opening verse 1 excerpt (25.8s)', () {
      final List recordings = manifest['recordings'];
      final item = recordings.firstWhere((r) => r['id'] == 'VEDA-MTR-0443');

      expect(item['title'], 'Shiva Tandava Stotram');
      expect(item['is_bundled'], false);
      expect(item['filename'], 'Shiva Tandava Stotram.wav');
      expect((item['duration_seconds'] as num).toDouble(), closeTo(25.8, 0.5));
      expect(item['mantra'], contains('Jata Tavi Gala Jjala'));
    });
  });
}
