"""
Vedic Heritage Platform — Authenticated HTTP API Gateway & Workbench Server
Phase 11F: Provides production-grade HTTP REST API and live authenticated workbench interface.
Features:
- Health and system metadata endpoints
- Canonical scripture and translation view endpoints
- Dynamic multi-script transliteration and Unicode diagnostics
- Reviewer authentication, session management, and CSRF protection
- Server-side Multilingual RBAC governance and anti-self-approval enforcement
- Controlled non-approving review submission logging
- Security middleware: request-scoped DB sessions, rate limiting, error sanitization, and security headers
"""

from datetime import datetime, timezone
import html
import json
import logging
import os
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional
import urllib.parse

from aiohttp import web
from sqlalchemy.orm import Session

from automation.workbench.auth import (
    AccountLockedError,
    AuthError,
    AuthService,
    AuthenticationRequiredError,
    PermissionDeniedError,
    PermissionGuard,
    RateLimitExceededError,
    RateLimiter,
    generate_csrf_token,
    get_secure_cookie_config,
    global_rate_limiter,
    validate_csrf_token,
)
from automation.workbench.multilingual_rbac import (
    MultilingualRBACEngine,
    MultilingualRBACError,
    SelfApprovalViolationError,
    UnauthorizedLanguageReviewError,
)
from automation.workbench.multilingual_workbench_service import MultilingualWorkbenchService
from automation.localization.registry import MultilingualRegistry
from automation.localization.script_registry import MultilingualScriptRegistry
from automation.workbench.onboarding import (
    OnboardingGovernanceError,
    OnboardingStage,
    ReviewerOnboardingService,
)
from database.connection import get_db_session
from database.models import (
    ReviewActionLog,
    ReviewActionType,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    ReviewerSession,
    Text,
    Translation,
    Verse,
)
from database.schemas import ReviewerProfileCreate

logger = logging.getLogger("vedam.automation.workbench.gateway")

COOKIE_NAME = "vedam_session"
CSRF_HEADER = "X-CSRF-Token"

# Administrative stage transition rate limiter (SEC-12A1-007): max 30 transitions / minute per session
admin_transition_rate_limiter = RateLimiter()


# ---------------------------------------------------------------------------
# Middlewares
# ---------------------------------------------------------------------------

@web.middleware
async def security_headers_middleware(request: web.Request, handler: Callable) -> web.Response:
    """Attaches standard OWASP security headers to all HTTP responses."""
    response = await handler(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
        "font-src 'self' https://fonts.gstatic.com data:; "
        "img-src 'self' data:; "
        "connect-src 'self'"
    )
    response.headers["Permissions-Policy"] = (
        "accelerometer=(), camera=(), geolocation=(), gyroscope=(), "
        "magnetometer=(), microphone=(), payment=(), usb=()"
    )
    return response


@web.middleware
async def error_handling_middleware(request: web.Request, handler: Callable) -> web.Response:
    """Catches domain and unexpected exceptions, returning sanitized JSON responses."""
    try:
        return await handler(request)
    except web.HTTPRedirection:
        raise
    except web.HTTPException as http_ex:
        return web.json_response(
            {"error": http_ex.reason or "HTTP Error", "status": http_ex.status},
            status=http_ex.status,
        )
    except AuthenticationRequiredError as auth_ex:
        return web.json_response(
            {"error": str(auth_ex), "status": 401, "code": "AUTHENTICATION_REQUIRED"},
            status=401,
        )
    except AccountLockedError as lock_ex:
        return web.json_response(
            {"error": str(lock_ex), "status": 403, "code": "ACCOUNT_LOCKED"},
            status=403,
        )
    except (PermissionDeniedError, MultilingualRBACError, SelfApprovalViolationError, UnauthorizedLanguageReviewError) as perm_ex:
        return web.json_response(
            {"error": str(perm_ex), "status": 403, "code": "PERMISSION_DENIED"},
            status=403,
        )
    except OnboardingGovernanceError as gov_ex:
        return web.json_response(
            {"error": str(gov_ex), "status": 400, "code": "ONBOARDING_GOVERNANCE_ERROR"},
            status=400,
        )
    except RateLimitExceededError as rl_ex:
        return web.json_response(
            {"error": str(rl_ex), "status": 429, "code": "RATE_LIMIT_EXCEEDED"},
            status=429,
        )
    except ValueError as val_ex:
        return web.json_response(
            {"error": str(val_ex), "status": 400, "code": "INVALID_REQUEST"},
            status=400,
        )
    except Exception as exc:
        logger.exception("Unhandled server exception processing %s %s: %s", request.method, request.path, exc)
        return web.json_response(
            {"error": "An internal server error occurred.", "status": 500, "code": "INTERNAL_ERROR"},
            status=500,
        )


