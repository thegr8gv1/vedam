"""
Vedic Heritage Platform — Phase 6C Batch 3 Classical Stotras Localization Data
Structured multilingual translation views (Devotional Bhavartha, Literal, Traditional Commentary, Padachheda)
across nine regional Indian languages for the four authorized compositions:
Group A:
1. Shiva Tandava Stotram (VEDA-TXT-00002) — 16 verses
2. Aditya Hrudayam (VEDA-TXT-00003) — 31 verses
Group B:
3. Kanakadhara Stotram (VEDA-TXT-00018) — 21 verses
4. Mahishasura Mardini Stotram (VEDA-TXT-00019) — 21 verses
"""

from .shiva_tandava_data import get_shiva_tandava_payload
from .aditya_hrudayam_data import get_aditya_hrudayam_payload
from .kanakadhara_stotram_data import get_kanakadhara_payload
from .mahishasura_mardini_data import get_mahishasura_mardini_payload

__all__ = [
    "get_shiva_tandava_payload",
    "get_aditya_hrudayam_payload",
    "get_kanakadhara_payload",
    "get_mahishasura_mardini_payload",
]
