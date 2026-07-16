"""Tests for the unified explanation endpoint (classification + strategies)."""

from __future__ import annotations

import uuid

from httpx import AsyncClient

from app.modules.explanation.context_extractor import ContextExtractor
from app.modules.explanation.provider import ExplanationError, ExplanationErrorCode
from app.prompts.paragraph_explanation import render_paragraph_explanation_prompt
from app.prompts.sentence_explanation import render_sentence_explanation_prompt
from app.prompts.word_explanation import render_word_explanation_prompt
from tests.conftest import FakeExplanationProvider

_AUTH = {"Authorization": "Bearer valid-token"}
_BOOKS = "/api/v1/books"
_TEXT = b"First sentence here. Second sentence here.\n\nSecond paragraph text here."


async def _upload(client: AsyncClient) -> tuple[str, str]:
    response = await client.post(
        _BOOKS, headers=_AUTH, files={"file": ("book.txt", _TEXT, "text/plain")}
    )
    book_id = response.json()["id"]
    content = await client.get(f"{_BOOKS}/{book_id}/content", headers=_AUTH)
    return book_id, content.json()["content"]


async def _explain(
    client: AsyncClient, book_id: str, *, text: str, start: int, end: int
) -> dict[str, object]:
    response = await client.post(
        f"{_BOOKS}/{book_id}/explain",
        headers=_AUTH,
        json={
            "anchor": str(start),
            "end_anchor": str(end),
            "selected_text": text,
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


async def test_word_selection_is_classified_as_word(client: AsyncClient) -> None:
    book_id, _ = await _upload(client)

    body = await _explain(client, book_id, text="First", start=0, end=5)

    assert body["selection_type"] == "word"
    assert body["meaning"]
    assert body["explanation"]
    assert body["example"]


async def test_sentence_selection_is_classified_as_sentence(
    client: AsyncClient,
) -> None:
    book_id, content = await _upload(client)
    sentence = "First sentence here."
    end = content.index(sentence) + len(sentence)

    body = await _explain(client, book_id, text=sentence, start=0, end=end)

    assert body["selection_type"] == "sentence"
    assert body["explanation"]
    assert body["meaning"] is None
    assert body["example"] is None


async def test_paragraph_selection_is_classified_as_paragraph(
    client: AsyncClient,
) -> None:
    book_id, content = await _upload(client)
    paragraph = content.split("\n\n")[0]

    body = await _explain(client, book_id, text=paragraph, start=0, end=len(paragraph))

    assert body["selection_type"] == "paragraph"
    assert body["explanation"]


async def test_selection_outside_content_returns_422(client: AsyncClient) -> None:
    book_id, content = await _upload(client)
    beyond = len(content) + 100

    response = await client.post(
        f"{_BOOKS}/{book_id}/explain",
        headers=_AUTH,
        json={
            "anchor": str(beyond),
            "end_anchor": str(beyond + 4),
            "selected_text": "zzzz",
        },
    )

    assert response.status_code == 422


async def test_provider_failure_returns_503(
    client: AsyncClient,
    explanation_provider: FakeExplanationProvider,
) -> None:
    explanation_provider.error = ExplanationError(
        ExplanationErrorCode.TIMEOUT, "timed out"
    )
    book_id, _ = await _upload(client)

    response = await client.post(
        f"{_BOOKS}/{book_id}/explain",
        headers=_AUTH,
        json={"anchor": "0", "end_anchor": "5", "selected_text": "First"},
    )

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "dependency_unavailable"


async def test_explain_requires_authentication(client: AsyncClient) -> None:
    book_id, _ = await _upload(client)

    response = await client.post(
        f"{_BOOKS}/{book_id}/explain",
        json={"anchor": "0", "end_anchor": "5", "selected_text": "First"},
    )

    assert response.status_code == 401


async def test_explain_unknown_book_returns_404(client: AsyncClient) -> None:
    response = await client.post(
        f"{_BOOKS}/{uuid.uuid4()}/explain",
        headers=_AUTH,
        json={"anchor": "0", "end_anchor": "5", "selected_text": "First"},
    )

    assert response.status_code == 404


def test_prompt_templates_carry_constraints() -> None:
    word = render_word_explanation_prompt(word="w", context="c", book_title="B")
    sentence = render_sentence_explanation_prompt(
        sentence="s", context="c", book_title="B"
    )
    paragraph = render_paragraph_explanation_prompt(
        paragraph="p", context="c", book_title="B"
    )

    assert "three sentences" in word
    assert "five sentences" in sentence
    assert "seven sentences" in paragraph
    assert "NEVER summarize" in paragraph


def test_context_extractor_bounds_and_centres() -> None:
    extractor = ContextExtractor(max_chars=20)

    result = extractor.extract(
        reader_context="x" * 100 + " laptop " + "y" * 100, word="laptop"
    )

    assert len(result) <= 20
    assert "laptop" in result