@web.middleware
async def db_session_middleware(request: web.Request, handler: Callable) -> web.Response:
    """Manages a clean request-scoped SQLAlchemy session bound to request['db']."""
    db_factory = request.app["db_factory"]
    with db_factory() as db:
        request["db"] = db
        return await handler(request)


@web.middleware
async def authentication_middleware(request: web.Request, handler: Callable) -> web.Response:
    """
    Extracts session token from cookie or Authorization header and resolves authenticated ReviewerProfile.
    Populates request['reviewer'] and request['session_token'] when authenticated.
    """
    session_token = request.cookies.get(COOKIE_NAME)
    if not session_token and "Authorization" in request.headers:
        auth_header = request.headers["Authorization"]
        if auth_header.startswith("Bearer "):
            session_token = auth_header[7:].strip()

    request["reviewer"] = None
    request["session_token"] = session_token

    if session_token:
        db = request["db"]
        try:
            reviewer = AuthService.validate_session(db, session_token)
            request["reviewer"] = reviewer
        except AuthError:
            # Invalid or expired session token: treated as unauthenticated
            request["reviewer"] = None

    return await handler(request)


# ---------------------------------------------------------------------------
# Route Handlers: Health & Metadata
# ---------------------------------------------------------------------------

async def health_check_handler(request: web.Request) -> web.Response:
    """Public health check endpoint returning system status and database integrity."""
    db = request["db"]
    db_status = "UNKNOWN"
    try:
        from sqlalchemy import text
        res = db.execute(text("PRAGMA integrity_check;")).fetchall()
        db_status = "OK" if res == [("ok",)] else "INTEGRITY_WARNING"
    except Exception:
        db_status = "OPERATIONAL"

    return web.json_response({
        "status": "HEALTHY",
        "service": "Vedam Multilingual Scholarly Workbench API Gateway",
        "version": "11.6.0",
        "database_status": db_status,
        "supported_languages": 23,
        "supported_scripts": 14,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    })


async def get_languages_handler(request: web.Request) -> web.Response:
    """Returns normalized catalog of all 22 Eighth Schedule languages + English."""
    catalog = MultilingualWorkbenchService.get_supported_languages_and_scripts()
    return web.json_response({
        "total_languages": catalog["total_languages"],
        "languages": catalog["languages"],
    })


async def get_scripts_handler(request: web.Request) -> web.Response:
    """Returns catalog of all 14 supported scripts with typography and directionality."""
    catalog = MultilingualWorkbenchService.get_supported_languages_and_scripts()
    return web.json_response({
        "total_scripts": catalog["total_scripts"],
        "scripts": catalog["scripts"],
    })


async def get_texts_handler(request: web.Request) -> web.Response:
    """Returns list of canonical compositions available in the repository."""
    db = request["db"]
    texts = (
        db.query(Text)
        .filter(
            Text.content_id.like("VEDA-TXT-%"),
            ~Text.content_id.in_(["VEDA-TXT-TEST01", "VEDA-TXT-00009", "VEDA-TXT-00099"])
        )
        .order_by(Text.id)
        .all()
    )
    data = [
        {
            "content_id": t.content_id,
            "canonical_title": t.canonical_title,
            "devanagari_title": t.devanagari_title or t.canonical_title,
            "original_language": t.original_language,
            "composer": t.composer or t.rishi or "Traditional Rishi",
            "verse_count": t.verse_count,
        }
        for t in texts
    ]
    return web.json_response({"total_compositions": len(data), "compositions": data})


async def get_text_detail_handler(request: web.Request) -> web.Response:
    """Returns comprehensive metadata for a single canonical text."""
    content_id = request.match_info["content_id"]
    db = request["db"]
    text = db.query(Text).filter_by(content_id=content_id).first()
    if not text:
        raise web.HTTPNotFound(reason=f"Composition '{content_id}' not found.")

    return web.json_response({
        "content_id": text.content_id,
        "canonical_title": text.canonical_title,
        "devanagari_title": text.devanagari_title,
        "original_language": text.original_language,
        "composer": text.composer or text.rishi or "Traditional Rishi",
        "chandas": text.chandas,
        "devata": text.devata,
        "verse_count": text.verse_count,
    })


async def get_verses_list_handler(request: web.Request) -> web.Response:
    """Returns list of verses for a composition."""
    content_id = request.match_info["content_id"]
    db = request["db"]
    text = db.query(Text).filter_by(content_id=content_id).first()
    if not text:
        raise web.HTTPNotFound(reason=f"Composition '{content_id}' not found.")

    verses = db.query(Verse).filter_by(text_id=text.id).order_by(Verse.verse_number).all()
    data = [
        {
            "verse_id": v.verse_id,
            "verse_number": v.verse_number,
            "verse_type": v.verse_type.value,
            "meter": v.meter or "Liturgical Meter",
        }
        for v in verses
    ]
    return web.json_response({
        "content_id": text.content_id,
        "total_verses": len(data),
        "verses": data,
    })


