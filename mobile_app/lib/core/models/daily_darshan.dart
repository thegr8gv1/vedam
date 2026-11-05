class DailyDarshan {
  final String dateString;
  final String dayName;
  final String paksha;
  final String tithi;
  final String nakshatra;
  final String rahuKalam;
  final String abhijitMuhurat;
  final String presidingDeity;
  final String dailySankalpaMantra;
  final String dailyVerseTitle;
  final String dailyVerseDevanagari;
  final String dailyVerseIast;
  final String dailyVerseMeaningDraft;
  final String dailyVerseAttribution;

  const DailyDarshan({
    required this.dateString,
    required this.dayName,
    required this.paksha,
    required this.tithi,
    required this.nakshatra,
    required this.rahuKalam,
    required this.abhijitMuhurat,
    required this.presidingDeity,
    required this.dailySankalpaMantra,
    required this.dailyVerseTitle,
    required this.dailyVerseDevanagari,
    required this.dailyVerseIast,
    required this.dailyVerseMeaningDraft,
    required this.dailyVerseAttribution,
  });

  static DailyDarshan today() {
    return const DailyDarshan(
      dateString: "Kartika Shukla Trayodashi",
      dayName: "Guruvara (Thursday)",
      paksha: "Shukla Paksha",
      tithi: "Trayodashi (Until 07:42 PM)",
      nakshatra: "Ashwini (Until 05:15 PM)",
      rahuKalam: "01:30 PM - 03:00 PM",
      abhijitMuhurat: "11:45 AM - 12:32 PM",
      presidingDeity: "Sri Dakshinamurthy & Lord Vishnu",
      dailySankalpaMantra: "मम आत्मनः श्रुतिस्मृतिपुराणोक्त फलप्राप्त्यर्थं श्रीपरमेश्वर प्रीत्यर्थं...",
      dailyVerseTitle: "Mahamrityunjaya Vedic Mantra (Rigveda 7.59.12)",
      dailyVerseDevanagari: "ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्।\nउर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात्॥",
      dailyVerseIast: "oṃ tryambakaṃ yajāmahe sugandhiṃ puṣṭivardhanam |\nurvārukamiva bandhanānmṛtyormukṣīya māmṛtāt ||",
      dailyVerseMeaningDraft: "We venerate the Three-Eyed Lord who is fragrant and nourishes all beings. As a ripe melon is severed from its stalk, may we be liberated from the bondage of mortality into the realm of immortality.",
      dailyVerseAttribution: "Rigveda Mandala 7, Sukta 59, Mantra 12 • Rishi Maitravaruni Vasishtha • Chandas Anushtup",
    );
  }
}
