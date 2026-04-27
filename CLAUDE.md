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

### Deploying to App Store / TestFlight
```bash
# Full build + upload (build number auto-managed by App Store Connect)
./deploy.sh

# With explicit build number
./deploy.sh --build-number 29
```

Requires one-time setup: App Store Connect API Key (`.p8` file at `~/.appstoreconnect/private_keys/`) and credentials in `.deploy.env`. See deploy script comments for details.

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

- **home/** - Main dashboard: journal entries list, empty state, add movie button
  - `screens/` - HomeScreen. Empty state renders `EmptyPlaceholder` outside `SingleChildScrollView` (needs bounded height for `LayoutBuilder`); non-empty state wraps `JournalsList` in `SingleChildScrollView`.
  - `widgets/` - JournalCard, JournalsList, EmptyPlaceholder, AddMovieButton.
    - `JournalCard`: long-press triggers iOS-style `CupertinoContextMenu` with Edit / Share / Delete actions, all delegating to `lib/features/journal/widgets/journal_actions.dart`. Tap navigation is gated on `animation.value == 0` to ignore taps during the context-menu zoom. The card is wrapped in a `ConstrainedBox(maxWidth: 200, maxHeight: 340)` to sidestep a `CupertinoContextMenu` layout assertion — do not remove.
    - `JournalsList`: grid uses a `LayoutBuilder` that computes `mainAxisExtent` from actual cell width, not `childAspectRatio`. If you change card padding / gap / text size / poster ratio, update `nonPosterHeight` and `posterAspectFactor` in `journals_list.dart` so cells stay tight.

- **journal/** - Core journaling features with full workflow from movie selection to saving
  - `controllers/` - JournalState (single journal), JournalsState (list of journals), JournalMode enum + JournalModeNotifier (create/edit mode)
  - `screens/` - Journaling (main editor), JournalComplete (post-save success screen), JournalContent (view saved journal), MoviePreview, ThoughtsEditor, CaptionEditor
  - `widgets/` - EmotionsSelectorButton, EmotionsSelectorBottomSheet, ScenesSelector, ScenesSelectSheet, SceneCard, ReviewItem, ReviewsBottomSheet, ThoughtsEditor, PosterPreviewModal, AiReferencesAccordion, JournalContentMoreMenu, and `journal_actions.dart` — a set of shared helper functions (`editJournal`, `shareJournal`, `confirmDeleteJournal`, `deleteJournal`) that encapsulate the domain actions a journal can undergo. Reused by both the more-menu on `JournalContent` and the long-press menu on `JournalCard`. The helpers own the *domain action* (load state / navigate to editor, confirm dialog, Firestore delete + toast, navigate to `TicketPosterPickerScreen`) but intentionally leave post-action navigation (e.g. popping after delete) to the caller, since that depends on which screen initiated the action.

- **movie/** - Movie data management with repository pattern
  - `controllers/` - MovieDetailController, MovieImagesController, SearchMovieController
  - `data/models/` - BriefMovie, DetailedMovie, MovieImage
  - `data/data_sources/` - MovieApi (TMDB integration)
  - `data/repositories/` - MovieRepository
  - `movie_providers.dart` - Riverpod providers for movie-related state

- **search_movie/** - Movie search interface integrating with TMDB API
  - `screens/` - SearchMovieScreen
  - `widgets/` - MovieSearchBar, MovieResultList

- **emotion/** - Emotion data model (24 emotions in 4 groups — see Working with Emotions section)

- **quesgen/** - AI review fetching service for movie reviews from external sources
  - `review.dart` - Review data model with `text` and `source` fields (sources: "letterboxd", "reddit")
  - `controller.dart` - Review generation logic (QuesgenController, QuesgenState)
  - `provider.dart` - Riverpod provider
  - `api.dart` - API integration (GET `/generate/{movieId}`) returning `{ reviews: [{ text, source }] }`

- **share/** - Share ticket feature for saving/sharing movie ticket images
  - `screens/` - ShareTicketScreen (ticket preview with save-to-gallery)
  - `widgets/` - FlippableTicket (3D flip animation), TicketFront (poster side), TicketBack (details side), FilmStripClipper (perforation CustomClipper)

- **login/** - Authentication screens and user creation flows
  - `screens/` - LoginScreen, CreateUserScreen (username input with validation: alphanumeric/underscore/dot only, uniqueness check via Firestore, error toasts use `ToastGravity.TOP` to stay visible above the keyboard). `validateUsername()` is a top-level function for testability.

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
- `analytics_manager.dart` - Firebase Analytics wrapper (screen views, user ID, custom events). Also exports `ScreenViewTracker` widget for wrapping ConsumerWidget screens
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
   - **Logout/Delete**: SettingsScreen invalidates `journalsControllerProvider` and `currentUsernameProvider` before navigating via `pushAndRemoveUntil`. Don't pop dialogs before calling the handler — `showDialog`'s `builder: (context)` shadows the outer context and popping it unmounts the dialog context.
   - **Onboarding (create user) must invalidate `currentUsernameProvider`**: `main.dart` eagerly subscribes to it via `ref.listenManual(..., fireImmediately: true)` for analytics, so at app startup for a first-time signup the provider runs while `users/{uid}` doesn't exist yet, resolves to the `'User'` fallback, and caches it. After `_createUser()` writes the doc in `CreateUserScreen`, call `ref.invalidate(currentUsernameProvider)` before navigating to `HomeScreen` or the home will display `'User'` instead of the chosen name.
   - **Delete Account ordering (gotcha)**: `_deleteAccount()` must call `FirebaseManager.reauthenticate()` *before* any destructive action. Otherwise `currentUser.delete()` fails with `requires-recent-login` after Firestore data is already gone, leaving an unrecoverable half-deleted state. Order: reauthenticate → `FirestoreManager.deleteUser()` → log analytics per deleted journal id → `currentUser.delete()`.

## Key Dependencies

- **flutter_riverpod** (3.0.3) - State management framework
- **dio** (5.8.0+1) - HTTP client for API calls
- **firebase_core** (4.2.0) - Firebase initialization
- **firebase_auth** (6.1.1) - User authentication (Apple, Google)
- **cloud_firestore** (6.1.0) - NoSQL cloud database
- **firebase_analytics** (12.0.4) - Google Analytics for Firebase (screen views, custom events, user properties)
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
- **AvenirNext** is the primary UI font (registered in `pubspec.yaml` at weights 100–800, with Demi at w600). For inline bold accents in body text (emotion names, scene labels, date subtitles) use `fontFamily: 'AvenirNext'` with `FontWeight.w600` — not `.bold`/`.w700`, which falls back to a synthetic bold of the ambient font. The emotion-name typography is pinned by the `typography` group in `emotions_selector_button_test.dart`.
- **Google Fonts** are used for specific display treatments — `Inter` for movie/journal titles, `Nothing You Could Do` for usernames in Settings. Access via the `google_fonts` package.
- Theme colors via `Theme.of(context).colorScheme`.

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

### Analytics
- `AnalyticsManager` in `lib/analytics_manager.dart` wraps `FirebaseAnalytics` with static methods. Disabled in debug builds (`!kDebugMode`, set in `main.dart`). All events, screen names, and user properties live there — read the source rather than maintaining a list here.
- **Screen tracking pattern**: stateful screens call `logScreenView()` in `initState`; ConsumerWidget screens wrap in the `ScreenViewTracker` widget.
- **User identification**: `ref.listenManual` on auth/username providers in `MyApp` sets user id + `sign_in_method` / `username` properties.
- **iOS config**: `IS_ANALYTICS_ENABLED: true` in `GoogleService-Info.plist`.

## Testing

### Test Structure
Tests mirror `lib/features/` under `test/features/`. Shared helpers live in `test/helpers/` (see below). Browse `test/features/` directly for the current test inventory — listing every file here would rot.

### Test Approach
- **Pure model tests**: Serialization, deserialization, backward compatibility, equality
- **Controller state tests**: Use `ProviderContainer` to test Riverpod notifiers without Flutter widgets
- **Widget tests**: Use `testWidgets` with `MaterialApp` wrapper; require `FakeHttpOverrides` for `Image.network` and `GoogleFonts.config.allowRuntimeFetching = false`
- **Data integrity tests**: Validate emotion list structure (24 emotions, 4 groups, energy levels)
- No Firebase or API mocking — tests cover models, state mutations, and widget rendering only

### Test Helpers
- `test/helpers/test_journal.dart` — `makeJournal()` factory creates a `JournalState` with defaults (tmdbId: 550, movieTitle: 'Fight Club'). Override any field for specific tests.
- `test/helpers/test_movie.dart` — `makeBriefMovieJson()`, `makeDetailedMovieJson()`, `makeCastJson()`, `makeCrewJson()` factories create TMDB-style JSON maps. Override any field for specific tests.
- `test/helpers/fake_http_client.dart` — `FakeHttpOverrides` that returns a transparent 1x1 PNG for any HTTP GET. Used by `widget_test_setup.dart`.
- `test/helpers/widget_test_setup.dart` — `setUpWidgetTests()` and `tearDownWidgetTests()` combine `FakeHttpOverrides` and `GoogleFonts.config.allowRuntimeFetching = false` into a single call. Use in `setUpAll`/`tearDownAll` for any widget test that renders `Image.network` or GoogleFonts widgets.

### Writing New Tests
- Place tests in `test/features/<feature>/` mirroring the source structure
- Use test helpers to avoid repeating boilerplate constructors
- For Riverpod controller tests: create a `ProviderContainer` in `setUp()`, dispose in `tearDown()`
- For model tests: no special setup needed, just import the model
- For widget tests: wrap in `MaterialApp`, call `setUpWidgetTests()` / `tearDownWidgetTests()` from `test/helpers/widget_test_setup.dart` in `setUpAll`/`tearDownAll`. Use `pumpAndSettle()` after `pumpWidget()` when testing animated widgets. When testing `IgnorePointer`, use `find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring)` to filter out Flutter's internal `IgnorePointer` widgets.

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
- **`MovieImagesController.build()`** intentionally returns a never-completing `Completer<MovieImagesState>().future` so the provider stays in `AsyncLoading` until callers explicitly invoke `getMovieImages(id:)`. Do **not** make `build()` `throw` or return an empty state — both produce a one-frame UI flash on `ScenesSelector` (issue #2): `throw` flips the AsyncNotifier into `AsyncError` on the next microtask (overriding any synchronous `state = AsyncLoading` that callers set), and an empty state would briefly trigger the "Scene missing!" placeholder.

### Modifying Journal Features
State lives in `lib/features/journal/controllers/`: `JournalState` (single) and `JournalsState` (list). See the `journal-data-access` skill for provider patterns.

- **`JournalingScreen(editJournalId?)`**: single editor for both create and edit. `null` = create, non-null = edit. Sets `journalModeProvider` in `initState`, resets in `_cleanupState()`.
- **Mode provider**: `journalModeProvider` (`JournalMode.create` / `edit`) — widgets like `ThoughtsScreen` read it to hide edit-inappropriate UI (Reviews FAB, "Add" card; review taps become no-ops in edit mode).
- **Create flow**: `JournalController.save()` → captures `JournalState` → `pushAndRemoveUntil` to `JournalCompleteScreen` (keeps Home) → "View Journal" `pushReplacement` to `JournalContent`.
- **Edit flow**: `JournalController.loadJournal()` → `JournalingScreen(editJournalId)` → `JournalController.update()` (Firestore `.update()`, preserves `createdAt`) → `popUntil(isFirst)`.
- **Caption editor focus management**: `caption_editor.dart` owns `_captionFocusNodes` keyed by scene path. A `postFrameCallback` in `initState` focuses the initial scene's `TextField`; `_onPageChanged` re-focuses on every swipe so the keyboard stays up as the user captions multiple scenes.
- **Journal actions**: `lib/features/journal/widgets/journal_actions.dart` holds `editJournal` / `shareJournal` / `confirmDeleteJournal` / `deleteJournal`. Reused by both `JournalContent`'s more-menu and `JournalCard`'s context menu. Helpers own the domain action but leave post-action navigation to the caller.
- **`ReviewItem`** has four visual states via `showAction` / `isSelected` / `transparent` props — used in reviews bottom sheet (add/selected), AI references accordion (transparent, no action), etc.

### Working with Share Ticket
Feature lives under `lib/features/share/`. Flow: callers → `TicketPosterPickerScreen` → `ShareTicketScreen`.

- **`ShareTicketEntry` enum** (`journalContent` / `journalComplete`): identifies which screen opened the flow so the close button can route back correctly. Both `TicketPosterPickerScreen` and `ShareTicketScreen` close via the shared `closeShareFlow(context, entry)` helper in `share_ticket_screen.dart`:
  - `journalComplete` (just-saved journal) → `popUntil(isFirst)` → back to Home (skipping the celebration screen).
  - `journalContent` (sharing existing journal) → `popUntil((r) => r.settings.name != kShareFlowRouteName)` → back to JournalContent.
- **`kShareFlowRouteName` route tagging**: every push into the share flow sets `MaterialPageRoute(settings: const RouteSettings(name: kShareFlowRouteName), …)`. The `journalContent` close path uses this to pop until it leaves the flow — robust if intermediate screens are added/removed. **If you add a new screen inside the share flow, tag its route or close-back will overshoot.** Currently tagged at: `journal_complete.dart`, `journal_content.dart`, `journal_actions.dart`, and the in-flow push in `ticket_poster_picker_screen.dart`.
- **`TicketPosterPickerScreen`** has no Next button and no default-selected poster; tapping a poster pushes `ShareTicketScreen` immediately with that poster path. The AppBar carries only a close (X) action that calls `closeShareFlow`.
- **Ticket number**: `_computeTicketNumber()` = journal's chronological 1-based position. Sorts all journals by `createdAt` asc, finds current journal's index, returns `index + 1`.
- **Poster picker language tabs**: after the movie detail loads, `_applyLanguageTabFilter()` drops any fixed-language tab whose base code matches the movie's `originalLanguage` to avoid duplicates (e.g. an English movie hides the "English" tab). 繁體中文 uses `zh-TW`.
- **FlippableTicket peek animation**: `hintOnMount: true` triggers a 500ms-delayed peek (0 → 0.30 → 0) on mount. **Must use `animateBack(0.0)` for the return, not `animateTo(0.0)`** — `animateTo` leaves controller status as `completed`, which breaks `_flip()`'s `isCompleted` check. See the `flutter-animation-testing` skill for related pitfalls.
- **Image capture**: `_captureTicketAsBytes()` → PNG `Uint8List` from `RepaintBoundary`; `_captureTicketToFile()` writes it to a temp file. All save/share paths route through these two helpers.
- **Share destinations**: Instagram Story via `appinio_social_share` (requires Facebook App ID, stored as `_facebookAppId`), Threads via `url_launcher` to `threads.net/intent/post`, native share via `SharePlus`.
- **Platform config (don't forget)**:
  - iOS `Info.plist`: `LSApplicationQueriesSchemes` for `instagram-stories` + `threads`, Facebook App ID in `CFBundleURLSchemes`, `NSPhotoLibraryAddUsageDescription` for gallery save, `UIApplicationSceneManifest` for Flutter scene lifecycle.
  - `AppDelegate.swift` uses `FlutterImplicitEngineDelegate` — register plugins in `didInitializeImplicitFlutterEngine`, **not** `application:didFinishLaunchingWithOptions`.
  - Android `AndroidManifest.xml`: `<queries>` for Instagram + Threads intents, `FileProvider` with `filepaths.xml`.

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
    ├── journal-data-access/
    │   ├── SKILL.md                 # Riverpod patterns for journal CRUD
    │   └── references/
    │       └── journal-state-model.md  # JournalState fields and Firestore schema
    └── flutter-animation-testing/
        └── SKILL.md                 # Animation test pitfalls and patterns
```

### Hooks
- **pre-commit-test.sh** — A `PreToolUse` hook on the `Bash` tool that intercepts `git commit` commands. Runs `flutter test` before allowing the commit. If tests fail, the commit is blocked with test output shown as the reason. Non-commit Bash commands pass through unaffected.
- **stop-update-claude-md.sh** — A `Stop` hook that fires when Claude is about to finish responding. Checks if any `.dart`, `.yaml`, or `.json` files were modified (staged, unstaged, or untracked) without a corresponding CLAUDE.md update. If code changed but CLAUDE.md didn't, the hook blocks stopping (exit 2) and lists the changed files, prompting Claude to update CLAUDE.md before finishing. Excludes `.claude/` config files from the check. Once CLAUDE.md is also modified, the hook passes (exit 0) and Claude stops normally.
- **stop-sync-tests.sh** — A `Stop` hook that ensures unit tests stay in sync with source code. When `.dart` files under `lib/` are modified, it checks if the corresponding test file (`test/` mirror with `_test.dart` suffix) was also modified. If a source file has an existing test that wasn't updated, the hook blocks (exit 2) and lists the stale source→test pairs. Source files without existing tests are mentioned as an FYI but don't block on their own. Once the stale tests are updated, the hook passes (exit 0).
- Hooks are registered in `settings.local.json` under the `hooks.PreToolUse` and `hooks.Stop` keys (gitignored, local to each developer)

### Skills
- **journal-data-access** — Documents the Riverpod provider architecture for journal data. Covers the three core providers (`journalControllerProvider`, `journalsControllerProvider`, `journalModeProvider`), `ref.watch` vs `ref.read` patterns, CRUD operations, create vs edit mode, and AsyncValue handling. Reference file includes full JournalState fields and Firestore document schema.
- **flutter-animation-testing** — Pitfalls and patterns for testing Flutter animations. Covers: (1) `animateTo` vs `animateBack` status corruption (`animateTo(0.0)` leaves `isCompleted=true`), (2) `pumpAndSettle` not advancing past `Future.delayed` timers, (3) `pumpAndSettle` exiting between chained async animations. Includes a checklist and explicit-pump patterns.
