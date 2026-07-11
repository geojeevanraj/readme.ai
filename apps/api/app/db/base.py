"""Declarative base for ORM models.

All future models will inherit from :class:`Base` so that a single
``Base.metadata`` describes the schema for Alembic autogeneration. No concrete
models exist yet (Sprint 0.2 is foundation only).
"""

from __future__ import annotations

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Shared declarative base. Models in later sprints subclass this."""
