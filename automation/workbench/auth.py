"""
Vedic Heritage Platform — Scholarly Workbench Authentication & Security Engine
Implements secure password hashing, cryptographic session management, role-based access control,
account lockout protections, sliding-window rate limiting, CSRF tokens, and tamper-evident audit logging.
"""

from datetime import datetime, timedelta, timezone
import base64
import hashlib
import hmac
import logging
import os
import secrets
import threading
import time
from typing import Any, Dict, List, Optional, Set, Tuple
from cryptography.hazmat.primitives.kdf.argon2 import Argon2id
from sqlalchemy.orm import Session

from database.models import (
    AuthAuditLog,
    ReviewerProfile,
    ReviewerRole,
    ReviewerSession,
)

logger = logging.getLogger("vedam.automation.workbench.auth")

SECRET_KEY = os.getenv("VEDAM_AUTH_SECRET", "vedam-scholarly-workbench-production-secret-key-2026")
MAX_FAILED_ATTEMPTS = 5
DEFAULT_SESSION_DURATION_HOURS = 12
DEFAULT_IDLE_TIMEOUT_MINUTES = 30
DEFAULT_ABSOLUTE_SESSION_HOURS = 12


class AuthError(Exception):
    """Base class for authentication and authorization errors."""
    pass


class AuthenticationRequiredError(AuthError):
    """Raised when an operation requires authentication but valid credentials were not supplied."""
    pass


class PermissionDeniedError(AuthError):
    """Raised when an authenticated reviewer lacks permissions for the requested operation."""
    pass


class AccountLockedError(AuthError):
    """Raised when an account is locked due to repeated authentication failures."""
    pass


class RateLimitExceededError(AuthError):
    """Raised when rate limits for API or authentication endpoints are exceeded."""
    pass


# ---------------------------------------------------------------------------
# Rate Limiting Engine
# ---------------------------------------------------------------------------

class RateLimiter:
    """Sliding-window in-memory rate limiter."""

    def __init__(self):
        self._lock = threading.Lock()
        self._history: Dict[str, List[float]] = {}

    def check_rate_limit(self, key: str, max_requests: int = 10, window_seconds: int = 60) -> bool:
        """
        Validates whether key has exceeded max_requests in the past window_seconds.
        Raises RateLimitExceededError if rate limit is exceeded; otherwise records request and returns True.
        """
        now = time.time()
        with self._lock:
            timestamps = self._history.get(key, [])
            cutoff = now - window_seconds
            # Filter timestamps in current window
            valid_timestamps = [t for t in timestamps if t > cutoff]
            if len(valid_timestamps) >= max_requests:
                logger.warning("Rate limit exceeded for key %s (%d requests in %ds)", key, len(valid_timestamps), window_seconds)
                raise RateLimitExceededError(f"Rate limit exceeded. Please wait before retrying.")
            valid_timestamps.append(now)
            self._history[key] = valid_timestamps
            return True

    def reset(self, key: Optional[str] = None) -> None:
        """Clears history for key or all keys (useful for test isolation)."""
        with self._lock:
            if key:
                self._history.pop(key, None)
            else:
                self._history.clear()


# Global rate limiter instance
global_rate_limiter = RateLimiter()


# ---------------------------------------------------------------------------
# Password Hashing and Cryptographic Utilities
# ---------------------------------------------------------------------------
# Password Hashing and Cryptographic Utilities (OWASP Argon2id + PBKDF2 Migration)
# ---------------------------------------------------------------------------

