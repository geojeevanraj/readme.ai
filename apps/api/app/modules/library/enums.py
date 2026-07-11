"""Enumerations for the library module."""

from __future__ import annotations

from enum import StrEnum


class BookStatus(StrEnum):
    """Lifecycle state of a book.

    Only ``UPLOADING``/``UPLOADED`` are reached in the Library Foundation; the
    processing states are reserved for later sprints and carry no behaviour yet.
    """

    UPLOADING = "UPLOADING"
    UPLOADED = "UPLOADED"
    PROCESSING = "PROCESSING"
    READY = "READY"
    FAILED = "FAILED"
