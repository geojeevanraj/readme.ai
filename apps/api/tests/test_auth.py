"""Tests for the authentication module."""

from __future__ import annotations

from httpx import AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.modules.auth.models import User
from tests.conftest import INVALID_TOKEN, FakeTokenVerifier

_AUTH = {"Authorization": "Bearer valid-token"}


async def test_me_provisions_user_on_first_request(
    client: AsyncClient,
    identity,
) -> None:
    response = await client.get("/api/v1/auth/me", headers=_AUTH)

    assert response.status_code == 200
    body = response.json()
    assert body["email"] == identity.email
    assert body["display_name"] == identity.display_name
    assert body["photo_url"] == identity.photo_url
    assert body["id"]
    assert body["created_at"]
    assert body["last_login_at"]


async def test_me_does_not_duplicate_existing_user(
    client: AsyncClient,
    sessionmaker: async_sessionmaker[AsyncSession],
) -> None:
    first = await client.get("/api/v1/auth/me", headers=_AUTH)
    second = await client.get("/api/v1/auth/me", headers=_AUTH)

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["id"] == second.json()["id"]

    async with sessionmaker() as session:
        count = await session.scalar(select(func.count()).select_from(User))
    assert count == 1


async def test_me_requires_authentication(client: AsyncClient) -> None:
    response = await client.get("/api/v1/auth/me")

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


async def test_me_rejects_invalid_token(client: AsyncClient) -> None:
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {INVALID_TOKEN}"},
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


async def test_logout_succeeds_when_authenticated(client: AsyncClient) -> None:
    response = await client.post("/api/v1/auth/logout", headers=_AUTH)

    assert response.status_code == 200
    assert response.json()["detail"]


async def test_logout_requires_authentication(client: AsyncClient) -> None:
    response = await client.post("/api/v1/auth/logout")

    assert response.status_code == 401


async def test_token_is_verified_on_every_request(
    client: AsyncClient,
    verifier: FakeTokenVerifier,
) -> None:
    await client.get("/api/v1/auth/me", headers=_AUTH)
    await client.get("/api/v1/auth/me", headers=_AUTH)

    # The client is never trusted: the token is validated on each request.
    assert verifier.verify_calls == 2
