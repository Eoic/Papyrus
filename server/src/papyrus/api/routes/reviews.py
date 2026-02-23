"""Review routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas.community_review import (
    CreateReviewRequest,
    ReviewReactionRequest,
    ReviewResponse,
    UpdateReviewRequest,
)

router = APIRouter()


@router.post("", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def create_review(user_id: CurrentUserId, request: CreateReviewRequest) -> ReviewResponse:
    """Create a review for a book."""
    return ReviewResponse(
        review_id=uuid4(),
        user_id=user_id,
        catalog_book_id=request.catalog_book_id,
        title=request.title,
        body=request.body,
        contains_spoilers=request.contains_spoilers,
        visibility=request.visibility,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get("/{review_id}", response_model=ReviewResponse)
async def get_review(user_id: CurrentUserId, review_id: UUID) -> ReviewResponse:
    """Get a review by ID."""
    return ReviewResponse(
        review_id=review_id,
        user_id=user_id,
        catalog_book_id=uuid4(),
        body="Example review text for this book.",
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.patch("/{review_id}", response_model=ReviewResponse)
async def update_review(
    user_id: CurrentUserId, review_id: UUID, request: UpdateReviewRequest
) -> ReviewResponse:
    """Update a review."""
    return ReviewResponse(
        review_id=review_id,
        user_id=user_id,
        catalog_book_id=uuid4(),
        title=request.title,
        body=request.body or "Original review text.",
        contains_spoilers=request.contains_spoilers or False,
        visibility=request.visibility or "public",
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(user_id: CurrentUserId, review_id: UUID) -> Response:
    """Delete a review."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/{review_id}/react", status_code=status.HTTP_204_NO_CONTENT)
async def react_to_review(
    user_id: CurrentUserId, review_id: UUID, request: ReviewReactionRequest
) -> Response:
    """Add a reaction (like/helpful) to a review."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/{review_id}/react", status_code=status.HTTP_204_NO_CONTENT)
async def remove_reaction(user_id: CurrentUserId, review_id: UUID) -> Response:
    """Remove a reaction from a review."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
