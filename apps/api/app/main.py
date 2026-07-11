"""Application factory and composition root.

``create_app`` builds and wires the FastAPI application: logging, middleware,
error handlers, CORS, and routing. A module-level ``app`` instance is exposed
for ASGI servers (``uvicorn app.main:app``).
"""

from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import Settings, get_settings
from app.core.errors import register_error_handlers
from app.core.lifespan import lifespan
from app.core.logging import configure_logging
from app.core.middleware import RequestContextMiddleware


def create_app(settings: Settings | None = None) -> FastAPI:
    """Build and configure the FastAPI application.

    Accepts an optional ``settings`` override so tests can construct an app with
    bespoke configuration without touching the environment.
    """
    settings = settings or get_settings()
    configure_logging(settings.log_level, settings.log_format)

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        # Interactive docs are disabled outside development.
        docs_url=None if settings.is_production else "/docs",
        redoc_url=None if settings.is_production else "/redoc",
        openapi_url=None if settings.is_production else "/openapi.json",
        lifespan=lifespan,
    )

    # Middleware added later runs outermost. CORS is outermost so it can answer
    # preflight requests; the request-context (correlation id) middleware runs
    # for every application request beneath it.
    app.add_middleware(RequestContextMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    register_error_handlers(app)
    app.include_router(api_router)

    # Pin the dependency-injected settings to the instance this app was built
    # with, so configuration is consistent across the process and overridable
    # in tests via ``create_app(settings=...)``.
    app.dependency_overrides[get_settings] = lambda: settings

    return app


app = create_app()
