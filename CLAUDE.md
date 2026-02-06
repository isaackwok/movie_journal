# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter movie journal application that allows users to search for movies, view movie details, and create journal entries with emotions, thoughts, and AI-curated reviews about watched movies. The app integrates with The Movie Database (TMDB) API and uses Firebase for authentication and data storage.

## Development Commands

### Running the App
```bash
flutter run
```

### Building
```bash
# Development build
flutter build apk --debug

# Production build
flutter build apk --release
flutter build ios --release
```

### Testing and Linting
```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart
```

### Dependencies
```bash
# Install dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## Architecture

### Feature-Based Structure

The app follows a feature-based architecture where each feature is self-contained in `lib/features/`:

- **home/** - Main dashboard displaying journal entries list, empty state placeholders, and add movie button
  - `screens/` - HomeScreen with navigation. Empty state renders `EmptyPlaceholder` outside `SingleChildScrollView` (needs bounded height for `LayoutBuilder`); non-empty state wraps `JournalsList` in `SingleChildScrollView`.
  - `widgets/` - JournalCard, JournalsList, EmptyPlaceholder, AddMovieButton

- **journal/** - Core journaling features with full workflow from movie selection to saving
  - `controllers/` - JournalState (single journal), JournalsState (list of journals), JournalMode enum + JournalModeNotifier (create/edit mode)
  - `screens/` - Journaling (main editor), JournalComplete (post-save success screen), JournalContent (view saved journal), MoviePreview, ThoughtsEditor, CaptionEditor
  - `widgets/` - EmotionsSelectorButton, EmotionsSelectorBottomSheet, ScenesSelector, ScenesSelectSheet, SceneCard, ReviewItem, ReviewsBottomSheet, ThoughtsEditor, PosterPreviewModal, AiReferencesAccordion, JournalContentMoreMenu

- **movie/** - Movie data management with repository pattern
  - `controllers/` - MovieDetailController, MovieImagesController, SearchMovieController
  - `data/models/` - BriefMovie, DetailedMovie, MovieImage
  - `data/data_sources/` - MovieApi (TMDB integration)
  - `data/repositories/` - MovieRepository
  - `movie_providers.dart` - Riverpod providers for movie-related state

- **search_movie/** - Movie search interface integrating with TMDB API
  - `screens/` - SearchMovieScreen
  - `widgets/` - MovieSearchBar, MovieResultList

- **emotion/** - Emotion data model and definitions
  - `emotion.dart` - Emotion class and EmotionType enum with 24 emotions organized into 4 groups:
    - **Uplifting** (high energy, positive): Joyful, Funny, Inspired, Mind-blown, Hopeful, Fulfilling
    - **Intense** (high energy, negative): Shocked, Angry, Terrified, Anxious, Overwhelmed, Disturbed
    - **Soothing** (low energy, positive): Heartwarming, Touched, Peaceful, Therapeutic, Nostalgic, Cozy
    - **Quiet** (low energy, negative): Melancholic, Confused, Profound, Bittersweet, Powerless, Lonely

- **quesgen/** - AI review fetching service for movie reviews from external sources
  - `review.dart` - Review data model with `text` and `source` fields (sources: "letterboxd", "reddit")
  - `controller.dart` - Review generation logic (QuesgenController, QuesgenState)
  - `provider.dart` - Riverpod provider
  - `api.dart` - API integration (GET `/generate/{movieId}`) returning `{ reviews: [{ text, source }] }`

- **share/** - Share ticket feature for saving/sharing movie ticket images
  - `screens/` - ShareTicketScreen (ticket preview with save-to-gallery)
  - `widgets/` - FlippableTicket (3D flip animation), TicketFront (poster side), TicketBack (details side), FilmStripClipper (perforation CustomClipper)

- **login/** - Authentication screens and user creation flows
  - `screens/` - LoginScreen, CreateUserScreen

- **settings/** - User settings and account management
  - `screens/` - SettingsScreen (displays username, sign out, delete account options). Logout and delete flows invalidate journal/username providers to prevent stale data on re-login.

- **toast/** - Toast notification utilities
  - `custom_toast.dart` - Custom toast implementation using fluttertoast

### Core Infrastructure

**lib/core/**
- `network/` - Dio HTTP clients for external APIs
  - `tmdb_dio_client.dart` - The Movie Database API client
  - `quesgen_dio_client.dart` - AI review generation API client
- `utils/` - Shared utility functions
  - `color_utils.dart` - Color manipulation utilities

**lib/shared_widgets/**
- Reusable UI components used across features
- `confirmation_dialog.dart` - Generic confirmation dialog widget
- `circled_icon_button.dart` - Circular icon button with border styling, used for back buttons and action buttons across screens
  - Props: `icon` (required), `onPressed` (required), `iconSize` (default: 16), `iconColor`, `borderColor`, `outerPadding`, `size` (default: 36)

**Root-level managers:**
- `firebase_manager.dart` - Firebase Authentication wrapper (Apple Sign-In, Google Sign-In)
- `firestore_manager.dart` - Firestore CRUD operations for journal entries
- `shared_preferences_manager.dart` - Local preferences storage
- `themes.dart` - App-wide theme definitions (light/dark mode)
- `main.dart` - App entry point with Firebase initialization and web responsiveness

### State Management

Uses **Riverpod** for state management:
- Providers are typically defined in feature-specific files (e.g., `movie_providers.dart`)
- Controllers use Riverpod notifiers for complex state logic
- Follow patterns: `Provider` for computed values, `NotifierProvider` for simple and complex state, `FutureProvider`/`AsyncNotifierProvider` for async operations
- Note: Riverpod 3.x removed `StateProvider` — use a `Notifier` with a `set()` method instead (see `JournalModeNotifier` for pattern)

### Data Flow

1. **Movie Search**:
   - User searches → SearchMovieController → TMDB API (via `tmdb_dio_client.dart`) → BriefMovie models → Display results in MovieResultList
   - User selects movie → MovieDetailController → Fetch detailed movie data → Display in MoviePreview

2. **Journal Creation**:
   - Select movie → MoviePreview → Start journaling → Journaling screen
   - Select emotions (EmotionsSelectorBottomSheet) → Select scenes (ScenesSelectSheet) → Write thoughts (ThoughtsEditor)
   - Optionally fetch AI-curated reviews (ReviewsBottomSheet via `quesgen_dio_client.dart`)
   - Add caption (CaptionEditor) → Save to Firestore (via `FirestoreManager`) with userId → JournalCompleteScreen (animated success screen with journal card preview, "Share Ticket" and "View Journal" buttons)
   - Optional: "Share Ticket" → ShareTicketScreen → flippable movie ticket (poster front / details back with film strip perforations) → "Save Image" captures ticket as PNG via `RepaintBoundary` → saves to gallery via `gal` package

3. **Journal Editing**:
   - JournalContent → More menu → Edit → loads journal into `JournalController`, fetches movie images/details, navigates to `JournalingScreen(editJournalId: id)`
   - `JournalMode` provider (`journalModeProvider`) tracks create vs edit mode — any widget can read it without prop threading
   - In edit mode: ThoughtsScreen hides Reviews FAB and "Add" card, review taps are no-ops, date shows `createdAt`
   - Save calls `update()` (Firestore `.update()`, preserves `createdAt`) → `popUntil(isFirst)` back to home
   - Navigation: Home → JournalContent → [Edit] → JournalingScreen → [Save] → popUntil Home

4. **Journal Viewing**:
   - HomeScreen displays JournalsList → Fetch from Firestore by userId
   - Select journal → JournalContent screen → View emotions, thoughts, scenes, reviews

5. **Authentication**:
   - LoginScreen → Apple/Google Sign-In → Firebase Auth → Store user session
   - CreateUserScreen for new users → Set username → Store in Firestore
   - Journals synced by userId field in Firestore documents
   - **Logout/Delete**: SettingsScreen invalidates `journalsControllerProvider` and `currentUsernameProvider` via `ref.invalidate()` before navigating to HomeScreen, ensuring stale data from the previous user is discarded

## Key Dependencies

- **flutter_riverpod** (3.0.3) - State management framework
- **dio** (5.8.0+1) - HTTP client for API calls
- **firebase_core** (4.2.0) - Firebase initialization
- **firebase_auth** (6.1.1) - User authentication (Apple, Google)
- **cloud_firestore** (6.1.0) - NoSQL cloud database
- **google_sign_in** (7.2.0) - Google authentication integration
- **shared_preferences** (2.5.3) - Local key-value storage
- **flutter_dotenv** (6.0.0) - Environment variables (API keys stored in `.env`)
- **skeletonizer** (2.0.1) - Loading state skeleton animations
- **google_fonts** (6.2.1) - Custom typography (e.g., Nothing You Could Do font)
- **flutter_svg** (2.1.0) - SVG rendering support
- **jiffy** (6.4.3) - Date formatting and manipulation
- **fluttertoast** (9.0.0) - Toast notifications
- **uuid** (4.5.1) - Unique ID generation for journal entries
- **cupertino_icons** (1.0.8) - iOS-style icons
- **gal** (2.3.0) - Save images/videos to device gallery (used by share ticket feature)
- **share_plus** (12.0.1) - Native share sheet for sharing files/text (used by share ticket feature)
- **appinio_social_share** (0.3.2) - Instagram Story sticker sharing via pasteboard/intent (requires Facebook App ID)
- **url_launcher** (6.3.1) - Opens URLs externally (used for Threads Web Intent sharing)

### Dev Dependencies
- **flutter_lints** (6.0.0) - Recommended linting rules
- **custom_lint** (0.8.0) - Custom lint rule framework
- **riverpod_lint** (3.0.3) - Riverpod-specific linting
- **mocktail** (1.0.4) - Lightweight mocking (no codegen)

## Environment Setup

The app requires a `.env` file in the root directory with:
- TMDB API key
- Review generation API endpoint and key
- Other environment-specific configuration

Firebase configuration is in `lib/firebase_options.dart` (auto-generated).

## Coding Standards

### Widget Development
- Prefer `StatelessWidget` over `StatefulWidget`
- Use `const` constructors for performance
- Follow single responsibility principle
- Name widgets descriptively (screens end with "Screen", e.g., `HomeScreen`)

### File Naming
- Use snake_case for file names: `movie_detail_screen.dart`
- Use PascalCase for classes: `MovieDetailScreen`
- Use camelCase for variables/functions: `fetchMovieDetails`

### Feature Organization
Within each feature directory:
```
feature_name/
├── controllers/     # Riverpod notifiers and state logic
├── data/           # Data models and repositories
├── screens/        # Full-screen UI components
└── widgets/        # Reusable UI components
```

### Error Handling
- Always handle errors in async operations with try-catch
- Use Riverpod's `AsyncValue` for loading/error/data states
- Provide meaningful error messages to users via toast notifications

## UI/UX Guidelines

### Typography
- **Google Fonts** are used throughout the app (e.g., Nothing You Could Do for usernames in Settings)
- Access via `GoogleFonts` package with customizable font weights and sizes
- Maintain consistent text styles across the app using theme definitions

### Theme
- Supports light and dark themes (default: dark mode)
- Theme definitions in `lib/themes.dart`
- Access colors via `Theme.of(context).colorScheme`

### Loading States
- Use **Skeletonizer** package for skeleton screens
- Wrap loading content with `Skeletonizer.zone()`
- Use `Skeleton.leaf()` for individual loading elements

### Responsive Design
- Web builds are constrained to 400px width (mobile-like experience)
- Use `MediaQuery` for responsive breakpoints
- Support both mobile and web platforms

## Firebase Integration

### Authentication
- `FirebaseManager` provides wrappers for auth operations
- Supports Apple Sign-In and Google Sign-In
- Auth state changes available via `authStateChanges` stream
- Current implementation note: Apple Sign-In is enabled (check `firebase_manager.dart` for setup instructions)

### Firestore
- `FirestoreManager` handles journal CRUD operations
- Journals stored in `journals` collection with `userId` field
- Query journals by user: `getJournalsCollection(userId)`
- Add journals: `addJournal(userId, journal)`
- Update journals: `updateJournal(journalId, journal)` — uses Firestore `.update()`, fails if doc doesn't exist
- Delete journals: `deleteJournal(journalId)`

### Initialization
- Firebase initialized in `main.dart` before app runs
- Must call `Firebase.initializeApp()` with platform-specific options

## Testing

### Test Structure
Tests mirror the `lib/features/` structure under `test/features/`:
```
test/
├── helpers/
│   ├── test_journal.dart          # makeJournal() factory with sensible defaults
│   ├── test_movie.dart            # makeBriefMovieJson() factory for TMDB JSON fixtures
│   └── fake_http_client.dart      # FakeHttpOverrides for widget tests with Image.network
├── features/
│   ├── journal/
│   │   ├── controllers/
│   │   │   └── journal_test.dart      # JournalState model, SceneItem, JournalController (28 tests)
│   │   └── screens/
│   │       └── journal_complete_test.dart  # JournalCompleteScreen widget tests (10 tests)
│   ├── movie/
│   │   ├── data/models/
│   │   │   ├── brief_movie_test.dart   # BriefMovie.fromJson parsing (5 tests)
│   │   │   └── movie_image_test.dart   # MovieImage.fromJson parsing (1 test)
│   │   ├── data/data_sources/
│   │   │   └── movie_api_test.dart     # MovieListResponse.fromJson (2 tests)
│   │   └── controllers/
│   │       └── search_movie_controller_test.dart  # movieIntegrityChecker, state logic (5 tests)
│   ├── emotion/
│   │   └── emotion_test.dart      # Emotion data integrity (6 tests)
│   ├── quesgen/
│   │   └── review_test.dart       # Review model serialization + equality (5 tests)
│   └── share/
│       └── widgets/
│           ├── film_strip_clipper_test.dart  # CustomClipper geometry: corner holes, edge perforations, evenOdd fill (23 tests)
│           └── ticket_back_test.dart         # TicketBack widget: header, title, details, emotions, date/time, scene, layout (22 tests)
```

### Test Approach
- **Pure model tests**: Serialization, deserialization, backward compatibility, equality
- **Controller state tests**: Use `ProviderContainer` to test Riverpod notifiers without Flutter widgets
- **Widget tests**: Use `testWidgets` with `MaterialApp` wrapper; require `FakeHttpOverrides` for `Image.network` and `GoogleFonts.config.allowRuntimeFetching = false`
- **Data integrity tests**: Validate emotion list structure (24 emotions, 4 groups, energy levels)
- No Firebase or API mocking — tests cover models, state mutations, and widget rendering only

### Test Helpers
- `test/helpers/test_journal.dart` — `makeJournal()` factory creates a `JournalState` with defaults (tmdbId: 550, movieTitle: 'Fight Club'). Override any field for specific tests.
- `test/helpers/test_movie.dart` — `makeBriefMovieJson()` factory creates a TMDB-style JSON map. Override any field for specific tests.
- `test/helpers/fake_http_client.dart` — `FakeHttpOverrides` that returns a transparent 1x1 PNG for any HTTP GET. Use in `setUpAll` for widget tests that render `Image.network` widgets (e.g., `JournalCard`). Set `HttpOverrides.global = FakeHttpOverrides()` and reset to `null` in `tearDownAll`.

### Writing New Tests
- Place tests in `test/features/<feature>/` mirroring the source structure
- Use test helpers to avoid repeating boilerplate constructors
- For Riverpod controller tests: create a `ProviderContainer` in `setUp()`, dispose in `tearDown()`
- For model tests: no special setup needed, just import the model
- For widget tests: wrap in `MaterialApp`, use `FakeHttpOverrides` for network images, disable `GoogleFonts.config.allowRuntimeFetching`. Use `pumpAndSettle()` after `pumpWidget()` when testing animated widgets. When testing `IgnorePointer`, use `find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring)` to filter out Flutter's internal `IgnorePointer` widgets.

### Known Test Findings
- `SceneItem.copyWith(caption: null)` does not clear an existing caption — `??` operator preserves the old value. Clearing a caption after one was set requires a different approach than passing empty string to `updateSceneCaption()`.

## Common Development Workflows

### Adding a New Feature
1. Create feature directory under `lib/features/feature_name/`
2. Organize into subdirectories as needed:
   - `controllers/` for Riverpod notifiers and state logic
   - `data/` for models, repositories, and data sources
   - `screens/` for full-screen UI components
   - `widgets/` for reusable UI components specific to the feature
3. Define Riverpod providers for state management (create `providers.dart` or define in controller files)
4. For navigation:
   - From HomeScreen: Add navigation in `lib/features/home/screens/home.dart`
   - Within feature: Use `Navigator.push()` or `Navigator.of(context).push()`
5. Follow existing patterns from similar features:
   - For data-heavy features: See `movie/` (repository pattern, controllers, data models)
   - For UI-heavy features: See `journal/` (screens with bottom sheets, selectors)
   - For simple screens: See `settings/` (single screen, straightforward layout)
6. If the feature requires shared widgets used across multiple features, add them to `lib/shared_widgets/`

### Working with TMDB API
- API client: `lib/core/network/tmdb_dio_client.dart`
- Environment variable required: TMDB API key in `.env`
- Movie data models in `lib/features/movie/data/`

### Modifying Journal Features
- **Single journal state** managed by `JournalState` in `lib/features/journal/controllers/journal.dart`
- **List of journals** managed by `JournalsState` in `lib/features/journal/controllers/journals.dart`
- **Main screens**:
  - `journaling.dart` - Main journal editor with emotion and scene selection. Supports both create and edit modes via optional `editJournalId` prop (null = create, non-null = edit). Sets `journalModeProvider` on init.
  - `journal_content.dart` - View saved journal with all details
  - `movie_preview.dart` - Movie poster and details preview before journaling
  - `thoughts.dart` - Dedicated thoughts editor screen with horizontal selected reviews section at the top (scrollable cards + "Add" button) and text input below
  - `caption_editor.dart` - Caption editing screen
  - `journal_complete.dart` - Post-save success screen shown after creating a journal. Displays animated checkmark, "You've saved a journal" message, reuses `JournalCard` from `home/widgets/` (wrapped in `IgnorePointer`), "Share Ticket" button (navigates to `ShareTicketScreen`), and "View Journal" button. Uses staggered animations (`SingleTickerProviderStateMixin` with `Interval` curves) for a cascading reveal effect. Accepts a `JournalState` prop captured before state cleanup.
- **Key widgets**:
  - `emotions_selector_button.dart` & `emotions_selector_bottom_sheet.dart` - Emotion selection UI
  - `scenes_selector.dart` & `scenes_select_sheet.dart` - Scene selection from movie images
  - `review_item.dart` - Reusable review card with source icon (Letterboxd/Reddit) and optional action button. Props: `review` (required), `onPress` (optional), `showAction` (default: true), `isSelected` (default: false), `transparent` (default: false). When `transparent: true`, background is transparent with a subtle white border (used in accordion and horizontal scroll contexts). Four visual states: no action button (`showAction: false`), add button (`showAction: true`), selected checkmark (`showAction: true, isSelected: true`), transparent variant (`transparent: true`)
  - `reviews_bottom_sheet.dart` - Scrollable bottom sheet listing AI-curated reviews with add/selected actions
  - `poster_preview_modal.dart` - Full-size poster preview modal
  - `ai_references_accordion.dart` - Expandable AI references/reviews section using `ReviewItem` with `transparent: true` and `showAction: false`
  - `journal_content_more_menu.dart` - More options menu for saved journals (edit and delete actions)
- **Create flow**: Save to Firestore via `JournalController.save()` → captures `JournalState` → navigates to `JournalCompleteScreen` (pushAndRemoveUntil, keeps Home) → "View Journal" does `pushReplacement` to `JournalContent` → back returns to Home
- **Edit flow**: Load via `JournalController.loadJournal()` → edit in `JournalingScreen(editJournalId: id)` → `JournalController.update()` → popUntil home
- **Mode management**: `journalModeProvider` (`JournalMode.create` / `JournalMode.edit`) — set in `JournalingScreen.initState`, reset in `_cleanupState()`. Widgets like `ThoughtsScreen` read it to conditionally hide edit-inappropriate UI (FAB, Add card)

### Working with Share Ticket
- Feature lives under `lib/features/share/` with `screens/` and `widgets/` subdirectories
- **ShareTicketScreen** (`ConsumerStatefulWidget`) accepts a `JournalState` prop, reads movie details from `movieDetailControllerProvider` and images from `movieImagesControllerProvider`. Shows a centered `CircularProgressIndicator` while either provider is loading (`isLoading`), hiding the ticket and save button and disabling the share button. Once both APIs complete, renders the ticket and enables all actions.
- **FlippableTicket** wraps front/back widgets with 3D `Matrix4.rotationY` flip animation (600ms, tap to toggle)
- **TicketFront**: poster-only image filling the clipped ticket shape
- **TicketBack**: cream background with movie details, emotions, date band, B&W scene image
- **FilmStripClipper**: `CustomClipper<Path>` using `PathFillType.evenOdd` for film perforation holes
- **Save to gallery**: `RepaintBoundary` → `toImage()` → PNG bytes → `Gal.putImageBytes()` (saves to Camera Roll, no custom album) → `CustomToast.showSuccess`
- **Data extraction**: director from `movie.credits.crew` (job == 'Director'), cast from top 3 `movie.credits.cast`, scene fallback to `movieImages.backdrops.first`
- **Ticket number**: `journalsControllerProvider.value.journals.length` (total journal count)
- **Share bottom sheet**: App bar "Share" button opens `showModalBottomSheet` with drag indicator, "Copy text to post on Social" section (hidden when `thoughts` is empty) displaying `journal.thoughts` (maxLines: 10, ellipsis overflow), a "Copy Text" button using `Clipboard.setData()` + `CustomToast.showSuccess`, and a "Share Option" section with three buttons in a Row: Instagram Story, Threads, and Others
- **Instagram Story sharing**: `_shareToInstagramStory()` captures ticket via `RepaintBoundary.toImage()`, writes PNG to temp file, calls `AppinioSocialShare().shareToInstagramStory(appId, stickerImage: path)`. Requires Facebook App ID (stored as `_facebookAppId` constant). Shows toast if Instagram not installed.
- **Threads sharing**: `_shareToThreads()` composes text via `_composeThreadsText()`, opens `https://www.threads.net/intent/post?text={encoded}` via `url_launcher` with `LaunchMode.externalApplication`. Shows toast if Threads not installed.
- **Native share**: `_shareImageNatively()` captures current ticket side via `RepaintBoundary.toImage()`, writes PNG to `Directory.systemTemp`, and shares via `SharePlus.instance.share(ShareParams(files: [...]))`
- **Platform config**: iOS `Info.plist` has `LSApplicationQueriesSchemes` for `instagram-stories` and `threads`, plus Facebook App ID in `CFBundleURLSchemes`. Android `AndroidManifest.xml` has `<queries>` for Instagram story intent and Threads URL, plus `FileProvider` config with `filepaths.xml`.
- iOS requires `NSPhotoLibraryAddUsageDescription` in `Info.plist` for gallery save permission

