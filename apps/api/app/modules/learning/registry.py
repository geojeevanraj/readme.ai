"""Capability registry.

Capabilities register here; the engine consults the registry and never
hardcodes capability implementations. New capabilities are added by registering
them at composition time — the engine is untouched.
"""

from __future__ import annotations

from app.modules.learning.capability import LearningCapability


class CapabilityRegistry:
    """Holds the ordered set of registered learning capabilities."""

    def __init__(self) -> None:
        self._capabilities: list[LearningCapability] = []

    def register(self, capability: LearningCapability) -> None:
        """Register a capability for execution by the engine."""
        self._capabilities.append(capability)

    @property
    def capabilities(self) -> list[LearningCapability]:
        """The registered capabilities, in registration order."""
        return list(self._capabilities)
