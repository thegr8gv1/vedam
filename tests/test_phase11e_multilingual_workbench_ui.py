"""
Phase 11E: Multilingual Workbench UI, Script-Aware Typography & Reviewer Experience Tests
Validates the language/script selector, scholarly text workspace, transliteration previews,
Unicode diagnostics, typography/directionality (<bdi>), reviewer RBAC governance,
publication preflight gating, and accessibility standards under strict test database isolation.
"""

from datetime import datetime, timezone
import html
import os
from pathlib import Path
import pytest
from sqlalchemy.orm import Session

from automation.cleaners.unicode_preserver import VedicSwara
from automation.exporters.publication_gatekeeper import ReleaseGateVerdict
from automation.localization.registry import MultilingualRegistry
from automation.localization.script_registry import MultilingualScriptRegistry, ScriptDirection
from automation.localization.transliteration_engine import (
    MultilingualTransliterationEngine,
    TransliterationReversibility,
)
from automation.localization.unicode_inspector import UnicodeFidelityInspector
from automation.workbench.multilingual_dashboard import MultilingualWorkbenchViewGenerator
from automation.workbench.multilingual_rbac import (
    MultilingualRBACEngine,
    SelfApprovalViolationError,
    UnauthorizedLanguageReviewError,
)
from automation.workbench.multilingual_workbench_service import MultilingualWorkbenchService
from database.models import (
    ReviewActionType,
    ReviewerProfile,
    ReviewerRole,
    ReviewerVerificationStatus,
    Text,
    Translation,
    Verse,
)


# ===========================================================================
# 1. LANGUAGE & SCRIPT REGISTRY TESTS
# ===========================================================================

def test_language_script_registry_coverage():
    """Verify registry covers 22 Eighth Schedule languages + English and 14 scripts."""
    catalog = MultilingualWorkbenchService.get_supported_languages_and_scripts()
    assert catalog["total_languages"] == 23
    assert catalog["total_scripts"] == 14

    lang_codes = {l["iso_639_1"] for l in catalog["languages"]}
    # Check 22 scheduled languages + English
    expected_langs = {
        "sa", "hi", "te", "ta", "kn", "ml", "bn", "gu", "mr", "or", "pa", "as",
        "mai", "ne", "kok", "doi", "brx", "sat", "ks", "sd", "mni", "ur", "en"
    }
    assert expected_langs.issubset(lang_codes)

    script_codes = {s["iso_15924"] for s in catalog["scripts"]}
    expected_scripts = {
        "Deva", "Telu", "Taml", "Gran", "Knda", "Mlym", "Beng", "Gujr",
        "Guru", "Orya", "Olck", "Mtei", "Arab", "Latn"
    }
    assert expected_scripts == script_codes


def test_unsupported_language_script_combinations():
    """Verify unsupported language-script pairs are recognized as invalid."""
    is_valid_1, msg_1 = MultilingualScriptRegistry.validate_script_for_language("ur", "Orya")
    assert not is_valid_1
    assert "not registered" in msg_1

    is_valid_2, _ = MultilingualScriptRegistry.validate_script_for_language("hi", "Arab")
    assert not is_valid_2

    is_valid_3, _ = MultilingualScriptRegistry.validate_script_for_language("te", "Mtei")
    assert not is_valid_3


def test_sanskrit_multiple_scripts_support():
    """Verify Sanskrit supports all major liturgical Indic scripts and Latin IAST."""
    sa_def = MultilingualRegistry.get_language("sa")
    assert sa_def is not None
    # Sanskrit supports multi-script projections
    assert "Deva" in sa_def.supported_scripts
    assert "Telu" in sa_def.supported_scripts
    assert "Gran" in sa_def.supported_scripts
    assert "Taml" in sa_def.supported_scripts
    assert "Mlym" in sa_def.supported_scripts
    assert "Latn" in sa_def.supported_scripts


