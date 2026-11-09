import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/state/audio_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 20E Android Runtime: Real Future Reminder Scheduling & Android UI Playback', () {
    testWidgets('1. Real future reminder scheduling lifecycle, pending requests, cancellation, and persistence', (tester) async {
      final reminderService = LocalNotificationReminderService();
      await reminderService.initialize();

      // 1. Permission Status on Android 13
      final permStatus = await reminderService.getPermissionStatus();
      expect(
        permStatus == ReminderPermissionStatus.granted || permStatus == ReminderPermissionStatus.denied,
        isTrue,
        reason: 'Permission status on Android 13 must be determined',
      );

      // 2. Schedule a real future reminder via production scheduleReminder()
      final now = tz.TZDateTime.now(tz.local);
      final futureTime = now.add(const Duration(seconds: 4));
      final futureDateStr = '${futureTime.year}-${futureTime.month.toString().padLeft(2, '0')}-${futureTime.day.toString().padLeft(2, '0')}';

      final futureReminder = DevotionalReminder(
        id: 'runtime_future_rem_1',
        type: ReminderType.morningSadhana,
        title: 'Morning Sadhana Call',
        body: 'Time for mindful morning recitation and dhyana.',
        hour: futureTime.hour,
        minute: futureTime.minute,
        second: futureTime.second,
        scheduledDate: futureDateStr,
        isEnabled: true,
      );

      await reminderService.scheduleReminder(futureReminder);
      final notifId = await reminderService.getOrCreateNotificationId(futureReminder.id);
      expect(notifId, greaterThan(0));

      // 3. Verify in pending notification requests
      final pendingList = await reminderService.getPendingNotificationRequests();
      final hasPending = pendingList.any((p) => p.id == notifId || p.title == futureReminder.title);
      expect(hasPending, isTrue, reason: 'Future reminder must be registered in platform pending requests');

      // 4. Test Cancellation before delivery
      final cancelReminder = DevotionalReminder(
        id: 'runtime_cancel_rem_2',
        type: ReminderType.custom,
        title: 'Temporary Observance',
        body: 'This will be cancelled before delivery.',
        hour: futureTime.hour,
        minute: futureTime.minute,
        second: futureTime.second,
        scheduledDate: futureDateStr,
        isEnabled: true,
      );
      await reminderService.scheduleReminder(cancelReminder);
      final cancelNotifId = await reminderService.getOrCreateNotificationId(cancelReminder.id);
      expect(cancelNotifId, greaterThan(0));

      // Cancel it
      await reminderService.cancelReminder(cancelReminder.id);
      final pendingAfterCancel = await reminderService.getPendingNotificationRequests();
      expect(pendingAfterCancel.any((p) => p.id == cancelNotifId), isFalse,
          reason: 'Cancelled reminder must be removed from platform pending requests');

      // 5. Test Rescheduling (update title & body)
      final rescheduledReminder = futureReminder.copyWith(
        title: 'Rescheduled Morning Sadhana Call',
        body: 'Updated text for mindful dhyana.',
      );
      await reminderService.scheduleReminder(rescheduledReminder);
      final pendingAfterReschedule = await reminderService.getPendingNotificationRequests();
      expect(pendingAfterReschedule.where((p) => p.id == notifId).length, lessThanOrEqualTo(1),
          reason: 'Rescheduled reminder must not duplicate pending notification IDs');

      // 6. Test Persistence across restart
      final newServiceInstance = LocalNotificationReminderService();
      await newServiceInstance.initialize();
      final reloadedId = await newServiceInstance.getOrCreateNotificationId(futureReminder.id);
      expect(reloadedId, equals(notifId),
          reason: 'Notification ID registry must persist across service restarts in SharedPreferences');

      // 7. Test Vrat Observance reminder fixture
      const vratReminder = DevotionalReminder(
        id: 'vrat_ekadashi_rem_fixture',
        type: ReminderType.personalVrat,
        title: 'Rama Ekadashi Vrat Morning',
        body: 'Today is Rama Ekadashi observance. Maintain fasting and contemplation.',
        hour: 6,
        minute: 30,
        second: 0,
        scheduledDate: '2026-11-15',
        linkedVratId: 'vrat_rama_ekadashi',
        isEnabled: true,
      );
      await reminderService.scheduleReminder(vratReminder);
      final vratNotifId = await reminderService.getOrCreateNotificationId(vratReminder.id);
      expect(vratNotifId, greaterThan(0));
      expect(vratNotifId != notifId, isTrue);

      // Clean up
      await reminderService.cancelReminder(futureReminder.id);
      await reminderService.releaseReminderId(futureReminder.id);
      await reminderService.cancelReminder(vratReminder.id);
      await reminderService.releaseReminderId(vratReminder.id);
    });

    testWidgets('2. Real Android UI Playback for all 3 bundled scriptures (Gayatri, Hanuman Doha, Mrityunjaya)', (tester) async {
      final audioService = AudioPlaybackServiceImpl();
      final audioState = AudioState(audioService: audioService);

      const playPauseKey = ValueKey('primary_play_pause_button');
      final playPauseButton = find.byKey(playPauseKey);

      // --- TRACK 1: Gayatri Mantra (VEDA-MTR-0399) ---
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantraPlayerScreen(
            key: const ValueKey('player_gayatri'),
            mantra: gayatri,
            audioState: audioState,
          ),
        ),
      );

      // Wait for post-frame callback and initial autoplay
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));

      // Scroll using explicit primary scrollable
      await tester.scrollUntilVisible(
        playPauseButton,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify UI shows Pause button because playback initiated
      expect(playPauseButton, findsOneWidget, reason: 'UI must show primary Play/Pause button');
      expect(find.descendant(of: playPauseButton, matching: find.byIcon(Icons.pause)), findsOneWidget,
          reason: 'UI must show Pause icon when actively playing');
      expect(audioState.isPlaying, isTrue);
      expect(audioState.activeMantra?.id, 'VEDA-MTR-0399');

      // 2. Tap Pause button in UI
      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 300));
      expect(audioState.isPlaying, isFalse, reason: 'Tapping Pause in UI must pause the audio service');
      expect(find.descendant(of: playPauseButton, matching: find.byIcon(Icons.play_arrow)), findsOneWidget,
          reason: 'UI must flip to Play icon when paused');

      // 3. Tap Play button in UI to resume
      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(audioState.isPlaying, isTrue, reason: 'Tapping Play in UI must resume playback');
      expect(find.descendant(of: playPauseButton, matching: find.byIcon(Icons.pause)), findsOneWidget);

      // Stop before switching
      audioState.stop();
      await tester.pump(const Duration(milliseconds: 300));

      // --- TRACK 2: Hanuman Chalisa Opening Doha (VEDA-MTR-0401) ---
      // Note: Contains only opening Doha, not the complete 40 Chaupais!
      const hanuman = MantraItem(
        id: 'VEDA-MTR-0401',
        collection: 'Assorted deities',
        deity: 'Hanuman',
        title: 'Hanuman Chalisa (Opening Doha)',
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantraPlayerScreen(
            key: const ValueKey('player_hanuman'),
            mantra: hanuman,
            audioState: audioState,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));

      await tester.scrollUntilVisible(
        playPauseButton,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(audioState.isPlaying, isTrue);
      expect(audioState.activeMantra?.id, 'VEDA-MTR-0401');
      expect(find.descendant(of: playPauseButton, matching: find.byIcon(Icons.pause)), findsOneWidget);

      // Pause and resume via UI
      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 300));
      expect(audioState.isPlaying, isFalse);
      expect(find.descendant(of: playPauseButton, matching: find.byIcon(Icons.play_arrow)), findsOneWidget);

      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(audioState.isPlaying, isTrue);

      audioState.stop();
      await tester.pump(const Duration(milliseconds: 300));

      // --- TRACK 3: Maha Mrityunjaya Mantra (VEDA-MTR-0413) ---
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantraPlayerScreen(
            key: const ValueKey('player_mrityunjaya'),
            mantra: mrityunjaya,
            audioState: audioState,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));

      await tester.scrollUntilVisible(
        playPauseButton,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(audioState.isPlaying, isTrue);
      expect(audioState.activeMantra?.id, 'VEDA-MTR-0413');
      expect(find.descendant(of: playPauseButton, matching: find.byIcon(Icons.pause)), findsOneWidget);

      // Pause and resume via UI
      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 300));
      expect(audioState.isPlaying, isFalse);
      expect(find.descendant(of: playPauseButton, matching: find.byIcon(Icons.play_arrow)), findsOneWidget);

      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(audioState.isPlaying, isTrue);

      audioState.stop();
      await tester.pump(const Duration(milliseconds: 300));
      await audioService.dispose();
    });
  });
}
