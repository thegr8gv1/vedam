// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'வேதம்';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navLibrary => 'நூலகம்';

  @override
  String get navSadhana => 'சாதனை';

  @override
  String get navSaved => 'சேமிக்கப்பட்டவை';

  @override
  String get navSettings => 'அமைப்புகள்';

  @override
  String get offlineModeBanner =>
      'ஆஃப்லைன் முறைமை — நூல்களும் சாதனைகளும் கிடைக்கின்றன';

  @override
  String get offlineUnavailableAudio => 'ஆடியோவிற்கு இணைய இணைப்பு தேவை';

  @override
  String get offlineAvailable => 'ஆஃப்லைனில் கிடைக்கிறது';

  @override
  String get offlineIndicator => 'ஆஃப்லைன்';

  @override
  String get homeDailyDarshan => 'தினசரி தரிசனம்';

  @override
  String get homePanchangamPreview => 'இன்றைய பஞ்சாங்கம்';

  @override
  String get homeDailyRoutine => 'தினசரி ஆன்மீக முறை';

  @override
  String get homeJapaPractice => 'தினசரி ஜப சாதனை';

  @override
  String get homeUpcomingVrat => 'வரவிருக்கும் விரதங்கள்';

  @override
  String get homeScriptureProgress => 'ஸ்லோக வாசிப்பு';

  @override
  String get homeFestivalCalendar => 'திருவிழா & விரத காலண்டர்';

  @override
  String get homeDevotionalFocus => 'இஷ்ட தெய்வம்';

  @override
  String get homeQuickAccess => 'விரைவு தரிசனம்';

  @override
  String get settingsTitle => 'அமைப்புகள் & விருப்பங்கள்';

  @override
  String get settingsLanguage => 'செயலி மொழி';

  @override
  String get settingsLanguageSubtitle =>
      'பயன்பாட்டு மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get settingsScript => 'ஸ்லோக வரிவடிவம்';

  @override
  String get settingsScriptSubtitle => 'வேத ஸ்லோகங்களுக்கான எழுத்துரு';

  @override
  String get settingsTheme => 'தோற்றம்';

  @override
  String get settingsThemeSacredLight => 'புனித ஒளி (காவி & பளிங்கு)';

  @override
  String get settingsThemeTempleNight => 'கோவில் இரவு (கருங்கல் & தங்கம்)';

  @override
  String get settingsThemeSystem => 'கணினி இயல்புநிலை';

  @override
  String get settingsTextScale => 'எழுத்து அளவு';

  @override
  String get settingsTextScaleRegular => 'வழக்கமான';

  @override
  String get settingsTextScaleLarge => 'பெரியது';

  @override
  String get settingsTextScaleExtraLarge => 'ஆன்மீக கவனம் (மிகப் பெரியது)';

  @override
  String get settingsDevotionalFocus => 'இஷ்ட தெய்வம்';

  @override
  String get settingsSadhanaGoals => 'தினசரி சாதனை இலக்குகள்';

  @override
  String get settingsReminders => 'ஆன்மீக நினைவூட்டல்கள்';

  @override
  String get settingsLocation => 'பஞ்சாங்க இடம்';

  @override
  String get settingsRerunOnboarding => 'அறிமுகப் பயிற்சியை மீண்டும் தொடங்கு';

  @override
  String get settingsAbout => 'வேதம் பற்றி';

  @override
  String get libraryTitle => 'ஸ்லோக நூலகம்';

  @override
  String get librarySearchPlaceholder => 'ஸ்லோகங்கள், மந்திரங்களை தேடுங்கள்...';

  @override
  String libraryVerseCount(int count) {
    return '$count ஸ்லோகங்கள்';
  }

  @override
  String get libraryRecent => 'சமீபத்தில் படித்தவை';

  @override
  String get libraryFavorites => 'விருப்பமானவை';

  @override
  String get libraryAll => 'அனைத்து ஸ்லோகங்கள்';

  @override
  String readerVerse(int number) {
    return 'ஸ்லோகம் $number';
  }

  @override
  String readerVerseOf(int current, int total) {
    return 'ஸ்லோகம் $current / $total';
  }

  @override
  String get readerSourceText => 'மூல ஸ்லோகம்';

  @override
  String get readerTransliteration => 'உச்சரிப்பு (எழுத்துப் பெயர்ப்பு)';

  @override
  String get readerTranslation => 'மொழிபெயர்ப்பு (வரைவு)';

  @override
  String get readerCommentary => 'உரை விளக்கம்';

  @override
  String get readerScholarlyDisclaimer =>
      'மொழிபெயர்ப்பு பரிசீலனையில் உள்ளது. சான்றோர் உரையை அணுகவும்.';

  @override
  String get readerLearningMode => 'கற்றல் முறைமை';

  @override
  String get japaTitle => 'ஜப சாதனை';

  @override
  String japaTargetLabel(int count) {
    return 'இலக்கு: $count ஜபங்கள்';
  }

  @override
  String japaCompletedChants(int completed, int target) {
    return '$completed / $target ஜபங்கள் நிறைவுற்றன';
  }

  @override
  String japaChantsRemaining(int count) {
    return 'இன்னும் $count மீதம்';
  }

  @override
  String japaMalaCompleted(int count) {
    return '$count மாலை நிறைவுற்றது';
  }

  @override
  String get japaTapToCount => 'எண்ண தொடவும்';

  @override
  String get japaTargetSelector => 'ஜப எண்ணிக்கையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get japaCustomCount => 'விருப்ப எண்ணிக்கை';

  @override
  String get japaStartChanting => 'ஜபத்தைத் தொடங்குங்கள்';

  @override
  String get japaReset => 'மீட்டமை';

  @override
  String get audioPlay => 'இயக்குக';

  @override
  String get audioPause => 'நிறுத்துக';

  @override
  String get audioResume => 'தொடர்க';

  @override
  String get audioStop => 'முடிக்க';

  @override
  String get audioBundledOffline => 'ஆஃப்லைனில் கிடைக்கிறது';

  @override
  String get audioStreamingNetwork => 'ஆன்லைன் ஒலிபரப்பு';

  @override
  String get sadhanaTitle => 'தினசரி சாதனை';

  @override
  String get sadhanaMorning => 'காலை வழிபாடு (பிராதஃ ஸ்மரணம்)';

  @override
  String get sadhanaEvening => 'மாலை வழிபாடு (சாயம் சந்தியா)';

  @override
  String get sadhanaDailyPuja => 'தினசரி பூஜை வழிகாட்டிகள்';

  @override
  String sadhanaStep(int step, int total) {
    return 'படிநிலை $step / $total';
  }

  @override
  String get sadhanaComplete => 'நிறைவுற்றது';

  @override
  String get sadhanaMarkComplete => 'முடிந்ததாகக் குறிக்கவும்';

  @override
  String get panchangamTitle => 'பஞ்சாங்கம்';

  @override
  String get panchangamTithi => 'திதி';

  @override
  String get panchangamNakshatra => 'நட்சத்திரம்';

  @override
  String get panchangamYoga => 'யோகம்';

  @override
  String get panchangamKarana => 'கரணம்';

  @override
  String get panchangamSunrise => 'சூரிய உதயம்';

  @override
  String get panchangamSunset => 'சூரிய அஸ்தமனம்';

  @override
  String get panchangamRahuKalam => 'ராகு காலம்';

  @override
  String get panchangamYamagandam => 'எமகண்டம்';

  @override
  String get panchangamGulika => 'குளிகை காலம்';

  @override
  String get vratTitle => 'விரதங்கள் & அனுஷ்டானங்கள்';

  @override
  String get vratAdd => 'எனது விரதங்களில் சேர்க்கவும்';

  @override
  String get vratAdded => 'விரதத்தில் சேர்க்கப்பட்டது';

  @override
  String get vratActive => 'நடப்பு விரதம்';

  @override
  String get vratCompleted => 'விரதம் நிறைவுற்றது';

  @override
  String get festivalCalendarTitle => 'திருவிழா & விரத காலண்டர்';

  @override
  String get festivalUpcoming => 'வரவிருக்கும் பண்டிகைகள்';

  @override
  String get festivalRegional => 'பிராந்திய சிறப்பு';

  @override
  String get festivalSignificance => 'ஆன்மீக முக்கியத்துவம்';

  @override
  String get festivalPujaGuide => 'தொடர்புடைய பூஜை முறை';

  @override
  String get onboardingWelcome => 'வேதம் செயலிக்கு நல்வரவு';

  @override
  String get onboardingSubtitle =>
      'உண்மையான வேத பக்தி மற்றும் ஆன்மீக பயிற்சிக்கான உங்கள் வழிகாட்டி.';

  @override
  String get onboardingStepLanguage => 'செயலி மொழி & ஸ்லோக வரிவடிவம்';

  @override
  String get onboardingStepInterests => 'இஷ்ட தெய்வம்';

  @override
  String get onboardingStepSadhana => 'தினசரி சாதனை இலக்குகள்';

  @override
  String get onboardingStepLocation => 'பஞ்சாங்க இடம்';

  @override
  String get onboardingStepReminders => 'ஆன்மீக நினைவூட்டல்கள்';

  @override
  String get onboardingGetStarted => 'சாதனையைத் தொடங்குக';

  @override
  String get onboardingNext => 'அடுத்து';

  @override
  String get onboardingBack => 'பின்னால்';

  @override
  String get onboardingSkip => 'இப்போது தவிர்க்கவும்';

  @override
  String get commonSave => 'சேமி';

  @override
  String get commonCancel => 'ரத்து';

  @override
  String get commonDone => 'முடிந்தது';

  @override
  String get commonClose => 'மூடு';

  @override
  String get commonConfirm => 'உறுதிப்படுத்து';

  @override
  String get commonRetry => 'மீண்டும் முயற்சி செய்';

  @override
  String get commonSearch => 'தேடுக';
}
