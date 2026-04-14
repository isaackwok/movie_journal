# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter movie journal application that allows users to search for movies, view movie details, and create journal entries with emotions, thoughts, and AI-curated reviews about watched movies. The app integrates with The Movie Database (TMDB) API. Authentication (Apple + Google Sign-In) and journal/user data storage run on **Supabase** (Auth + Postgres + Edge Functions). Firebase Analytics is retained for product analytics.

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
  - `screens/` - LoginScreen, CreateUserScreen (username input with validation: alphanumeric/underscore/dot only, uniqueness check via `SupabaseDbManager.usernameExists`, error toasts use `ToastGravity.TOP` to stay visible above the keyboard). `validateUsername()` is a top-level function for testability.

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
- `supabase_manager.dart` - Supabase Auth wrapper (Apple Sign-In, Google Sign-In, anonymous session, re-auth, delete account). Exposes the app-local `AppUser` struct (`{id, providerId, isAnonymous}`), `AppAuthException`, `cancelledAuthCodes`, and the testable top-level `mapSupabaseProvider()` function. Keeps Firebase provider-id vocabulary (`apple.com`/`google.com`/`anonymous`) so analytics strings don't change.
- `supabase_db_manager.dart` - Supabase Postgres CRUD wrapper for `public.journals` and `public.users`. Mirrors the former `FirestoreManager` method shapes but returns new row ids as `String`/`List<String>`. Contains `@visibleForTesting` `journalToRow`/`rowToJournalJson` adapters that re-key between camelCase (`JournalState`) and snake_case (Postgres columns).
- `shared_preferences_manager.dart` - Local preferences storage
- `themes.dart` - App-wide theme definitions (light/dark mode)
- `main.dart` - App entry point with Firebase (Analytics) + Supabase initialization and web responsiveness

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
   - Add caption (CaptionEditor) → Save to Supabase Postgres (via `SupabaseDbManager`) with user_id → JournalCompleteScreen (animated success screen with journal card preview, "Share Ticket" and "View Journal" buttons)
   - Optional: "Share Ticket" → ShareTicketScreen → flippable movie ticket (poster front / details back with film strip perforations) → "Save Image" captures ticket as PNG via `RepaintBoundary` → saves to gallery via `gal` package

3. **Journal Editing**:
   - JournalContent → More menu → Edit → loads journal into `JournalController`, fetches movie images/details, navigates to `JournalingScreen(editJournalId: id)`
   - `JournalMode` provider (`journalModeProvider`) tracks create vs edit mode — any widget can read it without prop threading
   - In edit mode: ThoughtsScreen hides Reviews FAB and "Add" card, review taps are no-ops, date shows `createdAt`
   - Save calls `update()` (Postgres `UPDATE ... WHERE id = $1`, preserves `created_at`) → `popUntil(isFirst)` back to home
   - Navigation: Home → JournalContent → [Edit] → JournalingScreen → [Save] → popUntil Home

4. **Journal Viewing**:
   - HomeScreen displays JournalsList → Fetch from `public.journals` by `user_id` (RLS also enforces this server-side)
   - Select journal → JournalContent screen → View emotions, thoughts, scenes, reviews