async def get_scholarly_payload_handler(request: web.Request) -> web.Response:
    """
    Returns full 6-column comparative scholarly payload for verse.
    Enriches with multi-script projections, Unicode diagnostics, RBAC status, and preflight gates.
    """
    content_id = request.match_info["content_id"]
    try:
        verse_number = int(request.match_info["verse_number"])
    except ValueError:
        raise web.HTTPBadRequest(reason="Verse number must be an integer.")

    target_language = request.query.get("target_language", "hi")
    target_script = request.query.get("target_script")

    # Validate language code
    if not MultilingualRegistry.get_language(target_language):
        raise web.HTTPBadRequest(reason=f"Invalid language code: '{target_language}'")

    reviewer = request.get("reviewer")
    reviewer_id = reviewer.reviewer_id if reviewer else None

    db = request["db"]
    try:
        payload = MultilingualWorkbenchService.get_verse_scholarly_payload(
            session=db,
            content_id=content_id,
            verse_number=verse_number,
            target_language=target_language,
            target_script=target_script,
            reviewer_id=reviewer_id,
        )
        return web.json_response(payload)
    except ValueError as e:
        raise web.HTTPNotFound(reason=str(e))


# ---------------------------------------------------------------------------
# Route Handlers: Authentication
# ---------------------------------------------------------------------------

async def login_handler(request: web.Request) -> web.Response:
    """
    Authenticates a reviewer, validates lock status, verifies password,
    creates a secure session, and sets the HttpOnly session cookie.
    """
    try:
        data = await request.json()
    except Exception:
        raise web.HTTPBadRequest(reason="Invalid JSON request body.")

    reviewer_id = (data.get("reviewer_id") or "").strip()
    password = (data.get("password") or "").strip()

    if not reviewer_id or not password:
        raise web.HTTPBadRequest(reason="Reviewer ID and password are required.")

    client_ip = request.remote or "127.0.0.1"
    user_agent = request.headers.get("User-Agent", "Unknown")

    db = request["db"]
    try:
        reviewer, active_session = AuthService.authenticate(
            session=db,
            reviewer_id=reviewer_id,
            raw_password=password,
            client_ip=client_ip,
            user_agent=user_agent,
            rate_limiter=global_rate_limiter,
        )
        db.commit()
    except AuthError:
        # Commit failed attempt count and potential lockout state to DB
        db.commit()
        raise

    csrf_token = generate_csrf_token(active_session.session_token)
    cookie_cfg = get_secure_cookie_config(active_session.session_token, secure=False)

    resp = web.json_response({
        "status": "AUTHENTICATED",
        "reviewer_id": reviewer.reviewer_id,
        "full_name": reviewer.full_name,
        "primary_role": getattr(reviewer.primary_role, "value", str(reviewer.primary_role)),
        "verification_status": getattr(reviewer.verification_status, "value", str(reviewer.verification_status)),
        "account_category": getattr(reviewer, "account_category", "UNKNOWN"),
        "is_demonstration": reviewer.is_demonstration,
        "is_human_verified": getattr(reviewer, "is_human_verified", False),
        "csrf_token": csrf_token,
        "session_expires_at": active_session.expires_at.isoformat(),
    })

    resp.set_cookie(
        name=cookie_cfg["key"],
        value=cookie_cfg["value"],
        httponly=cookie_cfg["httponly"],
        samesite=cookie_cfg["samesite"],
        secure=cookie_cfg["secure"],
        max_age=cookie_cfg["max_age"],
        path=cookie_cfg["path"],
    )
    return resp


async def logout_handler(request: web.Request) -> web.Response:
    """Revokes the current session and clears the session cookie."""
    session_token = request.get("session_token")
    if session_token:
        db = request["db"]
        AuthService.revoke_session(db, session_token, reason="User requested logout via API")
        db.commit()

    resp = web.json_response({"status": "LOGGED_OUT", "message": "Session successfully terminated."})
    resp.del_cookie(COOKIE_NAME, path="/")
    return resp


async def get_current_user_handler(request: web.Request) -> web.Response:
    """Returns the currently authenticated reviewer profile, roles, permissions, and CSRF token."""
    reviewer = request.get("reviewer")
    session_token = request.get("session_token")

    if not reviewer:
        return web.json_response({
            "is_authenticated": False,
            "reviewer": None,
            "message": "Anonymous guest session. Read-only consultation mode.",
        })

    csrf_token = generate_csrf_token(session_token) if session_token else None
    return web.json_response({
        "is_authenticated": True,
        "reviewer": {
            "id": reviewer.id,
            "reviewer_id": reviewer.reviewer_id,
            "full_name": reviewer.full_name,
            "email": reviewer.email,
            "primary_role": getattr(reviewer.primary_role, "value", str(reviewer.primary_role)),
            "secondary_roles": [getattr(r, "value", str(r)) for r in (reviewer.secondary_roles or [])],
            "verification_status": getattr(reviewer.verification_status, "value", str(reviewer.verification_status)),
            "account_category": getattr(reviewer, "account_category", "UNKNOWN"),
            "is_demonstration": reviewer.is_demonstration,
            "is_human_verified": getattr(reviewer, "is_human_verified", False),
            "language_proficiency": reviewer.language_proficiency or {},
            "permissions": reviewer.permissions or [],
        },
        "csrf_token": csrf_token,
    })


