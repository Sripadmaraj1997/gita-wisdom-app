#!/usr/bin/env python3
"""Split one full chapter MP3 into verse-level MP3 assets.

Default input:
  assets/audio/raw/gita-chapter-01.mp3
  assets/audio/raw/gita-chapter-02.mp3
  ...

Default output:
  assets/audio/gita/chapter_1/verse_1.mp3
  assets/audio/gita/chapter_1/verse_2.mp3
  ...

Required:
  pip3 install pydub

Also required by pydub for MP3 reading/writing:
  brew install ffmpeg
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RAW_DIR = ROOT / "assets" / "audio" / "raw"
DEFAULT_OUTPUT_ROOT = ROOT / "assets" / "audio" / "gita"
DEFAULT_SEGMENTS_DIR = ROOT / "scripts" / "audio_segments"
DEFAULT_DATA_DIR = ROOT / "assets" / "data" / "gita"
DEFAULT_CHAPTER = 1
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
AUTO_TUNE_SETTINGS = [
    (1200, -38.0),
    (900, -36.0),
    (700, -34.0),
    (500, -32.0),
]


@dataclass(frozen=True)
class DetectionResult:
    source_label: str
    min_silence_len: int
    silence_thresh: float
    raw_segments: list[tuple[int, int]]
    exportable_segments: list[tuple[int, int]]

    @property
    def exportable_count(self) -> int:
        return len(self.exportable_segments)


@dataclass(frozen=True)
class VoiceSegment:
    start_ms: int
    end_ms: int
    status: str
    notes: str

    @property
    def duration_ms(self) -> int:
        return self.end_ms - self.start_ms


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Split a chapter MP3 into verse-level MP3 files using silence detection.",
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=None,
        help=(
            "Raw chapter MP3. Defaults to "
            "assets/audio/raw/gita-chapter-XX.mp3 for --chapter."
        ),
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Process all chapters 1 through 18.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help=(
            "Verse output directory. Defaults to "
            "assets/audio/gita/chapter_X for --chapter."
        ),
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=DEFAULT_DATA_DIR,
        help="Directory containing assets/data/gita/chapterX.json files.",
    )
    parser.add_argument("--chapter", type=int, default=DEFAULT_CHAPTER)
    parser.add_argument(
        "--make-template",
        action="store_true",
        help="Create scripts/audio_segments/chapter_X_segments.csv from JSON transliteration.",
    )
    parser.add_argument(
        "--suggest",
        action="store_true",
        help="Create CSV template with detected timestamp suggestions. Does not export unless --auto-export is passed.",
    )
    parser.add_argument(
        "--auto-export",
        action="store_true",
        help="With --suggest, export suggested timestamps immediately.",
    )
    parser.add_argument(
        "--preview",
        type=int,
        default=None,
        help="Export a preview MP3 for one verse from the reviewed CSV timestamps.",
    )
    parser.add_argument(
        "--detect",
        action="store_true",
        help="Detect verse segments from chapter audio. This is the default mode.",
    )
    parser.add_argument(
        "--from-csv",
        action="store_true",
        help="Export verse MP3s from scripts/audio_segments/chapter_X_segments.csv.",
    )
    parser.add_argument(
        "--detect-voice",
        action="store_true",
        help="Detect vocal/singing regions and skip music-only clips.",
    )
    parser.add_argument(
        "--segments-csv",
        type=Path,
        default=None,
        help=(
            "Editable segment CSV. Defaults to "
            "scripts/audio_segments/chapter_X_segments.csv."
        ),
    )
    parser.add_argument(
        "--expected-verse-count",
        type=int,
        default=None,
        help=(
            "Expected verse count for this chapter. Defaults to canonical Gita "
            "counts, e.g. Chapter 1 = 47."
        ),
    )
    parser.add_argument(
        "--silence-thresh",
        type=float,
        default=None,
        help=(
            "Silence threshold in dBFS. If omitted, uses chapter average dBFS - 16. "
            "Try lower values like -45 for quiet music beds."
        ),
    )
    parser.add_argument(
        "--min-silence-len",
        type=int,
        default=1200,
        help="Minimum silence/pause length in ms between verses.",
    )
    parser.add_argument(
        "--keep-silence",
        type=int,
        default=300,
        help="Padding to keep before and after each detected verse segment, in ms.",
    )
    parser.add_argument(
        "--min-duration",
        type=int,
        default=3000,
        help="Skip detected segments shorter than this many ms after padding.",
    )
    parser.add_argument(
        "--seek-step",
        type=int,
        default=10,
        help="Silence detection seek step in ms. Smaller is more precise but slower.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing verse MP3 files.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print detected segments without exporting files.",
    )
    parser.add_argument(
        "--timestamps-file",
        type=Path,
        default=None,
        help=(
            "Manual fallback file with one timestamp range per line. "
            "Examples: 00:04.2-00:24.1 or 4420-24170. Lines may include # comments."
        ),
    )
    parser.add_argument(
        "--manual-review",
        action="store_true",
        help="Write an editable segment CSV after detection.",
    )
    parser.add_argument(
        "--review-dir",
        type=Path,
        default=DEFAULT_SEGMENTS_DIR,
        help="Directory for editable segment CSV files.",
    )
    parser.add_argument(
        "--mismatch-warning-threshold",
        type=int,
        default=2,
        help="Print a significant mismatch warning when count differs by this many verses.",
    )
    args = parser.parse_args()

    selected_modes = sum(
        bool(value)
        for value in [
            args.detect,
            args.from_csv,
            args.detect_voice,
            args.make_template,
            args.suggest,
            args.preview is not None,
        ]
    )
    if selected_modes > 1:
        print(
            "ERROR: Use only one mode: --make-template, --suggest, --detect, "
            "--detect-voice, --from-csv, or --preview.",
            file=sys.stderr,
        )
        return 1
    if args.all and args.input is not None:
        print("ERROR: --input can only be used with one --chapter, not --all.", file=sys.stderr)
        return 1
    if args.all and args.output_dir is not None:
        print(
            "ERROR: --output-dir can only be used with one --chapter, not --all.",
            file=sys.stderr,
        )
        return 1
    if args.all and args.timestamps_file is not None:
        print(
            "ERROR: --timestamps-file can only be used with one --chapter, not --all.",
            file=sys.stderr,
        )
        return 1
    if args.all and args.segments_csv is not None:
        print(
            "ERROR: --segments-csv can only be used with one --chapter, not --all.",
            file=sys.stderr,
        )
        return 1
    if args.all and args.preview is not None:
        print("ERROR: --preview can only be used with one --chapter, not --all.", file=sys.stderr)
        return 1
    if args.auto_export and not args.suggest:
        print("ERROR: --auto-export can only be used with --suggest.", file=sys.stderr)
        return 1

    chapters = list(range(1, 19)) if args.all else [args.chapter]
    for chapter in chapters:
        if chapter < 1 or chapter > 18:
            print("ERROR: --chapter must be between 1 and 18.", file=sys.stderr)
            return 1

    try:
        from pydub import AudioSegment
        from pydub.silence import detect_nonsilent
    except ImportError:
        print("ERROR: pydub is not installed.", file=sys.stderr)
        print("Install it with: pip3 install pydub", file=sys.stderr)
        return 1

    failures = 0
    for chapter in chapters:
        print(f"\n=== Chapter {chapter} ===")
        try:
            ok = _process_chapter(
                args=args,
                chapter=chapter,
                audio_segment_cls=AudioSegment,
                detect_nonsilent=detect_nonsilent,
            )
        except Exception as error:  # noqa: BLE001 - batch mode should continue.
            print(f"ERROR: Chapter {chapter} failed: {error}", file=sys.stderr)
            ok = False
        if not ok:
            failures += 1

    if args.all:
        print(
            f"\nBatch complete. Chapters processed: {len(chapters)}. "
            f"Chapters with warnings/errors: {failures}."
        )
    return 1 if failures else 0


def _process_chapter(
    *,
    args: argparse.Namespace,
    chapter: int,
    audio_segment_cls: object,
    detect_nonsilent: Callable[..., list[list[int]]],
) -> bool:
    input_path = (args.input or _first_existing_default_input_path(chapter)).expanduser().resolve()
    output_dir = (args.output_dir or _default_output_dir(chapter)).expanduser().resolve()
    segments_csv = (
        args.segments_csv or _default_segments_csv(chapter)
    ).expanduser().resolve()
    verse_rows = _load_json_verse_rows(args.data_dir.expanduser(), chapter)
    expected_from_json = EXPECTED_VERSE_COUNTS.get(chapter)
    if expected_from_json is not None and len(verse_rows) != expected_from_json:
        print(
            f"WARNING: JSON verse count mismatch for chapter {chapter}. "
            f"Expected {expected_from_json}, found {len(verse_rows)}.",
            file=sys.stderr,
        )

    if args.make_template:
        _write_transliteration_template_csv(
            verse_rows=verse_rows,
            csv_path=segments_csv,
        )
        print(f"Template CSV written: {segments_csv}")
        return len(verse_rows) == expected_from_json

    if not input_path.exists():
        print(f"ERROR: Input file not found: {input_path}", file=sys.stderr)
        return False

    try:
        chapter_audio = audio_segment_cls.from_file(input_path, format="mp3")
    except Exception as error:  # noqa: BLE001 - script should print setup errors clearly.
        print(f"ERROR: Could not load MP3: {input_path}", file=sys.stderr)
        print(f"DETAIL: {error}", file=sys.stderr)
        print("TIP: Install ffmpeg with: brew install ffmpeg", file=sys.stderr)
        return False

    silence_thresh = (
        args.silence_thresh
        if args.silence_thresh is not None
        else chapter_audio.dBFS - 16
    )
    expected_verse_count = args.expected_verse_count or EXPECTED_VERSE_COUNTS.get(
        chapter
    )

    print(f"Input: {input_path}")
    print(f"Output directory: {output_dir}")
    print(f"Segments CSV: {segments_csv}")
    print(f"JSON verses loaded: {len(verse_rows)}")
    print(f"Chapter duration: {_format_duration(len(chapter_audio))}")
    print(f"Average loudness: {chapter_audio.dBFS:.2f} dBFS")
    print(f"Padding / keep silence: {args.keep_silence} ms")
    if expected_verse_count is not None:
        print(f"Expected verse count: {expected_verse_count}")
        effective_min_duration = 0
        print("Expected-count mode: short segments will not be skipped.")
    else:
        effective_min_duration = args.min_duration
        print(f"Minimum exported segment duration: {effective_min_duration} ms")

    if args.preview is not None:
        return _preview_verse_from_csv(
            chapter_audio=chapter_audio,
            csv_path=segments_csv,
            chapter=chapter,
            verse_number=args.preview,
        )

    if args.suggest:
        return _suggest_segments_from_audio(
            args=args,
            chapter_audio=chapter_audio,
            detect_nonsilent=detect_nonsilent,
            chapter=chapter,
            verse_rows=verse_rows,
            csv_path=segments_csv,
            output_dir=output_dir,
            expected_verse_count=expected_verse_count,
        )

    if args.detect_voice:
        return _process_voice_detection(
            chapter_audio=chapter_audio,
            chapter=chapter,
            output_dir=output_dir,
            review_csv_path=_default_voice_review_csv(chapter),
            overwrite=args.overwrite,
            dry_run=args.dry_run,
        )

    if args.from_csv:
        return _export_from_transliteration_csv(
            chapter_audio=chapter_audio,
            chapter=chapter,
            verse_rows=verse_rows,
            csv_path=segments_csv,
            output_dir=output_dir,
            overwrite=args.overwrite,
            dry_run=args.dry_run,
        )
    if args.timestamps_file is not None:
        raw_segments = _load_manual_segments(args.timestamps_file, len(chapter_audio))
        exportable_segments = _exportable_segments(
            raw_segments,
            audio_duration_ms=len(chapter_audio),
            keep_silence=args.keep_silence,
            min_duration=effective_min_duration,
        )
        print(
            f"Manual timestamp mode: loaded {len(raw_segments)} ranges, "
            f"{len(exportable_segments)} exportable segments."
        )
        result = DetectionResult(
            source_label="manual",
            min_silence_len=0,
            silence_thresh=0,
            raw_segments=raw_segments,
            exportable_segments=exportable_segments,
        )
    elif expected_verse_count is not None and args.silence_thresh is None:
        result = _choose_best_detection_settings(
            detect_nonsilent=detect_nonsilent,
            chapter_audio=chapter_audio,
            voice_focused_audio=_voice_focused_audio(chapter_audio),
            expected_verse_count=expected_verse_count,
            keep_silence=args.keep_silence,
            min_duration=effective_min_duration,
            seek_step=args.seek_step,
        )
    else:
        print(f"Silence threshold: {silence_thresh:.2f} dBFS")
        print(f"Minimum silence length: {args.min_silence_len} ms")
        raw_segments = detect_nonsilent(
            chapter_audio,
            min_silence_len=args.min_silence_len,
            silence_thresh=silence_thresh,
            seek_step=args.seek_step,
        )
        exportable_segments = _exportable_segments(
            raw_segments,
            audio_duration_ms=len(chapter_audio),
            keep_silence=args.keep_silence,
            min_duration=effective_min_duration,
        )
        result = DetectionResult(
            source_label="full mix",
            min_silence_len=args.min_silence_len,
            silence_thresh=silence_thresh,
            raw_segments=raw_segments,
            exportable_segments=exportable_segments,
        )

    if not result.raw_segments:
        print("ERROR: No verse-like audio segments detected.", file=sys.stderr)
        print(
            "Try tuning --silence-thresh or --min-silence-len. "
            "For music under narration, try --silence-thresh -45 --min-silence-len 1800.",
            file=sys.stderr,
        )
        return False

    print(
        "Chosen split settings: "
        f"source={result.source_label}, "
        f"min_silence_len={result.min_silence_len}, "
        f"silence_thresh={result.silence_thresh:.2f}, "
        f"raw_segments={len(result.raw_segments)}, "
        f"exportable_segments={result.exportable_count}"
    )
    has_mismatch = (
        expected_verse_count is not None
        and result.exportable_count != expected_verse_count
    )
    significant_mismatch = (
        expected_verse_count is not None
        and abs(result.exportable_count - expected_verse_count)
        >= args.mismatch_warning_threshold
    )
    if has_mismatch:
        print(
            "WARNING: Detected exportable segment count does not match expected "
            f"verse count. Expected {expected_verse_count}, got "
            f"{result.exportable_count}. Use --dry-run to inspect, tune settings, "
            "or use --timestamps-file for manual ranges.",
            file=sys.stderr,
        )
        if significant_mismatch:
            print(
                "SIGNIFICANT MISMATCH: Manual review is recommended before using "
                "--overwrite.",
                file=sys.stderr,
            )
        review_path = _write_segments_csv(
            chapter=chapter,
            result=result,
            csv_path=segments_csv,
        )
        print(f"Editable CSV written for manual review: {review_path}")

    if args.manual_review and not has_mismatch:
        review_path = _write_segments_csv(
            chapter=chapter,
            result=result,
            csv_path=segments_csv,
        )
        print(f"Editable CSV written: {review_path}")

    output_dir.mkdir(parents=True, exist_ok=True)
    exported, skipped_existing = _export_segments(
        chapter_audio=chapter_audio,
        segments=result.exportable_segments,
        output_dir=output_dir,
        overwrite=args.overwrite,
        dry_run=args.dry_run,
    )

    print(
        "Done. "
        f"Exported: {exported}. "
        f"Skipped existing: {skipped_existing}. "
        f"Skipped short: {len(result.raw_segments) - result.exportable_count}. "
        f"Detected raw segments: {len(result.raw_segments)}. "
        f"Exportable segments: {result.exportable_count}."
    )
    return not significant_mismatch


def _choose_best_detection_settings(
    *,
    detect_nonsilent: Callable[..., list[list[int]]],
    chapter_audio: object,
    voice_focused_audio: object,
    expected_verse_count: int,
    keep_silence: int,
    min_duration: int,
    seek_step: int,
) -> DetectionResult:
    best: DetectionResult | None = None

    print("Auto-tuning silence detection:")
    candidates = [
        ("full mix", chapter_audio),
        ("voice-focused", voice_focused_audio),
    ]
    for source_label, detection_audio in candidates:
        for min_silence_len, silence_thresh in AUTO_TUNE_SETTINGS:
            raw_segments = [
                (start, end)
                for start, end in detect_nonsilent(
                    detection_audio,
                    min_silence_len=min_silence_len,
                    silence_thresh=silence_thresh,
                    seek_step=seek_step,
                )
            ]
            exportable_segments = _exportable_segments(
                raw_segments,
                audio_duration_ms=len(chapter_audio),
                keep_silence=keep_silence,
                min_duration=min_duration,
            )
            result = DetectionResult(
                source_label=source_label,
                min_silence_len=min_silence_len,
                silence_thresh=silence_thresh,
                raw_segments=raw_segments,
                exportable_segments=exportable_segments,
            )
            distance = abs(result.exportable_count - expected_verse_count)
            print(
                f"  source={source_label}, "
                f"min_silence_len={min_silence_len}, "
                f"silence_thresh={silence_thresh:.0f}: "
                f"raw={len(raw_segments)}, exportable={result.exportable_count}, "
                f"distance={distance}"
            )
            if best is None or distance < abs(
                best.exportable_count - expected_verse_count
            ):
                best = result

    assert best is not None
    return best


def _exportable_segments(
    raw_segments: list[tuple[int, int]],
    *,
    audio_duration_ms: int,
    keep_silence: int,
    min_duration: int,
) -> list[tuple[int, int]]:
    exportable: list[tuple[int, int]] = []
    for start_ms, end_ms in raw_segments:
        padded_start = max(0, start_ms - keep_silence)
        padded_end = min(audio_duration_ms, end_ms + keep_silence)
        if padded_end - padded_start >= min_duration:
            exportable.append((padded_start, padded_end))
    return exportable


def _export_segments(
    *,
    chapter_audio: object,
    segments: list[tuple[int, int]],
    output_dir: Path,
    overwrite: bool,
    dry_run: bool,
) -> tuple[int, int]:
    exported = 0
    skipped_existing = 0

    for verse_number, (start_ms, end_ms) in enumerate(segments, start=1):
        duration_ms = end_ms - start_ms
        output_path = output_dir / f"verse_{verse_number}.mp3"

        if output_path.exists() and not overwrite:
            skipped_existing += 1
            print(
                f"SKIP existing: {output_path} "
                f"| verse {verse_number} | duration {_format_duration(duration_ms)}"
            )
            continue

        print(
            f"{'DRY RUN' if dry_run else 'EXPORT'}: {output_path} "
            f"| verse {verse_number} | duration {_format_duration(duration_ms)} "
            f"| range {start_ms}ms-{end_ms}ms"
        )

        if not dry_run:
            verse_audio = chapter_audio[start_ms:end_ms]
            verse_audio.export(output_path, format="mp3")

        exported += 1

    return exported, skipped_existing


def _process_voice_detection(
    *,
    chapter_audio: object,
    chapter: int,
    output_dir: Path,
    review_csv_path: Path,
    overwrite: bool,
    dry_run: bool,
) -> bool:
    segments = _detect_voice_segments(chapter_audio)
    _write_voice_review_csv(review_csv_path, segments)
    print(f"Voice review CSV written: {review_csv_path}")

    keep_segments = [
        (segment.start_ms, segment.end_ms)
        for segment in segments
        if segment.status == "keep"
    ]
    review_count = sum(1 for segment in segments if segment.status == "review")
    skipped_count = sum(1 for segment in segments if segment.status == "skipped")

    if review_count:
        print(
            f"WARNING: {review_count} vocal segment(s) marked for review and not exported.",
            file=sys.stderr,
        )

    output_dir.mkdir(parents=True, exist_ok=True)
    exported, skipped_existing = _export_segments(
        chapter_audio=chapter_audio,
        segments=keep_segments,
        output_dir=output_dir,
        overwrite=overwrite,
        dry_run=dry_run,
    )
    print(
        "Voice detection done. "
        f"Kept: {len(keep_segments)}. "
        f"Review: {review_count}. "
        f"Skipped: {skipped_count}. "
        f"Exported: {exported}. "
        f"Skipped existing: {skipped_existing}."
    )
    print(
        "To manually correct uncertain segments, edit the review CSV and use "
        "--from-csv with a compatible segment CSV."
    )
    return review_count == 0


def _suggest_segments_from_audio(
    *,
    args: argparse.Namespace,
    chapter_audio: object,
    detect_nonsilent: Callable[..., list[list[int]]],
    chapter: int,
    verse_rows: list[dict[str, object]],
    csv_path: Path,
    output_dir: Path,
    expected_verse_count: int | None,
) -> bool:
    effective_min_duration = 0 if expected_verse_count is not None else args.min_duration
    result = _choose_best_detection_settings(
        detect_nonsilent=detect_nonsilent,
        chapter_audio=chapter_audio,
        voice_focused_audio=_voice_focused_audio(chapter_audio),
        expected_verse_count=expected_verse_count or len(verse_rows),
        keep_silence=args.keep_silence,
        min_duration=effective_min_duration,
        seek_step=args.seek_step,
    )
    print(
        "Suggested split settings: "
        f"source={result.source_label}, "
        f"min_silence_len={result.min_silence_len}, "
        f"silence_thresh={result.silence_thresh:.2f}, "
        f"segments={result.exportable_count}"
    )
    suggestions: dict[int, tuple[int, int]] = {}
    for index, segment in enumerate(result.exportable_segments, start=1):
        suggestions[index] = segment

    _write_transliteration_template_csv(
        verse_rows=verse_rows,
        csv_path=csv_path,
        suggestions=suggestions,
    )
    print(f"Suggested CSV written for review: {csv_path}")

    if result.exportable_count != len(verse_rows):
        print(
            f"WARNING: Suggested segment count ({result.exportable_count}) does not "
            f"match JSON verse count ({len(verse_rows)}). Review the CSV before export.",
            file=sys.stderr,
        )

    if not args.auto_export:
        print("No audio exported. Review CSV, then run with --from-csv.")
        return result.exportable_count == len(verse_rows)

    print("--auto-export enabled: exporting suggested timestamps.")
    return _export_from_transliteration_csv(
        chapter_audio=chapter_audio,
        chapter=chapter,
        verse_rows=verse_rows,
        csv_path=csv_path,
        output_dir=output_dir,
        overwrite=args.overwrite,
        dry_run=args.dry_run,
    )


def _detect_voice_segments(chapter_audio: object) -> list[VoiceSegment]:
    chunk_ms = 100
    merge_gap_ms = 1500
    min_voice_duration_ms = 5000
    padding_ms = 300

    voice_audio = _voice_focused_audio(chapter_audio)
    low_music_audio = chapter_audio.low_pass_filter(180)

    voice_levels: list[float] = []
    low_levels: list[float] = []
    full_levels: list[float] = []
    positions: list[int] = []

    for start_ms in range(0, len(chapter_audio), chunk_ms):
        end_ms = min(len(chapter_audio), start_ms + chunk_ms)
        voice_levels.append(_safe_dbfs(voice_audio[start_ms:end_ms]))
        low_levels.append(_safe_dbfs(low_music_audio[start_ms:end_ms]))
        full_levels.append(_safe_dbfs(chapter_audio[start_ms:end_ms]))
        positions.append(start_ms)

    finite_voice = [level for level in voice_levels if level > -120]
    if not finite_voice:
        print("No measurable vocal-band energy found.")
        return []

    voice_threshold = max(
        _percentile(finite_voice, 62),
        _safe_dbfs(chapter_audio) - 16,
        -42,
    )
    print(
        "Voice detection thresholds: "
        f"voice_threshold={voice_threshold:.2f} dBFS, "
        "min_voice_duration=5000ms, merge_gap=1500ms, padding=300ms"
    )

    active_ranges: list[tuple[int, int]] = []
    active_start: int | None = None
    for index, start_ms in enumerate(positions):
        voice_db = voice_levels[index]
        low_db = low_levels[index]
        full_db = full_levels[index]
        vocal_band_present = voice_db >= voice_threshold
        low_music_dominated = low_db - voice_db > 7
        nearly_silent = full_db < -55
        is_voice_like = vocal_band_present and not low_music_dominated and not nearly_silent

        if is_voice_like and active_start is None:
            active_start = start_ms
        elif not is_voice_like and active_start is not None:
            active_ranges.append((active_start, start_ms))
            active_start = None

    if active_start is not None:
        active_ranges.append((active_start, len(chapter_audio)))

    merged_ranges = _merge_nearby_ranges(active_ranges, max_gap_ms=merge_gap_ms)
    segments: list[VoiceSegment] = []
    for start_ms, end_ms in merged_ranges:
        padded_start = max(0, start_ms - padding_ms)
        padded_end = min(len(chapter_audio), end_ms + padding_ms)
        duration_ms = padded_end - padded_start
        stats = _voice_segment_stats(
            padded_start,
            padded_end,
            positions=positions,
            voice_levels=voice_levels,
            low_levels=low_levels,
            threshold=voice_threshold,
        )
        status, reason = _classify_voice_segment(
            duration_ms=duration_ms,
            voiced_ratio=stats["voiced_ratio"],
            voice_over_low_db=stats["voice_over_low_db"],
            min_voice_duration_ms=min_voice_duration_ms,
        )
        print(
            f"{status.upper()}: "
            f"{_format_duration_for_timestamp(padded_start)}-"
            f"{_format_duration_for_timestamp(padded_end)} "
            f"| duration {_format_duration(duration_ms)} "
            f"| {reason}"
        )
        segments.append(
            VoiceSegment(
                start_ms=padded_start,
                end_ms=padded_end,
                status=status,
                notes=reason,
            )
        )
    return segments


def _voice_segment_stats(
    start_ms: int,
    end_ms: int,
    *,
    positions: list[int],
    voice_levels: list[float],
    low_levels: list[float],
    threshold: float,
) -> dict[str, float]:
    indexes = [
        index
        for index, position in enumerate(positions)
        if start_ms <= position < end_ms
    ]
    if not indexes:
        return {"voiced_ratio": 0, "voice_over_low_db": -999}

    voiced = [index for index in indexes if voice_levels[index] >= threshold]
    avg_voice = _average([voice_levels[index] for index in indexes])
    avg_low = _average([low_levels[index] for index in indexes])
    return {
        "voiced_ratio": len(voiced) / len(indexes),
        "voice_over_low_db": avg_voice - avg_low,
    }


def _classify_voice_segment(
    *,
    duration_ms: int,
    voiced_ratio: float,
    voice_over_low_db: float,
    min_voice_duration_ms: int,
) -> tuple[str, str]:
    if duration_ms < min_voice_duration_ms:
        return (
            "skipped",
            f"too short for verse vocal clip ({duration_ms}ms < {min_voice_duration_ms}ms)",
        )
    if voiced_ratio >= 0.48 and voice_over_low_db >= -4:
        return (
            "keep",
            f"vocal energy strong; voiced_ratio={voiced_ratio:.2f}, voice_over_low={voice_over_low_db:.2f}dB",
        )
    if voiced_ratio >= 0.25:
        return (
            "review",
            f"uncertain vocal/music mix; voiced_ratio={voiced_ratio:.2f}, voice_over_low={voice_over_low_db:.2f}dB",
        )
    return (
        "skipped",
        f"likely music-only; voiced_ratio={voiced_ratio:.2f}, voice_over_low={voice_over_low_db:.2f}dB",
    )


def _merge_nearby_ranges(
    ranges: list[tuple[int, int]],
    *,
    max_gap_ms: int,
) -> list[tuple[int, int]]:
    if not ranges:
        return []

    merged = [ranges[0]]
    for start_ms, end_ms in ranges[1:]:
        previous_start, previous_end = merged[-1]
        if start_ms - previous_end <= max_gap_ms:
            merged[-1] = (previous_start, max(previous_end, end_ms))
        else:
            merged.append((start_ms, end_ms))
    return merged


def _safe_dbfs(audio: object) -> float:
    value = audio.dBFS
    if value == float("-inf"):
        return -120
    return float(value)


def _average(values: list[float]) -> float:
    return sum(values) / len(values) if values else -120


def _percentile(values: list[float], percentile: float) -> float:
    if not values:
        return -120
    ordered = sorted(values)
    index = round((len(ordered) - 1) * (percentile / 100))
    return ordered[index]


def _write_voice_review_csv(path: Path, segments: list[VoiceSegment]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["verse", "start_ms", "end_ms", "status", "notes"],
        )
        writer.writeheader()
        for index, segment in enumerate(segments, start=1):
            writer.writerow(
                {
                    "verse": index,
                    "start_ms": segment.start_ms,
                    "end_ms": segment.end_ms,
                    "status": segment.status,
                    "notes": segment.notes,
                }
            )


def _voice_focused_audio(chapter_audio: object) -> object:
    """Reduce very low/high music energy before silence detection when possible."""
    try:
        filtered = chapter_audio.high_pass_filter(120).low_pass_filter(4200)
        print("Voice-focused detection: using 120Hz high-pass + 4200Hz low-pass.")
        return filtered
    except Exception as error:  # noqa: BLE001 - pydub filters may vary by backend.
        print(f"Voice-focused detection unavailable; using full mix. Detail: {error}")
        return chapter_audio


def _load_manual_segments(path: Path, audio_duration_ms: int) -> list[tuple[int, int]]:
    if not path.exists():
        raise FileNotFoundError(f"Manual timestamp file not found: {path}")

    segments: list[tuple[int, int]] = []
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.split("#", 1)[0].strip()
        if not line:
            continue
        if "-" not in line:
            raise ValueError(f"Line {line_number}: expected START-END, got {raw_line!r}")
        start_text, end_text = [part.strip() for part in line.split("-", 1)]
        start_ms = _parse_timestamp_ms(start_text)
        end_ms = _parse_timestamp_ms(end_text)
        if start_ms < 0 or end_ms > audio_duration_ms or end_ms <= start_ms:
            raise ValueError(
                f"Line {line_number}: invalid range {raw_line!r} for audio duration "
                f"{_format_duration(audio_duration_ms)}"
            )
        segments.append((start_ms, end_ms))
    return segments


def _load_json_verse_rows(data_dir: Path, chapter: int) -> list[dict[str, object]]:
    chapter_path = data_dir / f"chapter{chapter}.json"
    if not chapter_path.exists():
        raise FileNotFoundError(f"Missing JSON chapter file: {chapter_path}")

    with chapter_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    raw_verses = _extract_json_verses(data)
    rows: list[dict[str, object]] = []
    for raw in raw_verses:
        if not isinstance(raw, dict):
            continue
        verse_number = _read_int(
            raw.get("verseNumber")
            or raw.get("verse_number")
            or raw.get("number")
            or raw.get("verse")
        )
        transliteration = _clean_csv_text(
            raw.get("transliteration") or raw.get("transliterationText")
        )
        if not transliteration:
            print(
                f"WARNING: Chapter {chapter}, Verse {verse_number}: "
                "missing transliteration.",
                file=sys.stderr,
            )
        rows.append(
            {
                "verse": verse_number,
                "transliteration": transliteration,
            }
        )
    rows.sort(key=lambda row: int(row["verse"]))
    return rows


def _extract_json_verses(data: object) -> list[object]:
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


def _write_transliteration_template_csv(
    *,
    verse_rows: list[dict[str, object]],
    csv_path: Path,
    suggestions: dict[int, tuple[int, int]] | None = None,
) -> None:
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    suggestions = suggestions or {}
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["verse", "start_ms", "end_ms", "transliteration", "notes"],
        )
        writer.writeheader()
        for row in verse_rows:
            verse_number = int(row["verse"])
            suggested = suggestions.get(verse_number)
            start_ms = suggested[0] if suggested else ""
            end_ms = suggested[1] if suggested else ""
            notes = "suggested; review before export" if suggested else ""
            writer.writerow(
                {
                    "verse": verse_number,
                    "start_ms": start_ms,
                    "end_ms": end_ms,
                    "transliteration": row.get("transliteration", ""),
                    "notes": notes,
                }
            )


def _load_reviewed_verse_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise FileNotFoundError(f"Segment CSV not found: {path}")
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        required = {"verse", "start_ms", "end_ms", "transliteration", "notes"}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise ValueError(f"CSV missing required columns: {sorted(missing)}")
        return [dict(row) for row in reader]


def _export_from_transliteration_csv(
    *,
    chapter_audio: object,
    chapter: int,
    verse_rows: list[dict[str, object]],
    csv_path: Path,
    output_dir: Path,
    overwrite: bool,
    dry_run: bool,
) -> bool:
    csv_rows = _load_reviewed_verse_csv(csv_path)
    if len(csv_rows) != len(verse_rows):
        print(
            f"WARNING: CSV row count ({len(csv_rows)}) does not match JSON verse "
            f"count ({len(verse_rows)}).",
            file=sys.stderr,
        )

    valid_exports: list[tuple[int, int, int]] = []
    previous_end: int | None = None
    for row_number, row in enumerate(csv_rows, start=2):
        verse_number = _read_int(row.get("verse"))
        transliteration = _clean_csv_text(row.get("transliteration"))
        print(f"Review Verse {verse_number}: {transliteration}")
        start_text = _clean_csv_text(row.get("start_ms"))
        end_text = _clean_csv_text(row.get("end_ms"))
        if not start_text or not end_text:
            print(f"SKIP row {row_number}: missing timestamps for verse {verse_number}")
            continue
        start_ms = _parse_timestamp_ms(start_text)
        end_ms = _parse_timestamp_ms(end_text)
        if end_ms <= start_ms:
            print(
                f"WARNING row {row_number}: end_ms <= start_ms for verse {verse_number}.",
                file=sys.stderr,
            )
            continue
        if previous_end is not None and start_ms < previous_end:
            print(
                f"WARNING row {row_number}: timestamps overlap previous verse.",
                file=sys.stderr,
            )
        if start_ms < 0 or end_ms > len(chapter_audio):
            print(
                f"WARNING row {row_number}: timestamps exceed audio duration.",
                file=sys.stderr,
            )
            continue
        valid_exports.append((verse_number, start_ms, end_ms))
        previous_end = end_ms

    output_dir.mkdir(parents=True, exist_ok=True)
    exported = 0
    skipped_existing = 0
    for verse_number, start_ms, end_ms in valid_exports:
        output_path = output_dir / f"verse_{verse_number}.mp3"
        duration_ms = end_ms - start_ms
        if output_path.exists() and not overwrite:
            print(
                f"SKIP existing: {output_path} | verse {verse_number} "
                f"| duration {_format_duration(duration_ms)}"
            )
            skipped_existing += 1
            continue
        print(
            f"{'DRY RUN' if dry_run else 'EXPORT'}: {output_path} "
            f"| verse {verse_number} | duration {_format_duration(duration_ms)} "
            f"| range {start_ms}ms-{end_ms}ms"
        )
        if not dry_run:
            chapter_audio[start_ms:end_ms].export(output_path, format="mp3")
        exported += 1

    if len(valid_exports) != len(verse_rows):
        print(
            f"WARNING: Valid timestamp rows ({len(valid_exports)}) do not match "
            f"JSON verse count ({len(verse_rows)}).",
            file=sys.stderr,
        )
    print(
        "CSV export done. "
        f"Chapter: {chapter}. Exported: {exported}. "
        f"Skipped existing: {skipped_existing}. Valid timestamp rows: {len(valid_exports)}."
    )
    return len(valid_exports) == len(verse_rows)


def _preview_verse_from_csv(
    *,
    chapter_audio: object,
    csv_path: Path,
    chapter: int,
    verse_number: int,
) -> bool:
    rows = _load_reviewed_verse_csv(csv_path)
    row = next((item for item in rows if _read_int(item.get("verse")) == verse_number), None)
    if row is None:
        print(f"ERROR: Verse {verse_number} not found in {csv_path}", file=sys.stderr)
        return False
    start_text = _clean_csv_text(row.get("start_ms"))
    end_text = _clean_csv_text(row.get("end_ms"))
    if not start_text or not end_text:
        print(f"ERROR: Verse {verse_number} has missing timestamps.", file=sys.stderr)
        return False
    start_ms = _parse_timestamp_ms(start_text)
    end_ms = _parse_timestamp_ms(end_text)
    if end_ms <= start_ms:
        print(f"ERROR: Verse {verse_number} has invalid timestamps.", file=sys.stderr)
        return False
    preview_path = DEFAULT_SEGMENTS_DIR / f"chapter_{chapter}_verse_{verse_number}_preview.mp3"
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    chapter_audio[start_ms:end_ms].export(preview_path, format="mp3")
    print(f"Preview exported: {preview_path}")
    print(f"Verse {verse_number}: {_clean_csv_text(row.get('transliteration'))}")
    return True


def _load_csv_segments(path: Path, audio_duration_ms: int) -> list[tuple[int, int]]:
    if not path.exists():
        raise FileNotFoundError(f"Segment CSV not found: {path}")

    segments: list[tuple[int, int]] = []
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row_number, row in enumerate(reader, start=2):
            start_value = (row.get("start_ms") or row.get("start_time") or "").strip()
            end_value = (row.get("end_ms") or row.get("end_time") or "").strip()
            if not start_value or not end_value:
                raise ValueError(
                    f"CSV row {row_number}: expected start_ms/end_ms or start_time/end_time"
                )
            start_ms = _parse_timestamp_ms(start_value)
            end_ms = _parse_timestamp_ms(end_value)
            if start_ms < 0 or end_ms > audio_duration_ms or end_ms <= start_ms:
                raise ValueError(
                    f"CSV row {row_number}: invalid range {start_value}-{end_value} "
                    f"for audio duration {_format_duration(audio_duration_ms)}"
                )
            segments.append((start_ms, end_ms))
    return segments


def _write_segments_csv(
    *,
    chapter: int,
    result: DetectionResult,
    csv_path: Path,
) -> Path:
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "verse",
                "start_ms",
                "end_ms",
                "start_time",
                "end_time",
                "duration_ms",
                "notes",
            ],
        )
        writer.writeheader()
        for index, (start_ms, end_ms) in enumerate(result.exportable_segments, start=1):
            writer.writerow(
                {
                    "verse": index,
                    "start_ms": start_ms,
                    "end_ms": end_ms,
                    "start_time": _format_duration_for_timestamp(start_ms),
                    "end_time": _format_duration_for_timestamp(end_ms),
                    "duration_ms": end_ms - start_ms,
                    "notes": "detected",
                }
            )
    print(
        "Review/edit the CSV, then export with: "
        f"python3 scripts/split_chapter_audio.py --chapter {chapter} --from-csv --overwrite"
    )
    return csv_path


def _format_duration_for_timestamp(duration_ms: int) -> str:
    total_seconds = duration_ms / 1000
    minutes = int(total_seconds // 60)
    seconds = total_seconds - (minutes * 60)
    return f"{minutes:02d}:{seconds:05.2f}"


def _clean_csv_text(value: object) -> str:
    if value is None:
        return ""
    return " ".join(str(value).replace("\r", " ").replace("\n", " ").split())


def _read_int(value: object) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str):
        match = re.search(r"\d+", value)
        if match:
            return int(match.group(0))
    raise ValueError(f"Could not read integer from {value!r}")


def _parse_timestamp_ms(value: str) -> int:
    if ":" not in value:
        return int(float(value))

    parts = value.split(":")
    if len(parts) == 2:
        minutes = int(parts[0])
        seconds = float(parts[1])
        return int(round((minutes * 60 + seconds) * 1000))
    if len(parts) == 3:
        hours = int(parts[0])
        minutes = int(parts[1])
        seconds = float(parts[2])
        return int(round((hours * 3600 + minutes * 60 + seconds) * 1000))
    raise ValueError(f"Unsupported timestamp: {value}")


def _format_duration(duration_ms: int) -> str:
    total_seconds = duration_ms / 1000
    minutes = int(total_seconds // 60)
    seconds = total_seconds - (minutes * 60)
    return f"{minutes}:{seconds:05.2f}"


def _default_input_path(chapter: int) -> Path:
    return DEFAULT_RAW_DIR / f"gita-chapter-{chapter:02d}.mp3"


def _legacy_default_input_paths(chapter: int) -> list[Path]:
    return [
        DEFAULT_RAW_DIR / f"gita-chapter{chapter:02d}.mp3",
        DEFAULT_RAW_DIR / f"gita_chapter_{chapter:02d}.mp3",
    ]


def _first_existing_default_input_path(chapter: int) -> Path:
    preferred = _default_input_path(chapter)
    if preferred.exists():
        return preferred
    for legacy in _legacy_default_input_paths(chapter):
        if legacy.exists():
            return legacy
    return preferred


def _default_output_dir(chapter: int) -> Path:
    return DEFAULT_OUTPUT_ROOT / f"chapter_{chapter}"


def _default_segments_csv(chapter: int) -> Path:
    return DEFAULT_SEGMENTS_DIR / f"chapter_{chapter}_segments.csv"


def _default_voice_review_csv(chapter: int) -> Path:
    return DEFAULT_SEGMENTS_DIR / f"chapter_{chapter}_review.csv"


if __name__ == "__main__":
    raise SystemExit(main())
