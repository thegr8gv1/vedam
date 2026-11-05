"""
Vedic Heritage Platform — Audio Production Handoff Preparation Engine
Structures audio cues, verse pauses, Vedic accent guides, and script separations
for studio recording and automated synthesis without modifying text or translations.
"""

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from database.models import Text, Verse


@dataclass
class VerseAudioCue:
    verse_number: int
    verse_id: str
    original_text: str
    iast_phonetic: str
    pause_after_verse_sec: float
    has_vedic_swaras: bool
    swara_annotations: Optional[Dict[str, Any]]
    regional_script_rendering: Optional[str]
    pronunciation_notes: List[str]
    studio_recording_notes: str


@dataclass
class AudioProductionHandoffPackage:
    content_id: str
    canonical_title: str
    devanagari_title: str
    meter: Optional[str]
    primary_deity: Optional[str]
    original_language: str
    total_verses: int
    generated_at_utc: str
    cues: List[VerseAudioCue] = field(default_factory=list)
    translation_reference_note: str = (
        "Audio recording must recite only the immutable original sacred verse text; "
        "translations and regional explanations must be recorded as separate commentary tracks."
    )

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


class AudioPreparationEngine:
    """Prepares structured, standardized audio production packages for sacred recitations."""

    EXPORT_DIR = "exports/audio_manifests"

    @classmethod
    def ensure_export_dir(cls) -> None:
        Path(cls.EXPORT_DIR).mkdir(parents=True, exist_ok=True)

    @classmethod
    def prepare_handoff_package(
        cls,
        text: Text,
        regional_script: str = "Devanagari",
    ) -> AudioProductionHandoffPackage:
        sorted_verses = sorted(text.verses, key=lambda v: v.verse_number)
        cues: List[VerseAudioCue] = []

        is_vedic = text.content_id in (
            "VEDA-TXT-00005", "VEDA-TXT-00006", "VEDA-TXT-00007",
            "VEDA-TXT-00014", "VEDA-TXT-00015", "VEDA-TXT-00016"
        )

        for v in sorted_verses:
            # Determine script rendering
            script_text = v.devanagari_text
            for tr in v.transliterations:
                if tr.target_script.lower() == regional_script.lower():
                    script_text = tr.script_text
                    break

            # Pronunciation cues
            notes = []
            if v.vedic_accents_present or is_vedic:
                notes.append("Taittiriya/Rigvedic Swara markers active: maintain strictly pitch inflection (anudatta low, svarita high).")
                pause_sec = 2.5
                rec_note = "Slow classical Vedic tempo (Vilambita Laya); do not elide visargas."
            elif text.chandas and "Totaka" in text.chandas:
                notes.append("Totaka metre: dynamic anapestic fourfold rhythm (sa-gana sa-gana sa-gana sa-gana).")
                pause_sec = 1.8
                rec_note = "Rhythmic devotional tempo (Madhya Laya); preserve sweet musical cadence."
            else:
                pause_sec = 2.0
                rec_note = "Standard stotra recitation tempo; observe half-verse pause at single danda (।)."

            if "॥" in v.devanagari_text:
                notes.append("Full stop at double danda (॥).")

            cues.append(
                VerseAudioCue(
                    verse_number=v.verse_number,
                    verse_id=v.verse_id,
                    original_text=v.devanagari_text,
                    iast_phonetic=v.iast_text or "",
                    pause_after_verse_sec=pause_sec,
                    has_vedic_swaras=bool(v.vedic_accents_present),
                    swara_annotations=v.vedic_accent_annotations,
                    regional_script_rendering=script_text,
                    pronunciation_notes=notes,
                    studio_recording_notes=rec_note,
                )
            )

        return AudioProductionHandoffPackage(
            content_id=text.content_id,
            canonical_title=text.canonical_title,
            devanagari_title=text.devanagari_title,
            meter=text.chandas,
            primary_deity=text.deity.name if text.deity else None,
            original_language=text.original_language,
            total_verses=len(sorted_verses),
            generated_at_utc=datetime.now(timezone.utc).isoformat(),
            cues=cues,
        )

    @classmethod
    def export_audio_manifest(cls, text: Text, regional_script: str = "Devanagari") -> str:
        cls.ensure_export_dir()
        pkg = cls.prepare_handoff_package(text, regional_script=regional_script)
        slug = text.canonical_title.lower().replace(" ", "_").replace("-", "_")
        filename = f"{text.content_id}_{slug}_audio_manifest.json"
        out_path = os.path.join(cls.EXPORT_DIR, filename)

        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(pkg.to_dict(), f, indent=2, ensure_ascii=False)

        return out_path

    @classmethod
    def export_section_audio_manifests(
        cls,
        text: Text,
        regional_script: str = "Devanagari",
    ) -> List[str]:
        """
        Exports distinct audio production manifests for compositions with discrete liturgical sections
        (specifically Sri Venkateswara Suprabhatam Collection across its 4 sections).
        """
        cls.ensure_export_dir()
        manifest_paths: List[str] = []

        if text.content_id == "VEDA-TXT-00013":
            sections = [
                ("SEC-SV-01", "suprabhatam", "Sri Venkateswara Suprabhatam (Awakening)", 1, 29),
                ("SEC-SV-02", "stotram", "Sri Venkateswara Stotram (Eulogy of Glories)", 30, 40),
                ("SEC-SV-03", "prapatti", "Sri Venkateswara Prapatti (Solemn Surrender)", 41, 56),
                ("SEC-SV-04", "mangalasasanam", "Sri Venkateswara Mangalasasanam (Benediction)", 57, 70),
            ]

            full_pkg = cls.prepare_handoff_package(text, regional_script=regional_script)
            cues_by_vnum = {cue.verse_number: cue for cue in full_pkg.cues}

            for sec_id, sec_slug, sec_name, v_start, v_end in sections:
                sec_cues = [cues_by_vnum[v] for v in range(v_start, v_end + 1) if v in cues_by_vnum]
                sec_pkg = AudioProductionHandoffPackage(
                    content_id=f"{text.content_id}-{sec_id}",
                    canonical_title=f"{text.canonical_title} — {sec_name}",
                    devanagari_title=text.devanagari_title,
                    meter=text.chandas,
                    primary_deity=text.deity.name if text.deity else None,
                    original_language=text.original_language,
                    total_verses=len(sec_cues),
                    generated_at_utc=datetime.now(timezone.utc).isoformat(),
                    cues=sec_cues,
                )
                filename = f"{text.content_id}_{sec_id}_{sec_slug}_audio_manifest.json"
                out_path = os.path.join(cls.EXPORT_DIR, filename)
                with open(out_path, "w", encoding="utf-8") as f:
                    json.dump(sec_pkg.to_dict(), f, indent=2, ensure_ascii=False)
                manifest_paths.append(out_path)

        return manifest_paths
