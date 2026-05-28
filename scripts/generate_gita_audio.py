#!/usr/bin/env python3
"""Generate Bhagavad Gita verse MP3 assets with OpenAI TTS.

Default behavior is intentionally limited to Chapter 2, Verse 47 so the audio
pipeline can be tested before generating the full 700-verse set.

Required:
  pip3 install openai python-dotenv

Required .env:
  OPENAI_API_KEY=...
"""

from __future__ import annotations

import argparse
import json
import os
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
        description="Generate local MP3 audio files for Gita Wisdom verses.",
    )
    parser.add_argument("--input-dir", type=Path, default=DEFAULT_INPUT_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--chapter", type=int, default=2)
    parser.add_argument("--verse", type=int, default=47)
    parser.add_argument("--all", action="store_true", help="Generate all chapters.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing MP3s.")
    parser.add_argument("--model", default="gpt-4o-mini-tts")
    parser.add_argument("--voice", default="alloy")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    load_dotenv(ROOT / ".env")
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key and not args.dry_run:
        print("ERROR: OPENAI_API_KEY is missing. Add it to .env.", file=sys.stderr)
        return 1

    client = OpenAI(api_key=api_key) if not args.dry_run else None

    targets = _load_target_verses(
        input_dir=args.input_dir,
        chapter_number=args.chapter,
        verse_number=args.verse,
        all_verses=args.all,
    )
    if not targets:
        print("ERROR: No matching verses found.", file=sys.stderr)
        return 1

    print(f"Loaded {len(targets)} verse target(s).")
    generated = 0
    skipped = 0
    failed = 0

    for verse in targets:
        chapter_number = _read_int(verse.get("chapterNumber") or verse.get("chapter_number"))
        verse_number = _read_int(
            verse.get("verseNumber")
            or verse.get("verse_number")
            or verse.get("number")
            or verse.get("verse")
        )
        output_path = (
            args.output_dir
            / f"chapter_{chapter_number}"
            / f"verse_{verse_number}.mp3"
        )

        if output_path.exists() and not args.force:
            print(f"SKIP: {output_path} already exists")
            skipped += 1
            continue

        audio_text = _audio_text_for_verse(verse, chapter_number, verse_number)
        if not audio_text:
            print(
                f"ERROR: Chapter {chapter_number} Verse {verse_number} has no readable text.",
                file=sys.stderr,
            )
            failed += 1
            continue

        try:
            if args.dry_run:
                print(f"DRY RUN: Would generate {output_path}")
                print(f"TEXT PREVIEW: {audio_text[:260]}...")
            else:
                _generate_openai_tts(
                    client=client,
                    model=args.model,
                    voice=args.voice,
                    text=audio_text,
                    output_path=output_path,
                )
                print(f"SUCCESS: Generated {output_path}")
            generated += 1
        except Exception as error:  # noqa: BLE001 - script should log and continue.
            print(
                f"ERROR: Failed Chapter {chapter_number} Verse {verse_number}: {error}",
                file=sys.stderr,
            )
            failed += 1

    print(
        "Done. "
        f"Generated: {generated}. Skipped: {skipped}. Failed: {failed}."
    )
    return 1 if failed else 0


def _load_target_verses(
    *,
    input_dir: Path,
    chapter_number: int,
    verse_number: int,
    all_verses: bool,
) -> list[dict[str, Any]]:
    chapters = range(1, 19) if all_verses else [chapter_number]
    targets: list[dict[str, Any]] = []

    for current_chapter in chapters:
        chapter_file = input_dir / f"chapter{current_chapter}.json"
        if not chapter_file.exists():
            print(f"WARN: Missing chapter file: {chapter_file}", file=sys.stderr)
            continue

        try:
            verses = _load_verses(chapter_file, current_chapter)
            print(f"INFO: Chapter {current_chapter}: loaded {len(verses)} verses")
        except Exception as error:  # noqa: BLE001 - keep batch generation resilient.
            print(f"ERROR: Could not parse {chapter_file}: {error}", file=sys.stderr)
            continue

        for verse in verses:
            current_verse = _read_int(
                verse.get("verseNumber")
                or verse.get("verse_number")
                or verse.get("number")
                or verse.get("verse")
            )
            if all_verses or current_verse == verse_number:
                targets.append(verse)

    return targets


def _load_verses(path: Path, chapter_number: int) -> list[dict[str, Any]]:
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


def _audio_text_for_verse(
    verse: dict[str, Any],
    chapter_number: int,
    verse_number: int,
) -> str:
    sanskrit = _clean_text(
        verse.get("sanskrit") or verse.get("text") or verse.get("sloka")
    )
    transliteration = _clean_text(
        verse.get("transliteration") or verse.get("transliterationText")
    )
    english = _clean_text(
        verse.get("englishTranslation")
        or verse.get("translation")
        or verse.get("english")
    )

    devotional_text = sanskrit or transliteration
    lines = [
        f"Bhagavad Gita, Chapter {chapter_number}, Verse {verse_number}.",
        devotional_text,
    ]
    if transliteration and sanskrit:
        lines.append(f"Transliteration: {transliteration}")
    if english:
        lines.append(f"English translation: {english}")

    return "\n\n".join(line for line in lines if line)


def _generate_openai_tts(
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
        "Read in a slow, devotional, peaceful tone. "
        "For Sanskrit or transliteration, sound meditative and reverent. "
        "For English, use soft calm narration."
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
    if content:
        output_path.write_bytes(content)
        return
    raise RuntimeError("OpenAI TTS response did not include writable audio content.")


def _clean_text(value: Any) -> str:
    if value is None:
        return ""
    return " ".join(str(value).split()).strip()


def _read_int(value: Any) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if value is None:
        return 0
    return int(str(value).strip())


if __name__ == "__main__":
    raise SystemExit(main())
