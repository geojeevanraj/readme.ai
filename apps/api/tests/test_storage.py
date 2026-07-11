"""Tests for the local storage service."""

from __future__ import annotations

from pathlib import Path

import pytest

from app.core.storage.local import LocalStorageService


async def test_save_exists_and_delete_roundtrip(tmp_path: Path) -> None:
    storage = LocalStorageService(tmp_path)
    key = "users/abc/books/x.pdf"

    assert await storage.exists(key) is False

    await storage.save(key, b"hello", content_type="application/pdf")
    assert await storage.exists(key) is True
    assert (tmp_path / key).read_bytes() == b"hello"

    await storage.delete(key)
    assert await storage.exists(key) is False


async def test_delete_is_idempotent(tmp_path: Path) -> None:
    storage = LocalStorageService(tmp_path)

    # Deleting a non-existent key does not raise.
    await storage.delete("nope/missing.pdf")


async def test_rejects_path_traversal(tmp_path: Path) -> None:
    storage = LocalStorageService(tmp_path)

    with pytest.raises(ValueError):
        await storage.save("../escape.txt", b"x")
