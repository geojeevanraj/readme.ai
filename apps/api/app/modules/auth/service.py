"""Authentication service — orchestrates verification and provisioning."""

from __future__ import annotations

from app.modules.auth.models import User
from app.modules.auth.repository import UserRepository
from app.modules.auth.verifier import TokenVerifier


class AuthService:
    """Coordinates token verification and internal user provisioning."""

    def __init__(self, repository: UserRepository, verifier: TokenVerifier) -> None:
        self._repository = repository
        self._verifier = verifier

    async def authenticate(self, token: str) -> User:
        """Resolve the user for a bearer token.

        Verifies the token, provisions an internal user on first sight,
        refreshes profile fields and the last-login timestamp on subsequent
        sign-ins, and returns the persisted user.
        """
        identity = await self._verifier.verify(token)

        user = await self._repository.get_by_firebase_uid(identity.uid)
        if user is None:
            user = await self._repository.create(identity)
        else:
            await self._repository.sync_profile(user, identity)

        await self._repository.commit()
        return user
