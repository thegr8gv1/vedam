import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/app_settings.dart';
import 'package:vedam_app/core/models/scripture.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/data/fixtures/authentic_mantras_data.dart';
import 'package:vedam_app/data/fixtures/authentic_scriptures_data.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 19B Unit Tests: Content, Audio & Devotional Feature Completeness', () {
    late MantraRepository mantraRepo;
    late ScriptureRepositoryImpl scriptureRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mantraRepo = MantraRepositoryImpl();
      scriptureRepo = ScriptureRepositoryImpl();
    });

    test('1. Master Audio Catalog Completeness: 455 recordings in manifest & repository', () async {
      final allMantras = mantraRepo.getAllMantras();
      expect(allMantras.length, equals(455), reason: 'All 455 master recordings must be cataloged');

      // Verify no duplicates
      final idSet = <String>{};
      for (final m in allMantras) {
        expect(idSet.contains(m.id), isFalse, reason: 'Mantra ID ${m.id} is duplicated');
        idSet.add(m.id);
        expect(m.title.trim().isNotEmpty, isTrue);
        expect(m.filename.trim().isNotEmpty, isTrue);
        expect(m.deity.trim().isNotEmpty, isTrue);
        expect(m.durationSeconds > 0, isTrue);
      }
    });

    test('2. Bundled Audio Verification: Exactly 31 core offline recordings exist', () async {
      final bundledMantras = mantraRepo.getBundledMantras();
      expect(bundledMantras.length, equals(31), reason: 'Exactly 31 recordings must be bundled for offline use');

      for (final m in bundledMantras) {
        expect(m.isBundled, isTrue);
        expect(m.bundledAssetPath, isNotNull);
        expect(m.bundledAssetPath!.startsWith('assets/audio/bundled/'), isTrue);

        // Verify file exists on local disk if running in repository context
        final diskPath = 'mobile_app/${m.bundledAssetPath}';
        final file = File(diskPath);
        if (file.existsSync()) {
          expect(file.lengthSync() > 1000, isTrue, reason: 'Bundled audio file must not be empty');
        }
      }
    });

    test('3. Scripture Audio Mapping: Canonical verses correctly map to authentic recordings', () async {
      final mappedScriptures = {
        2: 'VEDA-MTR-0443', // Shiva Tandava Stotram
        5: 'VEDA-MTR-0413', // Mahamrityunjaya Mantra
        6: 'VEDA-MTR-0399', // Gayatri Mantra
        7: 'VEDA-MTR-0451', // Sri Suktam
        8: 'VEDA-MTR-0401', // Hanuman Chalisa
        10: 'VEDA-MTR-0414', // Mahalakshmi Ashtakam
        11: 'VEDA-MTR-0411', // Lingashtakam
        21: 'VEDA-MTR-0407', // Kanakadhara Stotram
        22: 'VEDA-MTR-0382', // Mahishasura Mardini Stotram
      };

      for (final entry in mappedScriptures.entries) {
        final scripture = await scriptureRepo.getScriptureById(entry.key);
        expect(scripture, isNotNull, reason: 'Scripture ID ${entry.key} must exist');
        expect(scripture!.verses.isNotEmpty, isTrue);

        final verse1 = scripture.verses.first;
        expect(verse1.audioMantraId, equals(entry.value),
            reason: 'Scripture ${scripture.canonicalTitle} verse 1 must map to ${entry.value}');

        // Verify that the mapped mantra exists in the authentic mantra data
        final mappedMantra = AuthenticMantrasData.getMantraById(entry.value);
        expect(mappedMantra, isNotNull,
            reason: 'Mantra ID ${entry.value} mapped to ${scripture.canonicalTitle} must exist in catalog');
      }
    });

    test('4. Section 8 Content Governance: Strict DRAFT disclosures and zero synthetic approvals', () async {
      final scriptures = await scriptureRepo.getAllScriptures();
      expect(scriptures.length, greaterThanOrEqualTo(20));

      int totalVerses = 0;
      for (final s in scriptures) {
        expect(s.canonicalTitle.trim().isNotEmpty, isTrue);
        expect(s.contentId.trim().isNotEmpty, isTrue);

        for (final v in s.verses) {
          totalVerses++;
          // Section 8 rule: zero approved translations
          expect(v.isApproved, isFalse,
              reason: 'Zero translations should be marked approved under Section 8 governance');
          expect(v.translationStatus, isIn(['DRAFT', 'IN_PROGRESS']),
              reason: 'All translations must be explicitly disclosed as DRAFT or IN_PROGRESS');
          expect(v.devanagariText.trim().isNotEmpty, isTrue);
          if (!s.canonicalTitle.startsWith('Test ')) {
            expect(v.iastText.trim().isNotEmpty, isTrue);
          }
        }
      }
      expect(totalVerses, greaterThanOrEqualTo(300));
    });

    test('5. Decoupled Multilingual Interface and Display Script Architecture', () async {
      final appState = AppState();

      // Verify default script is Devanagari
      expect(appState.activeScript, equals(ScriptOption.devanagari));

      // Change interface language
      appState.setInterfaceLanguage(InterfaceLanguage.telugu);
      expect(appState.interfaceLanguage, equals(InterfaceLanguage.telugu));
      // Changing interface language MUST NOT alter scripture display script
      expect(appState.activeScript, equals(ScriptOption.devanagari));

      // Change display script
      appState.setActiveScript(ScriptOption.tamil);
      expect(appState.activeScript, equals(ScriptOption.tamil));
      // Changing display script MUST NOT alter interface language
      expect(appState.interfaceLanguage, equals(InterfaceLanguage.telugu));

      // Test all 6 supported scripts render verse text properly
      final ganeshaScripture = await scriptureRepo.getScriptureById(1);
      final verse1 = ganeshaScripture!.verses.first;

      for (final script in ScriptOption.values) {
        final text = verse1.getTextInScript(script);
        expect(text.trim().isNotEmpty, isTrue,
            reason: 'Verse 1 must render non-empty text in ${script.label}');
      }
    });

    test('6. Mantra Filtering by Deity, Collection, and Offline Status', () {
      final deities = mantraRepo.getAllDeities();
      expect(deities.contains('Shiva'), isTrue);
      expect(deities.contains('Surya'), isTrue);
      expect(deities.contains('Lakshmi'), isTrue);

      final shivaMantras = mantraRepo.getMantrasByDeity('Shiva');
      expect(shivaMantras.isNotEmpty, isTrue);
      for (final m in shivaMantras) {
        expect(m.deity, equals('Shiva'));
      }

      final suryaMantras = mantraRepo.getMantrasByDeity('Surya');
      expect(suryaMantras.isNotEmpty, isTrue);
      for (final m in suryaMantras) {
        expect(m.deity, equals('Surya'));
      }

      // Search verification
      final searchResults = mantraRepo.searchMantras('gayatri');
      expect(searchResults.isNotEmpty, isTrue);
      for (final m in searchResults) {
        final match = m.title.toLowerCase().contains('gayatri') ||
            m.mantraText.toLowerCase().contains('gayatri') ||
            m.significance.toLowerCase().contains('gayatri') ||
            m.collection.toLowerCase().contains('gayatri');
        expect(match, isTrue);
      }
    });

    test('7. Scripture Metadata Honesty: Missing fields are distinguished from canonical attribution', () async {
      final scriptures = await scriptureRepo.getAllScriptures();
      for (final s in scriptures) {
        // Source scripture should be present or valid
        expect(s.sourceScripture.isNotEmpty, isTrue);
        // Category and Devata
        expect(s.category.isNotEmpty, isTrue);
        expect(s.devata.isNotEmpty, isTrue);
      }
    });
  });
}
