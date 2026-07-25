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
    - `JournalCard`: long-press triggers iOS-style `CupertinoContextMenu` with Edit / Share / Delete actions, all delegating to `lib/features/journal/widgets/journal_actions.dart`. Tap navigation is gated on `animation.value == 0` to ignore taps during the context-menu zoom. The card is wrapped in a `ConstrainedBox(maxWidth: 200, maxHeight: 340)` to sidestep a `CupertinoContextMenu` layout assertion — do not remove. Visual spec: outer padding `fromLTRB(8, 8, 8, 12)`, 12px gap below poster, 8px gap between title and date, and the title+date pair gets an extra `EdgeInsets.symmetric(horizontal: 4)` inset. The padding values are pinned by `journal_card_test.dart`'s "layout spec" group — updating them requires updating the test AND `nonPosterHeight` in `journals_list.dart`.
    - `JournalsList`: grid uses a `LayoutBuilder` that computes `mainAxisExtent` from actual cell width, not `childAspectRatio`. If you change card padding / gap / text size / poster ratio, update `nonPosterHeight` and `posterAspectFactor` in `journals_list.dart` so cells stay tight. Current values: `nonPosterHeight = 70` (= 8 top pad + 12 image-title gap + 16 title (ceil of 14·1.1) + 8 title-date gap + 14 date (ceil of 12·1.1) + 12 bottom pad), `horizontalPaddingPerCard = 16` (= 8 × 2 sides). The value is intentionally tight — over-estimating leaves visible empty space below the date because `Flexible(fit: loose)` reserves the slot but the inner Column shrinks to its content.

