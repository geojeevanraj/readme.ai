"""Enumerations for the processing module."""

from __future__ import annotations

from enum import StrEnum


class ProcessingStatus(StrEnum):
    """Lifecycle of a book's processing.

    ``QUEUED`` and ``PROCESSING`` exist to support a future background-worker
    pipeline without redesign; the current inline trigger moves a book
    ``QUEUED -> PROCESSING -> COMPLETED|FAILED`` within the request.
    """

    QUEUED = "QUEUED"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class ProcessingErrorCode(StrEnum):
    """Stable, structured reasons a book failed to process."""

    UNSUPPORTED_FORMAT = "unsupported_format"
    MALFORMED_FILE = "malformed_file"
    EMPTY_DOCUMENT = "empty_document"
    TOO_LARGE = "too_large"
    TIMEOUT = "timeout"
    INTERNAL = "internal_error"
