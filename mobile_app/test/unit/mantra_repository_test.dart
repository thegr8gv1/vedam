import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';

void main() {
  group('MantraRepository Tests', () {
    late MantraRepository repository;

    setUp(() {
      repository = MantraRepositoryImpl();
    });

    test('getAllMantras returns complete 455 recordings', () {
      final mantras = repository.getAllMantras();
      expect(mantras.length, equals(455));
    });

    test('getAllCollections returns all 7 core devotional collections', () {
      final collections = repository.getAllCollections();
      expect(collections, containsAll([
        'Surya',
        'Shiva',
        'Venkateswara',
        'Lakshmi Devi',
        'Bhairava',
        'Maha Vidyas',
        'Assorted deities',
      ]));
    });

    test('getMantrasByCollection filters accurately', () {
      final surya = repository.getMantrasByCollection('Surya');
      expect(surya.length, equals(86));
      for (final m in surya) {
        expect(m.collection, equals('Surya'));
      }

      final bhairava = repository.getMantrasByCollection('Bhairava');
      expect(bhairava.length, equals(64));
      for (final m in bhairava) {
        expect(m.collection, equals('Bhairava'));
      }
    });

    test('getBundledMantras returns 31 curated offline recordings', () {
      final bundled = repository.getBundledMantras();
      expect(bundled.length, equals(31));
      for (final m in bundled) {
        expect(m.isBundled, isTrue);
        expect(m.bundledAssetPath, isNotNull);
      }
    });

    test('searchMantras matches title, mantra text, and deity', () {
      final shivaMatches = repository.searchMantras('Mrityunjaya');
      expect(shivaMatches.isNotEmpty, isTrue);

      final gayatriMatches = repository.searchMantras('Gayatri');
      expect(gayatriMatches.length, greaterThan(3));

      final emptyMatches = repository.searchMantras('xyznonexistentquery999');
      expect(emptyMatches, isEmpty);
    });

    test('getMantraById returns correct mantra or null on invalid id', () {
      final first = repository.getMantraById('VEDA-MTR-0001');
      expect(first, isNotNull);
      expect(first!.id, equals('VEDA-MTR-0001'));

      final invalid = repository.getMantraById('INVALID-ID-999');
      expect(invalid, isNull);
    });
  });
}
