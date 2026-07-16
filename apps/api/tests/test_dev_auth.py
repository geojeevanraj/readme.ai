"""Tests for Development Authentication Mode (DEV_AUTH)."""

from __future__ import annotations

from collections.abc import AsyncIterator

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Environment, LogFormat, LogLevel, Settings
from app.db.session import get_db_session
from app.main import create_app
from app.modules.auth.dependencies import get_token_verifier
from app.modules.auth.verifier import (
    DevelopmentTokenVerifier,
    FirebaseTokenVerifier,
)

_DEV_TOKEN = {"Authorization": "Bearer development-token"}


def _settings(*, dev_auth: bool) -> Settings:
    return Settings(
        APP_ENV=Environment.DEVELOPMENT,
        LOG_LEVEL=LogLevel.WARNING,
        LOG_FORMAT=LogFormat.CONSOLE,
        FIREBASE_PROJECT_ID="",
        DEV_AUTH=dev_auth,
    )


async def _client(
    sessionmaker: async_sessionmaker[AsyncSession],
    *,
    dev_auth: bool,
) -> AsyncIterator[AsyncClient]:
    # Real token verifier (not overridden) so the DEV_AUTH selection is tested.
    app = create_app(settings=_settings(dev_auth=dev_auth))

    async def _override_session() -> AsyncIterator[AsyncSession]:
        async with sessionmaker() as session:
            yield session

    app.dependency_overrides[get_db_session] = _override_session
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


def test_verifier_selection_by_flag() -> None:
    assert isinstance(
        get_token_verifier(_settings(dev_auth=True)), DevelopmentTokenVerifier
    )
    assert isinstance(
        get_token_verifier(_settings(dev_auth=False)), FirebaseTokenVerifier
    )


async def test_dev_token_authenticates_mock_user_when_enabled(
    sessionmaker: async_sessionmaker[AsyncSession],
) -> None:
    async for client in _client(sessionmaker, dev_auth=True):
        response = await client.get("/api/v1/auth/me", headers=_DEV_TOKEN)

        assert response.status_code == 200
        body = response.json()
        assert body["email"] == "geo.dev@readme.ai"
        assert body["display_name"] == "Geo (Development)"


async def test_dev_token_rejected_when_disabled(
    sessionmaker: async_sessionmaker[AsyncSession],
) -> None:
    async for client in _client(sessionmaker, dev_auth=False):
        response = await client.get("/api/v1/auth/me", headers=_DEV_TOKEN)

        # Falls through to production Firebase verification -> rejected.
        assert response.status_code == 401


@pytest.mark.parametrize("token", ["wrong-token", "development-token-2"])
async def test_only_exact_dev_token_accepted(
    sessionmaker: async_sessionmaker[AsyncSession],
    token: str,
) -> None:
    async for client in _client(sessionmaker, dev_auth=True):
        response = await client.get(
            "/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"}
        )

        assert response.status_code == 401
