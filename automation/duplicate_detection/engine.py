"""
Vedic Heritage Platform — Duplicate Detection Engine
Identifies exact duplicates and traditional textual recension variants.
"""

import unicodedata
import re
from typing import Dict, List, Optional, Tuple

try:
    from rapidfuzz import fuzz
    USE_RAPIDFUZZ = True
except ImportError:
    import difflib
    USE_RAPIDFUZZ = False

from database.models import DuplicateStatus


class DuplicateDetectionEngine:
    """
    Detects potential duplicate and variant texts across multiple collections.
    
    Tiers of analysis:
    1. Exact SHA-256 Hash Matching (score = 1.0)
    2. Normalized Character Levenshtein Ratio
    3. Token Sort Ratio (matches across verse permutations or rearranged orders)
    """

    EXACT_THRESHOLD = 0.99
    VARIANT_THRESHOLD = 0.85

    @classmethod
    def normalize_text_for_comparison(cls, text: str) -> str:
        """Strip punctuation, danda markers, and normalize Indic whitespace."""
        if not text:
            return ""
        # Unicode NFC
        nfc = unicodedata.normalize("NFC", text)
        # Remove danda (।), double danda (॥), digits, and standard punctuation
        cleaned = re.sub(r"[।॥!?,:;\-\"'\(\)\[\]\d०-९]", " ", nfc)
        # Normalize whitespace
        return re.sub(r"\s+", " ", cleaned).strip().lower()

    @classmethod
    def calculate_similarity(cls, text_a: str, text_b: str) -> float:
        """Calculate normalized similarity ratio between two texts (0.0 to 1.0)."""
        norm_a = cls.normalize_text_for_comparison(text_a)
        norm_b = cls.normalize_text_for_comparison(text_b)

        if not norm_a and not norm_b:
            return 1.0
        if not norm_a or not norm_b:
            return 0.0
        if norm_a == norm_b:
            return 1.0

        if USE_RAPIDFUZZ:
            # Weighted average between direct sequence ratio and token sort ratio
            ratio = fuzz.ratio(norm_a, norm_b) / 100.0
            token_sort = fuzz.token_sort_ratio(norm_a, norm_b) / 100.0
            return round(max(ratio, token_sort), 4)
        else:
            matcher = difflib.SequenceMatcher(None, norm_a, norm_b)
            return round(matcher.ratio(), 4)

    @classmethod
    def classify_similarity(cls, score: float) -> Tuple[DuplicateStatus, str]:
        """Classify a numerical similarity score into an actionable status."""
        if score >= cls.EXACT_THRESHOLD:
            return DuplicateStatus.RESOLVED_IDENTICAL, "Exact or near-identical duplicate text."
        elif score >= cls.VARIANT_THRESHOLD:
            return DuplicateStatus.DETECTED, "Traditional recension or regional variant candidate."
        else:
            return DuplicateStatus.RESOLVED_DISTINCT, "Distinct independent composition."