- **journal/** - Core journaling features with full workflow from movie selection to saving
  - `controllers/` - JournalState (single journal), JournalsState (list of journals), JournalMode enum + JournalModeNotifier (create/edit mode)
  - `screens/` - Journaling (main editor), JournalComplete (post-save success screen), JournalContent (view saved journal), MoviePreview, ThoughtsEditor, CaptionEditor
  - `widgets/` - EmotionsSelectorButton, EmotionsSelectorBottomSheet, ScenesSelector, ScenesSelectSheet, SceneCard, ReviewItem, ReviewsBottomSheet, ThoughtsEditor, PosterPreviewModal, AiReferencesAccordion, JournalContentMoreMenu, and `journal_actions.dart` — a set of shared helper functions (`editJournal`, `shareJournal`, `confirmDeleteJournal`, `deleteJournal`) that encapsulate the domain actions a journal can undergo. Reused by both the more-menu on `JournalContent` and the long-press menu on `JournalCard`. The helpers own the *domain action* (load state / navigate to editor, confirm dialog, Supabase delete + toast, navigate to `TicketPosterPickerScreen`) but intentionally leave post-action navigation (e.g. popping after delete) to the caller, since that depends on which screen initiated the action.

- **movie/** - Movie data management with repository pattern
  - `controllers/` - MovieDetailController, MovieImagesController, SearchMovieController
  - `data/models/` - BriefMovie, DetailedMovie, MovieImage
  - `data/data_sources/` - MovieApi (TMDB integration)
  - `data/repositories/` - MovieRepository
  - `movie_providers.dart` - Riverpod providers for movie-related state

- **search_movie/** - Movie search interface integrating with TMDB API
  - `screens/` - SearchMovieScreen
  - `widgets/` - MovieSearchBar, MovieResultList
    - `MovieSearchBar`: **search-as-you-type** with a 300ms debounce (`_kSearchDebounce`). A `TextEditingController` *listener* (not `SearchBar.onChanged`) schedules the debounced `search()` — chosen so programmatic edits fire it too, notably the clear (X) button, which debounce-resets to popular. The listener also `setState`s so the trailing clear/search icon stays in sync (a `FocusNode` listener does the same for focus). Auto-fired searches are **not** logged to analytics; only explicit submit (keyboard "search" action / tap) logs via `logMovieSearched` and cancels any pending timer before searching immediately. `dispose()` cancels the timer, removes both listeners, and disposes the `FocusNode`. Each `search()` swaps the list for skeletons (`AsyncLoading`), so a too-short debounce flickers — 300ms avoids it; the deeper fix for flicker is preserving results during reload, not a longer delay. Behavior pinned by `movie_search_bar_test.dart`.

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
  - `screens/` - LoginScreen, CreateUserScreen (username input with validation: alphanumeric/underscore/dot only, uniqueness check via the `username_available` RPC, error toasts use `ToastGravity.TOP` to stay visible above the keyboard). `validateUsername()` is a top-level function for testability.

- **onboarding/** - Branded splash shown on cold start when the user is unauthenticated
  - `screens/` - BrandingSplashScreen — fade-in/hold/fade-out timeline (3s total) via a single `AnimationController` + `TweenSequence` (mirrors `journal_complete.dart`'s pattern). When the fade controller hits `completed`, calls `splashShownProvider.markShown()` so `HomeScreen` re-renders to `LoginScreen`. **No `Navigator.push`** — the splash plugs into `HomeScreen`'s stream-driven conditional at [home.dart:55](lib/features/home/screens/home.dart:55), gated by `splashShownProvider`.
  - `widgets/` - PosterMarquee (two rows, blurred via `ImageFiltered` + `ImageFilter.blur`, tilted ~-0.18 rad, positioned bottom-right with negative offsets so it spills off the edge); MarqueeRow (doubles the URL list and uses `Transform.translate` driven by a linear-repeating `AnimationController` so the wrap-around is invisible).
  - `controllers/` - `splashShownProvider` (session-scoped Riverpod `Notifier<bool>`, defaults to false; resets only on cold restart — **never invalidated on logout**, so signing out within a session goes straight to LoginScreen, no replay); `splashPostersProvider` (live TMDB `/movie/popular` via `MovieAPI().popularMovies()`, falls back to a small bundled poster URL list inside the provider's `catch` so widgets never see the error path). The splash pre-warms this fetch in `initState` via `ref.read(provider.future)` so posters likely arrive during fade-in; on late arrival, `AnimatedOpacity` fades them in gently.
  - **Asset**: `assets/images/fink_logo.svg` — the "i + ticket-stub" mark (92×105 viewBox); the "Fink" wordmark below it is rendered via `GoogleFonts.nothingYouCouldDo()` so we can tune size/color without touching the SVG.

- **account_link/** - Attaches an Apple/Google identity to a bridged user's anonymous session (issue #22). Inert for everyone else: `needsAccountLinkProvider` is false for every user who signed in through LoginScreen, so nothing here builds.
  - `controllers/account_link.dart` - `needsAccountLinkProvider` (derived from `authStateProvider`; true iff `user.isAnonymous` — see [The credential-less session](#the-credential-less-session)), `accountLinkPromptShownProvider` (session-scoped one-shot gate, mirrors `splashShownProvider`), and `AccountLinkService` behind `accountLinkServiceProvider` — a seam that exists purely so widget tests can fake the two link calls, including the conflict branch that would otherwise need two real provider accounts.
  - `widgets/` - `SecureAccountSheet` (dismissible modal, `show(context, journalCount:)`; renders the conflict explanation **inline** rather than as a dialog so the untried provider's button stays visible beside it), `SecureAccountBanner` (persistent, non-dismissible, self-clearing; also owns the one-time auto-prompt, scheduled to a post-frame callback because both flipping the Riverpod gate and pushing a route are illegal mid-build).

- **settings/** - User settings and account management
  - `screens/` - SettingsScreen (displays username, sign out, delete account options). Logout and delete flows invalidate journal/username providers to prevent stale data on re-login. When `needsAccountLinkProvider` is true it grows a warning-colored **Secure Account** item (the only entry point once the one-time prompt is gone) and the Logout dialog swaps in copy saying that getting back in depends on this device. Deliberately *not* "you will lose everything" — see [Logging out is recoverable](#logging-out-is-recoverable).

- **toast/** - Toast notification utilities
  - `custom_toast.dart` - Custom toast built on `fluttertoast`. Three static entry points — `showSuccess(context, msg)`, `showError(msg)`, `showWarning(msg)` — all render the same dark bordered card via a private `_show({icon, statusColor, message})`; only the icon glyph + accent vary. The icon is a filled circle in the status color with a **plain black** inner glyph. Colors come from `StatusColors` in `themes.dart` (success = primary `#A8DADD`, error `#FF615D`, warning `#FF9F1C`) — the single source of truth. `showSuccess` keeps a `context` param for call-site compatibility but no longer uses it for styling. Call `CustomToast.init(context)` once before showing (idiom: init immediately before the show call). Status→color mapping pinned by `custom_toast_test.dart`.

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
- `provider_sign_in_button.dart` - `ProviderSignInButton`, the outlined Apple/Google button. Extracted from `login.dart`'s private `_SignInButton` when `SecureAccountSheet` needed the same control: both flows ask for the same credential through the same native prompt, so they must look identical. Only the label differs ("Sign in with…" vs "Continue with…").

**Root-level managers:**
- `analytics_manager.dart` - Firebase Analytics wrapper (screen views, user ID, custom events). Also exports `ScreenViewTracker` widget for wrapping ConsumerWidget screens
- `supabase_auth_manager.dart` - Supabase Auth wrapper (native Apple/Google `signInWithIdToken`, sign-out, reauth, account deletion)
- `supabase_db_manager.dart` - Postgres CRUD for `profiles` / `journals`, and the snake_case ↔ camelCase translation layer
- `anonymous_bridge.dart` - one-shot migration bridge for pre-migration Firebase anonymous accounts (transitional; delete at the Firestore freeze)
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
- **Status colors**: `StatusColors` (in `themes.dart`) holds `success` (= primary `#A8DADD`), `error` (`#FF615D`), `warning` (`#FF9F1C`) as context-free constants — used as icon backgrounds (e.g. toasts), with a black inner glyph. They're constants rather than a `ThemeExtension` because consumers like `CustomToast.showError` run without a `BuildContext`.

### Loading States
- Use **Skeletonizer** package for skeleton screens
- Wrap loading content with `Skeletonizer.zone()`
- Use `Skeleton.leaf()` for individual loading elements

### Responsive Design
- Web builds are constrained to 400px width (mobile-like experience)
- Use `MediaQuery` for responsive breakpoints
- Support both mobile and web platforms

## Supabase Migration (in progress)

The data layer is migrating from Firebase (Firestore + Firebase Auth) to Supabase (Postgres + Supabase Auth). **Analytics stays on Firebase** — `firebase_core` and `firebase_analytics` are permanent, not transitional.

**Current state: call sites swapped; the app runs on Supabase.** `firebase_manager.dart` and `firestore_manager.dart` are deleted and `cloud_firestore` is out of `pubspec.yaml`. All data and auth go through `lib/supabase_auth_manager.dart` and `lib/supabase_db_manager.dart`.

**`firebase_auth` is still a dependency, and that is deliberate.** It survives only for the anonymous-account bridge (see below); it is not part of the data layer and should not be reached for in new code. It gets removed at the Firestore freeze.

The Phase 7 real-device sign-in test passed, the Phase 6 quesgen dual-token build is live on Cloud Run with `SUPABASE_URL` set, and anonymous sign-ins are enabled on the hosted Supabase project.

**But the cutover is NOT ready, and an earlier version of this file wrongly said it was.** What is verified is the bridge's **server half** — the staged-placeholder test drove the deployed Edge Function. Its **client half has never run successfully on a device**: does the Firebase anonymous session survive the update, and does `AnonymousBridge.attempt()` fire.

The first attempt (2026-07-25, an anonymous account created 2026-04-11 owning one journal) failed — login screen, Apple sign-in, CreateUserScreen, empty home — but **the install method invalidated the test**, so it is not evidence about the bridge either way. The new build was pushed with `flutter run --release` over a TestFlight install. Differing provenance makes that a *replace*, not an update, and iOS deletes an app's keychain items on removal, taking the Firebase session with them. See [The bridge is device-bound](#the-bridge-is-device-bound).

**Never use `flutter run` to test the migration path** — it destroys the one credential the path depends on, and does so silently. Use TestFlight, which preserves the container (same team `3U9565WWM2`, same bundle id `com.isaackwok.moviejournal`). Until one anonymous account has come through a real TestFlight update, the bridge's real-world success rate is unknown; do not force testers onto the build before then.

Also confirmed by that investigation: the Firebase auth export contains **zero `apple.com` identities** across all 26 users — the old app's population is 12 Google + 14 anonymous, and `firebase_identity_map` holds only `identity_map:google: 12`. So `claim_migrated_data()` is *dead code in practice*: it joins `auth.identities` against a map with no Apple rows, and the Google users it could serve are auto-linked by email before it ever runs. It is a fallback for a case that does not exist yet — do not rely on it as one.

**The app is TestFlight-only, which is what makes a hard cutover possible.** Expiring the old build in App Store Connect stops it launching and forces every tester onto the new one, collapsing the dual-write window from months to days. Two constraints: expire only *after* the new build is available to testers, and tell testers to **update in place rather than delete and reinstall** — deleting the app destroys the Firebase anonymous session the bridge depends on, which is the one failure mode that cannot be repaired afterwards.

### The anonymous-account bridge

14 pre-migration accounts were created by the old `signInAnonymously()` call (now removed) and own **54 journals — 46% of production data**. They have no email and no provider identity, so both normal linking paths structurally cannot find them: email auto-linking has nothing to match on, and `claim_migrated_data()` joins on `auth.identities`, which an anonymous user has none of.

`lib/anonymous_bridge.dart` trades the Firebase ID token still held on their device — unforgeable proof of that uid — for the pre-created placeholder row's data, via the `claim-anonymous` Edge Function. `hasProfileProvider`/`anonymousBridgeProvider` in `home.dart` run it once per app start before the login screen is offered.

Two ordering rules make it correct, and both are easy to break:
- The Edge Function re-points the profile **before** deleting the placeholder auth user. Deleting first would cascade the profile away, and the `AFTER DELETE` trigger would write a `kind='user'` tombstone — which the delta-sync reads as "deleted in the new app" and would then refuse to re-import that user's journals for the rest of the window.
- `claim_anonymous_data(text, uuid)` takes the firebase_uid as an *assertion*, so `EXECUTE` is granted to `service_role` **only**. Granting it to `authenticated` would let any user re-point anyone's journals to themselves. Pinned by `rls_smoke.sql`.

**Verified end-to-end against the live stack on 2026-07-25**, by staging a throwaway placeholder shaped exactly like the importer's and driving the deployed Edge Function through it: claim succeeds, journal and profile re-point to the claimant, `firebase_uid` survives, the placeholder auth user is deleted, **no tombstone is written** (confirming the ordering rule above), and a second call returns `already_claimed` without duplicating anything.

**Firebase's Anonymous provider is disabled on the project, and that is fine — do not re-enable it.** Disabling blocks `accounts:signUp`, but *not* the `securetoken` refresh path, so the 14 existing devices can still exchange their stored refresh tokens for the ID token the bridge needs (tested). Re-enabling would let old builds mint fresh anonymous accounts during the cutover window, creating new orphans. It also means the bridge can't be re-tested via `signInAnonymously()` — mint an anonymous-shaped token with the Admin SDK (`createUser({})` + `createCustomToken` + `signInWithCustomToken`) instead. `claim-anonymous` checks `iss`/`aud`/RS256/`sub` and never reads `firebase.sign_in_provider`, so such a token exercises the identical path.

- `supabase/migrations/` — versioned schema (`profiles`, `journals`, `sync_tombstones`, `firebase_identity_map`), RLS on every table, tombstone triggers, and the `username_available` / `claim_migrated_data` RPCs. `supabase/tests/rls_smoke.sql` holds 34 pgTAP assertions; run with `supabase test db`.
- `supabase/functions/delete-account/` — deletes the caller's account server-side. The `auth.users` delete cascades to profiles and journals, so unlike the old client-side flow there is no window where data is gone but the account remains.
- `migration/` — export/import/validate scripts for the delta-sync. Run `migration/sync.sh`. **All data and secrets live outside this repo** under `$MIGRATION_DATA_DIR`; this is a public repo and nothing there may leak into the tree.
- `migration/repair_anonymous_claim.ts` — by-hand equivalent of `claim_anonymous_data`, for a user the bridge could not reach: `node --env-file="$MIGRATION_DATA_DIR/.env" migration/repair_anonymous_claim.ts --firebase-uid <uid> --to <supabase user uuid>`. **Dry run unless `--confirm`.** Refuses to write if the target has no provider identity (repairing onto another credential-less session rebuilds the same problem), if the target already owns journals (it does not merge), if the target is itself a pre-created migration user, if the target profile carries a `firebase_uid` (deleting it would write a tombstone), or if a `kind='user'` tombstone already exists for the uid. Moves journals + profile in one transaction, verifies against the DB rather than trusting row counts, then deletes the placeholder auth user **after** the commit — the same ordering rule as the Edge Function, and the one step with no undo.
- `migration/bridge_status.ts` — read-only cutover monitor, run on demand: `node --env-file="$MIGRATION_DATA_DIR/.env" migration/bridge_status.ts`. Lists the anonymous cohort split into **claimed** (with the date the bridge fired) and **unclaimed** — the latter being the number that decides when the bridge can be deleted. Cohort membership is defined by a `firebase_uid` having **no row in `firebase_identity_map`** (anonymous Firebase accounts have no provider identity); do not key it off the importer's `app_metadata.anonymous` marker, which lives on the placeholder auth user and is deleted by a successful claim, so it can only ever see the unclaimed half. Exits non-zero on two real misconfigurations: a `kind='user'` tombstone against a still-live profile, and Firebase's Anonymous provider being re-enabled. Unclaimed placeholders alone are the expected mid-window state and never fail the run. Not wired into `sync.sh` — that runs under `set -e`, so a non-zero exit here would mark a successful sync as failed.

### The credential-less session

A successful claim leaves the user holding a Supabase **anonymous** session — `AnonymousBridge.attempt()` calls `signInAnonymously()` because a real `auth.users` row must exist before any journal can point at it. That session has no row in `auth.identities` and no credential, so a reinstall, a wipe, or a lost phone loses the account for good: the Firebase anonymous session that was the only proof of ownership goes with it, and the bridge cannot rescue the same user twice. This is the state 46% of production data lands in.

`lib/features/account_link/` fixes it by attaching a provider identity **to the current session**, via `SupabaseAuthManager.linkAppleIdentity()` / `linkGoogleIdentity()`.

- **Nobody else is affected.** `signInAnonymously()` appears exactly once in `lib/`, inside the bridge; LoginScreen offers only Apple and Google. So `needsIdentityLink` is false for every non-bridged user and none of this UI ever builds for them.
- **`linkIdentityWithIdToken`, never `linkIdentity()`.** The browser-OAuth variant shown in most Supabase docs needs an OAuth client secret this project deliberately never provisioned; probing it returns `"Unsupported provider: missing OAuth secret"`. The ID-token variant hits the same `/token?grant_type=id_token` endpoint as `signInWithIdToken` with `link_identity: true`, so it needs nothing new beyond **Allow manual linking** (Authentication → Sign In / Providers), enabled 2026-07-25. Turning that off breaks the flow with `manual_linking_disabled`, which is deliberately **not** classified as a conflict — it is a project misconfiguration hitting everyone, and reporting it as "your Apple account is taken" would be a lie.
- **`auth.uid()` does not change**, so journals stay put and nothing needs re-pointing. That is the entire appeal over a sign-in-and-migrate flow.
- **It self-heals.** Linking flips `is_anonymous` server-side and gotrue emits `userUpdated`, which flows through the existing `authStateChanges` stream into `needsAccountLinkProvider` — prompt and banner disappear with no invalidation anywhere.
- **The conflict case is reported, not resolved.** If the chosen Apple/Google account already belongs to a different Supabase user, linking fails with `identity_already_exists`; the sheet explains it and points at the other provider. A merge would need a server-side journal move plus a rule for which profile survives, and reaching this state requires having signed up separately during the window *and* still holding the old Firebase session. `account_link_conflict` is logged to size that population before anyone builds the merge.
- **Acceptance**: `claimed_still_on_anonymous_session` in `migration/bridge_status.ts` trends to zero. Do not delete the bridge until it does — the bridge is what recovers anyone who gets stranded.

#### The bridge is device-bound

`AnonymousBridge.attempt()` bails at [anonymous_bridge.dart:39](lib/anonymous_bridge.dart:39) when the device has no Firebase user or it is not anonymous. That token is the *only* proof of ownership an anonymous account has, so losing it — delete-and-reinstall, a wipe, a new phone — makes all three paths fail at once:

- **email auto-link** — the placeholder's email is `syntheticEmail()`, `fb-<uid>@anon.migrated.invalid`, matching nothing
- **`claim_migrated_data`** — joins `auth.identities`, which an anonymous user has none of
- **`claim-anonymous`** — needs the token that no longer exists

The user then signs in normally, gets a fresh Supabase user, and lands on CreateUserScreen. **Completing it is what makes the damage stick**: `claim_migrated_data()` and `claim_anonymous_data()` both short-circuit to `already_claimed` when the caller already has a profile, so from that point only `repair_anonymous_claim.ts` can fix it.

This is why "update in place, never delete and reinstall" is load-bearing rather than advisory. It was violated on the very first attempt, by someone who knew the rule — because the violation did not look like one: `flutter run --release` over a TestFlight install replaces the app rather than updating it (differing provenance), and iOS deletes keychain items on removal. No prompt, no deletion, session gone. Assume the rule will be broken again in some equally non-obvious way, and prefer detecting the loss over documenting the rule harder.

`AnonymousBridge` only `debugPrint`s, so a release build reports nothing about which branch it took. When diagnosing a stranded user, that absence of evidence is expected and is not itself a clue.

#### Logging out is recoverable

A bridged user cannot reach LoginScreen while holding their session — it is constructed in exactly one place ([home.dart:111](lib/features/home/screens/home.dart:111)) and only under `if (user == null)`. The single route there is Settings → Logout. And signing in with Apple from there creates a *new* user rather than linking, because `signInWithIdToken` resolves an identity to a user and ignores the current session; only `linkIdentityWithIdToken` attaches to it.

That sounds fatal and is not, which is why the logout copy must not claim it is:

- `claim_anonymous_data`'s `already_claimed` short-circuit keys on **the caller** already having a profile, so it only fires on a literal retry of the same call — not for a freshly minted anonymous user.
- The lookup keys on `firebase_uid`, which the RPC deliberately *retains* on the profile row when it re-points it (`update profiles set id = …` leaves `firebase_uid` intact).

So the next cold start after a logout re-runs the bridge, mints anonymous user #2, matches the profile by `firebase_uid`, moves journals and profile onto it, and returns `'claimed'`. The Edge Function then deletes the orphaned user #1 — cascading to nothing, and writing no tombstone, because the RPC moved its data away first. The user lands back in their account, still unlinked, so the banner reappears.

**The genuine loss condition is unchanged and predates all of this: losing the *Firebase* anonymous session** — reinstall, wipe, new phone. `SupabaseAuthManager.signOut()` clears only the Supabase session, so logout does not cause it.

### Timestamps — the bug being retired

Journals currently store `Jiffy.toString()`, a **naive local** string with no zone. Postgres stores `timestamptz`, so the boundary must convert both ways, and `SupabaseDbManager` is the only place that happens:

- **Write**: `jiffyToUtcIso()` → absolute UTC. Never `jiffy.toString()` — Postgres would read that as UTC and shift every timestamp by 8 hours.
- **Read**: `pgTimestampToLocalNaive()` → local wall time. `JournalState.fromJson` feeds the value straight into `Jiffy.parse`, so handing it a UTC instant would render every journal 8 hours early. Pinned by `test/supabase_db_manager_test.dart`.

Existing Firestore timestamps are interpreted as **Asia/Taipei** on import (hardcoded in `migration/lib/transform.ts`, deliberately not an env var).

`JournalState` stays untouched — `toMap()`/`fromJson()` remain the serialization seam, and all snake_case ↔ camelCase translation happens in the manager layer.

## Supabase Integration

### Authentication
- `SupabaseAuthManager` wraps all auth operations. Auth state via the `authStateChanges` stream (`onAuthStateChange` mapped to `Stream<User?>`).
- Apple and Google are **native-only** (`signInWithIdToken`): Supabase merely *verifies* a provider-signed token, so there is no client secret, no Apple Services ID, and no `.p8`. `kIsWeb` throws `UnsupportedError` deliberately — adding web later means adding all of that back.
- `reauthenticate()` returns `bool` (`false` = user backed out) rather than throwing, so screens never import `sign_in_with_apple` / `google_sign_in` just to recognise a cancellation. The classification itself lives in `_cancellable()`, shared with the link flows — it is the one place that knows `SignInWithAppleAuthorizationException` and `GoogleSignInException` both mean "dismissed".
- `linkAppleIdentity()` / `linkGoogleIdentity()` attach a provider identity to the **current** session and return `IdentityLinkOutcome` (`linked` / `cancelled` / `alreadyLinkedToAnotherAccount`) — an enum, not exceptions, because two of the three are ordinary user choices. Real faults still throw. Token acquisition is shared with the sign-in paths (`_appleIdToken()`, `_googleAccount()`) so the Apple *raw* nonce is bound identically on both; diverging there fails the nonce check on one path only. See [The credential-less session](#the-credential-less-session) for why this exists and why `linkIdentity()` can't be used.
- Google linking passes a best-effort `accessToken` from `authorizationForScopes`, which returns null instead of prompting when consent would be needed — linking must not turn into a second, unexplained permission dialog. GoTrue treats it as optional on the id_token grant (`signInWithGoogle` omits it entirely), so a null still links.
- `deleteAccount()` calls the `delete-account` Edge Function, then signs out locally — the server deletes the user but cannot clear this device's session.

### Data access
- `SupabaseDbManager` handles `profiles` / `journals` CRUD, mirroring the old `FirestoreManager` method-for-method.
- Ownership is enforced by RLS in the database; the `.eq('user_id', …)` filters are belt-and-braces, not the security boundary.
- Username availability goes through the `username_available` RPC, because RLS stops clients from scanning `profiles`. It compares **case-insensitively**, matching the `lower(username)` unique index.

### Initialization
- `main.dart` calls `WidgetsFlutterBinding.ensureInitialized()` **first** — `Supabase.initialize` persists sessions over platform channels and needs a live binding. Then dotenv, then `Firebase.initializeApp` (analytics), then `Supabase.initialize`.
- `.env` supplies `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`. The publishable key is meant to ship in the binary; the **secret** key must never appear in this repo (it lives in `$MIGRATION_DATA_DIR/.env`).

## Firebase Integration

> Analytics only, plus the transitional anonymous bridge. Auth and data moved to Supabase — see above.

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
- **Riverpod 3 auto-disposes by default, which makes async provider tests *hang* rather than fail.** `container.read(someStreamOrFutureProvider.future)` with nothing listening creates the element and tears it down in the same microtask, so the future never completes and the test sits until the 30s timeout — with a secondary `Bad state: … was disposed during loading state, yet no value could be emitted`. Attach `container.listen(provider, (_, _) {})` first (see `account_link_test.dart`'s `_containerFor`). Widgets never hit this because watching keeps the element alive. Five such tests turn a 12-second suite into a 20-minute one that looks like a slow compile.
- **A visible toast blocks taps underneath it.** `fluttertoast` inserts an overlay entry over the whole screen, so a `tester.tap()` after an error/success toast can miss its target ("derived an Offset that would not hit test on the specified widget"). Drain the toast with `pump(3s)` + `pumpAndSettle()` *before* the next tap, not just before the test ends.

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
- **Mode provider**: `journalModeProvider` (`JournalMode.create` / `edit`) — widgets like `ThoughtsScreen` read it to hide edit-inappropriate UI (sticky-bottom Reviews bar, "Add" card; review taps become no-ops in edit mode).
- **Create flow**: `JournalController.save()` → captures `JournalState` → `pushAndRemoveUntil` to `JournalCompleteScreen` (keeps Home) → "View Journal" `pushReplacement` to `JournalContent`.
- **Edit flow**: `JournalController.loadJournal()` → `JournalingScreen(editJournalId)` → `JournalController.update()` (row UPDATE, preserves `created_at`) → `popUntil(isFirst)`.
- **Caption editor focus management**: `caption_editor.dart` owns `_captionFocusNodes` keyed by scene path. A `postFrameCallback` in `initState` focuses the initial scene's `TextField`; `_onPageChanged` re-focuses on every swipe so the keyboard stays up as the user captions multiple scenes.
- **Journal actions**: `lib/features/journal/widgets/journal_actions.dart` holds `editJournal` / `shareJournal` / `confirmDeleteJournal` / `deleteJournal`. Reused by both `JournalContent`'s more-menu and `JournalCard`'s context menu. Helpers own the domain action but leave post-action navigation to the caller.
- **`ReviewItem`** has four visual states via `showAction` / `isSelected` / `transparent` props — used in reviews bottom sheet (add/selected), AI references accordion (transparent, no action), etc.
- **Selection-limit UX (scenes & emotions share one pattern)**: both `ScenesSelectSheet` (cap `_maxSceneLimit = 10`) and `EmotionsSelectorBottomSheet` (`maxSelectionLimit = 3`) show the same limit text — `'Select up to N (M/N)'`, styled `AvenirNext / 14 / w500 / height 1.5 / Colors.white.withAlpha(153)`, no color change at the cap. In `ScenesSelectSheet` this count is a **fixed header** above an `Expanded(SingleChildScrollView(GridView))` so it stays visible while the grid scrolls (don't move it back inside the scroll view). Tapping an *unselected* item while already at the cap is blocked **and** shows `CustomToast.showError('You can select up to N scenes/emotions')` (preceded by `CustomToast.init(context)`, per the `journal_actions.dart` idiom); deselect/re-select stay silent. **Testing gotcha**: the toast spawns chained `fluttertoast` timers (≈2s show + fade), so any widget test that triggers an over-cap tap must drain them with `await tester.pump(const Duration(seconds: 3)); await tester.pumpAndSettle();` or it fails with "Timer still pending" (see `scenes_select_sheet_test.dart` / `emotions_selector_bottom_sheet_test.dart`).

### Working with Share Ticket
Feature lives under `lib/features/share/`. Flow: callers → `TicketPosterPickerScreen` → `ShareTicketScreen`.

- **`ShareTicketEntry` enum** (`journalContent` / `journalComplete`): identifies which screen opened the flow so the close button can route back correctly. Both `TicketPosterPickerScreen` and `ShareTicketScreen` close via the shared `closeShareFlow(context, entry)` helper in `share_ticket_screen.dart`:
  - `journalComplete` (just-saved journal) → `popUntil(isFirst)` → back to Home (skipping the celebration screen).
  - `journalContent` (sharing existing journal) → `popUntil((r) => r.settings.name != kShareFlowRouteName)` → back to JournalContent.
- **`kShareFlowRouteName` route tagging**: every push into the share flow sets `MaterialPageRoute(settings: const RouteSettings(name: kShareFlowRouteName), …)`. The `journalContent` close path uses this to pop until it leaves the flow — robust if intermediate screens are added/removed. **If you add a new screen inside the share flow, tag its route or close-back will overshoot.** Currently tagged at: `journal_complete.dart`, `journal_content.dart`, `journal_actions.dart`, and the in-flow push in `ticket_poster_picker_screen.dart`.
- **`TicketPosterPickerScreen`** has no Next button and no default-selected poster; tapping a poster pushes `ShareTicketScreen` immediately with that poster path. The AppBar carries only a close (X) action that calls `closeShareFlow`.
- **`JournalCompleteScreen`** has its own close (X) in the top-right (a `Stack` overlay, not an AppBar, so the centered animation layout is not shifted). It does *not* call `closeShareFlow` — this screen isn't part of the share flow — but it pops to the same destination as the `journalComplete` close (`Navigator.popUntil((r) => r.isFirst)` → Home), since this screen only ever appears for a just-saved journal.
- **Ticket number**: `_computeTicketNumber()` = journal's chronological 1-based position. Sorts all journals by `createdAt` asc, finds current journal's index, returns `index + 1`.
- **Poster picker language tabs**: after the movie detail loads, `_applyLanguageTabFilter()` drops any fixed-language tab whose base code matches the movie's `originalLanguage` to avoid duplicates (e.g. an English movie hides the "English" tab). 繁體中文 uses `zh-TW`.
- **FlippableTicket peek animation**: `hintOnMount: true` triggers a 500ms-delayed peek (0 → 0.30 → 0) on mount. **Must use `animateBack(0.0)` for the return, not `animateTo(0.0)`** — `animateTo` leaves controller status as `completed`, which breaks `_flip()`'s `isCompleted` check. See the `flutter-animation-testing` skill for related pitfalls.
- **Image capture**: `_captureTicketAsBytes()` → PNG `Uint8List` from `RepaintBoundary`; `_captureTicketToFile()` writes it to a temp file. All save/share paths route through these two helpers.
- **"Copy Text" tap target**: the copy-thoughts-to-clipboard control is a `GestureDetector` with `behavior: HitTestBehavior.opaque` (so the whole row width is tappable, not just the centered icon+text glyphs — the default `deferToChild` ignores the empty space) wrapping a `Padding(vertical: 8)` to enlarge the vertical hit area to match the visible button.
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
    │       └── journal-state-model.md  # JournalState fields and Postgres schema
    └── flutter-animation-testing/
        └── SKILL.md                 # Animation test pitfalls and patterns
```

### Hooks
- **pre-commit-test.sh** — A `PreToolUse` hook on the `Bash` tool that intercepts `git commit` commands. Runs `flutter test` before allowing the commit. If tests fail, the commit is blocked with test output shown as the reason. Non-commit Bash commands pass through unaffected.
- **stop-update-claude-md.sh** — A `Stop` hook that nudges doc updates only for **significant, doc-worthy** code changes (not every edit — padding the docs for trivial fixes breeds rot). It scopes to `lib/**/*.dart` (excluding `*.g.dart` and `firebase_options.dart`; test-only and config changes never trigger it) plus `pubspec.yaml`. A change is "significant" if it adds a new `lib/` Dart file, touches ≥ `DOC_HOOK_MIN_LINES` lines (default 80, tunable via env var), or changes a dependency in `pubspec.yaml`. The two docs are required independently by relevance: **CLAUDE.md** (architecture/internals) is required for any significant change; **README.md** (user-facing) is required *only* when a brand-new feature directory appears under `lib/features/` or `pubspec.yaml` changes. Internal tweaks to existing screens/widgets never demand a README edit. When a required doc is missing the hook blocks (exit 2) and lists the relevant files; otherwise it passes (exit 0).
- **stop-sync-tests.sh** — A `Stop` hook that ensures unit tests stay in sync with source code. When `.dart` files under `lib/` are modified, it checks if the corresponding test file (`test/` mirror with `_test.dart` suffix) was also modified. If a source file has an existing test that wasn't updated, the hook blocks (exit 2) and lists the stale source→test pairs. Source files without existing tests are mentioned as an FYI but don't block on their own. Once the stale tests are updated, the hook passes (exit 0).
- Hooks are registered in `settings.local.json` under the `hooks.PreToolUse` and `hooks.Stop` keys (gitignored, local to each developer)

### Skills
- **journal-data-access** — Documents the Riverpod provider architecture for journal data. Covers the three core providers (`journalControllerProvider`, `journalsControllerProvider`, `journalModeProvider`), `ref.watch` vs `ref.read` patterns, CRUD operations, create vs edit mode, and AsyncValue handling. Reference file includes full JournalState fields and the Postgres `journals` schema.
- **flutter-animation-testing** — Pitfalls and patterns for testing Flutter animations. Covers: (1) `animateTo` vs `animateBack` status corruption (`animateTo(0.0)` leaves `isCompleted=true`), (2) `pumpAndSettle` not advancing past `Future.delayed` timers, (3) `pumpAndSettle` exiting between chained async animations. Includes a checklist and explicit-pump patterns.
