"""Dependency wiring for the explanation module."""

from __future__ import annotations

from functools import lru_cache
from typing import Annotated

from fastapi import Depends

from app.core.config import Settings, get_settings
from app.modules.explanation.classifier import SelectionClassifier
from app.modules.explanation.context_extractor import ContextExtractor
from app.modules.explanation.enums import SelectionType
from app.modules.explanation.provider import (
    ExplanationProvider,
    OllamaExplanationProvider,
)
from app.modules.explanation.service import ExplanationService
from app.modules.explanation.strategies import (
    ExplanationStrategy,
    ParagraphExplanationStrategy,
    SentenceExplanationStrategy,
    WordExplanationStrategy,
)
from app.modules.library.dependencies import get_book_service
from app.modules.library.service import BookService
from app.modules.processing.dependencies import get_processing_repository
from app.modules.processing.repository import ProcessingRepository


@lru_cache(maxsize=1)
def _ollama_provider(
    base_url: str, model: str, timeout: float
) -> OllamaExplanationProvider:
    return OllamaExplanationProvider(
        base_url=base_url, model=model, timeout_seconds=timeout
    )


def get_explanation_provider(
    settings: Annotated[Settings, Depends(get_settings)],
) -> ExplanationProvider:
    """Provide the explanation provider. Overridden with a fake in tests."""
    return _ollama_provider(
        settings.ollama_base_url,
        settings.ollama_model,
        settings.ollama_timeout_seconds,
    )


@lru_cache(maxsize=1)
def get_context_extractor() -> ContextExtractor:
    return ContextExtractor()


def get_selection_classifier(
    repository: Annotated[ProcessingRepository, Depends(get_processing_repository)],
) -> SelectionClassifier:
    return SelectionClassifier(repository)


def get_explanation_strategies(
    provider: Annotated[ExplanationProvider, Depends(get_explanation_provider)],
) -> dict[SelectionType, ExplanationStrategy]:
    return {
        SelectionType.WORD: WordExplanationStrategy(provider),
        SelectionType.SENTENCE: SentenceExplanationStrategy(provider),
        SelectionType.PARAGRAPH: ParagraphExplanationStrategy(provider),
    }


def get_explanation_service(
    classifier: Annotated[SelectionClassifier, Depends(get_selection_classifier)],
    strategies: Annotated[
        dict[SelectionType, ExplanationStrategy],
        Depends(get_explanation_strategies),
    ],
    context_extractor: Annotated[ContextExtractor, Depends(get_context_extractor)],
    book_service: Annotated[BookService, Depends(get_book_service)],
) -> ExplanationService:
    return ExplanationService(classifier, strategies, context_extractor, book_service)


ExplanationServiceDep = Annotated[ExplanationService, Depends(get_explanation_service)]