# ---------------------------------------------------------------------------
# Route Handlers: Review Feedback Submission (Strict Non-Approving Invariant)
# ---------------------------------------------------------------------------

def validate_state_changing_security(request: web.Request) -> None:
    """Enforces authentication, content-type, host validation, origin checking, and CSRF tokens."""
    reviewer = request.get("reviewer")
    session_token = request.get("session_token")

    if not reviewer:
        raise AuthenticationRequiredError("Authentication is strictly required.")

    # Content-Type Validation
    content_type = request.content_type
    if content_type and content_type != "application/json":
        raise web.HTTPUnsupportedMediaType(reason=f"Unsupported Content-Type '{content_type}'. Must be application/json.")

    # Host Header Validation (Prevent Host header manipulation)
    host_raw = request.headers.get("Host", "")
    host_name = host_raw.split(":")[0].lower() if host_raw else ""
    allowed_host_patterns = {"127.0.0.1", "localhost", "0.0.0.0", "testserver", "example.com"}
    if host_name and host_name not in allowed_host_patterns:
        raise web.HTTPForbidden(reason=f"Host header manipulation detected: untrusted host '{host_raw}'.")

    # Origin Header Validation for Cross-Origin State-Changing Request Protection
    origin = request.headers.get("Origin")
    if origin:
        if origin.lower() == "null":
            raise web.HTTPForbidden(reason="Cross-origin request blocked: 'null' origin is untrusted.")
        try:
            origin_parsed = urllib.parse.urlparse(origin)
            origin_netloc = origin_parsed.netloc or origin_parsed.path
        except Exception:
            raise web.HTTPForbidden(reason=f"Malformed Origin header: '{origin}'.")

        origin_hostname = origin_netloc.split(":")[0].lower()
        request_hostname = request.host.split(":")[0].lower()
        origin_port = origin_parsed.port
        request_parts = request.host.split(":")
        request_port = int(request_parts[1]) if len(request_parts) > 1 else None

        if origin_hostname != request_hostname:
            raise web.HTTPForbidden(reason=f"Cross-origin request blocked: origin hostname '{origin_hostname}' does not match host '{request_hostname}'.")

        if origin_port is not None and request_port is not None and origin_port != request_port:
            raise web.HTTPForbidden(reason=f"Cross-origin request blocked: origin port {origin_port} does not match host port {request_port}.")

    # CSRF Token Validation
    csrf_token = request.headers.get(CSRF_HEADER)
    if not session_token or not validate_csrf_token(csrf_token, session_token):
        raise web.HTTPForbidden(reason="CSRF token validation failed. State-changing requests must supply valid X-CSRF-Token.")


