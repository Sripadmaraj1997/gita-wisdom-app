# Gita Wisdom Architecture

Gita Wisdom is designed as an offline-first spiritual reading app. The core product promise is that a user can read scripture, receive practical guidance, save wisdom, journal privately, and continue a journey without an account or network connection.

## Why Offline First

The app avoids Firebase, cloud search, OpenAI runtime calls, and account setup in the core experience. This keeps scripture reading fast, private, and available when the user wants a quiet moment. Network-backed features can be added later, but the baseline should remain useful before any sync completes.

## Content Sources

Scripture and editorial content are bundled locally:

- `assets/data/gita/chapter*.json` provides Sanskrit, transliteration, and translation.
- Reviewed enrichment content provides Meaning, Gita Wisdom Interpretation, Reflection, Practice Today, and Tags when available.
- `GitaDataService` and `GitaRepository` are the source of truth for loading, lookup, and search ranking.

Local JSON is used because the Bhagavad Gita reading experience should not depend on API latency, search indexing, or remote availability.

## Screen Flow

Home is the companion entry point. It emphasizes one next step first, then offers Today’s Guidance, Journey continuity, Ask Gita, Search, Journal, and Saved Wisdom.

Verse Reader is the scripture-first screen. It presents Sanskrit, transliteration, translation, interpretation, reflection, and Practice Today before controls dominate attention. Controls are secondary because the purpose is reading and applying wisdom, not managing actions.

Ask Gita is deterministic and local. It maps user concerns to reviewed topic profiles, chooses relevant local verses, and renders:

1. Guidance
2. Verse
3. Meaning
4. Reflection
5. Practice Today
6. Source

The goal is practical wisdom, not chatbot behavior. Ask Gita should feel like a wise mentor helping a friend, while remaining auditable and offline.

Journeys guide users through Read, Reflect, Practice, Return. Journey state is local and intentionally simple:

- `currentJourneyId`: active guided path.
- `currentJourneyDay`: day Home and Journeys should resume.
- `completedDays`: completed day numbers grouped by journey.
- `completedJourneys`: completed journey IDs retained after the next journey starts.

Final-day completion persists the journey, shows a calm completion state, and guides the user to choose or restart another journey without a dead Continue button.

Search supports exact scripture lookup and emotional discovery. Ranking prioritizes exact references, emotional tags, interpretation, reflection, Practice Today, translation, and then transliteration/Sanskrit/chapter context. Searches for fear, peace, anger, discipline, purpose, attachment, devotion, clarity, and compassion should surface applicable wisdom, not only literal keyword matches.

Journal is private local reflection. It helps users convert reading into self-understanding and one small action. Journal text stays on device.

Saved Wisdom is a return surface. Saved verses, highlights, saved reflections, and journal reflections are framed as a personal wisdom collection to revisit and practice.

## SharedPreferences Keys

`LocalStorageService` owns most user-owned state:

- `gita_saved_verses`: saved verse snapshots for fast Saved Wisdom rendering.
- `gita_saved_reflections`: saved reflection and Practice Today snapshots.
- `gita_highlighted_verses`: highlighted verse IDs, resolved against local JSON.
- `gita_journal_entries`: private local journal entries.
- `gita_ask_history`: compact local Ask Gita history.
- `gita_recent_verses`: recently opened verse snapshots for continuity.
- `gita_recent_reflections`: recently reflected topics/verses for Home memory.
- `gita_completed_practice_dates`: date keys for Days of Reflection.
- `gita_reader_font_scale`: Verse Reader typography preference.
- `gita_reader_show_sanskrit`: Sanskrit visibility preference.
- `gita_reader_show_transliteration`: transliteration visibility preference.
- `gita_theme_mode`: app visual theme choice.
- `gita_current_journey`: active journey ID.
- `gita_current_journey_day`: day to resume in the active journey.
- `gita_reading_plan_progress`: completed days by journey ID.
- `gita_completed_journeys`: completed journey IDs.

`ReadingProgressService` keeps Continue Reading separate from saved verses:

- `reading_progress_verse_id`: last opened verse ID.
- `reading_progress_chapter_number`: fallback chapter number.
- `reading_progress_verse_number`: fallback verse number.
- `reading_progress_saved_at`: local timestamp for continuity.

`PersonalizationService` keeps private local recommendation signals:

- `gita_wisdom_personalization_seeking`: selected broad seeking theme.
- `gita_wisdom_personalization_language`: preferred language label.
- `gita_wisdom_personalization_reminder_hour`: local reminder hour preference.
- `gita_wisdom_personalization_reminder_minute`: local reminder minute preference.
- `gita_personal_theme_counts`: local theme counts for recommendations.
- `gita_personal_recent_themes`: recent themes for recency weighting.
- `gita_personal_opened_verses`: verse IDs opened locally.
- `gita_personal_ask_topics`: Ask Gita topics explored locally.
- `gita_personal_search_topics`: emotional search topics explored locally.
- `gita_personal_completed_journeys`: completed journeys used as recommendation context.

Legacy and framework keys:

- `gita_wisdom_last_completed_date`: legacy habit completion date.
- `gita_wisdom_daily_streak`: legacy habit streak count.
- `__theme_mode__`: FlutterFlow theme-mode compatibility key.

## Future Roadmap TODOs

Only these roadmap categories should appear as TODO tags in code:

- `TODO(cloud-sync)`
- `TODO(personalization-engine)`
- `TODO(wisdom-collections)`
- `TODO(community-backend)`
- `TODO(full-audio-library)`
