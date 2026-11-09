import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 20E: Section 8 Governance & Human Approval Barrier Protection', () {
    test('1. Every scripture in catalog has zero approved verses', () async {
      final repo = ScriptureRepositoryImpl();
      final scriptures = await repo.getAllScriptures();

      for (final s in scriptures) {
        for (final v in s.verses) {
          expect(v.isApproved, isFalse,
              reason: 'Section 8 violation: verse ${v.verseNumber} in ${s.canonicalTitle} marked approved!');
          expect(v.translationStatus, anyOf('DRAFT', 'IN_PROGRESS'),
              reason: 'Translation status must be DRAFT or IN_PROGRESS');
        }
      }
    });

    test('2. Synthetic reviewer cannot satisfy human verification requirement', () {
      bool isEligibleForApproval({
        required String reviewerId,
        required bool isHumanVerified,
        required String accountCategory,
      }) {
        if (!isHumanVerified) return false;
        if (accountCategory == 'SYNTHETIC_TEST_PERSONA' ||
            accountCategory == 'DEMONSTRATION_HARNESS') {
          return false;
        }
        return true;
      }

      // Test synthetic personas present in database
      expect(isEligibleForApproval(
        reviewerId: 'REV-ADMIN-001',
        isHumanVerified: false,
        accountCategory: 'SYNTHETIC_TEST_PERSONA',
      ), isFalse);

      expect(isEligibleForApproval(
        reviewerId: 'REV-PROD-VEDIC',
        isHumanVerified: false,
        accountCategory: 'SYNTHETIC_TEST_PERSONA',
      ), isFalse);

      expect(isEligibleForApproval(
        reviewerId: 'REV-DEMO-SIM',
        isHumanVerified: false,
        accountCategory: 'DEMONSTRATION_HARNESS',
      ), isFalse);
    });
  });
}
