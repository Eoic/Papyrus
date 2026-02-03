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

- **`main.dart`** - App entry point; initializes Firebase and sets up Provider
- **`config/`** - App configuration (routing via GoRouter)
- **`pages/`** - Full-screen views
- **`providers/`** - State management (ChangeNotifier pattern)
- **`widgets/`** - Reusable UI components
- **`forms/`** - Form widgets
- **`models/`** - Data models
- **`themes/`** - Color schemes (Material 3 light/dark)

### Key Patterns

**State Management**: Provider with ChangeNotifier classes.

**Navigation**: GoRouter with nested shell routes:
- Bottom nav: Dashboard, Library, Goals, Statistics, Profile
- Library drawer: Books, Shelves, Topics, Bookmarks, Annotations, Notes
- Routes in `config/app_router.dart`

**Authentication**: Firebase Auth with Google Sign-In.

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
- OpenAPI UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

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

## Project Resources

- **Documentation**: `docs/` directory, run `mkdocs serve` to browse locally
- **API Spec**: `docs/src/api/openapi.yaml` - OpenAPI specification
- **Design**: Figma prototype linked in README.md
