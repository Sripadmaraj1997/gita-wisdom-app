#!/usr/bin/env python3
"""Smoke-test local MP3 generation with gTTS.

This avoids OpenAI quota while still proving the Gita Wisdom audio pipeline can
write playable MP3 files.

Output:
  assets/audio/gita/test_tts.mp3
"""

from __future__ import annotations

import sys
from pathlib import Path

from gtts import gTTS


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = ROOT / "assets" / "audio" / "gita" / "test_tts.mp3"


def main() -> int:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    text = (
        "Bhagavad Gita, Chapter 2, Verse 47. "
        "Karmanye vadhikaraste, ma phaleshu kadachana. "
        "You have a right to action alone, never to its fruits."
    )

    print("Generating gTTS smoke test...")
    print(f"Output: {OUTPUT_PATH}")

    try:
        tts = gTTS(text=text, lang="en", slow=True)
        tts.save(str(OUTPUT_PATH))
    except Exception as error:  # noqa: BLE001 - CLI should show simple failures.
        print(f"ERROR: gTTS generation failed: {error}", file=sys.stderr)
        return 1

    print(f"SUCCESS: generated {OUTPUT_PATH}")
    print(f"Size: {OUTPUT_PATH.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
