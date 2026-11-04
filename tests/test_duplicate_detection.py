"""
Unit Tests for Duplicate Detection Engine
"""

from automation.duplicate_detection.engine import DuplicateDetectionEngine
from database.models import DuplicateStatus


def test_exact_duplicate():
    text_a = "मुदाकरात्तमोदकं सदा विमुक्तिसाधकम् । कलाधरावतंसकं विलासिलोकरक्षकम् ॥"
    text_b = "मुदाकरात्तमोदकं सदा विमुक्तिसाधकम् कलाधरावतंसकं विलासिलोकरक्षकम्"

    score = DuplicateDetectionEngine.calculate_similarity(text_a, text_b)
    status, reason = DuplicateDetectionEngine.classify_similarity(score)

    assert score >= 0.99
    assert status == DuplicateStatus.RESOLVED_IDENTICAL


def test_variant_recension_detection():
    # Subtle variation in traditional reading (e.g., विनाशितेभदैत्यकं vs प्रणाशितेभदैत्यकम्)
    text_a = "मुदाकरात्तमोदकं सदा विमुक्तिसाधकं कलाधरावतंसकं विलासिलोकरक्षकम् । अनायकैकनायकं विनाशितेभदैत्यकं नताशुभाशुकर्तकं नमामि तं विनायकम् ॥"
    text_b = "मुदाकरात्तमोदकं सदा विमुक्तिसाधकं कलाधरावतंसकं विलासिलोकरक्षकम् । अनायकैकनायकं प्रणाशितेभदैत्यकं नताशुभाशुकर्तकं नमामि तं विनायकम् ॥"

    score = DuplicateDetectionEngine.calculate_similarity(text_a, text_b)
    status, reason = DuplicateDetectionEngine.classify_similarity(score)

    assert 0.85 <= score < 1.0
    assert status == DuplicateStatus.DETECTED


def test_distinct_compositions():
    text_a = "ॐ नमः शिवाय"
    text_b = "ॐ नमो भगवते वासुदेवाय"

    score = DuplicateDetectionEngine.calculate_similarity(text_a, text_b)
    status, reason = DuplicateDetectionEngine.classify_similarity(score)

    assert score < 0.85
    assert status == DuplicateStatus.RESOLVED_DISTINCT
