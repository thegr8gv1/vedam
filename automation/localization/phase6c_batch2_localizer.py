"""
Vedic Heritage Platform — Phase 6C Batch 2 Localization Engine
Multilingual Localization of Four Important Vedic Suktams:
1. Sri Suktam (VEDA-TXT-00007) — 16 verses
2. Purusha Suktam (VEDA-TXT-00014) — 16 verses
3. Durga Suktam (VEDA-TXT-00015) — 7 verses
4. Narayana Suktam (VEDA-TXT-00016) — 12 verses

Total source verse units: 51
Total target translations: 51 * 9 regional languages = 459 new translation records.

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
B. Traditional meaning: informed by established classical commentaries (Sayana, Bhatta Bhaskara, Vidyaranya).
C. Devotional Bhavartha: readable explanation suitable for devotees across all 9 regional languages.
Separate Padachheda stored in word_by_word_json.

Strict Governance:
- All translations flagged as ReviewStatus.DRAFT.
- Attributed to 'Platform Multilingual Localization Engine (Editorial Vedic Synthesis; Awaiting Accredited Scholar Panel)'.
- Never automatically promote AI or editorial translations to approved status.
"""

from datetime import datetime, timezone
import json
import logging
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from automation.localization.audio_preparation import AudioPreparationEngine
from automation.localization.exporters import MultilingualPublicationExporter
from automation.localization.qa_framework import LanguageQualityAssuranceEngine, QACheckStatus
from automation.localization.vedic_suktams import (
    get_durga_suktam_payload,
    get_narayana_suktam_payload,
    get_purusha_suktam_payload,
    get_sri_suktam_payload,
)
from database.connection import get_db_session
from database.models import ReviewStatus, Text, Translation, TranslationType, Verse

logger = logging.getLogger("vedam.automation.localization.phase6c_batch2")


BATCH2_TEXT_MAP = {
    "VEDA-TXT-00007": get_sri_suktam_payload,
    "VEDA-TXT-00014": get_purusha_suktam_payload,
    "VEDA-TXT-00015": get_durga_suktam_payload,
    "VEDA-TXT-00016": get_narayana_suktam_payload,
}

ALL_NINE_REGIONAL_LANGS = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]


def localize_batch2_compositions(session: Session) -> Dict[str, Any]:
    """
    Ingests 459 multilingual translation records for the 4 Vedic Suktams across all 9 regional languages.
    Stores literal, traditional, and padachheda breakdowns in word_by_word_json.
    Strictly sets review_status to ReviewStatus.DRAFT.
    """
    results: Dict[str, Any] = {}
    translator_provenance = (
        "Platform Multilingual Localization Engine (Editorial Vedic Synthesis; Awaiting Accredited Scholar Panel)"
    )

    total_added = 0
    total_updated = 0
    total_verses_processed = 0

    for cid, payload_func in BATCH2_TEXT_MAP.items():
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
                    existing[0].translator = translator_provenance
                    existing[0].review_status = ReviewStatus.DRAFT
                    updated_count += 1
                else:
                    new_tr = Translation(
                        verse_id=v_obj.id,
                        target_language=lang_code,
                        translation_type=TranslationType.BHAVARTHA,
                        translated_text=trans_text,
                        word_by_word_json=wbw_payload,
                        translator=translator_provenance,
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
        "total_added": total_added,
        "total_updated": total_updated,
        "total_verses": total_verses_processed // len(ALL_NINE_REGIONAL_LANGS),
        "total_compositions": len(BATCH2_TEXT_MAP),
        "languages": ALL_NINE_REGIONAL_LANGS,
    }
    return results


def export_batch2_deliverables(session: Session) -> Dict[str, Any]:
    """
    Generates Excel (13-column), Word (12-row), and JSON comparative publication files
    plus audio recording preparation handoff manifests for the 4 Batch 2 compositions.
    """
    export_summary: Dict[str, Any] = {}

    for cid in BATCH2_TEXT_MAP.keys():
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


def run_batch2_qa_audits(session: Session) -> Dict[str, Any]:
    """
    Executes the 14-rule Language Quality Assurance Engine across all 4 texts and all 9 regional languages.
    """
    qa_results: Dict[str, Any] = {"total_audits": 0, "passed_audits": 0, "failed_audits": 0, "details": {}}

    for cid in BATCH2_TEXT_MAP.keys():
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


if __name__ == "__main__":
    with get_db_session() as session:
        print("=== Localizing Phase 6C Batch 2 Compositions ===")
        loc_res = localize_batch2_compositions(session)
        print(json.dumps(loc_res, indent=2, ensure_ascii=False))

        print("\n=== Generating Batch 2 Publication Deliverables & Audio Manifests ===")
        exp_res = export_batch2_deliverables(session)
        print(json.dumps(exp_res, indent=2, ensure_ascii=False))

        print("\n=== Running Batch 2 Language QA Audits ===")
        qa_res = run_batch2_qa_audits(session)
        print(f"Total Audits: {qa_res['total_audits']}, Passed: {qa_res['passed_audits']}, Failed: {qa_res['failed_audits']}")
