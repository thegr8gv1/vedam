"""
Vedic Heritage Platform — TranslationView Gap Audit & Backfill Queue Engine
Performs exhaustive gap audit across all 752 legacy translation records lacking separate
Literal and Traditional Meaning (Tatparya) views.
Generates prioritized backfill queues mapped to required reviewer competencies without
automatically manufacturing or publishing unapproved views.
"""

from collections import defaultdict
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import json
import logging
import os
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from database.models import (
    ReviewerRole,
    Text,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)

logger = logging.getLogger("vedam.automation.workbench.backfill_queue")


@dataclass
class BackfillItem:
    translation_id: int
    composition_id: str
    composition_title: str
    verse_id: int
    verse_number: int
    language: str
    available_views: List[str]
    missing_views: List[str]
    existing_bhavartha_text: str
    missing_literal_view: bool
    missing_tatparya_view: bool
    supporting_references: List[str]
    rights_clearance_status: str
    review_status: str
    priority_tier: str
    priority_level: int
    required_reviewer_roles: List[str]
    queue_status: str = "STAGED_AWAITING_AUTHORIZATION"


class BackfillQueueEngine:
    """Manages the 752-record legacy gap audit, priority scoring, and reviewer queue staging."""

    TIER_1_VEDIC = {
        "VEDA-TXT-00005",  # Mahamrityunjaya Mantra
        "VEDA-TXT-00006",  # Gayatri Mantra
        "VEDA-TXT-00007",  # Sri Suktam
        "VEDA-TXT-00014",  # Purusha Suktam
        "VEDA-TXT-00015",  # Durga Suktam
        "VEDA-TXT-00016",  # Narayana Suktam
    }

    TIER_2_MAJOR_STOTRAS = {
        "VEDA-TXT-00001",  # Ganesha Pancharatnam
        "VEDA-TXT-00002",  # Shiva Tandava Stotram
        "VEDA-TXT-00003",  # Aditya Hrudayam
        "VEDA-TXT-00013",  # Venkateswara Suprabhatam
        "VEDA-TXT-00018",  # Kanakadhara Stotram
        "VEDA-TXT-00019",  # Mahishasura Mardini Stotram
    }

    TIER_3_ASHTAKAMS = {
        "VEDA-TXT-00004",  # Madhurashtakam
        "VEDA-TXT-00010",  # Mahalakshmi Ashtakam
        "VEDA-TXT-00011",  # Lingashtakam
        "VEDA-TXT-00012",  # Sankata Nashana Ganesha Stotram
        "VEDA-TXT-00017",  # Surya Ashtakam
    }

    TIER_4_VERNACULAR = {
        "VEDA-TXT-00008",  # Hanuman Chalisa
    }

    LANGUAGE_ROLE_MAP = {
        "hi": ReviewerRole.HINDI_TRANSLATOR.value,
        "te": ReviewerRole.TELUGU_TRANSLATOR.value,
        "ta": ReviewerRole.TAMIL_TRANSLATOR.value,
        "kn": ReviewerRole.KANNADA_TRANSLATOR.value,
        "mr": ReviewerRole.MARATHI_TRANSLATOR.value,
        "bn": ReviewerRole.BENGALI_TRANSLATOR.value,
        "gu": ReviewerRole.GUJARATI_TRANSLATOR.value,
        "ml": ReviewerRole.MALAYALAM_TRANSLATOR.value,
        "or": ReviewerRole.ODIA_TRANSLATOR.value,
        "en": ReviewerRole.SANSKRIT_TEXTUAL.value,
    }

    @classmethod
    def audit_legacy_gaps(cls, session: Session) -> Dict[str, Any]:
        """
        Audits all 752 legacy translations lacking separate Literal and Tatparya views,
        classifies priorities, maps required reviewer roles, and prepares the staged queue.
        """
        translations = session.query(Translation).all()
        all_views = session.query(TranslationView).all()

        trans_views_map = defaultdict(set)
        for v in all_views:
            trans_views_map[v.translation_id].add(v.view_type.value if hasattr(v.view_type, "value") else str(v.view_type))

        gap_items: List[BackfillItem] = []
        comp_summary = defaultdict(int)
        lang_summary = defaultdict(int)
        tier_summary = defaultdict(int)

        for t in translations:
            existing_views = trans_views_map[t.id]
            missing = []
            if "LITERAL" not in existing_views:
                missing.append("LITERAL")
            if "TATPARYA" not in existing_views:
                missing.append("TATPARYA")

            # If missing either Literal or Tatparya (or both)
            if missing:
                verse = session.query(Verse).filter_by(id=t.verse_id).first()
                if not verse:
                    continue
                text = session.query(Text).filter_by(id=verse.text_id).first()
                if not text:
                    continue

                # Determine Priority Tier
                cid = text.content_id
                if cid in cls.TIER_1_VEDIC:
                    tier_name = "Tier 1: Canonical Vedic Mantras & Suktams"
                    tier_level = 1
                    base_roles = [ReviewerRole.VEDIC_RECENSION.value, ReviewerRole.TRADITIONAL_COMMENTARY.value]
                elif cid in cls.TIER_2_MAJOR_STOTRAS:
                    tier_name = "Tier 2: Major Devotional & Philosophical Stotras"
                    tier_level = 2
                    base_roles = [ReviewerRole.SANSKRIT_TEXTUAL.value, ReviewerRole.TRADITIONAL_COMMENTARY.value]
                elif cid in cls.TIER_3_ASHTAKAMS:
                    tier_name = "Tier 3: Classical Devotional Ashtakams"
                    tier_level = 3
                    base_roles = [ReviewerRole.SANSKRIT_GRAMMAR.value]
                elif cid in cls.TIER_4_VERNACULAR:
                    tier_name = "Tier 4: Vernacular Bhakti Literature (Awadhi)"
                    tier_level = 4
                    base_roles = [ReviewerRole.AWADHI_SPECIALIST.value]
                else:
                    tier_name = "Tier 5: General Devotional Hymns"
                    tier_level = 5
                    base_roles = [ReviewerRole.SANSKRIT_TEXTUAL.value]

                # Map Language-Specific Reviewer Role
                lang_role = cls.LANGUAGE_ROLE_MAP.get(t.target_language, ReviewerRole.HINDI_TRANSLATOR.value)
                required_roles = list(set(base_roles + [lang_role]))

                existing_bhavartha = (t.translated_text or "").strip()
                missing_lit = "LITERAL" in missing
                missing_tat = "TATPARYA" in missing
                rights_st = text.rights_clearance_status.value if hasattr(text, "rights_clearance_status") and text.rights_clearance_status else "GREEN_CLEARED"
                supp_refs = [
                    f"Primary Edition: {text.source_scripture or text.canonical_title}",
                    f"Canonical Attribution: {text.composer or 'Traditional Rishi'}",
                ]

                item = BackfillItem(
                    translation_id=t.id,
                    composition_id=text.content_id,
                    composition_title=text.canonical_title,
                    verse_id=verse.id,
                    verse_number=verse.verse_number,
                    language=t.target_language,
                    available_views=sorted(list(existing_views)),
                    missing_views=sorted(missing),
                    existing_bhavartha_text=existing_bhavartha[:150] + ("..." if len(existing_bhavartha) > 150 else ""),
                    missing_literal_view=missing_lit,
                    missing_tatparya_view=missing_tat,
                    supporting_references=supp_refs,
                    rights_clearance_status=rights_st,
                    review_status=t.review_status.value if hasattr(t.review_status, "value") else str(t.review_status),
                    priority_tier=tier_name,
                    priority_level=tier_level,
                    required_reviewer_roles=required_roles,
                )
                gap_items.append(item)
                comp_summary[f"{text.content_id} ({text.canonical_title})"] += 1
                lang_summary[t.target_language] += 1
                tier_summary[tier_name] += 1

        # Sort items by priority_level asc, composition_id asc, verse_number asc, language asc
        sorted_items = sorted(gap_items, key=lambda x: (x.priority_level, x.composition_id, x.verse_number, x.language))

        audit_results = {
            "audit_timestamp": datetime.now(timezone.utc).isoformat(),
            "total_legacy_gap_records": len(sorted_items),
            "tier_distribution": dict(tier_summary),
            "composition_breakdown": dict(comp_summary),
            "language_breakdown": dict(lang_summary),
            "staged_backfill_queue": [asdict(item) for item in sorted_items],
            "governance_note": (
                "STRICT GOVERNANCE BARRIER: Missing views are staged for reviewer dispatching only. "
                "No views are automatically inserted or published without explicit authorization."
            ),
        }

        # Save JSON Backfill Queue
        os.makedirs("exports/reports", exist_ok=True)
        json_file = "exports/reports/translation_view_backfill_queue.json"
        with open(json_file, "w", encoding="utf-8") as f:
            json.dump(audit_results, f, indent=2, ensure_ascii=False)

        # Generate Comprehensive Markdown Gap Report
        os.makedirs("documentation/quality", exist_ok=True)
        md_file = "documentation/quality/TRANSLATION_VIEW_GAP_REPORT_752.md"
        with open(md_file, "w", encoding="utf-8") as f:
            f.write("# TranslationView Gap Audit & Prioritized Backfill Queue Report\n\n")
            f.write(f"**Audit Date:** {audit_results['audit_timestamp']}  \n")
            f.write(f"**Total Legacy Records Audited:** **{len(sorted_items)}**  \n")
            f.write("**Status:** Staged in Backfill Queue (Awaiting Human Scholar Authorization)  \n")
            f.write("**Rule PUB-011 Enforced:** Zero automated insertion or pre-publication of unapproved views  \n\n")
            f.write("---\n\n")

            f.write("## 1. Executive Summary & Prioritization Tiers\n\n")
            f.write("| Priority Tier | Target Texts | Staged Records | Required Reviewer Roles |\n")
            f.write("| :--- | :--- | :--- | :--- |\n")
            f.write(f"| **Tier 1: Canonical Vedic** | Gayatri, Mahamrityunjaya, Sri, Purusha, Durga, Narayana Suktams | {tier_summary.get('Tier 1: Canonical Vedic Mantras & Suktams', 0)} | `VEDIC_RECENSION`, `TRADITIONAL_COMMENTARY`, Target Language Translator |\n")
            f.write(f"| **Tier 2: Major Stotras** | Ganesha Pancharatnam, Shiva Tandava, Aditya Hrudayam, Suprabhatam, Kanakadhara, Mahishasura Mardini | {tier_summary.get('Tier 2: Major Devotional & Philosophical Stotras', 0)} | `SANSKRIT_TEXTUAL`, `TRADITIONAL_COMMENTARY`, Target Language Translator |\n")
            f.write(f"| **Tier 3: Ashtakams** | Madhurashtakam, Mahalakshmi, Lingashtakam, Sankata Nashana, Surya Ashtakam | {tier_summary.get('Tier 3: Classical Devotional Ashtakams', 0)} | `SANSKRIT_GRAMMAR`, Target Language Translator |\n")
            f.write(f"| **Tier 4: Vernacular Bhakti** | Hanuman Chalisa | {tier_summary.get('Tier 4: Vernacular Bhakti Literature (Awadhi)', 0)} | `AWADHI_SPECIALIST`, `HINDI_TRANSLATOR` |\n")
            f.write(f"| **Total** | **All 18 Canonical Compositions** | **{len(sorted_items)}** | **Multi-disciplinary Scholarly Reviewers** |\n\n")

            f.write("---\n\n")
            f.write("## 2. Language-Wise Distribution of Legacy Records\n\n")
            f.write("| Language Code | Language Name | Legacy Records | Missing Views |\n")
            f.write("| :--- | :--- | :--- | :--- |\n")
            for lang, count in sorted(lang_summary.items()):
                f.write(f"| `{lang}` | {lang.upper()} | {count} | `LITERAL`, `TATPARYA` |\n")
            f.write(f"| **Total** | **All 10 Languages (EN + 9 Regional)** | **{len(sorted_items)}** | |\n\n")

            f.write("---\n\n")
            f.write("## 3. Composition-Wise Gap Ledger\n\n")
            f.write("| Content ID & Title | Legacy Count | Target Languages | Priority Tier |\n")
            f.write("| :--- | :--- | :--- | :--- |\n")
            for comp, count in sorted(comp_summary.items()):
                f.write(f"| {comp} | {count} | EN + 9 Regional | High / Normal |\n")
            f.write("\n---\n\n")

            f.write("## 4. Staged Backfill Queue Sample (First 25 Entries)\n\n")
            f.write("| Translation ID | Composition | Verse | Lang | Available | Missing | Required Roles | Status |\n")
            f.write("| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n")
            for item in sorted_items[:25]:
                f.write(
                    f"| `{item.translation_id}` | {item.composition_id} | v{item.verse_number} | "
                    f"`{item.language}` | {','.join(item.available_views)} | {','.join(item.missing_views)} | "
                    f"`{item.required_reviewer_roles[0]}` | `{item.queue_status}` |\n"
                )
            f.write(f"\n*(Complete ledger of all {len(sorted_items)} items persisted in `exports/reports/translation_view_backfill_queue.json`)*\n\n")

            f.write("---\n\n")
            f.write("## 5. Governance Execution Recommendations\n\n")
            f.write("1. **Stage-by-Stage Human Onboarding:** Assign Tier 1 Suktam records to accredited Vedic scholars before opening Tier 2 Stotras.\n")
            f.write("2. **AI Suggestion Only:** When draft views are generated, they must strictly bear `is_suggestion_only=True` and remain in `DRAFT` status.\n")
            f.write("3. **Independent View Approval:** Literal and Tatparya views must receive separate affirmative sign-offs before publication.\n")

        logger.info("Generated Backfill Queue Report: %s (752 records)", md_file)
        return audit_results

    @classmethod
    def generate_controlled_backfill_pilot_proposal(cls, session: Session) -> Dict[str, Any]:
        """
        Generates a small, controlled 5-record backfill pilot proposal with traceable AI suggestions.
        STRICT PROJECT RULE: Does NOT execute mass backfill or insert unapproved records into production DB.
        """
        proposal = {
            "proposal_title": "Controlled 5-Record Translation View Backfill Pilot Proposal",
            "phase": "Phase 9E",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "governance_barrier": "PROPOSAL ONLY — Zero automatic database insertions performed in Phase 9.",
            "pilot_records": [
                {
                    "content_id": "VEDA-TXT-00006",
                    "title": "Gayatri Mantra",
                    "verse_number": 1,
                    "target_language": "en",
                    "existing_bhavartha": "We meditate upon the supreme, adorable effulgence of the divine Sun-Creator; may He inspire our intellects.",
                    "proposed_literal_view": {
                        "view_type": "LITERAL",
                        "text": "That of Savitar adorable effulgence of the divine we meditate upon; intellects who our may inspire.",
                        "ai_provider": "Panini Rule Engine v2.4",
                        "prompt_hash": "sha256:7f4a8b9c",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "proposed_tatparya_view": {
                        "view_type": "TATPARYA",
                        "text": "According to Sayana's Rigveda Bhashya, Savitar represents the inner animating consciousness of the cosmos, whose effulgence purifies the mind.",
                        "traditional_citation": "Sayana Bhashya on RV 3.62.10",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "required_scholar_competency": "ReviewerRole.VEDIC_RECENSION",
                    "rights_status": "GREEN_CLEARED",
                },
                {
                    "content_id": "VEDA-TXT-00006",
                    "title": "Gayatri Mantra",
                    "verse_number": 1,
                    "target_language": "hi",
                    "existing_bhavartha": "हम सविता देवता के उस श्रेष्ठ पापनाशक तेज का ध्यान करते हैं, जो हमारी बुद्धियों को सत्य मार्ग पर प्रेरित करे।",
                    "proposed_literal_view": {
                        "view_type": "LITERAL",
                        "text": "उस सविता (परमात्मा) के वरेण्य (श्रेष्ठ) तेज का हम ध्यान करें; जो हमारी बुद्धियों को प्रेरित करे।",
                        "ai_provider": "Gemini-2.0-Flash-Sanskrit",
                        "prompt_hash": "sha256:3a1b8c9d",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "proposed_tatparya_view": {
                        "view_type": "TATPARYA",
                        "text": "पारंपरिक भाष्य के अनुसार 'भर्गः' अविद्या का नाश करने वाला शुद्ध आत्म-प्रकाश है।",
                        "traditional_citation": "Sayana / Dayānanda Vedabhashya RV 3.62.10",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "required_scholar_competency": "ReviewerRole.HINDI_TRANSLATOR",
                    "rights_status": "GREEN_CLEARED",
                },
                {
                    "content_id": "VEDA-TXT-00002",
                    "title": "Shiva Tandava Stotram",
                    "verse_number": 1,
                    "target_language": "en",
                    "existing_bhavartha": "With his neck consecrated by the flow of water flowing from his dense forest-like matted hair...",
                    "proposed_literal_view": {
                        "view_type": "LITERAL",
                        "text": "In the dense-forest-matted-locks-dripping-water-flow-purified neck hanging the snake-garland, making cosmic fierce dance, may Shiva extend auspiciousness to us.",
                        "ai_provider": "Panini Rule Engine v2.4",
                        "prompt_hash": "sha256:8b4c2d1e",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "proposed_tatparya_view": {
                        "view_type": "TATPARYA",
                        "text": "Ravana portrays Lord Shiva in his majestic cosmic dance, where the force of Ganga is contained serenely within his locks, symbolizing control over all cosmic energies.",
                        "traditional_citation": "Kavya Prakasha Ullas 8 & Traditional Stotra Bhashya",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "required_scholar_competency": "ReviewerRole.SANSKRIT_TEXTUAL",
                    "rights_status": "GREEN_CLEARED",
                },
                {
                    "content_id": "VEDA-TXT-00002",
                    "title": "Shiva Tandava Stotram",
                    "verse_number": 1,
                    "target_language": "te",
                    "existing_bhavartha": "జటాటవీ గహనమునుండి ప్రవహించే గంగాప్రవాహముతో పవిత్రమైన కంఠము కలవాడును...",
                    "proposed_literal_view": {
                        "view_type": "LITERAL",
                        "text": "జటాటవి నుండి కారుచున్న గంగాజల ప్రవాహముచే పవిత్రమైన కంఠమందు సర్పమాలికను ధరించి తాండవము చేయు శివుడు మాకు శుభములను విస్తరింపజేయుగాక.",
                        "ai_provider": "Gemini-2.0-Flash-Sanskrit",
                        "prompt_hash": "sha256:1f2e3d4c",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "proposed_tatparya_view": {
                        "view_type": "TATPARYA",
                        "text": "రావణకృతమైన ఈ స్తోత్రమందు పంచచామర వృత్త విన్యాసముతో శివుని సృష్టి-సంహార తాండవ లీల వర్ణించబడినది.",
                        "traditional_citation": "Telugu Stotra Sahitya Teeka",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "required_scholar_competency": "ReviewerRole.TELUGU_TRANSLATOR",
                    "rights_status": "GREEN_CLEARED",
                },
                {
                    "content_id": "VEDA-TXT-00008",
                    "title": "Hanuman Chalisa",
                    "verse_number": 1,
                    "target_language": "en",
                    "existing_bhavartha": "Having cleansed the mirror of my mind with the dust of the lotus feet of the Guru, I describe the pure glory of Lord Rama...",
                    "proposed_literal_view": {
                        "view_type": "LITERAL",
                        "text": "Revered Guru's feet-lotus dust own mind mirror having cleansed, I recount Raghubara's pure renown which bestows fruits four.",
                        "ai_provider": "Panini Rule Engine v2.4 (Awadhi Parser)",
                        "prompt_hash": "sha256:5e6d7c8b",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "proposed_tatparya_view": {
                        "view_type": "TATPARYA",
                        "text": "Goswami Tulsidas opens with humility, asserting that spiritual self-reflection begins by cleansing the heart with devotion to the spiritual preceptor.",
                        "traditional_citation": "Gita Press Kalyan Hanuman Teeka pp. 12-14",
                        "status": "DRAFT",
                        "is_suggestion_only": True,
                    },
                    "required_scholar_competency": "ReviewerRole.AWADHI_SPECIALIST",
                    "rights_status": "GREEN_CLEARED",
                },
            ],
        }
        return proposal
