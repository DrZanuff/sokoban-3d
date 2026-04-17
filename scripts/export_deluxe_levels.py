#!/usr/bin/env python3
"""Export selected Sokoban Deluxe levels as JSON and PNG images.

Fetches Borgar's Deluxe level pack, extracts levels 1..11 except 7, and writes:
- JSON data array (level index + ASCII rows)
- One deterministic PNG per level rendered from symbols
"""

from __future__ import annotations

import json
import io
import re
import urllib.request
from dataclasses import dataclass
from pathlib import Path

import cairosvg
from PIL import Image

SOURCE_URL = "https://borgar.net/programs/sokoban/levels/Deluxe.txt"
OUTPUT_DIR = Path("generated/deluxe_levels")
DATA_JSON_PATH = OUTPUT_DIR / "deluxe_levels_1_11_skip_7.json"
ASSETS_DIR = Path("generated")
WANTED_LEVELS = {1, 2, 3, 4, 5, 6, 8, 9, 10, 11}
TILE_SIZE = 20
ROOM_PADDING = 1
FLOOR_COLOR = (204, 204, 204, 255)  # matches .soko-floor background #ccc


@dataclass
class Level:
    level_number: int
    rows: list[str]


def fetch_text(url: str) -> str:
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode("utf-8")


def load_levels_from_existing_json(path: Path) -> list[Level]:
    if not path.exists():
        return []
    raw = json.loads(path.read_text(encoding="utf-8"))
    levels: list[Level] = []
    for item in raw:
        number = int(item["level"])
        rows = [str(r) for r in item["rows"]]
        levels.append(Level(level_number=number, rows=rows))
    return levels


def parse_deluxe_levels(raw_text: str) -> list[Level]:
    blocks = [block.strip("\n") for block in raw_text.split("---")]
    levels: list[Level] = []
    marker = re.compile(r"^;1-(\d+)\s*$")

    for block in blocks:
        lines = [line.rstrip() for line in block.splitlines()]
        level_number: int | None = None
        rows: list[str] = []
        collecting = False

        for line in lines:
            stripped = line.strip()
            if not stripped:
                if collecting and rows:
                    break
                continue

            matched = marker.match(stripped)
            if matched:
                level_number = int(matched.group(1))
                collecting = True
                continue

            if collecting and not stripped.startswith(";"):
                rows.append(line.rstrip("\n"))

        if level_number is not None and rows:
            levels.append(Level(level_number=level_number, rows=rows))

    return levels


def normalize_width(rows: list[str]) -> list[str]:
    width = max(len(row) for row in rows)
    return [row.ljust(width, " ") for row in rows]


def crop_to_map_bounds(rows: list[str]) -> list[str]:
    min_x: int | None = None
    max_x: int | None = None
    min_y: int | None = None
    max_y: int | None = None

    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != " ":
                if min_x is None or x < min_x:
                    min_x = x
                if max_x is None or x > max_x:
                    max_x = x
                if min_y is None or y < min_y:
                    min_y = y
                if max_y is None or y > max_y:
                    max_y = y

    if min_x is None or max_x is None or min_y is None or max_y is None:
        return rows

    return [row[min_x : max_x + 1] for row in rows[min_y : max_y + 1]]


def rasterize_svg(path: Path, tile_size: int) -> Image.Image:
    png_bytes = cairosvg.svg2png(url=str(path), output_width=tile_size, output_height=tile_size)
    return Image.open(io.BytesIO(png_bytes)).convert("RGBA")


def load_tiles() -> dict[str, Image.Image]:
    return {
        "#": rasterize_svg(ASSETS_DIR / "wall.svg", TILE_SIZE),
        ".": rasterize_svg(ASSETS_DIR / "dock.svg", TILE_SIZE),
        "$": rasterize_svg(ASSETS_DIR / "box.svg", TILE_SIZE),
        "@": rasterize_svg(ASSETS_DIR / "man.svg", TILE_SIZE),
        "*": rasterize_svg(ASSETS_DIR / "docked-box.svg", TILE_SIZE),
    }


def render_level_png(rows: list[str], output_path: Path, tiles: dict[str, Image.Image]) -> None:
    normalized_rows = crop_to_map_bounds(normalize_width(rows))
    width = len(normalized_rows[0])
    height = len(normalized_rows)
    room_w = width * TILE_SIZE + (ROOM_PADDING * 2)
    room_h = height * TILE_SIZE + (ROOM_PADDING * 2)
    img = Image.new("RGBA", (room_w, room_h), FLOOR_COLOR)
    floor_tile = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), FLOOR_COLOR)

    for y, row in enumerate(normalized_rows):
        for x, ch in enumerate(row):
            left = ROOM_PADDING + x * TILE_SIZE
            top = ROOM_PADDING + y * TILE_SIZE
            img.paste(floor_tile, (left, top))

            if ch in {"#", ".", "$", "@", "*"}:
                tile = tiles[ch]
                img.paste(tile, (left, top), tile)
            elif ch == "+":
                dock_tile = tiles["."]
                man_tile = tiles["@"]
                img.paste(dock_tile, (left, top), dock_tile)
                img.paste(man_tile, (left, top), man_tile)

    img = img.convert("RGB")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, format="PNG")


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    tiles = load_tiles()
    try:
        raw_text = fetch_text(SOURCE_URL)
        parsed = parse_deluxe_levels(raw_text)
    except Exception:
        parsed = load_levels_from_existing_json(DATA_JSON_PATH)
        if not parsed:
            raise
    picked = [lv for lv in parsed if lv.level_number in WANTED_LEVELS]
    picked.sort(key=lambda lv: lv.level_number)

    data = []
    for level in picked:
        rows = normalize_width(level.rows)
        data.append(
            {
                "pack": "Deluxe",
                "level": level.level_number,
                "rows": rows,
                "width": len(rows[0]),
                "height": len(rows),
            }
        )
        png_path = OUTPUT_DIR / f"deluxe_level_{level.level_number:02d}.png"
        render_level_png(rows, png_path, tiles)

    DATA_JSON_PATH.write_text(json.dumps(data, indent=2), encoding="utf-8")
    print(f"Wrote {len(data)} levels to {DATA_JSON_PATH}")
    print(f"PNG output dir: {OUTPUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
