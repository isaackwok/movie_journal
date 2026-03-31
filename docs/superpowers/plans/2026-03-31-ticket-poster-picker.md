# Ticket Poster Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a poster picker screen before the share ticket screen so users can choose a poster in their preferred language.

**Architecture:** New `TicketPosterPickerScreen` widget fetches TMDB posters per language tab, displays a 2-column grid, and passes the selected poster path to `ShareTicketScreen`. The existing `MovieApi.getMovieImages()` already supports language filtering, so no API layer changes are needed. Local `Map` state caches fetched posters per language to avoid redundant API calls.

**Tech Stack:** Flutter, Riverpod, TMDB API (existing `MovieApi`)

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/features/share/screens/ticket_poster_picker_screen.dart` | New screen: language tabs + poster grid + selection + navigation to ShareTicketScreen |
| Modify | `lib/features/share/screens/share_ticket_screen.dart` | Accept optional `posterPath` param, use it instead of `journal.moviePoster` when provided |
| Modify | `lib/features/journal/screens/journal_complete.dart` | Navigate to `TicketPosterPickerScreen` instead of `ShareTicketScreen` |
| Modify | `lib/features/journal/screens/journal_content.dart` | Navigate to `TicketPosterPickerScreen` instead of `ShareTicketScreen` |
| Modify | `CLAUDE.md` | Document the new screen |

---

### Task 1: Add optional `posterPath` parameter to ShareTicketScreen

**Files:**
- Modify: `lib/features/share/screens/share_ticket_screen.dart:21-24` (constructor), `:567-568` (TicketFront usage)

- [ ] **Step 1: Add `posterPath` param to constructor**

In `share_ticket_screen.dart`, change the widget class:

```dart
class ShareTicketScreen extends ConsumerStatefulWidget {
  final JournalState journal;
  final String? posterPath;

  const ShareTicketScreen({super.key, required this.journal, this.posterPath});
```

- [ ] **Step 2: Use `posterPath` in TicketFront**

In the `build` method, around line 567, change:

```dart
// Before:
front: TicketFront(
  posterPath: journal.moviePoster,
),

// After:
front: TicketFront(
  posterPath: widget.posterPath ?? journal.moviePoster,
),
```

Note: The `journal` local variable is `widget.journal`, so use `widget.posterPath`.

- [ ] **Step 3: Verify the app still compiles**

Run: `flutter analyze`
Expected: No new errors (existing callers still work because `posterPath` is optional).

- [ ] **Step 4: Commit**

```bash
git add lib/features/share/screens/share_ticket_screen.dart
git commit -m "feat: add optional posterPath param to ShareTicketScreen"
```

---

### Task 2: Create TicketPosterPickerScreen

**Files:**
- Create: `lib/features/share/screens/ticket_poster_picker_screen.dart`

This is the main new screen. It's a `ConsumerStatefulWidget` that:
- Reads `movieDetailControllerProvider` to get the movie's `originalLanguage`
- Has 4 language tabs in a horizontal scroll
- Fetches posters from TMDB via `MovieApi.getMovieImages()` when a tab is selected
- Caches results in a local `Map<String, List<MovieImage>>`
- Shows a 2-column `GridView` of poster thumbnails
- Tracks the selected poster path in local state
- Navigates to `ShareTicketScreen` with the selected poster on "Next"

- [ ] **Step 1: Create the screen file with full implementation**

Create `lib/features/share/screens/ticket_poster_picker_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/share/screens/share_ticket_screen.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';

class TicketPosterPickerScreen extends ConsumerStatefulWidget {
  final JournalState journal;

  const TicketPosterPickerScreen({super.key, required this.journal});

