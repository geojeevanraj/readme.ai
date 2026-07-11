"""Tests for the operational endpoints."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

from app.db import session as db


async def test_health_returns_ok(client: AsyncClient) -> None:
    response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_version_reports_configured_metadata(client: AsyncClient) -> None:
    response = await client.get("/version")

    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "ReadMe.ai API (test)"
    assert body["version"] == "0.0.0-test"
    assert body["environment"] == "development"


async def test_readiness_ok_when_dependencies_healthy(
    client: AsyncClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def _healthy() -> bool:
        return True

    monkeypatch.setattr(db, "ping", _healthy)

    response = await client.get("/health/ready")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert {"name": "postgres", "healthy": True} in body["dependencies"]


async def test_readiness_degraded_when_dependency_down(
    client: AsyncClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def _unhealthy() -> bool:
        return False

    monkeypatch.setattr(db, "ping", _unhealthy)

    response = await client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["status"] == "degraded"


async def test_unknown_route_uses_error_envelope(client: AsyncClient) -> None:
    response = await client.get("/does-not-exist")

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "not_found"
    assert "request_id" in body["error"]