5. **Authentication**:
   - LoginScreen → Apple/Google Sign-In → Supabase Auth (`signInWithIdToken` on native, `signInWithOAuth` on web) → Store user session
   - CreateUserScreen for new users → Set username → Insert into `public.users`
   - Journals linked by `user_id` FK to `auth.users(id)` — Row Level Security policies (`users_self`, `journals_owner`) restrict all reads/writes to `auth.uid() = user_id`
   - **Logout/Delete**: SettingsScreen invalidates `journalsControllerProvider` and `currentUsernameProvider` via `ref.invalidate()` before navigating to HomeScreen via `pushAndRemoveUntil`, ensuring stale data from the previous user is discarded. Both flows use `pushAndRemoveUntil` to clear the entire navigation stack (including any open dialogs) — avoid popping dialogs before calling the delete/logout handler, as `showDialog`'s `builder: (context)` shadows the outer `BuildContext` and popping unmounts the dialog context
   - **Delete Account ordering**: `_deleteAccount()` calls `SupabaseManager().reauthenticate()` *before* any destructive action. This forces a fresh Apple/Google prompt so the caller is guaranteed a just-confirmed session before the server-side delete runs. If the user cancels the re-auth prompt, `reauthenticate()` throws `AppAuthException` with a code in `cancelledAuthCodes` (`canceled`/`cancelled`/`sign-in-cancelled`/`popup-closed-by-user`/`web-context-canceled`) and the function returns without touching any data. Only after re-auth succeeds does it call `SupabaseDbManager.deleteUser()` (which cascades: selects journal ids, deletes `public.journals` rows, deletes the `public.users` row, and returns the list of deleted journal ids), log `AnalyticsManager.logJournalDeleted` for each id, then call `SupabaseManager().deleteAccount()` which invokes the `delete-account` edge function (service-role `auth.admin.deleteUser`) and signs out locally.
   - **`SupabaseManager.reauthenticate()`**: Detects the active provider via `AppUser.providerId` (derived from Supabase `user.appMetadata['provider']`, mapped to `apple.com`/`google.com`/`anonymous` via `mapSupabaseProvider()`). For `apple.com` it re-runs `signInWithApple()`; for `google.com` it re-runs `signInWithGoogle()`. Anonymous users are a no-op. Unknown providers throw `AppAuthException(code: 'unsupported-provider')`. Both sign-in flows translate user cancellation into `AppAuthException(code: 'canceled')`.

## Key Dependencies

