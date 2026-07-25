// Pure transforms from exported Firestore docs to Postgres column values.
//
// Everything here is deliberately side-effect free (apart from appending to a
// Report) so it can be unit-tested and so validate.ts can recompute a row from
// `raw` and diff it against what was actually written.

import type { Report } from "./report.ts";

/**
 * Journal createdAt/updatedAt were written by Jiffy `.toString()`, which emits
 * a NAIVE local wall-clock string ("2025-01-15T10:30:00.000") with no zone.
 * The app has only ever shipped to users in Taiwan, so those readings are
 * Asia/Taipei wall time.
 *
 * Hardcoded, never an env var: this is a fixed data-interpretation policy that
 * must be byte-identical across the dry run and all ~28 daily syncs. A missing
 * or wrong value shifts every timestamp by 8h with no error, and recovery would
 * mean re-deriving everything from `raw`.
 *
 * A fixed +08:00 is exact rather than approximate: Taiwan has observed UTC+8
 * with no DST since 1980, and all app data postdates that by decades. Anything
 * older is flagged rather than silently converted.
 */
export const SOURCE_TZ = "Asia/Taipei";
export const SOURCE_UTC_OFFSET = "+08:00";
const DST_ERA_CUTOFF_YEAR = 1980;

const HAS_ZONE = /(?:Z|[+-]\d{2}:?\d{2})$/i;
const NAIVE_ISO = /^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(?::\d{2})?(?:\.\d{1,6})?$/;

export type TimestampResult = { iso: string; note: string };

/**
 * Convert an exported timestamp value to a UTC ISO string.
 *
 * Firestore Timestamps are converted to zone-aware ISO at export time, so a
 * value arriving here with a zone is already absolute and is passed through.
 * A naive value is Taipei wall time. Anything unusable falls back to the doc's
 * own metadata time, and every fallback is reported.
 */
export function toUtcIso(
  value: unknown,
  fallbackIso: string,
  report: Report,
  ctx: string,
): TimestampResult {
  if (typeof value !== "string" || value.trim() === "") {
    report.anomaly("timestamp_missing", `${ctx}: missing, used doc metadata time`, {
      fallback: fallbackIso,
    });
    return { iso: fallbackIso, note: "fallback_missing" };
  }

  const raw = value.trim();

  if (HAS_ZONE.test(raw)) {
    const d = new Date(raw);
    if (Number.isNaN(d.getTime())) {
      report.anomaly("timestamp_unparseable", `${ctx}: zone-aware but unparseable: ${raw}`, {
        fallback: fallbackIso,
      });
      return { iso: fallbackIso, note: "fallback_unparseable" };
    }
    // Already absolute -- do NOT re-interpret as Taipei.
    return { iso: d.toISOString(), note: "already_zoned" };
  }

  if (!NAIVE_ISO.test(raw)) {
    report.anomaly("timestamp_unparseable", `${ctx}: unrecognised format: ${raw}`, {
      fallback: fallbackIso,
    });
    return { iso: fallbackIso, note: "fallback_unparseable" };
  }

  const d = new Date(`${raw.replace(" ", "T")}${SOURCE_UTC_OFFSET}`);
  if (Number.isNaN(d.getTime())) {
    report.anomaly("timestamp_unparseable", `${ctx}: naive but unparseable: ${raw}`, {
      fallback: fallbackIso,
    });
    return { iso: fallbackIso, note: "fallback_unparseable" };
  }
  if (d.getUTCFullYear() < DST_ERA_CUTOFF_YEAR) {
    report.anomaly(
      "timestamp_pre_dst_era",
      `${ctx}: ${raw} predates ${DST_ERA_CUTOFF_YEAR}; the fixed ${SOURCE_UTC_OFFSET} assumption may be wrong (Taiwan observed DST before then)`,
    );
  }
  return { iso: d.toISOString(), note: "naive_as_taipei" };
}

// ---------------------------------------------------------------- emotions

/** The 24 live ids, from lib/features/emotion/emotion.dart. */
export const EMOTION_IDS_V2 = [
  "joyful", "funny", "inspired", "mindBlown", "hopeful", "fulfilling",
  "shocked", "angry", "terrified", "anxious", "overwhelmed", "disturbed",
  "heartwarming", "touched", "peaceful", "therapeutic", "nostalgic", "cozy",
  "melancholic", "confused", "profound", "bittersweet", "powerless", "lonely",
] as const;

