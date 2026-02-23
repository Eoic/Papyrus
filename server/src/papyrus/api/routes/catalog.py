"""Community book catalog routes."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Query, status

from papyrus.api.deps import CurrentUserId, Pagination
from papyrus.schemas.catalog import (
    CatalogBookDetail,
    CatalogSearchResult,
    CreateCatalogBookRequest,
)
from papyrus.schemas.common import Pagination as PaginationSchema
from papyrus.schemas.community_rating import BookRatingsSummary
from papyrus.schemas.community_review import ReviewList

router = APIRouter()


@router.get("/search", response_model=CatalogSearchResult, summary="Search books")
async def search_catalog(
    user_id: CurrentUserId,
    q: Annotated[str, Query(min_length=1, max_length=200)],
) -> CatalogSearchResult:
    """Search for books in the local catalog and Open Library."""
    return CatalogSearchResult(local_results=[], open_library_results=[])


@router.get("/books/{book_id}", response_model=CatalogBookDetail, summary="Get catalog book")
async def get_catalog_book(user_id: CurrentUserId, book_id: UUID) -> CatalogBookDetail:
    """Get detailed information about a catalog book."""
    return CatalogBookDetail(
        catalog_book_id=book_id,
        title="Example Book",
        authors=["Example Author"],
        average_rating=None,
        rating_count=0,
        review_count=0,
        created_at=datetime.now(UTC),
    )


@router.post(
    "/books",
    response_model=CatalogBookDetail,
    status_code=status.HTTP_201_CREATED,
    summary="Add book to catalog",
)
async def add_catalog_book(
    user_id: CurrentUserId, request: CreateCatalogBookRequest
) -> CatalogBookDetail:
    """Add a user-contributed book to the community catalog."""
    return CatalogBookDetail(
        catalog_book_id=uuid4(),
        title=request.title,
        authors=request.authors,
        isbn=request.isbn,
        cover_url=request.cover_url,
        description=request.description,
        page_count=request.page_count,
        published_date=request.published_date,
        genres=request.genres,
        open_library_id=request.open_library_id,
        added_by_user_id=user_id,
        verified=False,
        average_rating=None,
        rating_count=0,
        review_count=0,
        created_at=datetime.now(UTC),
    )


@router.get(
    "/books/{book_id}/reviews", response_model=ReviewList, summary="Get book reviews"
)
async def get_book_reviews(
    user_id: CurrentUserId, book_id: UUID, pagination: Pagination
) -> ReviewList:
    """Get all reviews for a catalog book."""
    return ReviewList(
        reviews=[],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=0,
            total_pages=0,
            has_next=False,
            has_prev=False,
        ),
    )


@router.get(
    "/books/{book_id}/ratings/distribution",
    response_model=BookRatingsSummary,
    summary="Get rating distribution",
)
async def get_ratings_distribution(
    user_id: CurrentUserId, book_id: UUID
) -> BookRatingsSummary:
    """Get rating distribution for a catalog book."""
    return BookRatingsSummary(
        catalog_book_id=book_id, average_rating=None, rating_count=0, distribution=[]
    )
