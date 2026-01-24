# Server Architecture

This document describes the server-side architecture for Papyrus, including the self-hostable Papyrus Server, file storage backends, and synchronization mechanisms that enable cross-device functionality.

## Architecture Overview

Papyrus uses a **flexible storage architecture** with a central server for metadata and user-chosen file storage:

```mermaid
flowchart TB
    subgraph Clients["Papyrus Clients"]
        Android["Android"]
        iOS["iOS"]
        Web["Web"]
        Desktop["Desktop"]
        Eink["E-ink"]
    end

    subgraph Server["Papyrus Server (Self-Hostable)"]
        subgraph Metadata["Metadata Storage (Always)"]
            M1["User accounts"]
            M2["Book metadata"]
            M3["Reading progress"]
            M4["Annotations & bookmarks"]
            M5["Shelves, tags, series"]
            M6["Reading goals"]
            M7["Sync coordination"]
        end
        subgraph FileStorage["File Storage (Optional)"]
            F1["Book files (EPUB, PDF)"]
            F2["Cover images"]
        end
    end

    subgraph AltStorage["Alternative File Storage"]
        G["Google Drive"]
        O["OneDrive"]
        D["Dropbox"]
        W["WebDAV (Nextcloud)"]
        S3["MinIO / S3"]
        L["Local device only"]
    end

    Android --> Server
    iOS --> Server
    Web --> Server
    Desktop --> Server
    Eink --> Server

    Server -.->|"OR (user's choice)"| AltStorage
```

### Key Principles

1. **Unified Server**: The Papyrus Server handles metadata (always) and can also handle files (optionally)
2. **User Choice**: Users select their preferred file storage—either the Papyrus Server or external providers
3. **Self-Hostable**: The server can be self-hosted for complete data ownership
4. **Offline-First**: Clients work fully offline, syncing when connected
5. **Data Portability**: All data can be exported and migrated

---

## Papyrus Server

The Papyrus Server is the central, self-hostable backend for cross-device synchronization. It always handles metadata storage and can optionally serve as the file storage backend.

### Responsibilities

**Metadata (Always):**

| Component | Description |
|-----------|-------------|
| **User Management** | Account registration, authentication, sessions |
| **Book Metadata** | Title, author, ISBN, description, cover URLs |
| **Library Organization** | Shelves, tags, series, custom fields |
| **Reading Progress** | Current position, completion status, time tracking |
| **Annotations** | Highlights, notes, bookmarks |
| **Goals** | Reading goals and progress tracking |
| **Sync Coordination** | Change tracking, conflict resolution |
| **File References** | Pointers to files in storage backends |

**File Storage (Optional—when server is chosen as file backend):**

| Component | Description |
|-----------|-------------|
| **Book Files** | EPUB, PDF, MOBI, and other e-book formats |
| **Cover Images** | Book cover artwork |
| **File API** | Upload, download, and delete operations |
| **Storage Management** | Quota tracking, cleanup |

### Data Model

```mermaid
flowchart TB
    subgraph PapyrusServer["Papyrus Server"]
        User["User"]
        Book["Book"]
        Shelf["Shelf"]
        Tag["Tag"]
        Annotation["Annotation"]
        Bookmark["Bookmark"]
        Note["Note"]
        Progress["Progress"]
        Goal["Goal"]
        Series["Series"]
        FileRef["FileRef"]
    end

    User --> Book
    Book --> Shelf
    User --> Tag
    Book --> Annotation
    Book --> Bookmark
    Book --> Note
    Book --> Progress
    User --> Goal
    Book --> Series
    Book --> FileRef

    FileRef -.->|"Points to storage"| Storage[("Storage Backend")]
```

### API Endpoints

The Papyrus Server exposes a RESTful API:

| Category | Endpoints | Description |
|----------|-----------|-------------|
| **Auth** | `/api/v1/auth/*` | Register, login, OAuth, refresh tokens |
| **Users** | `/api/v1/users/*` | Profile, preferences, account deletion |
| **Books** | `/api/v1/books/*` | CRUD operations, metadata, cover images |
| **Shelves** | `/api/v1/shelves/*` | Create, update, organize books |
| **Tags** | `/api/v1/tags/*` | Tag management |
| **Series** | `/api/v1/series/*` | Series management and ordering |
| **Annotations** | `/api/v1/annotations/*` | Highlights, notes, bookmarks |
| **Progress** | `/api/v1/progress/*` | Reading position, sessions, statistics |
| **Goals** | `/api/v1/goals/*` | Goal creation and tracking |
| **Sync** | `/api/v1/sync/*` | Change synchronization |
| **Storage** | `/api/v1/storage/*` | Backend configuration |
| **Files** | `/api/v1/files/*` | File upload/download (when server is file backend) |

