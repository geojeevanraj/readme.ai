"""Explanation module.

Provides a single, contextual word explanation for the reader. It is not a chat
or conversational feature: it explains exactly one word using the surrounding
passage, behind a provider abstraction so the reader never talks to Ollama
directly (ADR 0003).
"""
