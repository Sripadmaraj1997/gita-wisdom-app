#!/usr/bin/env python3
"""Smoke-test ElevenLabs TTS for Gita Wisdom.

Reads ELEVENLABS_API_KEY from .env and writes:
  assets/audio/gita/test_elevenlabs.mp3
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs
from elevenlabs.types import VoiceSettings


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = ROOT / "assets" / "audio" / "gita" / "test_elevenlabs.mp3"

# Built-in public ElevenLabs voice: Antoni.
DEFAULT_VOICE_ID = "ErXwobaYiN019PkySvjV"


def main() -> int:
    load_dotenv(ROOT / ".env")
    api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
    if not api_key:
        print("ERROR: ELEVENLABS_API_KEY is missing in .env", file=sys.stderr)
        return 1

    voice_id = os.getenv("ELEVENLABS_VOICE_ID", DEFAULT_VOICE_ID).strip()
    client = ElevenLabs(api_key=api_key)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    text = """
    Use a warm Indian devotional narrator voice.

    Read slowly and peacefully, with devotional warmth and clear Sanskrit pronunciation.

    Use gentle pauses and a calm spiritual tone.

    Bhagavad Gita.

    Chapter 2.

    Verse 47.

    Transliteration.

    Kar-man-ye va-dhi-ka-ra-ste.

    Ma pha-le-shu ka-da-cha-na.

    Meaning.

    You have the right to perform your actions.

    But not to the fruits of those actions.

    Act with devotion.

    Offer your effort.

    Release the result.
    """

    print("Generating ElevenLabs TTS smoke test...")
    print(f"Voice ID: {voice_id}")
    print(f"Output: {OUTPUT_PATH}")

    try:
        audio_stream = client.text_to_speech.convert(
            voice_id=voice_id,
            model_id="eleven_multilingual_v2",
            output_format="mp3_44100_128",
            text=text,
            voice_settings=VoiceSettings(
                stability=0.88,
                similarity_boost=0.66,
                style=0.16,
                speed=0.74,
                use_speaker_boost=True,
            ),
        )
        with OUTPUT_PATH.open("wb") as handle:
            for chunk in audio_stream:
                if chunk:
                    handle.write(chunk)
    except Exception as error:  # noqa: BLE001 - CLI should report simple failures.
        print(f"ERROR: ElevenLabs TTS generation failed: {error}", file=sys.stderr)
        return 1

    print(f"SUCCESS: generated {OUTPUT_PATH}")
    print(f"Size: {OUTPUT_PATH.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
