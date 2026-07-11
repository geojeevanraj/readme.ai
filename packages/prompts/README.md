# packages/prompts

Versioned LLM prompt templates, treated as reviewed assets rather than inline
strings.

## Responsibility (target)

- Store prompt templates under version control with explicit version
  identifiers.
- Allow every AI output to be tagged with the `prompt_version` that produced it,
  enabling cache invalidation and quality evaluation when prompts change.
- Subject prompt changes to code review like any other asset.

## Status

**Empty in Sprint 0.2 (foundation).** No AI features exist yet. Prompts are
added when the AI Service is introduced in a later sprint.
