"""The learning-capability interface and shared value types.

A capability is a pluggable, learner-aware decision unit. The engine executes
registered capabilities before an explanation is generated. Capabilities do not
generate explanations and (in this foundation) do not call an LLM.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True, slots=True)
class Prerequisite:
    """A concept the reader may need to understand before the selection."""

    name: str
    reason: str


@dataclass(frozen=True, slots=True)
class CapabilityContext:
    """Everything a capability may inspect about a selection.

    Deliberately minimal for the foundation; future capabilities can extend the
    engine to populate more (e.g. learner profile) without changing this
    interface's consumers.
    """

    user_id: uuid.UUID
    book_id: uuid.UUID
    selected_text: str


@dataclass(frozen=True, slots=True)
class CapabilityOutcome:
    """The aggregate output a capability may contribute to a decision."""

    prerequisites: list[Prerequisite]


class LearningCapability(Protocol):
    """A pluggable learner-aware capability executed by the engine."""

    @property
    def name(self) -> str:
        """Stable capability identifier."""
        ...

    async def evaluate(self, context: CapabilityContext) -> CapabilityOutcome:
        """Produce this capability's contribution for the given selection."""
        ...
