"""Logging configuration.

Two output formats are supported, selected by configuration:

* ``console`` — human-readable, for local development.
* ``json``    — structured single-line records, for production aggregation.

A ``request_id`` is carried through a :class:`contextvars.ContextVar` so every
log line emitted while handling a request can be correlated end-to-end without
threading the id through every function call.
"""

from __future__ import annotations

import json
import logging
import sys
from contextvars import ContextVar
from typing import Any

from app.core.config import LogFormat, LogLevel

# Correlation id for the in-flight request. Set by middleware, read by the
# formatters. Defaults to "-" outside of a request context.
request_id_var: ContextVar[str] = ContextVar("request_id", default="-")

# Standard ``LogRecord`` attributes we never treat as structured "extra" fields.
_RESERVED_RECORD_KEYS = frozenset(
    logging.makeLogRecord({}).__dict__.keys() | {"message", "asctime", "taskName"}
)


class JsonFormatter(logging.Formatter):
    """Render log records as single-line JSON objects."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": request_id_var.get(),
        }

        # Merge any structured fields passed via ``logger.info(..., extra=...)``.
        for key, value in record.__dict__.items():
            if key not in _RESERVED_RECORD_KEYS and not key.startswith("_"):
                payload[key] = value

        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)

        return json.dumps(payload, default=str, ensure_ascii=False)


class ConsoleFormatter(logging.Formatter):
    """Human-readable formatter that includes the correlation id."""

    _FORMAT = (
        "%(asctime)s | %(levelname)-8s | %(name)s " "| [%(request_id)s] | %(message)s"
    )

    def __init__(self) -> None:
        super().__init__(fmt=self._FORMAT, datefmt="%Y-%m-%d %H:%M:%S")

    def format(self, record: logging.LogRecord) -> str:
        # Assign via __dict__ so the dynamic field is available to the format
        # string without tripping the static "unknown attribute" check.
        record.__dict__["request_id"] = request_id_var.get()
        return super().format(record)


def configure_logging(level: LogLevel, log_format: LogFormat) -> None:
    """Configure the root logger.

    Idempotent: existing handlers are cleared so repeated calls (e.g. under a
    reloader or in tests) do not duplicate log output.
    """
    formatter: logging.Formatter = (
        JsonFormatter() if log_format == LogFormat.JSON else ConsoleFormatter()
    )

    handler = logging.StreamHandler(stream=sys.stdout)
    handler.setFormatter(formatter)

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level.value)

    # Align uvicorn's loggers with ours so output is consistent.
    for name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        uvicorn_logger = logging.getLogger(name)
        uvicorn_logger.handlers.clear()
        uvicorn_logger.propagate = True


def get_logger(name: str) -> logging.Logger:
    """Return a named logger. Thin wrapper kept as the single import point."""
    return logging.getLogger(name)
