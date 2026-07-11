"""Book Processing module.

Converts an uploaded book into a structured internal document
(Document -> Chapter -> Section -> Paragraph -> Sentence) with stable anchors,
persists it, and tracks processing status. It is completely independent of AI:
future AI/search features consume this structured representation rather than raw
files.

The reader and all future modules address content via the **stable anchors**
produced here, never via page numbers.
"""
