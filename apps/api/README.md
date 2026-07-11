# ReadMe.ai — Backend (API)

FastAPI service that is the synchronous orchestration and policy boundary for
ReadMe.ai. **Sprint 3.5** adds the book processing engine (structured documents).

## Endpoints

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/health` | none | Liveness — process is up (no dependency checks) |
| GET | `/health/ready` | none | Readiness — verifies dependencies (503 if degraded) |
| GET | `/version` | none | Service name, version, and environment |
| GET | `/api/v1/auth/me` | bearer | Current user (provisions on first use) |
| POST | `/api/v1/auth/logout` | bearer | Stateless logout acknowledgement |
| POST | `/api/v1/books` | bearer | Upload a book (multipart) → triggers processing |
| GET | `/api/v1/books` | bearer | List the user's books |
| GET | `/api/v1/books/{id}` | bearer | Get one owned book |
| DELETE | `/api/v1/books/{id}` | bearer | Delete an owned book + its file |
| GET | `/api/v1/books/{id}/content` | bearer | Readable content (from structured doc) |
| GET/PUT | `/api/v1/books/{id}/progress` | bearer | Get / save reading position |
| GET/POST | `/api/v1/books/{id}/bookmarks` | bearer | List / create bookmarks |
| DELETE | `/api/v1/books/{id}/bookmarks/{bid}` | bearer | Delete a bookmark |
| GET/POST | `/api/v1/books/{id}/processing` | bearer | Get status / re-run processing |

See [`docs/api.md`](../../docs/api.md) for full request/response details.
Interactive docs at `/docs` (development only).

## Layout

```
app/
├── main.py            # application factory + composition root
├── core/              # config, logging, errors, middleware, lifespan
│   └── storage/       # StorageService protocol + LocalStorageService + provider
├── api/               # routing layer (routes/ + router aggregation)
├── db/                # SQLAlchemy 2.x async engine/session + declarative base
├── modules/           # bounded business modules
│   ├── auth/          # identity: verifier, repository, service, routes
│   ├── library/       # books: models, repository, service, routes
│   ├── reader/        # content (from processing), progress, bookmarks
│   └── processing/    # processors, registry, structured document, persistence
└── schemas/           # shared Pydantic models
migrations/            # Alembic environment + versions
tests/                 # pytest suite
```

## Local commands

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -e ".[dev]"

uvicorn app.main:app --reload --port 8000           # run

ruff check . && black --check . && isort --check-only . && mypy app && pytest
```

Configuration is environment-driven; see the root `.env.example`.