def test_tamil_orthographic_modes():
    """Verify Tamil modern vs Sangam traditional modes are exposed without duplicating language."""
    catalog = MultilingualWorkbenchService.get_supported_languages_and_scripts()
    ta_info = next(l for l in catalog["languages"] if l["iso_639_1"] == "ta")
    assert ta_info["special_modes"]
    mode_ids = {m["id"] for m in ta_info["special_modes"]}
    assert "ta-Taml" in mode_ids
    assert "ta-Taml-traditional" in mode_ids


def test_assamese_vs_bengali_distinction():
    """Verify Assamese and Bengali share Eastern Nagari script but are distinct languages."""
    as_def = MultilingualRegistry.get_language("as")
    bn_def = MultilingualRegistry.get_language("bn")
    assert as_def.primary_script == "Beng"
    assert bn_def.primary_script == "Beng"
    assert as_def.iso_639_1 != bn_def.iso_639_1
    assert as_def.name == "Assamese"
    assert bn_def.name == "Bengali"


def test_manipuri_script_selection():
    """Verify Manipuri exposes both Bengali-Assamese and Meitei Mayek scripts."""
    mni_def = MultilingualRegistry.get_language("mni")
    assert "Beng" in mni_def.supported_scripts
    assert "Mtei" in mni_def.supported_scripts


def test_rtl_language_handling():
    """Verify Urdu, Kashmiri, and Sindhi Arabic scripts are recognized as RTL."""
    assert MultilingualScriptRegistry.is_rtl("Arab")
    assert not MultilingualScriptRegistry.is_rtl("Deva")
    assert not MultilingualScriptRegistry.is_rtl("Telu")

    catalog = MultilingualWorkbenchService.get_supported_languages_and_scripts()
    ur_info = next(l for l in catalog["languages"] if l["iso_639_1"] == "ur")
    assert ur_info["is_rtl"] is True
    assert ur_info["primary_direction"] == "rtl"


# ===========================================================================
# 2. TEXT, UNICODE & TYPOGRAPHY TESTS
# ===========================================================================

def test_sanskrit_vedic_swara_detection(db_session: Session):
    """Verify Vedic tones (Svarita, Anudatta) are identified non-destructively."""
    # VEDA-TXT-00006 is Gayatri Vedic Mantra with preserved accents
    payload = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session, content_id="VEDA-TXT-00006", verse_number=1, target_language="sa", target_script="Deva"
    )
    col1 = payload["column_1_original"]
    assert col1["vedic_accents_present"] is True

    diag = payload["unicode_diagnostics"]
    assert diag["vedic_accent_count"] > 0
    # Vedic accents U+0951 and U+0952 present
    accents_hex = set(diag["vedic_accents"])
    assert "U+0951" in accents_hex or "U+0952" in accents_hex


def test_pre_base_vowel_sign_representation():
    """Verify short-i matra is recognized as a combining mark."""
    test_str = "विनायकम्"
    rep = UnicodeFidelityInspector.inspect(test_str)
    assert rep.combining_mark_count >= 2  # Short-i matra + Anusvara


def test_zwj_zwnj_detection():
    """Verify Unicode inspector detects zero-width joiners and non-joiners."""
    zwj_str = "क्\u200Dष"
    zwnj_str = "क्\u200Cष"
    normal_str = "क्ष"

    rep_zwj = UnicodeFidelityInspector.inspect(zwj_str)
    rep_zwnj = UnicodeFidelityInspector.inspect(zwnj_str)
    rep_norm = UnicodeFidelityInspector.inspect(normal_str)

    assert rep_zwj.has_zwj is True
    assert rep_zwj.has_zwnj is False

    assert rep_zwnj.has_zwj is False
    assert rep_zwnj.has_zwnj is True

    assert rep_norm.has_zwj is False
    assert rep_norm.has_zwnj is False


