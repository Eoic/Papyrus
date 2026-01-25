<div align="center">
  <img width="300" src="/public/img/logo-dark.svg#gh-dark-mode-only" alt="Papyrus">
  <img width="300" src="/public/img/logo-light.svg#gh-light-mode-only" alt="Papyrus">

  <p><strong>A cross-platform book management application</strong></p>

  <p>
    <a href="https://eoic.github.io/Papyrus/"><img src="https://img.shields.io/badge/Documentation-blue?logo=gitbook&logoColor=white" alt="Documentation"/></a>
    <a href="https://trello.com/invite/b/681367b2ba91db4e40b0cfea/ATTI5156837607437467bd3d646f933528054D126F02/papyrus"><img src="https://img.shields.io/badge/Trello-Board-blue?logo=trello&logoColor=white" alt="Trello Board"/></a>
    <a href="https://www.figma.com/design/nnL41KQvrlVU4ecF8mtB07/Papyrus"><img src="https://img.shields.io/badge/Figma-Prototype-orange?logo=figma&logoColor=white" alt="Figma Prototype"/></a>
    <img src="https://img.shields.io/badge/License-AGPL--3.0-blue" alt="License"/>
  </p>
</div>

---

## Overview

Papyrus is an open-source, cross-platform application for managing and reading books. It supports both physical and digital book collections across Android, iOS, Web, Desktop, and e-ink devices. The application features an integrated e-book reader, flexible organization tools, progress tracking, various storage back-ends and cross-device synchronization via a self-hostable server.

### Why Papyrus?

Many reading applications offer partial solutions but fall short on essential features or user experience. Papyrus aims to deliver a comprehensive, privacy oriented solution that:

- Works offline-first with optional cloud sync
- Supports self-hosting for complete data ownership
- Provides a unified experience across all platforms
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
| **Storage** | Multiple backends: Local, Google Drive, WebDAV, MinIO, S3 |
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
| E-ink | Supported | Optimized UI for Boox, Kobo, etc. |

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

## Project structure

```
Papyrus/
├── client/                 # Flutter application
│   ├── lib/
│   │   ├── config/         # App configuration, routing
│   │   ├── pages/          # Screen widgets
│   │   ├── providers/      # State management
│   │   ├── widgets/        # Reusable components
│   │   ├── models/         # Data models
│   │   └── themes/         # Color schemes
│   └── test/               # Unit and widget tests
├── spec/                   # Project documentation (MkDocs)
├── design/
│   └── api/                # OpenAPI specification
└── public/                 # Static assets
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

**Documentation includes:**

- [Market Analysis](spec/market-analysis.md) - Competitive landscape
- [Functional Requirements](spec/requirements/functional-requirements.md) - System capabilities
- [Use Cases](spec/use-cases.md) - Detailed workflows
- [Database Model](spec/database-model.md) - Data architecture
- [Server Architecture](spec/server-architecture.md) - Backend design
- [Technologies](spec/technologies.md) - Tech stack details

## Technology stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Flutter / Dart | Cross-platform UI |
| Backend | FastAPI / Python | REST API server |
| Database | PostgreSQL | Primary data store |
| Cache | Redis | Sessions, caching |
| Storage | Multiple backends | Book file storage |

## Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Commit** your changes:

   ```bash
   git commit -m "Add: description of your changes"
   ```

4. **Push** to your branch:

   ```bash
   git push origin feature/your-feature-name
   ```

5. **Open** a pull request

Please ensure your code follows the existing style and includes appropriate tests.

## Resources

| Resource | Description |
|----------|-------------|
| [Documentation](https://karolis-1.gitbook.io/papyrus-project/) | Full project specification |
| [API Specification](design/api/swagger.yaml) | OpenAPI/Swagger definition |
| [Figma Prototype](https://www.figma.com/design/nnL41KQvrlVU4ecF8mtB07/Papyrus) | UI/UX design |
| [Trello Board](https://trello.com/invite/b/681367b2ba91db4e40b0cfea/ATTI5156837607437467bd3d646f933528054D126F02/papyrus) | Project management |

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
