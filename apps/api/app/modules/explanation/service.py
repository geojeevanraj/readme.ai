"""Explanation service — classify the selection, then delegate to a strategy.

Reader -> API -> this service -> SelectionClassifier -> Strategy -> Provider ->
Ollama. The reader never reaches the provider. Ownership is enforced via the
library's BookService; classification uses the structured document.
"""

from __future__ import annotations

import uuid

from app.core.errors import DependencyUnavailableError
from app.modules.explanation.classifier import SelectionClassifier
from app.modules.explanation.context_extractor import ContextExtractor
from app.modules.explanation.enums import SelectionType
from app.modules.explanation.provider import ExplanationError
from app.modules.explanation.schemas import ExplanationResponse
from app.modules.explanation.strategies.base import ExplanationStrategy
from app.modules.library.service import BookService


class ExplanationService:
    def __init__(
        self,
        classifier: SelectionClassifier,
        strategies: dict[SelectionType, ExplanationStrategy],
        context_extractor: ContextExtractor,
        book_service: BookService,
    ) -> None:
        self._classifier = classifier
        self._strategies = strategies
        self._context_extractor = context_extractor
        self._book_service = book_service

    async def explain(
        self,
        *,
        user_id: uuid.UUID,
        book_id: uuid.UUID,
        anchor: str,
        end_anchor: str | None,
        selected_text: str,
    ) -> ExplanationResponse:
        book = await self._book_service.get_book(user_id, book_id)

        start = _parse_offset(anchor)
        end = _parse_offset(end_anchor) if end_anchor else start + len(selected_text)

        analysis = await self._classifier.analyze(
            book_id=book_id,
            start=start,
            end=max(end, start + 1),
            selected_text=selected_text,
        )
        context = self._context_extractor.extract(
            reader_context=analysis.context, word=selected_text[:80]
        )

        strategy = self._strategies[analysis.selection_type]
        try:
            result = await strategy.explain(
                selected_text=selected_text,
                context=context,
                book_title=book.title,
            )
        except ExplanationError as error:
            raise DependencyUnavailableError(
                "The explanation service is unavailable.",
                details={"reason": error.code.value},
            ) from error

        if not result.explanation and not result.meaning:
            raise DependencyUnavailableError(
                "The explanation service returned no result.",
                details={"reason": "empty"},
            )

        return ExplanationResponse(
            selection_type=analysis.selection_type,
            explanation=result.explanation,
            meaning=result.meaning,
            example=result.example,
        )


def _parse_offset(value: str) -> int:
    try:
        return max(0, int(value))
    except ValueError:
        return 0
