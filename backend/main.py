"""
FastAPI application for Vedam Platform Services.
Provides location-aware Hindu Panchangam calculations and astronomical endpoints.

Startup Command:
    python -m backend.main --host 0.0.0.0 --port 8000
    OR
    uvicorn backend.main:app --host 0.0.0.0 --port 8000
"""

import os
from datetime import datetime, timezone
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.panchangam.api import router as panchangam_router


app = FastAPI(
    title="Vedam Devotional Platform API",
    description="Astronomical Hindu Panchangam, Scripture, and Liturgical Services",
    version="1.0.0",
    docs_url="/docs",
    redoc_url=None,  # Disabled redundant documentation endpoint
)

# Configurable CORS for Flutter Web, development, and production origins
cors_origins_env = os.getenv("CORS_ORIGINS", "*")
allowed_origins = [o.strip() for o in cors_origins_env.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins if allowed_origins else ["*"],
    allow_credentials=True,
    allow_methods=["GET", "OPTIONS"],  # Panchangam API is strictly read-only
    allow_headers=["*"],
)

# Register Panchangam router
app.include_router(panchangam_router)


@app.get("/", tags=["Root"])
def root():
    return {
        "platform": "Vedam",
        "description": "Vedic Heritage & Devotional Platform Services",
        "status": "online",
        "docs_url": "/docs",
        "health_url": "/api/v1/health",
    }


@app.get("/api/v1/health", tags=["Health"])
def system_health():
    """Unified system health check endpoint."""
    return {
        "status": "healthy",
        "service": "vedam-api",
        "version": "1.0.0",
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "ephemeris_engine": "Astronomy Engine 2.1 (VSOP87/ELP2000-82, MIT License)",
        "governance_mode": "read_only_astronomical",
    }


def main():
    import argparse
    import uvicorn

    parser = argparse.ArgumentParser(description="Vedam Platform API Server")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="Host interface to bind (default: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=8000, help="Port to listen on (default: 8000)")
    parser.add_argument("--reload", action="store_true", help="Enable auto-reload for local development")
    args = parser.parse_args()

    print("==========================================================================")
    print(" Vedic Heritage Platform — Panchangam & Astronomical API Service")
    print(f" Binding: http://{args.host}:{args.port}")
    print(f" OpenAPI Docs: http://{args.host}:{args.port}/docs")
    print(f" Health Check: http://{args.host}:{args.port}/api/v1/health")
    print(f" Panchangam Daily: http://{args.host}:{args.port}/api/v1/panchangam/daily")
    print("==========================================================================")

    uvicorn.run("backend.main:app", host=args.host, port=args.port, reload=args.reload)


if __name__ == "__main__":
    main()
