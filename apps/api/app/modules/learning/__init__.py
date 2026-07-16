"""Learning Intelligence Engine (LIE).

LIE is the intelligence layer that decides *how* ReadMe.ai should help a reader.
It sits above the Explanation Service: it runs pluggable learner-aware
capabilities, then delegates explanation generation to the Explanation Service
and aggregates the results. The reader is unaware LIE exists — it calls the same
explanation API.

Future educational intelligence is added by implementing a new
``LearningCapability`` and registering it; the engine never changes.
"""
