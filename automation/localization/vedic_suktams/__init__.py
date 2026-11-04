"""
Vedic Heritage Platform — Phase 6C Batch 2 Vedic Suktams Localization Data
Structured multilingual translation views (Devotional Bhavartha, Literal, Traditional Commentary, Padachheda)
across nine regional Indian languages for the four approved Vedic Suktams:
1. Sri Suktam (VEDA-TXT-00007) — 16 verses
2. Purusha Suktam (VEDA-TXT-00014) — 16 verses
3. Durga Suktam (VEDA-TXT-00015) — 7 verses
4. Narayana Suktam (VEDA-TXT-00016) — 12 verses
"""

from .sri_suktam_data import get_sri_suktam_payload
from .purusha_suktam_data import get_purusha_suktam_payload
from .durga_suktam_data import get_durga_suktam_payload
from .narayana_suktam_data import get_narayana_suktam_payload

__all__ = [
    "get_sri_suktam_payload",
    "get_purusha_suktam_payload",
    "get_durga_suktam_payload",
    "get_narayana_suktam_payload",
]
