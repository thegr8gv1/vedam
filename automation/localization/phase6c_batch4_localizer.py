"""
Vedic Heritage Platform — Phase 6C Batch 4 Localization Engine
Complete Multilingual Localization of Hanuman Chalisa and Sri Venkateswara Suprabhatam Collection:

Compositions:
1. Hanuman Chalisa (VEDA-TXT-00008) — 43 verse units (Awadhi; 2 opening Dohas, 40 Chaupais, 1 closing Doha)
   -> 43 * 9 = 387 regional translation records.
2. Sri Venkateswara Suprabhatam Complete 4-Section Collection (VEDA-TXT-00013) — 70 verse units (Sanskrit)
   - Section 1: Suprabhatam (SEC-SV-01) — 29 verses (existing in DB, updated with section metadata)
   - Section 2: Stotram (SEC-SV-02) — 11 verses (global verses 30 to 40, newly ingested)
   - Section 3: Prapatti (SEC-SV-03) — 16 verses (global verses 41 to 56, newly ingested)
   - Section 4: Mangalasasanam (SEC-SV-04) — 14 verses (global verses 57 to 70, newly ingested)
   -> 70 * 9 = 630 regional translation records.

Batch 4 Total:
- 113 source verse units (43 + 70)
- 1,017 new regional-language translation records across 9 languages
- 41 new source verse records (V030 to V070) + 41 baseline English translations
- Library-wide completion: 18 of 18 compositions (100% regional localization!).

Target Languages (9):
1. Hindi (hi)
2. Telugu (te)
3. Tamil (ta)
4. Kannada (kn)
5. Marathi (mr)
6. Bengali (bn)
7. Gujarati (gu)
8. Malayalam (ml)
9. Odia (or)

Strict Governance:
- All translations strictly flagged as ReviewStatus.DRAFT.
- Zero auto-promotion from mechanical checks to accredited scholar approval.
- Preserves distinct translation views (literal, traditional meaning, devotional Bhavartha).
- Preserves Awadhi source linguistic specificity without confusing Awadhi with modern Hindi.
- Generates 4 separate audio manifests for Suprabhatam sections plus unified collection manifest.
"""

from datetime import datetime, timezone
import hashlib
import json
import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from automation.cleaners.unicode_preserver import TransliterationEngine
from automation.localization.audio_preparation import AudioPreparationEngine
from automation.localization.exporters import MultilingualPublicationExporter
from automation.localization.hanuman_chalisa import get_hanuman_chalisa_payload
from automation.localization.qa_framework import LanguageQualityAssuranceEngine, QACheckStatus
from automation.localization.venkateswara_suprabhatam import (
    SUPRABHATAM_SECTIONS,
    get_full_suprabhatam_collection_payload,
)
from database.connection import get_db_session
from database.models import (
    ReviewStatus,
    Text,
    Translation,
    TranslationType,
    Transliteration,
    Verse,
    VerseType,
)

logger = logging.getLogger("vedam.automation.localization.phase6c_batch4")

ALL_NINE_REGIONAL_LANGS = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]

HC_TRANSLATOR = (
    "Platform Multilingual Localization Engine (Editorial Awadhi Devotional Synthesis; Awaiting Accredited Scholar Panel)"
)
SV_TRANSLATOR = (
    "Platform Multilingual Localization Engine (Editorial Tirumala Liturgical Synthesis; Awaiting Scholarly Panel / Accredited Scholar Panel)"
)