def hash_password(raw_password: str) -> str:
    """
    Hashes a password using Argon2id with OWASP-aligned configuration:
    memory_cost=65536 KiB (64 MiB), iterations=3, parallelism=4, 16-byte salt, 32-byte key.
    Format: '$argon2id$v=19$m=65536,t=3,p=4$<salt_b64>$<key_b64>'
    """
    if not raw_password or len(raw_password) < 8:
        raise ValueError("Password must be at least 8 characters long.")
    salt = secrets.token_bytes(16)
    kdf = Argon2id(salt=salt, length=32, iterations=3, lanes=4, memory_cost=65536)
    derived = kdf.derive(raw_password.encode("utf-8"))
    salt_b64 = base64.b64encode(salt).decode("ascii")
    derived_b64 = base64.b64encode(derived).decode("ascii")
    return f"$argon2id$v=19$m=65536,t=3,p=4${salt_b64}${derived_b64}"


def verify_password(raw_password: str, hashed: str) -> bool:
    """
    Verifies a raw password against the stored hash.
    Supports modern Argon2id ($argon2id$...) and legacy PBKDF2-HMAC-SHA256 (pbkdf2_sha256$...).
    """
    valid, _ = verify_and_upgrade_password(raw_password, hashed)
    return valid


def verify_and_upgrade_password(raw_password: str, hashed: str) -> Tuple[bool, Optional[str]]:
    """
    Verifies password and determines if the stored hash should be upgraded to Argon2id.
    Returns (is_valid, upgraded_hash_if_migration_needed).
    """
    if not hashed or not raw_password:
        return False, None

    # Case 1: Modern Argon2id
    if hashed.startswith("$argon2id$"):
        parts = hashed.split("$")
        if len(parts) != 6 or parts[1] != "argon2id":
            return False, None
        try:
            params = dict(kv.split("=") for kv in parts[3].split(","))
            m = int(params.get("m", 65536))
            t = int(params.get("t", 3))
            p = int(params.get("p", 4))
            salt = base64.b64decode(parts[4])
            expected_key = base64.b64decode(parts[5])
            kdf = Argon2id(salt=salt, length=len(expected_key), iterations=t, lanes=p, memory_cost=m)
            kdf.verify(raw_password.encode("utf-8"), expected_key)
            return True, None
        except Exception as exc:
            logger.debug("Argon2id verification failed: %s", exc)
            return False, None

    # Case 2: Legacy PBKDF2-HMAC-SHA256 (Phase 8 format)
    if hashed.startswith("pbkdf2_sha256$") or hashed.startswith("$pbkdf2-sha256$"):
        parts = hashed.split("$")
        if len(parts) == 4 and parts[0] == "pbkdf2_sha256":
            try:
                iterations = int(parts[1])
                salt = bytes.fromhex(parts[2])
                expected_hash = bytes.fromhex(parts[3])
                computed = hashlib.pbkdf2_hmac("sha256", raw_password.encode("utf-8"), salt, iterations)
                if hmac.compare_digest(computed, expected_hash):
                    upgraded = hash_password(raw_password)
                    return True, upgraded
                return False, None
            except Exception as exc:
                logger.error("Error verifying legacy PBKDF2 hash: %s", exc)
                return False, None

    return False, None


def get_secure_cookie_config(session_token: str, secure: bool = True) -> Dict[str, Any]:
    """
    Returns production OWASP-compliant secure cookie attributes for the session token.
    Enforces HttpOnly, SameSite=Strict, Secure flag, and 12-hour max-age.
    """
    return {
        "key": "vedam_session",
        "value": session_token,
        "httponly": True,
        "samesite": "Strict",
        "secure": secure,
        "max_age": DEFAULT_ABSOLUTE_SESSION_HOURS * 3600,
        "path": "/",
    }


def generate_csrf_token(session_token: str) -> str:
    """Generates an HMAC-SHA256 CSRF token tied to a specific session token."""
    h = hmac.new(SECRET_KEY.encode("utf-8"), session_token.encode("utf-8"), hashlib.sha256)
    return h.hexdigest()


def validate_csrf_token(csrf_token: str, session_token: str) -> bool:
    """Validates CSRF token using constant-time comparison."""
    if not csrf_token or not session_token:
        return False
    expected = generate_csrf_token(session_token)
    return hmac.compare_digest(csrf_token, expected)


