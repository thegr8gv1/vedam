import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';

void main() {
  group('Puja Content Provenance & Governance Verification Tests', () {
    test('All 6 guides contain explicit content verification status and primary references', () {
      final guides = AuthenticPujaGuidesData.allGuides;
      expect(guides.length, 6);

      for (final guide in guides) {
        expect(guide.contentVerificationStatus, 'Curated Traditional Grihya Paddhati');
        expect(guide.primarySourceReferences.isNotEmpty, true,
            reason: '${guide.id} must list primary source references');
        expect(guide.editorialStatus, 'Verified Editorial Guide');
        expect(guide.sourceInfo.isNotEmpty, true);
        expect(guide.regionalVarianceNote.isNotEmpty, true);
      }
    });

    test('Steps clearly separate canonical verses from traditional Grihya actions', () {
      for (final guide in AuthenticPujaGuidesData.allGuides) {
        for (final step in guide.steps) {
          expect(step.stepProvenance, isNotNull,
              reason: 'Step ${step.stepNumber} of ${guide.id} must declare provenance');
          expect(
            step.stepProvenance == 'canonical_verse' ||
                step.stepProvenance == 'traditional_grihya_action',
            true,
          );

          if (step.stepProvenance == 'canonical_verse') {
            expect(step.sanskritMantra, isNotNull);
            expect(step.scripturalSource, isNotNull,
                reason: 'Canonical verse step must cite scriptural source');
          }
        }
      }
    });

    test('Canonical verses cite legitimate Upanishadic, Vedic, or Puranic sources', () {
      final ganeshGuide = AuthenticPujaGuidesData.getGuideById('guide_ganesh_puja')!;
      expect(ganeshGuide.steps.first.scripturalSource!.contains('Purana') ||
          ganeshGuide.steps.first.scripturalSource!.contains('Smriti'), true);

      final shivaGuide = AuthenticPujaGuidesData.getGuideById('guide_shiva_puja')!;
      expect(shivaGuide.steps.last.scripturalSource!.contains('Rigveda') ||
          shivaGuide.steps.last.scripturalSource!.contains('Yajurveda'), true);

      final vishnuGuide = AuthenticPujaGuidesData.getGuideById('guide_vishnu_puja')!;
      expect(vishnuGuide.steps.first.scripturalSource!.contains('Vishnu Sahasranama'), true);

      final lakshmiGuide = AuthenticPujaGuidesData.getGuideById('guide_lakshmi_puja')!;
      expect(lakshmiGuide.steps.first.scripturalSource!.contains('Taittiriya') ||
          lakshmiGuide.steps.first.scripturalSource!.contains('Upanishad'), true);

      final morningGuide = AuthenticPujaGuidesData.getGuideById('guide_morning_prayer')!;
      expect(morningGuide.steps.last.scripturalSource!.contains('Brihadaranyaka Upanishad'), true);
    });
  });
}
