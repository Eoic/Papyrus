# Technologies

This section describes the technology stack, architecture decisions, and deployment options for Papyrus.

## Technology Stack Overview

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.x (Dart 3.x) | Cross-platform UI |
| **Backend** | FastAPI (Python 3.9+) | REST API server |
| **Database** | PostgreSQL 14+ | Primary data store |
| **Caching** | Redis 6+ | Sessions, caching |
| **Storage** | Multiple backends | Book file storage |
| **Deployment** | Docker, Kubernetes | Container orchestration |

---

## Frontend: Flutter

### Why Flutter?

- **Single codebase** for Android, iOS, Web, Desktop, and e-ink devices
- **High performance** with native compilation
- **Rich widget library** with Material 3 support
- **Strong typing** with Dart language
- **Active community** and extensive packages

### Target Platforms

| Platform | SDK | Build Target |
|----------|-----|-------------|
| Android | Flutter SDK | APK/AAB |
| iOS | Flutter SDK + Xcode | IPA |
| Web | Flutter SDK | PWA |
| Windows | Flutter SDK + MSVC | EXE |
| macOS | Flutter SDK + Xcode | DMG |
| Linux | Flutter SDK + GTK | AppImage/Snap |
| E-ink | Android APK | Optimized build |

### Key Packages

```yaml
dependencies:
  # State Management
  provider: ^6.0.0          # ChangeNotifier pattern

  # Navigation
  go_router: ^12.0.0        # Declarative routing

  # Storage
  hive: ^2.2.0              # Local key-value store
  sqflite: ^2.3.0           # SQLite for mobile

  # E-book Rendering
  epub_view: ^3.0.0         # EPUB reader
  pdfx: ^2.4.0              # PDF viewer

  # Networking
  dio: ^5.3.0               # HTTP client
  connectivity_plus: ^5.0.0  # Network detection

  # UI Components
  flutter_slidable: ^3.0.0   # Swipe actions
  cached_network_image: ^3.3.0 # Image caching

  # Authentication
  firebase_auth: ^4.0.0     # Firebase auth
  google_sign_in: ^6.1.0    # Google OAuth
```

### Architecture: Clean Architecture

```
lib/
├── main.dart                    # App entry point
├── config/
│   ├── app_router.dart          # Route configuration
│   ├── themes.dart              # Theme definitions
│   └── constants.dart           # App constants
├── core/
│   ├── errors/                  # Error handling
│   ├── network/                 # API client
│   └── utils/                   # Utilities
├── data/
│   ├── datasources/             # Remote & local data
│   ├── models/                  # Data models (DTOs)
│   └── repositories/            # Repository implementations
├── domain/
│   ├── entities/                # Business entities
│   ├── repositories/            # Repository interfaces
│   └── usecases/                # Business logic
├── presentation/
│   ├── pages/                   # Screen widgets
│   ├── widgets/                 # Reusable components
│   ├── providers/               # State management
│   └── forms/                   # Form widgets
└── services/
    ├── storage/                 # Storage backends
    ├── sync/                    # Synchronization
    └── reader/                  # E-book rendering
```

### Offline-First Architecture

Papyrus uses an offline-first approach where all data is stored locally first, then synchronized with the server when online.

```mermaid
flowchart TB
    subgraph FlutterApp["Flutter App"]
        subgraph Presentation["Presentation Layer"]
            UI["UI Layer<br/>(Widgets)"]
        end

        subgraph Domain["Domain Layer"]
            UseCases["UseCases"]
        end

        subgraph Data["Data Layer"]
            Repository["Repository"]
        end

        UI --> UseCases --> Repository

        subgraph Storage["Storage"]
            Local["Local Storage<br/>(Hive/SQLite)"]
            Remote["Remote API<br/>(Optional)"]
            SyncQueue["Sync Queue<br/>(Pending Changes)"]
        end

        Repository --> Local
        Repository --> Remote
        Local --> SyncQueue
        Remote --> SyncQueue
    end
```

**Key Principles:**

1. All reads go to local storage first
2. Writes are saved locally immediately
3. Background sync pushes changes to server
4. Conflict resolution on sync
5. Works fully without internet

### E-ink Optimization

For e-ink devices, the app implements specific optimizations:

**E-ink Mode Features:**

- High contrast black/white color scheme
- Disabled or minimal animations
- Larger touch targets (minimum 48px)
- Reduced screen refresh operations
- Hardware page-turn button support
- Optimized font rendering for grayscale

**Detection and Configuration:**

- Automatic detection via device model (Boox, Kobo, etc.)
- Manual toggle in settings
- E-ink specific reading profile defaults
- Reduced refresh rate for battery efficiency

---

## Backend: FastAPI

### Why FastAPI?

- **High performance** with async support
- **Automatic API docs** via OpenAPI/Swagger
- **Type safety** with Pydantic models
- **Easy to deploy** with Docker
- **Python ecosystem** for OCR, ML features

### API Structure