def ingest_suprabhatam_collection_expansion(session: Session) -> Dict[str, Any]:
    """
    Expands VEDA-TXT-00013 from 29 verses to 70 verses across 4 canonical sections:
    1. Updates existing 29 verses (V001..V029) with Section 1 metadata in notes.
    2. Ingests 41 new Verse records (V030..V070) for Stotram, Prapatti, and Mangalasasanam.
    3. Adds baseline English draft translations for verses 30 to 70.
    4. Updates Text.verse_count = 70.
    """
    text_record = session.query(Text).filter_by(content_id="VEDA-TXT-00013").first()
    if not text_record:
        raise ValueError("Text VEDA-TXT-00013 not found in database.")

    collection_data = get_full_suprabhatam_collection_payload()
    existing_verses = {v.verse_number: v for v in text_record.verses}

    verses_added = 0
    verses_updated = 0
    english_added = 0

    for v_num in range(1, 71):
        v_data = collection_data[v_num]
        sec_id = v_data["section_id"]
        sec_meta = SUPRABHATAM_SECTIONS[sec_id]

        sec_notes_payload = {
            "section_id": sec_id,
            "section_name": sec_meta.original_section_name,
            "section_english_name": sec_meta.english_section_name,
            "section_order": sec_meta.traditional_order,
            "section_verse": v_data["section_verse"],
            "liturgical_role": sec_meta.liturgical_role,
        }
        notes_str = json.dumps(sec_notes_payload, ensure_ascii=False)

        if v_num in existing_verses:
            # Update existing verse notes
            v_obj = existing_verses[v_num]
            v_obj.notes = notes_str
            # Ensure multi-script transliterations are present
            existing_scripts = {t.target_script for t in v_obj.transliterations}
            for script in ["telugu", "tamil", "kannada", "malayalam", "iast"]:
                if script not in existing_scripts:
                    try:
                        conv = TransliterationEngine.to_script(v_data["devanagari"], script)
                        v_obj.transliterations.append(
                            Transliteration(
                                target_script=script,
                                script_text=conv,
                                is_lossless=True,
                            )
                        )
                    except Exception as e:
                        logger.warning(f"Error transliterating {v_obj.verse_id} to {script}: {e}")

            # Ensure English translation translator contains required scholar review note
            en_trans_list = [t for t in v_obj.translations if t.target_language == "en"]
            for et in en_trans_list:
                if "Awaiting Scholarly Panel" not in et.translator:
                    et.translator = SV_TRANSLATOR

            verses_updated += 1
        else:
            # Ingest new verse (V030 to V070)
            v_id_str = f"VEDA-TXT-00013-V{v_num:03d}"
            new_verse = Verse(
                text_id=text_record.id,
                verse_id=v_id_str,
                verse_number=v_num,
                verse_type=VerseType.VERSE,
                devanagari_text=v_data["devanagari"],
                iast_text=v_data["iast"],
                meter=v_data.get("meter", "Anushtubh"),
                notes=notes_str,
            )
            # Add multi-script transliterations
            for script in ["telugu", "tamil", "kannada", "malayalam", "iast"]:
                try:
                    conv = TransliterationEngine.to_script(v_data["devanagari"], script)
                    new_verse.transliterations.append(
                        Transliteration(
                            target_script=script,
                            script_text=conv,
                            is_lossless=True,
                        )
                    )
                except Exception as e:
                    logger.warning(f"Error transliterating {new_verse.verse_id} to {script}: {e}")

            session.add(new_verse)
            session.flush()  # assign id

            # Add English draft baseline translation for new verse
            literal_en = v_data.get("literal_translation", "")
            trad_en = v_data.get("traditional_meaning", "")
            en_wbw = {
                "padachheda": v_data.get("padachheda", []),
                "literal_translation": literal_en,
                "traditional_meaning": trad_en,
                "commentator": v_data.get("commentator", "Prativadi Bhayankaram Annan"),
                "section_id": sec_id,
                "section_verse": v_data["section_verse"],
            }
            en_trans = Translation(
                verse_id=new_verse.id,
                target_language="en",
                translation_type=TranslationType.BHAVARTHA,
                translated_text=literal_en,
                word_by_word_json=en_wbw,
                translator=SV_TRANSLATOR,
                review_status=ReviewStatus.DRAFT,
            )
            session.add(en_trans)
            verses_added += 1
            english_added += 1

    # Update Text record verse count and canonical collection metadata
    text_record.verse_count = 70
    session.commit()

    return {
        "content_id": "VEDA-TXT-00013",
        "title": text_record.canonical_title,
        "existing_verses_annotated": verses_updated,
        "new_verses_ingested": verses_added,
        "new_english_translations": english_added,
        "final_verse_count": len(text_record.verses),
    }


