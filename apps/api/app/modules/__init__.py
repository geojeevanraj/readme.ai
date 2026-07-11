"""Business capability modules.

Each module is a bounded vertical slice (models, schemas, repository, service,
dependencies, and routes) that depends on lower layers (``app.core``,
``app.db``) but never on its sibling modules' internals.
"""
