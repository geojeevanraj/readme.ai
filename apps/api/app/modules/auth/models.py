"""ORM models for the authentication module."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def _utcnow() -> datetime:
    """Return the current timezone-aware UTC timestamp."""
    return datetime.now(tz=UTC)


class User(Base):
    """An internal user, keyed to a Firebase identity.

    The internal :attr:`id` (a UUID) is the stable primary key used by all other
    domain data; :attr:`firebase_uid` links the record to the external identity
    provider so the provider can be migrated without rewriting relationships.

    Timestamp columns use client-side defaults so values are populated on the
    instance immediately after flush (avoiding async lazy-load round trips),
    and also carry a server default for inserts that bypass the ORM.
    """

    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
    )
    firebase_uid: Mapped[str] = mapped_column(
        String(128),
        unique=True,
        index=True,
        nullable=False,
    )
    email: Mapped[str] = mapped_column(
        String(320),
        unique=True,
        index=True,
        nullable=False,
    )
    display_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=_utcnow,
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=_utcnow,
        server_default=func.now(),
        onupdate=_utcnow,
        nullable=False,
    )
    last_login_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=_utcnow,
        nullable=False,
    )

    def __repr__(self) -> str:  # pragma: no cover - debug aid only
        return f"User(id={self.id!r}, firebase_uid={self.firebase_uid!r})"
