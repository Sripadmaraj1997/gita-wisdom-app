#!/usr/bin/env python3
"""Generate verse MP3 files using only Gita verse transliteration.

Input:
  assets/data/gita/chapter1.json ... assets/data/gita/chapter18.json

Output:
  assets/audio/gita/chapter_1/verse_1.mp3
  assets/audio/gita/chapter_1/verse_2.mp3

Required:
  pip3 install openai python-dotenv

Required .env:
  OPENAI_API_KEY=...
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from openai import OpenAI


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT_DIR = ROOT / "assets" / "data" / "gita"
DEFAULT_OUTPUT_DIR = ROOT / "assets" / "audio" / "gita"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate transliteration-only Bhagavad Gita verse audio.",
    )
    parser.add_argument("--chapter", type=int, required=True)
    parser.add_argument("--verse", type=int, default=None)
    parser.add_argument("--all", action="store_true", help="Generate all chapters.")
    parser.add_argument("--input-dir", type=Path, default=DEFAULT_INPUT_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--model", default="gpt-4o-mini-tts")
    parser.add_argument("--voice", default="alloy")
    args = parser.parse_args()

    if args.all:
        chapters = range(1, 19)
    else:
        if args.chapter < 1 or args.chapter > 18:
            print("ERROR: --chapter must be between 1 and 18.", file=sys.stderr)
            return 1
        chapters = [args.chapter]

    load_dotenv(ROOT / ".env")
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key and not args.dry_run:
        print("ERROR: OPENAI_API_KEY is missing. Add it to .env.", file=sys.stderr)
        return 1

    client = OpenAI(api_key=api_key) if not args.dry_run else None

    generated = 0
    skipped = 0
    missing = 0
    failed = 0

    for chapter_number in chapters:
        chapter_file = args.input_dir / f"chapter{chapter_number}.json"
        try:
            verses = _load_verses(chapter_file, chapter_number)
        except Exception as error:  # noqa: BLE001 - batch script should continue.
            print(f"ERROR: Could not load {chapter_file}: {error}", file=sys.stderr)
            failed += 1
            continue

        print(f"Chapter {chapter_number}: loaded {len(verses)} verse records.")
        for verse in verses:
            verse_number = _read_int(
                verse.get("verseNumber")
                or verse.get("verse_number")
                or verse.get("number")
                or verse.get("verse")
            )
            if args.verse is not None and verse_number != args.verse:
                continue

            transliteration = _clean_text(
                verse.get("transliteration") or verse.get("transliterationText")
            )
            if not transliteration:
                print(
                    f"WARN: Chapter {chapter_number}, Verse {verse_number}: "
                    "missing transliteration. Skipping.",
                    file=sys.stderr,
                )
                missing += 1
                continue

            output_path = (
                args.output_dir
                / f"chapter_{chapter_number}"
                / f"verse_{verse_number}.mp3"
            )
            if output_path.exists() and not args.overwrite:
                print(f"SKIP existing: {output_path}")
                skipped += 1
                continue

            text = _build_audio_text(chapter_number, verse_number, transliteration)
            try:
                if args.dry_run:
                    print(f"DRY RUN: {output_path}")
                    print(text)
                else:
                    _generate_tts(
                        client=client,
                        model=args.model,
                        voice=args.voice,
                        text=text,
                        output_path=output_path,
                    )
                    print(f"SUCCESS: {output_path}")
                generated += 1
            except Exception as error:  # noqa: BLE001 - log and continue.
                print(
                    f"ERROR: Chapter {chapter_number}, Verse {verse_number}: {error}",
                    file=sys.stderr,
                )
                failed += 1

    print(
        "Done. "
        f"Generated: {generated}. "
        f"Skipped existing: {skipped}. "
        f"Missing transliteration: {missing}. "
        f"Failed: {failed}."
    )
    return 1 if failed else 0


def _load_verses(path: Path, chapter_number: int) -> list[dict[str, Any]]:
    if not path.exists():
        raise FileNotFoundError(path)

    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    raw_verses = _extract_raw_verses(data)
    verses: list[dict[str, Any]] = []
    for raw in raw_verses:
        if isinstance(raw, dict):
            verse = dict(raw)
            verse.setdefault("chapterNumber", chapter_number)
            verses.append(verse)
    return verses


def _extract_raw_verses(data: Any) -> list[Any]:
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        if isinstance(data.get("verses"), list):
            return data["verses"]
        chapter = data.get("chapter")
        if isinstance(chapter, dict) and isinstance(chapter.get("verses"), list):
            return chapter["verses"]
        nested = data.get("data")
        if isinstance(nested, dict) and isinstance(nested.get("verses"), list):
            return nested["verses"]
    raise ValueError("Unsupported chapter JSON structure")


def _build_audio_text(
    chapter_number: int,
    verse_number: int,
    transliteration: str,
) -> str:
    paced_transliteration = _pace_transliteration(transliteration)
    return (
        f"Chapter {chapter_number}, Verse {verse_number}.\n\n"
        f"{paced_transliteration}"
    )


def _pace_transliteration(transliteration: str) -> str:
    transliteration = re.sub(r"\|\|\s*\d+\s*-\s*\d+\s*\|\|", "", transliteration)
    lines = [
        _clean_text(line)
        for line in transliteration.splitlines()
        if _clean_text(line)
    ]
    if not lines:
        lines = [_clean_text(transliteration)]

    paced_lines: list[str] = []
    for line in lines:
        line = re.sub(r"\s*\|\|?\s*", ".\n", line)
        line = re.sub(r"\s*\.\s*", ".\n", line)
        for part in line.splitlines():
            part = _clean_text(part)
            if not part:
                continue
            if not part.endswith((".", "?", "!", "||")):
                part = f"{part}."
            paced_lines.append(part)

    return "\n\n".join(paced_lines)


def _generate_tts(
    *,
    client: OpenAI | None,
    model: str,
    voice: str,
    text: str,
    output_path: Path,
) -> None:
    if client is None:
        raise RuntimeError("OpenAI client is not initialized.")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    instructions = (
        "Read slowly and peacefully with devotional warmth. "
        "Use gentle pauses between transliteration lines. "
        "Keep Sanskrit transliteration pronunciation clear and unhurried. "
        "Do not add English translation or commentary."
    )

    try:
        response = client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            instructions=instructions,
            response_format="mp3",
        )
    except TypeError:
        response = client.audio.speech.create(
            model=model,
            voice=voice,
            input=text,
            response_format="mp3",
        )

    if hasattr(response, "write_to_file"):
        response.write_to_file(output_path)
        return
    if hasattr(response, "stream_to_file"):
        response.stream_to_file(output_path)
        return

    content = getattr(response, "content", None)
    if content is None:
        raise RuntimeError("OpenAI TTS response did not include audio content.")
    output_path.write_bytes(content)


def _clean_text(value: Any) -> str:
    if value is None:
        return ""
    return re.sub(r"[ \t]+", " ", str(value).strip())


def _read_int(value: Any) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str):
        match = re.search(r"\d+", value)
        if match:
            return int(match.group(0))
    raise ValueError(f"Could not read integer from {value!r}")


if __name__ == "__main__":
    raise SystemExit(main())
