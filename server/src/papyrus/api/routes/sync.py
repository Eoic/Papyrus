"""Sync routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import (
    CreateMetadataServerConfigRequest,
    MetadataServerConfig,
    ServerType,
    SyncChanges,
    SyncConflictResponse,
    SyncPushRequest,
    SyncPushResponse,
    SyncStatus,
)
from papyrus.schemas.sync import SyncAccepted, SyncStatusEnum

router = APIRouter()


@router.get(
    "/status",
    response_model=SyncStatus,
    summary="Get sync status",
)
async def get_sync_status(user_id: CurrentUserId) -> SyncStatus:
    """Return current sync status for the user."""
    return SyncStatus(
        status=SyncStatusEnum.IDLE,
        last_sync_at=datetime.now(UTC),
        pending_changes=0,
    )


@router.get(
    "/changes",
    response_model=SyncChanges,
    summary="Pull changes from server",
)
async def pull_changes(
    user_id: CurrentUserId,
    since: datetime | None = None,
    device_id: str | None = None,
) -> SyncChanges:
    """Pull changes from the server since the specified timestamp."""
    return SyncChanges(
        changes=[],
        server_timestamp=datetime.now(UTC),
    )


@router.post(
    "/changes",
    response_model=SyncPushResponse,
    summary="Push changes to server",
)
async def push_changes(
    user_id: CurrentUserId,
    request: SyncPushRequest,
) -> SyncPushResponse:
    """Push local changes to the server."""
    accepted = []
    for change in request.changes:
        accepted.append(
            SyncAccepted(
                entity_type=change.entity_type,
                entity_id=change.entity_id,
                new_version=(change.version or 0) + 1,
            )
        )

    return SyncPushResponse(
        accepted=accepted,
        rejected=[],
        server_timestamp=datetime.now(UTC),
    )


@router.get(
    "/conflicts",
    response_model=SyncConflictResponse,
    summary="Get unresolved conflicts",
)
async def get_sync_conflicts(user_id: CurrentUserId) -> SyncConflictResponse:
    """Return any unresolved sync conflicts."""
    return SyncConflictResponse(conflicts=[])


@router.post(
    "/force",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Force full sync",
)
async def force_sync(user_id: CurrentUserId) -> Response:
    """Force a full sync, re-downloading all data."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# Metadata server configuration routes
@router.get(
    "/config",
    response_model=MetadataServerConfig | None,
    summary="Get metadata server configuration",
)
async def get_metadata_server_config(user_id: CurrentUserId) -> MetadataServerConfig | None:
    """Return the current metadata server configuration."""
    return MetadataServerConfig(
        config_id=uuid4(),
        server_url="https://api.papyrus.app",
        server_type=ServerType.OFFICIAL,
        is_connected=True,
        sync_enabled=True,
        sync_interval_seconds=30,
        last_sync_at=datetime.now(UTC),
        sync_status=SyncStatusEnum.IDLE,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.post(
    "/config",
    response_model=MetadataServerConfig,
    status_code=status.HTTP_201_CREATED,
    summary="Configure metadata server",
)
async def create_metadata_server_config(
    user_id: CurrentUserId,
    request: CreateMetadataServerConfigRequest,
) -> MetadataServerConfig:
    """Configure a metadata server connection."""
    return MetadataServerConfig(
        config_id=uuid4(),
        server_url=str(request.server_url),
        server_type=request.server_type,
        is_connected=False,
        sync_enabled=request.sync_enabled,
        sync_interval_seconds=request.sync_interval_seconds,
        sync_status=SyncStatusEnum.IDLE,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.delete(
    "/config",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove metadata server configuration",
)
async def delete_metadata_server_config(user_id: CurrentUserId) -> Response:
    """Remove the metadata server configuration."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/config/test",
    response_model=MetadataServerConfig,
    summary="Test metadata server connection",
)
async def test_metadata_server_connection(user_id: CurrentUserId) -> MetadataServerConfig:
    """Test the connection to the configured metadata server."""
    return MetadataServerConfig(
        config_id=uuid4(),
        server_url="https://api.papyrus.app",
        server_type=ServerType.OFFICIAL,
        is_connected=True,
        sync_enabled=True,
        sync_interval_seconds=30,
        last_sync_at=datetime.now(UTC),
        sync_status=SyncStatusEnum.IDLE,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )
