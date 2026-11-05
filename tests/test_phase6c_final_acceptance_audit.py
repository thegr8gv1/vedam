"""
Vedic Heritage Platform — Phase 6C Final Acceptance Audit Test Suite
Verifies:
1. Canonical 18 Compositions completeness and metadata integrity.
2. Exact source verse counts totaling 307 verses (including Ganesha Pancharatnam phalasruti & Suprabhatam 4 sections).
3. Exact multilingual translation coverage across 9 regional languages + English (3,070 total active translations).
4. Zero false approvals: All active translations are DRAFT pending accredited scholar panel review.
5. Publication gate enforcement: Blocks commercial release for unreviewed or editorial translations without accredited human scholar sign-off.
6. TranslationView architecture: 7,706 granular views across Bhavartha, Literal, and Tatparya views.
7. Analytics dashboard metrics: Distinction between 22 scheduled Indian languages and 9 regional workflows.
"""

import pytest
from sqlalchemy import func

from automation.reporting.library_analytics import LibraryAnalyticsEngine
from automation.validators.publication_gate import PublicationPreflightGate, PreflightReport
from database.connection import get_db_session
from database.models import (
    ReviewStatus,
    RightsClearanceStatus,
    Text,
    TextualVerificationStatus,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
    VerseType,
)


EXPECTED_CANONICAL_TEXTS = {
    "VEDA-TXT-00001": ("Ganesha Pancharatnam", 6),
    "VEDA-TXT-00002": ("Shiva Tandava Stotram", 16),
    "VEDA-TXT-00003": ("Aditya Hrudayam", 31),
    "VEDA-TXT-00004": ("Madhurashtakam", 9),
    "VEDA-TXT-00005": ("Gayatri Mantra", 1),
    "VEDA-TXT-00006": ("Mahamrityunjaya Mantra", 1),
    "VEDA-TXT-00007": ("Sri Suktam", 16),
    "VEDA-TXT-00008": ("Hanuman Chalisa", 43),
    "VEDA-TXT-00010": ("Lingashtakam", 10),
    "VEDA-TXT-00011": ("Bilvashtakam", 9),
    "VEDA-TXT-00012": ("Surya Ashtakam", 8),
    "VEDA-TXT-00013": ("Sri Venkateswara Suprabhatam", 70),
    "VEDA-TXT-00014": ("Purusha Suktam", 16),
    "VEDA-TXT-00015": ("Durga Suktam", 7),
    "VEDA-TXT-00016": ("Narayana Suktam", 12),
    "VEDA-TXT-00017": ("Suryashtakam (Hymn)", 10),
    "VEDA-TXT-00018": ("Kanakadhara Stotram", 21),
    "VEDA-TXT-00019": ("Mahishasura Mardini Stotram", 21),
}

REGIONAL_LANGS = {"hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"}


def test_audit_canonical_18_compositions():
    """Verify that all 18 canonical compositions exist and are SCHOLAR_VERIFIED."""
    with get_db_session() as session:
        canonical_texts = (
            session.query(Text)
            .filter(Text.content_id.in_(EXPECTED_CANONICAL_TEXTS.keys()))
            .all()
        )
        assert len(canonical_texts) == 18

        for text in canonical_texts:
            title, expected_verses = EXPECTED_CANONICAL_TEXTS[text.content_id]
            assert text.textual_verification_status == TextualVerificationStatus.SCHOLAR_VERIFIED
            assert text.rights_clearance_status == RightsClearanceStatus.GREEN_CLEARED
            assert len(text.verses) == expected_verses, (
                f"{text.content_id} ({title}) verse count mismatch: "
                f"expected {expected_verses}, got {len(text.verses)}"
            )


def test_audit_ganesha_pancharatnam_structure():
    """Verify Ganesha Pancharatnam has 5 stanzas and 1 phalasruti."""
    with get_db_session() as session:
        text = session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        assert text is not None
        assert len(text.verses) == 6
        assert text.verses[0].verse_number == 1
        assert text.verses[4].verse_number == 5
        assert text.verses[5].verse_number == 6
        assert text.verses[5].verse_type == VerseType.PHALASRUTI


def test_audit_venkateswara_suprabhatam_4_sections():
    """Verify Sri Venkateswara Suprabhatam has exactly 70 verses across 4 liturgical sections."""
    with get_db_session() as session:
        text = session.query(Text).filter_by(content_id="VEDA-TXT-00013").first()
        assert text is not None
        assert len(text.verses) == 70

        # Check section boundaries
        v1_29 = [v for v in text.verses if 1 <= v.verse_number <= 29]
        v30_40 = [v for v in text.verses if 30 <= v.verse_number <= 40]
        v41_56 = [v for v in text.verses if 41 <= v.verse_number <= 56]
        v57_70 = [v for v in text.verses if 57 <= v.verse_number <= 70]

        assert len(v1_29) == 29   # Suprabhatam proper
        assert len(v30_40) == 11  # Stotram
        assert len(v41_56) == 16  # Prapatti
        assert len(v57_70) == 14  # Mangalasasanam


