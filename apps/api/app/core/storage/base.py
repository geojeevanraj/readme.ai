"""Storage service contract.

The contract is intentionally minimal — store, delete, and existence — which is
all the Library Foundation requires and is satisfiable by both a local
filesystem and a future object store (e.g. Cloudflare R2).
"""

from __future__ import annotations

from typing import Protocol, runtime_checkable


@runtime_checkable
class StorageService(Protocol):
    """Stores and removes opaque binary objects addressed by a string key."""

    async def save(
        self,
        key: str,
        content: bytes,
        *,
        content_type: str | None = None,
    ) -> None:
        """Persist ``content`` under ``key``, overwriting any existing object."""
        ...

    async def read(self, key: str) -> bytes:
        """Return the bytes stored at ``key``. Raises if the object is absent."""
        ...

    async def delete(self, key: str) -> None:
        """Remove the object at ``key``. A missing object is not an error."""
        ...

    async def exists(self, key: str) -> bool:
        """Return whether an object exists at ``key``."""
        ...
