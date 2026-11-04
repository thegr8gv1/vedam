"""
Tests for Phase 4B: Verified Full-Text Pilot Ingestion
Validates unabridged verse counts, Awadhi meters, Vedic swara annotations,
and multi-script transliterations across all 8 pilot compositions.
"""

import pytest
from sqlalchemy.orm import Session

from automation.validators.qa_engine import ContentQualityAssuranceEngine, TextCompletenessStatus
from database.connection import get_db_session
from database.models import Text, Verse, VerseType


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


class TestFullTextPilotIngestion:
    """Verifies complete, unabridged ingestion for the 8 pilot compositions."""

    def test_all_eight_pilots_present(self, db_session: Session):
        pilot_ids = [
            "VEDA-TXT-00001", "VEDA-TXT-00002", "VEDA-TXT-00003", "VEDA-TXT-00004",
            "VEDA-TXT-00005", "VEDA-TXT-00006", "VEDA-TXT-00007", "VEDA-TXT-00008",
        ]
        for cid in pilot_ids:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            assert text is not None, f"Pilot text {cid} missing from database."
            assert text.verse_count > 0

    def test_ganesha_pancharatnam_exact_verse_count(self, db_session: Session):
        """Vani Vilas 1910 critical edition: 5 Vasantatilaka stanzas + 1 Phalasruti = 6 verses."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        assert t.verse_count == 6
        assert len(t.verses) == 6
        sorted_v = sorted(t.verses, key=lambda v: v.verse_number)
        assert sorted_v[-1].verse_type == VerseType.PHALASRUTI
        assert "महागणेशपञ्चरत्नमादरेण" in sorted_v[-1].devanagari_text

    def test_madhurashtakam_exact_verse_count(self, db_session: Session):
        """NSP 1912 critical edition: 8 Totaka stanzas + 1 Phalasruti = 9 units."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00004").first()
        assert t.verse_count == 9
        assert len(t.verses) == 9
        sorted_v = sorted(t.verses, key=lambda v: v.verse_number)
        assert sorted_v[0].meter == "Totaka"
        assert sorted_v[-1].verse_type == VerseType.PHALASRUTI

    def test_shiva_tandava_stotram_exact_verse_count(self, db_session: Session):
        """NSP 1912 critical edition: 14 Panchachamara stanzas + 2 Phalasruti = 16 verses."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00002").first()
        assert t.verse_count == 16
        assert len(t.verses) == 16
        sorted_v = sorted(t.verses, key=lambda v: v.verse_number)
        assert sorted_v[14].verse_type == VerseType.PHALASRUTI
        assert sorted_v[15].verse_type == VerseType.PHALASRUTI

    def test_aditya_hrudayam_exact_verse_count(self, db_session: Session):
        """Valmiki Ramayana Yuddha Kanda 105 (NSP 1902): 31 epic verses."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00003").first()
        assert t.verse_count == 31
        assert len(t.verses) == 31
        sorted_v = sorted(t.verses, key=lambda v: v.verse_number)
        assert "ततो युद्धपरिश्रान्तं" in sorted_v[0].devanagari_text
        assert "त्वरेति" in sorted_v[30].devanagari_text

    def test_hanuman_chalisa_exact_verse_count_and_meters(self, db_session: Session):
        """Munshi Nawal Kishore 1874: 2 opening Dohas, 40 Chaupais, 1 closing Doha = 43 units."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00008").first()
        assert t.verse_count == 43
        assert len(t.verses) == 43
        sorted_v = sorted(t.verses, key=lambda v: v.verse_number)

        # Dohas at indices 0, 1, and 42
        assert sorted_v[0].verse_type == VerseType.DOHA
        assert sorted_v[1].verse_type == VerseType.DOHA
        assert sorted_v[42].verse_type == VerseType.DOHA
        assert "श्रीगुरु चरन सरोज रज" in sorted_v[0].devanagari_text
        assert "पवनतनय संकट हरन" in sorted_v[42].devanagari_text

        # Chaupais from index 2 to 41 (40 chaupais)
        for i in range(2, 42):
            assert sorted_v[i].verse_type == VerseType.CHAUPAI, f"Verse {i+1} should be CHAUPAI"

    def test_sri_suktam_swara_accents_preserved(self, db_session: Session):
        """Scheftelowitz 1906 / VSM 1946: 15 canonical Vedic Riks + 1 Phalasruti with Swaras."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00007").first()
        assert t.verse_count == 16
        assert len(t.verses) == 16
        sorted_v = sorted(t.verses, key=lambda v: v.verse_number)

        # Check Vedic swaras in Rik 1
        rik1 = sorted_v[0]
        assert rik1.vedic_accents_present is True
        assert rik1.vedic_accent_annotations is not None
        assert rik1.vedic_accent_annotations.get("has_vedic_accents") is True
        assert rik1.vedic_accent_annotations.get("total_accent_count") > 0

    def test_qa_engine_approvals_on_all_pilots(self, db_session: Session):
        """All 8 pilot texts must pass QA audit with VERIFIED_FULL_TEXT status."""
        pilot_ids = [
            "VEDA-TXT-00001", "VEDA-TXT-00002", "VEDA-TXT-00003", "VEDA-TXT-00004",
            "VEDA-TXT-00005", "VEDA-TXT-00006", "VEDA-TXT-00007", "VEDA-TXT-00008",
        ]
        for cid in pilot_ids:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            report = ContentQualityAssuranceEngine.audit_text(text)
            assert report.completeness_status == TextCompletenessStatus.VERIFIED_FULL_TEXT
            assert report.passed_all_mandatory_checks is True, f"Failed checks for {cid}: {[i.message for i in report.issues]}"

    def test_translations_and_transliterations_coverage(self, db_session: Session):
        """Every verse across all 8 pilot texts must have IAST and approved English translations."""
        pilot_ids = [f"VEDA-TXT-{i:05d}" for i in range(1, 9)]
        for cid in pilot_ids:
            t = db_session.query(Text).filter_by(content_id=cid).first()
            assert t is not None
            for v in t.verses:
                assert v.iast_text is not None and len(v.iast_text) > 0, f"Missing IAST in {v.verse_id}"
                assert len(v.translations) > 0, f"Missing translation in {v.verse_id}"
                assert len(v.transliterations) >= 4, f"Missing regional script transliterations in {v.verse_id}"
