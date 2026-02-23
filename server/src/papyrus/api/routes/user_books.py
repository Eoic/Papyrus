"""User book tracking routes."""

from datetime import UTC, datetime
from uuid import UUID

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas.community_user_book import (
    CreateUserBookRequest,
    UpdateUserBookRequest,
    UserBookResponse,
)

router = APIRouter()


@router.post("", response_model=UserBookResponse, status_code=status.HTTP_201_CREATED)
async def add_book(user_id: CurrentUserId, request: CreateUserBookRequest) -> UserBookResponse:
    """Add a book to the user's community library."""
    return UserBookResponse(
        user_id=user_id,
        catalog_book_id=request.catalog_book_id,
        status=request.status,
        visibility=request.visibility,
        created_at=datetime.now(UTC),
    )


@router.patch("/{book_id}", response_model=UserBookResponse)
async def update_book(
    user_id: CurrentUserId, book_id: UUID, request: UpdateUserBookRequest
) -> UserBookResponse:
    """Update book status or visibility."""
    return UserBookResponse(
        user_id=user_id,
        catalog_book_id=book_id,
        status=request.status or "want_to_read",
        visibility=request.visibility or "public",
        progress=request.progress,
        created_at=datetime.now(UTC),
    )


@router.delete("/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_book(user_id: CurrentUserId, book_id: UUID) -> Response:
    """Remove a book from the user's community library."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
