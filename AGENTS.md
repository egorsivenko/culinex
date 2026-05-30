# Repository Guidelines

## Project Structure & Module Organization

- `mobile/lib/` holds app code, grouped by `core/`, `features/`, `app/`, and `l10n/`.
- `mobile/test/` contains Flutter widget and unit tests.
- `mobile/assets/` stores icons and sounds declared in `mobile/pubspec.yaml`.
- `backend/cmd/` contains the API entry point.
- `backend/internal/` contains private backend packages for auth, handlers, DB, AI, Pexels, recipes, and responses.
- `backend/internal/db/migrations/` contains SQL migrations applied at startup.
- `docker-compose.yml` starts the local API and PostgreSQL stack.

## Build, Test, and Development Commands

- `docker compose up --build -d`: build and run the backend plus PostgreSQL.
- `cd backend && go run ./cmd`: run the API directly against a configured database.
- `cd backend && go test ./...`: run backend tests.
- `cd mobile && flutter pub get`: install Flutter dependencies.
- `cd mobile && flutter analyze`: run static analysis with Flutter lints.
- `cd mobile && flutter test`: run mobile unit and widget tests.
- `cd mobile && flutter gen-l10n`: regenerate localization output after editing ARB files.
- `cd mobile && flutter build apk`: build an Android APK.

## Coding Style & Naming Conventions

Format Go with `gofmt`; keep package names short, lowercase, and aligned with `backend/internal/*` domains.

Dart follows `package:flutter_lints/flutter.yaml`. Use two-space indentation, `lower_snake_case.dart` file names, `UpperCamelCase` classes/widgets, and `lowerCamelCase` members.

## Testing Guidelines

Add Flutter tests under `mobile/test/` with names ending in `_test.dart`. Prefer widget tests for screens and unit tests for controllers, stores, and API clients.

Add Go tests beside backend packages as `*_test.go` and run `go test ./...`. Cover handlers, auth, database behavior, and service edge cases when backend logic changes.

## Commit & Pull Request Guidelines

Recent commits use concise imperative summaries, for example `Add Docker setup for backend API service`. Keep subjects specific and under roughly 72 characters when practical.

Pull requests should include a short description, test results, linked issues, and screenshots or recordings for visible mobile UI changes. Note configuration, migration, or localization changes explicitly.

## Security & Configuration Tips

Do not commit real secrets. Start from `.env.example`, `backend/.env.example`, and `mobile/.env.example`. Backend JWT secrets must be at least 32 bytes. Use emulator-appropriate API URLs, such as `http://10.0.2.2:8080/api/` for Android emulators.
