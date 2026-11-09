import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kn'),
    Locale('ml'),
    Locale('ta'),
    Locale('te'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Vedam'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSadhana.
  ///
  /// In en, this message translates to:
  /// **'Sadhana'**
  String get navSadhana;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @offlineModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode — Local scriptures & practices available'**
  String get offlineModeBanner;

  /// No description provided for @offlineUnavailableAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio requires network connection'**
  String get offlineUnavailableAudio;

  /// No description provided for @offlineAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available Offline'**
  String get offlineAvailable;

  /// No description provided for @offlineIndicator.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineIndicator;

  /// No description provided for @homeDailyDarshan.
  ///
  /// In en, this message translates to:
  /// **'Daily Darshan'**
  String get homeDailyDarshan;

  /// No description provided for @homePanchangamPreview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Panchangam'**
  String get homePanchangamPreview;

  /// No description provided for @homeDailyRoutine.
  ///
  /// In en, this message translates to:
  /// **'Daily Spiritual Routine'**
  String get homeDailyRoutine;

  /// No description provided for @homeJapaPractice.
  ///
  /// In en, this message translates to:
  /// **'Daily Japa Practice'**
  String get homeJapaPractice;

  /// No description provided for @homeUpcomingVrat.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Vrat & Observances'**
  String get homeUpcomingVrat;

  /// No description provided for @homeScriptureProgress.
  ///
  /// In en, this message translates to:
  /// **'Scripture Reading'**
  String get homeScriptureProgress;

  /// No description provided for @homeFestivalCalendar.
  ///
  /// In en, this message translates to:
  /// **'Festival & Observance Calendar'**
  String get homeFestivalCalendar;

  /// No description provided for @homeDevotionalFocus.
  ///
  /// In en, this message translates to:
  /// **'Devotional Focus'**
  String get homeDevotionalFocus;

  /// No description provided for @homeQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Devotional Access'**
  String get homeQuickAccess;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & Preferences'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select application language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsScript.
  ///
  /// In en, this message translates to:
  /// **'Scripture Script'**
  String get settingsScript;

  /// No description provided for @settingsScriptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Primary script for Vedic verses'**
  String get settingsScriptSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSacredLight.
  ///
  /// In en, this message translates to:
  /// **'Sacred Light (Saffron & Marble)'**
  String get settingsThemeSacredLight;

  /// No description provided for @settingsThemeTempleNight.
  ///
  /// In en, this message translates to:
  /// **'Temple Night (Obsidian & Gold)'**
  String get settingsThemeTempleNight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsTextScale.
  ///
  /// In en, this message translates to:
  /// **'Text Scaling & Readability'**
  String get settingsTextScale;

  /// No description provided for @settingsTextScaleRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get settingsTextScaleRegular;

  /// No description provided for @settingsTextScaleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settingsTextScaleLarge;

  /// No description provided for @settingsTextScaleExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Spiritual Focus (Extra Large)'**
  String get settingsTextScaleExtraLarge;

  /// No description provided for @settingsDevotionalFocus.
  ///
  /// In en, this message translates to:
  /// **'Devotional Focus'**
  String get settingsDevotionalFocus;

  /// No description provided for @settingsSadhanaGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Sadhana Targets'**
  String get settingsSadhanaGoals;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Devotional Reminders'**
  String get settingsReminders;

  /// No description provided for @settingsLocation.
  ///
  /// In en, this message translates to:
  /// **'Panchangam Location'**
  String get settingsLocation;

  /// No description provided for @settingsRerunOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Re-run Devotee Onboarding'**
  String get settingsRerunOnboarding;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Vedam'**
  String get settingsAbout;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Scripture Library'**
  String get libraryTitle;

  /// No description provided for @librarySearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search sacred scriptures, stotras...'**
  String get librarySearchPlaceholder;

  /// No description provided for @libraryVerseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String libraryVerseCount(int count);

  /// No description provided for @libraryRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently Read'**
  String get libraryRecent;

  /// No description provided for @libraryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFavorites;

  /// No description provided for @libraryAll.
  ///
  /// In en, this message translates to:
  /// **'All Scriptures'**
  String get libraryAll;

  /// No description provided for @readerVerse.
  ///
  /// In en, this message translates to:
  /// **'Verse {number}'**
  String readerVerse(int number);

  /// No description provided for @readerVerseOf.
  ///
  /// In en, this message translates to:
  /// **'Verse {current} of {total}'**
  String readerVerseOf(int current, int total);

  /// No description provided for @readerSourceText.
  ///
  /// In en, this message translates to:
  /// **'Source Text'**
  String get readerSourceText;

  /// No description provided for @readerTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get readerTransliteration;

  /// No description provided for @readerTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation (Draft)'**
  String get readerTranslation;

  /// No description provided for @readerCommentary.
  ///
  /// In en, this message translates to:
  /// **'Commentary'**
  String get readerCommentary;

  /// No description provided for @readerScholarlyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Translation under review. Consult verified traditional commentary.'**
  String get readerScholarlyDisclaimer;

  /// No description provided for @readerLearningMode.
  ///
  /// In en, this message translates to:
  /// **'Focused Learning Mode'**
  String get readerLearningMode;

  /// No description provided for @japaTitle.
  ///
  /// In en, this message translates to:
  /// **'Japa Practice'**
  String get japaTitle;

  /// No description provided for @japaTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target: {count} Chants'**
  String japaTargetLabel(int count);

  /// No description provided for @japaCompletedChants.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {target} Chants'**
  String japaCompletedChants(int completed, int target);

  /// No description provided for @japaChantsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String japaChantsRemaining(int count);

  /// No description provided for @japaMalaCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} Mala Completed'**
  String japaMalaCompleted(int count);

  /// No description provided for @japaTapToCount.
  ///
  /// In en, this message translates to:
  /// **'Tap to Count'**
  String get japaTapToCount;

  /// No description provided for @japaTargetSelector.
  ///
  /// In en, this message translates to:
  /// **'Select Japa Target'**
  String get japaTargetSelector;

  /// No description provided for @japaCustomCount.
  ///
  /// In en, this message translates to:
  /// **'Custom Count'**
  String get japaCustomCount;

  /// No description provided for @japaStartChanting.
  ///
  /// In en, this message translates to:
  /// **'Start Chanting'**
  String get japaStartChanting;

  /// No description provided for @japaReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Count'**
  String get japaReset;

  /// No description provided for @audioPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get audioPlay;

  /// No description provided for @audioPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get audioPause;

  /// No description provided for @audioResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get audioResume;

  /// No description provided for @audioStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get audioStop;

  /// No description provided for @audioBundledOffline.
  ///
  /// In en, this message translates to:
  /// **'Bundled (Available Offline)'**
  String get audioBundledOffline;

  /// No description provided for @audioStreamingNetwork.
  ///
  /// In en, this message translates to:
  /// **'Online Stream'**
  String get audioStreamingNetwork;

  /// No description provided for @sadhanaTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Sadhana'**
  String get sadhanaTitle;

  /// No description provided for @sadhanaMorning.
  ///
  /// In en, this message translates to:
  /// **'Pratah Smaranam (Morning)'**
  String get sadhanaMorning;

  /// No description provided for @sadhanaEvening.
  ///
  /// In en, this message translates to:
  /// **'Sayam Sandhya (Evening)'**
  String get sadhanaEvening;

  /// No description provided for @sadhanaDailyPuja.
  ///
  /// In en, this message translates to:
  /// **'Daily Puja Guides'**
  String get sadhanaDailyPuja;

  /// No description provided for @sadhanaStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String sadhanaStep(int step, int total);

  /// No description provided for @sadhanaComplete.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sadhanaComplete;

  /// No description provided for @sadhanaMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Step Complete'**
  String get sadhanaMarkComplete;

  /// No description provided for @panchangamTitle.
  ///
  /// In en, this message translates to:
  /// **'Panchangam'**
  String get panchangamTitle;

  /// No description provided for @panchangamTithi.
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get panchangamTithi;

  /// No description provided for @panchangamNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get panchangamNakshatra;

  /// No description provided for @panchangamYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get panchangamYoga;

  /// No description provided for @panchangamKarana.
  ///
  /// In en, this message translates to:
  /// **'Karana'**
  String get panchangamKarana;

  /// No description provided for @panchangamSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get panchangamSunrise;

  /// No description provided for @panchangamSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get panchangamSunset;

  /// No description provided for @panchangamRahuKalam.
  ///
  /// In en, this message translates to:
  /// **'Rahu Kalam'**
  String get panchangamRahuKalam;

  /// No description provided for @panchangamYamagandam.
  ///
  /// In en, this message translates to:
  /// **'Yamagandam'**
  String get panchangamYamagandam;

  /// No description provided for @panchangamGulika.
  ///
  /// In en, this message translates to:
  /// **'Gulika Kalam'**
  String get panchangamGulika;

  /// No description provided for @vratTitle.
  ///
  /// In en, this message translates to:
  /// **'Vrat & Observances'**
  String get vratTitle;

  /// No description provided for @vratAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to My Vrats'**
  String get vratAdd;

  /// No description provided for @vratAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to Observances'**
  String get vratAdded;

  /// No description provided for @vratActive.
  ///
  /// In en, this message translates to:
  /// **'Active Observance'**
  String get vratActive;

  /// No description provided for @vratCompleted.
  ///
  /// In en, this message translates to:
  /// **'Observance Completed'**
  String get vratCompleted;

  /// No description provided for @festivalCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Festival & Observance Calendar'**
  String get festivalCalendarTitle;

  /// No description provided for @festivalUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Festivals'**
  String get festivalUpcoming;

  /// No description provided for @festivalRegional.
  ///
  /// In en, this message translates to:
  /// **'Regional Observance'**
  String get festivalRegional;

  /// No description provided for @festivalSignificance.
  ///
  /// In en, this message translates to:
  /// **'Spiritual Significance'**
  String get festivalSignificance;

  /// No description provided for @festivalPujaGuide.
  ///
  /// In en, this message translates to:
  /// **'Related Puja Guide'**
  String get festivalPujaGuide;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Vedam'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal companion for authentic Vedic devotion and spiritual practice.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingStepLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface Language & Scripture Script'**
  String get onboardingStepLanguage;

  /// No description provided for @onboardingStepInterests.
  ///
  /// In en, this message translates to:
  /// **'Devotional Focus'**
  String get onboardingStepInterests;

  /// No description provided for @onboardingStepSadhana.
  ///
  /// In en, this message translates to:
  /// **'Daily Sadhana Targets'**
  String get onboardingStepSadhana;

  /// No description provided for @onboardingStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Panchangam Location'**
  String get onboardingStepLocation;

  /// No description provided for @onboardingStepReminders.
  ///
  /// In en, this message translates to:
  /// **'Devotional Reminders'**
  String get onboardingStepReminders;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Begin Sadhana'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkip;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kn', 'ml', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
