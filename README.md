# Fink

A Flutter movie journal app for capturing how films make you feel. Search for movies, pick the emotions they evoked, select memorable scenes, write your thoughts, and save shareable movie tickets.

## Features

- **Movie Search** — Search TMDB's database and view detailed movie information
- **Emotion Journaling** — Choose from 24 curated emotions across 4 groups (Uplifting, Intense, Soothing, Quiet) to describe your experience
- **Scene Selection** — Pick memorable scenes from movie stills
- **Thoughts & Captions** — Write freeform reflections about the film. The caption editor auto-focuses the input on entry and keeps the keyboard attached as you swipe between scenes, so you can caption multiple scenes in a single pass.
- **AI-Curated Reviews** — Browse reviews from Letterboxd and Reddit to spark your own thoughts
- **Shareable Movie Tickets** — Generate flippable movie ticket images with high-res poster front and details back, peek hint animation on entry. Tap the ticket to flip, then use the bottom action row to save to gallery or open the share sheet (Instagram Stories, Threads, or native share). Close (X) in the top-right exits the flow straight to the journal's content page.
- **Poster Picker** — Choose ticket posters in multiple languages (Original, English, 繁體中文, 日本語)
- **Account Management** — Sign in with Apple or Google. Deleting your account performs a fresh re-authentication and then permanently removes all your journals and account data — no orphaned records left behind.

## Getting Started

### Prerequisites

- Flutter SDK `^3.7.2` 
- A [TMDB API](https://www.themoviedb.org/documentation/api) key
- Firebase project with Authentication and Firestore enabled
- Xcode (for iOS) / Android Studio (for Android)

### Setup

1. **Clone the repository**

   ```bash
   git clone <repo-url>
   cd movie_journal
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Create a `.env` file in the project root with your API keys:

   ```
   TMDB_API_KEY=your_tmdb_api_key
   QUESGEN_API_URL=your_review_api_url
   QUESGEN_API_KEY=your_review_api_key
   ```

4. **Set up Firebase**

   Follow the [FlutterFire setup guide](https://firebase.google.com/docs/flutter/setup) to generate `lib/firebase_options.dart` for your project.

5. **Run the app**

   ```bash
   flutter run
   ```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter |
| State Management | Riverpod 3.x |
| Backend | Firebase Auth + Cloud Firestore + Analytics |
| Networking | Dio |
| Movie Data | TMDB API |
| AI Reviews | Custom review generation API |

## Development

```bash
flutter analyze    # Static analysis
flutter test       # Run 235 tests
flutter build apk  # Android build
flutter build ios   # iOS build
```
