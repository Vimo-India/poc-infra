# sync-images-from-app

Receives cross-repository image metadata sync requests from application repositories and updates `images.json` in `poc-infra`.

Workflow file:
- `.github/workflows/sync-images-from-app.yml`

## Triggers

- `repository_dispatch` with event type `sync-infra-images`
- `workflow_dispatch` for manual testing/debugging

## Branch behavior

- `main` -> updates `main`
- `story/*` -> updates matching story branch
- `release/YY.MM` -> updates matching release branch, but only after approval
- other branches -> no-op success

## Release approval

Release syncs are gated by GitHub environment:

- `release-images-sync`

This means `images.json` is not modified on release branches until a reviewer approves the waiting job in `poc-infra`.

Configure required reviewers in:

- `poc-infra` -> Settings -> Environments -> `release-images-sync`

## Implementation

The workflow uses local scripts in this repository:

- `.github/scripts/sync_images.sh`
- `.github/scripts/update_images_json.py`

These scripts handle:

- missing branch creation
- release-branch seeding rules
- `images.json` update logic
- commit/push with retry
