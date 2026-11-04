"""
Tests for Phase 6C Batch 2 Multilingual Localization
Verifies:
1. Source verification of the four Vedic Suktams (Sri, Purusha, Durga, Narayana).
2. Swara preservation in original Sanskrit text.
3. Ingestion of 459 regional-language translations across 9 languages (51 verses * 9).
4. Strictly flags all translations as ReviewStatus.DRAFT.
5. Three distinct translation views: literal, traditional commentary, and devotional Bhavartha.
6. Language QA 14-rule pass rate across all 36 audits (4 texts * 9 languages).
7. Expansion of SanskritTerminologyGlossary to 40 terms covering Vedic concepts.
8. Generation of comparative Excel, Word, JSON bundles, and audio recording manifests.
9. Dashboard analytics metrics: 12 localized compositions (66.67%), 105 verses per regional language.
"""

import json
import os
from pathlib import Path
import pytest
from sqlalchemy.orm import Session

from automation.localization.audio_preparation import AudioPreparationEngine
from automation.localization.exporters import MultilingualPublicationExporter
from automation.localization.glossary import SanskritTerminologyGlossary, TerminologyCategory
from automation.localization.phase6c_batch2_localizer import (
    ALL_NINE_REGIONAL_LANGS,
    BATCH2_TEXT_MAP,
    export_batch2_deliverables,
    localize_batch2_compositions,
    run_batch2_qa_audits,
)
from automation.localization.qa_framework import LanguageQualityAssuranceEngine, QACheckStatus
from automation.reporting.library_analytics import LibraryAnalyticsEngine
from database.connection import get_db_session
from database.models import ReviewStatus, Text, Translation, TranslationType, Verse


