"""Object storage abstraction.

Defines the :class:`StorageService` contract and its local-filesystem
implementation. Callers depend on the protocol (resolved via
:func:`app.core.storage.provider.get_storage_service`), so the backend can be
swapped (e.g. to Cloudflare R2) without changing any business module.
"""

from app.core.storage.base import StorageService
from app.core.storage.local import LocalStorageService

__all__ = ["LocalStorageService", "StorageService"]
