# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Papyrus is a cross-platform book management application with a Flutter client and Python FastAPI server. It supports reading and managing both physical and digital books across Android, iOS, Web, and Desktop platforms. Supported e-book formats: EPUB, PDF, MOBI, AZW3, TXT, CBR, CBZ.

## Repository Structure

```
Papyrus/
├── client/          # Flutter mobile/web/desktop app
├── server/          # Python FastAPI REST API
├── docs/            # Project documentation (MkDocs)
└── .github/         # CI/CD workflows
```

## Client (Flutter)

### Commands

Run from the `client/` directory:

```bash
# Install dependencies
flutter pub get

# Run the application
flutter run                    # Mobile (Android/iOS)
flutter run -d chrome          # Web
flutter run -d windows         # Desktop (also: macos, linux)

# Code quality
dart format .                  # Format code
dart analyze                   # Static analysis
dart fix --apply               # Auto-fix lint issues

# Run tests
flutter test
```

### Architecture (`client/lib/`)

- **`main.dart`** - Entry point; Firebase init, MultiProvider setup
- **`config/`** - GoRouter routing (`app_router.dart`)
- **`pages/`** - 20 full-screen views (auth, library, book management, goals, statistics, profile, settings, developer options)
- **`providers/`** - 13 ChangeNotifier providers (auth, library, book details/edit, shelves, goals, statistics, dashboard, annotations, bookmarks, notes, display mode, sidebar)
- **`widgets/`** - 100+ components in 23 feature subdirectories (auth, book, book_details, library, dashboard, shell, goals, statistics, etc.)
- **`models/`** - 16 data models (book, shelf, tag, annotation, bookmark, note, reading session/goal/streak, series, etc.)
- **`data/`** - DataStore (single source of truth ChangeNotifier) + SampleData for offline mode
- **`services/`** - Metadata extraction (`metadata_service.dart`, `file_metadata_service.dart`)
- **`forms/`** - Login and register form state/validation
- **`themes/`** - Material 3 themes (light/dark/e-ink) + design tokens (`design_tokens.dart`)
- **`utils/`** - Responsive layout, color/image utils, search query parser, navigation helpers

### Key Patterns

**State Management**: Provider with ChangeNotifier classes. DataStore in `data/data_store.dart` is the single source of truth, loaded with SampleData on startup for offline mode.

**Navigation**: GoRouter with nested shell routes:

- Bottom nav: Dashboard, Library, Goals, Statistics, Profile
- Library drawer: Books, Shelves, Topics, Bookmarks, Annotations, Notes
- Routes in `config/app_router.dart`

**Authentication**: Firebase Auth with Google Sign-In.

**Responsive Design**: `utils/responsive.dart` with breakpoints defined in `themes/design_tokens.dart` — mobile (<600), tablet (600-839), desktop (840+), large desktop (1200+). Grid columns, gutters, and margins adapt per breakpoint.

**Design Tokens**: `themes/design_tokens.dart` defines `Spacing`, `ComponentSizes`, `BorderWidths`, `IconSizes`, `AppRadius`, `AppElevation`, and `Breakpoints`.

**E-ink Mode**: Theme-based approach — `AppTheme.eink` handles grayscale colors; widgets use theme colors, not hardcoded values. No separate widget builds. 4 remaining e-ink-specific widgets for structurally different navigation components.

**Widgets**: Feature-based directory organization under `widgets/` (auth/, book/, library/, dashboard/, shell/, etc.). Reuse shared components from `widgets/shared/`.

### Tests

29 test files covering models, providers, widgets, services, and utils. Run with `flutter test` from `client/`.

## Server (Python/FastAPI)

### Commands

Run from the `server/` directory:

```bash
# Install dependencies
pip install -e ".[dev]"

# Run the server
uvicorn papyrus.main:app --reload

# Code quality
ruff format .                  # Format code
ruff check .                   # Lint code
mypy src/                      # Type checking

# Run tests
pytest                         # Run all tests
pytest --cov                   # Run with coverage
```

### Architecture (`server/src/papyrus/`)

- **`main.py`** - FastAPI app factory and configuration
- **`config.py`** - Settings management (pydantic-settings)
- **`api/`** - API layer
  - **`routes/`** - Route handlers (auth, books, shelves, tags, etc.)
  - **`deps.py`** - Dependency injection (auth, pagination)
- **`schemas/`** - Pydantic models for request/response validation
- **`core/`** - Core utilities (security, exceptions, database)
- **`services/`** - Business logic (placeholder)

### API Documentation

When the server is running:

- OpenAPI UI: <http://localhost:8000/docs>
- ReDoc: <http://localhost:8000/redoc>

## Development Setup

### Git Hooks (Lefthook)

Pre-commit and pre-push hooks run quality checks automatically:

```bash
# Install lefthook hooks
lefthook install
```

**Pre-commit** (runs in parallel):

- Client: `dart format`, `dart analyze`
- Server: `ruff format`, `ruff check`

**Pre-push** (runs in parallel):

- Client: `flutter test`
- Server: `mypy`, `pytest`

To skip hooks temporarily: `git commit --no-verify`

### CI/CD Workflows

**Client CI** (`.github/workflows/ci.yml`):

- Triggers on changes to `client/**`
- Runs format check, analysis, and tests

**Client Release** (`.github/workflows/release.yml`):

- Triggers on `v*` tags (e.g., `v1.0.0`)
- Builds Android, Web, Linux, Windows artifacts
- Creates GitHub Release

**Server CI** (`.github/workflows/server-ci.yml`):

- Triggers on changes to `server/**`
- Runs format, lint, type check, and tests with coverage

**Server Release** (`.github/workflows/server-release.yml`):

- Triggers on `server-v*` tags (e.g., `server-v1.0.0`)
- Runs quality checks and creates GitHub Release

### Creating Releases

```bash
# Client release
git tag v1.0.0
git push origin v1.0.0

# Server release (independent versioning)
git tag server-v1.0.0
git push origin server-v1.0.0
```

## UI Conventions

- **Sentence case** for all UI text (buttons, labels, headings)
- Examples: "Apply filters" (not "Apply Filters")
- Exception: Acronyms remain uppercase (PDF, EPUB)

## Visual App Exploration (Chrome MCP)

To visually explore the running Flutter web app using Chrome MCP (`mcp__claude-in-chrome__*`):

1. Start the web server: `flutter run -d web-server --web-port=8080` from `client/`
2. Navigate to `http://localhost:8080` using `mcp__claude-in-chrome__navigate`
3. Use `mcp__claude-in-chrome__computer` with `screenshot` action to capture current state
4. Use `left_click` with coordinates to interact with UI elements

**Notes:**

- Flutter web uses CanvasKit (canvas rendering) — Playwright MCP cannot interact with elements, but Chrome MCP `computer` tool works via coordinate-based clicks
- Click "Use offline mode" on the welcome page to bypass auth for local testing

## Project Resources

- **Documentation**: `docs/` directory, run `mkdocs serve` to browse locally
- **API Spec**: `docs/src/api/openapi.yaml` - OpenAPI specification
- **Design**: Figma prototype linked in README.md
