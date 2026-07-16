"""Explanation strategies (Strategy Pattern).

The service classifies the selection, then delegates to the matching strategy —
avoiding large conditionals. Each strategy owns its prompt template and output
shaping (sentence limit, which fields it fills).
"""

from app.modules.explanation.strategies.base import (
    ExplanationStrategy,
    StrategyResult,
)
from app.modules.explanation.strategies.paragraph import (
    ParagraphExplanationStrategy,
)
from app.modules.explanation.strategies.sentence import (
    SentenceExplanationStrategy,
)
from app.modules.explanation.strategies.word import WordExplanationStrategy

__all__ = [
    "ExplanationStrategy",
    "ParagraphExplanationStrategy",
    "SentenceExplanationStrategy",
    "StrategyResult",
    "WordExplanationStrategy",
]
