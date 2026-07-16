"""Context extraction for word explanations.

Normalises and bounds the reader-supplied passage so the prompt stays focused
and within a sensible size, centring the window on the selected word.
"""

from __future__ import annotations

_MAX_CONTEXT_CHARS = 600


class ContextExtractor:
    """Produces a clean, bounded context window around the selected word."""

    def __init__(self, *, max_chars: int = _MAX_CONTEXT_CHARS) -> None:
        self._max_chars = max_chars

    def extract(self, *, reader_context: str, word: str) -> str:
        collapsed = " ".join(reader_context.split())
        if not collapsed:
            return word
        if len(collapsed) <= self._max_chars:
            return collapsed
        return self._window(collapsed, word)

    def _window(self, text: str, word: str) -> str:
        half = self._max_chars // 2
        center = text.lower().find(word.lower())
        if center == -1:
            center = len(text) // 2
        start = max(0, center - half)
        end = min(len(text), start + self._max_chars)
        return text[start:end].strip()
