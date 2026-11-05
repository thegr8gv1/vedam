"""
Database Connection and Session Management
Supports SQLite (development/prototyping) and PostgreSQL (production).
Enforces strict test database isolation to prevent mutation of the live production database.
"""

from contextlib import contextmanager
import logging
import os
from typing import Generator, Optional, Tuple

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from automation.database.safety import (
    ProductionDatabaseProtectionError,
    assert_not_production_database,
    is_production_database,
    is_test_environment,
)
from database.models import Base

load_dotenv()
logger = logging.getLogger("vedam.database.connection")


def get_active_database_url() -> str:
    """Returns the currently configured database URL from environment or defaults."""
    return os.getenv("DATABASE_URL", "sqlite:///./database/vedam.db")


DATABASE_URL = get_active_database_url()

# Connect arguments (thread safety for SQLite)
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

# If running in a test runner environment and DATABASE_URL points to production,
# do NOT bind the global engine to the production database!
_is_test = is_test_environment()
_is_prod = is_production_database(DATABASE_URL)

if _is_test and _is_prod:
    logger.warning(
        "[SAFETY GUARD] Test environment detected with default production DATABASE_URL. "
        "Global engine initialization to production is deferred pending test isolation."
    )
    engine = create_engine("sqlite:///:memory:", echo=False, connect_args={"check_same_thread": False})
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
else:
    engine = create_engine(
        DATABASE_URL,
        echo=os.getenv("LOG_LEVEL", "INFO") == "DEBUG",
        connect_args=connect_args,
    )
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def configure_engine(
    database_url: Optional[str] = None,
    echo: Optional[bool] = None,
) -> Tuple[Engine, sessionmaker]:
    """
    Reconfigures the active database engine and sessionmaker.
    Strictly verifies that test execution does not target the production database.
    """
    global DATABASE_URL, engine, SessionLocal
    url = database_url or get_active_database_url()

    # Safety guard: refuse production database during test execution
    assert_not_production_database(url, context="configure_engine")

    DATABASE_URL = url
    c_args = {"check_same_thread": False} if url.startswith("sqlite") else {}
    is_debug = echo if echo is not None else (os.getenv("LOG_LEVEL", "INFO") == "DEBUG")

    engine = create_engine(url, echo=is_debug, connect_args=c_args)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    logger.info(f"Database engine reconfigured to: {url}")
    return engine, SessionLocal


def set_test_database_url(test_url: str) -> Tuple[Engine, sessionmaker]:
    """
    Explicitly reconfigures database engine and sessionmaker to an isolated test database.
    Strictly asserts that test_url is NOT production before setting os.environ.
    """
    assert_not_production_database(test_url, context="set_test_database_url")
    os.environ["DATABASE_URL"] = test_url
    os.environ["VEDAM_TEST_MODE"] = "1"
    return configure_engine(test_url)


def reset_database_configuration() -> Tuple[Engine, sessionmaker]:
    """Resets database engine to the default environment configuration."""
    return configure_engine(os.getenv("DATABASE_URL", "sqlite:///./database/vedam.db"))


def init_db(target_engine: Optional[Engine] = None) -> None:
    """Initialize database tables according to the declarative models."""
    eng = target_engine or engine
    assert_not_production_database(str(eng.url), context="init_db")
    Base.metadata.create_all(bind=eng)


def drop_db(target_engine: Optional[Engine] = None) -> None:
    """Drop all tables (strictly used in test fixtures against non-production databases)."""
    eng = target_engine or engine
    assert_not_production_database(str(eng.url), context="drop_db")
    Base.metadata.drop_all(bind=eng)


@contextmanager
def get_db_session() -> Generator[Session, None, None]:
    """
    Context manager for transactional database sessions.
    Guarantees that test sessions operate solely against isolated test databases.
    """
    active_url = get_active_database_url()
    assert_not_production_database(active_url, context="get_db_session")

    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
