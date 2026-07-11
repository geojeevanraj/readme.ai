"""Schemas for the operational endpoints (health, readiness, version)."""

from __future__ import annotations

from enum import StrEnum

from pydantic import BaseModel, Field


class ServiceStatus(StrEnum):
    """Coarse health status of the service or a dependency."""

    OK = "ok"
    DEGRADED = "degraded"


class HealthResponse(BaseModel):
    """Liveness response — the process is up and serving."""

    status: ServiceStatus = Field(description="Overall liveness status.")


class DependencyStatus(BaseModel):
    """Readiness status of a single downstream dependency."""

    name: str = Field(description="Dependency identifier, e.g. 'postgres'.")
    healthy: bool = Field(description="Whether the dependency is reachable.")


class ReadinessResponse(BaseModel):
    """Readiness response — whether the service can serve real traffic."""

    status: ServiceStatus = Field(description="Aggregate readiness status.")
    dependencies: list[DependencyStatus] = Field(
        default_factory=list,
        description="Per-dependency readiness detail.",
    )


class VersionResponse(BaseModel):
    """Service identity and version metadata."""

    name: str = Field(description="Human-readable service name.")
    version: str = Field(description="Semantic version of the running service.")
    environment: str = Field(description="Active runtime environment.")