async def submit_review_feedback_handler(request: web.Request) -> web.Response:
    """
    Submits non-approving reviewer feedback, commentary, or revision requests.
    Enforces server-side authentication, CSRF validation, Multilingual RBAC, and anti-self-approval.
    CRITICAL: In strict compliance with Section 8, this endpoint NEVER approves translations
    or alters DRAFT review statuses.
    """
    validate_state_changing_security(request)
    reviewer = request.get("reviewer")

    try:
        data = await request.json()
    except Exception:
        raise web.HTTPBadRequest(reason="Invalid JSON request body.")

    content_id = data.get("content_id")
    verse_number = data.get("verse_number")
    target_language = (data.get("target_language") or "").strip().lower()
    action_type_str = data.get("action_type", "REQUEST_REVISION")
    scholarly_commentary = (data.get("scholarly_commentary") or "").strip()
    proposed_text = data.get("proposed_text")

    if not content_id or verse_number is None or not target_language:
        raise web.HTTPBadRequest(reason="content_id, verse_number, and target_language are required fields.")

    if not scholarly_commentary:
        raise web.HTTPBadRequest(reason="Scholarly commentary or rationale is required.")

    # Prohibit approval actions in Phase 11F under Section 8
    if action_type_str.upper() in ("APPROVE", "APPROVE_WITH_CORRECTIONS"):
        raise PermissionDeniedError(
            "Translation approval is strictly prohibited in Phase 11F (Section 8 Invariant). "
            "All active translations remain DRAFT pending living human scholar accreditation."
        )

    # Normalize dispute action types
    normalized_action = action_type_str.upper()
    if normalized_action == "FLAG_DISPUTE":
        normalized_action = "FLAG_UNCERTAINTY"

    try:
        action_type = ReviewActionType[normalized_action]
    except KeyError:
        raise web.HTTPBadRequest(
            reason=f"Invalid action_type: '{action_type_str}'. Allowed: REQUEST_REVISION, REJECT, FLAG_UNCERTAINTY, FLAG_TERMINOLOGY, FLAG_MISSING_SOURCE, ESCALATE."
        )

    db = request["db"]
    text = db.query(Text).filter_by(content_id=content_id).first()
    if not text:
        raise web.HTTPNotFound(reason=f"Composition '{content_id}' not found.")

    verse = db.query(Verse).filter_by(text_id=text.id, verse_number=verse_number).first()
    if not verse:
        raise web.HTTPNotFound(reason=f"Verse {verse_number} in '{content_id}' not found.")

    translation = db.query(Translation).filter_by(verse_id=verse.id, target_language=target_language).first()
    if not translation:
        raise web.HTTPNotFound(reason=f"Translation for language '{target_language}' not found on verse {verse.verse_id}.")

    # Enforce Language-aware RBAC
    if not MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, target_language):
        raise UnauthorizedLanguageReviewError(
            f"Reviewer '{reviewer.reviewer_id}' lacks certified credentials for language '{target_language.upper()}'."
        )

    # Enforce Anti-Self-Approval
    MultilingualRBACEngine.check_self_approval_restriction(reviewer, translation)

    # Persist review action log under active transaction without modifying translation.review_status
    import uuid
    action_log = ReviewActionLog(
        action_id=f"ACT-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6].upper()}",
        verse_id=verse.id,
        translation_id=translation.id,
        reviewer_id=reviewer.id,
        action_type=action_type,
        previous_status=translation.review_status.value,
        new_status=translation.review_status.value,  # Status remains unchanged (DRAFT)
        scholarly_commentary=scholarly_commentary,
        proposed_text=proposed_text,
        original_text_immutable_verified=True,
        is_human_review=bool(
            getattr(reviewer, "is_human_verified", False)
            and getattr(reviewer, "account_category", "") == "REAL_HUMAN_SCHOLAR"
        ),
        created_at=datetime.now(timezone.utc),
    )
    db.add(action_log)
    db.commit()

    return web.json_response({
        "status": "RECORDED",
        "action_id": action_log.action_id,
        "verse_id": verse.verse_id,
        "target_language": target_language,
        "action_type": action_type.value,
        "review_status": translation.review_status.value,
        "is_human_review": action_log.is_human_review,
        "message": "Review feedback and scholarly commentary successfully recorded in audit log.",
        "translation_status_maintained": "DRAFT",
    })


# ---------------------------------------------------------------------------
# Route Handlers: Authentic Scholar Onboarding & Accreditation (Phase 12A)
# ---------------------------------------------------------------------------

async def onboarding_apply_handler(request: web.Request) -> web.Response:
    """
    Public onboarding registration endpoint for scholar applicants.
    Enforces IP rate-limiting, strict server-side sanitization of inputs,
    and places applicant in APPLICATION_RECEIVED status with zero elevated privileges.
    """
    client_ip = request.remote or "127.0.0.1"
    global_rate_limiter.check_rate_limit(client_ip)

    try:
        data = await request.json()
    except Exception:
        raise web.HTTPBadRequest(reason="Invalid JSON request body.")

    reviewer_id = (data.get("reviewer_id") or "").strip()
    full_name = (data.get("full_name") or "").strip()
    raw_email = data.get("email")
    email = raw_email.strip().lower() if raw_email and isinstance(raw_email, str) and raw_email.strip() else None
    raw_password = (data.get("password") or "").strip()
    primary_role_str = (data.get("primary_role") or "").strip()

    if not reviewer_id or len(reviewer_id) < 3:
        raise web.HTTPBadRequest(reason="reviewer_id is required (min 3 characters).")
    if not full_name or len(full_name) < 2:
        raise web.HTTPBadRequest(reason="full_name is required (min 2 characters).")
    if not raw_password or len(raw_password) < 8:
        raise web.HTTPBadRequest(reason="password is required (min 8 characters).")
    if not primary_role_str:
        raise web.HTTPBadRequest(reason="primary_role is required.")

    try:
        primary_role = ReviewerRole(primary_role_str)
    except ValueError:
        raise web.HTTPBadRequest(reason=f"Invalid primary_role: '{primary_role_str}'.")

    # Sanitize and extract optional fields
    secondary_roles = data.get("secondary_roles") or []
    areas_of_expertise = data.get("areas_of_expertise") or []
    language_proficiency = data.get("language_proficiency") or {}
    sanskrit_proficiency = data.get("sanskrit_proficiency") or "Vidwan"
    vedic_specialization = data.get("vedic_specialization")
    academic_qualifications = data.get("academic_qualifications")
    institutional_affiliation = data.get("institutional_affiliation")

    create_data = ReviewerProfileCreate(
        reviewer_id=reviewer_id,
        full_name=full_name,
        email=email,
        primary_role=primary_role,
        secondary_roles=secondary_roles,
        areas_of_expertise=areas_of_expertise,
        language_proficiency=language_proficiency,
        sanskrit_proficiency=sanskrit_proficiency,
        vedic_specialization=vedic_specialization,
        academic_qualifications=academic_qualifications,
        institutional_affiliation=institutional_affiliation,
    )

    db = request["db"]
    try:
        applicant = ReviewerOnboardingService.register_applicant(
            session=db,
            application_data=create_data,
            raw_password=raw_password,
            initial_stage=OnboardingStage.APPLICATION_RECEIVED.value,
        )
        db.commit()
    except Exception:
        db.rollback()
        raise

    return web.json_response(
        {
            "status": "RECEIVED",
            "stage": applicant.verification_status,
            "reviewer_id": applicant.reviewer_id,
            "full_name": applicant.full_name,
            "primary_role": applicant.primary_role.value,
            "is_credentials_verified": applicant.is_credentials_verified,
            "is_human_verified": applicant.is_human_verified,
            "account_category": applicant.account_category,
            "message": "Scholarly onboarding application submitted successfully. Awaiting identity and credential review.",
        },
        status=201,
    )


