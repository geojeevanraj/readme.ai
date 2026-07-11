"""Pydantic schemas for the authentication module."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class UserResponse(BaseModel):
    """Public representation of an internal user."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID = Field(description="Internal, stable user identifier.")
    email: str = Field(description="User's email address.")
    display_name: str | None = Field(
        default=None,
        description="User's display name, if provided by the identity provider.",
    )
    photo_url: str | None = Field(
        default=None,
        description="URL of the user's avatar, if available.",
    )
    created_at: datetime = Field(description="When the user was first provisioned.")
    updated_at: datetime = Field(description="When the user was last updated.")
    last_login_at: datetime = Field(description="Most recent successful sign-in.")


class LogoutResponse(BaseModel):
    """Acknowledgement of a logout request."""

    detail: str = Field(description="Human-readable result of the operation.")
