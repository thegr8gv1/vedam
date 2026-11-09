import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/services/reminder_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 20D Android Runtime: Real App Reminder Service & Real Audio Playback', () {
    testWidgets('1. Real LocalNotificationReminderService schedules, delivers immediate notif, and releases IDs', (tester) async {
      final reminderService = LocalNotificationReminderService();
      await reminderService.initialize();

      // Check permission status on device
      final permStatus = await reminderService.getPermissionStatus();
      expect(
        permStatus == ReminderPermissionStatus.granted || permStatus == ReminderPermissionStatus.denied,
        true,
        reason: 'Permission status on Android 13 must be determined',
      );

      // Concurrent ID allocation test on device
      final ids = await Future.wait([
        reminderService.getOrCreateNotificationId('devotee_rem_morning'),
        reminderService.getOrCreateNotificationId('devotee_rem_japa'),
        reminderService.getOrCreateNotificationId('devotee_rem_evening'),
      ]);

      expect(ids[0], greaterThan(0));
      expect(ids[1], greaterThan(0));
      expect(ids[2], greaterThan(0));
      expect(ids.toSet().length, 3, reason: 'Concurrent allocations must yield distinct positive integers');

      // Scheduling an actual Devotional Reminder through the app service
      const testReminder = DevotionalReminder(
        id: 'runtime_test_rem_1',
        type: ReminderType.morningSadhana,
        title: 'Morning Sadhana',
        body: 'Time for morning devotional recitation and prayer.',
        hour: 6,
        minute: 0,
        isEnabled: true,
      );

      await reminderService.scheduleReminder(testReminder);
      final notifId = await reminderService.getOrCreateNotificationId(testReminder.id);
      expect(notifId, greaterThan(0));

      // Deliver an actual notification directly through the FlutterLocalNotificationsPlugin
      await reminderService.showImmediateNotification(
        id: 'runtime_test_rem_1',
        title: 'Vedam Devotional Reminder',
        body: 'Time for prayer and peaceful reflection.',
      );

      // Allow OS notification delivery processing
      await tester.pump(const Duration(milliseconds: 500));

      // Clean up: cancel and release reminder
      await reminderService.cancelReminder(testReminder.id);
      await reminderService.releaseReminderId(testReminder.id);
    });

    testWidgets('2. Real AudioPlaybackServiceImpl plays bundled MP3s on Android device and rejects vault paths', (tester) async {
      final audioService = AudioPlaybackServiceImpl();

      // Test Mantra 1: Gayatri Mantra (VEDA-MTR-0399)
      const gayatri = MantraItem(
        id: 'VEDA-MTR-0399',
        collection: 'Surya',
        deity: 'Surya',
        title: 'Gayatri Mantra',
        filename: 'Gayatri Mantra.wav',
        mantraText: 'Om Bhur Bhuvah Svah...',
        significance: 'Vedic prayer for spiritual illumination',
        form: 'Vedic Suktam',
        durationSeconds: 18.95,
        sampleRate: 48000,
        bitDepth: 16,
        channels: 2,
        fileSizeBytes: 3638476,
        sha256: 'a1b2c3d4...',
        sourceTxt: 'Rigveda 3.62.10',
        isBundled: true,
        bundledAssetPath: 'assets/audio/bundled/gayatri_mantra.mp3',
      );

      await audioService.playMantra(gayatri);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(audioService.activeMantra?.id, 'VEDA-MTR-0399');
      // On real device, player transitions to playing
      expect(
        audioService.playerState == PlayerState.playing || audioService.playerState == PlayerState.completed,
        true,
        reason: 'Gayatri Mantra should start playing on Android runtime',
      );

      await audioService.pause();
      await tester.pump(const Duration(milliseconds: 200));
      await audioService.stop();

      // Test Mantra 2: Hanuman Chalisa opening Doha (VEDA-MTR-0401)
      const hanuman = MantraItem(
        id: 'VEDA-MTR-0401',
        collection: 'Assorted deities',
        deity: 'Hanuman',
        title: 'Hanuman Chalisa',
        filename: 'Hanuman Chalisa.wav',
        mantraText: 'Shri Guru Charan Saroj Raj...',
        significance: 'Opening doha of Hanuman Chalisa',
        form: 'Stotram',
        durationSeconds: 25.60,
        sampleRate: 48000,
        bitDepth: 16,
        channels: 2,
        fileSizeBytes: 4915276,
        sha256: 'b2c3d4e5...',
        sourceTxt: 'Tulsidas Awadhi tradition',
        isBundled: true,
        bundledAssetPath: 'assets/audio/bundled/hanuman_chalisa.mp3',
      );

      await audioService.playMantra(hanuman);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(audioService.activeMantra?.id, 'VEDA-MTR-0401');
      await audioService.stop();

      // Test Mantra 3: Maha Mrityunjaya Mantra (VEDA-MTR-0413)
      const mrityunjaya = MantraItem(
        id: 'VEDA-MTR-0413',
        collection: 'Shiva',
        deity: 'Shiva',
        title: 'Maha Mrityunjaya Mantra',
        filename: 'Maha Mrityunjaya Mantra.wav',
        mantraText: 'Tryambakam Yajamahe...',
        significance: 'Vedic healing and moksha mantra',
        form: 'Vedic Suktam',
        durationSeconds: 17.00,
        sampleRate: 48000,
        bitDepth: 16,
        channels: 2,
        fileSizeBytes: 3264076,
        sha256: 'c3d4e5f6...',
        sourceTxt: 'Rigveda 7.59.12',
        isBundled: true,
        bundledAssetPath: 'assets/audio/bundled/maha_mrityunjaya_mantra.mp3',
      );

      await audioService.playMantra(mrityunjaya);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(audioService.activeMantra?.id, 'VEDA-MTR-0413');
      await audioService.stop();

      // Test Unbundled Vault Item: Shiva Tandava Stotram (VEDA-MTR-0443)
      const shivaTandava = MantraItem(
        id: 'VEDA-MTR-0443',
        collection: 'Shiva',
        deity: 'Shiva',
        title: 'Shiva Tandava Stotram',
        filename: 'Shiva Tandava Stotram.wav',
        mantraText: 'Jata Tavi Gala Jjala...',
        significance: 'Hymn of praise by Ravana',
        form: 'Stotram',
        durationSeconds: 25.80,
        sampleRate: 48000,
        bitDepth: 16,
        channels: 2,
        fileSizeBytes: 4954124,
        sha256: '29849e82...',
        sourceTxt: 'Traditional Stotram Literature',
        isBundled: false,
        bundledAssetPath: null,
      );

      // On Android runtime, attempting to play unbundled vault recording must throw FileSystemException
      expect(
        () => audioService.playMantra(shivaTandava),
        throwsA(isA<FileSystemException>()),
      );

      await audioService.dispose();
    });
  });
}
