#!/usr/bin/env python3
"""Generate a static BuilderIcons JSON cache from Roblox font files."""

from __future__ import annotations

import json
import logging
import sys
from contextlib import redirect_stderr
from collections import defaultdict
from datetime import datetime, timezone
from io import BytesIO
from io import StringIO
from pathlib import Path
from typing import Any
from urllib.request import urlopen

from fontTools.ttLib import TTFont

logging.getLogger("fontTools").setLevel(logging.ERROR)

BASE_URL = (
    "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/"
    "refs/heads/roblox/LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/Font/"
)
FONT_FILES = {
    "regular": "BuilderIcons-Regular.ttf",
    "filled": "BuilderIcons-Filled.ttf",
}
OUTPUT_PATH = Path(".well-known") / "buildericons" / "icons.json"


def is_private_use(codepoint: int) -> bool:
    return (
        0xE000 <= codepoint <= 0xF8FF
        or 0xF0000 <= codepoint <= 0xFFFFD
        or 0x100000 <= codepoint <= 0x10FFFD
    )


def choose_component_codepoint(codepoints: set[int]) -> int | None:
    if not codepoints:
        return None
    public_codepoints = sorted(cp for cp in codepoints if not is_private_use(cp))
    if public_codepoints:
        return public_codepoints[0]
    return sorted(codepoints)[0]


def choose_icon_codepoint(codepoints: set[int]) -> int | None:
    if not codepoints:
        return None
    private_use_codepoints = sorted(cp for cp in codepoints if is_private_use(cp))
    if private_use_codepoints:
        return private_use_codepoints[0]
    return sorted(codepoints)[0]


def format_codepoint(codepoint: int) -> str:
    return f"U+{codepoint:04X}"


def build_unicode_maps(font: TTFont) -> tuple[dict[str, set[int]], dict[str, int]]:
    glyph_to_codepoints: dict[str, set[int]] = defaultdict(set)
    for table in font["cmap"].tables:
        if not table.isUnicode():
            continue
        for codepoint, glyph_name in table.cmap.items():
            glyph_to_codepoints[glyph_name].add(codepoint)

    glyph_to_component_codepoint = {
        glyph_name: choose_component_codepoint(codepoints)
        for glyph_name, codepoints in glyph_to_codepoints.items()
    }
    return glyph_to_codepoints, glyph_to_component_codepoint


def fetch_font(url: str) -> TTFont:
    with urlopen(url) as response:
        with redirect_stderr(StringIO()):
            return TTFont(BytesIO(response.read()))


def ensure_entry(
    entries: dict[str, dict[str, Any]],
    *,
    components: str,
    label: str,
) -> dict[str, Any]:
    entry = entries.get(components)
    if entry is None:
        entry = {
            "name": label,
            "components": components,
            "styles": {},
        }
        entries[components] = entry
    elif not entry.get("name") and label:
        entry["name"] = label
    return entry


def attach_style(
    entry: dict[str, Any],
    *,
    style: str,
    codepoint: int,
) -> None:
    entry["styles"][style] = {
        "codepoint": codepoint,
        "codePoint": format_codepoint(codepoint),
        "character": chr(codepoint),
    }


def scan_font(entries: dict[str, dict[str, Any]], *, font: TTFont, style: str) -> None:
    glyph_to_codepoints, glyph_to_component_codepoint = build_unicode_maps(font)
    gsub_table = font.get("GSUB")

    if gsub_table is not None:
        for lookup in gsub_table.table.LookupList.Lookup:
            if lookup.LookupType != 4:
                continue
            for subtable in lookup.SubTable:
                ligatures = getattr(subtable, "ligatures", None)
                if not ligatures:
                    continue
                for first_glyph_name, ligature_list in ligatures.items():
                    for ligature in ligature_list:
                        component_glyph_names = [first_glyph_name, *ligature.Component]
                        component_codepoints: list[int] = []
                        for glyph_name in component_glyph_names:
                            codepoint = glyph_to_component_codepoint.get(glyph_name)
                            if codepoint is None:
                                component_codepoints = []
                                break
                            component_codepoints.append(codepoint)
                        if not component_codepoints:
                            continue

                        components = "".join(chr(codepoint) for codepoint in component_codepoints)
                        ligature_glyph_name = ligature.LigGlyph
                        icon_codepoint = choose_icon_codepoint(
                            glyph_to_codepoints.get(ligature_glyph_name, set())
                        )
                        if icon_codepoint is None:
                            continue

                        entry = ensure_entry(
                            entries,
                            components=components,
                            label=ligature_glyph_name or components,
                        )
                        attach_style(entry, style=style, codepoint=icon_codepoint)

    for glyph_name, codepoints in glyph_to_codepoints.items():
        sorted_codepoints = sorted(codepoints)
        if not glyph_name or len(sorted_codepoints) < 2:
            continue

        primary_codepoint = choose_component_codepoint(codepoints)
        if primary_codepoint is None:
            continue

        alternate_codepoints = [cp for cp in sorted_codepoints if cp != primary_codepoint]
        if not alternate_codepoints:
            continue

        icon_codepoint = choose_icon_codepoint(set(alternate_codepoints))
        if icon_codepoint is None:
            continue

        entry = ensure_entry(entries, components=glyph_name, label=glyph_name)
        if style not in entry["styles"]:
            attach_style(entry, style=style, codepoint=icon_codepoint)


def serialize_entries(entries: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    output = []
    for index, components in enumerate(sorted(entries), start=1):
        entry = entries[components]
        styles = entry["styles"]
        output.append(
            {
                "index": index,
                "name": entry["name"] or components,
                "components": components,
                "styles": dict(sorted(styles.items())),
                "availableStyles": sorted(styles),
            }
        )
    return output


def main() -> int:
    entries: dict[str, dict[str, Any]] = {}

    for style, filename in FONT_FILES.items():
        scan_font(
            entries,
            font=fetch_font(f"{BASE_URL}{filename}"),
            style=style,
        )

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "source": {
            "baseUrl": BASE_URL,
            "fonts": FONT_FILES,
        },
        "count": len(entries),
        "icons": serialize_entries(entries),
    }

    previous_generated_at = None
    if OUTPUT_PATH.exists():
        previous_payload = json.loads(OUTPUT_PATH.read_text(encoding="utf-8"))
        previous_generated_at = previous_payload.get("generatedAt")
        comparable_previous = {
            key: value
            for key, value in previous_payload.items()
            if key != "generatedAt"
        }
        if comparable_previous == payload:
            print(f"BuilderIcons cache unchanged: {OUTPUT_PATH} ({payload['count']} icons)")
            return 0

    payload["generatedAt"] = (
        datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    )
    if previous_generated_at and previous_generated_at == payload["generatedAt"]:
        payload["generatedAt"] = previous_generated_at

    OUTPUT_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"BuilderIcons cache refreshed: {OUTPUT_PATH} ({payload['count']} icons)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
