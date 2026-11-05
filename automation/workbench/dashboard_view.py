"""
Vedic Heritage Platform — Web-Based Scholarly Review Workbench HTML Dashboard
Backward-compatible wrapper delegating to MultilingualWorkbenchViewGenerator.
"""

import logging
from typing import Optional
from sqlalchemy.orm import Session

from automation.workbench.multilingual_dashboard import MultilingualWorkbenchViewGenerator

logger = logging.getLogger("vedam.automation.workbench.dashboard_view")


class ScholarlyWorkbenchViewGenerator:
    """Generates the static/interactive HTML Review Workbench."""

    @classmethod
    def generate_html_workbench(
        cls,
        session: Session,
        content_id: str = "VEDA-TXT-00002",
        verse_number: int = 1,
        target_language: str = "te",
        output_file: str = "exports/reports/scholarly_review_workbench.html",
        reviewer_id: Optional[str] = "REV-ADMIN-001",
        target_script: Optional[str] = None,
    ) -> str:
        """Generates self-contained HTML review dashboard for a specific verse."""
        return MultilingualWorkbenchViewGenerator.generate_html_workbench(
            session=session,
            content_id=content_id,
            verse_number=verse_number,
            target_language=target_language,
            target_script=target_script,
            reviewer_id=reviewer_id,
            output_file=output_file,
        )


if __name__ == "__main__":
    from database.connection import get_db_session
    with get_db_session() as session:
        out = ScholarlyWorkbenchViewGenerator.generate_html_workbench(session)
        print("Generated Scholarly Workbench:", out)
