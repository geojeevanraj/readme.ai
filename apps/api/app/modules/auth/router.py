"""HTTP routes for the authentication module."""

from __future__ import annotations

from fastapi import APIRouter

from app.modules.auth.dependencies import CurrentUser
from app.modules.auth.schemas import LogoutResponse, UserResponse

router = APIRouter()


@router.get("/me", response_model=UserResponse, summary="Get the current user")
async def get_me(user: CurrentUser) -> UserResponse:
    """Return the authenticated user's profile.

    Provisions the internal user on first authenticated request as a side effect
    of token verification.
    """
    return UserResponse.model_validate(user)


@router.post("/logout", response_model=LogoutResponse, summary="Log out")
async def logout(user: CurrentUser) -> LogoutResponse:
    """Acknowledge a logout.

    Sessions are stateless (the client holds and discards the Firebase token),
    so the server has no session to invalidate. Requiring authentication here
    keeps the endpoint symmetric and confirms the caller held a valid token.
    """
    return LogoutResponse(detail="Logged out.")
