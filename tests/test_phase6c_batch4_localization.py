"""
Tests for Phase 6C Batch 4 Multilingual Localization
Verifies:
1. Hanuman Chalisa (VEDA-TXT-00008): 43 source verses (2 opening Dohas, 40 Chaupais, 1 closing Doha; Awadhi language).
2. Sri Venkateswara Suprabhatam Collection (VEDA-TXT-00013): 70 source verses across 4 canonical sections:
   - Section 1: Suprabhatam (29 verses)
   - Section 2: Stotram (11 verses)
   - Section 3: Prapatti (16 verses)
   - Section 4: Mangalasasanam (14 verses)
3. 1,017 new regional-language translation records across 9 languages (113 * 9).
4. Strict governance: all 1,017 records flagged as ReviewStatus.DRAFT.
5. Three distinct translation views (literal, traditional commentary, devotional Bhavartha).
6. 14-rule Language QA 100% pass rate across all 18 audits (2 texts * 9 languages).
7. Glossary expansion with Awadhi metrics and Sri Vaishnava theological terms.
8. Publication deliverables: 2 Excel (13-col), 2 Word (12-row with TOC for Suprabhatam), 2 JSON bundles,
   audio manifests (1 for HC + 4 discrete section manifests for Suprabhatam + 1 collection manifest),
   and SHA-256 integrity manifest.
9. Final library-wide completion milestone: 100% regional localization across all 18 canonical compositions
   (18/18 localized, 0 awaiting, 307 source verses, 2,763 active regional translations, 3,070 total active translations).
"""

import json
import os
from pathlib import Path
import pytest
from sqlalchemy.orm import Session

from automation.localization.audio_preparation import AudioPreparationEngine
from automation.localization.glossary import SanskritTerminologyGlossary, TerminologyCategory
from automation.localization.hanuman_chalisa import get_hanuman_chalisa_payload
from automation.localization.qa_framework import LanguageQualityAssuranceEngine
from automation.localization.venkateswara_suprabhatam import (
    SUPRABHATAM_SECTIONS,
    get_full_suprabhatam_collection_payload,
)
from automation.reporting.library_analytics import LibraryAnalyticsEngine
from database.connection import get_db_session
from database.models import ReviewStatus, Text, Translation, TranslationType, Verse, VerseType


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


def test_hanuman_chalisa_structure_and_meter(db_session: Session):
    """Verifies Hanuman Chalisa has 43 verses with distinct Doha and Chaupai meters in Awadhi."""
    hc_text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00008").first()
    assert hc_text is not None
    assert hc_text.original_language == "awa"
    assert hc_text.canonical_title == "Hanuman Chalisa"
    assert len(hc_text.verses) == 43
    assert hc_text.verse_count == 43

    verses = sorted(hc_text.verses, key=lambda v: v.verse_number)
    # Verse 1 & 2: Opening Dohas
    assert verses[0].verse_type == VerseType.DOHA
    assert "श्रीगुरु चरन सरोज रज" in verses[0].devanagari_text
    assert verses[1].verse_type == VerseType.DOHA
    assert "बुद्धिहीन तनु जानिके" in verses[1].devanagari_text

    # Verses 3..42: Chaupais (40 verses)
    for v in verses[2:42]:
        assert v.verse_type == VerseType.CHAUPAI

    # Verse 43: Concluding Doha
    assert verses[42].verse_type == VerseType.DOHA
    assert "पवनतनय संकट हरन" in verses[42].devanagari_text

    # Verify payload integrity
    hc_payload = get_hanuman_chalisa_payload()
    assert len(hc_payload) == 43
    # Check that Hindi translation is modern standard Hindi and distinct from raw Awadhi text
    v1_bhavartha = hc_payload[1]["bhavartha"]
    assert "hi" in v1_bhavartha
    assert "चरण-कमलों" in v1_bhavartha["hi"]
    assert v1_bhavartha["hi"] != verses[0].devanagari_text  # Not raw repetition


