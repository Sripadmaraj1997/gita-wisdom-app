#!/usr/bin/env python3
"""Generate verse-by-verse English Bhagavad Gita audio with ElevenLabs.

Examples:
  python3 scripts/generate_english_verse_audio.py --chapter 2
  python3 scripts/generate_english_verse_audio.py --chapter 2 --verse 47
  python3 scripts/generate_english_verse_audio.py --all

The script intentionally does not generate all 700 verses unless --all is
passed. Existing MP3 files are skipped unless --overwrite is passed.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs
from elevenlabs.types import VoiceSettings


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT_DIR = ROOT / "assets" / "data" / "gita"
DEFAULT_OUTPUT_DIR = ROOT / "assets" / "audio" / "english"

# Built-in public ElevenLabs voice: Antoni.
DEFAULT_VOICE_ID = "ErXwobaYiN019PkySvjV"
DEFAULT_MODEL_ID = "eleven_multilingual_v2"

EXPECTED_VERSE_COUNTS = {
    1: 47,
    2: 72,
    3: 43,
    4: 42,
    5: 29,
    6: 47,
    7: 30,
    8: 28,
    9: 34,
    10: 42,
    11: 55,
    12: 20,
    13: 35,
    14: 27,
    15: 20,
    16: 24,
    17: 28,
    18: 78,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate English MP3 narration files for Bhagavad Gita verses.",
    )
    scope = parser.add_mutually_exclusive_group(required=True)
    scope.add_argument("--chapter", type=int, help="Chapter number to generate.")
    scope.add_argument(
        "--all",
        action="store_true",
        help="Explicitly generate all 18 chapters.",
    )
    parser.add_argument("--verse", type=int, help="Optional verse number for one verse.")
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=DEFAULT_INPUT_DIR,
        help="Directory containing chapter1.json through chapter18.json.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Directory where chapter_N/verse_N.mp3 files will be written.",
    )
    parser.add_argument(
        "--voice-id",
        default=os.getenv("ELEVENLABS_VOICE_ID", DEFAULT_VOICE_ID),
        help="ElevenLabs voice ID. Defaults to ELEVENLABS_VOICE_ID or Antoni.",
    )
    parser.add_argument(
        "--model-id",
        default=DEFAULT_MODEL_ID,
        help=f"ElevenLabs model ID. Default: {DEFAULT_MODEL_ID}.",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=1.2,
        help="Delay in seconds between API requests to avoid rate limits.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing MP3 files.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned work without calling ElevenLabs.",
    )
    return parser.parse_args()


def clean_text(value: Any) -> str:
    if value is None:
        return ""
    text = str(value)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def first_text(verse: dict[str, Any], keys: list[str]) -> str:
    for key in keys:
        value = clean_text(verse.get(key))
        if value:
            return value
    return ""


def read_int(value: Any, fallback: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return fallback


def extract_verse_list(raw: Any) -> list[dict[str, Any]]:
    if isinstance(raw, list):
        return [item for item in raw if isinstance(item, dict)]
    if not isinstance(raw, dict):
        return []

    direct = raw.get("verses")
    if isinstance(direct, list):
        return [item for item in direct if isinstance(item, dict)]

    for container_key in ("chapter", "data"):
        container = raw.get(container_key)
        if isinstance(container, dict) and isinstance(container.get("verses"), list):
            return [item for item in container["verses"] if isinstance(item, dict)]

    return []


def load_chapter(input_dir: Path, chapter_number: int) -> list[dict[str, Any]]:
    path = input_dir / f"chapter{chapter_number}.json"
    if not path.exists():
        raise FileNotFoundError(f"Missing JSON file: {path}")

    with path.open("r", encoding="utf-8") as handle:
        raw = json.load(handle)

    verses = extract_verse_list(raw)
    expected_count = EXPECTED_VERSE_COUNTS.get(chapter_number)
    print(f"Chapter {chapter_number}: loaded {len(verses)} verse records from {path}")
    if expected_count and len(verses) != expected_count:
        print(
            f"WARNING: Chapter {chapter_number} expected {expected_count} verses, "
            f"but JSON has {len(verses)}.",
            file=sys.stderr,
        )
    return verses


def format_translation_for_pacing(translation: str) -> str:
    """Add gentle pauses without adding commentary or non-translation content."""
    text = clean_text(translation)
    if not text:
        return ""

    # Preserve the exact English meaning while making the TTS cadence slower.
    text = re.sub(r";\s*", "...\n", text)
    text = re.sub(r":\s*", "...\n", text)
    text = re.sub(r",\s+", ",\n", text)
    text = re.sub(r"([.!?])\s+", r"\1\n\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def narration_text(chapter_number: int, verse_number: int, translation: str) -> str:
    paced_translation = format_translation_for_pacing(translation)
    return f"Chapter {chapter_number}, Verse {verse_number}...\n\n{paced_translation}"


def write_audio_file(
    client: ElevenLabs,
    output_path: Path,
    text: str,
    voice_id: str,
    model_id: str,
) -> None:
    temp_path = output_path.with_suffix(".tts.tmp.mp3")
    audio_stream = client.text_to_speech.convert(
        voice_id=voice_id,
        model_id=model_id,
        output_format="mp3_44100_128",
        text=text,
        voice_settings=VoiceSettings(
            stability=0.85,
            similarity_boost=0.55,
            style=0.1,
            speed=0.78,
            use_speaker_boost=True,
        ),
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with temp_path.open("wb") as handle:
            for chunk in audio_stream:
                if chunk:
                    handle.write(chunk)
        if temp_path.stat().st_size == 0:
            raise RuntimeError("ElevenLabs returned an empty audio file.")
        temp_path.replace(output_path)
    except Exception:
        if temp_path.exists():
            temp_path.unlink()
        raise


def selected_chapters(args: argparse.Namespace) -> list[int]:
    if args.all:
        return list(range(1, 19))
    if args.chapter < 1 or args.chapter > 18:
        raise ValueError("--chapter must be between 1 and 18.")
    return [args.chapter]


def generate_for_chapter(
    args: argparse.Namespace,
    client: ElevenLabs | None,
    chapter_number: int,
) -> tuple[int, int, int]:
    verses = load_chapter(args.input_dir, chapter_number)
    if args.verse is not None:
        verses = [
            verse
            for index, verse in enumerate(verses, start=1)
            if read_int(verse.get("verseNumber"), index) == args.verse
        ]
        if not verses:
            print(
                f"WARNING: Chapter {chapter_number} verse {args.verse} was not found.",
                file=sys.stderr,
            )
            return (0, 0, 1)

    total = len(verses)
    generated = 0
    skipped = 0
    warnings = 0

    for index, verse in enumerate(verses, start=1):
        verse_number = read_int(verse.get("verseNumber"), index)
        translation = first_text(verse, ["englishTranslation", "translation"])
        output_path = (
            args.output_dir
            / f"chapter_{chapter_number}"
            / f"verse_{verse_number}.mp3"
        )
        label = f"Chapter {chapter_number} Verse {verse_number}"

        if not translation:
            print(
                f"WARNING: {label} has no englishTranslation or translation. Skipping."
            )
            skipped += 1
            warnings += 1
            continue

        if output_path.exists() and output_path.stat().st_size > 0 and not args.overwrite:
            print(f"[{index}/{total}] SKIP existing: {output_path}")
            skipped += 1
            continue
        if output_path.exists() and output_path.stat().st_size == 0:
            print(f"[{index}/{total}] Existing file is empty; regenerating: {output_path}")

        text = narration_text(chapter_number, verse_number, translation)
        print(f"[{index}/{total}] Generating {label} -> {output_path}")

        if args.dry_run:
            preview = text.replace("\n", " ")
            print(f"DRY RUN: {preview[:220]}")
            generated += 1
            continue

        if client is None:
            raise RuntimeError("ElevenLabs client was not initialized.")

        try:
            write_audio_file(
                client=client,
                output_path=output_path,
                text=text,
                voice_id=args.voice_id,
                model_id=args.model_id,
            )
        except Exception as error:  # noqa: BLE001 - CLI should keep running.
            print(f"ERROR: {label} failed: {error}", file=sys.stderr)
            warnings += 1
            continue

        generated += 1
        print(f"SUCCESS: {output_path} ({output_path.stat().st_size} bytes)")
        if args.delay > 0:
            time.sleep(args.delay)

    return (generated, skipped, warnings)


def main() -> int:
    args = parse_args()
    load_dotenv(ROOT / ".env")

    if args.verse is not None and args.all:
        print("ERROR: --verse can only be used with --chapter.", file=sys.stderr)
        return 1

    try:
        chapters = selected_chapters(args)
    except ValueError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    client: ElevenLabs | None = None
    if not args.dry_run:
        api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
        if not api_key:
            print("ERROR: ELEVENLABS_API_KEY is missing in .env", file=sys.stderr)
            return 1
        client = ElevenLabs(api_key=api_key)

    print("English verse audio generation")
    print(f"Input JSON: {args.input_dir}")
    print(f"Output MP3: {args.output_dir}")
    print(f"Voice ID: {args.voice_id}")
    print(f"Model ID: {args.model_id}")
    print("Audio: narration only")
    if args.dry_run:
        print("Mode: dry run, no API calls will be made.")
    if args.all:
        print("Scope: all 18 chapters requested explicitly.")
    else:
        scope = f"chapter {args.chapter}"
        if args.verse is not None:
            scope += f", verse {args.verse}"
        print(f"Scope: {scope}")

    total_generated = 0
    total_skipped = 0
    total_warnings = 0

    for chapter_number in chapters:
        try:
            generated, skipped, warnings = generate_for_chapter(
                args=args,
                client=client,
                chapter_number=chapter_number,
            )
        except Exception as error:  # noqa: BLE001 - CLI should report simple failures.
            print(f"ERROR: Chapter {chapter_number} failed: {error}", file=sys.stderr)
            return 1
        total_generated += generated
        total_skipped += skipped
        total_warnings += warnings

    print("Done.")
    print(f"Generated: {total_generated}")
    print(f"Skipped: {total_skipped}")
    print(f"Warnings/errors: {total_warnings}")
    return 0 if total_warnings == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
