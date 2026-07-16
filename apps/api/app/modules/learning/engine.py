"""The Learning Intelligence Engine.

Runs registered capabilities, then delegates explanation generation to the
Explanation Service, and aggregates both into the final response. It contains no
feature-specific logic — capabilities are the extension point.
"""

from __future__ import annotations

import uuid

from app.core.logging import get_logger
from app.modules.explanation.schemas import (
    ExplanationResponse,
    PrerequisiteResponse,
)
from app.modules.explanation.service import ExplanationService
from app.modules.learning.capability import CapabilityContext, Prerequisite
from app.modules.learning.registry import CapabilityRegistry

logger = get_logger(__name__)


class LearningIntelligenceEngine:
    def __init__(
        self,
        registry: CapabilityRegistry,
        explanation_service: ExplanationService,
    ) -> None:
        self._registry = registry
        self._explanation_service = explanation_service

    async def explain(
        self,
        *,
        user_id: uuid.UUID,
        book_id: uuid.UUID,
        anchor: str,
        end_anchor: str | None,
        selected_text: str,
    ) -> ExplanationResponse:
        context = CapabilityContext(
            user_id=user_id, book_id=book_id, selected_text=selected_text
        )
        prerequisites = await self._run_capabilities(context)

        response = await self._explanation_service.explain(
            user_id=user_id,
            book_id=book_id,
            anchor=anchor,
            end_anchor=end_anchor,
            selected_text=selected_text,
        )
        return response.model_copy(update={"prerequisites": prerequisites})

    async def _run_capabilities(
        self, context: CapabilityContext
    ) -> list[PrerequisiteResponse]:
        collected: list[Prerequisite] = []
        seen: set[str] = set()
        for capability in self._registry.capabilities:
            try:
                outcome = await capability.evaluate(context)
            except Exception:
                # A misbehaving capability must never break the explanation.
                logger.exception(
                    "Capability failed", extra={"capability": capability.name}
                )
                continue
            for prerequisite in outcome.prerequisites:
                if prerequisite.name not in seen:
                    seen.add(prerequisite.name)
                    collected.append(prerequisite)

        return [
            PrerequisiteResponse(name=item.name, reason=item.reason)
            for item in collected
        ]
