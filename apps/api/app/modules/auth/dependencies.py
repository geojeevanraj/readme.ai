"""Dependency wiring and route protection for the authentication module.

These dependencies are the security boundary: every protected route depends on
:func:`get_current_user`, which validates the bearer token on every request.
Each collaborator is provided via FastAPI's dependency injection so tests can
override the token verifier and database session without real Firebase or
PostgreSQL.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.core.errors import UnauthorizedError
from app.db.session import get_db_session
from app.modules.auth.models import User
from app.modules.auth.repository import UserRepository
from app.modules.auth.service import AuthService
from app.modules.auth.verifier import (
    DevelopmentTokenVerifier,
    FirebaseTokenVerifier,
    TokenVerifier,
)

# auto_error=False so a missing/!malformed header yields our typed 401 envelope
# rather than FastAPI's default 403 response.
_bearer_scheme = HTTPBearer(auto_error=False)


@lru_cache(maxsize=1)
def _firebase_verifier(project_id: str) -> FirebaseTokenVerifier:
    """Return a process-wide verifier so its cert cache is shared."""
    return FirebaseTokenVerifier(project_id)


@lru_cache(maxsize=1)
def _development_verifier() -> DevelopmentTokenVerifier:
    return DevelopmentTokenVerifier()


def get_token_verifier(
    settings: Annotated[Settings, Depends(get_settings)],
) -> TokenVerifier:
    """Provide the token verifier based on configuration.

    In development mode (``DEV_AUTH=true``) a fixed dev token authenticates a
    mock user; otherwise production Firebase verification is used unchanged.
    """
    if settings.dev_auth:
        return _development_verifier()
    return _firebase_verifier(settings.firebase_project_id)


def get_user_repository(
    session: Annotated[AsyncSession, Depends(get_db_session)],
) -> UserRepository:
    """Provide a request-scoped user repository."""
    return UserRepository(session)


def get_auth_service(
    repository: Annotated[UserRepository, Depends(get_user_repository)],
    verifier: Annotated[TokenVerifier, Depends(get_token_verifier)],
) -> AuthService:
    """Provide the authentication service for the current request."""
    return AuthService(repository, verifier)


async def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(_bearer_scheme)
    ],
    service: Annotated[AuthService, Depends(get_auth_service)],
) -> User:
    """Resolve and return the authenticated user, or raise 401.

    This is the single protection point for authenticated routes. It enforces
    the presence of a bearer token and delegates validation to the service on
    every request — the client is never trusted.
    """
    if credentials is None or not credentials.credentials:
        raise UnauthorizedError("Authentication credentials were not provided.")
    return await service.authenticate(credentials.credentials)


CurrentUser = Annotated[User, Depends(get_current_user)]
