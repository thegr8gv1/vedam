"""
Populate Translation Views from Active Translation Records.

Extracts independently reviewable and versionable views:
1. Devotional Bhavartha View (BHAVARTHA)
2. Literal / Word-Dissection View (LITERAL)
3. Traditional Meaning / Exegesis View (TATPARYA)

Each view carries its own view_id, review_status, translator_provenance,
reviewer, and approval audit history.
"""

from datetime import datetime, timezone
import logging
from typing import Dict, Any, List

from database.connection import get_db_session
from database.models import (
    Translation,
    TranslationView,
    TranslationType,
    ReviewStatus,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def populate_views_for_all_translations() -> Dict[str, int]:
    """Iterates through all translation records and creates granular TranslationView records."""
    stats = {
        "processed_translations": 0,
        "views_created": 0,
        "bhavartha_views": 0,
        "literal_views": 0,
        "tatparya_views": 0,
    }

    with get_db_session() as session:
        # Check if views already populated
        existing_views_count = session.query(TranslationView).count()
        if existing_views_count > 0:
            logger.info("translation_views table already contains %d records. Skipping full re-population.", existing_views_count)
            stats["views_created"] = existing_views_count
            return stats

        translations = session.query(Translation).all()
        logger.info("Found %d translations to populate views for.", len(translations))

        views_to_insert: List[TranslationView] = []
        now = datetime.now(timezone.utc)

        for t in translations:
            stats["processed_translations"] += 1
            wbw = t.word_by_word_json if isinstance(t.word_by_word_json, dict) else {}

            # 1. Devotional Bhavartha View
            bhavartha_text = (
                wbw.get("devotional_bhavartha")
                if wbw.get("devotional_bhavartha")
                else t.translated_text
            )
            bhavartha_source = (
                f"Traditional Commentator: {wbw.get('commentator')}"
                if wbw.get("commentator")
                else "Traditional Devotional Chanting Practice"
            )

            bv = TranslationView(
                view_id=f"VIEW-TR-{t.id:05d}-BHAVARTHA-v1",
                translation_id=t.id,
                verse_id=t.verse_id,
                target_language=t.target_language,
                view_type=TranslationType.BHAVARTHA,
                view_text=bhavartha_text,
                version=1,
                source_reference=bhavartha_source,
                translator_provenance=t.translator,
                review_status=t.review_status,
                reviewer=t.reviewer,
                reviewer_affiliation=None,
                reviewed_at=None,
                approval_notes="Migrated from translation record to dedicated view entity.",
                approval_history_json=[
                    {
                        "action": "VIEW_EXTRACTED",
                        "timestamp": now.isoformat(),
                        "previous_status": None,
                        "new_status": t.review_status.value if hasattr(t.review_status, "value") else str(t.review_status),
                        "notes": "Initial granular view creation."
                    }
                ],
                created_at=now,
                updated_at=now,
            )
            views_to_insert.append(bv)
            stats["bhavartha_views"] += 1

            # 2. Literal View (if present in wbw)
            literal_text = wbw.get("literal_translation")
            if literal_text:
                lv = TranslationView(
                    view_id=f"VIEW-TR-{t.id:05d}-LITERAL-v1",
                    translation_id=t.id,
                    verse_id=t.verse_id,
                    target_language=t.target_language,
                    view_type=TranslationType.LITERAL,
                    view_text=literal_text,
                    version=1,
                    source_reference="Padachheda & Grammatical Word Dissection",
                    translator_provenance=t.translator,
                    review_status=t.review_status,
                    reviewer=t.reviewer,
                    reviewer_affiliation=None,
                    reviewed_at=None,
                    approval_notes="Literal word-by-word syntax rendering.",
                    approval_history_json=[
                        {
                            "action": "VIEW_EXTRACTED",
                            "timestamp": now.isoformat(),
                            "previous_status": None,
                            "new_status": t.review_status.value if hasattr(t.review_status, "value") else str(t.review_status),
                            "notes": "Literal view extracted from padachheda analysis."
                        }
                    ],
                    created_at=now,
                    updated_at=now,
                )
                views_to_insert.append(lv)
                stats["literal_views"] += 1

            # 3. Traditional Tatparya View (if present in wbw)
            tatparya_text = wbw.get("traditional_meaning")
            if tatparya_text:
                tv = TranslationView(
                    view_id=f"VIEW-TR-{t.id:05d}-TATPARYA-v1",
                    translation_id=t.id,
                    verse_id=t.verse_id,
                    target_language=t.target_language,
                    view_type=TranslationType.TATPARYA,
                    view_text=tatparya_text,
                    version=1,
                    source_reference=f"Sampradaya Exegesis ({wbw.get('commentator')})" if wbw.get("commentator") else "Traditional Sampradaya Commentary",
                    translator_provenance=t.translator,
                    review_status=t.review_status,
                    reviewer=t.reviewer,
                    reviewer_affiliation=None,
                    reviewed_at=None,
                    approval_notes="Traditional contextual commentary rendering.",
                    approval_history_json=[
                        {
                            "action": "VIEW_EXTRACTED",
                            "timestamp": now.isoformat(),
                            "previous_status": None,
                            "new_status": t.review_status.value if hasattr(t.review_status, "value") else str(t.review_status),
                            "notes": "Tatparya view extracted from sampradaya commentary."
                        }
                    ],
                    created_at=now,
                    updated_at=now,
                )
                views_to_insert.append(tv)
                stats["tatparya_views"] += 1

            # Batch insert in chunks of 1000
            if len(views_to_insert) >= 1000:
                session.bulk_save_objects(views_to_insert)
                session.commit()
                stats["views_created"] += len(views_to_insert)
                views_to_insert.clear()

        if views_to_insert:
            session.bulk_save_objects(views_to_insert)
            session.commit()
            stats["views_created"] += len(views_to_insert)
            views_to_insert.clear()

        logger.info("Successfully populated translation views: %s", stats)
        return stats


if __name__ == "__main__":
    populate_views_for_all_translations()