def test_suprabhatam_four_section_canonical_structure(db_session: Session):
    """Verifies Sri Venkateswara Suprabhatam has 70 verses across 4 canonical sections."""
    sv_text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00013").first()
    assert sv_text is not None
    assert sv_text.original_language == "sa"
    assert len(sv_text.verses) == 70
    assert sv_text.verse_count == 70

    verses = sorted(sv_text.verses, key=lambda v: v.verse_number)

    # Check 4 sections in metadata
    assert len(SUPRABHATAM_SECTIONS) == 4
    assert "SEC-SV-01" in SUPRABHATAM_SECTIONS  # Suprabhatam (29)
    assert "SEC-SV-02" in SUPRABHATAM_SECTIONS  # Stotram (11)
    assert "SEC-SV-03" in SUPRABHATAM_SECTIONS  # Prapatti (16)
    assert "SEC-SV-04" in SUPRABHATAM_SECTIONS  # Mangalasasanam (14)

    # Verify section 1: Suprabhatam (Verses 1 to 29)
    for v in verses[:29]:
        meta = json.loads(v.notes)
        assert meta["section_id"] == "SEC-SV-01"
        assert meta["section_order"] == 1
    assert "कौसल्या सुप्रजा राम" in verses[0].devanagari_text

    # Verify section 2: Stotram (Verses 30 to 40)
    for v in verses[29:40]:
        meta = json.loads(v.notes)
        assert meta["section_id"] == "SEC-SV-02"
        assert meta["section_order"] == 2
    assert "कमलाकुचचूचुककुङ्कुमतो" in verses[29].devanagari_text

    # Verify section 3: Prapatti (Verses 41 to 56)
    for v in verses[40:56]:
        meta = json.loads(v.notes)
        assert meta["section_id"] == "SEC-SV-03"
        assert meta["section_order"] == 3
    # Verse 41 (Prapatti 1) invokes Sri Mahalakshmi (Purushakara)
    assert "ईशानां जगतोऽस्य" in verses[40].devanagari_text
    # Verse 55 (Prapatti 15) invokes Swami Manavala Mamunigal
    assert "सौम्योपयन्तृमुनिना" in verses[54].devanagari_text
    # Verse 56 (Prapatti 16) concludes with Kainkarya prayer
    assert "स्यां किङ्करो वृषगिरीश" in verses[55].devanagari_text

    # Verify section 4: Mangalasasanam (Verses 57 to 70)
    for v in verses[56:70]:
        meta = json.loads(v.notes)
        assert meta["section_id"] == "SEC-SV-04"
        assert meta["section_order"] == 4
        assert "मङ्गलम्" in v.devanagari_text
    assert "श्रियः कान्ताय कल्याणनिधये" in verses[56].devanagari_text
    # Verse 69 (Mangalasasanam 13) mentions Manavala Mamuni
    assert "श्रीमत्सुन्दरजामातृमुनि" in verses[68].devanagari_text


def test_batch4_translation_records_and_draft_governance(db_session: Session):
    """Verifies 1,017 new regional translation records strictly marked as ReviewStatus.DRAFT."""
    regional_langs = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]

    # 1. Hanuman Chalisa (43 * 9 = 387)
    hc_text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00008").first()
    hc_v_ids = [v.id for v in hc_text.verses]
    hc_reg_trans = (
        db_session.query(Translation)
        .filter(Translation.verse_id.in_(hc_v_ids), Translation.target_language.in_(regional_langs))
        .all()
    )
    assert len(hc_reg_trans) == 387
    for tr in hc_reg_trans:
        assert tr.review_status == ReviewStatus.DRAFT
        assert tr.reviewer is None  # Never auto-approved!
        assert "Platform Multilingual Localization Engine" in tr.translator

    # 2. Sri Venkateswara Suprabhatam (70 * 9 = 630)
    sv_text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00013").first()
    sv_v_ids = [v.id for v in sv_text.verses]
    sv_reg_trans = (
        db_session.query(Translation)
        .filter(Translation.verse_id.in_(sv_v_ids), Translation.target_language.in_(regional_langs))
        .all()
    )
    assert len(sv_reg_trans) == 630
    for tr in sv_reg_trans:
        assert tr.review_status == ReviewStatus.DRAFT
        assert tr.reviewer is None  # Never auto-approved!
        assert "Platform Multilingual Localization Engine" in tr.translator

    # Batch 4 total
    assert len(hc_reg_trans) + len(sv_reg_trans) == 1017


def test_three_distinct_translation_views(db_session: Session):
    """Verifies that literal translation, traditional meaning, and devotional Bhavartha are stored."""
    regional_langs = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]

    for cid in ["VEDA-TXT-00008", "VEDA-TXT-00013"]:
        text_record = db_session.query(Text).filter_by(content_id=cid).first()
        for v in text_record.verses[:3]:  # inspect first 3 verses
            for lang in regional_langs:
                tr = [t for t in v.translations if t.target_language == lang][0]
                wbw = tr.word_by_word_json
                assert wbw is not None
                assert "literal_translation" in wbw
                assert len(wbw["literal_translation"]) > 20
                assert "traditional_meaning" in wbw
                assert len(wbw["traditional_meaning"]) > 20
                assert "devotional_bhavartha" in wbw
                assert len(wbw["devotional_bhavartha"]) > 10


def test_batch4_qa_framework_pass_rate(db_session: Session):
    """Verifies 100% pass rate on 14-rule QA engine across all 18 audits (2 texts * 9 languages)."""
    regional_langs = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]
    total_audits = 0
    passed_audits = 0

    for cid in ["VEDA-TXT-00008", "VEDA-TXT-00013"]:
        text_record = db_session.query(Text).filter_by(content_id=cid).first()
        for lang in regional_langs:
            report = LanguageQualityAssuranceEngine.audit_text_language(text_record, lang)
            total_audits += 1
            if report.passed_all_mandatory:
                passed_audits += 1

    assert total_audits == 18
    assert passed_audits == 18


