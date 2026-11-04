"""
Vedic Heritage Platform — Structured Pipeline Logger
Provides centralized logging with timestamping, structured JSON outputs,
console formatting, and error rotation.
"""

from datetime import datetime, timezone
import json
import logging
import os
from pathlib import Path
from typing import Any, Dict, Optional


class PipelineLogger:
    """Manages platform loggers and structured audit event recording."""

    _logger: Optional[logging.Logger] = None

    @classmethod
    def get_logger(cls, name: str = "vedam_pipeline") -> logging.Logger:
        if cls._logger:
            return cls._logger

        logger = logging.getLogger(name)
        log_level = os.getenv("LOG_LEVEL", "INFO").upper()
        logger.setLevel(getattr(logging, log_level, logging.INFO))

        # Avoid duplicate handlers
        if not logger.handlers:
            log_dir = Path("logs")
            log_dir.mkdir(parents=True, exist_ok=True)
            log_file = log_dir / "pipeline.log"

            # File Handler
            file_handler = logging.FileHandler(str(log_file), encoding="utf-8")
            file_format = logging.Formatter(
                '{"timestamp": "%(asctime)s", "level": "%(levelname)s", "module": "%(name)s", "message": "%(message)s"}'
            )
            file_handler.setFormatter(file_format)
            logger.addHandler(file_handler)

            # Console Handler
            console_handler = logging.StreamHandler()
            console_format = logging.Formatter("[%(asctime)s] %(levelname)s [%(name)s]: %(message)s", datefmt="%H:%M:%S")
            console_handler.setFormatter(console_format)
            logger.addHandler(console_handler)

        cls._logger = logger
        return logger

    @classmethod
    def log_event(cls, event_type: str, details: Dict[str, Any], level: str = "INFO") -> None:
        """Record structured operational audit event."""
        logger = cls.get_logger()
        record = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "event_type": event_type,
            **details,
        }
        msg = json.dumps(record, ensure_ascii=False)
        if level == "DEBUG":
            logger.debug(msg)
        elif level == "WARNING":
            logger.warning(msg)
        elif level == "ERROR":
            logger.error(msg)
        else:
            logger.info(msg)