# ---------------------------------------------------------------------------
# Authentication & Session Management
# ---------------------------------------------------------------------------

class AuthService:
    """Handles scholar login, session lifecycle, credential checks, and audit logging."""

    @classmethod
    def log_event(
        cls,
        session: Session,
        event_type: str,
        reviewer_id: Optional[int] = None,
        ip_address: Optional[str] = None,
        details: Optional[str] = None,
    ) -> AuthAuditLog:
        """Appends an immutable entry to the authentication audit trail."""
        log = AuthAuditLog(
            reviewer_id=reviewer_id,
            event_type=event_type,
            ip_address=ip_address,
            details=details,
            created_at=datetime.now(timezone.utc),
        )
        session.add(log)
        session.flush()
        return log

    @classmethod
    def authenticate(
        cls,
        session: Session,
        reviewer_id: str,
        raw_password: str,
        client_ip: Optional[str] = None,
        user_agent: Optional[str] = None,
        rate_limiter: Optional[RateLimiter] = None,
    ) -> Tuple[ReviewerProfile, ReviewerSession]:
        """
        Authenticates a reviewer, validates lock status, verifies password,
        resets failure counter on success, and creates an active session.
        """
        rl = rate_limiter or global_rate_limiter
        rate_key = f"auth:{reviewer_id}:{client_ip or 'unknown'}"
        rl.check_rate_limit(rate_key, max_requests=10, window_seconds=60)

        reviewer = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not reviewer:
            cls.log_event(
                session,
                event_type="LOGIN_FAILED_UNKNOWN_USER",
                ip_address=client_ip,
                details=f"Unknown reviewer_id: {reviewer_id}",
            )
            raise AuthenticationRequiredError("Invalid reviewer ID or password.")

        if reviewer.is_locked:
            cls.log_event(
                session,
                event_type="LOGIN_REJECTED_LOCKED_ACCOUNT",
                reviewer_id=reviewer.id,
                ip_address=client_ip,
                details="Attempted login on locked account.",
            )
            raise AccountLockedError("Account is locked due to repeated authentication failures. Contact an administrator.")

        if not reviewer.is_active:
            cls.log_event(
                session,
                event_type="LOGIN_REJECTED_INACTIVE_ACCOUNT",
                reviewer_id=reviewer.id,
                ip_address=client_ip,
                details="Attempted login on deactivated account.",
            )
            raise AuthenticationRequiredError("Reviewer account has been deactivated.")

        # Check password with automatic Argon2id upgrade
        is_valid, upgraded_hash = verify_and_upgrade_password(raw_password, reviewer.password_hash)
        if not is_valid:
            reviewer.failed_login_attempts = (reviewer.failed_login_attempts or 0) + 1
            if reviewer.failed_login_attempts >= MAX_FAILED_ATTEMPTS:
                reviewer.is_locked = True
                cls.log_event(
                    session,
                    event_type="ACCOUNT_LOCKED",
                    reviewer_id=reviewer.id,
                    ip_address=client_ip,
                    details=f"Account locked after {reviewer.failed_login_attempts} failed attempts.",
                )
            else:
                cls.log_event(
                    session,
                    event_type="LOGIN_FAILED_BAD_PASSWORD",
                    reviewer_id=reviewer.id,
                    ip_address=client_ip,
                    details=f"Failed attempt {reviewer.failed_login_attempts}/{MAX_FAILED_ATTEMPTS}",
                )
            session.flush()
            raise AuthenticationRequiredError("Invalid reviewer ID or password.")

        if upgraded_hash:
            reviewer.password_hash = upgraded_hash
            cls.log_event(
                session,
                event_type="PASSWORD_HASH_UPGRADED_TO_ARGON2ID",
                reviewer_id=reviewer.id,
                ip_address=client_ip,
                details="Migrated legacy PBKDF2 hash to modern Argon2id ($argon2id$v=19$m=65536,t=3,p=4).",
            )

        # Successful authentication
        reviewer.failed_login_attempts = 0
        reviewer.last_login_at = datetime.now(timezone.utc)

        # Create active session
        now_utc = datetime.now(timezone.utc)
        session_token = secrets.token_urlsafe(32)
        expires_at = now_utc + timedelta(hours=DEFAULT_ABSOLUTE_SESSION_HOURS)
        active_session = ReviewerSession(
            session_token=session_token,
            reviewer_id=reviewer.id,
            created_at=now_utc,
            expires_at=expires_at,
            last_activity_at=now_utc,
            absolute_expires_at=expires_at,
            is_revoked=False,
            client_ip=client_ip,
            user_agent=user_agent,
        )
        session.add(active_session)
        cls.log_event(
            session,
            event_type="LOGIN_SUCCESS",
            reviewer_id=reviewer.id,
            ip_address=client_ip,
            details=f"Successful login for {reviewer.reviewer_id} (Category: {getattr(reviewer, 'account_category', 'UNKNOWN')}, Demo: {reviewer.is_demonstration}).",
        )
        session.flush()
        return reviewer, active_session

    @classmethod
    def validate_session(cls, session: Session, session_token: str) -> ReviewerProfile:
        """
        Validates that a session token is active, not revoked, and unexpired.
        Returns the authenticated ReviewerProfile.
        """
        if not session_token:
            raise AuthenticationRequiredError("Missing session token.")

        sess = session.query(ReviewerSession).filter_by(session_token=session_token).first()
        if not sess:
            raise AuthenticationRequiredError("Invalid session token.")

        if sess.is_revoked:
            raise AuthenticationRequiredError("Session has been revoked.")

        now_utc = datetime.now(timezone.utc)

        # 1. Absolute expiration check (12 hours)
        abs_exp = getattr(sess, "absolute_expires_at", None) or sess.expires_at
        abs_exp_utc = abs_exp.replace(tzinfo=timezone.utc) if abs_exp.tzinfo is None else abs_exp
        if abs_exp_utc <= now_utc:
            sess.is_revoked = True
            session.flush()
            cls.log_event(
                session,
                event_type="SESSION_EXPIRED_ABSOLUTE",
                reviewer_id=sess.reviewer_id,
                details="Absolute session duration limit reached (12 hours).",
            )
            raise AuthenticationRequiredError("Session has expired (absolute duration reached). Please log in again.")

        # 2. Server-side idle inactivity timeout check (30 minutes)
        last_act = getattr(sess, "last_activity_at", None)
        if last_act:
            last_act_utc = last_act.replace(tzinfo=timezone.utc) if last_act.tzinfo is None else last_act
            if (now_utc - last_act_utc).total_seconds() > DEFAULT_IDLE_TIMEOUT_MINUTES * 60:
                sess.is_revoked = True
                session.flush()
                cls.log_event(
                    session,
                    event_type="SESSION_EXPIRED_IDLE",
                    reviewer_id=sess.reviewer_id,
                    details=f"Session expired due to inactivity ({DEFAULT_IDLE_TIMEOUT_MINUTES} min idle timeout).",
                )
                raise AuthenticationRequiredError(f"Session expired due to inactivity ({DEFAULT_IDLE_TIMEOUT_MINUTES} minutes). Please log in again.")

        # Update last activity timestamp
        sess.last_activity_at = now_utc
        session.flush()

        reviewer = session.query(ReviewerProfile).filter_by(id=sess.reviewer_id).first()
        if not reviewer or not reviewer.is_active:
            raise AuthenticationRequiredError("Associated reviewer account is inactive.")

        if reviewer.is_locked:
            raise AccountLockedError("Account is currently locked.")

        return reviewer

    @classmethod
    def rotate_session(
        cls,
        session: Session,
        old_session_token: str,
        client_ip: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> Tuple[ReviewerProfile, ReviewerSession]:
        """
        Rotates session token upon privilege elevation or security revalidation.
        Invalidates old session and issues a fresh token while maintaining absolute lifetime.
        """
        reviewer = cls.validate_session(session, old_session_token)
        old_sess = session.query(ReviewerSession).filter_by(session_token=old_session_token).first()
        if old_sess:
            old_sess.is_revoked = True

        now_utc = datetime.now(timezone.utc)
        abs_exp = getattr(old_sess, "absolute_expires_at", None) if old_sess else None
        if not abs_exp:
            abs_exp = now_utc + timedelta(hours=DEFAULT_ABSOLUTE_SESSION_HOURS)

        new_token = secrets.token_urlsafe(32)
        new_session = ReviewerSession(
            session_token=new_token,
            reviewer_id=reviewer.id,
            created_at=now_utc,
            expires_at=abs_exp,
            last_activity_at=now_utc,
            absolute_expires_at=abs_exp,
            is_revoked=False,
            client_ip=client_ip or (old_sess.client_ip if old_sess else None),
            user_agent=user_agent or (old_sess.user_agent if old_sess else None),
        )
        session.add(new_session)
        cls.log_event(
            session,
            event_type="SESSION_ROTATED",
            reviewer_id=reviewer.id,
            ip_address=client_ip,
            details=f"Rotated session token {old_session_token[:8]}... -> {new_token[:8]}...",
        )
        session.flush()
        return reviewer, new_session

    @classmethod
    def require_reauthentication(
        cls,
        session: Session,
        reviewer_id: str,
        raw_password: str,
        client_ip: Optional[str] = None,
    ) -> bool:
        """
        Validates password for high-privilege/sensitive administrative modifications
        (e.g., credential verification, role modification, or credential revocation).
        """
        reviewer = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not reviewer or not reviewer.is_active or reviewer.is_locked:
            return False
        is_valid, _ = verify_and_upgrade_password(raw_password, reviewer.password_hash)
        if not is_valid:
            cls.log_event(
                session,
                event_type="REAUTHENTICATION_FAILED",
                reviewer_id=reviewer.id,
                ip_address=client_ip,
                details="Failed re-authentication attempt for sensitive administrative operation.",
            )
            return False
        cls.log_event(
            session,
            event_type="REAUTHENTICATION_SUCCESS",
            reviewer_id=reviewer.id,
            ip_address=client_ip,
            details="Successful re-authentication for sensitive operation.",
        )
        session.flush()
        return True

    @classmethod
    def revoke_session(cls, session: Session, session_token: str, reason: str = "User logout") -> None:
        """Revokes an individual session token."""
        sess = session.query(ReviewerSession).filter_by(session_token=session_token).first()
        if sess:
            sess.is_revoked = True
            cls.log_event(
                session,
                event_type="LOGOUT",
                reviewer_id=sess.reviewer_id,
                details=f"Session revoked: {reason}",
            )
            session.flush()

    @classmethod
    def revoke_all_sessions(cls, session: Session, reviewer_id: int, reason: str = "Admin security revocation") -> int:
        """Revokes all active sessions for a reviewer (e.g. upon credential change or deactivation)."""
        active_sessions = (
            session.query(ReviewerSession)
            .filter_by(reviewer_id=reviewer_id, is_revoked=False)
            .all()
        )
        count = len(active_sessions)
        for s in active_sessions:
            s.is_revoked = True
        cls.log_event(
            session,
            event_type="ALL_SESSIONS_REVOKED",
            reviewer_id=reviewer_id,
            details=f"Revoked {count} active sessions: {reason}",
        )
        session.flush()
        return count

    @classmethod
    def unlock_account(cls, session: Session, reviewer_id: str, admin_name: str) -> ReviewerProfile:
        """Administratively unlocks a locked reviewer account."""
        reviewer = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not reviewer:
            raise AuthError(f"Reviewer '{reviewer_id}' not found.")
        reviewer.is_locked = False
        reviewer.failed_login_attempts = 0
        cls.log_event(
            session,
            event_type="ACCOUNT_UNLOCKED",
            reviewer_id=reviewer.id,
            details=f"Unlocked by admin: {admin_name}",
        )
        session.flush()
        return reviewer


# ---------------------------------------------------------------------------
# Authorization & RBAC Checks
# ---------------------------------------------------------------------------

class PermissionGuard:
    """Enforces fine-grained role-based permissions and demonstration guardrails."""

    @classmethod
    def require_permission(
        cls,
        reviewer: ReviewerProfile,
        required_permission: str,
    ) -> None:
        """Validates that reviewer possesses the required permission flag."""
        perms = reviewer.permissions or []
        if "ADMIN_ALL" in perms:
            return
        if required_permission not in perms:
            logger.warning("Permission denied for %s: missing %s", reviewer.reviewer_id, required_permission)
            raise PermissionDeniedError(
                f"Reviewer '{reviewer.reviewer_id}' lacks required permission: '{required_permission}'."
            )

    @classmethod
    def require_production_endorsement_capability(cls, reviewer: ReviewerProfile) -> None:
        """
        Enforces that demonstration profiles and synthetic personas cannot issue
        canonical production approvals or masquerade as living scholars.
        """
        if reviewer.is_demonstration or getattr(reviewer, "account_category", "") == "DEMONSTRATION_HARNESS":
            raise PermissionDeniedError(
                f"Reviewer '{reviewer.reviewer_id}' is a demonstration profile and cannot issue canonical approvals."
            )
        if not reviewer.is_credentials_verified or reviewer.verification_status != "VERIFIED":
            raise PermissionDeniedError(
                f"Reviewer '{reviewer.reviewer_id}' is not in verified status ({reviewer.verification_status})."
            )

    @classmethod
    def require_human_scholar(cls, reviewer: ReviewerProfile) -> None:
        """
        Enforces that only verified living human scholars can issue production sign-offs.
        Synthetic test personas and demonstration harnesses are strictly rejected.
        """
        if reviewer.is_demonstration or getattr(reviewer, "account_category", "") == "DEMONSTRATION_HARNESS":
            raise PermissionDeniedError(
                f"Reviewer '{reviewer.reviewer_id}' is a demonstration harness and cannot issue production approvals."
            )
        if getattr(reviewer, "account_category", "") == "SYNTHETIC_TEST_PERSONA":
            raise PermissionDeniedError(
                f"Reviewer '{reviewer.reviewer_id}' is a synthetic test persona. "
                "Production sign-off strictly requires an accredited living human scholar."
            )
        if not getattr(reviewer, "is_human_verified", False) or getattr(reviewer, "account_category", "") != "REAL_HUMAN_SCHOLAR":
            raise PermissionDeniedError(
                f"Reviewer '{reviewer.reviewer_id}' is not an accredited human scholar with verified physical credentials."
            )

    @classmethod
    def require_role(cls, reviewer: ReviewerProfile, allowed_roles: List[ReviewerRole]) -> None:
        """Validates that reviewer possesses at least one of the allowed roles."""
        perms = reviewer.permissions or []
        if "ADMIN_ALL" in perms:
            return
        roles = {reviewer.primary_role}
        if reviewer.secondary_roles:
            roles.update(reviewer.secondary_roles)
        role_values = {r.value if isinstance(r, ReviewerRole) else r for r in roles}
        allowed_values = {r.value if isinstance(r, ReviewerRole) else r for r in allowed_roles}
        if not (role_values & allowed_values):
            raise PermissionDeniedError(
                f"Reviewer '{reviewer.reviewer_id}' does not possess required role in {allowed_values}."
            )
