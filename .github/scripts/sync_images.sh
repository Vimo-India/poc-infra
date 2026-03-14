#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

git fetch origin '+refs/heads/*:refs/remotes/origin/*' --prune

if git show-ref --verify --quiet "refs/remotes/origin/${TARGET_BRANCH}"; then
  echo "[infra-sync] target branch exists: ${TARGET_BRANCH}"
  git checkout -B "${TARGET_BRANCH}" "origin/${TARGET_BRANCH}"
else
  echo "[infra-sync] target branch missing, creating: ${TARGET_BRANCH}"
  seed_branch="main"
  if [[ "${TARGET_BRANCH}" == release/* ]]; then
    latest_release_branch="$(
      git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin/release/* \
        | grep -E '^release/[0-9]{2}\.[0-9]{2}$' \
        | sort -V \
        | tail -n 1 || true
    )"
    if [[ -n "${latest_release_branch}" ]]; then
      seed_branch="${latest_release_branch}"
    fi
    echo "[infra-sync] release branch seed selected: ${seed_branch}"
  fi
  if ! git show-ref --verify --quiet "refs/remotes/origin/${seed_branch}"; then
    echo "[infra-sync] missing seed branch on remote: ${seed_branch}" >&2
    exit 1
  fi
  git checkout -B "${TARGET_BRANCH}" "origin/${seed_branch}"
fi

echo "[infra-sync] updating ${IMAGES_FILE} for app=${APP_NAME}"
python3 "${script_dir}/update_images_json.py" \
  "${IMAGES_FILE}" \
  "${APP_NAME}" \
  "${IMAGE}" \
  "${SOURCE_SHA}" \
  "${SOURCE_TRIGGER_ACTOR}" \
  "${SOURCE_COMMIT_AUTHOR:-}"

git add "${IMAGES_FILE}"
if git diff --cached --quiet; then
  echo "[infra-sync] no changes detected in ${IMAGES_FILE}, skipping commit"
  exit 0
fi

git commit -m "ci: sync ${APP_NAME} image from ${SOURCE_BRANCH}"

for attempt in 1 2 3; do
  echo "[infra-sync] push attempt ${attempt} to ${TARGET_BRANCH}"
  if git push origin "HEAD:${TARGET_BRANCH}"; then
    echo "[infra-sync] push succeeded"
    exit 0
  fi
  if [[ "${attempt}" -eq 3 ]]; then
    echo "[infra-sync] push failed after retries" >&2
    exit 1
  fi
  echo "[infra-sync] non-fast-forward or conflict, rebasing and retrying"
  git fetch origin "${TARGET_BRANCH}:refs/remotes/origin/${TARGET_BRANCH}"
  git rebase "origin/${TARGET_BRANCH}" || {
    git rebase --abort || true
    echo "[infra-sync] rebase failed during retry" >&2
    exit 1
  }
done
