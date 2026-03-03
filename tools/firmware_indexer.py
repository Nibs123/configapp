#!/usr/bin/env python3
"""Index offline firmware cache into JSON."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE_ROOT = ROOT / "firmware-cache"
OUTPUT = CACHE_ROOT / "firmware_index.json"


def sha256sum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_index() -> dict:
    stacks: dict[str, dict] = {}
    for stack_dir in sorted([d for d in CACHE_ROOT.iterdir() if d.is_dir()]):
        stack_data = {}
        for target_dir in sorted([d for d in stack_dir.iterdir() if d.is_dir()]):
            target_data = {}
            for version_dir in sorted([d for d in target_dir.iterdir() if d.is_dir()]):
                files = []
                for firmware in sorted(version_dir.glob("*")):
                    if firmware.is_file() and firmware.suffix.lower() in {".hex", ".bin"}:
                        files.append(
                            {
                                "name": firmware.name,
                                "path": str(firmware.relative_to(ROOT)),
                                "sha256": sha256sum(firmware),
                                "size": firmware.stat().st_size,
                            }
                        )
                if files:
                    target_data[version_dir.name] = files
            if target_data:
                stack_data[target_dir.name] = target_data
        stacks[stack_dir.name] = stack_data
    return stacks


def main():
    CACHE_ROOT.mkdir(parents=True, exist_ok=True)
    index = build_index()
    with OUTPUT.open("w", encoding="utf-8") as handle:
        json.dump(index, handle, indent=2)
    print(f"Wrote firmware index: {OUTPUT}")


if __name__ == "__main__":
    main()
