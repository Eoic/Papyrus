"""Shelf routes."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Query, Response, status
from pydantic import BaseModel

from papyrus.api.deps import CurrentUserId, Pagination
from papyrus.schemas import (
    BookList,
    CreateShelfRequest,
    Pagination as PaginationSchema,
    Shelf,
    ShelfList,
    UpdateShelfRequest,
)

router = APIRouter()


class RemoveBooksRequest(BaseModel):
    """Request to remove books from a shelf."""

    book_ids: list[UUID]


class RemoveBooksResponse(BaseModel):
    """Response for removing books from a shelf."""

    removed_count: int


def _example_shelf(shelf_id: UUID | None = None) -> Shelf:
    """Create an example shelf for responses."""
    return Shelf(
        shelf_id=shelf_id or uuid4(),
        name="Example Shelf",
        description="An example shelf",
        color="#4A90D9",
        is_default=False,
        is_smart=False,
        book_count=0,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=ShelfList,
    summary="List all shelves",
)
async def list_shelves(
    user_id: CurrentUserId,
    include_books: bool = False,
    flat: bool = False,
) -> ShelfList:
    """Return all shelves for the user, including nested structure."""
    return ShelfList(shelves=[_example_shelf()])


@router.post(
    "",
    response_model=Shelf,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new shelf",
)
async def create_shelf(
    user_id: CurrentUserId,
    request: CreateShelfRequest,
) -> Shelf:
    """Create a new shelf or sub-shelf."""
    return Shelf(
        shelf_id=uuid4(),
        name=request.name,
        description=request.description,
        color=request.color,
        icon=request.icon,
        is_default=False,
        is_smart=request.is_smart,
        smart_query=request.smart_query,
        sort_order=request.sort_order,
        parent_shelf_id=request.parent_shelf_id,
        book_count=0,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/{shelf_id}",
    response_model=Shelf,
    summary="Get shelf details",
)
async def get_shelf(
    user_id: CurrentUserId,
    shelf_id: UUID,
) -> Shelf:
    """Return detailed information about a shelf."""
    return _example_shelf(shelf_id)


@router.patch(
    "/{shelf_id}",
    response_model=Shelf,
    summary="Update shelf",
)
async def update_shelf(
    user_id: CurrentUserId,
    shelf_id: UUID,
    request: UpdateShelfRequest,
) -> Shelf:
    """Update shelf properties."""
    shelf = _example_shelf(shelf_id)
    if request.name:
        shelf.name = request.name
    if request.description:
        shelf.description = request.description
    if request.color:
        shelf.color = request.color
    return shelf


@router.delete(
    "/{shelf_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete shelf",
)
async def delete_shelf(
    user_id: CurrentUserId,
    shelf_id: UUID,
    move_books_to: Annotated[UUID | None, Query(description="Move books to this shelf")] = None,
) -> Response:
    """Delete a shelf. Books are not deleted."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/{shelf_id}/books",
    response_model=BookList,
    summary="List books in shelf",
)
async def list_shelf_books(
    user_id: CurrentUserId,
    shelf_id: UUID,
    pagination: Pagination,
) -> BookList:
    """Return paginated list of books in this shelf."""
    return BookList(
        books=[],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=0,
            total_pages=0,
            has_next=False,
            has_prev=False,
        ),
    )


# Static route must come before dynamic route to avoid conflict
@router.post(
    "/{shelf_id}/books/remove",
    response_model=RemoveBooksResponse,
    summary="Remove multiple books from shelf",
)
async def remove_books_from_shelf(
    user_id: CurrentUserId,
    shelf_id: UUID,
    request: RemoveBooksRequest,
) -> RemoveBooksResponse:
    """Remove multiple books from this shelf in one request."""
    return RemoveBooksResponse(removed_count=len(request.book_ids))


@router.post(
    "/{shelf_id}/books/{book_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Add book to shelf",
)
async def add_book_to_shelf(
    user_id: CurrentUserId,
    shelf_id: UUID,
    book_id: UUID,
) -> Response:
    """Add a book to this shelf."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete(
    "/{shelf_id}/books/{book_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove book from shelf",
)
async def remove_book_from_shelf(
    user_id: CurrentUserId,
    shelf_id: UUID,
    book_id: UUID,
) -> Response:
    """Remove a book from this shelf."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