  @override
  ConsumerState<TicketPosterPickerScreen> createState() =>
      _TicketPosterPickerScreenState();
}

class _TicketPosterPickerScreenState
    extends ConsumerState<TicketPosterPickerScreen> {
  static const _languageTabs = [
    ('Original Language', null), // null = will be resolved to movie's original language
    ('English', 'en'),
    ('繁體中文', 'zh'),
    ('日本語', 'ja'),
  ];

  int _selectedTabIndex = 0;
  String? _selectedPosterPath;
  bool _loading = false;

  /// Cache of fetched posters per language code.
  final Map<String, List<MovieImage>> _posterCache = {};

  String? _resolvedOriginalLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndFetch();
    });
  }

  Future<void> _initAndFetch() async {
    // Ensure movie details are loaded so we can read originalLanguage
    final notifier = ref.read(movieDetailControllerProvider.notifier);
    await notifier.fetchMovieDetails(widget.journal.tmdbId);

    final movie = ref.read(movieDetailControllerProvider).valueOrNull;
    if (movie != null) {
      _resolvedOriginalLanguage = movie.originalLanguage;
    }

    // Fetch posters for the default tab (Original Language)
    await _fetchPostersForTab(0);
  }

  String _languageCodeForTab(int index) {
    if (index == 0) {
      return _resolvedOriginalLanguage ?? 'en';
    }
    return _languageTabs[index].$2!;
  }

  Future<void> _fetchPostersForTab(int index) async {
    final langCode = _languageCodeForTab(index);

    // Use cache if available
    if (_posterCache.containsKey(langCode)) {
      _autoSelectFirst(langCode);
      return;
    }

    setState(() => _loading = true);

    try {
      final repo = ref.read(movieRepoProvider);
      final images = await repo.getMovieImages(
        id: widget.journal.tmdbId,
        language: langCode,
      );
      _posterCache[langCode] = images.posters;
      _autoSelectFirst(langCode);
    } catch (e) {
      debugPrint('Failed to fetch posters: $e');
      _posterCache[langCode] = [];
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _autoSelectFirst(String langCode) {
    final posters = _posterCache[langCode] ?? [];
    if (posters.isNotEmpty && _selectedPosterPath == null) {
      setState(() {
        _selectedPosterPath = posters.first.filePath;
      });
    }
  }

  void _onTabSelected(int index) {
    if (index == _selectedTabIndex) return;
    setState(() {
      _selectedTabIndex = index;
      _selectedPosterPath = null;
    });
    _fetchPostersForTab(index);
  }

  void _onPosterSelected(String path) {
    setState(() => _selectedPosterPath = path);
  }

  void _onNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareTicketScreen(
          journal: widget.journal,
          posterPath: _selectedPosterPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = _languageCodeForTab(_selectedTabIndex);
    final posters = _posterCache[langCode] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircledIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Choose a Ticket Poster',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'AvenirNext',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _selectedPosterPath != null ? _onNext : null,
              child: Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'AvenirNext',
                  color: _selectedPosterPath != null
                      ? Colors.white
                      : Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Language tabs
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languageTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedTabIndex;
                return GestureDetector(
                  onTap: () => _onTabSelected(index),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withAlpha(77),
                        ),
                      ),
                      child: Text(
                        _languageTabs[index].$1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'AvenirNext',
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Poster grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : posters.isEmpty
                    ? Center(
                        child: Text(
                          'No posters available',
                          style: TextStyle(
                            color: Colors.white.withAlpha(128),
                            fontSize: 14,
                            fontFamily: 'AvenirNext',
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: posters.length,
                        itemBuilder: (context, index) {
                          final poster = posters[index];
                          final isSelected =
                              poster.filePath == _selectedPosterPath;
                          return GestureDetector(
                            onTap: () => _onPosterSelected(poster.filePath),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isSelected ? 9 : 12,
                                ),
                                child: Image.network(
                                  'https://image.tmdb.org/t/p/w500${poster.filePath}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: const Color(0xFF2C2C2E),
                                    child: const Center(
                                      child: Icon(
                                        Icons.movie,
                                        color: Colors.white54,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: No errors related to the new file.

- [ ] **Step 3: Commit**

```bash
git add lib/features/share/screens/ticket_poster_picker_screen.dart
git commit -m "feat: add TicketPosterPickerScreen with language tabs and poster grid"
```

---

### Task 3: Update navigation to use TicketPosterPickerScreen

**Files:**
- Modify: `lib/features/journal/screens/journal_complete.dart:155-162`
- Modify: `lib/features/journal/screens/journal_content.dart:86-91`

- [ ] **Step 1: Update journal_complete.dart**

Change the `ShareTicketScreen` navigation (around line 155-162):

```dart
// Before:
builder: (context) =>
    ShareTicketScreen(journal: widget.journal),

// After:
builder: (context) =>
    TicketPosterPickerScreen(journal: widget.journal),
```

Add the import at the top:
```dart
import 'package:movie_journal/features/share/screens/ticket_poster_picker_screen.dart';
```

Remove the now-unused `ShareTicketScreen` import if present.

- [ ] **Step 2: Update journal_content.dart**

Change the share icon navigation (around line 87-89):

```dart
// Before:
builder: (_) => ShareTicketScreen(journal: journal),

// After:
builder: (_) => TicketPosterPickerScreen(journal: journal),
```

Add the import at the top:
```dart
import 'package:movie_journal/features/share/screens/ticket_poster_picker_screen.dart';
```

Remove the now-unused `ShareTicketScreen` import if present.

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze`
Expected: No errors. The unused `ShareTicketScreen` import should be removed.

- [ ] **Step 4: Commit**

```bash
git add lib/features/journal/screens/journal_complete.dart lib/features/journal/screens/journal_content.dart
git commit -m "feat: route share ticket flow through poster picker screen"
```

---

### Task 4: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add documentation for the new screen**

In the "Working with Share Ticket" section, add after the ShareTicketScreen entry:

```markdown
- **TicketPosterPickerScreen** — poster selection screen before share ticket. Displays language tabs ("Original Language", "English", "繁體中文", "日本語") and a 2-column grid of TMDB posters. "Original Language" resolves to the movie's `originalLanguage` field. Caches fetched posters per language in local `Map`. Navigates to `ShareTicketScreen(journal:, posterPath:)` on "Next".
```

Update the navigation flow description:
```markdown
- **Navigation flow**: callers → TicketPosterPickerScreen(journal:) → ShareTicketScreen(journal:, posterPath:)
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add TicketPosterPickerScreen to CLAUDE.md"
```
