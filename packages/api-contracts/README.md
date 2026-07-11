# packages/api-contracts

The **single source of truth** for request/response shapes shared between the
Flutter client (`apps/mobile`) and the FastAPI backend (`apps/api`).

## Responsibility (target)

- Hold the canonical contract definitions for the product API.
- Prevent frontend/backend drift by generating typed models for both sides from
  one definition (e.g. via the backend's OpenAPI schema).

## Status

**Empty in Sprint 0.2 (foundation).** Only operational endpoints exist so far
(`/health`, `/version`), whose schemas live with the backend. Product contracts
are added here when the first business endpoints are designed.
