import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/data/fixtures/authentic_mantras_data.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';

void main() {
  group('Puja Guides Content & Governance Audit Tests', () {
    test('All 6 initial puja guides are present with valid metadata', () {
      final guides = AuthenticPujaGuidesData.allGuides;
      expect(guides.length, 6);

      final expectedIds = [
        'guide_ganesh_puja',
        'guide_shiva_puja',
        'guide_vishnu_puja',
        'guide_lakshmi_puja',
        'guide_morning_prayer',
        'guide_evening_prayer',
      ];

      for (final id in expectedIds) {
        final guide = AuthenticPujaGuidesData.getGuideById(id);
        expect(guide, isNotNull, reason: 'Guide $id should exist');
        expect(guide!.title.isNotEmpty, true);
        expect(guide.sanskritTitle.isNotEmpty, true);
        expect(guide.deity.isNotEmpty, true);
        expect(guide.tradition.isNotEmpty, true);
        expect(guide.shortIntro.isNotEmpty, true);
        expect(guide.purposeAndContext.isNotEmpty, true);
        expect(guide.preparation.isNotEmpty, true);
        expect(guide.materialsList.isNotEmpty, true);
        expect(guide.steps.isNotEmpty, true);
        expect(guide.estimatedDurationMinutes, greaterThan(0));
      }
    });

    test('Editorial and regional variance transparency in every guide', () {
      for (final guide in AuthenticPujaGuidesData.allGuides) {
        expect(guide.editorialStatus, 'Verified Editorial Guide');
        expect(guide.sourceInfo.isNotEmpty, true);
        expect(guide.regionalVarianceNote.isNotEmpty, true);
        expect(
          guide.regionalVarianceNote.toLowerCase().contains('sampradaya') ||
              guide.regionalVarianceNote.toLowerCase().contains('domestic') ||
              guide.regionalVarianceNote.toLowerCase().contains('lineage'),
          true,
          reason: '${guide.id} should explicitly document regional/lineage variance',
        );
        expect(guide.lastReviewedDate, '2026-11-05');
      }
    });

    test('All steps contain ordered numbers, actions, and readable text', () {
      for (final guide in AuthenticPujaGuidesData.allGuides) {
        for (int i = 0; i < guide.steps.length; i++) {
          final step = guide.steps[i];
          expect(step.stepNumber, i + 1, reason: 'Step numbers must be strictly 1-based sequential');
          expect(step.stepName.isNotEmpty, true);
          expect(step.actionDescription.isNotEmpty, true);

          if (step.sanskritMantra != null) {
            expect(step.sanskritMantra!.isNotEmpty, true);
            expect(step.meaning, isNotNull, reason: 'Every Sanskrit mantra must carry meaning');
            expect(step.meaning!.isNotEmpty, true);
          }
        }
      }
    });

    test('All linked mantras map to genuine recordings in authentic catalog', () {
      final allMantraIds = AuthenticMantrasData.allMantras.map((m) => m.id).toSet();

      int verifiedLinksCount = 0;
      for (final guide in AuthenticPujaGuidesData.allGuides) {
        for (final step in guide.steps) {
          if (step.linkedMantraId != null) {
            expect(
              allMantraIds.contains(step.linkedMantraId),
              true,
              reason: 'Linked mantra ${step.linkedMantraId} in ${guide.id} must exist in catalog',
            );
            expect(step.linkedMantraTitle, isNotNull);
            verifiedLinksCount++;
          }
        }
      }

      // Ensure significant audio integration across guides
      expect(verifiedLinksCount, greaterThanOrEqualTo(8));
    });

    test('Unknown guide ID lookup returns null safely', () {
      expect(AuthenticPujaGuidesData.getGuideById('non_existent_guide'), isNull);
    });
  });
}
