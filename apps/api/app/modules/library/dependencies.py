"""Dependency wiring for the library module."""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.core.storage.base import StorageService
from app.core.storage.provider import get_storage_service
from app.db.session import get_db_session
from app.modules.library.repository import BookRepository
from app.modules.library.service import BookService


def get_book_repository(
    session: Annotated[AsyncSession, Depends(get_db_session)],
) -> BookRepository:
    """Provide a request-scoped book repository."""
    return BookRepository(session)


def get_book_service(
    repository: Annotated[BookRepository, Depends(get_book_repository)],
    storage: Annotated[StorageService, Depends(get_storage_service)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> BookService:
    """Provide the library service for the current request."""
    return BookService(
        repository,
        storage,
        max_upload_size_bytes=settings.max_upload_size_bytes,
    )


BookServiceDep = Annotated[BookService, Depends(get_book_service)]