Full API specification: [`/design/api/swagger.yaml`](../design/api/swagger.yaml)

### Self-Hosting

The Papyrus Server is designed for easy self-hosting:

**Minimum Requirements:**

- 1 CPU core
- 512MB RAM
- 1GB storage for metadata (scales with library size)
- Additional storage for files (if using server as file backend)
- PostgreSQL 14+ or SQLite
- Docker (recommended) or Python 3.9+

**Deployment Options:**

```yaml
# docker-compose.yml (minimal)
version: "3.8"
services:
  papyrus-server:
    image: papyrus/server:latest
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=sqlite:///data/papyrus.db
      - SECRET_KEY=${SECRET_KEY}
    volumes:
      - papyrus_data:/data

volumes:
  papyrus_data:
```

```yaml
# docker-compose.yml (production)
version: "3.8"
services:
  papyrus-server:
    image: papyrus/server:latest
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://papyrus:${DB_PASSWORD}@postgres/papyrus
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: papyrus
      POSTGRES_USER: papyrus
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Hosted Option

For users who don't want to self-host, an official hosted service may be provided:

| Tier | Features | Metadata | File Storage |
|------|----------|----------|--------------|
| **Free** | Basic sync, 1 device | 100 books | Not included (use external) |
| **Personal** | Full sync, 5 devices | Unlimited | 5 GB included |
| **Family** | 6 accounts, sharing | Unlimited | 25 GB shared |

*Note: Users can always use external file storage (Google Drive, etc.) with any tier.*

---

## File Storage Backends

Users configure file storage backends in the application settings. Multiple backends can be configured, with one designated as primary.

### Supported Backends

#### 1. Local Storage (Default)

Files stored only on the device. No sync capability.

| Property | Value |
|----------|-------|
| **Use Case** | Offline-only, single device |
| **Sync** | None |
| **Setup** | None required |
| **Capacity** | Device storage |

#### 2. Google Drive

Files stored in user's Google Drive account.

| Property | Value |
|----------|-------|
| **Use Case** | Consumer users, existing Google users |
| **Sync** | Automatic via Google |
| **Setup** | OAuth 2.0 authorization |
| **Capacity** | User's Google storage quota |

**Configuration:**

```
Storage Type: Google Drive
Folder: /Papyrus/Books (customizable)
Auth: OAuth 2.0 (sign in with Google)
```

#### 3. OneDrive

Files stored in user's Microsoft OneDrive account.

| Property | Value |
|----------|-------|
| **Use Case** | Microsoft ecosystem users |
| **Sync** | Automatic via OneDrive |
| **Setup** | OAuth 2.0 authorization |
| **Capacity** | User's OneDrive storage quota |

**Configuration:**

```
Storage Type: OneDrive
Folder: /Apps/Papyrus (customizable)
Auth: OAuth 2.0 (sign in with Microsoft)
```

#### 4. Dropbox

Files stored in user's Dropbox account.

| Property | Value |
|----------|-------|
| **Use Case** | Dropbox users, cross-platform |
| **Sync** | Automatic via Dropbox |
| **Setup** | OAuth 2.0 authorization |
| **Capacity** | User's Dropbox storage quota |

**Configuration:**

```
Storage Type: Dropbox
Folder: /Apps/Papyrus (customizable)
Auth: OAuth 2.0 (sign in with Dropbox)
```

#### 5. WebDAV

Files stored on any WebDAV-compatible server (Nextcloud, ownCloud, etc.).

| Property | Value |
|----------|-------|
| **Use Case** | Self-hosters, NAS users |
| **Sync** | Via WebDAV server |
| **Setup** | Server URL + credentials |
| **Capacity** | Server storage |

**Configuration:**

```
Storage Type: WebDAV
Server URL: https://nextcloud.example.com/remote.php/dav/files/user/
Folder: /Papyrus/Books
Username: user
Password: ********
```

#### 6. MinIO / S3-Compatible

Files stored in MinIO, AWS S3, or any S3-compatible storage.

| Property | Value |
|----------|-------|
| **Use Case** | Self-hosters, enterprise, developers |
| **Sync** | Via S3 API |
| **Setup** | Endpoint + access keys |
| **Capacity** | Bucket capacity |

**Configuration:**

```
Storage Type: S3-Compatible
Endpoint: https://minio.example.com
Bucket: papyrus-books
Access Key: ********
Secret Key: ********
Region: us-east-1 (optional)
```

#### 7. Papyrus Server (Unified Storage)

Files stored on the same Papyrus Server that handles metadata—the simplest self-hosted setup.

| Property | Value |
|----------|-------|
| **Use Case** | Full self-hosting, single server |
| **Sync** | Via Papyrus API |
| **Setup** | Included with Papyrus Server |
| **Capacity** | Server storage |

**Configuration:**

```
Storage Type: Papyrus Server
Server URL: https://papyrus.example.com
Auth: Same as Papyrus Server login
```

### Backend Comparison

| Backend | Self-Hosted | Free Tier | Max File Size | Offline Access |
|---------|-------------|-----------|---------------|----------------|
| Local | Yes (device) | Yes | Device limit | Full |
| Google Drive | No | 15GB shared | 5TB | Selective |
| OneDrive | No | 5GB | 250GB | Selective |
| Dropbox | No | 2GB | 2GB (free) | Selective |
| WebDAV | Yes | N/A | Server limit | Selective |
| MinIO/S3 | Yes | N/A | 5TB per object | Selective |
| Papyrus Server | Yes | N/A | Server limit | Selective |

### Storage Configuration UI

Users configure storage backends in **Settings > Storage**:

```mermaid
flowchart TB
    subgraph UI["Storage Configuration Screen"]
        direction TB
        Primary["Primary Storage Selector"]

        subgraph Backends["Configured Backends"]
            GD["✓ Google Drive [Primary]<br/>user@gmail.com<br/>2.3 GB / 15 GB"]
            WD["WebDAV (Nextcloud) [Secondary]<br/>nextcloud.example.com<br/>Connected"]
        end

        Add["+ Add Storage Backend"]

        subgraph Offline["Offline Books"]
            Status["Downloaded: 45 books (1.2 GB)"]
            Manage["Manage Offline Books"]
        end
    end

    Primary --> Backends
    Backends --> Add
    Add --> Offline
