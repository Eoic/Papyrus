"""Bookmark routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import (
    Bookmark,
    BookmarkList,
    CreateBookmarkRequest,
    UpdateBookmarkRequest,
)

router = APIRouter()


def _example_bookmark(bookmark_id: UUID | None = None, book_id: UUID | None = None) -> Bookmark:
    """Create an example bookmark for responses."""
    return Bookmark(
        bookmark_id=bookmark_id or uuid4(),
        book_id=book_id or uuid4(),
        position="epubcfi(/6/4[chap01]!/4/2/1:0)",
        page_number=42,
        chapter_title="Chapter 3",
        note="Interesting section",
        color="#FF5722",
        created_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=BookmarkList,
    summary="List all bookmarks",
)
async def list_bookmarks(
    user_id: CurrentUserId,
    book_id: UUID | None = None,
) -> BookmarkList:
    """Return list of bookmarks, optionally filtered by book."""
    return BookmarkList(bookmarks=[_example_bookmark()])


@router.get(
    "/books/{book_id}",
    response_model=BookmarkList,
    summary="List book bookmarks",
)
async def list_book_bookmarks(
    user_id: CurrentUserId,
    book_id: UUID,
) -> BookmarkList:
    """Return list of bookmarks for a specific book."""
    return BookmarkList(bookmarks=[_example_bookmark(book_id=book_id)])


@router.post(
    "/books/{book_id}",
    response_model=Bookmark,
    status_code=status.HTTP_201_CREATED,
    summary="Create bookmark",
)
async def create_bookmark(
    user_id: CurrentUserId,
    book_id: UUID,
    request: CreateBookmarkRequest,
) -> Bookmark:
    """Create a new bookmark for a book."""
    return Bookmark(
        bookmark_id=uuid4(),
        book_id=book_id,
        position=request.position,
        page_number=request.page_number,
        chapter_title=request.chapter_title,
        note=request.note,
        color=request.color,
        created_at=datetime.now(UTC),
    )


@router.get(
    "/{bookmark_id}",
    response_model=Bookmark,
    summary="Get bookmark details",
)
async def get_bookmark(
    user_id: CurrentUserId,
    bookmark_id: UUID,
) -> Bookmark:
    """Return detailed information about a bookmark."""
    return _example_bookmark(bookmark_id)


@router.patch(
    "/{bookmark_id}",
    response_model=Bookmark,
    summary="Update bookmark",
)
async def update_bookmark(
    user_id: CurrentUserId,
    bookmark_id: UUID,
    request: UpdateBookmarkRequest,
) -> Bookmark:
    """Update a bookmark's note or color."""
    bookmark = _example_bookmark(bookmark_id)
    if request.note is not None:
        bookmark.note = request.note
    if request.color:
        bookmark.color = request.color
    return bookmark


@router.delete(
    "/{bookmark_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete bookmark",
)
async def delete_bookmark(
    user_id: CurrentUserId,
    bookmark_id: UUID,
) -> Response:
    """Delete a bookmark."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
