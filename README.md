# poc-infra

Infrastructure metadata repository for cross-repository image promotion signals.

## images.json

- Source of truth file: `images.json`
- Top-level keys:
  - `schema_version`
  - `applications`
- Each app entry is created automatically by CI when first seen.
- Each app entry contains:
  - `repository`
  - `tag`
  - `sha`
  - `updated_at`

## Branch strategy

- `main`: alpha image pointers from app `main` branch builds
- `story/*`: story image pointers from matching app `story/*` builds
- `release/YY.MM`: RC image pointers from matching app `release/YY.MM` builds

Cross-repository sync workflow updates these branches directly.