- **flutter_riverpod** (3.0.3) - State management framework
- **dio** (5.8.0+1) - HTTP client for API calls
- **firebase_core** (4.2.0) - Firebase initialization (retained for Analytics)
- **firebase_analytics** (12.0.4) - Google Analytics for Firebase (screen views, custom events, user properties)
- **supabase_flutter** (^2.8.0) - Supabase Auth + Postgres + Edge Functions client
- **sign_in_with_apple** (^6.1.0) - Native Apple ID credential flow on iOS (feeds `signInWithIdToken`)
- **crypto** (^3.0.3) - SHA-256 nonce hashing for Apple Sign-In
- **google_sign_in** (7.2.0) - Source of Google ID tokens on native (passed to Supabase `signInWithIdToken`)
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
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` for Supabase client initialization
- Other environment-specific configuration

Firebase configuration is in `lib/firebase_options.dart` (auto-generated, still needed for Firebase Analytics).

## Supabase Backend

The authentication + data backend lives in Supabase. Two artifacts in-repo describe the server-side contract:

- **`supabase/migrations/0001_init.sql`** — defines `public.users` (FK to `auth.users(id)` with `on delete cascade`, `username` unique), `public.journals` (FK to `auth.users`, snake_case columns for all `JournalState` fields, `emotions text[]`, `selected_scenes jsonb`, `selected_refs jsonb`, timestamptz `created_at`/`updated_at`), and Row Level Security policies:
  - `users_self` — a user can CRUD only their own `public.users` row (`auth.uid() = id`).
  - `users_username_readable` — anyone authenticated can `select` the `username` column for uniqueness checks during CreateUser.
  - `journals_owner` — a user can CRUD only their own `public.journals` rows (`auth.uid() = user_id`).
- **`supabase/functions/delete-account/index.ts`** — Deno edge function. The Supabase client SDK cannot delete its own auth user (only the service role can call `auth.admin.deleteUser`). The function verifies the caller's JWT via the anon key client, then uses a service-role client to delete `auth.users(<caller id>)`. Invoked from Dart via `client.functions.invoke('delete-account')`.

Apply migrations by running `supabase db push` (or pasting the SQL into Supabase Studio). Deploy the edge function with `supabase functions deploy delete-account` — it requires the `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` environment variables to be available to the function runtime (set via `supabase secrets set`).

### Schema mapping

`JournalState.toMap()` produces camelCase keys; Postgres columns are snake_case. The translation lives entirely in `SupabaseDbManager.journalToRow`/`rowToJournalJson` — `JournalState.toMap/fromJson` is still the single source of truth for field values. Mapping:

| JournalState key | Postgres column | Notes |
|---|---|---|
| `tmdbId` | `tmdb_id` | int |
| `movieTitle` | `movie_title` | text |
| `moviePoster` | `movie_poster` | nullable text, adapter defaults to `''` |
| `emotions` | `emotions` | text[] |
| `selectedScenes` | `selected_scenes` | jsonb |
| `selectedRefs` | `selected_refs` | jsonb |
| `thoughts` | `thoughts` | text |
| `createdAt` | `created_at` | timestamptz |
| `updatedAt` | `updated_at` | timestamptz |

The `user_id` column is added by the caller (`addJournal`/`addJournalsToCollection`) — `journalToRow` never emits it, and `rowToJournalJson` drops it so `JournalState.fromJson` is unchanged.

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

## Backend Integration

### Authentication (Supabase Auth)
- `SupabaseManager` (in `lib/supabase_manager.dart`) wraps `Supabase.instance.client.auth`.
- Supports **Apple Sign-In** (native iOS uses `sign_in_with_apple` + `signInWithIdToken` with a SHA-256 hashed nonce; web/Android falls back to `signInWithOAuth(OAuthProvider.apple)`) and **Google Sign-In** (native uses `GoogleSignIn.instance.authenticate()` → `idToken` → `signInWithIdToken`; web uses `signInWithOAuth(OAuthProvider.google)`).
- Auth state changes available via `authStateChanges` stream — a `Stream<AppUser?>` mapped from `onAuthStateChange`.
- `currentUser` returns an `AppUser` struct (`{id, providerId, isAnonymous}`), built from Supabase `User.appMetadata['provider']` via the testable top-level `mapSupabaseProvider()` function. Provider ids preserve Firebase's vocabulary (`apple.com`, `google.com`, `anonymous`) so analytics strings don't change.
- Re-auth + delete are handled by instance methods `reauthenticate()` and `deleteAccount()`. `deleteAccount()` invokes the `delete-account` edge function (service role required) and then calls `auth.signOut()` locally.
- Predictable failures surface as `AppAuthException {code, message}`. Cancellation codes are collected in `cancelledAuthCodes` so call sites can silently abort instead of showing an error.
- Xcode capability required: **Sign in with Apple** must be enabled on the Runner target.

### Postgres (Supabase)
- `SupabaseDbManager` (in `lib/supabase_db_manager.dart`) handles journal + user CRUD against `public.journals` and `public.users`.
- Query journals by user: `getJournalsCollection(userId)` → `from('journals').select().eq('user_id', userId)`.
- Add journals: `addJournal(userId, journal)` returns the new row's `id` (`String`). Bulk insert: `addJournalsToCollection(userId, journals)` returns `List<String>`.
- Update journals: `updateJournal(journalId, journal)` — `UPDATE ... WHERE id = $1`.
- Delete journals: `deleteJournal(journalId)`.
- User CRUD: `createUser`, `userExists`, `getUser` (shaped to match the old Firestore payload: `{userId, username, createdAt, updatedAt}`), `usernameExists` (used by CreateUser uniqueness check), `updateUsername`, `deleteUser` (cascading: returns journal ids before deleting, for analytics).
- All reads/writes are gated by RLS — clients can only see/modify their own rows.

### Initialization
- `main.dart` calls `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` first (Analytics still needs it), then `await Supabase.initialize(url: dotenv.env['SUPABASE_URL']!, anonKey: dotenv.env['SUPABASE_ANON_KEY']!)`.
- Both must succeed before `runApp` — the `authStateProvider` in `home.dart` listens to `SupabaseManager().authStateChanges`.

### Analytics
- `AnalyticsManager` in `lib/analytics_manager.dart` wraps `FirebaseAnalytics` with static methods
- Analytics collection disabled in debug builds (`!kDebugMode`), set in `main.dart`
- **User identification**: User ID and properties (`sign_in_method`, `username`) set via `ref.listenManual` on auth/username providers in `MyApp`
- **Screen tracking**: Manual `logScreenView()` calls in each screen's `initState` (stateful screens) or via `ScreenViewTracker` wrapper widget (ConsumerWidget screens: Home, Settings, MoviePreview)
- **Screen names**: Login, CreateUser, Home, Settings, SearchMovie, MoviePreview, Journaling, JournalComplete, JournalContent, Thoughts, CaptionEditor, TicketPosterPicker, ShareTicket
- **Custom events**:
  - `login` / `sign_up` — GA4 recommended events, logged in LoginScreen and CreateUserScreen
  - `journal_created` (movie_title, tmdb_id, emotion_count, scene_count) — logged in `JournalController.save()`
  - `journal_updated` (journal_id) — logged in `JournalController.update()`
  - `journal_deleted` (journal_id) — logged in `JournalsController.removeJournal()`
  - `movie_searched` (query) — logged on search submit in MovieSearchBar
  - `movie_selected` (tmdb_id, movie_title) — logged when user taps a search result
  - `journal_shared` (movie_title, share_method) — logged for instagram_story, threads, native share
  - `ticket_saved` (movie_title) — logged when ticket image saved to gallery
- **iOS config**: `IS_ANALYTICS_ENABLED` set to `true` in `GoogleService-Info.plist`

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
│   ├── home/
│   │   └── widgets/
│   │       └── journal_card_test.dart     # JournalCard widget: poster, title, date, styling (7 tests)
│   ├── journal/
│   │   ├── controllers/
│   │   │   ├── journal_test.dart      # JournalState model, SceneItem, JournalController (28 tests)
│   │   │   └── journals_test.dart     # JournalsState copyWith (4 tests)
│   │   ├── screens/
│   │   │   └── journal_complete_test.dart  # JournalCompleteScreen widget tests (10 tests)
│   │   └── widgets/
│   │       ├── emotions_selector_bottom_sheet_test.dart  # Multi-select, max limit, selection/deselection, Done/cancel (18 tests)
│   │       ├── emotions_selector_button_test.dart  # Energy gradients, text formatting, readonly mode (13 tests)
│   │       └── review_item_test.dart  # ReviewItem: 4 visual states, interaction, transparent variant (13 tests)
│   ├── movie/
│   │   ├── data/models/
│   │   │   ├── brief_movie_test.dart   # BriefMovie.fromJson parsing (5 tests)
│   │   │   ├── detailed_movie_test.dart # DetailedMovie + nested types fromJson (25 tests)
│   │   │   └── movie_image_test.dart   # MovieImage.fromJson parsing (1 test)
│   │   ├── data/data_sources/
│   │   │   └── movie_api_test.dart     # MovieListResponse.fromJson (2 tests)
│   │   └── controllers/
│   │       ├── movie_images_controller_test.dart  # Initial AsyncLoading state (regression test for issue #2 — "Error loading images" flash, 1 test)
│   │       └── search_movie_controller_test.dart  # movieIntegrityChecker, state logic (5 tests)
│   ├── login/
│   │   └── screens/
│   │       └── create_user_test.dart  # validateUsername: valid inputs, invalid chars, special-char-only, trailing _ and . (21 tests)
│   ├── emotion/
│   │   └── emotion_test.dart      # Emotion data integrity (6 tests)
│   ├── quesgen/
│   │   └── review_test.dart       # Review model serialization + equality (5 tests)
│   └── share/
│       └── widgets/
│           ├── film_strip_clipper_test.dart  # CustomClipper geometry: corner holes, edge perforations, evenOdd fill (23 tests)
│           ├── flippable_ticket_test.dart     # FlippableTicket: tap, swipe, fling, peek hint (21 tests)
│           ├── ticket_back_test.dart         # TicketBack widget: header, title, details, emotions, date/time, scene, layout (22 tests)
│           └── ticket_front_test.dart        # TicketFront widget: ClipPath, TMDB URL, error fallback (4 tests)
├── supabase_db_manager_test.dart     # SupabaseDbManager.journalToRow / rowToJournalJson adapters + round-trip through JournalState.fromJson (5 tests)
└── supabase_manager_test.dart        # mapSupabaseProvider (google/apple/unknown/anonymous/empty), cancelledAuthCodes membership, AppAuthException toString (8 tests)
```

