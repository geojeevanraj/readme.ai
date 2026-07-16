"""Enumerations for the explanation module."""

from __future__ import annotations

from enum import StrEnum


class SelectionType(StrEnum):
    """The kind of selection the reader made, decided by the backend."""

    WORD = "word"
    SENTENCE = "sentence"
    PARAGRAPH = "paragraph"