```
server/
├── app/
│   ├── main.py              # FastAPI app
│   ├── config.py            # Settings
│   ├── database.py          # DB connection
│   ├── api/
│   │   ├── v1/
│   │   │   ├── auth.py      # Authentication
│   │   │   ├── books.py     # Book endpoints
│   │   │   ├── shelves.py   # Shelf endpoints
│   │   │   ├── sync.py      # Sync endpoints
│   │   │   └── ...
│   │   └── deps.py          # Dependencies
│   ├── models/              # SQLAlchemy models
│   ├── schemas/             # Pydantic schemas
│   ├── services/            # Business logic
│   └── utils/               # Utilities
├── tests/
├── alembic/                 # Migrations
├── Dockerfile
└── requirements.txt
```

### API Endpoints (Summary)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/v1/auth/register | Register account |
| POST | /api/v1/auth/login | Login |
| POST | /api/v1/auth/google | Google OAuth |
| GET | /api/v1/books | List books |
| POST | /api/v1/books | Create book |
| GET | /api/v1/books/{id} | Get book |
| PUT | /api/v1/books/{id} | Update book |
| DELETE | /api/v1/books/{id} | Delete book |
| POST | /api/v1/books/{id}/upload | Upload file |
| GET | /api/v1/shelves | List shelves |
| POST | /api/v1/sync | Sync changes |
| GET | /api/v1/sync/status | Sync status |

Full API specification: [`/design/api/swagger.yaml`](../design/api/swagger.yaml)

---

## Database: PostgreSQL

### Why PostgreSQL?

- **JSONB support** for flexible metadata
- **Full-text search** for book content
- **Reliability** and ACID compliance
- **Scalability** with read replicas
- **Rich ecosystem** of tools

### Configuration

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: papyrus
      POSTGRES_USER: papyrus
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
```

---

## Caching: Redis

### Use Cases

- **Session storage** - JWT token blacklist
- **Rate limiting** - API request throttling
- **Cache** - Frequently accessed data
- **Pub/Sub** - Real-time sync notifications

```yaml
# docker-compose.yml
services:
  redis:
    image: redis:6-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
```

---

## Storage Architecture

Papyrus uses a **split storage architecture** separating metadata from files:

- **Metadata Server**: Stores user data, book metadata, reading progress, annotations, sync state
- **File Storage Backends**: Store actual book files (user's choice)

This separation allows users to choose their preferred file storage while using a centralized (or self-hosted) metadata server for synchronization.

See [Server Architecture](server-architecture.md) for complete details.

### File Storage Backends

| Backend | Use Case | Configuration |
|---------|----------|--------------|
| **Local** | Default, single device | Device file system |
| **Google Drive** | Consumer cloud | OAuth 2.0 |
| **OneDrive** | Microsoft ecosystem | OAuth 2.0 |
| **Dropbox** | Cross-platform cloud | OAuth 2.0 |
| **WebDAV** | NAS, Nextcloud | Username/Password |
| **MinIO/S3** | Self-hosted S3-compatible | Access/Secret keys |
| **Papyrus Server** | Unified self-hosting | Same as metadata server |

### Storage Interface

```dart
abstract class StorageBackend {
  Future<void> connect();
  Future<void> disconnect();
  Future<String> uploadFile(String localPath, String remotePath);
  Future<String> downloadFile(String remotePath, String localPath);
  Future<void> deleteFile(String remotePath);
  Future<List<String>> listFiles(String path);
  Future<bool> fileExists(String path);
  Future<StorageInfo> getStorageInfo();
}
```

---

## Security

### Authentication

- **JWT tokens** for API authentication
- **Refresh token rotation** for security
- **OAuth 2.0** for Google sign-in
- **bcrypt/Argon2** for password hashing

### Encryption

- **TLS 1.3** for all network traffic
- **AES-256** for sensitive data at rest
- **Key derivation** using PBKDF2

### Privacy

- **No default analytics** - opt-in telemetry only
- **Data minimization** - collect only necessary data
- **Right to deletion** - complete data removal
- **Data export** - full user data portability

---

## Deployment

### Docker Compose (Development/Small Scale)

```yaml
# docker-compose.yml
version: "3.8"
services:
  api:
    build: ./server
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://papyrus:password@postgres/papyrus
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:14-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:6-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes (Production)

For production deployments with scaling requirements, Kubernetes manifests are provided with:

- Horizontal pod autoscaling
- Secrets management
- Persistent volume claims
- Ingress configuration
- Health checks

---

## Development Environment

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.x | Frontend development |
| Dart | 3.x | Flutter language |
| Python | 3.9+ | Backend development |
| Docker | 20+ | Container runtime |
| VS Code | Latest | Recommended IDE |

### Setup Commands

```bash
# Clone repository
git clone https://github.com/user/papyrus.git
cd papyrus

# Frontend setup
cd client
flutter pub get
flutter run

# Backend setup (in another terminal)
cd server
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# Or with Docker
docker-compose up -d
```

### Code Quality

```bash
# Frontend
dart analyze
dart format .
flutter test

# Backend
flake8 app/
black app/
pytest tests/
```

---

## Third-Party Services (Optional)

| Service | Purpose | Required |
|---------|---------|----------|
| Firebase Auth | Authentication | Optional |
| Google Books API | Metadata | Optional |
| Open Library API | Metadata | Optional |
| Sentry | Error tracking | Optional |
| Plausible | Privacy-friendly analytics | Optional |
