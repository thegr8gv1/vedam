"""
Vedic Heritage Platform — Phase 6C Batch 3 Localization Engine
Multilingual Localization of Major Shiva, Aditya, Lakshmi, and Devi Classical Stotras:

Group A (47 source verse units -> 423 regional translation records):
1. Shiva Tandava Stotram (VEDA-TXT-00002) — 16 verses
2. Aditya Hrudayam (VEDA-TXT-00003) — 31 verses

Group B (42 source verse units -> 378 regional translation records):
3. Kanakadhara Stotram (VEDA-TXT-00018) — 21 verses
4. Mahishasura Mardini Stotram (VEDA-TXT-00019) — 21 verses

Total source verse units: 89
Total target translations: 89 * 9 regional languages = 801 new translation records.

Target Languages:
1. Hindi (hi)
2. Telugu (te)
3. Tamil (ta)
4. Kannada (kn)
5. Marathi (mr)
6. Bengali (bn)
7. Gujarati (gu)
8. Malayalam (ml)
9. Odia (or)

Three Distinct Translation Views provided for each verse:
A. Literal translation: close translation of original Sanskrit wording.
B. Traditional meaning: informed by established classical commentaries (Shaiva Sampradaya, Valmiki Ramayana Govindaraja/Tilaka, Sankarite Kanakadhara tradition, Shakta Devi Mahatmya tradition).
C. Devotional Bhavartha: readable, culturally attuned translation across all 9 regional languages.
Separate Padachheda stored in word_by_word_json.

Strict Governance:
- All translations strictly flagged as ReviewStatus.DRAFT.
- Attributed to 'Platform Multilingual Localization Engine (Editorial Stotra Synthesis; Awaiting Accredited Scholar Panel)'.
- Never automatically promote AI or editorial translations to approved status.
- Zero final publication PDFs containing unapproved draft translations.
"""

from datetime import datetime, timezone
import json
import logging
from typing import Any, Callable, Dict, List, Optional
from sqlalchemy.orm import Session

from automation.localization.audio_preparation import AudioPreparationEngine
from automation.localization.classical_stotras import (
    get_aditya_hrudayam_payload,
    get_kanakadhara_payload,
    get_mahishasura_mardini_payload,
    get_shiva_tandava_payload,
)
from automation.localization.exporters import MultilingualPublicationExporter
from automation.localization.qa_framework import LanguageQualityAssuranceEngine, QACheckStatus
from database.connection import get_db_session
from database.models import ReviewStatus, Text, Translation, TranslationType, Verse

logger = logging.getLogger("vedam.automation.localization.phase6c_batch3")

GROUP_A_MAP: Dict[str, Callable[[], Dict[int, Dict[str, Any]]]] = {
    "VEDA-TXT-00002": get_shiva_tandava_payload,
    "VEDA-TXT-00003": get_aditya_hrudayam_payload,
}

GROUP_B_MAP: Dict[str, Callable[[], Dict[int, Dict[str, Any]]]] = {
    "VEDA-TXT-00018": get_kanakadhara_payload,
    "VEDA-TXT-00019": get_mahishasura_mardini_payload,
}

ALL_BATCH3_MAP: Dict[str, Callable[[], Dict[int, Dict[str, Any]]]] = {
    **GROUP_A_MAP,
    **GROUP_B_MAP,
}

ALL_NINE_REGIONAL_LANGS = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]
TRANSLATOR_PROVENANCE = (
    "Platform Multilingual Localization Engine (Editorial Stotra Synthesis; Awaiting Accredited Scholar Panel)"
)


