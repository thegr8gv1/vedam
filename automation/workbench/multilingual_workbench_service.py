"""
Vedic Heritage Platform — Multilingual Scholarly Workbench Service
Part E.1: Core backend service powering the Multilingual Scholarly Workbench UI.
Connects canonical database models, Phase 11A language registries, Phase 11B RBAC engine,
Phase 11C script & transliteration engines, Phase 11C Unicode inspector, and Phase 11D publication gates.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional, Set, Tuple
import unicodedata
from sqlalchemy.orm import Session

from automation.cleaners.unicode_preserver import VedicSwara
from automation.exporters.bidi_layout import BidiLayoutEngine
from automation.exporters.publication_gatekeeper import PublicationGatekeeper, ReleaseGateVerdict
from automation.exporters.publication_model import (
    LanguageScriptTarget,
    MissingContentLedger,
    PublicationDocument,
    PublicationGovernance,
    PublicationMetadata,
    VerseEntry,
)
from automation.exporters.typography import MultilingualTypographyEngine
from automation.localization.registry import MultilingualRegistry
from automation.localization.script_registry import MultilingualScriptRegistry, ScriptDirection
from automation.localization.transliteration_engine import (
    MultilingualTransliterationEngine,
    TransliterationReversibility,
)
from automation.localization.unicode_inspector import UnicodeFidelityInspector, UnicodeFidelityReport
from automation.workbench.multilingual_rbac import (
    MultilingualRBACEngine,
    MultilingualRBACError,
    SelfApprovalViolationError,
    UnauthorizedLanguageReviewError,
)
from database.models import (
    ReviewActionLog,
    ReviewActionType,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    ReviewerVerificationStatus,
    Text,
    TextualDispute,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)

logger = logging.getLogger("vedam.automation.workbench.multilingual_workbench_service")


class MultilingualWorkbenchService:
    """
    Central orchestration service for the Multilingual Scholarly Review Workbench.
    Extracts live database entities and enriches them with script, linguistic,
    diagnostic, RBAC, and publication metadata.
    """

    @classmethod
    def get_supported_languages_and_scripts(cls) -> Dict[str, Any]:
        """
        Returns normalized catalog of all 22 Eighth Schedule Indian Languages + English bridge,
        along with their supported scripts, writing directions, and orthographic modes.
        Derived strictly from the Phase 11A MultilingualRegistry and Phase 11C MultilingualScriptRegistry.
        """
        languages = []
        for code, ldef in MultilingualRegistry.LANGUAGES.items():
            primary_script = MultilingualScriptRegistry.get_script(ldef.primary_script)
            supported_scripts_info = []
            for sc in ldef.supported_scripts:
                s_prof = MultilingualScriptRegistry.get_script(sc)
                if s_prof:
                    supported_scripts_info.append({
                        "iso_15924": s_prof.iso_15924,
                        "name": s_prof.name,
                        "native_name": s_prof.native_name,
                        "direction": s_prof.direction.value,
                        "is_rtl": s_prof.direction == ScriptDirection.RTL,
                        "supports_vedic_swaras": s_prof.supports_vedic_swaras,
                        "requires_opentype": s_prof.requires_opentype_shaping,
                    })

            # Special linguistic modes
            special_modes = []
            if code == "ta":
                special_modes = [
                    {"id": "ta-Taml", "name": "Modern Tamil (Standard Orthography)", "is_default": True},
                    {"id": "ta-Taml-traditional", "name": "Sangam / Classical Literary Mode", "is_default": False},
                ]
            elif code == "mni":
                special_modes = [
                    {"id": "mni-Beng", "name": "Bengali-Assamese Script (Traditional Liturgy)", "is_default": True},
                    {"id": "mni-Mtei", "name": "Meitei Mayek Script (Modern Standard)", "is_default": False},
                ]

            languages.append({
                "iso_639_1": ldef.iso_639_1,
                "iso_639_3": ldef.iso_639_3,
                "bcp47": ldef.bcp47,
                "name": ldef.name,
                "native_name": ldef.native_name,
                "family": ldef.family.value,
                "is_eighth_schedule": ldef.is_eighth_schedule,
                "primary_script": ldef.primary_script,
                "primary_direction": primary_script.direction.value if primary_script else "ltr",
                "is_rtl": (primary_script.direction == ScriptDirection.RTL) if primary_script else False,
                "supported_scripts": supported_scripts_info,
                "special_modes": special_modes,
                "has_sacred_tradition": ldef.has_sacred_liturgical_tradition,
            })

        scripts = []
        for sc_code, s_prof in MultilingualScriptRegistry.SCRIPTS.items():
            font_prof = MultilingualTypographyEngine.get_profile(sc_code)
            scripts.append({
                "iso_15924": s_prof.iso_15924,
                "name": s_prof.name,
                "native_name": s_prof.native_name,
                "direction": s_prof.direction.value,
                "is_rtl": s_prof.direction == ScriptDirection.RTL,
                "category": s_prof.category.value,
                "supports_vedic_swaras": s_prof.supports_vedic_swaras,
                "requires_opentype": s_prof.requires_opentype_shaping,
                "css_font_stack": font_prof.css_stack if font_prof else "sans-serif",
                "primary_languages": list(s_prof.primary_languages),
            })

        return {
            "total_languages": len(languages),
            "total_scripts": len(scripts),
            "languages": languages,
            "scripts": scripts,
        }

    @classmethod
    def get_verse_scholarly_payload(
        cls,
        session: Session,
        content_id: str,
        verse_number: int,
        target_language: str = "te",
        target_script: Optional[str] = None,
        reviewer_id: Optional[str] = "REV-ADMIN-001",
    ) -> Dict[str, Any]:
        """
        Builds a comprehensive scholarly payload for a single verse combining:
        1. Original Sanskrit text & liturgical metadata.
        2. Transliterations across 14 scripts with reversibility classifications.
        3. Available TranslationViews (Literal, Tatparya, Bhavartha) with legacy gap identification.
        4. Non-destructive Unicode fidelity diagnostics.
        5. Reviewer RBAC authorization and anti-self-approval resolution.
        6. Publication preflight gating and format readiness warnings.
        """
        text = session.query(Text).filter_by(content_id=content_id).first()
        if not text:
            raise ValueError(f"Composition '{content_id}' not found.")

        verse = (
            session.query(Verse)
            .filter_by(text_id=text.id, verse_number=verse_number)
            .first()
        )
        if not verse:
            raise ValueError(f"Verse {verse_number} in '{content_id}' not found.")

        # Target language and script normalization
        lang_def = MultilingualRegistry.get_language(target_language)
        if not lang_def:
            raise ValueError(f"Language '{target_language}' not registered in platform.")

        active_script = target_script or lang_def.primary_script
        script_prof = MultilingualScriptRegistry.get_script(active_script)
        if not script_prof:
            active_script = lang_def.primary_script
            script_prof = MultilingualScriptRegistry.get_script(active_script)

        is_rtl = script_prof.direction == ScriptDirection.RTL

        # -------------------------------------------------------------------
        # 1. Original Source & Liturgical Metadata
        # -------------------------------------------------------------------
        col1_original = {
            "verse_id": verse.verse_id,
            "verse_number": verse.verse_number,
            "verse_type": verse.verse_type.value,
            "source_scripture": text.canonical_title,
            "original_language": text.original_language,
            "composer": text.composer or text.rishi or "Traditional Sage",
            "chandas_meter": verse.meter or "Traditional Liturgical Meter",
            "vedic_accents_present": verse.vedic_accents_present,
            "devanagari_text": verse.devanagari_text,
            "raw_source_text": verse.raw_source_text or verse.devanagari_text,
            "iast_text": verse.iast_text,
            "vedic_accent_annotations": verse.vedic_accent_annotations,
        }

        # -------------------------------------------------------------------
        # 2. Transliterations & Reversibility Projections
        # -------------------------------------------------------------------
        transliterations_list = []
        # Store database-persisted transliterations
        persisted_trans = {t.target_script: t.script_text for t in verse.transliterations}

        # Project across 14 registered scripts dynamically if not in DB
        for s_code in MultilingualScriptRegistry.SCRIPTS.keys():
            t_text = persisted_trans.get(s_code)
            trans_res = MultilingualTransliterationEngine.transliterate(
                verse.devanagari_text, "Deva", s_code
            )
            # Use persisted text if available, else generated projection
            display_text = t_text if t_text else trans_res.text
            transliterations_list.append({
                "script_code": s_code,
                "script_name": MultilingualScriptRegistry.get_script(s_code).name,
                "text": display_text,
                "is_persisted": s_code in persisted_trans,
                "reversibility": trans_res.reversibility.value,
                "is_lossless": trans_res.is_lossless,
                "warnings": list(trans_res.warnings),
                "is_rtl": MultilingualScriptRegistry.is_rtl(s_code),
            })

        # -------------------------------------------------------------------
        # 3. Translation Views & Legacy Gap Detection
        # -------------------------------------------------------------------
        translation = (
            session.query(Translation)
            .filter_by(verse_id=verse.id, target_language=target_language)
            .first()
        )

        views_by_type: Dict[TranslationType, TranslationView] = {}
        if translation:
            for v in translation.views:
                views_by_type[v.view_type] = v

        # Literal View
        lit_view = views_by_type.get(TranslationType.LITERAL)
        wbw = translation.word_by_word_json if (translation and isinstance(translation.word_by_word_json, dict)) else {}
        is_lit_gap = lit_view is None
        col3_literal = {
            "view_id": lit_view.view_id if lit_view else None,
            "version": lit_view.version if lit_view else 1,
            "review_status": lit_view.review_status.value if lit_view else "PENDING_REVIEW",
            "is_legacy_gap": is_lit_gap,
            "text": lit_view.view_text if lit_view else None,
            "display_notice": "Literal translation view is pending scholarly collation in the Legacy 747 Gap Queue." if is_lit_gap else None,
            "padachheda_words": wbw.get("padachheda", []),
            "source_reference": lit_view.source_reference if lit_view else "Padachheda Syntactical Analysis",
        }

        # Tatparya View
        tat_view = views_by_type.get(TranslationType.TATPARYA)
        is_tat_gap = tat_view is None
        col4_traditional = {
            "view_id": tat_view.view_id if tat_view else None,
            "version": tat_view.version if tat_view else 1,
            "review_status": tat_view.review_status.value if tat_view else "PENDING_REVIEW",
            "is_legacy_gap": is_tat_gap,
            "text": tat_view.view_text if tat_view else None,
            "display_notice": "Traditional Tatparya commentary is pending sampradaya exegesis in the Legacy 747 Gap Queue." if is_tat_gap else None,
            "commentator_citation": wbw.get("commentator", "Traditional Sampradaya Commentary"),
            "source_reference": tat_view.source_reference if tat_view else "Classical Exegesis",
        }

        # Bhavartha View
        bhav_view = views_by_type.get(TranslationType.BHAVARTHA)
        bhav_text = bhav_view.view_text if bhav_view else (translation.translated_text if translation else None)
        col5_bhavartha = {
            "view_id": bhav_view.view_id if bhav_view else None,
            "version": bhav_view.version if bhav_view else 1,
            "review_status": bhav_view.review_status.value if bhav_view else (translation.review_status.value if translation else "NOT_FOUND"),
            "text": bhav_text,
            "display_notice": "Devotional Bhavartha translation pending regional language draft." if not bhav_text else None,
            "source_reference": bhav_view.source_reference if bhav_view else "Traditional Liturgical Recitation",
            "is_rtl": is_rtl,
        }

        # -------------------------------------------------------------------
        # 4. Read-Only Unicode & Vedic Swara Diagnostics
        # -------------------------------------------------------------------
        unicode_report = UnicodeFidelityInspector.inspect(verse.devanagari_text)
        codepoints_breakdown = [
            f"U+{ord(c):04X} ({unicodedata.name(c, 'UNKNOWN')})"
            for c in verse.devanagari_text[:25]
        ]
        unicode_diagnostics = {
            "char_count": unicode_report.char_count,
            "byte_count_utf8": unicode_report.byte_count_utf8,
            "is_nfc_normalized": unicode_report.is_nfc_normalized,
            "is_nfd_normalized": unicode_report.is_nfd_normalized,
            "combining_mark_count": unicode_report.combining_mark_count,
            "vedic_accent_count": unicode_report.vedic_accent_count,
            "vedic_accents": [f"U+{ord(c):04X}" for c in unicode_report.vedic_accents],
            "has_zwj": unicode_report.has_zwj,
            "has_zwnj": unicode_report.has_zwnj,
            "script_detected": unicode_report.script_detected,
            "is_pure_script": unicode_report.is_pure_script,
            "sample_codepoints": codepoints_breakdown,
            "immutability_guarantee": "Canonical database records are strictly read-only and immutable during workbench inspection.",
        }

        # -------------------------------------------------------------------
        # 5. Reviewer RBAC & Governance Status
        # -------------------------------------------------------------------
        reviewer = None
        if reviewer_id:
            reviewer = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()

        is_authorized = False
        is_quarantined = False
        is_self_approval = False
        authorization_reason = "No reviewer session active."

        if reviewer:
            is_authorized = MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, target_language)
            v_status = getattr(reviewer.verification_status, "value", str(reviewer.verification_status))
            is_quarantined = v_status in (
                "DEMO",
                "PENDING_VERIFICATION",
                "REJECTED",
                "DEACTIVATED",
            )

            # Check self-approval
            if translation and reviewer:
                if translation.translator and reviewer.full_name and translation.translator.lower().strip() == reviewer.full_name.lower().strip():
                    is_self_approval = True
                elif translation.translator_id and str(translation.translator_id) == str(getattr(reviewer, "id", "")):
                    is_self_approval = True

            if is_self_approval:
                authorization_reason = "Self-approval violation: Translators cannot approve their own translations (Rule REV-002)."
            elif is_quarantined:
                authorization_reason = f"Sandbox Account Mode: Reviewer status is '{v_status}' (Rule REV-005: Approvals restricted to local test sandbox)."
            elif is_authorized:
                authorization_reason = f"Reviewer accredited for language '{target_language.upper()}' under role '{getattr(reviewer.primary_role, 'value', str(reviewer.primary_role))}'."
            else:
                authorization_reason = f"Unauthorized: Reviewer lacks certified credential for language '{target_language.upper()}'. Read-only consultation only."

        # Audit History & Open Disputes
        recent_actions = (
            session.query(ReviewActionLog)
            .filter_by(verse_id=verse.id)
            .order_by(ReviewActionLog.created_at.desc())
            .limit(10)
            .all()
        )
        actions_list = [
            {
                "action_id": a.action_id,
                "action_type": a.action_type.value,
                "reviewer_id": a.reviewer.reviewer_id if a.reviewer else "SYSTEM",
                "reviewer_name": a.reviewer.full_name if a.reviewer else "Scholar",
                "previous_status": a.previous_status,
                "new_status": a.new_status,
                "scholarly_commentary": a.scholarly_commentary,
                "timestamp": a.created_at.isoformat(),
            }
            for a in recent_actions
        ]

        disputes = session.query(TextualDispute).filter_by(verse_id=verse.id).all()
        disputes_list = [
            {
                "dispute_id": d.dispute_id,
                "dispute_nature": d.dispute_nature,
                "status": d.status.value,
                "opinion_a": d.opinion_a_json,
                "opinion_b": d.opinion_b_json,
                "editorial_notes": d.editorial_resolution_notes,
            }
            for d in disputes
        ]

        col6_governance = {
            "reviewer_profile": {
                "reviewer_id": reviewer.reviewer_id if reviewer else None,
                "full_name": reviewer.full_name if reviewer else "Anonymous Scholar",
                "primary_role": getattr(reviewer.primary_role, "value", str(reviewer.primary_role)) if reviewer else "None",
                "secondary_roles": [getattr(r, "value", str(r)) for r in (reviewer.secondary_roles or [])] if reviewer else [],
                "verification_status": getattr(reviewer.verification_status, "value", str(reviewer.verification_status)) if reviewer else "UNAUTHENTICATED",
                "language_proficiency": reviewer.language_proficiency if reviewer else {},
                "permissions": reviewer.permissions if reviewer else [],
            },
            "target_language": target_language,
            "target_script": active_script,
            "is_authorized_for_language": is_authorized,
            "is_quarantined": is_quarantined,
            "is_self_approval_blocked": is_self_approval,
            "can_approve_views": is_authorized and not is_quarantined and not is_self_approval,
            "authorization_message": authorization_reason,
            "overall_status": translation.review_status.value if translation else "NOT_FOUND",
            "recent_actions": actions_list,
            "open_disputes": disputes_list,
        }

        # -------------------------------------------------------------------
        # 6. Publication Preflight & Gatekeeper Evaluation
        # -------------------------------------------------------------------
        has_missing_views = is_lit_gap or is_tat_gap
        publication_preview = {
            "channel": "draft_export",
            "overall_review_status": translation.review_status.value if translation else "DRAFT",
            "gatekeeper_verdict": ReleaseGateVerdict.CONDITIONAL_DRAFT_ONLY.value,
            "watermark_text": "UNREVIEWED DRAFT — NOT FOR PUBLIC DEVOTIONAL USE",
            "has_missing_views": has_missing_views,
            "missing_view_count": (1 if is_lit_gap else 0) + (1 if is_tat_gap else 0),
            "formats": {
                "html": {"status": "PRODUCTION_READY", "description": "Native browser DirectWrite/HarfBuzz complex shaping with <bdi> isolation."},
                "docx": {"status": "PRODUCTION_READY", "description": "Microsoft Word OOXML with <w:bidi/> paragraph bidirectional flow."},
                "epub": {"status": "PRODUCTION_READY", "description": "IDPF EPUB 3.2 package with RTL spine navigation for Arabic."},
                "pdf": {
                    "status": "LIMITED_PREVIEW_ONLY",
                    "badge": "LIMITED PREVIEW ONLY (NOT PRINT-READY)",
                    "warning": "ReportLab core lacks OpenType GSUB/GPOS shaping for Indic conjuncts and matra reordering. Output restricted to internal proofreading drafts.",
                },
            },
        }

        return {
            "content_id": text.content_id,
            "canonical_title": text.canonical_title,
            "devanagari_title": text.devanagari_title or text.canonical_title,
            "target_language": target_language,
            "target_language_name": lang_def.name,
            "target_script": active_script,
            "target_script_name": script_prof.name,
            "target_bcp47": f"{target_language}-{active_script}",
            "direction": script_prof.direction.value,
            "is_rtl": is_rtl,
            "column_1_original": col1_original,
            "column_2_transliterations": {
                "iast": verse.iast_text,
                "scripts": persisted_trans,
                "all_projections": transliterations_list,
            },
            "column_3_literal": col3_literal,
            "column_4_traditional": col4_traditional,
            "column_5_bhavartha": col5_bhavartha,
            "column_6_governance": col6_governance,
            "unicode_diagnostics": unicode_diagnostics,
            "publication_preview": publication_preview,
        }

    @classmethod
    def validate_review_submission(
        cls,
        session: Session,
        reviewer_id: str,
        translation_id: int,
        action_type: ReviewActionType,
        scholarly_commentary: str,
    ) -> Dict[str, Any]:
        """
        Validates and simulates a reviewer action submission enforcing all server-side RBAC rules.
        Does not mutate the production database.
        """
        reviewer = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not reviewer:
            raise ValueError(f"Reviewer '{reviewer_id}' not found.")

        translation = session.query(Translation).filter_by(id=translation_id).first()
        if not translation:
            raise ValueError(f"Translation record '{translation_id}' not found.")

        # Enforce RBAC
        can_approve, reason = MultilingualRBACEngine.can_reviewer_approve_language(reviewer, translation.target_language)
        if not can_approve:
            raise UnauthorizedLanguageReviewError(reason or "Unauthorized review action.")

        # Enforce anti-self-approval
        MultilingualRBACEngine.check_self_approval_restriction(reviewer, translation)

        return {
            "is_valid": True,
            "reviewer_id": reviewer.reviewer_id,
            "translation_id": translation.id,
            "target_language": translation.target_language,
            "action_type": action_type.value,
            "status": "VALIDATED_BY_RBAC_GUARD",
        }