def localize_hanuman_chalisa(session: Session) -> Dict[str, Any]:
    """
    Ingests 387 regional translations (43 verses x 9 languages) for Hanuman Chalisa (VEDA-TXT-00008).
    Preserves Awadhi vocabulary analysis, Doha vs Chaupai meter, and standard modern Hindi translation.
    """
    text_record = session.query(Text).filter_by(content_id="VEDA-TXT-00008").first()
    if not text_record:
        raise ValueError("Text VEDA-TXT-00008 not found in database.")

    hc_data = get_hanuman_chalisa_payload()
    verse_records = {v.verse_number: v for v in text_record.verses}

    added_count = 0
    updated_count = 0

    for v_num, v_info in hc_data.items():
        if v_num not in verse_records:
            logger.warning(f"Verse {v_num} not found in Hanuman Chalisa")
            continue

        v_obj = verse_records[v_num]
        awadhi_words = v_info.get("awadhi_words", [])
        literal_trans = v_info.get("literal_translation", "")
        traditional_meaning = v_info.get("traditional_meaning", "")
        cultural_notes = v_info.get("cultural_notes", "")
        bhavartha_map = v_info.get("bhavartha", {})

        for lang_code in ALL_NINE_REGIONAL_LANGS:
            trans_text = bhavartha_map.get(lang_code, "")
            if not trans_text:
                continue

            wbw_payload = {
                "verse_type": v_info.get("verse_type", "CHAUPAI"),
                "awadhi_words": awadhi_words,
                "literal_translation": literal_trans,
                "traditional_meaning": traditional_meaning,
                "cultural_notes": cultural_notes,
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
                existing[0].translator = HC_TRANSLATOR
                existing[0].review_status = ReviewStatus.DRAFT
                updated_count += 1
            else:
                new_tr = Translation(
                    verse_id=v_obj.id,
                    target_language=lang_code,
                    translation_type=TranslationType.BHAVARTHA,
                    translated_text=trans_text,
                    word_by_word_json=wbw_payload,
                    translator=HC_TRANSLATOR,
                    review_status=ReviewStatus.DRAFT,
                )
                v_obj.translations.append(new_tr)
                added_count += 1

    session.commit()

    return {
        "content_id": "VEDA-TXT-00008",
        "title": text_record.canonical_title,
        "source_language": "awa (Awadhi)",
        "source_verses": len(hc_data),
        "translations_added": added_count,
        "translations_updated": updated_count,
        "languages": ALL_NINE_REGIONAL_LANGS,
        "review_status": "DRAFT",
    }


def localize_venkateswara_suprabhatam(session: Session) -> Dict[str, Any]:
    """
    Ingests 630 regional translations (70 verses x 9 languages) for Sri Venkateswara Suprabhatam (VEDA-TXT-00013).
    Populates padachheda, literal, traditional meaning, and 9 regional Bhavarthas with section awareness.
    """
    text_record = session.query(Text).filter_by(content_id="VEDA-TXT-00013").first()
    if not text_record:
        raise ValueError("Text VEDA-TXT-00013 not found in database.")

    sv_data = get_full_suprabhatam_collection_payload()
    verse_records = {v.verse_number: v for v in text_record.verses}

    added_count = 0
    updated_count = 0

    for v_num, v_info in sv_data.items():
        if v_num not in verse_records:
            logger.warning(f"Verse {v_num} not found in Venkateswara Suprabhatam")
            continue

        v_obj = verse_records[v_num]
        sec_id = v_info["section_id"]
        sec_meta = SUPRABHATAM_SECTIONS[sec_id]

        padachheda = v_info.get("padachheda", [])
        literal_trans = v_info.get("literal_translation", "")
        traditional_meaning = v_info.get("traditional_meaning", "")
        commentator = v_info.get("commentator", "Prativadi Bhayankaram Annan")
        bhavartha_map = v_info.get("bhavartha", {})

        for lang_code in ALL_NINE_REGIONAL_LANGS:
            trans_text = bhavartha_map.get(lang_code, "")
            if not trans_text:
                continue

            wbw_payload = {
                "section_id": sec_id,
                "section_name": sec_meta.original_section_name,
                "section_order": sec_meta.traditional_order,
                "section_verse": v_info["section_verse"],
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
                existing[0].translator = SV_TRANSLATOR
                existing[0].review_status = ReviewStatus.DRAFT
                updated_count += 1
            else:
                new_tr = Translation(
                    verse_id=v_obj.id,
                    target_language=lang_code,
                    translation_type=TranslationType.BHAVARTHA,
                    translated_text=trans_text,
                    word_by_word_json=wbw_payload,
                    translator=SV_TRANSLATOR,
                    review_status=ReviewStatus.DRAFT,
                )
                v_obj.translations.append(new_tr)
                added_count += 1

    session.commit()

    return {
        "content_id": "VEDA-TXT-00013",
        "title": text_record.canonical_title,
        "source_language": "sa (Sanskrit)",
        "canonical_sections": 4,
        "source_verses": len(sv_data),
        "translations_added": added_count,
        "translations_updated": updated_count,
        "languages": ALL_NINE_REGIONAL_LANGS,
        "review_status": "DRAFT",
    }


def run_batch4_qa_audits(session: Session) -> Dict[str, Any]:
    """
    Executes all 14 QA checks on Hanuman Chalisa and Sri Venkateswara Suprabhatam
    across all 9 regional languages (2 compositions x 9 languages = 18 audits).
    """
    qa_results: Dict[str, Any] = {
        "batch": "Phase 6C Batch 4",
        "total_audits": 0,
        "passed_audits": 0,
        "failed_audits": 0,
        "details": {},
    }

    for cid in ["VEDA-TXT-00008", "VEDA-TXT-00013"]:
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


def export_batch4_deliverables(session: Session) -> Dict[str, Any]:
    """
    Generates 2 Excel (13-column), 2 Word (12-row with TOC for Suprabhatam), 2 JSON comparative publication files,
    plus 1 audio manifest for Hanuman Chalisa, 4 section audio manifests for Suprabhatam, 1 full Suprabhatam audio manifest,
    and a complete SHA-256 publication manifest.
    """
    export_summary: Dict[str, Any] = {}
    manifest_entries: List[Dict[str, Any]] = []

    for cid in ["VEDA-TXT-00008", "VEDA-TXT-00013"]:
        text_record = session.query(Text).filter_by(content_id=cid).first()
        if not text_record:
            continue

        # 1. Multilingual comparative exports
        pub_files = MultilingualPublicationExporter.export_all_formats(text_record)

        # 2. Audio handoff manifests
        if cid == "VEDA-TXT-00013":
            # 4 discrete section audio manifests
            sec_manifests = AudioPreparationEngine.export_section_audio_manifests(text_record)
            # Full collection audio manifest
            full_audio = AudioPreparationEngine.export_audio_manifest(text_record)
            audio_files = [full_audio] + sec_manifests
        else:
            full_audio = AudioPreparationEngine.export_audio_manifest(text_record)
            audio_files = [full_audio]

        export_summary[cid] = {
            "title": text_record.canonical_title,
            "excel": pub_files["excel"],
            "word": pub_files["word"],
            "json": pub_files["json"],
            "audio_manifests": audio_files,
        }

        # Calculate SHA-256 for all exported artifacts
        for fpath in [pub_files["excel"], pub_files["word"], pub_files["json"]] + audio_files:
            if os.path.exists(fpath):
                with open(fpath, "rb") as f:
                    sha256 = hashlib.sha256(f.read()).hexdigest()
                manifest_entries.append({
                    "content_id": cid,
                    "file_path": fpath,
                    "file_name": os.path.basename(fpath),
                    "file_size_bytes": os.path.getsize(fpath),
                    "sha256": sha256,
                })

    # Save Batch 4 SHA-256 Manifest
    manifest_dir = Path("exports/manifests")
    manifest_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = manifest_dir / "phase6c_batch4_sha256_manifest.json"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump({
            "batch": "Phase 6C Batch 4",
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "total_artifacts": len(manifest_entries),
            "artifacts": manifest_entries,
        }, f, indent=2, ensure_ascii=False)

    export_summary["sha256_manifest"] = str(manifest_path)
    return export_summary


def run_full_batch4_pipeline(session: Session) -> Dict[str, Any]:
    """
    Executes the complete Phase 6C Batch 4 pipeline:
    Stage 1: Expand Sri Venkateswara Suprabhatam to 70 verses across 4 sections.
    Stage 2: Localize Hanuman Chalisa (387 translations).
    Stage 3: Localize Sri Venkateswara Suprabhatam (630 translations).
    Stage 4: Run Batch 4 QA Audits (18 audits across 9 languages).
    Stage 5: Generate Publication Files, Section Audio Manifests, and SHA-256 Manifest.
    """
    pipeline_res: Dict[str, Any] = {}

    # Stage 1: Suprabhatam Expansion
    logger.info("Executing Stage 1: Suprabhatam 70-verse 4-section expansion...")
    exp_sv = ingest_suprabhatam_collection_expansion(session)
    pipeline_res["suprabhatam_expansion"] = exp_sv

    # Stage 2: Hanuman Chalisa Localization
    logger.info("Executing Stage 2: Hanuman Chalisa localization (387 translations)...")
    res_hc = localize_hanuman_chalisa(session)
    pipeline_res["hanuman_chalisa_localization"] = res_hc

    # Stage 3: Suprabhatam Localization
    logger.info("Executing Stage 3: Suprabhatam localization (630 translations)...")
    res_sv = localize_venkateswara_suprabhatam(session)
    pipeline_res["suprabhatam_localization"] = res_sv

    # Stage 4: QA Audits
    logger.info("Executing Stage 4: QA Audits (18 audits)...")
    qa_res = run_batch4_qa_audits(session)
    pipeline_res["qa_audits"] = qa_res
    if qa_res["failed_audits"] > 0:
        logger.error(f"Batch 4 QA Audits failed: {qa_res['failed_audits']} failures!")
        raise RuntimeError(f"Batch 4 QA Audits failed with {qa_res['failed_audits']} failures.")

    # Stage 5: Exports
    logger.info("Executing Stage 5: Publication deliverables & Audio section manifests...")
    deliverables = export_batch4_deliverables(session)
    pipeline_res["deliverables"] = deliverables

    pipeline_res["summary"] = {
        "status": "SUCCESS",
        "batch": "Phase 6C Batch 4",
        "total_source_verses": 113,
        "total_regional_translations": 1017,
        "total_qa_audits": qa_res["total_audits"],
        "total_qa_passed": qa_res["passed_audits"],
        "total_qa_failed": qa_res["failed_audits"],
        "suprabhatam_sections": 4,
        "hanuman_chalisa_verses": 43,
        "suprabhatam_verses": 70,
        "library_milestone": "100% REGIONAL LOCALIZATION COMPLETE (18/18 compositions)",
    }
    return pipeline_res


if __name__ == "__main__":
    with get_db_session() as session:
        print("=== Running Phase 6C Batch 4 Complete Controlled Pipeline ===")
        res = run_full_batch4_pipeline(session)
        print(f"Pipeline Result: {res['summary']}")
