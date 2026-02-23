"""Rating routes."""

from datetime import UTC, datetime
from uuid import UUID

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas.community_rating import (
    CreateRatingRequest,
    RatingResponse,
    UpdateRatingRequest,
)

router = APIRouter()


@router.post("", response_model=RatingResponse, status_code=status.HTTP_201_CREATED)
async def rate_book(user_id: CurrentUserId, request: CreateRatingRequest) -> RatingResponse:
    """Rate a book (1-10 scale)."""
    return RatingResponse(
        user_id=user_id,
        catalog_book_id=request.catalog_book_id,
        score=request.score,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.patch("/{book_id}", response_model=RatingResponse)
async def update_rating(
    user_id: CurrentUserId, book_id: UUID, request: UpdateRatingRequest
) -> RatingResponse:
    """Update an existing rating."""
    return RatingResponse(
        user_id=user_id,
        catalog_book_id=book_id,
        score=request.score,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.delete("/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_rating(user_id: CurrentUserId, book_id: UUID) -> Response:
    """Remove a rating."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
