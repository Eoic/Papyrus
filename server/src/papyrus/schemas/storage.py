"""Storage backend schemas."""

from datetime import datetime
from enum import Enum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class StorageBackendType(str, Enum):
    """Supported storage backend types."""

    LOCAL = "local"
    GOOGLE_DRIVE = "google_drive"
    ONEDRIVE = "onedrive"
    DROPBOX = "dropbox"
    WEBDAV = "webdav"
    MINIO = "minio"
    S3 = "s3"
    PAPYRUS_SERVER = "papyrus_server"


class ConnectionStatus(str, Enum):
    """Storage backend connection status."""

    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    ERROR = "error"


class StorageBackend(BaseModel):
    """Storage backend response schema."""

    model_config = ConfigDict(from_attributes=True)

    backend_id: UUID
    backend_type: StorageBackendType
    name: str
    is_primary: bool = False
    is_active: bool = True
    base_path: str | None = None
    storage_used_bytes: int | None = None
    storage_quota_bytes: int | None = None
    last_accessed_at: datetime | None = None
    connection_status: ConnectionStatus | None = None
    error_message: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class StorageBackendList(BaseModel):
    """Storage backend list response."""

    backends: list[StorageBackend]


class CreateStorageBackendRequest(BaseModel):
    """Storage backend creation request."""

    backend_type: StorageBackendType
    name: str = Field(..., max_length=100)
    is_primary: bool = False
    connection_config: dict[str, Any] | None = Field(
        None, description="Type-specific connection settings"
    )
    credentials: dict[str, Any] | None = Field(
        None, description="OAuth tokens or API keys"
    )
    base_path: str | None = None


class UpdateStorageBackendRequest(BaseModel):
    """Storage backend update request."""

    name: str | None = Field(None, max_length=100)
    is_active: bool | None = None
    connection_config: dict[str, Any] | None = None
    credentials: dict[str, Any] | None = None
    base_path: str | None = None
