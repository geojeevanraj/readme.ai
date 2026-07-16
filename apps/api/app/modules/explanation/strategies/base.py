"""Strategy interface and shared helpers."""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Protocol

from app.modules.explanation.enums import SelectionType

_SENTENCE_SPLIT = re.compile(r"(?<=[.!?])\s+")


@dataclass(frozen=True, slots=True)
class StrategyResult:
    """The output of a strategy, before mapping to the API response."""

    explanation: str
    meaning: str | None = None
    example: str | None = None


class ExplanationStrategy(Protocol):
    """Explains a selection of a particular type."""

    @property
    def selection_type(self) -> SelectionType:
        """The selection type this strategy handles."""
        ...

    async def explain(
        self,
        *,
        selected_text: str,
        context: str,
        book_title: str,
    ) -> StrategyResult:
        """Produce an explanation, or raise ``ExplanationError``."""
        ...


def limit_sentences(text: str, max_sentences: int) -> str:
    """Trim ``text`` to at most ``max_sentences`` sentences."""
    cleaned = text.strip()
    if not cleaned:
        return ""
    sentences = _SENTENCE_SPLIT.split(cleaned)
    return " ".join(sentences[:max_sentences]).strip()
