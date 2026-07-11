"""Operational endpoints: liveness, readiness, and version.

These are intentionally the only endpoints in the foundation sprint. They are
unversioned because they are part of the operational contract (used by
orchestrators and load balancers) rather than the product API.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Response, status

from app.core.config import Settings, get_settings
from app.db import session as db
from app.schemas.system import (
    DependencyStatus,
    HealthResponse,
    ReadinessResponse,
    ServiceStatus,
    VersionResponse,
)

router = APIRouter(tags=["system"])


@router.get("/health", response_model=HealthResponse, summary="Liveness probe")
async def health() -> HealthResponse:
    """Report that the process is alive.

    Deliberately checks no external dependencies — a load balancer uses this to
    decide whether the process should be restarted, not whether it can serve.
    """
    return HealthResponse(status=ServiceStatus.OK)


@router.get(
    "/health/ready",
    response_model=ReadinessResponse,
    summary="Readiness probe",
)
async def readiness(response: Response) -> ReadinessResponse:
    """Report whether the service can serve real traffic.

    Checks downstream dependencies. Returns HTTP 503 when any dependency is
    unavailable so orchestrators stop routing traffic until it recovers.
    """
    postgres_healthy = await db.ping()
    dependencies = [DependencyStatus(name="postgres", healthy=postgres_healthy)]

    all_healthy = all(dep.healthy for dep in dependencies)
    if not all_healthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE

    return ReadinessResponse(
        status=ServiceStatus.OK if all_healthy else ServiceStatus.DEGRADED,
        dependencies=dependencies,
    )


@router.get("/version", response_model=VersionResponse, summary="Service version")
async def version(settings: Settings = Depends(get_settings)) -> VersionResponse:
    """Return service identity and version metadata."""
    return VersionResponse(
        name=settings.app_name,
        version=settings.app_version,
        environment=settings.app_env.value,
    )