/**
 * v1 ids, still present commented-out in the EmotionType enum. Old journals can
 * legitimately carry these, so they are reported separately from genuinely
 * unknown ids -- "legacy data as expected" and "something is wrong" deserve
 * different buckets when deciding whether to add the cardinality<=3 constraint.
 */
export const EMOTION_IDS_V1_ONLY = [
  "amazed", "excited", "entertained", "humorous", "melancholy", "frustrated",
  "disgust", "isolated", "bored", "calm", "surprised", "relatable", "nervous",
  "ironic",
] as const;

const V2 = new Set<string>(EMOTION_IDS_V2);
const V1 = new Set<string>(EMOTION_IDS_V1_ONLY);

/** Emotion ids are kept VERBATIM -- never remapped. Unknown ids are reported,
 *  not dropped: the goal is zero data loss, and `raw` must stay reproducible. */
export function normalizeEmotions(value: unknown, report: Report, ctx: string): string[] {
  if (value == null) return [];
  if (!Array.isArray(value)) {
    report.anomaly("emotions_not_array", `${ctx}: emotions was ${typeof value}, coerced to []`);
    return [];
  }
  const out: string[] = [];
  for (const e of value) {
    if (typeof e !== "string") {
      report.anomaly("emotions_entry_not_string", `${ctx}: dropped non-string emotion entry`);
      continue;
    }
    if (!V2.has(e)) {
      if (V1.has(e)) {
        report.anomaly("emotion_legacy_v1", `${ctx}: legacy v1 emotion id "${e}" (expected in old journals)`, { id: e });
      } else {
        report.anomaly("emotion_unknown", `${ctx}: unrecognised emotion id "${e}"`, { id: e });
      }
    }
    out.push(e);
  }
  if (out.length > 3) {
    report.anomaly("emotions_over_limit", `${ctx}: ${out.length} emotions (app caps at 3)`, {
      count: out.length,
    });
  }
  return out;
}

// ------------------------------------------------------------------ scenes

export type Scene = { path: string; caption?: string };

/** Legacy docs stored scenes as plain strings; current ones as {path, caption?}. */
export function normalizeScenes(value: unknown, report: Report, ctx: string): Scene[] {
  if (value == null) return [];
  if (!Array.isArray(value)) {
    report.anomaly("scenes_not_array", `${ctx}: selectedScenes was ${typeof value}, coerced to []`);
    return [];
  }
  const out: Scene[] = [];
  for (const s of value) {
    if (typeof s === "string") {
      report.count("scene_legacy_string_upgraded");
      out.push({ path: s });
    } else if (s && typeof s === "object" && typeof (s as any).path === "string") {
      const scene: Scene = { path: (s as any).path };
      const cap = (s as any).caption;
      if (typeof cap === "string" && cap !== "") scene.caption = cap;
      out.push(scene);
    } else {
      report.anomaly("scene_entry_unusable", `${ctx}: dropped scene entry ${JSON.stringify(s)}`);
    }
  }
  return out;
}

// -------------------------------------------------------------------- refs

export const REF_SOURCES = ["letterboxd", "reddit", "unknown"] as const;
export type Ref = { text: string; source: string };

const SOURCES = new Set<string>(REF_SOURCES);

/** Legacy docs stored refs as plain strings, and used the key `selectedQuestions`. */
export function normalizeRefs(value: unknown, report: Report, ctx: string): Ref[] {
  if (value == null) return [];
  if (!Array.isArray(value)) {
    report.anomaly("refs_not_array", `${ctx}: refs field was ${typeof value}, coerced to []`);
    return [];
  }
  const out: Ref[] = [];
  for (const r of value) {
    if (typeof r === "string") {
      report.count("ref_legacy_string_upgraded");
      out.push({ text: r, source: "unknown" });
    } else if (r && typeof r === "object" && typeof (r as any).text === "string") {
      let source = (r as any).source;
      if (typeof source !== "string" || !SOURCES.has(source)) {
        report.anomaly("ref_source_unknown", `${ctx}: ref source ${JSON.stringify(source)} coerced to "unknown"`);
        source = "unknown";
      }
      out.push({ text: (r as any).text, source });
    } else {
      report.anomaly("ref_entry_unusable", `${ctx}: dropped ref entry ${JSON.stringify(r)}`);
    }
  }
  return out;
}

// ----------------------------------------------------------------- scalars

