"""The processor interface and processing error type."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from app.modules.processing.document import StructuredDocument
from app.modules.processing.enums import ProcessingErrorCode


class ProcessingError(Exception):
    """A structured, recoverable processing failure.

    Carries a stable :class:`ProcessingErrorCode` so failures are reported
    consistently and can drive UI without string matching.
    """

    def __init__(self, code: ProcessingErrorCode, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


@runtime_checkable
class BookProcessor(Protocol):
    """Converts a raw file of a supported format into a structured document."""

    @property
    def name(self) -> str:
        """Stable processor identifier, persisted with the result."""
        ...

    def supports(self, *, mime_type: str, filename: str) -> bool:
        """Return whether this processor can handle the given file."""
        ...

    def process(
        self,
        *,
        filename: str,
        mime_type: str,
        data: bytes,
    ) -> StructuredDocument:
        """Produce a structured document, or raise :class:`ProcessingError`."""
        ...