def _localize_group(
    session: Session, group_name: str, target_map: Dict[str, Callable[[], Dict[int, Dict[str, Any]]]]
) -> Dict[str, Any]:
    """
    Generic localization worker for a controlled group.
    Maintains exact verse counts, populates word_by_word_json with 3 distinct views,
    and flags all records as ReviewStatus.DRAFT.
    """
    results: Dict[str, Any] = {}
    total_added = 0
    total_updated = 0
    total_verses_processed = 0

    for cid, payload_func in target_map.items():
        text_record = session.query(Text).filter_by(content_id=cid).first()
        if not text_record:
            logger.warning(f"Text {cid} not found in database. Skipping.")
            continue

        verses_data = payload_func()
        verse_records = {v.verse_number: v for v in text_record.verses}
        added_count = 0
        updated_count = 0

        for v_num, v_info in verses_data.items():
            if v_num not in verse_records:
                logger.warning(f"Verse {v_num} not found in text {cid}")
                continue
            v_obj = verse_records[v_num]
            total_verses_processed += 1

            padachheda = v_info.get("padachheda", [])
            literal_trans = v_info.get("literal_translation", "")
            traditional_meaning = v_info.get("traditional_meaning", "")
            commentator = v_info.get("commentator", "")
            bhavartha_map = v_info.get("bhavartha", {})

            for lang_code in ALL_NINE_REGIONAL_LANGS:
                trans_text = bhavartha_map.get(lang_code, "")
                if not trans_text:
                    logger.warning(f"Missing translation for {cid} V{v_num} in {lang_code}")
                    continue

                wbw_payload = {
                    "padachheda": padachheda,
                    "literal_translation": literal_trans,
                    "traditional_meaning": traditional_meaning,
                    "commentator": commentator,
                    "devotional_bhavartha": trans_text,
                    "target_language": lang_code,
                }

                existing = [
                    t for t in v_obj.translations
                    if t.target_language == lang_code and t.translation_type == TranslationType.BHAVARTHA
                ]
                if existing:
                    existing[0].translated_text = trans_text
                    existing[0].word_by_word_json = wbw_payload
                    existing[0].translator = TRANSLATOR_PROVENANCE
                    existing[0].review_status = ReviewStatus.DRAFT
                    updated_count += 1
                else:
                    new_tr = Translation(
                        verse_id=v_obj.id,
                        target_language=lang_code,
                        translation_type=TranslationType.BHAVARTHA,
                        translated_text=trans_text,
                        word_by_word_json=wbw_payload,
                        translator=TRANSLATOR_PROVENANCE,
                        review_status=ReviewStatus.DRAFT,
                    )
                    v_obj.translations.append(new_tr)
                    added_count += 1

        total_added += added_count
        total_updated += updated_count

        results[cid] = {
            "title": text_record.canonical_title,
            "verse_count": len(text_record.verses),
            "added_translations": added_count,
            "updated_translations": updated_count,
            "review_status": "DRAFT",
        }

    session.commit()

    results["summary"] = {
        "group": group_name,
        "total_added": total_added,
        "total_updated": total_updated,
        "total_verses": total_verses_processed // len(ALL_NINE_REGIONAL_LANGS),
        "total_compositions": len(target_map),
        "languages": ALL_NINE_REGIONAL_LANGS,
    }
    return results


def localize_group_a(session: Session) -> Dict[str, Any]:
    """Ingests Group A: Shiva Tandava (16) + Aditya Hrudayam (31) = 47 verses (423 translations)."""
    return _localize_group(session, "Group A (Shiva Tandava & Aditya Hrudayam)", GROUP_A_MAP)


def localize_group_b(session: Session) -> Dict[str, Any]:
    """Ingests Group B: Kanakadhara (21) + Mahishasura Mardini (21) = 42 verses (378 translations)."""
    return _localize_group(session, "Group B (Kanakadhara & Mahishasura Mardini)", GROUP_B_MAP)


def _run_group_qa(
    session: Session, group_name: str, target_map: Dict[str, Callable[[], Dict[int, Dict[str, Any]]]]
) -> Dict[str, Any]:
    """Executes the 14-rule QA engine across all compositions in the group for all 9 regional languages."""
    qa_results: Dict[str, Any] = {
        "group": group_name,
        "total_audits": 0,
        "passed_audits": 0,
        "failed_audits": 0,
        "details": {},
    }

    for cid in target_map.keys():
        text_record = session.query(Text).filter_by(content_id=cid).first()
        if not text_record:
            continue

        qa_results["details"][cid] = {}
        for lang_code in ALL_NINE_REGIONAL_LANGS:
            report = LanguageQualityAssuranceEngine.audit_text_language(text_record, lang_code)
            qa_results["total_audits"] += 1
            if report.passed_all_mandatory:
                qa_results["passed_audits"] += 1
            else:
                qa_results["failed_audits"] += 1

            qa_results["details"][cid][lang_code] = {
                "passed": report.passed_all_mandatory,
                "total_checks": report.total_checks,
                "passed_checks": report.passed_checks,
                "failed_checks": report.failed_checks,
            }

    return qa_results


