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

- **home/** - Main dashboard displaying journal entries, empty states, and add movie button
- **movie/** - Movie details display with data models and controllers
- **search_movie/** - Movie search functionality integrating with TMDB API
- **journal/** - Core journaling features including emotion selection, thoughts editor, scenes selector, and AI-generated questions
- **emotion/** - Emotion tracking and selection UI components
- **quesgen/** - AI question generation for movie reflection prompts
- **login/** - Authentication screens and flows
- **toast/** - Toast notification utilities

### Core Infrastructure

**lib/core/**
- `network/` - Dio HTTP clients for TMDB and question generation APIs
- `utils/` - Shared utility functions

**Root-level managers:**
- `firebase_manager.dart` - Firebase Authentication wrapper (Apple Sign-In, Google Sign-In)
- `firestore_manager.dart` - Firestore CRUD operations for journal entries
- `shared_preferences_manager.dart` - Local preferences storage
- `themes.dart` - App-wide theme definitions (light/dark mode)

### State Management

Uses **Riverpod** for state management:
- Providers are typically defined in feature-specific files (e.g., `movie_providers.dart`)
- Controllers use Riverpod notifiers for complex state logic
- Follow patterns: `Provider` for computed values, `StateProvider` for simple state, `FutureProvider` for async operations, `NotifierProvider` for complex state

### Data Flow

1. **Movie Search**: User searches → TMDB API (via `tmdb_dio_client.dart`) → Movie data models → Display results
2. **Journal Creation**: Select movie → Create journal entry → Add emotions/thoughts/scenes → Generate AI questions (via `quesgen_dio_client.dart`) → Save to Firestore
3. **Authentication**: Apple/Google Sign-In → Firebase Auth → Store user session → Sync journals by userId

## Key Dependencies

- **flutter_riverpod** (3.0.3) - State management
- **dio** (5.8.0) - HTTP client for API calls
- **firebase_core** (4.2.0) - Firebase initialization
- **firebase_auth** (6.1.1) - Authentication
- **cloud_firestore** (6.1.0) - Cloud database
- **google_sign_in** (7.2.0) - Google authentication
- **flutter_dotenv** (6.0.0) - Environment variables (API keys stored in `.env`)
- **skeletonizer** (2.0.1) - Loading state animations
- **google_fonts** (6.2.1) - Typography
- **jiffy** (6.4.3) - Date formatting
- **fluttertoast** (9.0.0) - Toast notifications
- **uuid** (4.5.1) - Unique ID generation

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
- **Primary Font**: AvenirNext (custom font, weights 100-800)
- Fallback to Google Fonts for additional needs

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
2. Organize into controllers, data, screens, widgets subdirectories
3. Define Riverpod providers for state management
4. Integrate with existing navigation in `HomeScreen`
5. Follow existing patterns from similar features (e.g., `journal/` or `movie/`)

### Working with TMDB API
- API client: `lib/core/network/tmdb_dio_client.dart`
- Environment variable required: TMDB API key in `.env`
- Movie data models in `lib/features/movie/data/`

### Modifying Journal Features
- Journal state managed by `JournalState` controller in `lib/features/journal/controllers/journal.dart`
- UI components: emotion selector, thoughts editor, scenes selector, questions bottom sheet
- Save to Firestore via `FirestoreManager`

### Linting
- Uses `flutter_lints`, `custom_lint`, and `riverpod_lint`
- Run `flutter analyze` to check for issues
- Lint configuration in `analysis_options.yaml`
