"""Sync-related schemas."""

from datetime import datetime
from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class ServerType(StrEnum):
    """Metadata server type."""

    OFFICIAL = "official"
    SELF_HOSTED = "self_hosted"


class SyncStatusEnum(StrEnum):
    """Sync status values."""

    IDLE = "idle"
    SYNCING = "syncing"
    ERROR = "error"


class ResolutionStrategy(StrEnum):
    """Conflict resolution strategy."""

    LATEST_WINS = "latest_wins"
    MERGE = "merge"
    MANUAL = "manual"


class SyncOperation(StrEnum):
    """Sync operation type."""

    CREATE = "create"
    UPDATE = "update"
    DELETE = "delete"


class MetadataServerConfig(BaseModel):
    """Metadata server configuration response."""

    model_config = ConfigDict(from_attributes=True)

    config_id: UUID
    server_url: HttpUrl | str
    server_type: ServerType | None = None
    is_connected: bool = False
    sync_enabled: bool = True
    sync_interval_seconds: int | None = None
    last_sync_at: datetime | None = None
    sync_status: SyncStatusEnum | None = None
    sync_error_message: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class CreateMetadataServerConfigRequest(BaseModel):
    """Metadata server configuration creation request."""

    server_url: HttpUrl | str = Field(..., description="URL of the metadata server")
    server_type: ServerType | None = None
    sync_enabled: bool = True
    sync_interval_seconds: int = Field(30, ge=10, le=3600)
    auth_token: str | None = Field(None, description="JWT or API token for authentication")


class SyncChange(BaseModel):
    """Individual sync change."""

    entity_type: str
    entity_id: UUID
    operation: SyncOperation
    data: dict[str, Any] | None = None
    version: int | None = None
    updated_at: datetime | None = None
    device_id: str | None = None


class SyncChanges(BaseModel):
    """Sync changes response."""

    changes: list[SyncChange]
    server_timestamp: datetime


class SyncPushChange(BaseModel):
    """Individual change in push request."""

    entity_type: str
    entity_id: UUID
    operation: SyncOperation
    data: dict[str, Any]
    timestamp: datetime
    version: int | None = None


class SyncPushRequest(BaseModel):
    """Sync push request."""

    changes: list[SyncPushChange]
    device_id: str


class SyncAccepted(BaseModel):
    """Accepted sync change."""

    entity_type: str
    entity_id: UUID
    new_version: int


class SyncRejected(BaseModel):
    """Rejected sync change."""

    entity_type: str
    entity_id: UUID
    reason: str


class SyncPushResponse(BaseModel):
    """Sync push response."""

    accepted: list[SyncAccepted]
    rejected: list[SyncRejected]
    server_timestamp: datetime


class SyncConflict(BaseModel):
    """Sync conflict detail."""

    entity_type: str
    entity_id: UUID
    local_version: int
    server_version: int
    server_data: dict[str, Any] | None = None
    resolved_data: dict[str, Any] | None = None
    resolution_strategy: ResolutionStrategy | None = None


class SyncConflictResponse(BaseModel):
    """Sync conflicts response."""

    conflicts: list[SyncConflict]


class SyncStatus(BaseModel):
    """Sync status response."""

    status: SyncStatusEnum
    last_sync_at: datetime | None = None
    pending_changes: int | None = None
    error_message: str | None = None
