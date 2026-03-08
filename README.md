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
| **Storage** | Multiple backends: self-hosted, Google Drive, WebDAV, S3 |
| **Accessibility** | E-ink optimization, dark/light themes, customizable fonts |

## Supported platforms

- Android
- iOS
- macOS
- Linux
- Windows
- Web

## Getting started

### Prerequisites

- Flutter SDK 3.x: [Installation guide](https://flutter.dev/docs/get-started/install)

### Installation

1. **Clone the repository**

   ```bash
   git clone git@github.com:PapyrusReader/client.git
   cd client
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
   flutter run -d windows  # or: macos, linux
   ```

## Documentation

See [PapyrusReader/docs](https://github.com/PapyrusReader/docs).

## Technology stack

| Layer        | Technology         |
|--------------|--------------------|
| Frontend     | Flutter / Dart     |
| Backend      | FastAPI / Python   |
| Database     | PostgreSQL         |
| Cache        | Redis              |
| File storage | Multiple (e.g., Google Drive, S3, [OPFS](https://developer.mozilla.org/en-US/docs/Web/API/File_System_API/Origin_private_file_system), self-hosted)  |

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
   dart format .
   dart analyze
   flutter test
   ```

3. Commit your changes and push:

   ```bash
   git commit -m "feat: description of your changes"
   git push origin feature/your-feature-name
   ```

4. Open a pull request

## Resources

| Repository | Description |
|---|---|
| [server](https://github.com/PapyrusReader/server) | Back-end for self-hosted sync and file storage |
| [website](https://github.com/PapyrusReader/website) | Landing page |
| [docs](https://github.com/PapyrusReader/docs) | Documentation |
