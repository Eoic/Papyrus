"""Series routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import (
    CreateSeriesRequest,
    Series,
    SeriesList,
    SeriesWithBooks,
    UpdateSeriesRequest,
)

router = APIRouter()


def _example_series(series_id: UUID | None = None) -> Series:
    """Create an example series for responses."""
    return Series(
        series_id=series_id or uuid4(),
        name="Example Series",
        description="An example series",
        author="John Author",
        total_books=5,
        is_complete=False,
        book_count=2,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=SeriesList,
    summary="List all series",
)
async def list_series(user_id: CurrentUserId) -> SeriesList:
    """Return all series for the user."""
    return SeriesList(series=[_example_series()])


@router.post(
    "",
    response_model=Series,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new series",
)
async def create_series(
    user_id: CurrentUserId,
    request: CreateSeriesRequest,
) -> Series:
    """Create a new series."""
    return Series(
        series_id=uuid4(),
        name=request.name,
        description=request.description,
        author=request.author,
        total_books=request.total_books,
        is_complete=request.is_complete,
        book_count=0,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/{series_id}",
    response_model=SeriesWithBooks,
    summary="Get series details",
)
async def get_series(
    user_id: CurrentUserId,
    series_id: UUID,
) -> SeriesWithBooks:
    """Return detailed information about a series with its books."""
    base = _example_series(series_id)
    return SeriesWithBooks(
        series_id=base.series_id,
        name=base.name,
        description=base.description,
        author=base.author,
        total_books=base.total_books,
        is_complete=base.is_complete,
        book_count=base.book_count,
        created_at=base.created_at,
        updated_at=base.updated_at,
        books=[],
    )


@router.patch(
    "/{series_id}",
    response_model=Series,
    summary="Update series",
)
async def update_series(
    user_id: CurrentUserId,
    series_id: UUID,
    request: UpdateSeriesRequest,
) -> Series:
    """Update series properties."""
    series = _example_series(series_id)
    if request.name:
        series.name = request.name
    if request.description:
        series.description = request.description
    if request.author:
        series.author = request.author
    if request.total_books is not None:
        series.total_books = request.total_books
    if request.is_complete is not None:
        series.is_complete = request.is_complete
    return series


@router.delete(
    "/{series_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete series",
)
async def delete_series(
    user_id: CurrentUserId,
    series_id: UUID,
) -> Response:
    """Delete a series. Books are not deleted."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
