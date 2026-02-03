"""Storage backend routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status
from pydantic import BaseModel

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import (
    ConnectionStatus,
    CreateStorageBackendRequest,
    StorageBackend,
    StorageBackendList,
    StorageBackendType,
    UpdateStorageBackendRequest,
)

router = APIRouter()


class SetPrimaryRequest(BaseModel):
    """Request to set a storage backend as primary."""

    backend_id: UUID


def _example_backend(backend_id: UUID | None = None) -> StorageBackend:
    """Create an example storage backend for responses."""
    return StorageBackend(
        backend_id=backend_id or uuid4(),
        backend_type=StorageBackendType.LOCAL,
        name="Local Storage",
        is_primary=True,
        is_active=True,
        base_path="/storage/books",
        storage_used_bytes=1024 * 1024 * 500,  # 500 MB
        storage_quota_bytes=1024 * 1024 * 1024 * 10,  # 10 GB
        last_accessed_at=datetime.now(UTC),
        connection_status=ConnectionStatus.CONNECTED,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/backends",
    response_model=StorageBackendList,
    summary="List storage backends",
)
async def list_storage_backends(user_id: CurrentUserId) -> StorageBackendList:
    """Return all configured storage backends for the user."""
    return StorageBackendList(backends=[_example_backend()])


@router.post(
    "/backends",
    response_model=StorageBackend,
    status_code=status.HTTP_201_CREATED,
    summary="Add storage backend",
)
async def create_storage_backend(
    user_id: CurrentUserId,
    request: CreateStorageBackendRequest,
) -> StorageBackend:
    """Add a new storage backend configuration."""
    return StorageBackend(
        backend_id=uuid4(),
        backend_type=request.backend_type,
        name=request.name,
        is_primary=request.is_primary,
        is_active=True,
        base_path=request.base_path,
        connection_status=ConnectionStatus.DISCONNECTED,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/backends/{backend_id}",
    response_model=StorageBackend,
    summary="Get storage backend details",
)
async def get_storage_backend(
    user_id: CurrentUserId,
    backend_id: UUID,
) -> StorageBackend:
    """Return detailed information about a storage backend."""
    return _example_backend(backend_id)


@router.patch(
    "/backends/{backend_id}",
    response_model=StorageBackend,
    summary="Update storage backend",
)
async def update_storage_backend(
    user_id: CurrentUserId,
    backend_id: UUID,
    request: UpdateStorageBackendRequest,
) -> StorageBackend:
    """Update storage backend configuration."""
    backend = _example_backend(backend_id)
    if request.name:
        backend.name = request.name
    if request.is_active is not None:
        backend.is_active = request.is_active
    if request.base_path:
        backend.base_path = request.base_path
    return backend


@router.delete(
    "/backends/{backend_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove storage backend",
)
async def delete_storage_backend(
    user_id: CurrentUserId,
    backend_id: UUID,
) -> Response:
    """Remove a storage backend configuration."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/backends/{backend_id}/test",
    response_model=StorageBackend,
    summary="Test storage backend connection",
)
async def test_storage_backend(
    user_id: CurrentUserId,
    backend_id: UUID,
) -> StorageBackend:
    """Test the connection to a storage backend."""
    backend = _example_backend(backend_id)
    backend.connection_status = ConnectionStatus.CONNECTED
    return backend


@router.post(
    "/backends/set-primary",
    response_model=StorageBackend,
    summary="Set primary storage backend",
)
async def set_primary_storage_backend(
    user_id: CurrentUserId,
    request: SetPrimaryRequest,
) -> StorageBackend:
    """Set a storage backend as the primary."""
    backend = _example_backend(request.backend_id)
    backend.is_primary = True
    return backend
