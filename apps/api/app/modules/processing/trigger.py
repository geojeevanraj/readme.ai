"""Processing trigger — the seam between "a book was uploaded" and "process it".

Today the only implementation runs processing inline within the request. A
future ``QueuedProcessingTrigger`` can enqueue work for a background worker
instead; because callers depend on the :class:`ProcessingTrigger` protocol, that
change requires no edits at the call site (the library upload route).
"""

from __future__ import annotations

import uuid
from typing import Protocol

from app.modules.processing.service import ProcessingService


class ProcessingTrigger(Protocol):
    """Schedules processing for a freshly uploaded book."""

    async def schedule(self, user_id: uuid.UUID, book_id: uuid.UUID) -> None:
        """Begin (or enqueue) processing for the given book."""
        ...


class InlineProcessingTrigger:
    """Runs processing synchronously within the current request."""

    def __init__(self, service: ProcessingService) -> None:
        self._service = service

    async def schedule(self, user_id: uuid.UUID, book_id: uuid.UUID) -> None:
        await self._service.process_book(user_id, book_id)
