# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter movie journal application that allows users to search for movies, view movie details, and create journal entries with emotions, thoughts, and AI-curated reviews about watched movies. The app integrates with The Movie Database (TMDB) API, uses **Supabase** (Postgres + Supabase Auth) for authentication and data storage, and Firebase for analytics only.

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

- **auth/** - `auth_providers.dart`: the app-wide auth providers, importable without dragging in any screen — `authStateProvider` (Supabase auth stream), `currentUsernameProvider`, `anonymousBridgeProvider` (one-shot pre-login migration bridge), `hasProfileProvider` (HomeScreen vs CreateUserScreen; runs `claim_migrated_data()` once on a missing profile). Moved out of `home/screens/home.dart` (ISA-11) so features stop importing a screen file to reach auth state.

- **home/** - Main dashboard: journal entries list, empty state, add movie button
  - `screens/` - HomeScreen. Empty state renders `EmptyPlaceholder` outside `SingleChildScrollView` (needs bounded height for `LayoutBuilder`); non-empty state wraps `JournalsList` in `SingleChildScrollView`.
  - `widgets/` - JournalCard, JournalsList, EmptyPlaceholder, AddMovieButton.
    - `JournalCard`: long-press triggers iOS-style `CupertinoContextMenu` with Edit / Share / Delete actions, all delegating to `lib/features/journal/widgets/journal_actions.dart`. Tap navigation is gated on `animation.value == 0` to ignore taps during the context-menu zoom. The card is wrapped in a `ConstrainedBox(maxWidth: 200, maxHeight: 340)` to sidestep a `CupertinoContextMenu` layout assertion — do not remove. Visual spec: outer padding `fromLTRB(8, 8, 8, 12)`, 12px gap below poster, 8px gap between title and date, and the title+date pair gets an extra `EdgeInsets.symmetric(horizontal: 4)` inset. The padding values are pinned by `journal_card_test.dart`'s "layout spec" group — updating them requires updating the test AND `nonPosterHeight` in `journals_list.dart`.
    - `JournalsList`: month grouping + sorting live in `groupedJournalsProvider` (in `journals.dart`), a derived provider memoized per journals change — the widget just renders it. Grid uses a `LayoutBuilder` that computes `mainAxisExtent` from actual cell width, not `childAspectRatio`. If you change card padding / gap / text size / poster ratio, update `nonPosterHeight` and `posterAspectFactor` in `journals_list.dart` so cells stay tight. Current values: `nonPosterHeight = 70` (= 8 top pad + 12 image-title gap + 16 title (ceil of 14·1.1) + 8 title-date gap + 14 date (ceil of 12·1.1) + 12 bottom pad), `horizontalPaddingPerCard = 16` (= 8 × 2 sides). The value is intentionally tight — over-estimating leaves visible empty space below the date because `Flexible(fit: loose)` reserves the slot but the inner Column shrinks to its content.

- **journal/** - Core journaling features with full workflow from movie selection to saving
  - `controllers/` - `journal_state.dart` (SceneItem + JournalState model), `journal_mode.dart` (JournalMode enum + JournalModeNotifier), `journal.dart` (JournalController + provider; re-exports the other two, so `controllers/journal.dart` remains the one import for journal state), `journals.dart` (JournalsState list)
  - `screens/` - Journaling (main editor), JournalComplete (post-save success screen), JournalContent (view saved journal), MoviePreview, ThoughtsScreen (`thoughts.dart`), CaptionEditor. Note `ThoughtsScreen` (screen) and `ThoughtsEditor` (widget, below) are different classes — don't confuse them.
  - `widgets/` - SectionSeparator (the thin rule between JournalingScreen sections — extracted from `journaling.dart`, spelling fixed from `SectionSeperator`), EmotionsSelectorButton, EmotionsSelectorBottomSheet, ScenesSelector (whose selected-scene card is `SelectedSceneCard`), ScenesSelectSheet (whose grid tile is `SceneGridTile`), SceneCard, ReviewItem, ReviewsBottomSheet (opened only via `ReviewsBottomSheet.show(context)` — ThoughtsScreen and ReviewsFloatingButton share it), ThoughtsEditor, AiReferencesAccordion, JournalContentMoreMenu, and `journal_actions.dart` — a set of shared helper functions (`editJournal`, `shareJournal`, `confirmDeleteJournal`, `deleteJournal`) that encapsulate the domain actions a journal can undergo. Reused by both the more-menu on `JournalContent` and the long-press menu on `JournalCard`. The helpers own the *domain action* (load state / navigate to editor, confirm dialog, Supabase delete + toast, navigate to `TicketPosterPickerScreen`) but intentionally leave post-action navigation (e.g. popping after delete) to the caller, since that depends on which screen initiated the action.

- **movie/** - Movie data management with repository pattern
  - `controllers/` - MovieDetailController, MovieImagesController, SearchMovieController
    - `MovieDetailController` and `MovieImagesController` are **`.family(movieId)`** providers — one instance per TMDB id, so overlapping flows (journaling one movie while sharing another) cannot clobber each other's state. Both are deliberately **not autoDispose** (instances are a per-movie session cache; the prefetch-then-navigate pattern in `journal_actions.dart` and the share screens relies on state surviving until the destination screen watches) and have **retry disabled** (Riverpod 3's default exponential-backoff retry keeps `.future` pending across the whole schedule, hanging awaiters like `TicketPosterPickerScreen._initAndFetch` for minutes on a network error). `MovieDetailController.build()` fetches directly, so a failed fetch surfaces as `AsyncError` and `.future` always settles — the old fetch-on-demand Completer hung `.future` forever on error. Pinned by `movie_detail_controller_test.dart` / the family group in `movie_images_controller_test.dart`.
    - `SearchMovieController` carries race guards: a monotonic request id (`_requestId`) is checked before every `state =` so an out-of-order TMDB response (or failure) from a superseded query is dropped, and each `search()` cancels the previous query's Dio `CancelToken` (threaded through `MovieRepository`/`MovieAPI` as an optional param). `loadMore()` is a no-op while a reload is in flight — the visible list is the *previous* query's, preserved by Riverpod's automatic `copyWithPrevious` merge on `state = AsyncLoading()`. Pinned by the "race guards" group in `search_movie_controller_test.dart` (uses `_ControlledMovieRepo`, a completer-backed fake that lets tests deliver responses out of order).
  - `data/models/` - BriefMovie, DetailedMovie, MovieImage
  - `data/data_sources/` - MovieApi (TMDB integration)
  - `data/repositories/` - MovieRepository
  - `movie_providers.dart` - Riverpod providers for movie-related state

- **search_movie/** - Movie search interface integrating with TMDB API
  - `screens/` - SearchMovieScreen
  - `widgets/` - MovieSearchBar, MovieResultList
    - `MovieSearchBar`: **search-as-you-type** with a 300ms debounce (`_kSearchDebounce`). A `TextEditingController` *listener* (not `SearchBar.onChanged`) schedules the debounced `search()` — chosen so programmatic edits fire it too, notably the clear (X) button, which debounce-resets to popular. The listener also `setState`s so the trailing clear/search icon stays in sync (a `FocusNode` listener does the same for focus). Auto-fired searches are **not** logged to analytics; only explicit submit (keyboard "search" action / tap) logs via `logMovieSearched` and cancels any pending timer before searching immediately. `dispose()` cancels the timer, removes both listeners, and disposes the `FocusNode`. A reload no longer flashes skeletons: Riverpod merges the `AsyncLoading` with the previous state, and `MovieResultList` opts in with `skipLoadingOnReload: true`, so the old list stays visible until the new results land (skeletons only on first load). Behavior pinned by `movie_search_bar_test.dart`.

- **emotion/** - Emotion data model (24 emotions in 4 groups — see Working with Emotions section)

- **quesgen/** - AI review fetching service for movie reviews from external sources
  - `review.dart` - Review data model with `text` and `source` fields (sources: "letterboxd", "reddit")
  - `controller.dart` - Review generation logic (QuesgenController, QuesgenState). Also exports `toBackendLocaleTag()`, a top-level public function (public for testability, like `validateUsername`) converting the OS `Locale` to the BCP 47 tag the backend accepts — drops script subtags (`zh-Hant-TW` → `zh-TW`)
  - `provider.dart` - Riverpod provider
  - `api.dart` - API integration (GET `/generate/{movieId}`) returning `{ reviews: [{ text, source }] }`

- **share/** - Share ticket feature for saving/sharing movie ticket images
  - `share_flow.dart` - ShareTicketEntry enum, `kShareFlowRouteName`, `closeShareFlow()` — the flow's routing seam, importable without pulling in a screen.
  - `ticket_capture.dart` - `captureTicketAsBytes(repaintKey, pixelRatio:)` / `captureTicketToFile(...)` — RepaintBoundary → PNG; all save/share paths go through these.
  - `share_targets.dart` - `shareTicketToInstagramStory`, `shareToThreads`, `shareTicketNatively` — the destination integrations (appinio pasteboard, Threads web intent, native sheet) plus the Facebook App ID const.
  - `screens/` - TicketPosterPickerScreen (**flow entry point** — poster selection), ShareTicketScreen (ticket preview; owns only the screen layout + `_saveImage` state now). See [Working with Share Ticket](#working-with-share-ticket) for the close/route-tagging rules.
  - `widgets/` - FlippableTicket (3D flip animation), TicketFront (poster side), TicketBack (details side), FilmStripClipper (perforation CustomClipper), ShareOptionsSheet (the share bottom sheet: copy-thoughts block + three destination tiles; `show()` takes destination callbacks that run after the sheet pops)

- **login/** - Authentication screens and user creation flows
  - `screens/` - LoginScreen, CreateUserScreen (username input with validation: alphanumeric/underscore/dot only, uniqueness check via the `username_available` RPC, error toasts use `CustomToast.showError(..., gravity: ToastGravity.TOP)` to stay visible above the keyboard). `validateUsername()` is a top-level function for testability.

- **onboarding/** - Branded splash shown on cold start when the user is unauthenticated
  - `screens/` - BrandingSplashScreen — fade-in/hold/fade-out timeline (3s total) via a single `AnimationController` + `TweenSequence` (mirrors `journal_complete.dart`'s pattern). When the fade controller hits `completed`, calls `splashShownProvider.markShown()` so `HomeScreen` re-renders to `LoginScreen`. **No `Navigator.push`** — the splash plugs into `HomeScreen`'s stream-driven conditional in `home.dart` (the `splashShown ? LoginScreen : BrandingSplashScreen` branch), gated by `splashShownProvider`.
  - `widgets/` - PosterMarquee (two rows, blurred via `ImageFiltered` + `ImageFilter.blur`, tilted ~-0.18 rad, positioned bottom-right with negative offsets so it spills off the edge); MarqueeRow (doubles the URL list and uses `Transform.translate` driven by a linear-repeating `AnimationController` so the wrap-around is invisible).
  - `controllers/` - `splashShownProvider` (session-scoped Riverpod `Notifier<bool>`, defaults to false; resets only on cold restart — **never invalidated on logout**, so signing out within a session goes straight to LoginScreen, no replay); `splashPostersProvider` (live TMDB `/movie/popular` via `MovieAPI().popularMovies()`, falls back to a small bundled poster URL list inside the provider's `catch` so widgets never see the error path). The splash pre-warms this fetch in `initState` via `ref.read(provider.future)` so posters likely arrive during fade-in; on late arrival, `AnimatedOpacity` fades them in gently.
  - **Asset**: `assets/images/fink_logo.svg` — the "i + ticket-stub" mark (92×105 viewBox); the "Fink" wordmark below it is rendered via `GoogleFonts.nothingYouCouldDo()` so we can tune size/color without touching the SVG.

- **account_link/** - Attaches an Apple/Google identity to a bridged user's anonymous session (issue #22). Inert for everyone else: `needsAccountLinkProvider` is false for every user who signed in through LoginScreen, so nothing here builds.
  - `controllers/account_link.dart` - `needsAccountLinkProvider` (derived from `authStateProvider`; wraps `SupabaseAuthManager.needsIdentityLink()`, true iff `user.isAnonymous` — see the `supabase-migration` skill for why), `accountLinkPromptShownProvider` (session-scoped one-shot gate, mirrors `splashShownProvider`), and `AccountLinkService` behind `accountLinkServiceProvider` — a seam that exists purely so widget tests can fake the two link calls, including the conflict branch that would otherwise need two real provider accounts.
  - `widgets/` - `SecureAccountSheet` (dismissible modal, `show(context, journalCount:)`; renders the conflict explanation **inline** rather than as a dialog so the untried provider's button stays visible beside it), `SecureAccountBanner` (persistent, non-dismissible, self-clearing; also owns the one-time auto-prompt, scheduled to a post-frame callback because both flipping the Riverpod gate and pushing a route are illegal mid-build).

- **settings/** - User settings and account management
  - `screens/` - SettingsScreen (displays username, sign out, delete account options). Logout and delete flows invalidate journal/username providers to prevent stale data on re-login. When `needsAccountLinkProvider` is true it grows a warning-colored **Secure Account** item (the only entry point once the one-time prompt is gone) and the Logout dialog swaps in copy saying that getting back in depends on this device. Deliberately *not* "you will lose everything" — logging out is recoverable; see the `supabase-migration` skill.

- **toast/** - Toast notification utilities
  - `custom_toast.dart` - Custom toast built on `fluttertoast`. Three static entry points — `showSuccess(context, msg)`, `showError(context, msg, {gravity})`, `showWarning(context, msg)` — all render the same dark bordered card via a private `_show(...)`; only the icon glyph + accent vary. The icon is a filled circle in the status color with a **plain black** inner glyph. Colors come from `StatusColors` in `themes.dart` (success = primary `#A8DADD`, error `#FF615D`, warning `#FF9F1C`) — the single source of truth. There is no `init` step: `_show` re-inits its `FToast` from the passed context on every call (the old `CustomToast.init(context)` + show pairing is gone). `showError` takes an optional `gravity` (default `ToastGravity.BOTTOM`; the enum is re-exported from `custom_toast.dart` so call sites don't import fluttertoast) — CreateUserScreen passes `ToastGravity.TOP` to stay above the keyboard. This is the app's only error surface: no raw `Fluttertoast` or `SnackBar` calls. Status→color mapping pinned by `custom_toast_test.dart`.

### Core Infrastructure

**lib/core/**
- `network/` - Dio HTTP clients for external APIs
  - `tmdb_dio_client.dart` - The Movie Database API client
  - `quesgen_dio_client.dart` - AI review generation API client
- `utils/` - Shared utility functions
  - `tmdb_image_url.dart` - `tmdbImageUrl(path, TmdbImageSize)`, the one place TMDB image URLs are built (sizes: w154/w342/w500/w780/original; tolerates a missing leading slash). Rendering call sites do not use it directly — they go through `TmdbImage` (see below), which owns the size bucket. Direct callers are `TmdbImage` itself and `tmdbImageProvider`.

**lib/shared_widgets/**
- Reusable UI components used across features
- `tmdb_image.dart` - **Every TMDB poster/backdrop in the app renders through `TmdbImage`.** See [Working with TMDB imagery](#working-with-tmdb-imagery) for the cache policy and the two rules that are easy to break.
- `confirmation_dialog.dart` - Generic confirmation dialog widget
- `circled_icon_button.dart` - Circular icon button with border styling, used for back buttons and action buttons across screens
  - Props: `icon` (required), `onPressed` (required), `iconSize` (default: 16), `iconColor`, `borderColor`, `outerPadding`, `size` (default: 36)
- `sheet_app_bar.dart` - `SheetAppBar({title?, onCancel, onDone, backgroundColor?})`, the Cancel / centered-title / Done app bar shared by ThoughtsScreen, ScenesSelectSheet, and CaptionEditor (which passes no title). Implements `PreferredSizeWidget`.
- `provider_sign_in_button.dart` - `ProviderSignInButton`, the outlined Apple/Google button. Extracted from `login.dart`'s private `_SignInButton` when `SecureAccountSheet` needed the same control: both flows ask for the same credential through the same native prompt, so they must look identical. Only the label differs ("Sign in with…" vs "Continue with…").

**Root-level managers:**
- `analytics_manager.dart` - Firebase Analytics wrapper (screen views, user ID, custom events). Also exports `ScreenViewTracker` widget for wrapping ConsumerWidget screens
- `supabase_auth_manager.dart` - Supabase Auth wrapper (native Apple/Google `signInWithIdToken`, sign-out, reauth, account deletion)
- `supabase_db_manager.dart` - Postgres CRUD for `profiles` / `journals`, and the snake_case ↔ camelCase translation layer
- `anonymous_bridge.dart` - one-shot migration bridge for pre-migration Firebase anonymous accounts (transitional; delete at the Firestore freeze)
- `themes.dart` - App-wide theme definitions (light/dark mode)
- `main.dart` - App entry point with Firebase and Supabase initialization

### State Management

Uses **Riverpod** for state management:
- Providers are typically defined in feature-specific files (e.g., `movie_providers.dart`)
- Controllers use Riverpod notifiers for complex state logic
- Follow patterns: `Provider` for computed values, `NotifierProvider` for simple and complex state, `FutureProvider`/`AsyncNotifierProvider` for async operations
- Note: Riverpod 3.x removed `StateProvider` — use a `Notifier` with a `set()` method instead (see `JournalModeNotifier` for pattern)
- **State classes carry value equality.** `JournalState`, `JournalsState`, `SearchMovieState`, `QuesgenState`, `MovieImagesState` and their element models (`SceneItem`, `Emotion`, `Review`, `BriefMovie`, `MovieImage`) implement hand-rolled `==`/`hashCode` (deliberately no freezed/codegen). Riverpod's default `updateShouldNotify` compares with `==`, so a no-op `state = state.copyWith(...)` no longer notifies listeners. **Adding a field to one of these classes means updating its `==`/`hashCode` too** — the equality groups in the mirrored test files will catch a missed field only if you extend them.
- `JournalState` is immutable (all fields `final`). Its public constructor is a factory so a defaulted `updatedAt` equals the *resolved* `createdAt` (identical `Jiffy`, not a second `Jiffy.now()`).
- Prefer `ref.watch(provider.select((s) => s.field))` when a widget uses one or two fields of a larger state — done in `thoughts_editor.dart`, `scenes_selector.dart`, `caption_editor.dart`. Note `.select()` on a `List` field compares by list *identity*, which works because `copyWith` preserves untouched list instances.

### Data Flow

1. **Movie Search**:
   - User searches → SearchMovieController → TMDB API (via `tmdb_dio_client.dart`) → BriefMovie models → Display results in MovieResultList
   - User selects movie → MovieDetailController → Fetch detailed movie data → Display in MoviePreview

2. **Journal Creation**:
   - Select movie → MoviePreview → Start journaling → Journaling screen
   - Select emotions (EmotionsSelectorBottomSheet) → Select scenes (ScenesSelectSheet) → Write thoughts (ThoughtsEditor)
   - Optionally fetch AI-curated reviews (ReviewsBottomSheet via `quesgen_dio_client.dart`)
   - Add caption (CaptionEditor) → Save to Supabase (via `SupabaseDbManager`) with the caller's user id → JournalCompleteScreen (animated success screen with journal card preview, "Share Ticket" and "View Journal" buttons)
   - Optional: "Share Ticket" → ShareTicketScreen → flippable movie ticket (poster front / details back with film strip perforations) → "Save Image" captures ticket as PNG via `RepaintBoundary` → saves to gallery via `gal` package

3. **Journal Editing**:
   - JournalContent → More menu → Edit → loads journal into `JournalController`, fetches movie images/details, navigates to `JournalingScreen(editJournalId: id)`
   - `JournalMode` provider (`journalModeProvider`) tracks create vs edit mode — any widget can read it without prop threading
   - In edit mode: ThoughtsScreen hides the sticky-bottom Reviews bar and "Add" card, review taps are no-ops, date shows `createdAt`
   - Save calls `update()` (row UPDATE, preserves `created_at`) → `popUntil(isFirst)` back to home
   - Navigation: Home → JournalContent → [Edit] → JournalingScreen → [Save] → popUntil Home

4. **Journal Viewing**:
   - HomeScreen displays JournalsList → Fetch from Supabase by `user_id` (ordered newest-first by `created_at`)
   - Select journal → JournalContent screen → View emotions, thoughts, scenes, reviews

5. **Authentication**:
   - Cold start while logged out → BrandingSplashScreen (3s, fade-in/hold/fade-out, blurred poster marquee in bottom-right) → LoginScreen. Splash is gated by the session-scoped `splashShownProvider` and **only plays once per cold start** — logging out within the same session goes straight to LoginScreen, no replay.
   - Before the login screen is offered, `anonymousBridgeProvider` runs the anonymous-account bridge once. It returns `false` with no network call on devices with no Firebase anonymous session (the common case).
   - LoginScreen → native Apple/Google Sign-In → `signInWithIdToken` → Supabase session
   - `hasProfileProvider` decides HomeScreen vs CreateUserScreen. On a missing profile it runs `claim_migrated_data()` **once** and re-checks — that RPC is the fallback for a migrated user whose provider email changed since the export, so auto-linking had nothing to match. It must stay in a provider, not a `FutureBuilder(future: …)`, which would re-fire it on every rebuild.
   - CreateUserScreen for new users → Set username → insert into `profiles`
   - Journals are owned via `journals.user_id`, a FK to `auth.users`
   - **Logout/Delete**: SettingsScreen invalidates `journalsControllerProvider` and `currentUsernameProvider` before navigating via `pushAndRemoveUntil`. Don't pop dialogs before calling the handler — `showDialog`'s `builder: (context)` shadows the outer context and popping it unmounts the dialog context.
   - **Onboarding (create user) must invalidate TWO providers.** `main.dart` eagerly subscribes to `currentUsernameProvider` via `ref.listenManual(..., fireImmediately: true)` for analytics, so at startup for a first-time signup it resolves to the `'User'` fallback and caches it — invalidate or Home shows `'User'` instead of the chosen name. Also invalidate `hasProfileProvider`: it cached `false` a moment earlier (that is what routed the user to CreateUserScreen), so without it HomeScreen renders straight back to CreateUserScreen and signup appears to do nothing. Both are invalidated in `_handleStartJournaling()`; logout and account deletion invalidate them too.
   - **Delete Account**: now a single server-side call. `_deleteAccount()` reauthenticates (to confirm presence and allow cancel), then `SupabaseAuthManager.deleteAccount()`; deleting the `auth.users` row cascades to `profiles` + `journals` and fires the tombstone triggers. The old `requires-recent-login` half-deleted-state hazard is gone — Supabase has no such constraint, and the cascade is atomic. Reauth is kept for the UX, not for correctness.

## Key Dependencies

- **flutter_riverpod** (3.0.3) - State management framework
- **dio** (5.8.0+1) - HTTP client for API calls
- **supabase_flutter** (2.16.0) - Auth + Postgres data layer (replaced `cloud_firestore`)
- **sign_in_with_apple** (6.1.4) - Native Apple credential for `signInWithIdToken`
- **firebase_core** (4.10.0) - Firebase initialization
- **firebase_auth** (6.5.2) - **Transitional.** Only the anonymous-account bridge uses this; not for auth in new code. Removed at the Firestore freeze.
- **firebase_analytics** (12.4.2) - Google Analytics for Firebase (screen views, custom events, user properties)
  - **Keep the FlutterFire suite version-aligned.** Each Firebase plugin pins a specific `flutterfire` Swift package version (tracking `firebase_core`). If `firebase_auth` / `firebase_analytics` drift to versions released against *different* `firebase_core` builds, `flutter build ipa` fails at "Adding Swift Package Manager integration" with `Could not resolve package dependencies` (mismatched `flutterfire` pins). Fix: `flutter pub upgrade firebase_core firebase_auth firebase_analytics` to land a coordinated set.
- **google_sign_in** (7.2.0) - Google authentication integration
- **flutter_dotenv** (6.0.0) - Environment variables (API keys stored in `.env`)
- **skeletonizer** (2.0.1) - Loading state skeleton animations
- **cached_network_image** (3.4.1) - Disk-backed image loading; every TMDB image goes through it via `TmdbImage`. See [Working with TMDB imagery](#working-with-tmdb-imagery) for why it was adopted.
- **flutter_cache_manager** (3.4.2) - A direct dependency, not just a transitive one: `TmdbImageCache` configures its `CacheManager`/`Config` explicitly. Brings `sqflite` (the only new platform dependency in the set) and `path_provider` (already present).
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
- **file** (7.0.1) - Only for `test/helpers/fake_cache_manager.dart`: `BaseCacheManager` traffics in `package:file`'s `File`, so the fake serves bytes from a `MemoryFileSystem`.

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
- **Dark surfaces**: `DarkSurfaces` (in `themes.dart`) names the dark-grey ramp — `card` `#151515` (dialogs/toasts/filled fields), `sheet` `#171717` (reviews sheet), `sheetSecondary` `#1C1C1E` (selector sheets), `raisedCard` `#202020` (review/"Add" cards), `tile` `#222222` (home journal tile), `imagePlaceholder` `#2C2C2E` (poster loading). Don't hardcode a new dark hex — pick the closest step or add it to the class first. `journal_card_test.dart` / `review_item_test.dart` pin their widgets to the named steps.
- **Status colors**: `StatusColors` (in `themes.dart`) holds `success` (= primary `#A8DADD`), `error` (`#FF615D`), `warning` (`#FF9F1C`) as context-free constants — used as icon backgrounds (e.g. toasts), with a black inner glyph. They're constants rather than a `ThemeExtension` because they're identical in every theme and consumers shouldn't need a `BuildContext` just to pick an accent.

### Loading States
- Use **Skeletonizer** package for skeleton screens
- Wrap loading content with `Skeletonizer.zone()`
- Use `Skeleton.leaf()` for individual loading elements

### Responsive Design
- **Web is not a supported target.** The `web/`, `linux/`, and `windows/` scaffolds are deleted; `SupabaseAuthManager._assertNative()` throws `UnsupportedError` under `kIsWeb`. The throw is deliberate (decision 9): web auth would need an Apple Services ID, a `.p8`, and the OAuth redirect flow.
- Use `MediaQuery` for responsive breakpoints
- Mobile (iOS/Android) is the only functional platform

## Supabase Migration (transitional)

The Firebase→Supabase migration is **in progress and not yet cut over.** The full
runbook — the anonymous-account bridge, the credential-less session it creates, the
device-bound failure mode, and the `migration/` scripts — lives in the
**`supabase-migration` skill**, which loads on demand.

**Read that skill before** touching `lib/anonymous_bridge.dart`,
`lib/features/account_link/`, `supabase/functions/claim-anonymous/`, or anything under
`migration/` — and before testing any migration path on a device.

Two rules are here because breaking them is unrecoverable and the cost is not obvious:

- **Never use `flutter run` to test the migration path.** Pushing a build over a
  TestFlight install is a *replace*, not an update; iOS deletes the app's keychain
  items, destroying the Firebase anonymous session the bridge depends on. Silent, no
  prompt. Use TestFlight.
- **`firebase_auth` is a dependency solely for that bridge.** Not for auth in new
  code. It goes away at the Firestore freeze.

Permanent Supabase behavior — schema, RLS/GRANT column rules, timestamp conversion —
is under [Supabase Integration](#supabase-integration) below, not in the skill.

## Supabase Integration

### Authentication
- `SupabaseAuthManager` wraps all auth operations. Auth state via the `authStateChanges` stream (`onAuthStateChange` mapped to `Stream<User?>`).
- Apple and Google are **native-only** (`signInWithIdToken`): Supabase merely *verifies* a provider-signed token, so there is no client secret, no Apple Services ID, and no `.p8`. `kIsWeb` throws `UnsupportedError` deliberately — adding web later means adding all of that back.
- `reauthenticate()` returns `bool` (`false` = user backed out) rather than throwing, so screens never import `sign_in_with_apple` / `google_sign_in` just to recognise a cancellation. The classification itself lives in `cancellable()` (public — `LoginScreen` wraps the sign-in flows with it so a dismissed prompt stays silent while a real fault toasts), shared with the link flows — it is the one place that knows `SignInWithAppleAuthorizationException` and `GoogleSignInException` both mean "dismissed".
- `linkAppleIdentity()` / `linkGoogleIdentity()` attach a provider identity to the **current** session and return `IdentityLinkOutcome` (`linked` / `cancelled` / `alreadyLinkedToAnotherAccount`) — an enum, not exceptions, because two of the three are ordinary user choices. Real faults still throw. Token acquisition is shared with the sign-in paths (`_appleIdToken()`, `_googleAccount()`) so the Apple *raw* nonce is bound identically on both; diverging there fails the nonce check on one path only. See the `supabase-migration` skill for why this exists and why `linkIdentity()` can't be used.
- Google linking passes a best-effort `accessToken` from `authorizationForScopes`, which returns null instead of prompting when consent would be needed — linking must not turn into a second, unexplained permission dialog. GoTrue treats it as optional on the id_token grant (`signInWithGoogle` omits it entirely), so a null still links.
- `deleteAccount()` calls the `delete-account` Edge Function, then signs out locally — the server deletes the user but cannot clear this device's session.

### Data access
- `SupabaseDbManager` handles `profiles` / `journals` CRUD, mirroring the old `FirestoreManager` method-for-method.
- Ownership is enforced by RLS in the database; the `.eq('user_id', …)` filters are belt-and-braces, not the security boundary.
- Username availability goes through the `username_available` RPC, because RLS stops clients from scanning `profiles`. It compares **case-insensitively**, matching the `lower(username)` unique index.

### Schema, RLS, and grants

- `supabase/migrations/` — versioned schema (`profiles`, `journals`, `sync_tombstones`, `firebase_identity_map`), RLS on every table, tombstone triggers, and the `username_available` / `claim_migrated_data` RPCs. `supabase/tests/rls_smoke.sql` holds 63 pgTAP assertions; run with `supabase test db`.
- `supabase/functions/delete-account/` — deletes the caller's account server-side. The `auth.users` delete cascades to profiles and journals, so unlike the old client-side flow there is no window where data is gone but the account remains.
- **RLS scopes rows; GRANTs scope columns.** A policy like `journals_update_own` proves `auth.uid() = user_id` and says nothing about *which columns* the UPDATE touches — that is the GRANT's job, and `grant update on table` means all of them. `20260725071500_lock_migration_control_columns.sql` therefore replaces the blanket INSERT/UPDATE grants with **column allowlists that mirror `lib/supabase_db_manager.dart` exactly**. Consequences worth knowing before you debug a 403:
  - **Adding a column to `journalToRow()` (or the profiles writers) without adding it to that migration makes the write fail with 403**, not silently drop the column.
  - `user_id` *is* in the journals UPDATE allowlist — `journalToRow()` always sends it, even on edit. `WITH CHECK` is what stops it pointing at another user; the grant never was.
  - `created_at` is *not* in the journals UPDATE allowlist, so "an edit preserves `created_at`" is now a database guarantee rather than a client convention.
  - Ungranted to clients on both tables: `firestore_id`, `migrated_updated_at`, `raw`, `firebase_uid`, `journals.id`. These belong to the delta-sync. The reason is not tidiness: a client that could set its own `firestore_id` and then delete the row would make the `AFTER DELETE` trigger write a tombstone against **another user's** Firestore doc, and `import_data.ts` reads `sync_tombstones` as "deleted in the new app" and skips it for the rest of the window.
- **`alter default privileges … revoke execute on functions` does not work on Supabase Postgres 17.6** (measured; the table equivalent in `20260725033216` does). New functions still come out `proacl = NULL`, i.e. EXECUTE to PUBLIC, i.e. anon-callable. So **every new function in `public` needs an explicit `revoke execute … from public, anon`**. `rls_smoke.sql` enforces this: one assertion fails if any callable function is anon-executable, another pins the exact set callable by `authenticated`. Both name the offending function in the failure output.

### Timestamps

Journals store `Jiffy.toString()`, a **naive local** string with no zone. Postgres stores `timestamptz`, so the boundary must convert both ways, and `SupabaseDbManager` is the only place that happens:

- **Write**: `jiffyToUtcIso()` → absolute UTC. Never `jiffy.toString()` — Postgres would read that as UTC and shift every timestamp by 8 hours.
- **Read**: `pgTimestampToLocalNaive()` → local wall time. `JournalState.fromJson` feeds the value straight into `Jiffy.parse`, so handing it a UTC instant would render every journal 8 hours early. Pinned by `test/supabase_db_manager_test.dart`.

`JournalState` stays untouched — `toMap()`/`fromMap()` (with `fromJson` as a thin decode-then-`fromMap` wrapper) remain the serialization seam, and all snake_case ↔ camelCase translation happens in the manager layer. `rowToJournal` hands the row map straight to `fromMap` — no per-row `jsonEncode`/`jsonDecode` round trip.

### Initialization
- `main.dart` calls `WidgetsFlutterBinding.ensureInitialized()` **first** — `Supabase.initialize` persists sessions over platform channels and needs a live binding. Then dotenv, then `Firebase.initializeApp` (analytics), then `Supabase.initialize`.
- `.env` supplies `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`. The publishable key is meant to ship in the binary; the **secret** key must never appear in this repo (it lives in `$MIGRATION_DATA_DIR/.env`).

## Firebase Integration

> Analytics only, plus the transitional anonymous bridge. Auth and data moved to Supabase — see above.

### Analytics
- `AnalyticsManager` in `lib/analytics_manager.dart` wraps `FirebaseAnalytics` with static methods. Disabled in debug builds (`!kDebugMode`, set in `main.dart`). All events, screen names, and user properties live there — read the source rather than maintaining a list here.
- **Screen tracking pattern**: one idiom — every screen wraps its built root in the `ScreenViewTracker` widget (no `logScreenView()`-in-`initState` variant anymore). Screens with early loading/error returns (e.g. `JournalContent`) wrap only the main state so transient frames aren't logged. `ThoughtsScreen` deliberately does **not** log a screen view — it is a section of the Journaling flow, and logging it inflated screen counts.
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
- `test/helpers/fake_cache_manager.dart` — `FakeCacheManager`, a `BaseCacheManager` that serves the 1x1 PNG from a `MemoryFileSystem`. `FakeHttpOverrides` alone is **not** enough for `TmdbImage`: `cached_network_image` uses its own `http` client rather than `dart:io`'s, and the real `CacheManager` reaches for the `path_provider`/`sqflite` platform channels, which have no implementation under `flutter_test`. Only `getFileStream` is stubbed — everything else throws so a new dependency on it fails loudly. `failAll` / `delay` switches drive the error and placeholder branches.
- `test/helpers/widget_test_setup.dart` — `setUpWidgetTests()` and `tearDownWidgetTests()` combine `FakeHttpOverrides`, `GoogleFonts.config.allowRuntimeFetching = false`, and `TmdbImageCache.debugCacheManagerOverride` into a single call. Use in `setUpAll`/`tearDownAll` for any widget test that renders `TmdbImage`, `Image.network`, or GoogleFonts widgets. The installed fake is exposed as `currentFakeCacheManager` so a test can assert the requested URLs or flip `failAll`/`delay` — **call `setUpWidgetTests()` again in `setUp` if you do**, since those are per-test state and a leaked `delay` hangs the next test.

### Writing New Tests
- Place tests in `test/features/<feature>/` mirroring the source structure
- Use test helpers to avoid repeating boilerplate constructors
- For Riverpod controller tests: create a `ProviderContainer` in `setUp()`, dispose in `tearDown()`
- For model tests: no special setup needed, just import the model
- For widget tests: wrap in `MaterialApp`, call `setUpWidgetTests()` / `tearDownWidgetTests()` from `test/helpers/widget_test_setup.dart` in `setUpAll`/`tearDownAll`. Use `pumpAndSettle()` after `pumpWidget()` when testing animated widgets. When testing `IgnorePointer`, use `find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring)` to filter out Flutter's internal `IgnorePointer` widgets.

### Known Test Findings
- `SceneItem.copyWith(caption: null)` does not clear an existing caption — `??` operator preserves the old value. Clearing a caption after one was set requires a different approach than passing empty string to `updateSceneCaption()`.
- **Riverpod 3 auto-disposes by default, which makes async provider tests *hang* rather than fail.** `container.read(someStreamOrFutureProvider.future)` with nothing listening creates the element and tears it down in the same microtask, so the future never completes and the test sits until the 30s timeout — with a secondary `Bad state: … was disposed during loading state, yet no value could be emitted`. Attach `container.listen(provider, (_, _) {})` first (see `account_link_test.dart`'s `_containerFor`). Widgets never hit this because watching keeps the element alive. Five such tests turn a 12-second suite into a 20-minute one that looks like a slow compile.
- **A visible toast blocks taps underneath it.** `fluttertoast` inserts an overlay entry over the whole screen, so a `tester.tap()` after an error/success toast can miss its target ("derived an Offset that would not hit test on the specified widget"). Drain the toast with `pump(3s)` + `pumpAndSettle()` *before* the next tap, not just before the test ends.
- **The global `imageCache` poisons later tests in the same file.** An `Image.network` load cut off by a test's teardown caches its *error* keyed by URL; the next `testWidgets` rendering the same URL synchronously gets the poisoned entry and Flutter's unconstrained error placeholder — which surfaces as a baffling `RenderFlex overflowed` in a layout that cannot overflow, and only when tests run in a particular order. Fix with `setUp(() { imageCache.clear(); imageCache.clearLiveImages(); });` (see `movie_result_list_test.dart`). The *symptom* is now milder — `TmdbImage`'s default error widget is a bounded `Container`, not Flutter's unconstrained placeholder, so a poisoned entry shows as a blank tile rather than an overflow — but the poisoning itself is unchanged, so keep the `setUp`.
- **`pumpAndSettle` hangs on any screen showing a `Skeletonizer` shimmer that never resolves.** `JournalingScreen`'s scenes selector stays skeletonized by design (`MovieImagesController.build()` never completes until `getMovieImages` is called), so its shimmer loops forever. Drain timers with fixed-duration `pump(Duration(...))` calls instead (see `journaling_test.dart`).

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
- Images render through `TmdbImage`, which picks the size bucket — see [Working with TMDB imagery](#working-with-tmdb-imagery). **Do not fetch `/t/p/original` into phone-width boxes**: original posters run 2000×3000+ (~24MB decoded), and `w780` already exceeds a phone-width box at 3x.
- Environment variable required: TMDB API key in `.env`
- Movie data models in `lib/features/movie/data/`
- **`MovieImagesController.build()`** intentionally returns a never-completing `Completer<MovieImagesState>().future` so the provider stays in `AsyncLoading` until callers explicitly invoke `getMovieImages()` on the family instance (`movieImagesControllerProvider(movieId).notifier`). Do **not** make `build()` `throw` or return an empty state — both produce a one-frame UI flash on `ScenesSelector` (issue #2): `throw` flips the AsyncNotifier into `AsyncError` on the next microtask (overriding any synchronous `state = AsyncLoading` that callers set), and an empty state would briefly trigger the "Scene missing!" placeholder.

### Working with TMDB imagery

**Decision (ISA-18): the app uses `cached_network_image`.** Flutter's built-in
`imageCache` is memory-only and process-scoped, so raw `Image.network` re-downloaded
every poster on each cold start and again after any eviction. TMDB paths are
content-addressed — `/abc123.jpg` never changes bytes — so a disk cache has no
revalidation problem, only a size problem, which an explicit bound solves. The cost
was measured before adopting: 11 transitive packages, of which the only genuinely new
platform dependency is `sqflite` (`path_provider` was already pulled in by
`share_plus`/`gal`). `sqflite_darwin` is an ordinary CocoaPods pod; no `Podfile` edit
was needed. **Do not re-litigate this**; if it is ever reverted, the reason must be
recorded here.

- **`TmdbImage` (`lib/shared_widgets/tmdb_image.dart`) is the only way to render a TMDB image.** It takes a `path` + `TmdbImageSize`, never a URL — the size bucket is the widget's business, so no call site builds one. Widgets that used to accept an `imageUrl` (`SceneGridTile`, `SelectedSceneCard`) now accept an `imagePath`, and `splashPostersProvider` returns **paths, not URLs**, for the same reason.
- **Where an `ImageProvider` is genuinely needed** (`precacheImage`, palette extraction), use `tmdbImageProvider(path, size)` — *not* a bare `NetworkImage`. `CachedNetworkImageProvider` equality is by URL, so the provider warms the exact `imageCache` entry the widget resolves; a `NetworkImage` would warm an entry nothing reads.
- **Cache policy** lives in `TmdbImageCache`: key `tmdbImageCache`, `stalePeriod` 60 days, `maxNrOfCacheObjects` 400 (~20–60 MB at the w154–w780 sizes this app requests). The package defaults (30 days / 200 objects) are both short for immutable art and unbounded enough to matter — set explicitly rather than inherited.
- **`ShareTicketScreen` rasterises the ticket through a `RepaintBoundary`**, so it must never build while an image is still a placeholder — that placeholder would be baked into the saved PNG. Two things guarantee this and both must stay: `initState` precaches the poster and `isLoading` is gated on `_posterReady`, and `TicketFront`/`TicketBack` pass `fadeInDuration: Duration.zero` so a fade in flight cannot be captured either.
- **`cacheWidth` is deliberately absent.** ISA-12 surveyed every call site: the `w154`/`w342`/`w500` buckets are already at or below display resolution on 2–3x phones, so `cacheWidth` would be a no-op or force an upscaled decode. Do not add it.

### Modifying Journal Features
State lives in `lib/features/journal/controllers/`: `JournalState` (single) and `JournalsState` (list). See the `journal-data-access` skill for provider patterns.

- **`JournalingScreen(editJournalId?)`**: single editor for both create and edit. `null` = create, non-null = edit. Sets `journalModeProvider` in `initState`, resets in `_cleanupState()`.
- **Mode provider**: `journalModeProvider` (`JournalMode.create` / `edit`) — widgets like `ThoughtsScreen` read it to hide edit-inappropriate UI (sticky-bottom Reviews bar, "Add" card; review taps become no-ops in edit mode).
- **Create flow**: `JournalController.save()` → captures `JournalState` → `pushAndRemoveUntil` to `JournalCompleteScreen` (keeps Home) → "View Journal" `pushReplacement` to `JournalContent`.
- **Edit flow**: `JournalController.loadJournal()` → `JournalingScreen(editJournalId)` → `JournalController.update()` (row UPDATE, preserves `created_at`) → `popUntil(isFirst)`.
- **Caption editor focus management**: `caption_editor.dart` owns `_captionFocusNodes` keyed by scene path. A `postFrameCallback` in `initState` focuses the initial scene's `TextField`; `_onPageChanged` re-focuses on every swipe so the keyboard stays up as the user captions multiple scenes.
- **Journal actions**: `lib/features/journal/widgets/journal_actions.dart` holds `editJournal` / `shareJournal` / `confirmDeleteJournal` / `deleteJournal`. Reused by both `JournalContent`'s more-menu and `JournalCard`'s context menu. Helpers own the domain action but leave post-action navigation to the caller.
- **`ReviewItem`** has four visual states via `showAction` / `isSelected` / `transparent` props — used in reviews bottom sheet (add/selected), AI references accordion (transparent, no action), etc.
- **Selection-limit UX (scenes & emotions share one pattern)**: both `ScenesSelectSheet` (cap `_maxSceneLimit = 10`) and `EmotionsSelectorBottomSheet` (`maxSelectionLimit = 3`) show the same limit text — `'Select up to N (M/N)'`, styled `AvenirNext / 14 / w500 / height 1.5 / Colors.white.withAlpha(153)`, no color change at the cap. In `ScenesSelectSheet` this count is a **fixed header** above an `Expanded(SingleChildScrollView(GridView))` so it stays visible while the grid scrolls (don't move it back inside the scroll view). Tapping an *unselected* item while already at the cap is blocked **and** shows `CustomToast.showError(context, 'You can select up to N scenes/emotions')`; deselect/re-select stay silent. **Testing gotcha**: the toast spawns chained `fluttertoast` timers (≈2s show + fade), so any widget test that triggers an over-cap tap must drain them with `await tester.pump(const Duration(seconds: 3)); await tester.pumpAndSettle();` or it fails with "Timer still pending" (see `scenes_select_sheet_test.dart` / `emotions_selector_bottom_sheet_test.dart`).

### Working with Share Ticket
Feature lives under `lib/features/share/`. Flow: callers → `TicketPosterPickerScreen` → `ShareTicketScreen`.

- **`ShareTicketEntry` enum** (`journalContent` / `journalComplete`): identifies which screen opened the flow so the close button can route back correctly. Both `TicketPosterPickerScreen` and `ShareTicketScreen` close via the shared `closeShareFlow(context, entry)` helper. The enum, `kShareFlowRouteName`, and `closeShareFlow` all live in `lib/features/share/share_flow.dart`:
  - `journalComplete` (just-saved journal) → `popUntil(isFirst)` → back to Home (skipping the celebration screen).
  - `journalContent` (sharing existing journal) → `popUntil((r) => r.settings.name != kShareFlowRouteName)` → back to JournalContent.
- **`kShareFlowRouteName` route tagging**: every push into the share flow sets `MaterialPageRoute(settings: const RouteSettings(name: kShareFlowRouteName), …)`. The `journalContent` close path uses this to pop until it leaves the flow — robust if intermediate screens are added/removed. **If you add a new screen inside the share flow, tag its route or close-back will overshoot.** Currently tagged at: `journal_complete.dart`, `journal_content.dart`, `journal_actions.dart`, and the in-flow push in `ticket_poster_picker_screen.dart`.
- **`TicketPosterPickerScreen`** has no Next button and no default-selected poster; tapping a poster pushes `ShareTicketScreen` immediately with that poster path. The AppBar carries only a close (X) action that calls `closeShareFlow`.
- **`JournalCompleteScreen`** has its own close (X) in the top-right (a `Stack` overlay, not an AppBar, so the centered animation layout is not shifted). It does *not* call `closeShareFlow` — this screen isn't part of the share flow — but it pops to the same destination as the `journalComplete` close (`Navigator.popUntil((r) => r.isFirst)` → Home), since this screen only ever appears for a just-saved journal.
- **Ticket number**: `ticketNumberProvider(journalId)` (in `share/controllers/ticket_number.dart`) = journal's chronological 1-based position (sort by `createdAt` asc, index + 1; 0 while loading or if the id is unknown). A `.family` provider so the sort is memoized per journals change instead of re-running on every `ShareTicketScreen` rebuild.
- **Poster picker language tabs**: after the movie detail loads, `_applyLanguageTabFilter()` drops any fixed-language tab whose base code matches the movie's `originalLanguage` to avoid duplicates (e.g. an English movie hides the "English" tab). 繁體中文 uses `zh-TW`.
- **FlippableTicket peek animation**: `hintOnMount: true` triggers a 500ms-delayed peek (0 → 0.30 → 0) on mount. **Must use `animateBack(0.0)` for the return, not `animateTo(0.0)`** — `animateTo` leaves controller status as `completed`, which breaks `_flip()`'s `isCompleted` check. See the `flutter-animation-testing` skill for related pitfalls.
- **Image capture**: `ticket_capture.dart`'s `captureTicketAsBytes(repaintKey, pixelRatio:)` → PNG `Uint8List` from `RepaintBoundary`; `captureTicketToFile(...)` writes it to a temp file. All save/share paths route through these two helpers; read `devicePixelRatio` from context *before* any async gap and pass it in.
- **"Copy Text" tap target**: the copy-thoughts-to-clipboard control is a `GestureDetector` with `behavior: HitTestBehavior.opaque` (so the whole row width is tappable, not just the centered icon+text glyphs — the default `deferToChild` ignores the empty space) wrapping a `Padding(vertical: 8)` to enlarge the vertical hit area to match the visible button.
- **Share destinations**: `share_targets.dart` — Instagram Story via `appinio_social_share` (requires the Facebook App ID const kept there), Threads via `url_launcher` to `threads.net/intent/post`, native share via `SharePlus`.
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
- **`analyzer.exclude: build/**` is load-bearing.** Swift Package Manager checks out the *full pub source* of the Firebase plugins — including their own mockito-based `test/` dirs — into `build/{ios,macos}/SourcePackages/`. Without the exclude, `flutter analyze` reports ~950 errors from third-party test files (`undefined_function: when/verify/anyNamed`) after any iOS/macOS build. Deleting `build/` also clears them, but they come back on the next build.

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
    │       └── journal-state-model.md  # JournalState fields and Postgres schema
    ├── flutter-animation-testing/
    │   └── SKILL.md                 # Animation test pitfalls and patterns
    ├── deploy/
    │   └── SKILL.md                 # App Store Connect / TestFlight deploy flow
    └── supabase-migration/
        └── SKILL.md                 # Firebase→Supabase bridge + cutover runbook
```

### Hooks
- **pre-commit-test.sh** — A `PreToolUse` hook on the `Bash` tool that intercepts `git commit` commands. Runs `flutter test` before allowing the commit. If tests fail, the commit is blocked with test output shown as the reason. Non-commit Bash commands pass through unaffected.
- **stop-update-claude-md.sh** — A `Stop` hook that nudges doc updates only for **significant, doc-worthy** code changes (not every edit — padding the docs for trivial fixes breeds rot). It scopes to `lib/**/*.dart` (excluding `*.g.dart` and `firebase_options.dart`; test-only and config changes never trigger it) plus `pubspec.yaml`. A change is "significant" if it adds a new `lib/` Dart file, touches ≥ `DOC_HOOK_MIN_LINES` lines (default 80, tunable via env var), or changes a dependency in `pubspec.yaml`. The two docs are required independently by relevance: **CLAUDE.md** (architecture/internals) is required for any significant change; **README.md** (user-facing) is required *only* when a brand-new feature directory appears under `lib/features/` or `pubspec.yaml` changes. Internal tweaks to existing screens/widgets never demand a README edit. When a required doc is missing the hook blocks (exit 2) and lists the relevant files; otherwise it passes (exit 0).
- **stop-sync-tests.sh** — A `Stop` hook that ensures unit tests stay in sync with source code. When `.dart` files under `lib/` are modified, it checks if the corresponding test file (`test/` mirror with `_test.dart` suffix) was also modified. If a source file has an existing test that wasn't updated, the hook blocks (exit 2) and lists the stale source→test pairs. Source files without existing tests are mentioned as an FYI but don't block on their own. Once the stale tests are updated, the hook passes (exit 0).
- Hooks are registered in `settings.local.json` under the `hooks.PreToolUse` and `hooks.Stop` keys (gitignored, local to each developer)

### Skills
- **journal-data-access** — Documents the Riverpod provider architecture for journal data. Covers the three core providers (`journalControllerProvider`, `journalsControllerProvider`, `journalModeProvider`), `ref.watch` vs `ref.read` patterns, CRUD operations, create vs edit mode, and AsyncValue handling. Reference file includes full JournalState fields and the Postgres `journals` schema.
- **flutter-animation-testing** — Pitfalls and patterns for testing Flutter animations. Covers: (1) `animateTo` vs `animateBack` status corruption (`animateTo(0.0)` leaves `isCompleted=true`), (2) `pumpAndSettle` not advancing past `Future.delayed` timers, (3) `pumpAndSettle` exiting between chained async animations. Includes a checklist and explicit-pump patterns.
- **deploy** — The App Store Connect / TestFlight deploy flow (`./deploy.sh`), its one-time credential setup, and upload troubleshooting.
- **supabase-migration** — The transitional Firebase→Supabase runbook: the anonymous-account bridge, the credential-less session, the device-bound failure mode, the `migration/` scripts, and the order to delete it all in. Extracted from CLAUDE.md so it loads only when the migration is actually in play. **Delete at the Firestore freeze.**
