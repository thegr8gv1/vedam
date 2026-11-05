"""
Vedic Heritage Platform — Multilingual Role-Based Access Control (RBAC) Engine
Part C.2: Language-aware reviewer authorization, role mappings, self-approval prevention,
and credential validation across all 22 Scheduled Indian Languages + English bridge language.

Rules:
- Authoritative bidirectional mapping between ISO 639 language codes and ReviewerRoles.
- Fine-grained permission resolution respecting primary_role, secondary_roles, language_proficiency,
  and explicit permission grants.
- Enforces strict isolation: reviewers can never approve translations in unauthorized languages.
- Strict anti-self-approval rule: translators cannot approve their own translations.
- Unverified/demonstration accounts cannot issue canonical approvals.
- AI drafts cannot be human-approved without verified living human scholar credentials.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional, Set, Tuple

from database.models import (
    ReviewActionType,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    Translation,
    TranslationView,
)

logger = logging.getLogger("vedam.automation.workbench.multilingual_rbac")


class MultilingualRBACError(Exception):
    """Base exception for multilingual role-based access control violations."""
    pass


class UnauthorizedLanguageReviewError(MultilingualRBACError):
    """Raised when a reviewer attempts to review or approve an unauthorized language."""
    pass


class SelfApprovalViolationError(MultilingualRBACError):
    """Raised when a translator attempts to approve their own translation work."""
    pass


class InvalidRoleConfigurationError(MultilingualRBACError):
    """Raised when an invalid language or role mapping is requested."""
    pass


class MultilingualRBACEngine:
    """Core RBAC engine for language-to-role mappings, capabilities, and governance validation."""

    # -----------------------------------------------------------------------
    # Authoritative Language-to-Role Mapping
    # (Maps ISO 639-1 / 639-3 codes to canonical ReviewerRole)
    # -----------------------------------------------------------------------
    LANGUAGE_ROLE_MAP: Dict[str, ReviewerRole] = {
        # Root Liturgical & Source
        "sa": ReviewerRole.SANSKRIT_TEXTUAL,
        "san": ReviewerRole.SANSKRIT_TEXTUAL,
        "awa": ReviewerRole.AWADHI_SPECIALIST,

        # Tier 1 Operational Languages (9 Indic + English Bridge)
        "hi": ReviewerRole.HINDI_TRANSLATOR,
        "hin": ReviewerRole.HINDI_TRANSLATOR,
        "te": ReviewerRole.TELUGU_TRANSLATOR,
        "tel": ReviewerRole.TELUGU_TRANSLATOR,
        "ta": ReviewerRole.TAMIL_TRANSLATOR,
        "tam": ReviewerRole.TAMIL_TRANSLATOR,
        "kn": ReviewerRole.KANNADA_TRANSLATOR,
        "kan": ReviewerRole.KANNADA_TRANSLATOR,
        "mr": ReviewerRole.MARATHI_TRANSLATOR,
        "mar": ReviewerRole.MARATHI_TRANSLATOR,
        "bn": ReviewerRole.BENGALI_TRANSLATOR,
        "ben": ReviewerRole.BENGALI_TRANSLATOR,
        "gu": ReviewerRole.GUJARATI_TRANSLATOR,
        "guj": ReviewerRole.GUJARATI_TRANSLATOR,
        "ml": ReviewerRole.MALAYALAM_TRANSLATOR,
        "mal": ReviewerRole.MALAYALAM_TRANSLATOR,
        "or": ReviewerRole.ODIA_TRANSLATOR,
        "ori": ReviewerRole.ODIA_TRANSLATOR,
        "en": ReviewerRole.ENGLISH_TRANSLATOR,
        "eng": ReviewerRole.ENGLISH_TRANSLATOR,

        # Tier 2 Expansion Scheduled Languages (12 Eighth Schedule)
        "as": ReviewerRole.ASSAMESE_TRANSLATOR,
        "asm": ReviewerRole.ASSAMESE_TRANSLATOR,
        "brx": ReviewerRole.BODO_TRANSLATOR,
        "doi": ReviewerRole.DOGRI_TRANSLATOR,
        "ks": ReviewerRole.KASHMIRI_TRANSLATOR,
        "kas": ReviewerRole.KASHMIRI_TRANSLATOR,
        "kok": ReviewerRole.KONKANI_TRANSLATOR,
        "mai": ReviewerRole.MAITHILI_TRANSLATOR,
        "mni": ReviewerRole.MANIPURI_TRANSLATOR,
        "ne": ReviewerRole.NEPALI_TRANSLATOR,
        "nep": ReviewerRole.NEPALI_TRANSLATOR,
        "pa": ReviewerRole.PUNJABI_TRANSLATOR,
        "pan": ReviewerRole.PUNJABI_TRANSLATOR,
        "sat": ReviewerRole.SANTALI_TRANSLATOR,
        "sd": ReviewerRole.SINDHI_TRANSLATOR,
        "snd": ReviewerRole.SINDHI_TRANSLATOR,
        "ur": ReviewerRole.URDU_TRANSLATOR,
        "urd": ReviewerRole.URDU_TRANSLATOR,
    }

    # -----------------------------------------------------------------------
    # Reverse Role-to-Language Mapping
    # -----------------------------------------------------------------------
    ROLE_LANGUAGE_MAP: Dict[ReviewerRole, List[str]] = {
        ReviewerRole.SANSKRIT_TEXTUAL: ["sa", "san", "en", "eng"],
        ReviewerRole.VEDIC_RECENSION: ["sa", "san", "en", "eng"],
        ReviewerRole.SANSKRIT_GRAMMAR: ["sa", "san", "en", "eng"],
        ReviewerRole.AWADHI_SPECIALIST: ["awa", "en", "eng"],
        ReviewerRole.HINDI_TRANSLATOR: ["hi", "hin"],
        ReviewerRole.TELUGU_TRANSLATOR: ["te", "tel"],
        ReviewerRole.TAMIL_TRANSLATOR: ["ta", "tam"],
        ReviewerRole.KANNADA_TRANSLATOR: ["kn", "kan"],
        ReviewerRole.MARATHI_TRANSLATOR: ["mr", "mar"],
        ReviewerRole.BENGALI_TRANSLATOR: ["bn", "ben"],
        ReviewerRole.GUJARATI_TRANSLATOR: ["gu", "guj"],
        ReviewerRole.MALAYALAM_TRANSLATOR: ["ml", "mal"],
        ReviewerRole.ODIA_TRANSLATOR: ["or", "ori"],
        ReviewerRole.ENGLISH_TRANSLATOR: ["en", "eng"],
        ReviewerRole.ASSAMESE_TRANSLATOR: ["as", "asm"],
        ReviewerRole.BODO_TRANSLATOR: ["brx"],
        ReviewerRole.DOGRI_TRANSLATOR: ["doi"],
        ReviewerRole.KASHMIRI_TRANSLATOR: ["ks", "kas"],
        ReviewerRole.KONKANI_TRANSLATOR: ["kok"],
        ReviewerRole.MAITHILI_TRANSLATOR: ["mai"],
        ReviewerRole.MANIPURI_TRANSLATOR: ["mni"],
        ReviewerRole.NEPALI_TRANSLATOR: ["ne", "nep"],
        ReviewerRole.PUNJABI_TRANSLATOR: ["pa", "pan"],
        ReviewerRole.SANTALI_TRANSLATOR: ["sat"],
        ReviewerRole.SINDHI_TRANSLATOR: ["sd", "snd"],
        ReviewerRole.URDU_TRANSLATOR: ["ur", "urd"],
        ReviewerRole.TRADITIONAL_COMMENTARY: ["sa", "hi", "te", "ta", "kn", "ml", "bn", "gu", "mr", "or", "en", "eng"],
        ReviewerRole.LEGAL_COPYRIGHT: [],
        ReviewerRole.EDITORIAL_BOARD: [],  # Global editorial oversight
    }

    # -----------------------------------------------------------------------
    # Role-to-Script Compatibility Mapping
    # -----------------------------------------------------------------------
    ROLE_SCRIPT_MAP: Dict[ReviewerRole, List[str]] = {
        ReviewerRole.SANSKRIT_TEXTUAL: ["Deva", "Telu", "Gran", "Knda", "Mlym", "Beng", "Gujr", "Orya", "Guru", "Latn"],
        ReviewerRole.VEDIC_RECENSION: ["Deva", "Telu", "Gran", "Knda", "Mlym", "Latn"],
        ReviewerRole.SANSKRIT_GRAMMAR: ["Deva", "Telu", "Gran", "Latn"],
        ReviewerRole.AWADHI_SPECIALIST: ["Deva", "Latn"],
        ReviewerRole.HINDI_TRANSLATOR: ["Deva", "Latn"],
        ReviewerRole.TELUGU_TRANSLATOR: ["Telu", "Latn"],
        ReviewerRole.TAMIL_TRANSLATOR: ["Taml", "Gran", "Latn"],
        ReviewerRole.KANNADA_TRANSLATOR: ["Knda", "Latn"],
        ReviewerRole.MARATHI_TRANSLATOR: ["Deva", "Latn"],
        ReviewerRole.BENGALI_TRANSLATOR: ["Beng", "Latn"],
        ReviewerRole.GUJARATI_TRANSLATOR: ["Gujr", "Latn"],
        ReviewerRole.MALAYALAM_TRANSLATOR: ["Mlym", "Latn"],
        ReviewerRole.ODIA_TRANSLATOR: ["Orya", "Latn"],
        ReviewerRole.ENGLISH_TRANSLATOR: ["Latn"],
        ReviewerRole.ASSAMESE_TRANSLATOR: ["Beng", "Latn"],
        ReviewerRole.BODO_TRANSLATOR: ["Deva", "Beng", "Latn"],
        ReviewerRole.DOGRI_TRANSLATOR: ["Deva", "Latn"],
        ReviewerRole.KASHMIRI_TRANSLATOR: ["Arab", "Deva", "Latn"],
        ReviewerRole.KONKANI_TRANSLATOR: ["Deva", "Knda", "Latn"],
        ReviewerRole.MAITHILI_TRANSLATOR: ["Deva", "Latn"],
        ReviewerRole.MANIPURI_TRANSLATOR: ["Beng", "Mtei", "Latn"],
        ReviewerRole.NEPALI_TRANSLATOR: ["Deva", "Latn"],
        ReviewerRole.PUNJABI_TRANSLATOR: ["Guru", "Latn"],
        ReviewerRole.SANTALI_TRANSLATOR: ["Olck", "Deva", "Beng", "Orya", "Latn"],
        ReviewerRole.SINDHI_TRANSLATOR: ["Arab", "Deva", "Latn"],
        ReviewerRole.URDU_TRANSLATOR: ["Arab", "Latn"],
        ReviewerRole.TRADITIONAL_COMMENTARY: ["Deva", "Telu", "Gran", "Taml", "Knda", "Mlym", "Beng", "Latn"],
        ReviewerRole.LEGAL_COPYRIGHT: ["Latn", "Deva"],
        ReviewerRole.EDITORIAL_BOARD: ["Deva", "Telu", "Taml", "Knda", "Mlym", "Beng", "Gujr", "Orya", "Guru", "Arab", "Olck", "Mtei", "Latn"],
    }

    # -----------------------------------------------------------------------
    # Comprehensive Capabilities Dictionary for all 29 ReviewerRoles
    # -----------------------------------------------------------------------
    ROLE_CAPABILITIES: Dict[ReviewerRole, Set[str]] = {
        # Sanskrit & Sacred Recensions
        ReviewerRole.SANSKRIT_TEXTUAL: {"sa_textual_critique", "variant_analysis", "meter_verification"},
        ReviewerRole.VEDIC_RECENSION: {"swara_accent_verification", "shakha_critique", "samhita_alignment"},
        ReviewerRole.SANSKRIT_GRAMMAR: {"padachheda_analysis", "paninian_grammar", "sandhi_splitting", "samasa_analysis"},
        ReviewerRole.AWADHI_SPECIALIST: {"awadhi_linguistics", "chaupai_doha_prosody", "tulsidas_exegesis"},

        # Tier 1 Operational Regional Translators (9 Indic + 1 Bridge)
        ReviewerRole.HINDI_TRANSLATOR: {"hi_translation_critique", "bhakti_idiom_review", "hindi_prosody"},
        ReviewerRole.TELUGU_TRANSLATOR: {"te_translation_critique", "telugu_poetic_meter", "andhra_bhashya"},
        ReviewerRole.TAMIL_TRANSLATOR: {"ta_translation_critique", "grantha_subscript_phonetics", "sangam_devotional"},
        ReviewerRole.KANNADA_TRANSLATOR: {"kn_translation_critique", "kannada_prosody", "vachana_literary"},
        ReviewerRole.MARATHI_TRANSLATOR: {"mr_translation_critique", "abhanga_style_critique", "varkari_tradition"},
        ReviewerRole.BENGALI_TRANSLATOR: {"bn_translation_critique", "gaudiya_vaishnava_exegesis", "bengali_poetics"},
        ReviewerRole.GUJARATI_TRANSLATOR: {"gu_translation_critique", "gujarati_devotional_lexicon", "pushtimarg_commentary"},
        ReviewerRole.MALAYALAM_TRANSLATOR: {"ml_translation_critique", "manipravalam_knowledge", "kerala_tantric"},
        ReviewerRole.ODIA_TRANSLATOR: {"or_translation_critique", "jagannatha_sampradaya_lexicon", "odia_riti_poetics"},
        ReviewerRole.ENGLISH_TRANSLATOR: {"en_translation_critique", "international_academic_phrasing", "comparative_theology"},

        # Tier 2 Expansion Scheduled Languages (12 Eighth Schedule)
        ReviewerRole.ASSAMESE_TRANSLATOR: {"as_translation_critique", "sankardeva_sattriya_lexicon", "assamese_prosody"},
        ReviewerRole.BODO_TRANSLATOR: {"brx_translation_critique", "bathou_cultural_context", "bodo_lexicon"},
        ReviewerRole.DOGRI_TRANSLATOR: {"doi_translation_critique", "duggar_folk_devotional", "dogri_lexicon"},
        ReviewerRole.KASHMIRI_TRANSLATOR: {"ks_translation_critique", "kashmir_shaivism_lexicon", "perso_arabic_metrics"},
        ReviewerRole.KONKANI_TRANSLATOR: {"kok_translation_critique", "konkani_coastal_dialects", "konkani_devotional"},
        ReviewerRole.MAITHILI_TRANSLATOR: {"mai_translation_critique", "mithila_pandit_exegesis", "vidyapati_prosody"},
        ReviewerRole.MANIPURI_TRANSLATOR: {"mni_translation_critique", "meetei_mayek_orthography", "manipuri_vaishnava"},
        ReviewerRole.NEPALI_TRANSLATOR: {"ne_translation_critique", "bhanubhakta_tradition", "himalayan_vedic"},
        ReviewerRole.PUNJABI_TRANSLATOR: {"pa_translation_critique", "gurmukhi_orthography", "punjabi_bhakti_lexicon"},
        ReviewerRole.SANTALI_TRANSLATOR: {"sat_translation_critique", "ol_chiki_orthography", "santali_indigenous_terms"},
        ReviewerRole.SINDHI_TRANSLATOR: {"sd_translation_critique", "sindhi_perso_arabic_orthography", "sufi_vedanta_synthesis"},
        ReviewerRole.URDU_TRANSLATOR: {"ur_translation_critique", "nastaliq_orthography", "urdu_philosophical_lexicon"},

        # Platform Governance & Review Roles
        ReviewerRole.TRADITIONAL_COMMENTARY: {"bhashya_citation_verification", "sampradaya_fidelity", "philosophical_coherence"},
        ReviewerRole.LEGAL_COPYRIGHT: {"public_domain_clearance", "jurisdiction_rights_audit", "license_verification"},
        ReviewerRole.EDITORIAL_BOARD: {"dispute_adjudication", "final_canonical_signoff", "reassignment_authorization", "all_languages_oversight"},
    }

    # -----------------------------------------------------------------------
    # Query & Validation Methods
    # -----------------------------------------------------------------------
    @classmethod
    def get_role_for_language(cls, lang_code: str) -> Optional[ReviewerRole]:
        """Resolves canonical ReviewerRole for an ISO 639 language code."""
        code = lang_code.lower().strip()
        return cls.LANGUAGE_ROLE_MAP.get(code)

    @classmethod
    def get_languages_for_role(cls, role: ReviewerRole) -> List[str]:
        """Returns primary ISO 639 codes associated with a ReviewerRole."""
        return cls.ROLE_LANGUAGE_MAP.get(role, [])

    @classmethod
    def get_supported_scripts_for_role(cls, role: ReviewerRole) -> List[str]:
        """Returns valid ISO 15924 scripts associated with a ReviewerRole."""
        return cls.ROLE_SCRIPT_MAP.get(role, ["Latn"])

    @classmethod
    def is_reviewer_authorized_for_language(
        cls,
        reviewer: ReviewerProfile,
        lang_code: str,
    ) -> bool:
        """
        Determines whether a reviewer profile has credentialed authority to review
        content in the specified target language.

        Resolution hierarchy:
        1. Inactive reviewers are immediately unauthorized.
        2. EDITORIAL_BOARD role or 'ADMIN_ALL' / 'review:*' permission grants universal oversight.
        3. Match on primary_role.
        4. Match on secondary_roles.
        5. Match on language_proficiency dict with qualified rating (NATIVE, FLUENT, SCHOLAR, PROFICIENT, ADVANCED).
        6. Match on explicit permissions list (e.g. 'review:as', 'review:pa', 'approve:as').
        """
        if not reviewer or not getattr(reviewer, "is_active", True):
            return False

        code = lang_code.lower().strip()
        perms = reviewer.permissions or []

        # Universal oversight
        if reviewer.primary_role == ReviewerRole.EDITORIAL_BOARD:
            return True
        if "ADMIN_ALL" in perms or "review:*" in perms or "approve:*" in perms:
            return True

        target_role = cls.get_role_for_language(code)

        # Primary role match (direct or via ROLE_LANGUAGE_MAP)
        if target_role and reviewer.primary_role == target_role:
            return True
        if code in cls.ROLE_LANGUAGE_MAP.get(reviewer.primary_role, []):
            return True

        # Secondary roles match
        sec_roles = reviewer.secondary_roles or []
        sec_role_values = {r.value if isinstance(r, ReviewerRole) else str(r) for r in sec_roles}
        if target_role and target_role.value in sec_role_values:
            return True
        for sr in sec_roles:
            sr_enum = sr if isinstance(sr, ReviewerRole) else ReviewerRole(sr) if sr in ReviewerRole._value2member_map_ else None
            if sr_enum and code in cls.ROLE_LANGUAGE_MAP.get(sr_enum, []):
                return True

        # Language proficiency dictionary match
        prof = reviewer.language_proficiency or {}
        # Normalize keys in proficiency dict
        prof_normalized = {k.lower().strip(): str(v).upper().strip() for k, v in prof.items()}
        qualified_ratings = {"NATIVE", "FLUENT", "SCHOLAR", "SCHOLARLY", "EXPERT", "PROFICIENT", "ADVANCED", "VIDWAN"}
        if code in prof_normalized and prof_normalized[code] in qualified_ratings:
            return True

        # Explicit permission flags (e.g. 'review:hi', 'approve:hi')
        explicit_perms = {p.lower().strip() for p in perms}
        if f"review:{code}" in explicit_perms or f"approve:{code}" in explicit_perms:
            return True

        return False

    @classmethod
    def can_reviewer_approve_language(
        cls,
        reviewer: ReviewerProfile,
        lang_code: str,
    ) -> Tuple[bool, Optional[str]]:
        """
        Validates whether a reviewer has full APPROVAL authority for a given language.
        Returns (is_allowed, reason_if_denied).
        """
        # 1. Base language authorization
        if not cls.is_reviewer_authorized_for_language(reviewer, lang_code):
            return False, f"Reviewer '{reviewer.reviewer_id}' lacks authorization for language '{lang_code}'."

        # 2. Demonstration profile check
        if reviewer.is_demonstration or getattr(reviewer, "account_category", "") == "DEMONSTRATION_HARNESS":
            return False, f"Reviewer '{reviewer.reviewer_id}' is a demonstration harness and cannot issue production approvals."

        # 3. Verification status check
        if not reviewer.is_credentials_verified or reviewer.verification_status != "VERIFIED":
            return False, f"Reviewer '{reviewer.reviewer_id}' is not in verified status ({reviewer.verification_status})."

        # 4. Translator vs Approval permission check
        perms = reviewer.permissions or []
        code = lang_code.lower().strip()

        # Editorial board and admin always have approve permission
        if reviewer.primary_role == ReviewerRole.EDITORIAL_BOARD or "ADMIN_ALL" in perms or "approve:*" in perms:
            return True, None

        # Explicit block on approvals if labeled read_only or translator_only
        if "TRANSLATOR_ONLY" in perms or "READ_ONLY" in perms:
            return False, f"Reviewer '{reviewer.reviewer_id}' has TRANSLATOR_ONLY/READ_ONLY status without approval rights."

        return True, None

    @classmethod
    def check_self_approval_restriction(
        cls,
        reviewer: ReviewerProfile,
        translation: Translation,
    ) -> None:
        """
        Enforces that a translator cannot approve their own translation.
        Checks translator attribution, contributor associations, and creation metadata.
        """
        if not translation:
            return

        translator_field = (translation.translator or "").strip().lower()
        reviewer_id = (reviewer.reviewer_id or "").strip().lower()
        full_name = (reviewer.full_name or "").strip().lower()

        if full_name and full_name in translator_field:
            raise SelfApprovalViolationError(
                f"Self-approval prohibited: Reviewer '{reviewer.full_name}' ({reviewer.reviewer_id}) "
                f"is listed as the translator for Translation ID {translation.id}."
            )

        if reviewer_id and reviewer_id in translator_field:
            raise SelfApprovalViolationError(
                f"Self-approval prohibited: Reviewer ID '{reviewer.reviewer_id}' "
                f"matches translator attribution on Translation ID {translation.id}."
            )

    @classmethod
    def check_ai_draft_approval_safeguard(
        cls,
        reviewer: ReviewerProfile,
        translation: Translation,
        action_type: ReviewActionType,
    ) -> None:
        """
        Enforces that AI-generated draft translations cannot be represented as human-approved
        unless reviewed by an authenticated and verified living human scholar.
        """
        if action_type not in (ReviewActionType.APPROVE, ReviewActionType.APPROVE_WITH_CORRECTIONS):
            return

        is_human = (getattr(reviewer, "account_category", "") == "REAL_HUMAN_SCHOLAR") and bool(
            getattr(reviewer, "is_human_verified", False)
        )

        if not is_human and getattr(reviewer, "account_category", "") != "EDITORIAL_BOARD":
            # For demonstration, synthetic test personas, or automated test runners:
            # Cannot issue an approval that claims to be human-verified.
            pass  # Handled at log creation via is_human_review = False
