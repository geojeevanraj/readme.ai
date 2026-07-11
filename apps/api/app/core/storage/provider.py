"""Storage service provider (dependency injection).

Resolves the configured :class:`StorageService` implementation. This is the only
place that knows which concrete backend is in use, so swapping LocalStorageService
for a future CloudflareStorageService is a change here alone — no business module
is affected.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Annotated

from fastapi import Depends

from app.core.config import Settings, StorageBackend, get_settings
from app.core.storage.base import StorageService
from app.core.storage.local import LocalStorageService


@lru_cache(maxsize=1)
def _local_storage(base_path: str) -> LocalStorageService:
    return LocalStorageService(base_path)


def get_storage_service(
    settings: Annotated[Settings, Depends(get_settings)],
) -> StorageService:
    """Provide the configured storage service.

    Overridden in tests with an in-memory fake.
    """
    if settings.storage_backend is StorageBackend.LOCAL:
        return _local_storage(settings.storage_local_path)
    # R2 is a documented extension point, not implemented this sprint.
    raise NotImplementedError("Cloudflare R2 storage is not implemented yet.")
