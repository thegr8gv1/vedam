"""
Vedic Heritage Platform — Base Source Connector Framework
Provides the abstract foundation for authorized, rate-limited, resilient,
and resumable content extraction.
"""

from abc import ABC, abstractmethod
from datetime import datetime, timezone
import time
from typing import Any, Dict, List, Optional
import requests

from automation.pipeline.checkpoint import JobCheckpoint
from automation.pipeline.logger import PipelineLogger
from database.models import ReleaseStatus, Source


class ConnectorPermissionError(Exception):
    """Raised when an extraction is attempted against an unauthorized or restricted source."""
    pass


class BaseSourceConnector(ABC):
    """
    Abstract Base Class for all external source connectors.
    
    Guarantees:
    - Never circumvents robots.txt or access restrictions.
    - Never extracts full text without established legal clearance.
    - Operates with strict rate limits and exponential backoff.
    - Maintains resumable checkpoints.
    - Supports dry-run simulation mode.
    """

    def __init__(
        self,
        source_code: str,
        base_url: str,
        request_delay_seconds: float = 2.0,
        max_retries: int = 3,
        timeout_seconds: int = 20,
        is_enabled: bool = True,
        dry_run: bool = False,
        job_id: Optional[str] = None,
    ):
        self.source_code = source_code
        self.base_url = base_url
        self.request_delay_seconds = request_delay_seconds
        self.max_retries = max_retries
        self.timeout_seconds = timeout_seconds
        self.is_enabled = is_enabled
        self.dry_run = dry_run

        self.job_id = job_id or f"job_{source_code.lower()}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.checkpoint = JobCheckpoint(job_id=self.job_id, source_code=self.source_code)
        self.logger = PipelineLogger.get_logger(f"connector.{source_code.lower()}")

        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "VedicHeritageResearchBot/1.0 (+https://vedam.org/bot-info; non-commercial scholarly research)",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        })

    @abstractmethod
    def verify_source_authorization(self) -> bool:
        """Verify whether collection from this source is legally authorized."""
        pass

    @abstractmethod
    def discover_items(self) -> List[Dict[str, Any]]:
        """Discover catalog URLs, categories, and text slugs."""
        pass

    @abstractmethod
    def fetch_item(self, item_metadata: Dict[str, Any]) -> Dict[str, Any]:
        """Fetch individual raw text content and metadata."""
        pass

    def run_collection(self, limit: Optional[int] = None) -> Dict[str, Any]:
        """
        Orchestrate resumable, rate-limited extraction cycle.
        """
        if not self.is_enabled:
            self.logger.warning(f"Connector for {self.source_code} is currently disabled. Halting.")
            return {"status": "DISABLED", "processed": 0}

        if not self.verify_source_authorization():
            err = (
                f"Collection Blocked: Source '{self.source_code}' has not established authorized collection rights. "
                "Halting to prevent unauthorized scraping."
            )
            self.logger.error(err)
            raise ConnectorPermissionError(err)

        self.logger.info(f"Starting extraction for {self.source_code} (Dry Run: {self.dry_run})")
        self.checkpoint.status = "RUNNING"
        self.checkpoint.save()

        items = self.discover_items()
        if limit:
            items = items[:limit]

        processed_count = 0
        failed_count = 0

        for item in items:
            item_key = item.get("url") or item.get("slug")
            if not item_key:
                continue

            if self.checkpoint.is_processed(item_key):
                self.logger.debug(f"Skipping already processed item: {item_key}")
                continue

            if self.dry_run:
                self.logger.info(f"[DRY-RUN] Would fetch: {item_key}")
                self.checkpoint.mark_completed(item_key)
                processed_count += 1
                continue

            # Respect rate limit delay
            time.sleep(self.request_delay_seconds)

            try:
                raw_data = self._fetch_with_retry(item)
                self.checkpoint.mark_completed(item_key)
                processed_count += 1
                self.logger.info(f"Successfully collected: {item_key}")
            except Exception as e:
                failed_count += 1
                err_msg = str(e)
                self.checkpoint.mark_failed(item_key, err_msg)
                self.logger.error(f"Failed collecting {item_key}: {err_msg}")

        self.checkpoint.status = "COMPLETED" if failed_count == 0 else "PARTIAL"
        self.checkpoint.save()

        summary = {
            "job_id": self.job_id,
            "source_code": self.source_code,
            "status": self.checkpoint.status,
            "processed": processed_count,
            "failed": failed_count,
            "total_items": len(items),
        }
        self.logger.info(f"Collection complete for {self.source_code}: {summary}")
        return summary

    def _fetch_with_retry(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """Execute HTTP request with exponential backoff."""
        attempts = 0
        backoff = 1.5

        while attempts < self.max_retries:
            attempts += 1
            try:
                return self.fetch_item(item)
            except Exception as e:
                if attempts >= self.max_retries:
                    raise
                wait_time = backoff ** attempts
                self.logger.warning(f"Attempt {attempts} failed for item. Retrying in {wait_time:.1f}s... Error: {e}")
                time.sleep(wait_time)
        raise RuntimeError("Exceeded maximum retries.")
