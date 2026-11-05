# PRODUCTION SECURITY ASSESSMENT & THREAT MODEL
**Phase**: Phase 9 Production Security Hardening  
**Document Reference**: `VEDAM-SEC-THREAT-2026-V1`  
**Standard Compliance Alignment**: OWASP Top 10 (2021/2024), NIST SP 800-63B, OWASP ASVS Level 2  
**Date**: 2026-11-04  

---

> [!WARNING]
> **Independent Penetration Testing Notice**: This assessment documents internal security engineering, automated regression testing, and defensive controls. **Internal unit/integration tests do NOT constitute an independent external penetration test or third-party security certification.** Formal production certification requires scheduled third-party CREST/OSCP accredited external testing prior to commercial public launch.

---

## 1. Executive Summary & Security Posture

Phase 9 implements an upgraded security baseline for the Vedam Vedic Knowledge Platform. The authentication engine has been transitioned from PBKDF2 to **Argon2id** (OWASP-recommended parameters: 64 MiB memory, 3 iterations, 4 lanes), cryptographically secure session rotation, sliding-window inactivity timeouts, absolute session expiration, and role-based access control with hard guardrails separating demonstration fixtures from verified human scholars.

---

## 2. Threat Modeling: STRIDE Matrix

| Threat Category (STRIDE) | Attack Vector / Scenario | Platform Mitigation & Security Controls | Verification Mechanism |
| :--- | :--- | :--- | :--- |
| **Spoofing (Identity)** | Adversary attempts brute-force credential stuffing or stolen session token replay. | • **Argon2id** password hashing (61.2 ms/hash, GPU-resistant).<br>• Progressive account lockout after 5 failed attempts.<br>• Sliding-window IP/Account rate limiting (max 10 requests / 60s).<br>• 256-bit entropy session tokens (`secrets.token_urlsafe(32)`).<br>• Server-side idle timeout (30 min) and absolute session expiration (12h). | Automated security tests in `test_phase9_human_review_and_ai_benchmark.py`. |
| **Tampering (Data)** | Adversary or malicious reviewer attempts to alter sacred Sanskrit texts or forge approval entries. | • Original Sanskrit/Awadhi texts are **strictly immutable** in the database engine and API.<br>• Corrections create version increments (`version + 1`) and immutable audit logs.<br>• Demonstration accounts cannot modify canonical states.<br>• Constant-time CSRF tokens tied to session tokens (`hmac.compare_digest`). | Database integrity triggers & `PermissionGuard` checks. |
| **Repudiation** | Scholar denies making a textual dispute, correction, or review approval. | • Immutable `ReviewActionLog` and `AuthAuditLog` entries with UTC timestamps, reviewer ID, client IP, previous text, proposed text, and rationale.<br>• Append-only ledger architecture. | Audit log validation tests. |
| **Information Disclosure** | Public API exposes private reviewer identities, personal phone numbers, or administrative notes. | • Public API sanitizes all PII (`email`, `institutional_affiliation`, `verification_doc_hash` stripped from `ReviewerProfilePublicRead`).<br>• Database backups stored in restricted directory with SHA-256 integrity checksums. | Schema serialization unit tests. |
| **Denial of Service** | Automated bots flood authentication endpoints or translation review queries. | • In-memory sliding window `RateLimiter` rejecting requests exceeding 10/min.<br>• Account lockout preventing continuous password guessing. | Concurrency and rate limit unit tests. |
| **Elevation of Privilege** | Demonstration account or unverified applicant attempts to issue production approval or export. | • `PermissionGuard.require_human_scholar` blocks non-human accounts.<br>• `PermissionGuard.require_production_endorsement_capability` blocks unverified and demo users.<br>• Publication Gate enforces independent orthogonal legal, editorial, and scholar sign-offs. | Negative authorization tests in pytest suite. |

---

## 3. Cryptographic Controls Evaluation

### A. Password Hashing Benchmark & Selection

| Algorithm | Parameter Configuration | Benchmark Latency (Environment) | GPU / ASIC Resistance | Selection Status |
| :--- | :--- | :---: | :---: | :--- |
| **Argon2id** | $m=65536\text{ KiB}$ (64 MiB), $t=3$, $p=4$, 16-byte salt, 32-byte key | **61.19 ms** | **Exceptional** (Memory-hard) | **PRIMARY (OWASP Gold Standard)** |
| **PBKDF2-HMAC-SHA256** | 600,000 iterations, 16-byte salt | 228.04 ms | Moderate (Vulnerable to specialized ASICs) | Fallback / Migration Source |
| **Legacy PBKDF2** | 100,000 iterations (Phase 8) | 38.10 ms | Moderate | Deprecated / Automatic Upgrade |

- **Safe Migration Strategy**: When a user authenticates with an existing Phase 8 PBKDF2 hash, the credentials are authenticated and their password hash is immediately and transparently upgraded to modern Argon2id without exposing plaintext.

### B. Session Architecture & Cookie Security

```mermaid
sequenceDiagram
    autonumber
    actor Scholar as Scholar Browser
    participant API as Workbench Auth API
    participant DB as SQLite / Alembic DB

    Scholar->>API: POST /api/workbench/login (credentials)
    API->>DB: Check lockout & verify Argon2id hash
    API->>DB: Create ReviewerSession (256-bit token, 12h absolute, 30m idle)
    API-->>Scholar: Set-Cookie: vedam_session; HttpOnly; SameSite=Strict; Secure; Max-Age=43200
    
    loop Active Review Session
        Scholar->>API: GET /api/workbench/verse (with session cookie & CSRF header)
        API->>DB: Verify session (idle < 30m, absolute < 12h)
        API->>DB: Update last_activity_at = NOW()
        API-->>Scholar: 200 OK (sanitized comparison payload)
    end

    Note over Scholar,API: Inactivity > 30 minutes
    Scholar->>API: POST /api/workbench/review/action
    API->>DB: Inactivity detected (> 30 min)
    API->>DB: Mark session is_revoked = True
    API-->>Scholar: 401 Unauthorized (Session Expired Due to Inactivity)
```

---

## 4. Vulnerability Assessment & Mitigation Strategy

1. **SQL Injection**:
   - *Control*: 100% of queries use SQLAlchemy ORM parameter binding or explicit parameterized text expressions. Zero string concatenation in SQL execution.
2. **Cross-Site Scripting (XSS)**:
   - *Control*: Content served in the 6-column review dashboard utilizes HTML escaping and strictly separates structured JSON from visual HTML components.
3. **Cross-Site Request Forgery (CSRF)**:
   - *Control*: Stateful endpoints validate HMAC-SHA256 tokens tied to the active session token using constant-time comparison (`secrets.compare_digest`).
4. **Secret Management**:
   - *Control*: Application secrets (`VEDAM_AUTH_SECRET`) are loaded from environment variables with fallback to local development defaults. In production deployments, secrets must be provisioned via hardware security modules (HSM) or cloud secret managers.

---

## 5. Certification Boundary & External Testing Roadmap

The platform security controls implemented in Phase 9 meet internal security baseline requirements. However, **production certification is explicitly contingent upon the following pre-launch milestones**:

1. [ ] Static Application Security Testing (SAST) automated pipeline scan.
2. [ ] Software Bill of Materials (SBOM) dependency scan verifying 0 critical CVEs.
3. [ ] Independent third-party manual application penetration test.
4. [ ] Production TLS termination validation (HSTS, TLS 1.3, CSP headers).
