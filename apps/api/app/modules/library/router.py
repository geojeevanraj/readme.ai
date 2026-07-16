"""HTTP routes for the library module."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, File, Form, UploadFile, status

from app.core.config import Settings, get_settings
from app.modules.auth.dependencies import CurrentUser
from app.modules.library.dependencies import BookServiceDep
from app.modules.library.schemas import BookListResponse, BookResponse
from app.modules.processing.dependencies import ProcessingTriggerDep

from typing import Annotated
from fastapi import Depends

router = APIRouter()


async def _read_upload_with_limit(file: UploadFile, max_bytes: int) -> bytes:
    """Read at most *max_bytes + 1* from the upload stream.

    Reading one byte beyond the configured limit lets the downstream service
    detect oversized payloads without buffering the entire file into memory.
    """
    return await file.read(max_bytes + 1)


@router.post(
    "",
    response_model=BookResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a book",
)
async def upload_book(
    user: CurrentUser,
    service: BookServiceDep,
    processing: ProcessingTriggerDep,
    settings: Annotated[Settings, Depends(get_settings)],
    file: UploadFile = File(..., description="The book file to upload."),
    title: str | None = Form(default=None, description="Optional display title."),
) -> BookResponse:
    """Upload a book file, create its library record, and begin processing.

    Processing is triggered through the :class:`ProcessingTrigger` seam (inline
    today, a background worker later) and never fails the upload — processing
    errors are recorded as the book's processing status.
    """
    content = await _read_upload_with_limit(file, settings.max_upload_size_bytes)
    book = await service.upload(
        user_id=user.id,
        filename=file.filename or "book",
        content=content,
        content_type=file.content_type,
        title=title,
    )
    response = BookResponse.model_validate(book)
    await processing.schedule(user.id, book.id)
    return response


@router.get("", response_model=BookListResponse, summary="List the user's books")
async def list_books(user: CurrentUser, service: BookServiceDep) -> BookListResponse:
    """Return all books owned by the current user."""
    books = await service.list_books(user.id)
    items = [BookResponse.model_validate(book) for book in books]
    return BookListResponse(items=items, total=len(items))


@router.get("/{book_id}", response_model=BookResponse, summary="Get a book")
async def get_book(
    book_id: uuid.UUID,
    user: CurrentUser,
    service: BookServiceDep,
) -> BookResponse:
    """Return a single book owned by the current user."""
    book = await service.get_book(user.id, book_id)
    return BookResponse.model_validate(book)


@router.delete(
    "/{book_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a book",
)
async def delete_book(
    book_id: uuid.UUID,
    user: CurrentUser,
    service: BookServiceDep,
) -> None:
    """Delete a book owned by the current user, including its stored file."""
    await service.delete_book(user.id, book_id)
