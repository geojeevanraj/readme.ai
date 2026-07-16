"""Word explanation strategy: meaning + concise explanation + example."""

from __future__ import annotations

from app.modules.explanation.enums import SelectionType
from app.modules.explanation.provider import ExplanationProvider
from app.modules.explanation.strategies.base import StrategyResult, limit_sentences
from app.prompts.word_explanation import render_word_explanation_prompt

_MAX_SENTENCES = 3


class WordExplanationStrategy:
    def __init__(self, provider: ExplanationProvider) -> None:
        self._provider = provider

    @property
    def selection_type(self) -> SelectionType:
        return SelectionType.WORD

    async def explain(
        self,
        *,
        selected_text: str,
        context: str,
        book_title: str,
    ) -> StrategyResult:
        prompt = render_word_explanation_prompt(
            word=selected_text, context=context, book_title=book_title
        )
        generated = await self._provider.explain(prompt=prompt)
        return StrategyResult(
            explanation=limit_sentences(generated.explanation, _MAX_SENTENCES),
            meaning=generated.meaning.strip() or None,
            example=generated.example.strip() or None,
        )
