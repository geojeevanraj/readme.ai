"""Pydantic schemas for the explanation module."""

from __future__ import annotations

from pydantic import BaseModel, Field

from app.modules.explanation.enums import SelectionType


class ExplainRequest(BaseModel):
    """Request to explain a selection (book id comes from the path).

    ``anchor`` is the stable start offset; ``end_anchor`` the optional end
    offset. When omitted, the end is derived from the selected text length.
    """

    anchor: str = Field(
        min_length=1,
        max_length=255,
        description="Stable start offset of the selection.",
    )
    end_anchor: str | None = Field(
        default=None,
        max_length=255,
        description="Stable end offset of the selection, if known.",
    )
    selected_text: str = Field(
        min_length=1,
        max_length=8000,
        description="The exact text the reader selected.",
    )


class PrerequisiteResponse(BaseModel):
    """A concept the reader may need to understand first."""

    name: str = Field(description="The prerequisite concept's name.")
    reason: str = Field(description="Why it is a prerequisite for the selection.")


class ExplanationResponse(BaseModel):
    """Unified explanation result; the client need not know the strategy used."""

    selection_type: SelectionType = Field(
        description="How the backend classified the selection.",
    )
    explanation: str = Field(description="The explanation of the selection.")
    meaning: str | None = Field(
        default=None,
        description="A brief definition (word selections only).",
    )
    example: str | None = Field(
        default=None,
        description="An optional contextual example (word selections only).",
    )
    prerequisites: list[PrerequisiteResponse] = Field(
        default_factory=list,
        description="Concepts to understand first, decided by the Learning "
        "Intelligence Engine. May be empty.",
    )
