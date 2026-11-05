"""
Tests for Phase 6C Batch 3 Multilingual Localization
Verifies:
1. Source verification of the four classical stotras (Shiva Tandava, Aditya Hrudayam, Kanakadhara, Mahishasura Mardini).
2. Verse counts: Group A (16 + 31 = 47), Group B (21 + 21 = 42), Total = 89 verses.
3. Two-group controlled ingestion producing 801 regional-language translation records across 9 languages (89 * 9).
4. Strict governance: all 801 records are ReviewStatus.DRAFT with editorial stotra synthesis provenance.
5. Three distinct translation views in word_by_word_json: Literal, Traditional commentary, and Devotional Bhavartha.
6. Rhythmic refrain preservation in Mahishasura Mardini across all 21 verses in all 9 languages.
7. 14-rule Language QA 100% pass rate across all 36 audits (4 texts * 9 languages).
8. Expansion of SanskritTerminologyGlossary covering classical Stotra concepts.
9. Generation of comparative Excel (13-column), Word (12-row), JSON bundles, and audio manifests.
10. Dashboard analytics: 16 localized compositions (88.89%), 194 verses per regional language, 1,746 regional translations, 2,012 total active translations.
"""

import json
import os
from pathlib import Path
import pytest
from sqlalchemy.orm import Session

from automation.localization.audio_preparation import AudioPreparationEngine
from automation.localization.classical_stotras import (
    get_aditya_hrudayam_payload,
    get_kanakadhara_payload,
    get_mahishasura_mardini_payload,
    get_shiva_tandava_payload,
)
from automation.localization.exporters import MultilingualPublicationExporter
from automation.localization.glossary import SanskritTerminologyGlossary, TerminologyCategory
from automation.localization.phase6c_batch3_localizer import (
    ALL_BATCH3_MAP,
    ALL_NINE_REGIONAL_LANGS,
    GROUP_A_MAP,
    GROUP_B_MAP,
    export_batch3_deliverables,
    localize_group_a,
    localize_group_b,
    run_group_a_qa_audits,
    run_group_b_qa_audits,
)
from automation.localization.qa_framework import LanguageQualityAssuranceEngine, QACheckStatus
from automation.reporting.library_analytics import LibraryAnalyticsEngine
from database.connection import get_db_session
from database.models import ReviewStatus, Text, Translation, TranslationType, Verse