```

---

## Synchronization Architecture

### Sync Flow

```mermaid
sequenceDiagram
    participant A as Client A (Phone)
    participant LA as Local Store A
    participant S as Papyrus Server
    participant LB as Local Store B
    participant B as Client B (Tablet)
    participant FS as File Storage Backend

    A->>LA: 1. Local Change (read page 50)
    LA->>LA: Save to Sync Queue
    LA->>S: 2. Push to Server
    S->>S: Record in Change Log<br/>book_123.position = 50
    S-->>B: 3. Notify/Poll
    B->>S: 4. Fetch Changes
    S-->>LB: Return changes
    LB->>LB: Apply updates
    LB->>FS: 5. Sync Files (if needed)
```

### Sync Components

#### 1. Change Tracking

Every syncable entity includes:

```json
{
  "id": "uuid",
  "data": { ... },
  "version": 15,
  "updated_at": "2024-01-15T10:30:00Z",
  "device_id": "device_abc123",
  "deleted": false
}
```

#### 2. Sync Queue

Local changes are queued for sync:

```json
{
  "queue": [
    {
      "entity_type": "reading_progress",
      "entity_id": "book_123",
      "operation": "update",
      "data": { "position": "chapter:5,paragraph:12" },
      "timestamp": "2024-01-15T10:30:00Z",
      "retry_count": 0
    }
  ]
}
```

#### 3. Conflict Resolution

When concurrent edits occur:

| Conflict Type | Resolution Strategy |
|---------------|---------------------|
| Reading position | Latest timestamp wins |
| Metadata edits | Last write wins + merge non-conflicting fields |
| Annotations | Keep both (no true conflict) |
| Shelf membership | Union of all changes |
| Deletions | Delete wins (with grace period) |

**Conflict Example:**

```
Device A: Sets book title to "Title A" at T1
Device B: Sets book author to "Author B" at T2
Resolution: Title = "Title A", Author = "Author B" (merged)
```

#### 4. File Sync

Book files sync separately from metadata:

```mermaid
sequenceDiagram
    participant C as Client
    participant PS as Papyrus Server
    participant SB as Storage Backend

    Note over PS: Server stores file reference:<br/>file_id, storage_backend,<br/>storage_path, checksum, size

    C->>PS: GET /api/v1/books/{id}/file
    PS-->>C: { download_url: "signed_url" }
    C->>SB: Download file directly
    SB-->>C: Book file (EPUB, PDF, etc.)
    C->>C: Cache locally for offline access
