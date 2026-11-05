import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';

void main() {
  group('ScriptureRepository Tests', () {
    late ScriptureRepositoryImpl repository;

    setUp(() {
      repository = ScriptureRepositoryImpl();
    });

    test('getAllScriptures returns all 20 canonical scriptures', () async {
      final scriptures = await repository.getAllScriptures();
      expect(scriptures.length, 20);
      expect(scriptures.first.canonicalTitle, 'Ganesha Pancharatnam');
    });

    test('getScripturesByCategory filters accurately', () async {
      final stotras = await repository.getScripturesByCategory('Stotra');
      expect(stotras.isNotEmpty, isTrue);
      for (final s in stotras) {
        expect(s.category.toLowerCase(), 'stotra');
      }

      final suktams = await repository.getScripturesByCategory('Suktam');
      expect(suktams.isNotEmpty, isTrue);
      for (final s in suktams) {
        expect(s.category.toLowerCase(), 'suktam');
      }
    });

    test('getScripturesByDeity filters accurately', () async {
      final shivaTexts = await repository.getScripturesByDeity('Lord Shiva');
      expect(shivaTexts.isNotEmpty, isTrue);
      for (final s in shivaTexts) {
        expect(s.deity.toLowerCase(), contains('shiva'));
      }
    });

    test('searchScriptures matches title, deity, and composer', () async {
      final searchByTitle = await repository.searchScriptures('Tandava');
      expect(searchByTitle.length, 1);
      expect(searchByTitle.first.canonicalTitle, 'Shiva Tandava Stotram');

      final searchByDeity = await repository.searchScriptures('Surya');
      expect(searchByDeity.length, greaterThanOrEqualTo(2));

      final searchByComposer = await repository.searchScriptures('Shankaracharya');
      expect(searchByComposer.isNotEmpty, isTrue);
    });

    test('getScriptureById returns scripture with verses and transliterations', () async {
      final ganesha = await repository.getScriptureById(1);
      expect(ganesha, isNotNull);
      expect(ganesha!.canonicalTitle, 'Ganesha Pancharatnam');
      expect(ganesha.verses.length, 6);

      final v1 = ganesha.verses.first;
      expect(v1.verseNumber, 1);
      expect(v1.devanagariText.isNotEmpty, isTrue);
      expect(v1.iastText.isNotEmpty, isTrue);
      expect(v1.transliterations.containsKey('telugu'), isTrue);
    });

    test('Section 8 Governance Invariant: Zero approved translations in production catalog', () async {
      final scriptures = await repository.getAllScriptures();
      for (final s in scriptures) {
        for (final v in s.verses) {
          expect(v.isApproved, isFalse,
              reason: 'Section 8 barrier violated: Translation in ${s.canonicalTitle} marked approved!');
          expect(v.translationStatus, anyOf('DRAFT', 'IN_PROGRESS'),
              reason: 'Translation status must be DRAFT or IN_PROGRESS');
        }
      }
    });

    test('getDailyDarshan provides complete liturgical data', () async {
      final darshan = await repository.getDailyDarshan();
      expect(darshan.dailyVerseTitle.isNotEmpty, isTrue);
      expect(darshan.dailyVerseDevanagari.isNotEmpty, isTrue);
      expect(darshan.tithi.isNotEmpty, isTrue);
      expect(darshan.nakshatra.isNotEmpty, isTrue);
    });
  });
}