### Test Approach
- **Pure model tests**: Serialization, deserialization, backward compatibility, equality
- **Controller state tests**: Use `ProviderContainer` to test Riverpod notifiers without Flutter widgets
- **Widget tests**: Use `testWidgets` with `MaterialApp` wrapper; require `FakeHttpOverrides` for `Image.network` and `GoogleFonts.config.allowRuntimeFetching = false`
- **Data integrity tests**: Validate emotion list structure (24 emotions, 4 groups, energy levels)
- No Firebase, Supabase, or API mocking — tests cover models, state mutations, widget rendering, and pure adapter/mapping functions. The Supabase manager tests exercise `mapSupabaseProvider` (a top-level pure function) and `SupabaseDbManager.journalToRow`/`rowToJournalJson` (marked `@visibleForTesting`), so no `SupabaseClient` stubbing is needed.

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
- **Single journal state** managed by `JournalState` in `lib/features/journal/controllers/journal.dart`
- **List of journals** managed by `JournalsState` in `lib/features/journal/controllers/journals.dart`
- **Main screens**:
  - `journaling.dart` - Main journal editor with emotion and scene selection. Supports both create and edit modes via optional `editJournalId` prop (null = create, non-null = edit). Sets `journalModeProvider` on init.
  - `journal_content.dart` - View saved journal with all details
  - `movie_preview.dart` - Movie poster and details preview before journaling
  - `thoughts.dart` - Dedicated thoughts editor screen with horizontal selected reviews section at the top (scrollable cards + "Add" button) and text input below
  - `caption_editor.dart` - Caption editing screen. Owns a `Map<String, FocusNode> _captionFocusNodes` keyed by scene path, mirroring the existing `_captionControllers` lifecycle — populated in `initState`, disposed in `dispose`. A `WidgetsBinding.instance.addPostFrameCallback` in `initState` focuses the initial scene's `TextField` on mount, and `_onPageChanged` re-focuses the newly visible scene on every swipe, so the keyboard follows the user as they caption multiple scenes in a single pass. `SceneCard` accepts the node via an optional `FocusNode? focusNode` passthrough with no owner-flag bookkeeping (if `null`, `TextField` creates its own internal node).
  - `journal_complete.dart` - Post-save success screen shown after creating a journal. Displays animated checkmark, "You've saved a journal" message, reuses `JournalCard` from `home/widgets/` (wrapped in `IgnorePointer`), "Share Ticket" button (navigates to `ShareTicketScreen`), and "View Journal" button. Uses staggered animations (`SingleTickerProviderStateMixin` with `Interval` curves) for a cascading reveal effect. Accepts a `JournalState` prop captured before state cleanup.
