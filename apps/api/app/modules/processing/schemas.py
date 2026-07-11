"""Pydantic schemas for the processing module."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.modules.processing.enums import ProcessingStatus


class ProcessingStatusResponse(BaseModel):
    """Processing status and extracted metadata for a book."""

    model_config = ConfigDict(from_attributes=True)

    book_id: uuid.UUID = Field(description="The book this record describes.")
    status: ProcessingStatus = Field(description="Current processing status.")
    processor_name: str | None = Field(
        default=None, description="Processor that produced the document."
    )
    title: str | None = Field(default=None, description="Detected title.")
    author: str | None = Field(default=None, description="Detected author.")
    language: str | None = Field(default=None, description="Detected language.")
    page_count: int | None = Field(default=None, description="Page count, if known.")
    word_count: int = Field(description="Total words in the document.")
    character_count: int = Field(description="Total characters in the document.")
    estimated_reading_minutes: int | None = Field(
        default=None, description="Estimated reading time in minutes."
    )
    error_code: str | None = Field(
        default=None, description="Structured error code when failed."
    )
    error_message: str | None = Field(
        default=None, description="Human-readable failure detail."
    )
    processed_at: datetime | None = Field(
        default=None, description="When processing last completed or failed."
    )
