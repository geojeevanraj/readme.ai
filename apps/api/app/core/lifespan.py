"""Application lifespan management.

Startup and shutdown hooks live here so :mod:`app.main` stays a thin composition
root. The database engine is disposed on shutdown to release its connection
pool cleanly.
"""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.config import get_settings
from app.core.logging import get_logger
from app.db.session import dispose_engine

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    """Manage process-wide startup and shutdown."""
    settings = get_settings()
    logger.info(
        "service.startup",
        extra={
            "service": settings.app_name,
            "version": settings.app_version,
            "environment": settings.app_env.value,
        },
    )
    try:
        yield
    finally:
        await dispose_engine()
        logger.info("service.shutdown")
