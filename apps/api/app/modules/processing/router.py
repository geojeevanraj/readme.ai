"""HTTP routes for the processing module.

Mounted under ``/api/v1/books/{book_id}`` alongside library/reader routes.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter

from app.core.errors import NotFoundError
from app.modules.auth.dependencies import CurrentUser
from app.modules.processing.dependencies import ProcessingServiceDep
from app.modules.processing.schemas import ProcessingStatusResponse

router = APIRouter()


@router.get(
    "/{book_id}/processing",
    response_model=ProcessingStatusResponse,
    summary="Get processing status",
)
async def get_processing_status(
    book_id: uuid.UUID,
    user: CurrentUser,
    service: ProcessingServiceDep,
) -> ProcessingStatusResponse:
    """Return the processing status and metadata for an owned book."""
    record = await service.get_status(user.id, book_id)
    if record is None:
        raise NotFoundError("This book has not been processed.")
    return ProcessingStatusResponse.model_validate(record)


@router.post(
    "/{book_id}/processing",
    response_model=ProcessingStatusResponse,
    summary="Re-run processing",
)
async def reprocess(
    book_id: uuid.UUID,
    user: CurrentUser,
    service: ProcessingServiceDep,
) -> ProcessingStatusResponse:
    """Re-run processing for an owned book (idempotent; replaces prior output)."""
    record = await service.process_book(user.id, book_id)
    return ProcessingStatusResponse.model_validate(record)
