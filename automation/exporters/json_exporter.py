"""
Vedic Heritage Platform — Mobile JSON Exporter
Generates standardized, schema-validated JSON bundles for mobile application
sync, offline cache, and devotional audio production handoffs.
"""

from datetime import datetime, timezone
import json
from pathlib import Path
from typing import Any, Dict, Optional

from automation.rights.engine import RightsProvenanceEngine
from database.models import ReleaseStatus, Text


class JSONExporter:
    """Exports structured sacred literature into mobile-ready JSON data bundles."""

    @classmethod
    def export_text_bundle(cls, text: Text, output_path: str, target_channel: str = "scholarly_review") -> str:
        """
        Serialize a Text entity into an authoritative JSON bundle.
        Enforces rights clearance before generating the payload.
        """
        RightsProvenanceEngine.assert_export_clearance(text.rights, target_channel)

        rights = text.rights
        is_green = rights.release_status == ReleaseStatus.GREEN if rights else False

        verses_data = []
        for v in text.verses:
            translit_map = {t.target_script: t.script_text for t in v.transliterations}
            trans_list = []
            for tr in v.translations:
                trans_list.append({
                    "language": tr.target_language,
                    "type": tr.translation_type.value,
                    "text": tr.translated_text,
                    "word_by_word": tr.word_by_word_json,
                    "review_status": tr.review_status.value if tr.review_status else "DRAFT",
                })

            verses_data.append({
                "verse_id": v.verse_id,
                "verse_number": v.verse_number,
                "verse_type": v.verse_type.value,
                "devanagari": v.devanagari_text,
                "iast": v.iast_text,
                "vedic_accents_present": v.vedic_accents_present,
                "meter": v.meter,
                "transliterations": translit_map,
                "translations": trans_list,
            })

        bundle: Dict[str, Any] = {
            "schema_version": "1.0.0",
            "content_id": text.content_id,
            "uuid": text.uuid,
            "title": {
                "canonical": text.canonical_title,
                "devanagari": text.devanagari_title,
                "alternatives": text.alternative_titles or [],
            },
            "taxonomy": {
                "category": text.primary_category.slug if text.primary_category else "stotra",
                "category_name": text.primary_category.name if text.primary_category else "Stotra",
                "deity": text.deity.slug if text.deity else None,
                "deity_name": text.deity.name if text.deity else None,
            },
            "liturgical_metadata": {
                "composer": text.composer,
                "rishi": text.rishi,
                "chandas": text.chandas,
                "devata": text.devata,
                "source_scripture": text.source_scripture,
                "associated_festival": text.associated_festival,
                "traditional_usage": text.traditional_usage,
                "original_language": text.original_language,
                "original_script": text.original_script,
            },
            "rights_and_provenance": {
                "release_status": rights.release_status.value if rights else "UNAUDITED",
                "license_type": rights.license_type if rights else "RESTRICTED",
                "commercial_reuse_permitted": rights.commercial_reuse_permitted if rights else False,
                "primary_source": rights.primary_source if rights else "Unknown",
                "specific_edition": rights.specific_edition if rights else None,
                "attribution_required": rights.attribution_required if rights else True,
                "attribution_text": rights.attribution_text if rights else None,
                "content_hash": text.content_hash,
            },
            "mobile_integration": {
                "is_released_for_production": is_green,
                "total_verses": text.verse_count,
                "chanting_presets": [1, 3, 11, 21, 27, 54, 108],
                "supports_japa_counter": True,
                "offline_cache_priority": "HIGH" if is_green else "LOW",
            },
            "verses": verses_data,
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

        out_file = Path(output_path)
        out_file.parent.mkdir(parents=True, exist_ok=True)
        with open(out_file, "w", encoding="utf-8") as f:
            json.dump(bundle, f, indent=2, ensure_ascii=False)

        return str(out_file)
