"""
Vedic Heritage Platform — Unified Multilingual Publication Orchestrator
Part D.8: End-to-end coordinator delivering high-level APIs for generating
all 4 publication formats (HTML, PDF, DOCX, EPUB) from domain models or database entities,
enforcing scholarly release governance, tracking artifact manifests, and calculating SHA-256 digests.
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Union

from sqlalchemy.orm import Session

from automation.exporters.docx_multilingual_exporter import MultilingualDOCXExporter
from automation.exporters.epub_exporter import MultilingualEPUBExporter
from automation.exporters.html_exporter import MultilingualHTMLExporter
from automation.exporters.pdf_multilingual_exporter import MultilingualPDFExporter
from automation.exporters.publication_gatekeeper import (
    PublicationGatekeeper,
    PublicationGateReport,
    ReleaseGateVerdict,
)
from automation.exporters.publication_model import PublicationDocument, PublicationGovernance
from database.models import ReviewerProfile, Text

logger = logging.getLogger("vedam.automation.exporters.multilingual_publication_orchestrator")


@dataclass(frozen=True)
class PublicationArtifact:
    format_type: str            # "html", "pdf", "docx", "epub"
    file_path: str
    file_size_bytes: int
    sha256_hash: str
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


@dataclass(frozen=True)
class PublicationManifest:
    content_id: str
    canonical_title: str
    target_bcp47: str
    publication_channel: str
    gate_verdict: str
    artifacts: Dict[str, PublicationArtifact]
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> Dict[str, Any]:
        return {
            "content_id": self.content_id,
            "canonical_title": self.canonical_title,
            "target_bcp47": self.target_bcp47,
            "publication_channel": self.publication_channel,
            "gate_verdict": self.gate_verdict,
            "created_at": self.created_at.isoformat(),
            "artifacts": {
                fmt: {
                    "format_type": art.format_type,
                    "file_path": art.file_path,
                    "file_size_bytes": art.file_size_bytes,
                    "sha256": art.sha256_hash,
                }
                for fmt, art in self.artifacts.items()
            },
        }


class MultilingualPublicationOrchestrator:
    """
    Central orchestration facade coordinating multi-format publication exports
    across all 14 scripts, 22 languages, and 4 physical target formats.
    """

    SUPPORTED_FORMATS = ("html", "pdf", "docx", "epub")

    @classmethod
    def export_all(
        cls,
        document: PublicationDocument,
        formats: Optional[Sequence[str]] = None,
        output_dir: Optional[Union[str, Path]] = None,
        enforce_gate: bool = True,
        requesting_reviewer: Optional[ReviewerProfile] = None,
    ) -> PublicationManifest:
        """
        Coordinates generation of requested publication formats from a PublicationDocument.
        Enforces governance preflight check before triggering any file creation.
        """
        chosen_formats = [f.lower().strip() for f in (formats or cls.SUPPORTED_FORMATS)]
        for f in chosen_formats:
            if f not in cls.SUPPORTED_FORMATS:
                raise ValueError(f"Unsupported publication format '{f}'. Supported: {cls.SUPPORTED_FORMATS}")

        # Preflight release gate check
        gate_rep = PublicationGatekeeper.evaluate_publication(
            document,
            requesting_reviewer=requesting_reviewer,
        )
        if enforce_gate and not gate_rep.can_export:
            blocker_msgs = "; ".join([b.message for b in gate_rep.blockers])
            raise PermissionError(f"Publication Release Gate Blocked Export: {blocker_msgs}")

        artifacts: Dict[str, PublicationArtifact] = {}
        base_dir = Path(output_dir) if output_dir else Path("exports/multilingual_publication")

        for fmt in chosen_formats:
            fmt_dir = base_dir / fmt
            fmt_dir.mkdir(parents=True, exist_ok=True)
            slug = document.metadata.canonical_title.lower().replace(" ", "_").replace("-", "_")
            fname = f"{document.metadata.content_id}_{slug}_{document.target.bcp47}_{document.governance.publication_channel}.{fmt}"
            out_file_path = str((fmt_dir / fname).resolve())

            if fmt == "html":
                actual_path = MultilingualHTMLExporter.export(document, output_path=out_file_path, enforce_gate=False)
            elif fmt == "pdf":
                actual_path = MultilingualPDFExporter.export(document, output_path=out_file_path, enforce_gate=False)
            elif fmt == "docx":
                actual_path = MultilingualDOCXExporter.export(document, output_path=out_file_path, enforce_gate=False)
            elif fmt == "epub":
                actual_path = MultilingualEPUBExporter.export(document, output_path=out_file_path, enforce_gate=False)
            else:
                continue

            # Calculate artifact metadata
            p = Path(actual_path)
            content_bytes = p.read_bytes()
            art = PublicationArtifact(
                format_type=fmt,
                file_path=str(p),
                file_size_bytes=len(content_bytes),
                sha256_hash=hashlib.sha256(content_bytes).hexdigest(),
            )
            artifacts[fmt] = art

        manifest = PublicationManifest(
            content_id=document.metadata.content_id,
            canonical_title=document.metadata.canonical_title,
            target_bcp47=document.target.bcp47,
            publication_channel=document.governance.publication_channel,
            gate_verdict=gate_rep.verdict.value,
            artifacts=artifacts,
        )

        # Write manifest file alongside
        manifest_path = base_dir / f"{document.metadata.content_id}_{document.target.bcp47}_manifest.json"
        manifest_path.write_text(json.dumps(manifest.to_dict(), indent=2, ensure_ascii=False), encoding="utf-8")

        logger.info(
            "Publication completed for %s [%s] across formats %s. Manifest: %s",
            document.metadata.content_id,
            document.target.bcp47,
            list(artifacts.keys()),
            manifest_path,
        )
        return manifest

    @classmethod
    def export_text_from_database(
        cls,
        session: Session,
        text_id_or_content_id: str,
        target_language: str,
        target_script: Optional[str] = None,
        publication_channel: str = "draft_export",
        formats: Optional[Sequence[str]] = None,
        output_dir: Optional[Union[str, Path]] = None,
        enforce_gate: bool = True,
        requesting_reviewer: Optional[ReviewerProfile] = None,
    ) -> PublicationManifest:
        """
        Loads a Text and its associated verses/views from the database,
        constructs a PublicationDocument, and generates publication artifacts.
        """
        # Read-only query
        query = session.query(Text)
        if text_id_or_content_id.isdigit():
            text = query.filter(Text.id == int(text_id_or_content_id)).first()
        else:
            text = query.filter(
                (Text.content_id == text_id_or_content_id) | (Text.canonical_title == text_id_or_content_id)
            ).first()

        if not text:
            raise ValueError(f"Text not found in database for identifier: '{text_id_or_content_id}'.")

        # Construct canonical PublicationDocument
        doc = PublicationDocument.from_text_and_views(
            text=text,
            target_language=target_language,
            target_script=target_script,
            publication_channel=publication_channel,
        )

        return cls.export_all(
            document=doc,
            formats=formats,
            output_dir=output_dir,
            enforce_gate=enforce_gate,
            requesting_reviewer=requesting_reviewer,
        )
