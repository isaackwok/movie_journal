---
name: Journal Data Access
description: >
  This skill should be used when the user asks to "access journal data",
  "read journal state", "modify journal", "use journal providers",
  "watch journal", "create a journal feature", "add journal field",
  "save journal", "update journal", "delete journal",
  or needs guidance on Riverpod provider patterns for journal CRUD operations
  in this codebase.
version: 0.1.0
---

# Journal Data Access Through Riverpod

This skill documents the Riverpod provider architecture for all journal data
in the movie journal app. Follow these patterns when reading, creating,
editing, or deleting journal entries.

## Core Providers

Three providers manage all journal state:

| Provider | Type | State | Purpose |
|---|---|---|---|
| `journalControllerProvider` | `NotifierProvider` | `JournalState` | Single journal being created or edited |
| `journalsControllerProvider` | `AsyncNotifierProvider` | `JournalsState` | All journals for the current user (from Firestore) |
| `journalModeProvider` | `NotifierProvider` | `JournalMode` | Tracks whether the user is in create or edit mode |

All providers are defined in `lib/features/journal/controllers/`.

## Reading Journal Data

### Watching for Reactive Rebuilds

Use `ref.watch()` inside `build()` methods to rebuild the widget when state changes:

```dart
// Watch the full journal list (async — returns AsyncValue)
final journalsAsync = ref.watch(journalsControllerProvider);

// Access the list from the AsyncValue
final journals = journalsAsync.value?.journals ?? [];

// Watch a single journal being edited
final journal = ref.watch(journalControllerProvider);

// Watch specific fields for conditional UI
final isEditMode = ref.watch(journalModeProvider) == JournalMode.edit;
final selectedRefs = ref.watch(journalControllerProvider).selectedRefs;
```

### One-Time Reads

Use `ref.read()` inside callbacks, `initState`, or event handlers — never inside `build()`:

```dart
// Read current thoughts for a TextEditingController
thoughtsController.text = ref.read(journalControllerProvider).thoughts;

// Trigger a mutation
ref.read(journalControllerProvider.notifier).setEmotions(emotions);

// Set mode in initState
ref.read(journalModeProvider.notifier).set(JournalMode.edit);
```

### Key Rule

- `ref.watch()` = reactive, inside `build()` only
- `ref.read()` = imperative, inside callbacks and lifecycle methods only

## Mutating Journal State

### Setting Fields on the Active Journal

All setter methods are on the `journalControllerProvider.notifier` and return `this` for chaining:

```dart
ref.read(journalControllerProvider.notifier)
  .setMovie(tmdbId, title, poster);

ref.read(journalControllerProvider.notifier).setEmotions(emotions);
ref.read(journalControllerProvider.notifier).setSelectedScenes(scenes);
ref.read(journalControllerProvider.notifier).setThoughts(text);
ref.read(journalControllerProvider.notifier).addSelectedReview(review);
ref.read(journalControllerProvider.notifier).removeSelectedReview(review);
ref.read(journalControllerProvider.notifier).addScene(scenePath);
ref.read(journalControllerProvider.notifier).removeScene(scenePath);
ref.read(journalControllerProvider.notifier).updateSceneCaption(path, caption);
```

### Saving (Create Flow)

```dart
await ref.read(journalControllerProvider.notifier).save();
// save() internally:
//   1. Sets createdAt and updatedAt
//   2. Writes to Firestore via FirestoreManager.addJournal()
//   3. Updates state with Firestore-generated doc ID
//   4. Calls journalsControllerProvider.notifier.refreshJournals()
```

### Updating (Edit Flow)

```dart
await ref.read(journalControllerProvider.notifier).update();
// update() internally:
//   1. Sets updatedAt only (preserves createdAt)
//   2. Calls FirestoreManager.updateJournal()
//   3. Calls journalsControllerProvider.notifier.refreshJournals()
```

### Deleting

```dart
await ref.read(journalsControllerProvider.notifier).removeJournal(journalId);
// removeJournal() internally:
//   1. Calls FirestoreManager.deleteJournal()
//   2. Filters the journal out of local state
```

### Loading an Existing Journal for Editing

```dart
ref.read(journalControllerProvider.notifier).loadJournal(journal);
ref.read(journalModeProvider.notifier).set(JournalMode.edit);
```

### Cleanup After Navigation

```dart
ref.read(journalControllerProvider.notifier).clear();
ref.read(quesgenControllerProvider.notifier).clear();
ref.read(journalModeProvider.notifier).set(JournalMode.create);
```

## Create vs Edit Mode

`journalModeProvider` is a lightweight enum provider (`JournalMode.create` | `JournalMode.edit`).

- Set in `JournalingScreen.initState()` based on whether `editJournalId` is non-null
- Read by widgets to conditionally hide UI (e.g., ThoughtsScreen hides the Reviews FAB and "Add" card in edit mode)
- Reset to `JournalMode.create` during cleanup

Pattern for conditional UI:

```dart
final isEditMode = ref.watch(journalModeProvider) == JournalMode.edit;
// ...
floatingActionButton: isEditMode ? null : const ReviewsFloatingButton(),
```

## AsyncValue Handling for Journal Lists

`journalsControllerProvider` returns `AsyncValue<JournalsState>`. Handle all three states:

```dart
final journalsAsync = ref.watch(journalsControllerProvider);

journalsAsync.when(
  data: (journalsState) => JournalsList(journals: journalsState.journals),
  loading: () => const LoadingSkeleton(),
  error: (error, stack) => ErrorWidget(error),
);

// Or for simpler access:
final journals = journalsAsync.value?.journals ?? [];
```

## Additional Resources

### Reference Files

For detailed information, consult:
- **`references/journal-state-model.md`** — Full `JournalState` fields, serialization format, and Firestore document structure
