# Culinex

Culinex helps you decide what to cook with the ingredients you already have. Take a photo of what is in your kitchen or type the ingredients manually, review the list, and get a clear single-serving recipe with steps, timing, ingredient amounts, and nutrition estimates.

The app also keeps your generated recipes organized, so you can favorite dishes, group them into collections, and come back to meals worth making again. Behind the scenes, Culinex combines a Flutter mobile app with a Go API, PostgreSQL storage, Gemini-powered recipe generation, and Pexels recipe imagery.

## Features

- Scan ingredients from a photo instead of typing everything by hand.
- Add or edit ingredients manually before generating a recipe.
- Generate one-person recipes with clear steps, cook time, difficulty, portions, and macro estimates.
- Choose a recipe style that fits the moment, from simple everyday meals to more creative ideas.
- Save generated recipes, mark favorites, and organize them into collections.
- Browse recipe images that make saved dishes easier to recognize later.
- Use the app in English or Ukrainian.
- Personalize the experience with light or dark mode, sound effects, and haptic feedback.
- Manage your account and recipe data directly from settings.

## Tech Stack

| Area        | Technology                                  |
| ----------- | ------------------------------------------- |
| Mobile      | Flutter, Dart, Material UI                  |
| Backend     | Go, chi router, pgx, golang-migrate         |
| Database    | PostgreSQL                                  |
| AI          | Google Gemini via `google.golang.org/genai` |
| Images      | Pexels API                                  |
| Local state | Shared preferences and secure storage       |
| Tooling     | Docker Compose, Flutter test, Go test       |

## Repository Layout

```text
.
|-- backend/                 # Go API service
|   |-- cmd/                 # API entry point
|   `-- internal/            # Auth, handlers, DB, AI, Pexels, recipes
|-- mobile/                  # Flutter application
|   |-- lib/                 # App code
|   |-- test/                # Widget and unit tests
|   |-- android/             # Android project
|   `-- ios/                 # iOS project
|-- docker-compose.yml       # Local Postgres and API stack
`-- README.md
```

## Architecture

```text
Flutter mobile app
  |-- Auth, camera capture, ingredient review, recipes, settings
  `-- JSON and multipart requests
        |
        v
Go API
  |-- PostgreSQL for users, sessions, recipes, and collections
  |-- Gemini for ingredient extraction and recipe generation
  `-- Pexels for recipe imagery
```

The Flutter app handles the user experience and stores lightweight preferences locally. The Go API owns authentication, recipe persistence, AI calls, image lookup, and database migrations. PostgreSQL stores user accounts, refresh sessions, saved recipes, favorites, and recipe collections.

## Prerequisites

- Flutter SDK compatible with Dart `^3.11.1`.
- Go `1.26.3`.
- Docker and Docker Compose.
- A PostgreSQL-compatible connection for local backend runs.
- API credentials for Google Gemini and Pexels.

## Quick Start

Create local environment files from the checked-in examples:

```bash
cp .env.example .env
cp backend/.env.example backend/.env
```

Fill in the Gemini and Pexels keys in `backend/.env`, then start the backend and database:

```bash
docker compose up --build -d
```

Run the mobile app:

```bash
cd mobile
flutter pub get
flutter run
```

Only create `mobile/.env` if you need to override the app's default API URL:

```bash
cp mobile/.env.example mobile/.env
```

## Configuration

The backend reads configuration from `backend/.env` when run locally or from the Compose `env_file` when started through Docker Compose. Start from [backend/.env.example](backend/.env.example).

```env
DATABASE_URL=postgres://culinex:culinex@postgres:5432/culinex?sslmode=disable
JWT_ACCESS_SECRET=change-this-access-secret-to-at-least-32-bytes
JWT_REFRESH_SECRET=change-this-refresh-secret-to-at-least-32-bytes
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=720h
JWT_ISSUER=culinex
GOOGLE_API_KEY=your-google-gemini-api-key
PEXELS_API_KEY=your-pexels-api-key
```

`GEMINI_API_KEY` can be used instead of `GOOGLE_API_KEY`; if both are set, the Google GenAI client uses `GOOGLE_API_KEY`.

Docker Compose also expects root-level Postgres variables, usually in `.env`. Start from [.env.example](.env.example).

```env
POSTGRES_DB=culinex
POSTGRES_USER=culinex
POSTGRES_PASSWORD=culinex
```

The mobile app can use `mobile/.env` to override the API base URL. Start from [mobile/.env.example](mobile/.env.example).

```env
CULINEX_API_BASE_URL=http://127.0.0.1:8080/api/
```

When no mobile override is provided, Android emulators use `http://10.0.2.2:8080/api/` and other platforms use `http://127.0.0.1:8080/api/`.

## Running Locally

Start the backend stack:

```bash
docker compose up --build -d
```

The API listens on port `8080`. Health endpoints are available at:

- `GET /health`
- `GET /ping`

Then run the Flutter app:

```bash
cd mobile
flutter pub get
flutter run
```

The backend applies embedded database migrations automatically during startup.

## Development Commands

Backend:

```bash
cd backend
go test ./...
go run ./cmd
```

Mobile:

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter gen-l10n
```

Build an Android APK:

```bash
cd mobile
flutter build apk
```

## API Overview

Public endpoints:

- `POST /api/auth/check-email`
- `POST /api/auth/signup`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`

Authenticated endpoints:

- `POST /api/extract-ingredients`
- `POST /api/generate-recipe`
- `GET /api/recipes`
- `GET /api/recipes/{id}`
- `PATCH /api/recipes/{id}/favorite`
- `PATCH /api/recipes/{id}/collection`
- `DELETE /api/recipes`
- `DELETE /api/recipes/{id}`
- `GET /api/recipe-collections`
- `POST /api/recipe-collections`
- `PATCH /api/recipe-collections/{id}`
- `DELETE /api/recipe-collections/{id}`
- `DELETE /api/account`

## Testing

Run the full backend test suite:

```bash
cd backend
go test ./...
```

Run Flutter analysis and tests:

```bash
cd mobile
flutter analyze
flutter test
```

The mobile tests cover authentication flows, API client auth behavior, recipe screens, ingredient review, saved recipes, session control, and smoke coverage for the app shell.

## Troubleshooting

If the API exits during startup, check that `backend/.env` exists and includes all required values. JWT secrets must be at least 32 bytes, and token TTLs must use Go duration strings such as `15m` or `720h`.

If the API cannot connect to PostgreSQL in Docker Compose, use the Compose service host in `DATABASE_URL`: `postgres://culinex:culinex@postgres:5432/culinex?sslmode=disable`. If you run `go run ./cmd` directly on the host machine, use `127.0.0.1` or `localhost` instead of `postgres`.

If the mobile app cannot reach the API, check `CULINEX_API_BASE_URL`. Android emulators should use `http://10.0.2.2:8080/api/`; iOS simulators, desktop targets, and web runs usually use `http://127.0.0.1:8080/api/`.

If ingredient extraction or recipe generation fails, verify that either `GOOGLE_API_KEY` or `GEMINI_API_KEY` is set for the backend and that the key has access to the Gemini API.

If recipe images are missing or the backend fails while initializing image search, verify `PEXELS_API_KEY` in `backend/.env`.

## License

This project is licensed under the terms in [LICENSE](LICENSE).
