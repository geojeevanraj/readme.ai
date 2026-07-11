"""Firebase ID token verification.

Token verification is quarantined behind the :class:`TokenVerifier` protocol so
the rest of the module depends on a stable contract rather than on Firebase or
JWT specifics. The production :class:`FirebaseTokenVerifier` validates Google's
RS256-signed ID tokens against Google's published X.509 certificates; tests
inject a fake implementation.
"""

from __future__ import annotations

import asyncio
import time
from dataclasses import dataclass
from typing import Any, Protocol

import httpx
import jwt
from cryptography.x509 import load_pem_x509_certificate

from app.core.errors import UnauthorizedError

# Google's public X.509 certificates for Firebase Secure Token signing keys.
_CERTS_URL = (
    "https://www.googleapis.com/robot/v1/metadata/x509/"
    "securetoken@system.gserviceaccount.com"
)
_FALLBACK_CACHE_TTL_SECONDS = 3600.0
_FETCH_TIMEOUT_SECONDS = 10.0


@dataclass(frozen=True, slots=True)
class FirebaseIdentity:
    """The verified subset of a Firebase ID token's claims."""

    uid: str
    email: str
    display_name: str | None
    photo_url: str | None


class TokenVerifier(Protocol):
    """Verifies a bearer token and returns the authenticated identity."""

    async def verify(self, token: str) -> FirebaseIdentity:
        """Validate ``token`` and return its identity, or raise on failure."""
        ...


# Fixed token accepted only in development mode (DEV_AUTH=true).
DEV_AUTH_TOKEN = "development-token"

# The deterministic development user (mirrors the client's mock user).
DEV_IDENTITY = FirebaseIdentity(
    uid="development-user",
    email="geo.dev@readme.ai",
    display_name="Geo (Development)",
    photo_url=None,
)


class DevelopmentTokenVerifier:
    """Development-only verifier: accepts the fixed dev token as a mock user.

    Wired in only when ``DEV_AUTH=true``. Production JWT verification is
    untouched and never weakened.
    """

    async def verify(self, token: str) -> FirebaseIdentity:
        if token != DEV_AUTH_TOKEN:
            raise UnauthorizedError("Invalid development token.")
        return DEV_IDENTITY


class FirebaseTokenVerifier:
    """Verifies Firebase ID tokens using Google's published signing certs.

    Signing certificates are fetched lazily and cached for the duration advised
    by the response's ``Cache-Control`` header, with a single in-flight refresh
    guarded by a lock to avoid a stampede.
    """

    def __init__(self, project_id: str) -> None:
        self._project_id = project_id
        self._issuer = f"https://securetoken.google.com/{project_id}"
        self._certs: dict[str, str] = {}
        self._expires_at: float = 0.0
        self._lock = asyncio.Lock()

    async def verify(self, token: str) -> FirebaseIdentity:
        if not self._project_id:
            raise UnauthorizedError("Authentication is not configured.")

        try:
            header = jwt.get_unverified_header(token)
        except jwt.PyJWTError as exc:
            raise UnauthorizedError("Malformed authentication token.") from exc

        kid = header.get("kid")
        if not kid:
            raise UnauthorizedError("Authentication token is missing a key id.")

        public_key = await self._public_key_for(kid)

        try:
            claims: dict[str, Any] = jwt.decode(
                token,
                public_key,
                algorithms=["RS256"],
                audience=self._project_id,
                issuer=self._issuer,
                options={"require": ["exp", "iat", "sub", "aud", "iss"]},
            )
        except jwt.PyJWTError as exc:
            raise UnauthorizedError("Invalid authentication token.") from exc

        return self._identity_from_claims(claims)

    @staticmethod
    def _identity_from_claims(claims: dict[str, Any]) -> FirebaseIdentity:
        uid = claims.get("user_id") or claims.get("sub")
        if not isinstance(uid, str) or not uid:
            raise UnauthorizedError("Authentication token is missing a subject.")

        email = claims.get("email")
        if not isinstance(email, str) or not email:
            raise UnauthorizedError("Authentication token is missing an email.")

        name = claims.get("name")
        picture = claims.get("picture")
        return FirebaseIdentity(
            uid=uid,
            email=email,
            display_name=name if isinstance(name, str) else None,
            photo_url=picture if isinstance(picture, str) else None,
        )

    async def _public_key_for(self, kid: str) -> Any:
        cert = await self._cert_for(kid)
        certificate = load_pem_x509_certificate(cert.encode("utf-8"))
        return certificate.public_key()

    async def _cert_for(self, kid: str) -> str:
        if kid not in self._certs or time.monotonic() >= self._expires_at:
            await self._refresh_certs()
        cert = self._certs.get(kid)
        if cert is None:
            raise UnauthorizedError("Unknown token signing key.")
        return cert

    async def _refresh_certs(self) -> None:
        async with self._lock:
            # Another coroutine may have refreshed while we awaited the lock.
            if self._certs and time.monotonic() < self._expires_at:
                return
            try:
                async with httpx.AsyncClient(timeout=_FETCH_TIMEOUT_SECONDS) as client:
                    response = await client.get(_CERTS_URL)
                    response.raise_for_status()
                    self._certs = response.json()
            except (httpx.HTTPError, ValueError) as exc:
                raise UnauthorizedError(
                    "Could not verify the authentication token."
                ) from exc
            ttl = _parse_max_age(response.headers.get("Cache-Control"))
            self._expires_at = time.monotonic() + ttl


def _parse_max_age(cache_control: str | None) -> float:
    """Extract ``max-age`` seconds from a Cache-Control header value."""
    if not cache_control:
        return _FALLBACK_CACHE_TTL_SECONDS
    for directive in cache_control.split(","):
        directive = directive.strip()
        if directive.startswith("max-age="):
            try:
                return float(directive.removeprefix("max-age="))
            except ValueError:
                return _FALLBACK_CACHE_TTL_SECONDS
    return _FALLBACK_CACHE_TTL_SECONDS
