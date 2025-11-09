# BookSwap

Welcome to BookSwap — a simple Flutter app for swapping books with other users. This README explains what the app does, the main parts of the code, and how to run it on your machine.

## What is BookSwap?

BookSwap makes it easy for people to trade books. Users can create accounts, list books they want to swap, browse other people’s books, start swap requests, and chat with other users to arrange exchanges.

Key features
- User accounts (email/password)
- Book listings (add, edit, view)
- Chat between users to arrange swaps
- Swap request workflow (offer/accept/decline)
- Cloud storage for book images

## Architecture (simple)

BookSwap is organized by feature and responsibility. Here is an easy-to-read overview:

- Screens: UI pages the user navigates to (under `lib/screens/`). Examples: `main_screen.dart`, `home/*`, `auth/*`, `books/*`, `chat/*`, `settings/*`.
- Widgets: Reusable UI pieces (under `lib/widgets/`). Examples: `BookCard`, `ChatBubble`, `LoadingWidget`.
- Providers: State management using Riverpod (under `lib/providers/`). Providers expose and manage data (auth state, book lists, chats, swaps).
- Services: Backend helpers (under `lib/services/`). Examples: `firebase_service.dart` (auth + Firestore), `storage_service.dart` (image uploads).
- Models: Plain data classes used across the app (under `lib/models/`). Examples: `Book`, `User`, `Message`, `Swap`.

ASCII diagram

bookswap/
  lib/
    main.dart               # App entrypoint, Firebase initialization, dotenv loading

    screens/                # All UI screens
      auth/
        login_screen.dart
        register_screen.dart
        email_verification_screen.dart

      home/
        browse_listings_screen.dart
        my_listings_screen.dart
        chats_screen.dart

      main_screen.dart
      swap_requests_screen.dart
      add_edit_book_screen.dart
      chat_detail_screen.dart
      settings/
        settings_screen.dart

    models/
      user_model.dart
      book_model.dart
      swap_model.dart
      chat_model.dart

    providers/
      auth_provider.dart
      books_provider.dart
      swaps_provider.dart
      chat_provider.dart

    services/
      firebase_service.dart
      storage_service.dart

    widgets/
      book_card.dart
      chat_bubble.dart
      custom_button.dart

  .env                      # Environment variables (NOT committed)
  .env.example              # Template
  .gitignore
  pubspec.yaml
  README.md

android/
  app/
    google-services.json

Firebase Collections Structure:
  users/
    {userId}/
      id
      email
      name
      emailVerified
      createdAt

  books/
    {bookId}/
      id
      title
      author
      condition
      imageUrl
      ownerId
      ownerName
      isAvailable
      createdAt

  swaps/
    {swapId}/
      id
      bookId
      bookTitle
      requesterId
      requesterName
      ownerId
      ownerName
      status
      createdAt
      updatedAt

  chats/
    {swapId}/
      participants
      createdAt
      messages/
        {messageId}/
          id
          swapId
          senderId
          senderName
          text
          timestamp

Cloudinary Storage Structure:
  book_covers/
    {userId}/
      {timestamp}.jpg


This structure keeps UI, business logic, and backend helpers separated and easier to work on.

## Installation & setup

Prerequisites
- Flutter SDK (stable channel). See https://flutter.dev for install instructions.
- Git
- A Firebase project (for auth and Firestore)

Clone the repository

```bash
git clone https://github.com/PapiWinnie/BookSwap.git
cd BookSwap/bookswap
```

Install dependencies

```bash
flutter pub get
```

Run the app

To run on a connected Android device or emulator:

```bash
flutter run -d android
```

To run on iOS (macOS with Xcode):

```bash
flutter run -d ios
```

To run on web:

```bash
flutter run -d chrome
```

## Firebase setup (high level)

This project uses Firebase for authentication and Firestore for data storage. Follow these steps:

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Email/Password sign-in under Authentication > Sign-in method.
3. Create a Firestore database (start in test mode for development). Add the necessary collections like `books`, `users`, `chats`, `swaps` as your app creates them.
4. Add Android app in Firebase console:
   - Package name: (use the applicationId from `android/app/build.gradle.kts`)
   - Download `google-services.json` and put it into `android/app/`.
5. (iOS) Add an iOS app and download `GoogleService-Info.plist` into `ios/Runner/`.
6. If present, run `flutterfire configure` to generate `lib/firebase_options.dart` (this repo already contains `lib/firebase_options.dart` — check it and replace credentials if you created a new Firebase project).

Security note: Do not commit real service account keys or secrets. Keep them out of version control.

Optional: Cloudinary / image uploads

If the app uses a signed Cloudinary upload or another storage provider, set the relevant API keys according to the instructions in `lib/services/storage_service.dart`. The repo may expect environment variables or a local config — search the file for TODO or read the comments.

## Folder structure (quick)

- `lib/` — main app code
  - `screens/` — app pages and routes
  - `widgets/` — reusable UI components
  - `providers/` — Riverpod providers and state
  - `services/` — backend helpers (Firebase, uploads)
  - `models/` — simple data classes
  - `firebase_options.dart` — auto-generated Firebase config for this project
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` — platform code
- `test/` — unit/widget tests

## Running a build or analyzer

Run Flutter analyzer to catch issues:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Create a release build for Android:

```bash
flutter build apk --release
```

## Notes & troubleshooting

- If you get Firebase-related errors, confirm that `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present and match your Firebase project.
- If the app expects Cloudinary or other API keys, update `lib/services/storage_service.dart` or supply environment variables as documented in that file.
- If you change Flutter SDK versions, run `flutter pub get` again and consider `flutter pub upgrade`.


