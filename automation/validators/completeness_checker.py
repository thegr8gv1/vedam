"""
Vedic Heritage Platform — Content Completeness & Integrity Validator
Checks for missing verses in sequential stotrams, incomplete stanzas,
duplicate verse numbering, and structural omissions.
"""

from typing import Any, Dict, List, Tuple


class CompletenessChecker:
    """
    Validates structural continuity and numerical completeness of a sacred text.
    """

    @classmethod
    def validate_verse_sequence(cls, verses: List[Dict[str, Any]]) -> Tuple[bool, List[str]]:
        """
        Verify that verse numbers form an unbroken sequential series (1, 2, 3, ... N).
        Returns (is_complete, issues_list).
        """
        if not verses:
            return False, ["Text contains zero verses."]

        issues = []
        seen_numbers = set()
        max_num = 0

        for idx, v in enumerate(verses, start=1):
            num = v.get("verse_number")
            if num is None:
                issues.append(f"Verse at index {idx} lacks a verse_number.")
                continue

            if num in seen_numbers:
                issues.append(f"Duplicate verse number {num} detected at index {idx}.")
            seen_numbers.add(num)
            if num > max_num:
                max_num = num

            # Check for empty text
            text = v.get("devanagari_text", "").strip()
            if not text:
                issues.append(f"Verse {num} has empty or missing Devanagari text.")
            elif not (text.endswith("॥") or text.endswith("|") or text.endswith("।") or "॥" in text):
                issues.append(f"Verse {num} appears truncated (lacks closing danda punctuation).")

        # Check for sequence gaps
        expected_numbers = set(range(1, max_num + 1))
        missing = expected_numbers - seen_numbers
        if missing:
            sorted_missing = sorted(list(missing))
            issues.append(f"Missing verses detected in sequence: {sorted_missing}")

        is_complete = len(issues) == 0
        return is_complete, issues
