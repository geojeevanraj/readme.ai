"""Dependency wiring for the Learning Intelligence Engine."""

from __future__ import annotations

from functools import lru_cache
from typing import Annotated

from fastapi import Depends

from app.modules.explanation.dependencies import get_explanation_service
from app.modules.explanation.service import ExplanationService
from app.modules.learning.capabilities.prerequisite import PrerequisiteCapability
from app.modules.learning.engine import LearningIntelligenceEngine
from app.modules.learning.registry import CapabilityRegistry


@lru_cache(maxsize=1)
def get_capability_registry() -> CapabilityRegistry:
    """Build the registry and register capabilities.

    This is the single composition point for capabilities — add future
    capabilities here without touching the engine.
    """
    registry = CapabilityRegistry()
    registry.register(PrerequisiteCapability())
    return registry


def get_learning_engine(
    explanation_service: Annotated[
        ExplanationService, Depends(get_explanation_service)
    ],
) -> LearningIntelligenceEngine:
    return LearningIntelligenceEngine(get_capability_registry(), explanation_service)


LearningEngineDep = Annotated[LearningIntelligenceEngine, Depends(get_learning_engine)]