def test_transliteration_lossy_and_reversible_classifications():
    """Verify transliteration reversibility tags: Deva->Telu is REVERSIBLE, Deva->Taml is LOSSY."""
    res_telu = MultilingualTransliterationEngine.transliterate("मुदाकरात्तमोदकम्", "Deva", "Telu")
    assert res_telu.reversibility == TransliterationReversibility.REVERSIBLE
    assert res_telu.is_lossless is True

    res_taml = MultilingualTransliterationEngine.transliterate("खग", "Deva", "Taml")
    assert res_taml.reversibility == TransliterationReversibility.LOSSY
    assert res_taml.is_lossless is False
    assert len(res_taml.warnings) > 0


def test_unicode_inspector_read_only_immutability(db_session: Session):
    """Verify Unicode inspection leaves database record bit-for-bit unchanged."""
    verse = db_session.query(Verse).filter_by(verse_id="VEDA-TXT-00001-V001").first()
    original_text = verse.devanagari_text

    rep = UnicodeFidelityInspector.inspect(original_text)
    assert rep.original_text == original_text
    assert verse.devanagari_text == original_text


# ===========================================================================
# 3. REVIEWER RBAC & GOVERNANCE TESTS
# ===========================================================================

def test_authorized_reviewer_access(db_session: Session):
    """Verify accredited reviewer is authorized for their language."""
    # REV-ADMIN-001 has universal oversight (EDITORIAL_BOARD)
    payload_admin = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session, content_id="VEDA-TXT-00001", verse_number=1, target_language="te", reviewer_id="REV-ADMIN-001"
    )
    col6 = payload_admin["column_6_governance"]
    assert col6["is_authorized_for_language"] is True
    assert col6["can_approve_views"] is True


def test_unauthorized_reviewer_access(db_session: Session):
    """Verify Vedic recension reviewer is not authorized to approve Urdu."""
    payload_vedic = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session, content_id="VEDA-TXT-00006", verse_number=1, target_language="ur", reviewer_id="REV-PROD-VEDIC"
    )
    col6 = payload_vedic["column_6_governance"]
    assert col6["is_authorized_for_language"] is False
    assert col6["can_approve_views"] is False
    assert "Unauthorized" in col6["authorization_message"]


def test_quarantined_and_demo_restrictions(db_session: Session):
    """Verify simulated demo reviewer is flagged with sandbox mode under Rule REV-005."""
    payload_demo = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session, content_id="VEDA-TXT-00001", verse_number=1, target_language="sa", reviewer_id="REV-DEMO-SIM"
    )
    col6 = payload_demo["column_6_governance"]
    assert col6["is_quarantined"] is True
    assert col6["can_approve_views"] is False
    assert "Sandbox Account Mode" in col6["authorization_message"]


def test_self_approval_prevention_server_side(db_session: Session):
    """Verify translator cannot approve their own translation work under Rule REV-002."""
    translation = db_session.query(Translation).first()
    reviewer = db_session.query(ReviewerProfile).first()

    # Artificially set translator matching reviewer in test session
    translation.translator = reviewer.full_name

    with pytest.raises(SelfApprovalViolationError):
        MultilingualRBACEngine.check_self_approval_restriction(
            reviewer=reviewer,
            translation=translation,
        )


def test_server_side_rbac_validation_blocks_unauthorized_submission(db_session: Session):
    """Verify backend enforces language authorization independently of frontend controls."""
    # Find Hindi translation
    hi_trans = db_session.query(Translation).filter_by(target_language="hi").first()
    # Vedic recension reviewer only reviews Sanskrit
    vedic_reviewer = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-PROD-VEDIC").first()

    with pytest.raises(UnauthorizedLanguageReviewError):
        MultilingualWorkbenchService.validate_review_submission(
            session=db_session,
            reviewer_id=vedic_reviewer.reviewer_id,
            translation_id=hi_trans.id,
            action_type=ReviewActionType.APPROVE,
            scholarly_commentary="Unauthorized approval attempt",
        )


# ===========================================================================
# 4. PUBLICATION PREVIEW & GATING TESTS
# ===========================================================================

