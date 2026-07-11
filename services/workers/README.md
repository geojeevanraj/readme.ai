# services/workers

Asynchronous background processing tier for ReadMe.ai.

## Responsibility (target)

This service runs the long-running, retryable, idempotent work that must never
block the synchronous reader path:

- **Ingestion** — text extraction, segmentation, chunking, embedding.
- **Analysis** — difficulty, prerequisites, author-intent artifacts.
- **Reading-plan generation**.
- **Explanation pre-computation** — the "anticipate and cache" half of the
  flow-preservation strategy.

## Status

**Not implemented in Sprint 0.2 (foundation).** This directory documents an
architectural boundary so the repository structure matches the Sprint 0.1
blueprint. The worker process, its queue, and job handlers are introduced in a
later sprint and will share domain code with `apps/api`.