- **Key widgets**:
  - `emotions_selector_button.dart` & `emotions_selector_bottom_sheet.dart` - Emotion selection UI
  - `scenes_selector.dart` & `scenes_select_sheet.dart` - Scene selection from movie images
  - `review_item.dart` - Reusable review card with source icon (Letterboxd/Reddit) and optional action button. Props: `review` (required), `onPress` (optional), `showAction` (default: true), `isSelected` (default: false), `transparent` (default: false). When `transparent: true`, background is transparent with a subtle white border (used in accordion and horizontal scroll contexts). Four visual states: no action button (`showAction: false`), add button (`showAction: true`), selected checkmark (`showAction: true, isSelected: true`), transparent variant (`transparent: true`)
  - `reviews_bottom_sheet.dart` - Scrollable bottom sheet listing AI-curated reviews with add/selected actions
  - `poster_preview_modal.dart` - Full-size poster preview modal
  - `ai_references_accordion.dart` - Expandable AI references/reviews section using `ReviewItem` with `transparent: true` and `showAction: false`
  - `journal_content_more_menu.dart` - More options menu for saved journals (edit and delete actions)
- **Create flow**: Save to Supabase via `JournalController.save()` (inserts into `public.journals`, captures the returned row id and folds it into `JournalState.id`) → navigates to `JournalCompleteScreen` (pushAndRemoveUntil, keeps Home) → "View Journal" does `pushReplacement` to `JournalContent` → back returns to Home
- **Edit flow**: Load via `JournalController.loadJournal()` → edit in `JournalingScreen(editJournalId: id)` → `JournalController.update()` → popUntil home
- **Mode management**: `journalModeProvider` (`JournalMode.create` / `JournalMode.edit`) — set in `JournalingScreen.initState`, reset in `_cleanupState()`. Widgets like `ThoughtsScreen` read it to conditionally hide edit-inappropriate UI (FAB, Add card)

