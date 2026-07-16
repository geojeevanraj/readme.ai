"""Prerequisite capability — deterministic prerequisite detection.

Identifies concepts a reader likely needs first, using a configurable dependency
map (structured rules) rather than an LLM. This defines the capability
architecture; a future version may become AI-powered without changing the
engine or the registry.
"""

from __future__ import annotations

import re

from app.modules.learning.capability import (
    CapabilityContext,
    CapabilityOutcome,
    Prerequisite,
)

# Concept -> its prerequisites. Configurable/extensible; not exhaustive.
_DEFAULT_DEPENDENCY_MAP: dict[str, list[Prerequisite]] = {
    "gradient descent": [
        Prerequisite("Derivative", "Gradient descent builds upon derivatives."),
        Prerequisite(
            "Learning rate", "Gradient descent is controlled by a learning rate."
        ),
    ],
    "backpropagation": [
        Prerequisite("Gradient descent", "Backpropagation applies gradient descent."),
        Prerequisite("Chain rule", "Backpropagation relies on the chain rule."),
    ],
    "derivative": [
        Prerequisite("Function", "A derivative describes how a function changes."),
    ],
    "neural network": [
        Prerequisite(
            "Linear algebra", "Neural networks operate on vectors and matrices."
        ),
    ],
    "recursion": [
        Prerequisite("Function", "Recursion is a function that calls itself."),
    ],
}


class PrerequisiteCapability:
    """Returns prerequisite concepts for known terms in the selection."""

    def __init__(
        self,
        dependency_map: dict[str, list[Prerequisite]] | None = None,
    ) -> None:
        self._map = dependency_map or _DEFAULT_DEPENDENCY_MAP

    @property
    def name(self) -> str:
        return "prerequisite"

    async def evaluate(self, context: CapabilityContext) -> CapabilityOutcome:
        text = context.selected_text.lower()
        prerequisites: list[Prerequisite] = []
        seen: set[str] = set()
        for concept, dependencies in self._map.items():
            if not re.search(rf"\b{re.escape(concept)}\b", text):
                continue
            for prerequisite in dependencies:
                if prerequisite.name not in seen:
                    seen.add(prerequisite.name)
                    prerequisites.append(prerequisite)
        return CapabilityOutcome(prerequisites=prerequisites)