def test_glossary_expansion_batch4():
    """Verifies SanskritTerminologyGlossary includes Awadhi meters and Sri Vaishnava concepts."""
    all_terms = SanskritTerminologyGlossary.get_all_terms()
    term_ids = {t.term_id for t in all_terms}

    # Batch 4 terms
    assert "TERM-AWD-001" in term_ids  # Chaupai
    assert "TERM-AWD-002" in term_ids  # Doha
    assert "TERM-SV-001" in term_ids   # Prapatti
    assert "TERM-SV-002" in term_ids   # Mangalasasanam
    assert "TERM-SV-003" in term_ids   # Purushakara
    assert "TERM-SV-004" in term_ids   # Vrishachala
    assert "TERM-SV-005" in term_ids   # Sannidhi

    # Check Chaupai details
    chaupai = SanskritTerminologyGlossary.find_term("TERM-AWD-001")
    assert chaupai is not None
    assert chaupai.category == TerminologyCategory.GRAMMATICAL_TERMS
    assert len(chaupai.translations) == 9
    assert chaupai.is_human_reviewed is False


def test_publication_deliverables_and_section_audio_manifests():
    """Verifies Excel, Word, JSON, and discrete Section Audio manifests exist on disk."""
    # Excel files
    assert os.path.exists("exports/multilingual/excel/VEDA-TXT-00008_hanuman_chalisa_multilingual.xlsx")
    assert os.path.exists("exports/multilingual/excel/VEDA-TXT-00013_venkateswara_suprabhatam_multilingual.xlsx")

    # Word files
    assert os.path.exists("exports/multilingual/word/VEDA-TXT-00008_hanuman_chalisa_multilingual.docx")
    assert os.path.exists("exports/multilingual/word/VEDA-TXT-00013_venkateswara_suprabhatam_multilingual.docx")

    # JSON files
    assert os.path.exists("exports/multilingual/json/VEDA-TXT-00008_hanuman_chalisa_multilingual.json")
    assert os.path.exists("exports/multilingual/json/VEDA-TXT-00013_venkateswara_suprabhatam_multilingual.json")

    # Audio manifests
    assert os.path.exists("exports/audio_manifests/VEDA-TXT-00008_hanuman_chalisa_audio_manifest.json")
    assert os.path.exists("exports/audio_manifests/VEDA-TXT-00013_venkateswara_suprabhatam_audio_manifest.json")

    # Discrete 4 section audio manifests for Suprabhatam
    sec1 = "exports/audio_manifests/VEDA-TXT-00013_SEC-SV-01_suprabhatam_audio_manifest.json"
    sec2 = "exports/audio_manifests/VEDA-TXT-00013_SEC-SV-02_stotram_audio_manifest.json"
    sec3 = "exports/audio_manifests/VEDA-TXT-00013_SEC-SV-03_prapatti_audio_manifest.json"
    sec4 = "exports/audio_manifests/VEDA-TXT-00013_SEC-SV-04_mangalasasanam_audio_manifest.json"

    assert os.path.exists(sec1)
    assert os.path.exists(sec2)
    assert os.path.exists(sec3)
    assert os.path.exists(sec4)

    with open(sec1, "r", encoding="utf-8") as f:
        pkg1 = json.load(f)
        assert pkg1["total_verses"] == 29
    with open(sec2, "r", encoding="utf-8") as f:
        pkg2 = json.load(f)
        assert pkg2["total_verses"] == 11
    with open(sec3, "r", encoding="utf-8") as f:
        pkg3 = json.load(f)
        assert pkg3["total_verses"] == 16
    with open(sec4, "r", encoding="utf-8") as f:
        pkg4 = json.load(f)
        assert pkg4["total_verses"] == 14

    # SHA-256 manifest
    sha_manifest = "exports/manifests/phase6c_batch4_sha256_manifest.json"
    assert os.path.exists(sha_manifest)
    with open(sha_manifest, "r", encoding="utf-8") as f:
        manifest_data = json.load(f)
        assert manifest_data["total_artifacts"] == 12


def test_library_wide_completion_milestone(db_session: Session):
    """
    Verifies the ultimate Phase 6C completion milestone:
    100% regional localization across all 18 canonical compositions!
    """
    snapshot = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
    assert snapshot.compositions_with_regional_localization == 18
    assert snapshot.compositions_awaiting_regional_localization == 0
    assert snapshot.regional_translation_completion_pct == 100.0
    assert snapshot.total_verified_verses == 307
    assert snapshot.multilingual_artifacts_excel == 18
    assert snapshot.multilingual_artifacts_word == 18
    assert snapshot.multilingual_artifacts_json == 18

    # Each of the 9 regional languages must have exactly 307 translations
    regional_langs = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]
    for lang in regional_langs:
        cov = snapshot.multilingual_translation_coverage[lang]
        assert cov["total"] == 307
        assert cov["draft"] == 307

    # Total active translations in repository = 3,070
    total_active_trans = db_session.query(Translation).count()
    assert total_active_trans == 3070