```

### Sync Settings

Users configure sync behavior in Settings > Sync:

| Setting | Options | Default |
|---------|---------|---------|
| **Auto-sync** | On/Off | On |
| **Sync frequency** | Real-time, 5min, 15min, Manual | Real-time |
| **Sync on WiFi only** | On/Off | Off |
| **Sync reading position** | On/Off | On |
| **Sync annotations** | On/Off | On |
| **Sync statistics** | On/Off | On |
| **Conflict notification** | On/Off | On |

---

## Offline Capabilities

### Offline-First Design

Papyrus works fully offline with eventual sync:

| Feature | Offline Behavior |
|---------|------------------|
| **Reading** | Full access to downloaded books |
| **Annotations** | Create, edit, delete (queued for sync) |
| **Progress tracking** | Tracked locally, synced later |
| **Library browsing** | Cached metadata available |
| **Search** | Local index searched |
| **Book import** | Import to local storage |
| **Goals** | Progress tracked offline |

### Offline Storage

Local device storage structure:

```
/papyrus/
├── database/
│   ├── metadata.db          # SQLite: books, shelves, etc.
│   ├── annotations.db       # SQLite: highlights, notes
│   └── sync_queue.db        # Pending sync operations
├── books/
│   └── {book_id}/
│       ├── book.epub        # Downloaded book file
│       ├── cover.jpg        # Cached cover image
│       └── index.json       # Search index (if enabled)
├── cache/
│   ├── covers/              # Cover image cache
│   └── metadata/            # API response cache
└── config/
    ├── settings.json        # User preferences
    └── storage.json         # Backend configuration
```

### Download Management

Users control which books are available offline in **Settings > Offline Books**:

**Auto-download rules:**

- None (manual only)
- Currently reading shelf *(default)*
- All books
- Custom shelves

**Storage settings:**

- Storage limit: configurable (e.g., 5 GB)
- Shows current usage (e.g., 1.2 GB, 45 books)

**Book list shows:**

| Book | Size | Status |
|------|------|--------|
| The Great Gatsby | 12 MB | ☑ Downloaded |
| 1984 | 8 MB | ☑ Downloaded |
| Dune | 15 MB | ☑ Downloaded |
| War and Peace | 45 MB | ☐ Cloud only |

**Actions:** Download Selected, Remove All

---

## Security

### Authentication

| Method | Use Case |
|--------|----------|
| **JWT Tokens** | API authentication |
| **Refresh Tokens** | Long-lived sessions with rotation |
| **OAuth 2.0** | Google sign-in, storage backends |
| **API Keys** | Third-party integrations (optional) |

### Data Protection

| Layer | Protection |
|-------|------------|
| **In Transit** | TLS 1.3 for all connections |
| **At Rest (Server)** | Database encryption (optional) |
| **At Rest (Client)** | Platform keychain for credentials |
| **Storage Backends** | Provider's encryption (Google, etc.) |

### Privacy

- No analytics by default (opt-in only)
- Metadata server does not access file contents
- Storage backend credentials stored locally only
- Complete data export available
- Account deletion removes all server data

---

## Deployment Scenarios

### Scenario 1: Cloud-First User

Uses hosted Papyrus Server + Google Drive for files.

```
Client ──▶ Hosted Papyrus Server (papyrus.app)
       └──▶ Google Drive (user's account)
```

**Setup:** Sign up, connect Google Drive, done.

### Scenario 2: Privacy-Conscious Self-Hoster

Self-hosts everything on home server.

```
Client ──▶ Self-Hosted Papyrus Server (home.local)
       └──▶ Self-Hosted MinIO (home.local)
```

**Setup:** Deploy Docker stack, configure DNS/VPN.

### Scenario 3: Hybrid User

Self-hosted metadata, Dropbox for files (for mobile access).

```
Client ──▶ Self-Hosted Papyrus Server (VPS)
       └──▶ Dropbox (user's account)
```

**Setup:** Deploy server on VPS, connect Dropbox.

### Scenario 4: Offline-Only User

No server, local storage only.

```
Client ──▶ Local Storage Only
```

**Setup:** None. Works out of the box.

---

## Related Documents

- [Technologies](technologies.md) - Technology stack details
- [Database Model](database-model.md) - Data schema
- [Functional Requirements](requirements/functional-requirements.md) - FR-7.x (Storage & Sync)
- [Non-Functional Requirements](requirements/non-functional-requirements.md) - NFR-2.x (Synchronization)
- [API Specification](../design/api/swagger.yaml) - Full API documentation