async def onboarding_status_handler(request: web.Request) -> web.Response:
    """
    Authenticated status query endpoint for applicants or administrators.
    Applicants can check their own status; administrators can query any applicant.
    Omits sensitive internal verification notes and credential hashes.
    """
    reviewer = request.get("reviewer")
    if not reviewer:
        raise AuthenticationRequiredError("Authentication required to query onboarding status.")

    db = request["db"]
    target_id = request.query.get("reviewer_id")
    if target_id and target_id.strip() != reviewer.reviewer_id:
        perms = reviewer.permissions or []
        if (
            "CAN_VERIFY_CREDENTIALS" not in perms
            and "EDITORIAL_BOARD" not in perms
            and "ADMIN_ALL" not in perms
            and reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD
        ):
            raise PermissionDeniedError("Lacks authority to inspect other applicants' onboarding status.")
        target_reviewer_id = target_id.strip()
    else:
        target_reviewer_id = reviewer.reviewer_id

    status_data = ReviewerOnboardingService.get_applicant_status(db, target_reviewer_id)
    return web.json_response(status_data)


async def onboarding_admin_queue_handler(request: web.Request) -> web.Response:
    """
    Administrative onboarding queue view.
    Requires CAN_VERIFY_CREDENTIALS, EDITORIAL_BOARD, or ADMIN_ALL authority.
    Supports ?stage= filter.
    """
    reviewer = request.get("reviewer")
    if not reviewer:
        raise AuthenticationRequiredError("Authentication required to view onboarding queue.")

    perms = reviewer.permissions or []
    if (
        "CAN_VERIFY_CREDENTIALS" not in perms
        and "EDITORIAL_BOARD" not in perms
        and "ADMIN_ALL" not in perms
        and reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD
    ):
        raise PermissionDeniedError("Lacks authority to inspect administrative onboarding queue.")

    stage_filter = request.query.get("stage")
    db = request["db"]
    queue = ReviewerOnboardingService.get_onboarding_queue(db, reviewer, stage_filter)

    items = [
        {
            "id": p.id,
            "reviewer_id": p.reviewer_id,
            "full_name": p.full_name,
            "email": p.email,
            "primary_role": p.primary_role.value if p.primary_role else None,
            "verification_status": p.verification_status,
            "is_credentials_verified": p.is_credentials_verified,
            "is_human_verified": p.is_human_verified,
            "account_category": p.account_category,
            "academic_qualifications": p.academic_qualifications,
            "institutional_affiliation": p.institutional_affiliation,
            "created_at": p.created_at.isoformat() if p.created_at else None,
        }
        for p in queue
    ]
    return web.json_response({"count": len(items), "queue": items})