def run_group_a_qa_audits(session: Session) -> Dict[str, Any]:
    """Runs 18 QA audits for Group A (2 compositions x 9 languages)."""
    return _run_group_qa(session, "Group A", GROUP_A_MAP)


def run_group_b_qa_audits(session: Session) -> Dict[str, Any]:
    """Runs 18 QA audits for Group B (2 compositions x 9 languages)."""
    return _run_group_qa(session, "Group B", GROUP_B_MAP)


def export_batch3_deliverables(session: Session) -> Dict[str, Any]:
    """
    Generates Excel (13-column), Word (12-row), and JSON comparative publication files
    plus audio recording preparation handoff manifests for all 4 Batch 3 compositions.
    """
    export_summary: Dict[str, Any] = {}

    for cid in ALL_BATCH3_MAP.keys():
        text_record = session.query(Text).filter_by(content_id=cid).first()
        if not text_record:
            continue

        # 1. Multilingual comparative exports
        pub_files = MultilingualPublicationExporter.export_all_formats(text_record)

        # 2. Audio handoff manifest
        manifest_path = AudioPreparationEngine.export_audio_manifest(text_record)

        export_summary[cid] = {
            "title": text_record.canonical_title,
            "excel": pub_files["excel"],
            "word": pub_files["word"],
            "json": pub_files["json"],
            "audio_manifest": manifest_path,
        }

    return export_summary


def run_full_batch3_pipeline(session: Session) -> Dict[str, Any]:
    """
    Executes the complete Phase 6C Batch 3 pipeline in strict stages:
    Stage 1: Localize Group A (423 translations)
    Stage 2: Run Group A QA Audits (18 audits)
    Stage 3: Localize Group B (378 translations)
    Stage 4: Run Group B QA Audits (18 audits)
    Stage 5: Generate Publication Files & Audio Manifests (all 4 texts)
    """
    pipeline_res: Dict[str, Any] = {}

    # Stage 1: Group A Localization
    logger.info("Executing Stage 1: Group A Localization...")
    res_a = localize_group_a(session)
    pipeline_res["group_a_localization"] = res_a

    # Stage 2: Group A QA Audits
    logger.info("Executing Stage 2: Group A QA Audits...")
    qa_a = run_group_a_qa_audits(session)
    pipeline_res["group_a_qa"] = qa_a
    if qa_a["failed_audits"] > 0:
        logger.error(f"Group A QA Audits failed: {qa_a['failed_audits']} failures!")
        raise RuntimeError(f"Group A QA Audits failed with {qa_a['failed_audits']} failures.")

    # Stage 3: Group B Localization
    logger.info("Executing Stage 3: Group B Localization...")
    res_b = localize_group_b(session)
    pipeline_res["group_b_localization"] = res_b

    # Stage 4: Group B QA Audits
    logger.info("Executing Stage 4: Group B QA Audits...")
    qa_b = run_group_b_qa_audits(session)
    pipeline_res["group_b_qa"] = qa_b
    if qa_b["failed_audits"] > 0:
        logger.error(f"Group B QA Audits failed: {qa_b['failed_audits']} failures!")
        raise RuntimeError(f"Group B QA Audits failed with {qa_b['failed_audits']} failures.")

    # Stage 5: Exports
    logger.info("Executing Stage 5: Multilingual Publication Exports & Audio Manifests...")
    exp_res = export_batch3_deliverables(session)
    pipeline_res["exports"] = exp_res

    pipeline_res["summary"] = {
        "status": "SUCCESS",
        "total_source_verses": 89,
        "total_regional_translations": 801,
        "total_qa_audits": qa_a["total_audits"] + qa_b["total_audits"],
        "total_qa_passed": qa_a["passed_audits"] + qa_b["passed_audits"],
        "total_compositions": 4,
    }
    return pipeline_res


if __name__ == "__main__":
    with get_db_session() as session:
        print("=== Running Phase 6C Batch 3 Complete Controlled Pipeline ===")
        res = run_full_batch3_pipeline(session)
        print(f"Pipeline Result: {res['summary']}")
