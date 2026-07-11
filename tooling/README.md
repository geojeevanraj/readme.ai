# tooling

Shared developer tooling and configuration that is not owned by a single
application.

## Contents

Currently this directory holds cross-cutting configuration that lives at the
repository root by necessity (and is documented here for discoverability):

- **`../.pre-commit-config.yaml`** — git hooks spanning both ecosystems.
- **`../.editorconfig`** — editor defaults for all file types.

As the project grows, shared scripts (e.g. a one-shot `verify` that runs every
quality gate across `apps/api` and `apps/mobile`) belong here so they are not
duplicated per app.

## Status

Intentionally minimal in Sprint 0.2. Per-app quality commands are documented in
`docs/development-setup.md`; CI runs them in `.github/workflows/`.