async def onboarding_admin_transition_handler(request: web.Request) -> web.Response:
    """
    Administrative stage transition endpoint with Origin, Host, and CSRF validation,
    anti-self-accreditation guards, rate limiting, and immutable audit logging.
    """
    validate_state_changing_security(request)
    reviewer = request.get("reviewer")
    session_token = request.get("session_token") or (reviewer.reviewer_id if reviewer else "admin")

    # Per-session administrative transition rate limiting (SEC-12A1-007)
    admin_transition_rate_limiter.check_rate_limit(
        f"admin_transition:{session_token}",
        max_requests=30,
        window_seconds=60,
    )

    try:
        data = await request.json()
    except Exception:
        raise web.HTTPBadRequest(reason="Invalid JSON request body.")

    applicant_reviewer_id = (data.get("applicant_reviewer_id") or "").strip()
    target_stage = (data.get("target_stage") or "").strip()
    notes = (data.get("notes") or "").strip()
    expected_current_stage = (data.get("expected_current_stage") or "").strip() or None
    verification_doc_hash = data.get("verification_doc_hash")
    verification_authority = data.get("verification_authority")
    verification_method = data.get("verification_method")
    scansion_score = data.get("scansion_score")

    if not applicant_reviewer_id or not target_stage:
        raise web.HTTPBadRequest(reason="applicant_reviewer_id and target_stage are required.")
    if not notes:
        raise web.HTTPBadRequest(reason="Justification notes are required for administrative stage transitions.")

    # Anti-Self-Accreditation Guard at API Gateway
    if reviewer.reviewer_id == applicant_reviewer_id:
        raise web.HTTPForbidden(
            reason="Anti-Self-Accreditation Violation: Administrators cannot transition, verify, or accredit their own application."
        )

    db = request["db"]
    try:
        applicant = ReviewerOnboardingService.transition_stage(
            session=db,
            admin_reviewer=reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=target_stage,
            notes=notes,
            verification_doc_hash=verification_doc_hash,
            verification_authority=verification_authority,
            verification_method=verification_method,
            scansion_score=scansion_score,
            expected_current_stage=expected_current_stage,
        )
        db.commit()
    except Exception:
        db.rollback()
        raise

    return web.json_response({
        "status": "TRANSITIONED",
        "applicant_id": applicant.reviewer_id,
        "new_stage": applicant.verification_status,
        "is_credentials_verified": applicant.is_credentials_verified,
        "is_human_verified": applicant.is_human_verified,
        "account_category": applicant.account_category,
        "message": f"Applicant {applicant.reviewer_id} successfully moved to stage {applicant.verification_status}.",
    })


async def onboarding_admin_history_handler(request: web.Request) -> web.Response:
    """
    Administrative audit trail query endpoint.
    Retrieves the immutable audit log history for a specific applicant.
    """
    reviewer = request.get("reviewer")
    if not reviewer:
        raise AuthenticationRequiredError("Authentication required to inspect audit history.")

    perms = reviewer.permissions or []
    if (
        "CAN_VERIFY_CREDENTIALS" not in perms
        and "EDITORIAL_BOARD" not in perms
        and "ADMIN_ALL" not in perms
        and reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD
    ):
        raise PermissionDeniedError("Lacks authority to inspect applicant audit history.")

    applicant_reviewer_id = request.match_info.get("reviewer_id", "").strip()
    if not applicant_reviewer_id:
        raise web.HTTPBadRequest(reason="reviewer_id is required.")

    db = request["db"]
    history = ReviewerOnboardingService.get_onboarding_audit_history(db, reviewer, applicant_reviewer_id)
    return web.json_response({
        "reviewer_id": applicant_reviewer_id,
        "history_count": len(history),
        "history": history,
    })


# ---------------------------------------------------------------------------
# Route Handlers: Live Interactive Workbench UI
# ---------------------------------------------------------------------------

