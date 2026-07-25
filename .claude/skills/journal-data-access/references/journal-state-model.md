# JournalState Model Reference

## Fields

| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | `Uuid().v4()` | Client-generated UUID; replaced by the Postgres row's `id` after save |
| `tmdbId` | `int` | `0` | TMDB movie identifier |
| `movieTitle` | `String` | `''` | Display title of the movie |
| `moviePoster` | `String` | `''` | TMDB poster URL path |
| `emotions` | `List<Emotion>` | `[]` | Up to 3 selected emotions |
| `selectedScenes` | `List<SceneItem>` | `[]` | Movie stills with optional captions |
| `selectedRefs` | `List<Review>` | `[]` | AI-curated reviews (from Letterboxd/Reddit) |
| `thoughts` | `String` | `''` | Free-form user text |
| `createdAt` | `Jiffy` | `Jiffy.now()` | Set once during `save()` |
| `updatedAt` | `Jiffy` | `Jiffy.now()` | Set on every `save()` or `update()` |

## SceneItem

```dart
class SceneItem {
  final String path;      // Image URL path
  final String? caption;  // Optional user caption
}
```

**Known limitation:** `SceneItem.copyWith(caption: null)` does not clear an existing caption due to the `??` operator. Passing an empty string to `updateSceneCaption()` is also insufficient — clearing a caption after one was set requires a different approach.

## Review

Defined in `lib/features/quesgen/review.dart`:

```dart
class Review {
  final String text;    // Review content
  final String source;  // "letterboxd" or "reddit"
}
```

## Serialization

`JournalState` is **camelCase and database-agnostic on purpose.** It was deliberately left untouched by the Supabase migration: `toMap()` / `fromJson()` remain the serialization seam, and every snake_case ↔ camelCase translation happens in `SupabaseDbManager` (`rowToJournal` / `journalToRow`). Keep it that way — it is what stops a schema change from rippling into the widget tree.

### toMap() — the camelCase shape

Excludes the `id` field. Excludes user-set timestamps.

```json
{
  "tmdbId": 550,
  "movieTitle": "Fight Club",
  "moviePoster": "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
  "emotions": ["joyful", "inspired"],
  "selectedScenes": [
    { "path": "/scene1.jpg", "caption": "This moment" }
  ],
  "selectedRefs": [
    { "text": "A masterpiece...", "source": "letterboxd" }
  ],
  "thoughts": "Made me rethink everything",
  "createdAt": "2025-01-15T10:30:00.000",
  "updatedAt": "2025-01-15T10:30:00.000"
}
```

Ownership (`user_id`) is supplied separately by `SupabaseDbManager.addJournal()`.

### fromJson() — reads

Handles backward compatibility:
- Old format stored scenes and reviews as plain strings instead of objects
- `fromJson()` gracefully handles both formats

These legacy shapes are **not** hypothetical: the production import found 87 string scenes and 30 string refs. Both shapes still arrive from the `jsonb` columns, so keep the tolerance.

## Postgres table: `public.journals`

```sql
id               uuid primary key default gen_random_uuid()
user_id          uuid not null references auth.users (id) on delete cascade
tmdb_id          integer not null
movie_title      text not null default ''
movie_poster     text not null default ''
emotions         text[] not null default '{}'
selected_scenes  jsonb not null default '[]'   -- [{path, caption?}]
selected_refs    jsonb not null default '[]'   -- [{text, source}]
thoughts         text not null default ''
created_at       timestamptz not null default now()
updated_at       timestamptz not null default now()
firestore_id     text unique                   -- NULL for rows created in this app
migrated_updated_at timestamptz                -- delta-sync conflict marker
raw              jsonb                         -- verbatim original Firestore doc
```

The last three columns are migration machinery and the app never writes them. `firestore_id` in particular **must stay NULL** on new rows — that is how the daily delta-sync tells "imported from Firestore, keep managing it" from "created in the new app, leave it alone."

RLS restricts every operation to `auth.uid() = user_id`; there is no `anon` access at all.

### Timestamps

`timestamptz` is an absolute instant, but `JournalState` holds Jiffy **local wall time**, so the manager converts in both directions — `jiffyToUtcIso()` on write, `pgTimestampToLocalNaive()` on read. Never hand `Jiffy.toString()` to Postgres: it is naive local, would be read as UTC, and shifts every timestamp by 8 hours. Pinned by `test/supabase_db_manager_test.dart`.

## JournalsState

A thin wrapper around a list:

```dart
class JournalsState {
  final List<JournalState> journals;
  JournalsState({this.journals = const []});
  JournalsState copyWith({List<JournalState>? journals});
}
```

Accessed via `journalsControllerProvider`, which is an `AsyncNotifierProvider`. The `build()` method selects the current user's rows from `public.journals`, ordered `created_at` descending.