### Working with Share Ticket
- Feature lives under `lib/features/share/` with `screens/` and `widgets/` subdirectories
- **TicketPosterPickerScreen** — poster selection screen before share ticket. Displays language tabs ("Original Language", "English", "繁體中文", "日本語") with `Scrollable.ensureVisible` auto-scroll on selection. Tab styling: selected = white 70% bg / white 90% border / black text, unselected = white 15% bg / transparent border / white text, and a 2-column grid of TMDB posters. "Original Language" resolves to the movie's `originalLanguage` field. 繁體中文 uses `zh-TW` locale code. After the movie detail loads, `_applyLanguageTabFilter()` drops any fixed-language tab whose base code (part before `-`, case-insensitive) matches the movie's original language, so the duplicate tab is hidden (e.g. an English movie hides the "English" tab, a Chinese movie hides "繁體中文"). Caches fetched posters per language in local `Map`. Selected poster persists across tab switches. Selection uses `Stack` overlay border (no image shrink). "Next" button uses same `ElevatedButton` pattern as ShareTicketScreen's "Share" button. Navigates to `ShareTicketScreen(journal:, posterPath:)` on "Next".
- **Navigation flow**: callers → `TicketPosterPickerScreen(journal:)` → `ShareTicketScreen(journal:, posterPath:)`
- **ShareTicketScreen** (`ConsumerStatefulWidget`) accepts a `JournalState` prop and optional `posterPath` (overrides `journal.moviePoster` for the ticket front). Reads movie details from `movieDetailControllerProvider`, images from `movieImagesControllerProvider`, and journals from `journalsControllerProvider`. Shows a centered `CircularProgressIndicator` while any provider is loading (`isLoading` gates on all three), hiding the ticket and save button and disabling the share button. Once all APIs complete, renders the ticket and enables all actions.
- **"Tap to Flip" label** displayed above the ticket (Avenir Next demi-bold, 16px, white)
- **FlippableTicket** wraps front/back widgets with 3D `Matrix4.rotationY` flip animation (600ms). Supports tap-to-flip (full 180° animated flip) and horizontal swipe-to-flip (direct drag control with snap-to-nearest on release, fling support with 300 px/s velocity threshold). `hintOnMount` (default: false) triggers a peek animation on mount: 500ms delay → peek to 0.30 (350ms easeOut) → return to 0.0 (350ms easeIn via `animateBack`). Uses `_peekCancelled` flag so early taps/drags cancel the pending peek. `animateBack` (not `animateTo`) is used for the return to ensure the controller status is `dismissed` — `animateTo(0.0)` would leave status as `completed`, breaking `_flip()`'s `isCompleted` check.
- **TicketFront**: poster-only image filling the clipped ticket shape (uses `/w780` for higher-resolution share output)
- **TicketBack**: cream background with "FINK MOVIE JOURNAL" header, movie details, emotions, date band, B&W scene image
- **FilmStripClipper**: `CustomClipper<Path>` using `PathFillType.evenOdd` for film perforation holes
- **Image capture helpers**: `_captureTicketAsBytes()` captures the `RepaintBoundary` to PNG `Uint8List`, `_captureTicketToFile(filename)` wraps it to write a temp file. All share/save methods use these helpers instead of duplicating capture logic.
- **Save to gallery**: `_captureTicketAsBytes()` → `Gal.putImageBytes()` (saves to Camera Roll, no custom album) → `CustomToast.showSuccess`
- **Data extraction**: director from `movie.credits.crew` (job == 'Director'), cast from top 3 `movie.credits.cast`, scene fallback to `movieImages.backdrops.first`
- **Ticket number**: computed by `_computeTicketNumber()` — journal's chronological position (1-based), sorts all journals by `createdAt` ascending, finds the current journal's index by `id`, returns `index + 1`
- **Share bottom sheet**: App bar "Share" button opens `showModalBottomSheet` with drag indicator, "Copy text to post on Social" section (hidden when `thoughts` is empty) displaying `journal.thoughts` (maxLines: 10, ellipsis overflow), a "Copy Text" button using `Clipboard.setData()` + `CustomToast.showSuccess`, and a "Share Option" section with three buttons in a Row: Instagram Story, Threads, and Others
- **Instagram Story sharing**: `_shareToInstagramStory()` uses `_captureTicketToFile()` to get a temp PNG, calls `AppinioSocialShare().shareToInstagramStory(appId, stickerImage: path)`. Requires Facebook App ID (stored as `_facebookAppId` constant). Shows toast if Instagram not installed.
- **Threads sharing**: `_shareToThreads()` composes text via `_composeThreadsText()`, opens `https://www.threads.net/intent/post?text={encoded}` via `url_launcher` with `LaunchMode.externalApplication`. Shows toast if Threads not installed.
- **Native share**: `_shareImageNatively()` uses `_captureTicketToFile()` to get a temp PNG, shares via `SharePlus.instance.share(ShareParams(files: [...]))`
- **Platform config**: iOS `Info.plist` has `LSApplicationQueriesSchemes` for `instagram-stories` and `threads`, plus Facebook App ID in `CFBundleURLSchemes`, and `UIApplicationSceneManifest` for Flutter scene lifecycle. Android `AndroidManifest.xml` has `<queries>` for Instagram story intent and Threads URL, plus `FileProvider` config with `filepaths.xml`.
- iOS requires `NSPhotoLibraryAddUsageDescription` in `Info.plist` for gallery save permission
- **iOS engine lifecycle**: `AppDelegate.swift` uses `FlutterImplicitEngineDelegate` protocol — plugin registration happens in `didInitializeImplicitFlutterEngine` instead of `application:didFinishLaunchingWithOptions`

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
    │       └── journal-state-model.md  # JournalState fields and Supabase/Postgres schema
    └── flutter-animation-testing/
        └── SKILL.md                 # Animation test pitfalls and patterns
