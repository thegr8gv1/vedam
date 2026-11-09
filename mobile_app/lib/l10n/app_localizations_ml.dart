// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'വേദം';

  @override
  String get navHome => 'ഹോം';

  @override
  String get navLibrary => 'ഗ്രന്ഥശാല';

  @override
  String get navSadhana => 'സാധന';

  @override
  String get navSaved => 'സൂക്ഷിച്ചവ';

  @override
  String get navSettings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get offlineModeBanner =>
      'ഓഫ്‌ലൈൻ മോഡ് — പ്രാദേശിക സ്തോത്രങ്ങളും സാധനകളും ലഭ്യമാണ്';

  @override
  String get offlineUnavailableAudio =>
      'ഓഡിയോയ്ക്ക് ഇന്റർനെറ്റ് കണക്ഷൻ ആവശ്യമാണ്';

  @override
  String get offlineAvailable => 'ഓഫ്‌ലൈനിൽ ലഭ്യമാണ്';

  @override
  String get offlineIndicator => 'ഓഫ്‌ലൈൻ';

  @override
  String get homeDailyDarshan => 'നിത്യ ദർശനം';

  @override
  String get homePanchangamPreview => 'ഇന്നത്തെ പഞ്ചാംഗം';

  @override
  String get homeDailyRoutine => 'നിത്യ ആത്മീയ സാധന';

  @override
  String get homeJapaPractice => 'നിത്യ ജപ സാധന';

  @override
  String get homeUpcomingVrat => 'വരാനിരിക്കുന്ന വ്രതങ്ങൾ';

  @override
  String get homeScriptureProgress => 'സ്തോത്ര വായന';

  @override
  String get homeFestivalCalendar => 'ഉത്സവ & വ്രത കലണ്ടർ';

  @override
  String get homeDevotionalFocus => 'ഉപാസനാ മൂർത്തി';

  @override
  String get homeQuickAccess => 'പെട്ടെന്നുള്ള ദർശനം';

  @override
  String get settingsTitle => 'ക്രമീകരണങ്ങളും മുൻഗണനകളും';

  @override
  String get settingsLanguage => 'ആപ്പ് ഭാഷ';

  @override
  String get settingsLanguageSubtitle => 'ആപ്പ് ഭാഷ തിരഞ്ഞെടുക്കുക';

  @override
  String get settingsScript => 'സ്തോത്ര ലിപി';

  @override
  String get settingsScriptSubtitle => 'ശ്ലോകങ്ങളുടെ പ്രധാന ലിപി';

  @override
  String get settingsTheme => 'പ്രതീതി';

  @override
  String get settingsThemeSacredLight => 'പവിത്ര പ്രകാശം (കാവി & വെണ്ണക്കല്ല്)';

  @override
  String get settingsThemeTempleNight => 'ക്ഷേത്ര രാവ് (കൃഷ്ണശില & സ്വർണ്ണം)';

  @override
  String get settingsThemeSystem => 'സിസ്റ്റം ഡിഫോൾട്ട്';

  @override
  String get settingsTextScale => 'അക്ഷര വലിപ്പം';

  @override
  String get settingsTextScaleRegular => 'സാധാരണ';

  @override
  String get settingsTextScaleLarge => 'വലുത്';

  @override
  String get settingsTextScaleExtraLarge => 'ആത്മീയ ഏകാഗ്രത (ഏറ്റവും വലുത്)';

  @override
  String get settingsDevotionalFocus => 'ഉപാസനാ മൂർത്തി';

  @override
  String get settingsSadhanaGoals => 'നിത്യ സാധനാ ലക്ഷ്യങ്ങൾ';

  @override
  String get settingsReminders => 'ആത്മീയ ഓർമ്മപ്പെടുത്തലുകൾ';

  @override
  String get settingsLocation => 'പഞ്ചാംഗ സ്ഥലം';

  @override
  String get settingsRerunOnboarding => 'ആമുഖം വീണ്ടും ആരംഭിക്കുക';

  @override
  String get settingsAbout => 'വേദത്തെക്കുറിച്ച്';

  @override
  String get libraryTitle => 'സ്തോത്ര ഗ്രന്ഥശാല';

  @override
  String get librarySearchPlaceholder => 'സ്തോത്രങ്ങൾ, മന്ത്രങ്ങൾ തിരയുക...';

  @override
  String libraryVerseCount(int count) {
    return '$count ശ്ലോകങ്ങൾ';
  }

  @override
  String get libraryRecent => 'അടുത്തിടെ വായിച്ചവ';

  @override
  String get libraryFavorites => 'പ്രിയപ്പെട്ടവ';

  @override
  String get libraryAll => 'എല്ലാ സ്തോത്രങ്ങളും';

  @override
  String readerVerse(int number) {
    return 'ശ്ലോകം $number';
  }

  @override
  String readerVerseOf(int current, int total) {
    return 'ശ്ലോകം $current / $total';
  }

  @override
  String get readerSourceText => 'മൂല ശ്ലോകം';

  @override
  String get readerTransliteration => 'ലിപ്യന്തരണം';

  @override
  String get readerTranslation => 'തർജ്ജമ (കരട്)';

  @override
  String get readerCommentary => 'വ്യാഖ്യാനം';

  @override
  String get readerScholarlyDisclaimer =>
      'തർജ്ജമ പരിശോധനയിലാണ്. ആധികാരിക ഭാഷ്യങ്ങൾ പരിശോധിക്കുക.';

  @override
  String get readerLearningMode => 'പഠന മോഡ്';

  @override
  String get japaTitle => 'ജപ സാധന';

  @override
  String japaTargetLabel(int count) {
    return 'ലക്ഷ്യം: $count ജപങ്ങൾ';
  }

  @override
  String japaCompletedChants(int completed, int target) {
    return '$completed / $target ജപങ്ങൾ പൂർത്തിയായി';
  }

  @override
  String japaChantsRemaining(int count) {
    return 'ഇനി $count ബാക്കി';
  }

  @override
  String japaMalaCompleted(int count) {
    return '$count മാല പൂർത്തിയായി';
  }

  @override
  String get japaTapToCount => 'എണ്ണാൻ തൊടുക';

  @override
  String get japaTargetSelector => 'ജപ സംഖ്യ തിരഞ്ഞെടുക്കുക';

  @override
  String get japaCustomCount => 'സ്വന്തം സംഖ്യ';

  @override
  String get japaStartChanting => 'ജപം ആരംഭിക്കുക';

  @override
  String get japaReset => 'പുനഃക്രമീകരിക്കുക';

  @override
  String get audioPlay => 'പ്ലേ ചെയ്യുക';

  @override
  String get audioPause => 'നിർത്തുക';

  @override
  String get audioResume => 'തുടരുക';

  @override
  String get audioStop => 'അവസാനിപ്പിക്കുക';

  @override
  String get audioBundledOffline => 'ഓഫ്‌ലൈനിൽ ലഭ്യമാണ്';

  @override
  String get audioStreamingNetwork => 'ഓൺലൈൻ സ്ട്രീം';

  @override
  String get sadhanaTitle => 'നിത്യ സാധന';

  @override
  String get sadhanaMorning => 'പ്രാതഃസ്മരണം (രാവിലെ)';

  @override
  String get sadhanaEvening => 'സായം സന്ധ്യ (വൈകുന്നേരം)';

  @override
  String get sadhanaDailyPuja => 'നിത്യ പൂജാ മാർഗ്ഗനിർദ്ദേശങ്ങൾ';

  @override
  String sadhanaStep(int step, int total) {
    return 'ഘട്ടം $step / $total';
  }

  @override
  String get sadhanaComplete => 'പൂർത്തിയായി';

  @override
  String get sadhanaMarkComplete => 'പൂർത്തിയായതായി അടയാളപ്പെടുത്തുക';

  @override
  String get panchangamTitle => 'പഞ്ചാംഗം';

  @override
  String get panchangamTithi => 'തിഥി';

  @override
  String get panchangamNakshatra => 'നക്ഷത്രം';

  @override
  String get panchangamYoga => 'യോഗം';

  @override
  String get panchangamKarana => 'കരണം';

  @override
  String get panchangamSunrise => 'സൂര്യോദയം';

  @override
  String get panchangamSunset => 'സൂര്യാസ്തമയം';

  @override
  String get panchangamRahuKalam => 'രാഹുകാലം';

  @override
  String get panchangamYamagandam => 'യമഗണ്ഡം';

  @override
  String get panchangamGulika => 'ഗുളികകാലം';

  @override
  String get vratTitle => 'വ്രതങ്ങളും അനുഷ്ഠാനങ്ങളും';

  @override
  String get vratAdd => 'എന്റെ വ്രതങ്ങളിൽ ചേർക്കുക';

  @override
  String get vratAdded => 'വ്രതത്തിൽ ചേർത്തു';

  @override
  String get vratActive => 'സജീവ വ്രതം';

  @override
  String get vratCompleted => 'വ്രതം പൂർത്തിയായി';

  @override
  String get festivalCalendarTitle => 'ഉത്സവ & വ്രത കലണ്ടർ';

  @override
  String get festivalUpcoming => 'വരാനിരിക്കുന്ന ഉത്സവങ്ങൾ';

  @override
  String get festivalRegional => 'പ്രാദേശിക വിശേഷം';

  @override
  String get festivalSignificance => 'ആത്മീയ പ്രാധാന്യം';

  @override
  String get festivalPujaGuide => 'പൂജാ മാർഗ്ഗനിർദ്ദേശം';

  @override
  String get onboardingWelcome => 'വേദത്തിലേക്ക് സ്വാഗതം';

  @override
  String get onboardingSubtitle =>
      'ആധികാരിക വൈദിക ഭക്തിക്കും സാധനയ്ക്കുമുള്ള നിങ്ങളുടെ വഴികാട്ടി.';

  @override
  String get onboardingStepLanguage => 'ആപ്പ് ഭാഷ & സ്തോത്ര ലിപി';

  @override
  String get onboardingStepInterests => 'ഉപാസനാ മൂർത്തി';

  @override
  String get onboardingStepSadhana => 'നിത്യ സാധനാ ലക്ഷ്യങ്ങൾ';

  @override
  String get onboardingStepLocation => 'പഞ്ചാംഗ സ്ഥലം';

  @override
  String get onboardingStepReminders => 'ആത്മീയ ഓർമ്മപ്പെടുത്തലുകൾ';

  @override
  String get onboardingGetStarted => 'സാധന ആരംഭിക്കുക';

  @override
  String get onboardingNext => 'അടുത്തത്';

  @override
  String get onboardingBack => 'പിന്നോട്ട്';

  @override
  String get onboardingSkip => 'ഇപ്പോൾ വേണ്ട';

  @override
  String get commonSave => 'സൂക്ഷിക്കുക';

  @override
  String get commonCancel => 'റദ്ദാക്കുക';

  @override
  String get commonDone => 'പൂർത്തിയായി';

  @override
  String get commonClose => 'അടയ്ക്കുക';

  @override
  String get commonConfirm => 'ഉറപ്പാക്കുക';

  @override
  String get commonRetry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get commonSearch => 'തിരയുക';
}