### Working with Emotions
- Emotion definitions in `lib/features/emotion/emotion.dart`
- **24 emotions** organized into 4 groups based on energy level (high/low) and valence (positive/negative):
  - **Uplifting** (high energy, positive): Joyful, Funny, Inspired, Mind-blown, Hopeful, Fulfilling
  - **Intense** (high energy, negative): Shocked, Angry, Terrified, Anxious, Overwhelmed, Disturbed
  - **Soothing** (low energy, positive): Heartwarming, Touched, Peaceful, Therapeutic, Nostalgic, Cozy
  - **Quiet** (low energy, negative): Melancholic, Confused, Profound, Bittersweet, Powerless, Lonely
- Each emotion has:
  - `id`: Unique identifier (camelCase string)
  - `name`: Display name (with proper capitalization)
  - `group`: Group name (Uplifting, Intense, Soothing, or Quiet)
  - `energyLevel`: "high" or "low"
- Emotion colors are handled in the UI layer (EmotionsSelectorButton, EmotionsSelectorBottomSheet) rather than the data model
- Access emotions via `emotionList` map using `EmotionType` enum keys
- Users can select multiple emotions per journal entry

### Linting
- Uses `flutter_lints`, `custom_lint`, and `riverpod_lint`
- Run `flutter analyze` to check for issues
- Lint configuration in `analysis_options.yaml`