def test_draft_warning_and_watermark_in_payload(db_session: Session):
    """Verify DRAFT warning banner and watermark are present in publication preview."""
    payload = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session, content_id="VEDA-TXT-00001", verse_number=1, target_language="hi"
    )
    pub = payload["publication_preview"]
    assert pub["overall_review_status"] == "DRAFT"
    assert pub["watermark_text"] == "UNREVIEWED DRAFT — NOT FOR PUBLIC DEVOTIONAL USE"
    assert pub["gatekeeper_verdict"] == ReleaseGateVerdict.CONDITIONAL_DRAFT_ONLY.value


def test_pdf_explicitly_labeled_limited_preview(db_session: Session):
    """Verify PDF export is explicitly labeled LIMITED PREVIEW ONLY due to ReportLab shaping defects."""
    payload = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session, content_id="VEDA-TXT-00001", verse_number=1, target_language="hi"
    )
    pdf_info = payload["publication_preview"]["formats"]["pdf"]
    assert pdf_info["status"] == "LIMITED_PREVIEW_ONLY"
    assert "LIMITED PREVIEW ONLY" in pdf_info["badge"]
    assert "ReportLab" in pdf_info["warning"]
    assert "GSUB/GPOS" in pdf_info["warning"]


def test_legacy_gap_queue_visibility(db_session: Session):
    """Verify 747 legacy gap queue missing literal/tatparya views are flagged with notices."""
    # VEDA-TXT-00001 has no literal view in the legacy DB
    payload = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session, content_id="VEDA-TXT-00001", verse_number=1, target_language="hi"
    )
    col3 = payload["column_3_literal"]
    assert col3["is_legacy_gap"] is True
    assert "Legacy 747 Gap Queue" in col3["display_notice"]


# ===========================================================================
# 5. UI HTML GENERATION & ACCESSIBILITY TESTS
# ===========================================================================

def test_multilingual_workbench_html_generation_and_accessibility(db_session: Session, tmp_path):
    """Verify generated HTML workbench is well-formed, accessible, and contains required elements."""
    out_file = str(tmp_path / "test_workbench_ui.html")
    generated_path = MultilingualWorkbenchViewGenerator.generate_html_workbench(
        session=db_session,
        content_id="VEDA-TXT-00001",
        verse_number=1,
        target_language="hi",
        target_script="Deva",
        reviewer_id="REV-ADMIN-001",
        output_file=out_file,
    )
    assert os.path.exists(generated_path)
    assert os.path.getsize(generated_path) > 30000

    html_content = open(generated_path, "r", encoding="utf-8").read()

    # Accessibility attributes
    assert 'role="banner"' in html_content
    assert 'role="region"' in html_content
    assert 'aria-label=' in html_content
    assert ':focus-visible' in html_content

    # Directionality & Language
    assert 'lang="hi"' in html_content
    assert 'dir="ltr"' in html_content

    # Governance & Rule banners
    assert "UNREVIEWED DRAFT — NOT FOR PUBLIC DEVOTIONAL USE" in html_content
    assert "Rule PUB-010 / PUB-011 Active" in html_content
    assert "LIMITED PREVIEW ONLY" in html_content

    # Bidirectional isolation
    assert "<bdi>" in html_content


def test_urdu_rtl_html_generation(db_session: Session, tmp_path):
    """Verify Urdu workbench HTML generates with dir='rtl' and proper <bdi> isolation."""
    out_file = str(tmp_path / "test_urdu_ui.html")
    generated_path = MultilingualWorkbenchViewGenerator.generate_html_workbench(
        session=db_session,
        content_id="VEDA-TXT-00006",
        verse_number=1,
        target_language="ur",
        target_script="Arab",
        reviewer_id="REV-ADMIN-001",
        output_file=out_file,
    )
    assert os.path.exists(generated_path)

    html_content = open(generated_path, "r", encoding="utf-8").read()
    assert 'lang="ur"' in html_content
    assert 'dir="rtl"' in html_content
    assert "<bdi>" in html_content