```

### Hooks
- **pre-commit-test.sh** — A `PreToolUse` hook on the `Bash` tool that intercepts `git commit` commands. Runs `flutter test` before allowing the commit. If tests fail, the commit is blocked with test output shown as the reason. Non-commit Bash commands pass through unaffected.
- **stop-update-claude-md.sh** — A `Stop` hook that fires when Claude is about to finish responding. Checks if any `.dart`, `.yaml`, or `.json` files were modified (staged, unstaged, or untracked) without a corresponding CLAUDE.md update. If code changed but CLAUDE.md didn't, the hook blocks stopping (exit 2) and lists the changed files, prompting Claude to update CLAUDE.md before finishing. Excludes `.claude/` config files from the check. Once CLAUDE.md is also modified, the hook passes (exit 0) and Claude stops normally.
- **stop-sync-tests.sh** — A `Stop` hook that ensures unit tests stay in sync with source code. When `.dart` files under `lib/` are modified, it checks if the corresponding test file (`test/` mirror with `_test.dart` suffix) was also modified. If a source file has an existing test that wasn't updated, the hook blocks (exit 2) and lists the stale source→test pairs. Source files without existing tests are mentioned as an FYI but don't block on their own. Once the stale tests are updated, the hook passes (exit 0).
- Hooks are registered in `settings.local.json` under the `hooks.PreToolUse` and `hooks.Stop` keys (gitignored, local to each developer)

### Skills
- **journal-data-access** — Documents the Riverpod provider architecture for journal data. Covers the three core providers (`journalControllerProvider`, `journalsControllerProvider`, `journalModeProvider`), `ref.watch` vs `ref.read` patterns, CRUD operations, create vs edit mode, and AsyncValue handling. Reference file includes full JournalState fields and Supabase Postgres schema.
- **flutter-animation-testing** — Pitfalls and patterns for testing Flutter animations. Covers: (1) `animateTo` vs `animateBack` status corruption (`animateTo(0.0)` leaves `isCompleted=true`), (2) `pumpAndSettle` not advancing past `Future.delayed` timers, (3) `pumpAndSettle` exiting between chained async animations. Includes a checklist and explicit-pump patterns.