## Claude Code Configuration

### Directory Structure
```
.claude/
├── settings.local.json              # Local permissions and hook config (gitignored)
├── hooks/
│   ├── pre-commit-test.sh           # Runs flutter test before git commits
│   ├── stop-update-claude-md.sh     # Reminds to update CLAUDE.md after code changes
│   └── stop-sync-tests.sh          # Reminds to update tests when source files change
└── skills/
    └── journal-data-access/
        ├── SKILL.md                 # Riverpod patterns for journal CRUD
        └── references/
            └── journal-state-model.md  # JournalState fields and Firestore schema
```

### Hooks
- **pre-commit-test.sh** — A `PreToolUse` hook on the `Bash` tool that intercepts `git commit` commands. Runs `flutter test` before allowing the commit. If tests fail, the commit is blocked with test output shown as the reason. Non-commit Bash commands pass through unaffected.
- **stop-update-claude-md.sh** — A `Stop` hook that fires when Claude is about to finish responding. Checks if any `.dart`, `.yaml`, or `.json` files were modified (staged, unstaged, or untracked) without a corresponding CLAUDE.md update. If code changed but CLAUDE.md didn't, the hook blocks stopping (exit 2) and lists the changed files, prompting Claude to update CLAUDE.md before finishing. Excludes `.claude/` config files from the check. Once CLAUDE.md is also modified, the hook passes (exit 0) and Claude stops normally.
- **stop-sync-tests.sh** — A `Stop` hook that ensures unit tests stay in sync with source code. When `.dart` files under `lib/` are modified, it checks if the corresponding test file (`test/` mirror with `_test.dart` suffix) was also modified. If a source file has an existing test that wasn't updated, the hook blocks (exit 2) and lists the stale source→test pairs. Source files without existing tests are mentioned as an FYI but don't block on their own. Once the stale tests are updated, the hook passes (exit 0).
- Hooks are registered in `settings.local.json` under the `hooks.PreToolUse` and `hooks.Stop` keys (gitignored, local to each developer)

### Skills
- **journal-data-access** — Documents the Riverpod provider architecture for journal data. Covers the three core providers (`journalControllerProvider`, `journalsControllerProvider`, `journalModeProvider`), `ref.watch` vs `ref.read` patterns, CRUD operations, create vs edit mode, and AsyncValue handling. Reference file includes full JournalState fields and Firestore document schema.
