// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'వేదం';

  @override
  String get navHome => 'హోమ్';

  @override
  String get navLibrary => 'గ్రంథాలయం';

  @override
  String get navSadhana => 'సాధన';

  @override
  String get navSaved => 'భద్రపరిచినవి';

  @override
  String get navSettings => 'అమరికలు';

  @override
  String get offlineModeBanner =>
      'ఆఫ్‌లైన్ మోడ్ — స్థానిక స్తోత్రాలు & సాధనలు అందుబాటులో ఉన్నాయి';

  @override
  String get offlineUnavailableAudio => 'ఆడియోకు నెట్‌వర్క్ కనెక్షన్ అవసరం';

  @override
  String get offlineAvailable => 'ఆఫ్‌లైన్‌లో అందుబాటులో ఉంది';

  @override
  String get offlineIndicator => 'ఆఫ్‌లైన్';

  @override
  String get homeDailyDarshan => 'నిత్య దర్శనం';

  @override
  String get homePanchangamPreview => 'నేటి పంచాంగం';

  @override
  String get homeDailyRoutine => 'నిత్య ఆధ్యాత్మిక సాధన';

  @override
  String get homeJapaPractice => 'నిత్య జప సాధన';

  @override
  String get homeUpcomingVrat => 'రాబోయే వ్రతాలు & నియమాలు';

  @override
  String get homeScriptureProgress => 'స్తోత్ర పఠనం';

  @override
  String get homeFestivalCalendar => 'పండుగలు & విశేష దినాల క్యాలెండర్';

  @override
  String get homeDevotionalFocus => 'ఉపాసనా దైవం';

  @override
  String get homeQuickAccess => 'త్వరిత దర్శనం';

  @override
  String get settingsTitle => 'అమరికలు & ప్రాధాన్యతలు';

  @override
  String get settingsLanguage => 'యాప్ భాష';

  @override
  String get settingsLanguageSubtitle => 'యాప్ ప్రదర్శన భాషను ఎంచుకోండి';

  @override
  String get settingsScript => 'స్తోత్ర లిపి';

  @override
  String get settingsScriptSubtitle => 'శ్లోకాల ప్రధాన లిపి';

  @override
  String get settingsTheme => 'రూపురేఖలు';

  @override
  String get settingsThemeSacredLight => 'పవిత్ర వెలుగు (కాషాయం & పాలరాయి)';

  @override
  String get settingsThemeTempleNight => 'కోవెల రాత్రి (కృష్ణశిల & స్వర్ణం)';

  @override
  String get settingsThemeSystem => 'సిస్టమ్ డిఫాల్ట్';

  @override
  String get settingsTextScale => 'అక్షర పరిమాణం';

  @override
  String get settingsTextScaleRegular => 'సాధారణం';

  @override
  String get settingsTextScaleLarge => 'పెద్దది';

  @override
  String get settingsTextScaleExtraLarge => 'ఆధ్యాత్మిక ఏకాగ్రత (చాలా పెద్దది)';

  @override
  String get settingsDevotionalFocus => 'ఉపాసనా దైవం';

  @override
  String get settingsSadhanaGoals => 'నిత్య సాధన లక్ష్యాలు';

  @override
  String get settingsReminders => 'ఆధ్యాత్మిక జ్ఞాపికలు';

  @override
  String get settingsLocation => 'పంచాంగ స్థలం';

  @override
  String get settingsRerunOnboarding => 'పరిచయ ప్రక్రియను పునఃప్రారంభించండి';

  @override
  String get settingsAbout => 'వేదం గురించి';

  @override
  String get libraryTitle => 'స్తోత్ర గ్రంథాలయం';

  @override
  String get librarySearchPlaceholder => 'స్తోత్రాలు, మంత్రాలను వెతకండి...';

  @override
  String libraryVerseCount(int count) {
    return '$count శ్లోకాలు';
  }

  @override
  String get libraryRecent => 'ఇటీవల చదివినవి';

  @override
  String get libraryFavorites => 'ఇష్టమైనవి';

  @override
  String get libraryAll => 'అన్ని స్తోత్రాలు';

  @override
  String readerVerse(int number) {
    return 'శ్లోకం $number';
  }

  @override
  String readerVerseOf(int current, int total) {
    return 'శ్లోకం $current / $total';
  }

  @override
  String get readerSourceText => 'మూల శ్లోకం';

  @override
  String get readerTransliteration => 'లిప్యంతరీకరణ';

  @override
  String get readerTranslation => 'అనువాదం (చిత్తుప్రతి)';

  @override
  String get readerCommentary => 'వ్యాఖ్యానం';

  @override
  String get readerScholarlyDisclaimer =>
      'అనువాదం పరిశీలనలో ఉంది. ప్రామాణిక సంప్రదాయ భాష్యాన్ని సంప్రదించండి.';

  @override
  String get readerLearningMode => 'ఏకాగ్రతా అధ్యయన మోడ్';

  @override
  String get japaTitle => 'జప సాధన';

  @override
  String japaTargetLabel(int count) {
    return 'లక్ష్యం: $count జపాలు';
  }

  @override
  String japaCompletedChants(int completed, int target) {
    return '$completed / $target జపాలు పూర్తయ్యాయి';
  }

  @override
  String japaChantsRemaining(int count) {
    return 'ఇంకా $count మిగిలి ఉన్నాయి';
  }

  @override
  String japaMalaCompleted(int count) {
    return '$count మాల పూర్తయింది';
  }

  @override
  String get japaTapToCount => 'లెక్కించడానికి తాకండి';

  @override
  String get japaTargetSelector => 'జప సంఖ్యను ఎంచుకోండి';

  @override
  String get japaCustomCount => 'సొంత సంఖ్య';

  @override
  String get japaStartChanting => 'జపం ప్రారంభించండి';

  @override
  String get japaReset => 'తిరిగి ప్రారంభించు';

  @override
  String get audioPlay => 'ప్లే చేయండి';

  @override
  String get audioPause => 'ఆపండి';

  @override
  String get audioResume => 'కొనసాగించండి';

  @override
  String get audioStop => 'ముగించండి';

  @override
  String get audioBundledOffline => 'ఆఫ్‌లైన్‌లో అందుబాటులో ఉంది';

  @override
  String get audioStreamingNetwork => 'ఆన్‌లైన్ స్ట్రీమ్';

  @override
  String get sadhanaTitle => 'నిత్య సాధన';

  @override
  String get sadhanaMorning => 'ప్రాతః స్మరణం (ఉదయం)';

  @override
  String get sadhanaEvening => 'సాయం సంధ్య (సాయంత్రం)';

  @override
  String get sadhanaDailyPuja => 'నిత్య పూజా విధానాలు';

  @override
  String sadhanaStep(int step, int total) {
    return 'విధానం $step / $total';
  }

  @override
  String get sadhanaComplete => 'పూర్తయింది';

  @override
  String get sadhanaMarkComplete => 'పూర్తయినట్లు గుర్తించండి';

  @override
  String get panchangamTitle => 'పంచాంగం';

  @override
  String get panchangamTithi => 'తిథి';

  @override
  String get panchangamNakshatra => 'నక్షత్రం';

  @override
  String get panchangamYoga => 'యోగం';

  @override
  String get panchangamKarana => 'కరణం';

  @override
  String get panchangamSunrise => 'సూర్యోదయం';

  @override
  String get panchangamSunset => 'సూర్యాస్తమయం';

  @override
  String get panchangamRahuKalam => 'రాహు కాలం';

  @override
  String get panchangamYamagandam => 'యమగండం';

  @override
  String get panchangamGulika => 'గుళిక కాలం';

  @override
  String get vratTitle => 'వ్రతాలు & నియమాలు';

  @override
  String get vratAdd => 'నా వ్రతాలలో చేర్చండి';

  @override
  String get vratAdded => 'వ్రతాలలో చేర్చబడింది';

  @override
  String get vratActive => 'ప్రస్తుత వ్రతం';

  @override
  String get vratCompleted => 'వ్రతం పూర్తయింది';

  @override
  String get festivalCalendarTitle => 'పండుగలు & విశేష దినాలు';

  @override
  String get festivalUpcoming => 'రాబోయే పండుగలు';

  @override
  String get festivalRegional => 'ప్రాంతీయ విశేషం';

  @override
  String get festivalSignificance => 'ఆధ్యాత్మిక ప్రాశస్త్యం';

  @override
  String get festivalPujaGuide => 'సంబంధిత పూజా విధానం';

  @override
  String get onboardingWelcome => 'వేదం కు స్వాగతం';

  @override
  String get onboardingSubtitle =>
      'ప్రామాణిక వైదిక భక్తి మరియు ఆధ్యాత్మిక సాధనకు మీ ఆత్మీయ నేస్తం.';

  @override
  String get onboardingStepLanguage => 'యాప్ భాష & స్తోత్ర లిపి';

  @override
  String get onboardingStepInterests => 'ఉపాసనా దైవం';

  @override
  String get onboardingStepSadhana => 'నిత్య సాధన లక్ష్యాలు';

  @override
  String get onboardingStepLocation => 'పంచాంగ స్థలం';

  @override
  String get onboardingStepReminders => 'ఆధ్యాత్మిక జ్ఞాపికలు';

  @override
  String get onboardingGetStarted => 'సాధన ప్రారంభించండి';

  @override
  String get onboardingNext => 'తదుపరి';

  @override
  String get onboardingBack => 'వెనుకకు';

  @override
  String get onboardingSkip => 'ఇప్పుడే కాదు';

  @override
  String get commonSave => 'భద్రపరచు';

  @override
  String get commonCancel => 'రద్దు';

  @override
  String get commonDone => 'పూర్తి';

  @override
  String get commonClose => 'మూసివేయి';

  @override
  String get commonConfirm => 'నిర్ధారించు';

  @override
  String get commonRetry => 'మళ్ళీ ప్రయత్నించు';

  @override
  String get commonSearch => 'వెతకండి';
}