/** journals.tmdb_id is NOT NULL. A journal with no usable id is still preserved
 *  with a 0 sentinel rather than dropped -- zero data loss is the stated goal,
 *  `raw` keeps the original, and the anomaly makes it findable. */
export function toTmdbId(value: unknown, report: Report, ctx: string): number {
  if (typeof value === "number" && Number.isInteger(value)) return value;
  if (typeof value === "number") {
    report.anomaly("tmdb_id_non_integer", `${ctx}: tmdbId ${value} truncated`);
    return Math.trunc(value);
  }
  if (typeof value === "string") {
    const n = Number.parseInt(value, 10);
    if (!Number.isNaN(n)) {
      report.count("tmdb_id_string_coerced");
      return n;
    }
  }
  report.anomaly("tmdb_id_missing", `${ctx}: no usable tmdbId (${JSON.stringify(value)}), stored 0 sentinel`);
  return 0;
}

export function toText(value: unknown): string {
  return typeof value === "string" ? value : "";
}

// ------------------------------------------------------------ journal row

export type ExportedDoc = {
  id: string;
  createTime: string;
  updateTime: string;
  data: Record<string, unknown>;
};

export type JournalRow = {
  firestore_id: string;
  firebase_uid: string;
  tmdb_id: number;
  movie_title: string;
  movie_poster: string;
  emotions: string[];
  selected_scenes: Scene[];
  selected_refs: Ref[];
  thoughts: string;
  created_at: string;
  updated_at: string;
  raw: Record<string, unknown>;
};

export function transformJournal(doc: ExportedDoc, report: Report): JournalRow | null {
  const d = doc.data;
  const ctx = `journal ${doc.id}`;

  const firebaseUid = d.userId;
  if (typeof firebaseUid !== "string" || firebaseUid === "") {
    report.anomaly("journal_no_user", `${ctx}: missing userId, cannot map to an owner -- SKIPPED`);
    return null;
  }

  // Legacy key: selectedQuestions predates selectedRefs.
  let refsSource = d.selectedRefs;
  if (refsSource == null && d.selectedQuestions != null) {
    report.count("refs_from_legacy_selectedQuestions");
    refsSource = d.selectedQuestions;
  }

  const created = toUtcIso(d.createdAt, doc.createTime, report, `${ctx}.createdAt`);
  const updated = toUtcIso(d.updatedAt, doc.updateTime, report, `${ctx}.updatedAt`);
  report.count(`ts_created:${created.note}`);
  report.count(`ts_updated:${updated.note}`);

  return {
    firestore_id: doc.id,
    firebase_uid: firebaseUid,
    tmdb_id: toTmdbId(d.tmdbId, report, ctx),
    movie_title: toText(d.movieTitle),
    movie_poster: toText(d.moviePoster),
    emotions: normalizeEmotions(d.emotions, report, ctx),
    selected_scenes: normalizeScenes(d.selectedScenes, report, ctx),
    selected_refs: normalizeRefs(refsSource, report, ctx),
    thoughts: toText(d.thoughts),
    created_at: created.iso,
    updated_at: updated.iso,
    raw: d,
  };
}

// ---------------------------------------------------------------- username

/**
 * Mirrors validateUsername() in lib/features/login/screens/create_user.dart.
 * All three rules, not just the character class -- rule 3 in particular
 * constrains what the dedupe suffixer may produce.
 *
 * Returns an error string (like the Dart original) or null when valid.
 *
 * Note these rules may postdate some stored usernames, so existing Firebase
 * data can legitimately fail them. Import reports such names rather than
 * rewriting them: renaming a user's handle during a migration is a visible,
 * surprising change, and only collisions force our hand.
 */
const USERNAME_CHARS = /^[a-zA-Z0-9_.]+$/;
const USERNAME_ONLY_SPECIAL = /^[_.]+$/;

export function validateUsername(username: string): string | null {
  if (username.length === 0) return "Username cannot be empty";
  if (!USERNAME_CHARS.test(username)) {
    return "Username can only contain letters, numbers, _ and .";
  }
  if (USERNAME_ONLY_SPECIAL.test(username)) return "Username cannot contain only _ and .";
  if (username.endsWith(".") || username.endsWith("_")) {
    return "Username cannot end with _ or .";
  }
  return null;
}

export function isValidUsername(u: string): boolean {
  return validateUsername(u) === null;
}
