"""Local-filesystem implementation of :class:`StorageService`.

Objects are stored as files under a configured base directory, with the storage
key used as the relative path. Blocking file I/O is delegated to a worker thread
so the event loop is never blocked. Keys are validated to prevent path traversal
outside the base directory.
"""

from __future__ import annotations

import asyncio
from pathlib import Path


class LocalStorageService:
    """Stores objects on the local filesystem rooted at ``base_path``."""

    def __init__(self, base_path: str | Path) -> None:
        self._base_path = Path(base_path).resolve()

    def _resolve(self, key: str) -> Path:
        # Resolve and confirm the target stays within the base directory.
        target = (self._base_path / key).resolve()
        if self._base_path != target and self._base_path not in target.parents:
            raise ValueError(f"Storage key escapes the base directory: {key!r}")
        return target

    async def save(
        self,
        key: str,
        content: bytes,
        *,
        content_type: str | None = None,
    ) -> None:
        target = self._resolve(key)
        await asyncio.to_thread(self._write, target, content)

    @staticmethod
    def _write(target: Path, content: bytes) -> None:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)

    async def read(self, key: str) -> bytes:
        target = self._resolve(key)
        return await asyncio.to_thread(target.read_bytes)

    async def delete(self, key: str) -> None:
        target = self._resolve(key)
        await asyncio.to_thread(target.unlink, True)

    async def exists(self, key: str) -> bool:
        target = self._resolve(key)
        return await asyncio.to_thread(target.is_file)
