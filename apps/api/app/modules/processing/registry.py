"""Processor registry — selects a processor for a file (the dispatcher).

The reader and service depend on this registry, never on a concrete processor.
Registering a future PDF/EPUB/DOCX/OCR processor is the only change needed to
support a new format.
"""

from __future__ import annotations

from app.modules.processing.processors.base import BookProcessor


class ProcessorRegistry:
    """Holds the available processors and selects one for a given file."""

    def __init__(self, processors: list[BookProcessor]) -> None:
        self._processors = processors

    def select(self, *, mime_type: str, filename: str) -> BookProcessor | None:
        """Return the first processor that supports the file, or ``None``."""
        for processor in self._processors:
            if processor.supports(mime_type=mime_type, filename=filename):
                return processor
        return None
