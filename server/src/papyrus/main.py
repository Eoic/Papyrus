"""FastAPI application factory and configuration."""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from papyrus.api.routes import api_router
from papyrus.config import get_settings
from papyrus.core.exceptions import AppError

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan events."""
    # Startup
    yield
    # Shutdown


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="Papyrus Server API",
        version="1.0.0",
        description="""
REST API for Papyrus - a cross-platform book management application.

## Overview

The Papyrus Server handles metadata storage and synchronization for the Papyrus
e-book reader application. It provides endpoints for:

- **Authentication**: User registration, login, OAuth, and session management
- **Books**: CRUD operations for book metadata and file references
- **Organization**: Shelves, tags, and series management
- **Annotations**: Highlights, notes, and bookmarks
- **Progress**: Reading sessions and statistics
- **Goals**: Reading goal tracking
- **Sync**: Cross-device synchronization
- **Storage**: File storage backend configuration
- **Files**: File upload/download (when server is file backend)

## Authentication

Most endpoints require authentication via JWT Bearer token. Obtain tokens
through the `/auth/login` or `/auth/oauth/google` endpoints.

```
Authorization: Bearer <access_token>
```

Access tokens expire after 1 hour. Use the refresh token to obtain new
access tokens via `/auth/refresh`.

## Rate Limiting

Rate limits are enforced per user:

| Endpoint Category | Limit |
|-------------------|-------|
| Authentication | 5 requests/minute |
| General API | 100 requests/minute |
| File uploads | 10 requests/minute |
| Batch operations | 20 requests/minute |
""",
        contact={
            "name": "Papyrus Support",
            "url": "https://github.com/Eoic/Papyrus",
        },
        license_info={
            "name": "AGPL-3.0",
            "url": "https://www.gnu.org/licenses/agpl-3.0.html",
        },
        lifespan=lifespan,
    )

    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Exception handlers
    @app.exception_handler(AppError)
    async def app_exception_handler(request: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": {
                    "code": exc.code,
                    "message": exc.message,
                    "details": exc.details,
                }
            },
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": {
                    "code": "INTERNAL_ERROR",
                    "message": "An unexpected error occurred",
                }
            },
        )

    # Include API router
    app.include_router(api_router, prefix="/v1")

    # Health check endpoint
    @app.get("/health", tags=["Health"])
    async def health_check() -> dict[str, str]:
        """Check API health status."""
        return {"status": "healthy"}

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "papyrus.main:app",
        host="0.0.0.0",
        port=8080,
        reload=True,
    )
