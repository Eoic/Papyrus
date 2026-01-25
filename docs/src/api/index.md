# API

This section contains the complete REST API documentation for the Papyrus Server.

## Overview

The Papyrus Server provides a RESTful API for:

- **Authentication** - User registration, login, OAuth, and session management
- **Books** - CRUD operations for book metadata and file references
- **Organization** - Shelves, tags, and series management
- **Annotations** - Highlights, notes, and bookmarks
- **Progress** - Reading sessions and statistics
- **Goals** - Reading goal tracking
- **Sync** - Cross-device synchronization
- **Storage** - File storage backend configuration
- **Files** - File upload/download (when server is file backend)

## Authentication

Most endpoints require authentication via JWT Bearer token:

```
Authorization: Bearer <access_token>
```

Obtain tokens through the `/auth/login` or `/auth/oauth/google` endpoints. Access tokens expire after 1 hour. Use the refresh token to obtain new access tokens via `/auth/refresh`.

## Base URL

| Environment | URL |
|-------------|-----|
| Production | `https://api.papyrus.app/v1` |
| Staging | `https://staging-api.papyrus.app/v1` |
| Local | `http://localhost:8080/v1` |

## Interactive Documentation

[:material-api: Open Interactive API Documentation](./redoc.html){ .md-button .md-button--primary target="_blank" }

The interactive documentation provides a complete reference for all API endpoints, including request/response schemas, authentication requirements, and example payloads.

---

## Download Specification

- [OpenAPI Specification (YAML)](./openapi.yaml) - Full API specification file

## Related Documentation

- [Server Architecture](../server-architecture.md) - System design and architecture
- [Database Model](../database-model.md) - Data schema and relationships
- [Entities](../entities.md) - Entity definitions and attributes
