<div align="center">
  <img width="300" src="/public/img/logo-dark.svg#gh-dark-mode-only" alt="Papyrus">
  <img width="300" src="/public/img/logo-light.svg#gh-light-mode-only" alt="Papyrus">

  <p><strong>A cross-platform book management application</strong></p>

  <p>
    <a href="https://eoic.github.io/Papyrus/"><img src="https://img.shields.io/badge/Documentation-blue?logo=gitbook&logoColor=white" alt="Documentation"/></a>
    <a href="https://codecov.io/gh/Eoic/Papyrus"><img src="https://codecov.io/gh/Eoic/Papyrus/branch/master/graph/badge.svg" alt="Coverage"/></a>
    <img src="https://img.shields.io/badge/License-AGPL--3.0-blue" alt="License"/>
  </p>
</div>

---

## Overview

Papyrus is an open-source, cross-platform application for managing and reading books. It supports both physical and digital book collections across Android, iOS, Web, Windows and Linux. The application features an integrated book reader, flexible organization tools, reading statistics, progress tracking, supports various file storage back-ends and cross-device synchronization via a self-hostable server.

<div align="center">
  <img src="/public/img/library.png" alt="Papyrus library view" />
</div>

### Why Papyrus?

Many reading applications offer partial solutions but fall short on essential features, platform availability or user experience. Papyrus aims to deliver a comprehensive, privacy oriented solution that:

- Works offline-first with optional cloud synchronization
- Supports self-hosting for complete data ownership
- Provides a unified experience across all popular platforms
- Offers extensive customization for different reading preferences

## Features

| Category | Features |
|----------|----------|
| **Reading** | Integrated viewer for EPUB, PDF, MOBI, AZW3, TXT, CBR, CBZ |
| **Organization** | Shelves, tags, topics, custom filters, advanced search |
| **Annotations** | Highlights, bookmarks, notes with export capabilities |
| **Progress** | Reading time tracking, page/percentage progress, statistics |
| **Goals** | Reading goals (books, pages, time) with streak tracking |
| **Sync** | Cross-device synchronization via self-hostable server |
| **Storage** | Multiple backends: Seff-hosted, Google Drive, WebDAV, MinIO, S3 |
| **Accessibility** | E-ink optimization, dark/light themes, customizable fonts |

## Supported platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Android | Supported | Primary mobile target |
| iOS | Supported | Requires Xcode for building |
| Web | Supported | PWA with offline support |
| Windows | Supported | Native desktop experience |
| macOS | Supported | Requires Xcode for building |
| Linux | Supported | AppImage/Snap distribution |

## Getting started

### Prerequisites

- **Flutter SDK 3.x**: [Installation guide](https://flutter.dev/docs/get-started/install)
- **Dart SDK 3.x**: Included with Flutter

### Installation

1. **Clone the repository**

   ```bash
   git clone git@github.com:Eoic/Papyrus.git
   cd Papyrus
   ```

2. **Install dependencies**

   ```bash
   cd client
   flutter pub get
   ```

3. **Run the application**

   ```bash
   # Android/iOS (with connected device or emulator)
   flutter run

   # Web
   flutter run -d chrome

   # Desktop
   flutter run -d windows    # or: macos, linux
   ```

## Documentation

Project documentation is available in the `/spec/` directory and can be built into a browsable static site using MkDocs.

```bash
# Install documentation dependencies
pip install -r docs-requirements.txt

# Serve documentation locally (http://127.0.0.1:8000)
mkdocs serve

# Build static site
mkdocs build
```

## Technology stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Flutter / Dart | Cross-platform UI |
| Backend | FastAPI / Python | REST API server |
| Database | PostgreSQL | Primary data store |
| Cache | Redis | Sessions, caching |
| Storage | Multiple backends | Book file storage |

## Contributing

### Setup

1. Fork and clone the repository
2. Install git hooks for code quality checks:

   ```bash
   ./scripts/setup-hooks.sh
   ```

   This installs a pre-commit hook that runs `dart format` and `dart analyze` before each commit.

### Development workflow

1. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and ensure quality checks pass:

   ```bash
   cd client
   dart format .
   dart analyze
   flutter test
   ```

3. Commit your changes and push:

   ```bash
   git commit -m "Add: description of your changes"
   git push origin feature/your-feature-name
   ```

4. Open a pull request

### Code style

- Run `dart format .` before committing
- Ensure `dart analyze` passes with no issues
- Use sentence case for UI text (e.g., "Apply filters" not "Apply Filters")

## Releases

Releases are automated via GitHub Actions. To create a new release:

1. Ensure all changes are merged to `master`
2. Create and push a version tag:

   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```

3. GitHub Actions will automatically:
   - Build all platforms (Android, Web, Linux, Windows)
   - Create a GitHub Release with auto-generated release notes
   - Attach versioned artifacts to the release

## Resources

| Resource | Description |
|----------|-------------|
| [Documentation]([https://karolis-1.gitbook.io/papyrus-project/](https://eoic.github.io/Papyrus/) | Full project specification |
| [API specification](docs/src/api/openapi.yaml) | OpenAPI |

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
