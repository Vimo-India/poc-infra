#!/usr/bin/env python3
"""Update images.json with separate repository and tag fields."""

from __future__ import annotations

import datetime
import json
import sys
from pathlib import Path


def split_image(image: str) -> tuple[str, str]:
    if "@" in image:
        repository, digest = image.split("@", 1)
        return repository, digest

    last_segment = image.rsplit("/", 1)[-1]
    if ":" in last_segment:
        repository, tag = image.rsplit(":", 1)
        return repository, tag

    return image, ""


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as fh:
        data = json.load(fh)
    return data if isinstance(data, dict) else {}


def main() -> int:
    if len(sys.argv) != 7:
        print(
            "usage: update_images_json.py <images_file> <app_name> <image> <source_sha> <source_trigger_actor> <source_commit_author>",
            file=sys.stderr,
        )
        return 2

    images_file = Path(sys.argv[1])
    app_name = sys.argv[2]
    image = sys.argv[3]
    source_sha = sys.argv[4]
    source_trigger_actor = sys.argv[5]
    source_commit_author = sys.argv[6]

    data = load_json(images_file)
    data.setdefault("schema_version", 1)

    applications = data.get("applications")
    if not isinstance(applications, dict):
        applications = {}
    data["applications"] = applications

    entry = applications.get(app_name)
    if not isinstance(entry, dict):
        entry = {}
    applications[app_name] = entry

    repository, tag = split_image(image)
    entry["repository"] = repository
    entry["tag"] = tag
    entry["sha"] = source_sha
    entry["source_trigger_actor"] = source_trigger_actor
    entry.pop("source_actor", None)
    entry["source_commit_author"] = source_commit_author
    entry["updated_at"] = (
        datetime.datetime.now(datetime.timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )

    images_file.parent.mkdir(parents=True, exist_ok=True)
    with images_file.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, sort_keys=True)
        fh.write("\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
