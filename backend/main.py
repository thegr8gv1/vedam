"""
FastAPI application for Vedam Platform Services.
Provides location-aware Hindu Panchangam calculations and astronomical endpoints.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.panchangam.api import router as panchangam_router


app = FastAPI(
    title="Vedam Devotional Platform API",
    description="Astronomical Hindu Panchangam, Scripture, and Liturgical Services",
    version="1.0.0",
)

# Enable CORS for Flutter Web (localhost:8089 or any origin) and mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(panchangam_router)


@app.get("/", tags=["Root"])
def root():
    return {
        "platform": "Vedam",
        "description": "Vedic Heritage & Devotional Platform Services",
        "status": "online",
        "docs_url": "/docs",
    }