def test_audit_source_verse_total():
    """Verify sum of verses across 18 canonical compositions is exactly 307."""
    total_canonical_verses = sum(count for _, count in EXPECTED_CANONICAL_TEXTS.values())
    assert total_canonical_verses == 307

    with get_db_session() as session:
        canonical_texts = (
            session.query(Text)
            .filter(Text.content_id.in_(EXPECTED_CANONICAL_TEXTS.keys()))
            .all()
        )
        db_canonical_verses = sum(len(t.verses) for t in canonical_texts)
        assert db_canonical_verses == 307


def test_audit_multilingual_translation_counts():
    """Verify 3,070 total active translations: 307 English + 2,763 Regional."""
    with get_db_session() as session:
        canonical_verse_ids = (
            session.query(Verse.id)
            .join(Text)
            .filter(Text.content_id.in_(EXPECTED_CANONICAL_TEXTS.keys()))
            .scalar_subquery()
        )

        translations = (
            session.query(Translation)
            .filter(Translation.verse_id.in_(canonical_verse_ids))
            .all()
        )

        assert len(translations) == 3070

        en_translations = [t for t in translations if t.target_language == "en"]
        assert len(en_translations) == 307

        regional_translations = [t for t in translations if t.target_language in REGIONAL_LANGS]
        assert len(regional_translations) == 2763
        assert len(regional_translations) == 307 * 9

        # Verify exact counts per regional language
        for lang in REGIONAL_LANGS:
            lang_count = sum(1 for t in translations if t.target_language == lang)
            assert lang_count == 307, f"Language {lang} has {lang_count} translations, expected 307"


def test_audit_zero_false_approvals():
    """Verify that zero active translations carry uncredited APPROVED status."""
    with get_db_session() as session:
        false_approvals = (
            session.query(Translation)
            .filter(
                Translation.review_status == ReviewStatus.APPROVED,
                (Translation.reviewer.is_(None) | (Translation.reviewer == ""))
            )
            .count()
        )
        assert false_approvals == 0

        # Verify that all 123 pilot English translations (6+16+31+9+1+1+16+43) are DRAFT
        pilot_texts = [f"VEDA-TXT-{i:05d}" for i in range(1, 9)]
        pilot_en = (
            session.query(Translation)
            .join(Verse)
            .join(Text)
            .filter(Text.content_id.in_(pilot_texts), Translation.target_language == "en")
            .all()
        )
        assert len(pilot_en) == 123
        for t in pilot_en:
            # All unaccredited pilot English translations are strictly DRAFT
            assert t.review_status == ReviewStatus.DRAFT


def test_audit_publication_preflight_gate_enforcement():
    """Verify that PublicationPreflightGate blocks commercial release for draft translations."""
    with get_db_session() as session:
        text = session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        assert text is not None

        # Commercial release MUST fail on unapproved draft translations
        report_commercial = PublicationPreflightGate.evaluate(
            text, target_channel="commercial_release"
        )
        assert report_commercial.can_publish is False
        failed_rule_ids = [c.rule_id for c in report_commercial.checks if not c.passed]
        assert "PUB-010" in failed_rule_ids

        # Scholarly review channel passes text with draft translations for inspection
        report_scholarly = PublicationPreflightGate.evaluate(
            text, target_channel="scholarly_review"
        )
        assert report_scholarly.can_publish is True


def test_audit_translation_view_architecture():
    """Verify translation views: 7,706 views across Bhavartha, Literal, and Tatparya."""
    with get_db_session() as session:
        total_views = session.query(TranslationView).count()
        assert total_views == 7706

        bhavartha_cnt = session.query(TranslationView).filter_by(view_type=TranslationType.BHAVARTHA).count()
        literal_cnt = session.query(TranslationView).filter_by(view_type=TranslationType.LITERAL).count()
        tatparya_cnt = session.query(TranslationView).filter_by(view_type=TranslationType.TATPARYA).count()

        assert bhavartha_cnt == 3070
        assert literal_cnt == 2318
        assert tatparya_cnt == 2318

        # Check relationships on Verse and Translation
        sample_v = session.query(Verse).filter_by(verse_id="VEDA-TXT-00007-V001").first()
        assert sample_v is not None
        assert len(sample_v.translation_views) == 28  # 10 bhavartha + 9 literal + 9 tatparya = 28


def test_audit_analytics_dashboard_metrics():
    """Verify dashboard metrics accurately distinguish 22 scheduled vs 9 active regional languages."""
    with get_db_session() as session:
        metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(session)

        assert metrics.scheduled_indian_languages_count == 22
        assert metrics.active_regional_workflows_count == 9
        assert metrics.verified_complete_texts == 18
        assert metrics.total_verified_verses == 307
        assert metrics.draft_localization_coverage_verses == 307
        assert metrics.draft_localization_coverage_pct == 100.0
        assert metrics.scholar_approved_translations == 0
        assert metrics.commercial_publication_ready_translations == 0
        assert metrics.translations_awaiting_scholarly_review == 3070
        assert metrics.translation_views_total == 7706