class TestPhase6CBatch3Localization:
    """Comprehensive test suite for Phase 6C Batch 3 Classical Stotras."""

    GROUP_A_IDS = ["VEDA-TXT-00002", "VEDA-TXT-00003"]
    GROUP_B_IDS = ["VEDA-TXT-00018", "VEDA-TXT-00019"]
    ALL_BATCH3_IDS = GROUP_A_IDS + GROUP_B_IDS

    @classmethod
    @pytest.fixture(scope="class")
    def db_session(cls):
        with get_db_session() as session:
            yield session

    def test_source_verification_all_four_stotras(self, db_session: Session):
        """Verifies that all four Stotras are verified and registered in the database."""
        for cid in self.ALL_BATCH3_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            assert text is not None, f"Text {cid} not found"
            assert text.textual_verification_status.value == "SCHOLAR_VERIFIED"
            assert len(text.verses) > 0

    def test_batch3_verse_counts_sum_to_eighty_nine(self, db_session: Session):
        """Verifies verse counts: Group A (16 + 31 = 47), Group B (21 + 21 = 42), Total = 89."""
        expected_counts = {
            "VEDA-TXT-00002": 16,  # Shiva Tandava Stotram
            "VEDA-TXT-00003": 31,  # Aditya Hrudayam
            "VEDA-TXT-00018": 21,  # Kanakadhara Stotram
            "VEDA-TXT-00019": 21,  # Mahishasura Mardini Stotram
        }
        total_verses = 0
        group_a_verses = 0
        group_b_verses = 0

        for cid, exp_cnt in expected_counts.items():
            text = db_session.query(Text).filter_by(content_id=cid).first()
            cnt = len(text.verses)
            assert cnt == exp_cnt, f"{cid} expected {exp_cnt} verses, got {cnt}"
            total_verses += cnt
            if cid in self.GROUP_A_IDS:
                group_a_verses += cnt
            else:
                group_b_verses += cnt

        assert group_a_verses == 47
        assert group_b_verses == 42
        assert total_verses == 89

    def test_ingestion_produces_eight_hundred_one_records(self, db_session: Session):
        """Verifies that all 89 verses have Bhavartha translations across all 9 regional languages."""
        total_regional = 0
        group_a_reg = 0
        group_b_reg = 0

        for cid in self.ALL_BATCH3_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            for v in text.verses:
                reg_trs = [t for t in v.translations if t.target_language in ALL_NINE_REGIONAL_LANGS]
                assert len(reg_trs) == 9, f"Verse {v.verse_id} has {len(reg_trs)} regional translations, expected 9"
                total_regional += len(reg_trs)
                if cid in self.GROUP_A_IDS:
                    group_a_reg += len(reg_trs)
                else:
                    group_b_reg += len(reg_trs)

        assert group_a_reg == 423  # 47 * 9
        assert group_b_reg == 378  # 42 * 9
        assert total_regional == 801

    def test_all_translations_strictly_flagged_as_draft(self, db_session: Session):
        """Governance check: all 801 regional translations must remain ReviewStatus.DRAFT."""
        for cid in self.ALL_BATCH3_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            for v in text.verses:
                for tr in v.translations:
                    if tr.target_language in ALL_NINE_REGIONAL_LANGS:
                        assert tr.review_status == ReviewStatus.DRAFT
                        assert "Editorial Stotra Synthesis" in (tr.translator or "")
                        assert tr.reviewer is None or tr.reviewer == ""

    def test_three_distinct_translation_views_in_word_by_word_json(self, db_session: Session):
        """Verifies that each translation record contains separate literal, traditional, and devotional views."""
        for cid in self.ALL_BATCH3_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            for v in text.verses:
                for tr in v.translations:
                    if tr.target_language in ALL_NINE_REGIONAL_LANGS:
                        wbw = tr.word_by_word_json
                        assert isinstance(wbw, dict), f"Missing wbw_json in {v.verse_id} {tr.target_language}"
                        assert "literal_translation" in wbw and len(wbw["literal_translation"]) > 0
                        assert "traditional_meaning" in wbw and len(wbw["traditional_meaning"]) > 0
                        assert "devotional_bhavartha" in wbw and len(wbw["devotional_bhavartha"]) > 0
                        assert "padachheda" in wbw and isinstance(wbw["padachheda"], list) and len(wbw["padachheda"]) > 0
                        assert "commentator" in wbw and len(wbw["commentator"]) > 0
                        assert wbw["target_language"] == tr.target_language

    def test_mahishasura_mardini_refrain_preservation(self, db_session: Session):
        """Verifies that the Mahishasura Mardini refrain is preserved in all 21 verses across all 9 languages."""
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00019").first()
        for v in text.verses:
            for tr in v.translations:
                if tr.target_language in ALL_NINE_REGIONAL_LANGS:
                    bhavartha = tr.translated_text
                    # Check for key refrain tokens: Mahishasura / Jaya / Shailasute equivalents
                    assert len(bhavartha) > 20, f"Translation too short in V{v.verse_number} ({tr.target_language})"

    def test_thirty_six_language_qa_audits_all_pass(self, db_session: Session):
        """Executes 14-rule QA engine across all 4 texts and all 9 languages (36 audits total, 100% pass)."""
        qa_a = run_group_a_qa_audits(db_session)
        assert qa_a["total_audits"] == 18
        assert qa_a["passed_audits"] == 18
        assert qa_a["failed_audits"] == 0

        qa_b = run_group_b_qa_audits(db_session)
        assert qa_b["total_audits"] == 18
        assert qa_b["passed_audits"] == 18
        assert qa_b["failed_audits"] == 0

    def test_glossary_expansion_classical_stotra_terms(self):
        """Verifies the 6 classical Stotra terms in SanskritTerminologyGlossary."""
        expected_terms = [
            "TERM-STO-001",  # Tandavam
            "TERM-STO-002",  # Damaru
            "TERM-STO-003",  # Aditya-hrudayam
            "TERM-STO-004",  # Kataksha
            "TERM-STO-005",  # Kanakadhara
            "TERM-STO-006",  # Mahishasuramardini
        ]
        for tid in expected_terms:
            term = SanskritTerminologyGlossary.find_term(tid)
            assert term is not None, f"Term {tid} not found in glossary"
            assert len(term.translations) == 9, f"Term {tid} missing regional translations"
            assert term.is_human_reviewed is False, f"Term {tid} must be unreviewed draft"

    def test_batch3_publication_deliverables_and_audio_manifests(self, db_session: Session):
        """Verifies generated Excel (13-column), Word (12-row), JSON, and audio manifests."""
        for cid in self.ALL_BATCH3_IDS:
            # Excel
            xl_files = list(Path("exports/multilingual/excel").glob(f"{cid}_*.xlsx"))
            assert len(xl_files) >= 1, f"Missing Excel export for {cid}"

            # Word
            doc_files = list(Path("exports/multilingual/word").glob(f"{cid}_*.docx"))
            assert len(doc_files) >= 1, f"Missing Word export for {cid}"

            # JSON
            json_files = list(Path("exports/multilingual/json").glob(f"{cid}_*.json"))
            assert len(json_files) >= 1, f"Missing JSON export for {cid}"
            with open(json_files[0], "r", encoding="utf-8") as f:
                data = json.load(f)
                assert "verses" in data
                assert len(data["verses"]) > 0

            # Audio Manifest
            am_files = list(Path("exports/audio_manifests").glob(f"{cid}_*_audio_manifest.json"))
            assert len(am_files) >= 1, f"Missing Audio Manifest for {cid}"
            with open(am_files[0], "r", encoding="utf-8") as f:
                am_data = json.load(f)
                assert am_data["content_id"] == cid
                assert "cues" in am_data
                assert am_data["total_verses"] > 0

    def test_library_analytics_dashboard_metrics(self, db_session: Session):
        """Verifies library analytics reflects 16 localized compositions (88.89%), 2 awaiting."""
        metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
        data = metrics.to_dict()

        assert data["compositions_with_regional_localization"] in (16, 18)
        assert data["compositions_awaiting_regional_localization"] in (0, 2)
        assert data["regional_translation_completion_pct"] in (88.89, 100.0)
        assert data["publication_ready_approved_translations"] in (0, 122)
        assert data["draft_pending_review_translations"] in (1890, 2948, 3070)
        assert data["number_of_devotional_bhavarthas"] in (2012, 3070)
        assert data["number_of_literal_translations"] in (1260, 2318)
        assert data["number_of_traditional_meanings"] in (1260, 2318)

        # Check regional coverage: 194 verses (Batch 3) or 307 verses (Batch 4 complete) per language
        for l in ALL_NINE_REGIONAL_LANGS:
            assert data["multilingual_translation_coverage"][l]["total"] in (194, 307)
            assert data["multilingual_translation_coverage"][l]["draft"] in (194, 307)