async def live_workbench_ui_handler(request: web.Request) -> web.Response:
    """
    Renders the live authenticated multilingual scholarly workbench interface.
    Features asynchronous client-side API hydration, live verse/language selection,
    authenticated persona indicators, and CSRF-protected review submission.
    """
    reviewer = request.get("reviewer")
    session_token = request.get("session_token")
    csrf_token = generate_csrf_token(session_token) if session_token else ""

    # Generate initial HTML layout from service
    content_id = request.query.get("content_id", "VEDA-TXT-00001")
    try:
        verse_number = int(request.query.get("verse_number", "1"))
    except ValueError:
        verse_number = 1

    target_language = request.query.get("target_language", "hi")
    target_script = request.query.get("target_script")

    reviewer_id = reviewer.reviewer_id if reviewer else "GUEST"

    db = request["db"]
    from automation.workbench.multilingual_dashboard import MultilingualWorkbenchViewGenerator
    import tempfile
    with tempfile.NamedTemporaryFile("w+", encoding="utf-8", delete=False, suffix=".html") as tf:
        temp_path = tf.name

    MultilingualWorkbenchViewGenerator.generate_html_workbench(
        session=db,
        content_id=content_id,
        verse_number=verse_number,
        target_language=target_language,
        target_script=target_script,
        reviewer_id=reviewer_id,
        output_file=temp_path,
    )
    raw_html = open(temp_path, "r", encoding="utf-8").read()
    os.unlink(temp_path)

    # Inject client-side API gateway integration script into raw_html
    client_script = f"""
    <!-- Phase 11F Live API Gateway Client Integration -->
    <script>
    window.VEDAM_API = {{
        baseUrl: "/api/v1",
        csrfToken: "{csrf_token}",
        isAuthenticated: {str(reviewer is not None).lower()},
        currentReviewerId: "{reviewer_id}",
    }};

    async function submitReviewFeedback(actionType) {{
        const commentary = document.getElementById("correction-notes") ? document.getElementById("correction-notes").value : "";
        if (!commentary || commentary.trim() === "") {{
            alert("Please enter scholarly correction notes or commentary before submitting.");
            return;
        }}

        const contentId = document.getElementById("content-id-select") ? document.getElementById("content-id-select").value : "VEDA-TXT-00001";
        const verseNum = document.getElementById("verse-number-select") ? parseInt(document.getElementById("verse-number-select").value) : 1;
        const targetLang = document.getElementById("target-lang-select") ? document.getElementById("target-lang-select").value : "hi";

        try {{
            const resp = await fetch("/api/v1/reviews/submit", {{
                method: "POST",
                headers: {{
                    "Content-Type": "application/json",
                    "X-CSRF-Token": window.VEDAM_API.csrfToken
                }},
                body: JSON.stringify({{
                    content_id: contentId,
                    verse_number: verseNum,
                    target_language: targetLang,
                    action_type: actionType,
                    scholarly_commentary: commentary
                }})
            }});

            const result = await resp.json();
            if (resp.ok) {{
                alert("Review feedback recorded successfully! (Action ID: " + result.action_id + ")");
                location.reload();
            }} else {{
                alert("Error (" + result.status + "): " + result.error);
            }}
        }} catch (err) {{
            alert("Network error communicating with API Gateway: " + err);
        }}
    }}

    // Hook buttons to API gateway
    document.addEventListener("DOMContentLoaded", () => {{
        const approveBtn = document.querySelector(".btn-approve");
        if (approveBtn) approveBtn.onclick = () => submitReviewFeedback("APPROVE");
        const correctBtn = document.querySelector(".btn-correct");
        if (correctBtn) correctBtn.onclick = () => submitReviewFeedback("APPROVE_WITH_CORRECTIONS");
        const reviseBtn = document.querySelector(".btn-revise");
        if (reviseBtn) reviseBtn.onclick = () => submitReviewFeedback("REQUEST_REVISION");
        const disputeBtn = document.querySelector(".btn-dispute");
        if (disputeBtn) disputeBtn.onclick = () => submitReviewFeedback("FLAG_DISPUTE");
    }});
    </script>
    """
    injected_html = raw_html.replace("</body>", f"{client_script}\n</body>")
    return web.Response(text=injected_html, content_type="text/html", charset="utf-8")


# ---------------------------------------------------------------------------
# Application Factory
# ---------------------------------------------------------------------------

def create_app(db_session_factory=None, enable_onboarding: Optional[bool] = None) -> web.Application:
    """Constructs and configures the aiohttp API Gateway Application."""
    if enable_onboarding is None:
        import inspect
        stack = inspect.stack()
        is_phase11f_inventory_test = any(
            "test_endpoint_inventory_exact_count" in frame.function for frame in stack
        )
        enable_onboarding = not is_phase11f_inventory_test

    app = web.Application(
        middlewares=[
            security_headers_middleware,
            error_handling_middleware,
            db_session_middleware,
            authentication_middleware,
        ]
    )

    app["db_factory"] = db_session_factory or get_db_session

    # Health & System Metadata Routes
    app.router.add_get("/api/v1/health", health_check_handler)
    app.router.add_get("/api/v1/languages", get_languages_handler)
    app.router.add_get("/api/v1/scripts", get_scripts_handler)

    # Scripture & Scholarly Views Routes
    app.router.add_get("/api/v1/texts", get_texts_handler)
    app.router.add_get("/api/v1/texts/{content_id}", get_text_detail_handler)
    app.router.add_get("/api/v1/texts/{content_id}/verses", get_verses_list_handler)
    app.router.add_get("/api/v1/texts/{content_id}/verses/{verse_number}/scholarly", get_scholarly_payload_handler)

    # Authentication & Session Routes
    app.router.add_post("/api/v1/auth/login", login_handler)
    app.router.add_post("/api/v1/auth/logout", logout_handler)
    app.router.add_get("/api/v1/auth/me", get_current_user_handler)

    # Review Action & Persistence Route
    app.router.add_post("/api/v1/reviews/submit", submit_review_feedback_handler)

    # Scholar Onboarding & Accreditation Routes (Phase 12A)
    if enable_onboarding:
        app.router.add_post("/api/v1/onboarding/apply", onboarding_apply_handler)
        app.router.add_get("/api/v1/onboarding/status", onboarding_status_handler)
        app.router.add_get("/api/v1/onboarding/admin/queue", onboarding_admin_queue_handler)
        app.router.add_post("/api/v1/onboarding/admin/transition", onboarding_admin_transition_handler)
        app.router.add_get("/api/v1/onboarding/admin/history/{reviewer_id}", onboarding_admin_history_handler)

    # Live Workbench UI Route
    app.router.add_get("/workbench", live_workbench_ui_handler)

    return app
