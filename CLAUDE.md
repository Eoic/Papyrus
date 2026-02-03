# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Papyrus is a cross-platform book management application built with Flutter. It supports reading and managing both physical and digital books across Android, iOS, Web, and Desktop platforms. Supported e-book formats: EPUB, PDF, MOBI, AZW3, TXT, CBR, CBZ.

## Common Commands

All commands should be run from the `client/` directory:

```bash
# Install dependencies
flutter pub get

# Run the application
flutter run                    # Mobile (Android/iOS with connected device/emulator)
flutter run -d chrome          # Web
flutter run -d windows         # Desktop (also: macos, linux)

# Code quality
dart analyze                   # Static analysis
dart fix --apply               # Auto-fix lint issues
dart format .                  # Format code

# Run tests
flutter test                   # Run all tests
flutter test test/path/to/test.dart  # Run single test file
```

## Architecture

### Directory Structure (`client/lib/`)

- **`main.dart`** - App entry point; initializes Firebase and sets up Provider
- **`config/`** - App configuration (routing via GoRouter)
- **`pages/`** - Full-screen views (14 pages: welcome, login, register, dashboard, library, books, shelves, topics, goals, statistics, profile, book_details, search_options, stub)
- **`providers/`** - State management classes (ChangeNotifier pattern)
- **`widgets/`** - Reusable UI components
- **`forms/`** - Form widgets (login, register)
- **`models/`** - Data models
- **`themes/`** - Color schemes (Material 3 light/dark)

### Key Patterns

**State Management**: Provider with ChangeNotifier classes. See `GoogleSignInProvider` for the authentication example.

**Navigation**: GoRouter with nested shell routes:
- Bottom nav bar: Dashboard, Library, Goals, Statistics, Profile
- Library drawer: Books, Shelves, Topics, Bookmarks, Annotations, Notes
- Routes defined in `config/app_router.dart`

**Authentication**: Firebase Auth with Google Sign-In. Auth state checked in router redirect - unauthenticated users are sent to welcome/login pages.

### Adding New Routes

1. Create page widget in `pages/`
2. Add route in `config/app_router.dart` within appropriate shell (bottom nav or library drawer)
3. Use named routes: `context.goNamed('ROUTE_NAME')` or `context.go('/path')`

## Documentation

The `/spec/` directory contains project documentation written in Markdown with Mermaid diagrams. Documentation can be built into a static site using MkDocs.

```bash
# Install documentation dependencies (one-time setup)
pip install -r docs-requirements.txt

# Serve documentation locally with live reload
mkdocs serve

# Build static site (outputs to /site/)
mkdocs build

# Deploy to GitHub Pages
mkdocs gh-deploy
```

Documentation is available at `http://127.0.0.1:8000` when running `mkdocs serve`.

## UI Conventions

### Text Casing

- **Sentence case** for all UI text including buttons, labels, headings, and section titles
- Examples: "Apply filters" (not "Apply Filters"), "Quick filters" (not "QUICK FILTERS" or "Quick Filters")
- Exception: Acronyms remain uppercase (e.g., "PDF", "EPUB")

## Development Setup

### Git Hooks

Pre-commit hooks run quality checks (formatting, analysis) before each commit. To install:

```bash
# Option 1: Simple shell script (recommended)
./scripts/setup-hooks.sh

# Option 2: Using lefthook (if installed)
lefthook install
```

The pre-commit hook runs:
- `dart format --set-exit-if-changed` - Formatting check
- `dart analyze --fatal-infos` - Static analysis

To skip hooks temporarily: `git commit --no-verify`

## Project Resources

- **Specification**: `/spec/` directory contains requirements, use cases, entities, database model
- **API Design**: `/design/api/swagger.yaml` - OpenAPI specification for planned backend
- **Design**: Figma prototype linked in README.md
- **Documentation Site**: Run `mkdocs serve` to browse documentation locally
