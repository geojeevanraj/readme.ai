"""Selection classifier.

Determines whether a selection is a WORD, SENTENCE, or PARAGRAPH by consulting
the structured document (Sprint 3.5) — never arbitrary character counts. It also
returns the surrounding context (the intersecting paragraph text) so strategies
can ground their prompts.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass

from app.core.errors import NotFoundError, ValidationError
from app.modules.explanation.enums import SelectionType
from app.modules.processing.enums import ProcessingStatus
from app.modules.processing.repository import ProcessingRepository


@dataclass(frozen=True, slots=True)
class SelectionAnalysis:
    """The classified selection type and its grounding context."""

    selection_type: SelectionType
    context: str


class SelectionClassifier:
    def __init__(self, processing_repository: ProcessingRepository) -> None:
        self._repository = processing_repository

    async def analyze(
        self,
        *,
        book_id: uuid.UUID,
        start: int,
        end: int,
        selected_text: str,
    ) -> SelectionAnalysis:
        record = await self._repository.get_by_book_id(book_id)
        if record is None or record.status is not ProcessingStatus.COMPLETED:
            raise NotFoundError("This book has not been processed for reading.")

        paragraphs = await self._repository.get_paragraphs_overlapping(
            record.id, start, end
        )
        if not paragraphs:
            raise ValidationError("The selection is outside the book content.")

        context = "\n\n".join(paragraph.text for paragraph in paragraphs)

        if len(paragraphs) > 1:
            return SelectionAnalysis(SelectionType.PARAGRAPH, context)

        sentence_count = await self._repository.count_sentences_overlapping(
            record.id, start, end
        )
        word_count = len(selected_text.split())

        if word_count <= 1 and sentence_count <= 1:
            selection_type = SelectionType.WORD
        elif sentence_count <= 1:
            selection_type = SelectionType.SENTENCE
        else:
            selection_type = SelectionType.PARAGRAPH

        return SelectionAnalysis(selection_type, context)
