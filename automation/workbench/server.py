"""
Vedic Heritage Platform — Scholarly Review Workbench Server Runner
CLI entry point for running the authenticated HTTP API Gateway & Multilingual Workbench server.
Usage:
    python -m automation.workbench.server [--host 127.0.0.1] [--port 8000]
"""

import argparse
import logging
import os
import sys
from aiohttp import web

from automation.workbench.gateway import create_app
from database.connection import get_db_session

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("vedam.workbench.server")


def main():
    parser = argparse.ArgumentParser(description="Vedam Multilingual Scholarly Workbench Server")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="Host interface to bind (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8000, help="Port to listen on (default: 8000)")
    args = parser.parse_args()

    app = create_app(db_session_factory=get_db_session)

    print("==========================================================================")
    print(" Vedic Heritage Platform — Multilingual Scholarly Workbench API Gateway")
    print(f" Server URL: http://{args.host}:{args.port}")
    print(f" Live Workbench: http://{args.host}:{args.port}/workbench")
    print(f" Health Check:   http://{args.host}:{args.port}/api/v1/health")
    print("==========================================================================")

    web.run_app(app, host=args.host, port=args.port, print=None)


if __name__ == "__main__":
    main()
