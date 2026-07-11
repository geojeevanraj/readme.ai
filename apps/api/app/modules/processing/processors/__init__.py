"""Processors turn raw uploaded files into structured documents.

Each processor implements :class:`BookProcessor`. The reader and dispatcher never
depend on a specific processor — only on the interface — so PDF, EPUB, DOCX, and
OCR processors can be added later without changes elsewhere.
"""
