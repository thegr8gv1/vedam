// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vedam';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSadhana => 'Sadhana';

  @override
  String get navSaved => 'Saved';

  @override
  String get navSettings => 'Settings';

  @override
  String get offlineModeBanner =>
      'Offline Mode — Local scriptures & practices available';

  @override
  String get offlineUnavailableAudio => 'Audio requires network connection';

  @override
  String get offlineAvailable => 'Available Offline';

  @override
  String get offlineIndicator => 'Offline';

  @override
  String get homeDailyDarshan => 'Daily Darshan';

  @override
  String get homePanchangamPreview => 'Today\'s Panchangam';

  @override
  String get homeDailyRoutine => 'Daily Spiritual Routine';

  @override
  String get homeJapaPractice => 'Daily Japa Practice';

  @override
  String get homeUpcomingVrat => 'Upcoming Vrat & Observances';

  @override
  String get homeScriptureProgress => 'Scripture Reading';

  @override
  String get homeFestivalCalendar => 'Festival & Observance Calendar';

  @override
  String get homeDevotionalFocus => 'Devotional Focus';

  @override
  String get homeQuickAccess => 'Quick Devotional Access';

  @override
  String get settingsTitle => 'Settings & Preferences';

  @override
  String get settingsLanguage => 'Interface Language';

  @override
  String get settingsLanguageSubtitle => 'Select application language';

  @override
  String get settingsScript => 'Scripture Script';

  @override
  String get settingsScriptSubtitle => 'Primary script for Vedic verses';

  @override
  String get settingsTheme => 'Appearance Theme';

  @override
  String get settingsThemeSacredLight => 'Sacred Light (Saffron & Marble)';

  @override
  String get settingsThemeTempleNight => 'Temple Night (Obsidian & Gold)';

  @override
  String get settingsThemeSystem => 'System Default';

  @override
  String get settingsTextScale => 'Text Scaling & Readability';

  @override
  String get settingsTextScaleRegular => 'Regular';

  @override
  String get settingsTextScaleLarge => 'Large';

  @override
  String get settingsTextScaleExtraLarge => 'Spiritual Focus (Extra Large)';

  @override
  String get settingsDevotionalFocus => 'Devotional Focus';

  @override
  String get settingsSadhanaGoals => 'Daily Sadhana Targets';

  @override
  String get settingsReminders => 'Devotional Reminders';

  @override
  String get settingsLocation => 'Panchangam Location';

  @override
  String get settingsRerunOnboarding => 'Re-run Devotee Onboarding';

  @override
  String get settingsAbout => 'About Vedam';

  @override
  String get libraryTitle => 'Scripture Library';

  @override
  String get librarySearchPlaceholder => 'Search sacred scriptures, stotras...';

  @override
  String libraryVerseCount(int count) {
    return '$count verses';
  }

  @override
  String get libraryRecent => 'Recently Read';

  @override
  String get libraryFavorites => 'Favorites';

  @override
  String get libraryAll => 'All Scriptures';

  @override
  String readerVerse(int number) {
    return 'Verse $number';
  }

  @override
  String readerVerseOf(int current, int total) {
    return 'Verse $current of $total';
  }

  @override
  String get readerSourceText => 'Source Text';

  @override
  String get readerTransliteration => 'Transliteration';

  @override
  String get readerTranslation => 'Translation (Draft)';

  @override
  String get readerCommentary => 'Commentary';

  @override
  String get readerScholarlyDisclaimer =>
      'Translation under review. Consult verified traditional commentary.';

  @override
  String get readerLearningMode => 'Focused Learning Mode';

  @override
  String get japaTitle => 'Japa Practice';

  @override
  String japaTargetLabel(int count) {
    return 'Target: $count Chants';
  }

  @override
  String japaCompletedChants(int completed, int target) {
    return '$completed of $target Chants';
  }

  @override
  String japaChantsRemaining(int count) {
    return '$count remaining';
  }

  @override
  String japaMalaCompleted(int count) {
    return '$count Mala Completed';
  }

  @override
  String get japaTapToCount => 'Tap to Count';

  @override
  String get japaTargetSelector => 'Select Japa Target';

  @override
  String get japaCustomCount => 'Custom Count';

  @override
  String get japaStartChanting => 'Start Chanting';

  @override
  String get japaReset => 'Reset Count';

  @override
  String get audioPlay => 'Play';

  @override
  String get audioPause => 'Pause';

  @override
  String get audioResume => 'Resume';

  @override
  String get audioStop => 'Stop';

  @override
  String get audioBundledOffline => 'Bundled (Available Offline)';

  @override
  String get audioStreamingNetwork => 'Online Stream';

  @override
  String get sadhanaTitle => 'Daily Sadhana';

  @override
  String get sadhanaMorning => 'Pratah Smaranam (Morning)';

  @override
  String get sadhanaEvening => 'Sayam Sandhya (Evening)';

  @override
  String get sadhanaDailyPuja => 'Daily Puja Guides';

  @override
  String sadhanaStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get sadhanaComplete => 'Completed';

  @override
  String get sadhanaMarkComplete => 'Mark Step Complete';

  @override
  String get panchangamTitle => 'Panchangam';

  @override
  String get panchangamTithi => 'Tithi';

  @override
  String get panchangamNakshatra => 'Nakshatra';

  @override
  String get panchangamYoga => 'Yoga';

  @override
  String get panchangamKarana => 'Karana';

  @override
  String get panchangamSunrise => 'Sunrise';

  @override
  String get panchangamSunset => 'Sunset';

  @override
  String get panchangamRahuKalam => 'Rahu Kalam';

  @override
  String get panchangamYamagandam => 'Yamagandam';

  @override
  String get panchangamGulika => 'Gulika Kalam';

  @override
  String get vratTitle => 'Vrat & Observances';

  @override
  String get vratAdd => 'Add to My Vrats';

  @override
  String get vratAdded => 'Added to Observances';

  @override
  String get vratActive => 'Active Observance';

  @override
  String get vratCompleted => 'Observance Completed';

  @override
  String get festivalCalendarTitle => 'Festival & Observance Calendar';

  @override
  String get festivalUpcoming => 'Upcoming Festivals';

  @override
  String get festivalRegional => 'Regional Observance';

  @override
  String get festivalSignificance => 'Spiritual Significance';

  @override
  String get festivalPujaGuide => 'Related Puja Guide';

  @override
  String get onboardingWelcome => 'Welcome to Vedam';

  @override
  String get onboardingSubtitle =>
      'Your personal companion for authentic Vedic devotion and spiritual practice.';

  @override
  String get onboardingStepLanguage => 'Interface Language & Scripture Script';

  @override
  String get onboardingStepInterests => 'Devotional Focus';

  @override
  String get onboardingStepSadhana => 'Daily Sadhana Targets';

  @override
  String get onboardingStepLocation => 'Panchangam Location';

  @override
  String get onboardingStepReminders => 'Devotional Reminders';

  @override
  String get onboardingGetStarted => 'Begin Sadhana';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingSkip => 'Skip for now';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDone => 'Done';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSearch => 'Search';
}
