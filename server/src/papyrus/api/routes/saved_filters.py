"""Saved filter routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import (
    CreateSavedFilterRequest,
    FilterType,
    SavedFilter,
    SavedFilterList,
    UpdateSavedFilterRequest,
)

router = APIRouter()


def _example_filter(filter_id: UUID | None = None) -> SavedFilter:
    """Create an example saved filter for responses."""
    return SavedFilter(
        filter_id=filter_id or uuid4(),
        name="Unread Fiction",
        description="Fiction books I haven't started",
        query="status:not_started tag:fiction",
        filter_type=FilterType.CUSTOM,
        icon="book",
        color="#4A90D9",
        is_pinned=True,
        usage_count=15,
        last_used_at=datetime.now(UTC),
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=SavedFilterList,
    summary="List saved filters",
)
async def list_saved_filters(
    user_id: CurrentUserId,
    is_pinned: bool | None = None,
) -> SavedFilterList:
    """Return all saved filters for the user."""
    return SavedFilterList(filters=[_example_filter()])


@router.post(
    "",
    response_model=SavedFilter,
    status_code=status.HTTP_201_CREATED,
    summary="Create saved filter",
)
async def create_saved_filter(
    user_id: CurrentUserId,
    request: CreateSavedFilterRequest,
) -> SavedFilter:
    """Create a new saved filter."""
    return SavedFilter(
        filter_id=uuid4(),
        name=request.name,
        description=request.description,
        query=request.query,
        filter_type=request.filter_type,
        icon=request.icon,
        color=request.color,
        is_pinned=request.is_pinned,
        usage_count=0,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/{filter_id}",
    response_model=SavedFilter,
    summary="Get saved filter",
)
async def get_saved_filter(
    user_id: CurrentUserId,
    filter_id: UUID,
) -> SavedFilter:
    """Return detailed information about a saved filter."""
    return _example_filter(filter_id)


@router.patch(
    "/{filter_id}",
    response_model=SavedFilter,
    summary="Update saved filter",
)
async def update_saved_filter(
    user_id: CurrentUserId,
    filter_id: UUID,
    request: UpdateSavedFilterRequest,
) -> SavedFilter:
    """Update a saved filter."""
    saved_filter = _example_filter(filter_id)
    for field, value in request.model_dump(exclude_unset=True).items():
        setattr(saved_filter, field, value)
    return saved_filter


@router.delete(
    "/{filter_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete saved filter",
)
async def delete_saved_filter(
    user_id: CurrentUserId,
    filter_id: UUID,
) -> Response:
    """Delete a saved filter."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/{filter_id}/use",
    response_model=SavedFilter,
    summary="Mark filter as used",
)
async def use_saved_filter(
    user_id: CurrentUserId,
    filter_id: UUID,
) -> SavedFilter:
    """Mark a filter as used, updating usage count and last_used_at."""
    saved_filter = _example_filter(filter_id)
    saved_filter.usage_count = (saved_filter.usage_count or 0) + 1
    saved_filter.last_used_at = datetime.now(UTC)
    return saved_filter
