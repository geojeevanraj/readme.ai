"""Tests for the Learning Intelligence Engine foundation."""

from __future__ import annotations

import uuid

import pytest
from httpx import AsyncClient

from app.modules.learning.capabilities.prerequisite import PrerequisiteCapability
from app.modules.learning.capability import (
    CapabilityContext,
    CapabilityOutcome,
)
from app.modules.learning.engine import LearningIntelligenceEngine
from app.modules.learning.registry import CapabilityRegistry

_AUTH = {"Authorization": "Bearer valid-token"}
_BOOKS = "/api/v1/books"
_TEXT = b"Gradient descent optimizes the model.\n\nA plain unrelated paragraph."


def _context(text: str) -> CapabilityContext:
    return CapabilityContext(
        user_id=uuid.uuid4(), book_id=uuid.uuid4(), selected_text=text
    )


# --- Registry & capability ------------------------------------------------
def test_registry_holds_registered_capabilities() -> None:
    registry = CapabilityRegistry()
    capability = PrerequisiteCapability()
    registry.register(capability)

    assert registry.capabilities == [capability]


async def test_prerequisite_capability_returns_concepts() -> None:
    capability = PrerequisiteCapability()

    outcome = await capability.evaluate(_context("Understanding gradient descent"))

    names = {p.name for p in outcome.prerequisites}
    assert "Derivative" in names
    assert "Learning rate" in names


async def test_prerequisite_capability_empty_when_no_match() -> None:
    capability = PrerequisiteCapability()

    outcome = await capability.evaluate(_context("an ordinary sentence"))

    assert outcome.prerequisites == []


# --- Engine ---------------------------------------------------------------
class _StubExplanationService:
    """Minimal stand-in exposing the same explain() contract."""

    def __init__(self) -> None:
        from app.modules.explanation.enums import SelectionType
        from app.modules.explanation.schemas import ExplanationResponse

        self._response = ExplanationResponse(
            selection_type=SelectionType.WORD, explanation="ok"
        )
        self.called = False

    async def explain(self, **_: object) -> object:
        self.called = True
        return self._response


async def test_engine_aggregates_capability_results() -> None:
    registry = CapabilityRegistry()
    registry.register(PrerequisiteCapability())
    service = _StubExplanationService()
    engine = LearningIntelligenceEngine(registry, service)  # type: ignore[arg-type]

    response = await engine.explain(
        user_id=uuid.uuid4(),
        book_id=uuid.uuid4(),
        anchor="0",
        end_anchor="5",
        selected_text="gradient descent",
    )

    assert service.called is True
    assert {p.name for p in response.prerequisites} >= {"Derivative"}


async def test_engine_survives_a_failing_capability() -> None:
    class _Boom:
        name = "boom"

        async def evaluate(self, context: CapabilityContext) -> CapabilityOutcome:
            raise RuntimeError("nope")

    registry = CapabilityRegistry()
    registry.register(_Boom())
    service = _StubExplanationService()
    engine = LearningIntelligenceEngine(registry, service)  # type: ignore[arg-type]

    response = await engine.explain(
        user_id=uuid.uuid4(),
        book_id=uuid.uuid4(),
        anchor="0",
        end_anchor="5",
        selected_text="anything",
    )

    assert response.prerequisites == []
    assert service.called is True


# --- API compatibility ----------------------------------------------------
async def _upload(client: AsyncClient) -> tuple[str, str]:
    response = await client.post(
        _BOOKS, headers=_AUTH, files={"file": ("book.txt", _TEXT, "text/plain")}
    )
    book_id = response.json()["id"]
    content = await client.get(f"{_BOOKS}/{book_id}/content", headers=_AUTH)
    return book_id, content.json()["content"]


async def test_response_includes_prerequisites_when_present(
    client: AsyncClient,
) -> None:
    book_id, content = await _upload(client)
    phrase = "Gradient descent"
    start = content.index(phrase)

    response = await client.post(
        f"{_BOOKS}/{book_id}/explain",
        headers=_AUTH,
        json={
            "anchor": str(start),
            "end_anchor": str(start + len(phrase)),
            "selected_text": phrase,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["explanation"]
    assert any(p["name"] == "Derivative" for p in body["prerequisites"])


async def test_response_prerequisites_empty_when_none(
    client: AsyncClient,
) -> None:
    book_id, content = await _upload(client)
    phrase = "plain"
    start = content.index(phrase)

    response = await client.post(
        f"{_BOOKS}/{book_id}/explain",
        headers=_AUTH,
        json={
            "anchor": str(start),
            "end_anchor": str(start + len(phrase)),
            "selected_text": phrase,
        },
    )

    assert response.status_code == 200
    assert response.json()["prerequisites"] == []


@pytest.mark.parametrize("missing_token", [True, False])
async def test_endpoint_contract_unchanged(
    client: AsyncClient, missing_token: bool
) -> None:
    book_id, _ = await _upload(client)
    headers = {} if missing_token else _AUTH

    response = await client.post(
        f"{_BOOKS}/{book_id}/explain",
        headers=headers,
        json={"anchor": "0", "end_anchor": "5", "selected_text": "Gradient"},
    )

    assert response.status_code == (401 if missing_token else 200)