class TestPhase6CBatch2Localization:
    """Comprehensive test suite for Phase 6C Batch 2 Vedic Suktams."""

    BATCH2_IDS = ["VEDA-TXT-00007", "VEDA-TXT-00014", "VEDA-TXT-00015", "VEDA-TXT-00016"]

    @classmethod
    @pytest.fixture(scope="class")
    def db_session(cls):
        with get_db_session() as session:
            yield session

    def test_source_verification_and_swara_presence_all_four_suktams(self, db_session: Session):
        """Verifies that all four Vedic Suktams are verified with authentic swara markers."""
        for cid in self.BATCH2_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            assert text is not None, f"Text {cid} not found"
            assert text.textual_verification_status.value == "SCHOLAR_VERIFIED"
            assert len(text.verses) > 0

            # Verify swara marks exist on every verse
            for v in text.verses:
                swara_count = v.devanagari_text.count("\u0951") + v.devanagari_text.count("\u0952")
                assert swara_count > 0, f"Verse {v.verse_id} missing Vedic swara marks"
                assert v.vedic_accents_present is True

    def test_batch2_verse_counts_sum_to_fifty_one(self, db_session: Session):
        """Verifies individual and total verse counts: 16 + 16 + 7 + 12 = 51."""
        expected_counts = {
            "VEDA-TXT-00007": 16,  # Sri Suktam
            "VEDA-TXT-00014": 16,  # Purusha Suktam
            "VEDA-TXT-00015": 7,   # Durga Suktam
            "VEDA-TXT-00016": 12,  # Narayana Suktam
        }
        total_verses = 0
        for cid, exp_cnt in expected_counts.items():
            text = db_session.query(Text).filter_by(content_id=cid).first()
            assert len(text.verses) == exp_cnt
            total_verses += len(text.verses)
        assert total_verses == 51

    def test_ingestion_produces_four_hundred_fifty_nine_records(self, db_session: Session):
        """Verifies that all 51 verses have Bhavartha translations across all 9 regional languages."""
        total_regional = 0
        for cid in self.BATCH2_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            for v in text.verses:
                reg_trs = [t for t in v.translations if t.target_language in ALL_NINE_REGIONAL_LANGS]
                assert len(reg_trs) == 9, f"Verse {v.verse_id} has {len(reg_trs)} regional translations, expected 9"
                total_regional += len(reg_trs)
        assert total_regional == 459

    def test_all_translations_strictly_flagged_as_draft(self, db_session: Session):
        """Governance check: all 459 regional translations must remain ReviewStatus.DRAFT."""
        for cid in self.BATCH2_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            for v in text.verses:
                for tr in v.translations:
                    if tr.target_language in ALL_NINE_REGIONAL_LANGS:
                        assert tr.review_status == ReviewStatus.DRAFT
                        assert "Editorial Vedic Synthesis" in (tr.translator or "")
                        assert tr.reviewer is None or tr.reviewer == ""

    def test_three_distinct_translation_views_in_word_by_word_json(self, db_session: Session):
        """Verifies that each translation record contains separate literal, traditional, and devotional views."""
        for cid in self.BATCH2_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            for v in text.verses:
                for tr in v.translations:
                    if tr.target_language in ALL_NINE_REGIONAL_LANGS:
                        wbw = tr.word_by_word_json
                        assert isinstance(wbw, dict), f"Verse {v.verse_id} missing word_by_word_json dict"
                        assert "literal_translation" in wbw and len(wbw["literal_translation"]) > 0
                        assert "traditional_meaning" in wbw and len(wbw["traditional_meaning"]) > 0
                        assert "commentator" in wbw and len(wbw["commentator"]) > 0
                        assert "padachheda" in wbw and len(wbw["padachheda"]) > 0
                        assert "devotional_bhavartha" in wbw and len(wbw["devotional_bhavartha"]) > 0
                        # Ensure literal is not identical to bhavartha (strictly separated)
                        assert wbw["literal_translation"] != tr.translated_text

    def test_language_qa_fourteen_rules_pass_all_thirty_six_audits(self, db_session: Session):
        """Verifies that all 36 text/language combinations pass all 14 QA checks."""
        qa_results = run_batch2_qa_audits(db_session)
        assert qa_results["total_audits"] == 36
        assert qa_results["passed_audits"] == 36
        assert qa_results["failed_audits"] == 0

    def test_vedic_accent_isolation_rule_thirteen_passes(self, db_session: Session):
        """Verifies Rule 13: translations must never contain combining Vedic swaras (\u0951, \u0952)."""
        for cid in self.BATCH2_IDS:
            text = db_session.query(Text).filter_by(content_id=cid).first()
            for lang in ALL_NINE_REGIONAL_LANGS:
                report = LanguageQualityAssuranceEngine.audit_text_language(text, lang)
                rule13 = next((c for c in report.checks if c.rule_id == "LANG-QA-013"), None)
                assert rule13 is not None
                assert rule13.status == QACheckStatus.PASSED

    def test_glossary_expanded_to_forty_canonical_terms(self):
        """Verifies the Sanskrit terminology glossary contains at least 40 terms including the 12 Vedic terms."""
        terms = SanskritTerminologyGlossary.get_all_terms()
        assert len(terms) >= 40

        required_vedic_terms = ["पुरुषः", "नारायणः", "श्रीः", "अग्निः", "जातवेदाः", "हिरण्यवर्णा", "भूमिः", "यज्ञः", "ऋषिः", "छन्दः", "देवता"]
        for s_term in required_vedic_terms:
            found = any(t.sanskrit_term == s_term or s_term in t.sanskrit_term for t in terms)
            assert found is True, f"Term {s_term} not found in glossary"

    def test_publication_exports_generated_for_all_four_texts(self):
        """Verifies that Excel (13-col), Word (12-row), JSON, and Audio manifests exist on disk."""
        for cid in self.BATCH2_IDS:
            excel_files = list(Path("exports/multilingual/excel").glob(f"{cid}_*.xlsx"))
            word_files = list(Path("exports/multilingual/word").glob(f"{cid}_*.docx"))
            json_files = list(Path("exports/multilingual/json").glob(f"{cid}_*.json"))
            audio_files = list(Path("exports/audio_manifests").glob(f"{cid}_*.json"))

            assert len(excel_files) >= 1, f"Missing Excel for {cid}"
            assert len(word_files) >= 1, f"Missing Word for {cid}"
            assert len(json_files) >= 1, f"Missing JSON for {cid}"
            assert len(audio_files) >= 1, f"Missing Audio Manifest for {cid}"

            # Verify JSON payload has 10+ languages
            with open(json_files[0], "r", encoding="utf-8") as f:
                data = json.load(f)
                assert "verses" in data
                assert len(data["verses"]) > 0
                first_v = data["verses"][0]
                assert "translations" in first_v
                assert len(first_v["translations"]) >= 10

    def test_library_dashboard_reflects_twelve_localized_compositions(self, db_session: Session):
        """Verifies dashboard metrics: 12 localized compositions (66.67%), 105 verses per language."""
        metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
        assert metrics.compositions_with_regional_localization == 12
        assert metrics.compositions_awaiting_regional_localization == 6
        assert metrics.regional_translation_completion_pct == 66.67
        assert metrics.number_of_devotional_bhavarthas == 1211
        assert metrics.number_of_literal_translations == 459
        assert metrics.number_of_traditional_meanings == 459

        for lang in ALL_NINE_REGIONAL_LANGS:
            assert metrics.multilingual_translation_coverage[lang]["total"] == 105
