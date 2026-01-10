# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter movie journal application that allows users to search for movies, view movie details, and create journal entries with emotions, thoughts, and AI-generated questions about watched movies. The app integrates with The Movie Database (TMDB) API and uses Firebase for authentication and data storage.

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
  - `screens/` - HomeScreen with navigation
  - `widgets/` - JournalCard, JournalsList, EmptyPlaceholder, AddMovieButton

- **journal/** - Core journaling features with full workflow from movie selection to saving
  - `controllers/` - JournalState (single journal), JournalsState (list of journals)
  - `screens/` - Journaling (main editor), JournalContent (view saved journal), MoviePreview, ThoughtsEditor, CaptionEditor
  - `widgets/` - EmotionsSelector, EmotionsSelectorBottomSheet, ScenesSelector, ScenesSelectSheet, SceneCard, QuestionsBottomSheet, ThoughtsEditor, PosterPreviewModal, AiReferencesAccordion, JournalContentMoreMenu

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
    - **Quiet** (low energy, negative): Melancholic, Confused, Thought-provoking, Bittersweet, Powerless, Lonely

- **quesgen/** - AI question generation service for movie reflection prompts
  - `controller.dart` - Question generation logic
  - `provider.dart` - Riverpod provider
  - `api.dart` - API integration for AI-generated questions

- **login/** - Authentication screens and user creation flows
  - `screens/` - LoginScreen, CreateUserScreen

- **settings/** - User settings and account management
  - `screens/` - SettingsScreen (displays username, sign out, delete account options)

- **toast/** - Toast notification utilities
  - `custom_toast.dart` - Custom toast implementation using fluttertoast

### Core Infrastructure

**lib/core/**
- `network/` - Dio HTTP clients for external APIs
  - `tmdb_dio_client.dart` - The Movie Database API client
  - `quesgen_dio_client.dart` - AI question generation API client
- `utils/` - Shared utility functions
  - `color_utils.dart` - Color manipulation utilities

**lib/shared_widgets/**
- Reusable UI components used across features
- `confirmation_dialog.dart` - Generic confirmation dialog widget

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
- Follow patterns: `Provider` for computed values, `StateProvider` for simple state, `FutureProvider` for async operations, `NotifierProvider` for complex state

### Data Flow

1. **Movie Search**:
   - User searches → SearchMovieController → TMDB API (via `tmdb_dio_client.dart`) → BriefMovie models → Display results in MovieResultList
   - User selects movie → MovieDetailController → Fetch detailed movie data → Display in MoviePreview

2. **Journal Creation**:
   - Select movie → MoviePreview → Start journaling → Journaling screen
   - Select emotions (EmotionsSelectorBottomSheet) → Select scenes (ScenesSelectSheet) → Write thoughts (ThoughtsEditor)
   - Optionally generate AI questions (QuestionsBottomSheet via `quesgen_dio_client.dart`)
   - Add caption (CaptionEditor) → Save to Firestore (via `FirestoreManager`) with userId

3. **Journal Viewing**:
   - HomeScreen displays JournalsList → Fetch from Firestore by userId
   - Select journal → JournalContent screen → View emotions, thoughts, scenes, questions

4. **Authentication**:
   - LoginScreen → Apple/Google Sign-In → Firebase Auth → Store user session
   - CreateUserScreen for new users → Set username → Store in Firestore
   - Journals synced by userId field in Firestore documents

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

### Dev Dependencies
- **flutter_lints** (6.0.0) - Recommended linting rules
- **custom_lint** (0.8.0) - Custom lint rule framework
- **riverpod_lint** (3.0.3) - Riverpod-specific linting

## Environment Setup

The app requires a `.env` file in the root directory with:
- TMDB API key
- Question generation API endpoint and key
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
- Add journals: `addJournalToCollection(userId, journal)`

### Initialization
- Firebase initialized in `main.dart` before app runs
- Must call `Firebase.initializeApp()` with platform-specific options

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
  - `journaling.dart` - Main journal editor with emotion and scene selection
  - `journal_content.dart` - View saved journal with all details
  - `movie_preview.dart` - Movie poster and details preview before journaling
  - `thoughts.dart` - Dedicated thoughts editor screen
  - `caption_editor.dart` - Caption editing screen
- **Key widgets**:
  - `emotions_selector.dart` & `emotions_selector_bottom_sheet.dart` - Emotion selection UI
  - `scenes_selector.dart` & `scenes_select_sheet.dart` - Scene selection from movie images
  - `questions_bottom_sheet.dart` - AI-generated questions display
  - `poster_preview_modal.dart` - Full-size poster preview modal
  - `ai_references_accordion.dart` - Expandable AI references section
  - `journal_content_more_menu.dart` - More options menu for saved journals
- Save to Firestore via `FirestoreManager.addJournalToCollection(userId, journal)`

### Working with Emotions
- Emotion definitions in `lib/features/emotion/emotion.dart`
- **24 emotions** organized into 4 groups based on energy level (high/low) and valence (positive/negative):
  - **Uplifting** (high energy, positive): Joyful, Funny, Inspired, Mind-blown, Hopeful, Fulfilling
  - **Intense** (high energy, negative): Shocked, Angry, Terrified, Anxious, Overwhelmed, Disturbed
  - **Soothing** (low energy, positive): Heartwarming, Touched, Peaceful, Therapeutic, Nostalgic, Cozy
  - **Quiet** (low energy, negative): Melancholic, Confused, Thought-provoking, Bittersweet, Powerless, Lonely
- Each emotion has:
  - `id`: Unique identifier (camelCase string)
  - `name`: Display name (with proper capitalization)
  - `color`: Color value (Color object) - FADD9E for positive, FC8885 for negative
  - `group`: Group name (Uplifting, Intense, Soothing, or Quiet)
  - `energyLevel`: "high" or "low"
- Access emotions via `emotionList` map using `EmotionType` enum keys
- Users can select multiple emotions per journal entry

### Linting
- Uses `flutter_lints`, `custom_lint`, and `riverpod_lint`
- Run `flutter analyze` to check for issues
- Lint configuration in `analysis_options.yaml`
