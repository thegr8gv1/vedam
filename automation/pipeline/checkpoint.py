"""
Vedic Heritage Platform — Job Checkpointing & Resumability Engine
Persists collection and processing state to disk, enabling zero-loss recovery
from network interrupts, rate limits, or system restarts.
"""

from datetime import datetime, timezone
import json
from pathlib import Path
from typing import Any, Dict, List, Optional, Set


class JobCheckpoint:
    """Tracks state and progress of an individual extraction or ingestion job."""

    def __init__(
        self,
        job_id: str,
        source_code: str,
        checkpoint_dir: str = "logs/checkpoints",
    ):
        self.job_id = job_id
        self.source_code = source_code
        self.checkpoint_dir = Path(checkpoint_dir)
        self.checkpoint_dir.mkdir(parents=True, exist_ok=True)
        self.file_path = self.checkpoint_dir / f"{job_id}.json"

        self.status: str = "PENDING"
        self.processed_items: Set[str] = set()
        self.failed_items: Dict[str, str] = {}
        self.metadata: Dict[str, Any] = {}
        self.created_at: str = datetime.now(timezone.utc).isoformat()
        self.last_updated: str = self.created_at

        # Attempt to load existing checkpoint if present
        self.load()

    def mark_completed(self, item_key: str) -> None:
        """Mark a URL or content slug as successfully completed and persist."""
        self.processed_items.add(item_key)
        if item_key in self.failed_items:
            del self.failed_items[item_key]
        self.save()

    def mark_failed(self, item_key: str, error_msg: str) -> None:
        """Record an extraction failure for retry and audit."""
        self.failed_items[item_key] = error_msg
        self.save()

    def is_processed(self, item_key: str) -> bool:
        """Check whether an item was already successfully processed."""
        return item_key in self.processed_items

    def save(self) -> None:
        """Serialize state to disk atomically."""
        self.last_updated = datetime.now(timezone.utc).isoformat()
        payload = {
            "job_id": self.job_id,
            "source_code": self.source_code,
            "status": self.status,
            "processed_count": len(self.processed_items),
            "failed_count": len(self.failed_items),
            "processed_items": sorted(list(self.processed_items)),
            "failed_items": self.failed_items,
            "metadata": self.metadata,
            "created_at": self.created_at,
            "last_updated": self.last_updated,
        }
        temp_file = self.file_path.with_suffix(".tmp")
        with open(temp_file, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2, ensure_ascii=False)
        temp_file.replace(self.file_path)

    def load(self) -> bool:
        """Load state from disk if checkpoint file exists."""
        if not self.file_path.exists():
            return False

        try:
            with open(self.file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            self.job_id = data.get("job_id", self.job_id)
            self.source_code = data.get("source_code", self.source_code)
            self.status = data.get("status", "PENDING")
            self.processed_items = set(data.get("processed_items", []))
            self.failed_items = data.get("failed_items", {})
            self.metadata = data.get("metadata", {})
            self.created_at = data.get("created_at", self.created_at)
            self.last_updated = data.get("last_updated", self.last_updated)
            return True
        except Exception:
            return False

    def reset(self) -> None:
        """Clear checkpoint state."""
        self.processed_items.clear()
        self.failed_items.clear()
        self.status = "RESET"
        self.save()
