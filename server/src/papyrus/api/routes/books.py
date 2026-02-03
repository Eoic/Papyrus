"""Book routes."""

from datetime import UTC, datetime
from typing import Annotated, Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Query, Response, UploadFile, status
from pydantic import BaseModel

from papyrus.api.deps import CurrentUserId, Pagination
from papyrus.schemas import (
    Book,
    BookCreate,
    BookList,
    BookUpdate,
    MetadataSearchResult,
    ReadingProgress,
    ReadingStatus,
    Shelf,
    Tag,
    UpdateProgressRequest,
)
from papyrus.schemas import (
    Pagination as PaginationSchema,
)

router = APIRouter()


# Batch operation schemas
class BatchCreateRequest(BaseModel):
    books: list[BookCreate]


class BatchCreateResponse(BaseModel):
    created: list[Book]
    errors: list[dict[str, Any]]


class BatchUpdateRequest(BaseModel):
    book_ids: list[UUID]
    updates: dict[str, Any] | None = None
    add_tag_ids: list[UUID] | None = None
    remove_tag_ids: list[UUID] | None = None
    add_shelf_ids: list[UUID] | None = None
    remove_shelf_ids: list[UUID] | None = None


class BatchUpdateResponse(BaseModel):
    updated_count: int
    errors: list[dict[str, Any]]


class BatchDeleteRequest(BaseModel):
    book_ids: list[UUID]
    delete_files: bool = False


class BatchDeleteResponse(BaseModel):
    deleted_count: int
    errors: list[dict[str, Any]]


class MetadataFetchRequest(BaseModel):
    isbn: str | None = None
    title: str | None = None
    author: str | None = None


class MetadataFetchResponse(BaseModel):
    results: list[MetadataSearchResult]


class ShelfIdsRequest(BaseModel):
    shelf_ids: list[UUID]


class TagIdsRequest(BaseModel):
    tag_ids: list[UUID]


class ShelvesResponse(BaseModel):
    shelves: list[Shelf]


class TagsResponse(BaseModel):
    tags: list[Tag]


def _example_book(book_id: UUID | None = None) -> Book:
    """Create an example book for responses."""
    return Book(
        book_id=book_id or uuid4(),
        title="Example Book",
        author="John Author",
        reading_status=ReadingStatus.NOT_STARTED,
        added_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=BookList,
    summary="List user's books",
)
async def list_books(
    user_id: CurrentUserId,
    pagination: Pagination,
    status_filter: Annotated[ReadingStatus | None, Query(alias="status")] = None,
    shelf_id: UUID | None = None,
    tag_id: UUID | None = None,
    series_id: UUID | None = None,
    is_physical: bool | None = None,
    is_favorite: bool | None = None,
    search: str | None = None,
    query: str | None = None,
) -> BookList:
    """Return a paginated list of books in the user's library."""
    return BookList(
        books=[_example_book()],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=1,
            total_pages=1,
            has_next=False,
            has_prev=False,
        ),
    )


@router.post(
    "",
    response_model=Book,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new book",
)
async def create_book(
    user_id: CurrentUserId,
    request: BookCreate,
) -> Book:
    """Add a new book to the user's library."""
    return Book(
        book_id=uuid4(),
        title=request.title,
        author=request.author,
        subtitle=request.subtitle,
        isbn=request.isbn,
        isbn13=request.isbn13,
        publication_date=request.publication_date,
        publisher=request.publisher,
        language=request.language,
        page_count=request.page_count,
        description=request.description,
        cover_image_url=request.cover_image_url,
        series_id=request.series_id,
        series_number=request.series_number,
        file_path=request.file_path,
        file_format=request.file_format,
        file_size=request.file_size,
        file_hash=request.file_hash,
        storage_backend_id=request.storage_backend_id,
        is_physical=request.is_physical,
        physical_location=request.physical_location,
        custom_metadata=request.custom_metadata,
        reading_status=ReadingStatus.NOT_STARTED,
        added_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


# Static routes must be defined BEFORE dynamic routes to avoid conflicts
@router.post(
    "/batch",
    response_model=BatchCreateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Batch create books",
)
async def batch_create_books(
    user_id: CurrentUserId,
    request: BatchCreateRequest,
) -> BatchCreateResponse:
    """Create multiple books in a single request."""
    created = []
    for book_req in request.books:
        created.append(
            Book(
                book_id=uuid4(),
                title=book_req.title,
                author=book_req.author,
                reading_status=ReadingStatus.NOT_STARTED,
                added_at=datetime.now(UTC),
                updated_at=datetime.now(UTC),
            )
        )
    return BatchCreateResponse(created=created, errors=[])


@router.patch(
    "/batch",
    response_model=BatchUpdateResponse,
    summary="Batch update books",
)
async def batch_update_books(
    user_id: CurrentUserId,
    request: BatchUpdateRequest,
) -> BatchUpdateResponse:
    """Update multiple books in a single request."""
    return BatchUpdateResponse(updated_count=len(request.book_ids), errors=[])


@router.delete(
    "/batch",
    response_model=BatchDeleteResponse,
    summary="Batch delete books",
)
async def batch_delete_books(
    user_id: CurrentUserId,
    request: BatchDeleteRequest,
) -> BatchDeleteResponse:
    """Delete multiple books in a single request."""
    return BatchDeleteResponse(deleted_count=len(request.book_ids), errors=[])


@router.post(
    "/metadata/fetch",
    response_model=MetadataFetchResponse,
    summary="Fetch metadata from online sources",
)
async def fetch_book_metadata(
    user_id: CurrentUserId,
    request: MetadataFetchRequest,
) -> MetadataFetchResponse:
    """Search online sources for book metadata."""
    return MetadataFetchResponse(
        results=[
            MetadataSearchResult(
                source="open_library",
                title=request.title or "Example Book",
                author=request.author or "Unknown Author",
                isbn=request.isbn,
            )
        ]
    )


# Dynamic routes with path parameters
@router.get(
    "/{book_id}",
    response_model=Book,
    summary="Get book details",
)
async def get_book(
    user_id: CurrentUserId,
    book_id: UUID,
) -> Book:
    """Return detailed information about a specific book."""
    return _example_book(book_id)


@router.patch(
    "/{book_id}",
    response_model=Book,
    summary="Update book metadata",
)
async def update_book(
    user_id: CurrentUserId,
    book_id: UUID,
    request: BookUpdate,
) -> Book:
    """Update book metadata fields."""
    book = _example_book(book_id)
    if request.title:
        book.title = request.title
    if request.author:
        book.author = request.author
    return book


@router.delete(
    "/{book_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a book",
)
async def delete_book(
    user_id: CurrentUserId,
    book_id: UUID,
    delete_file: bool = False,
) -> Response:
    """Remove a book from the library."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/{book_id}/cover",
    summary="Get book cover image",
)
async def get_book_cover(
    user_id: CurrentUserId,
    book_id: UUID,
) -> Response:
    """Return the book's cover image."""
    return Response(
        status_code=status.HTTP_302_FOUND,
        headers={"Location": "https://example.com/cover.jpg"},
    )


@router.put(
    "/{book_id}/cover",
    response_model=Book,
    summary="Upload book cover image",
)
async def upload_book_cover(
    user_id: CurrentUserId,
    book_id: UUID,
    file: UploadFile | None = None,
    url: str | None = None,
) -> Book:
    """Upload or replace the book's cover image."""
    book = _example_book(book_id)
    book.cover_image_url = url or "https://example.com/uploaded_cover.jpg"
    return book


@router.get(
    "/{book_id}/shelves",
    response_model=ShelvesResponse,
    summary="Get book's shelves",
)
async def get_book_shelves(
    user_id: CurrentUserId,
    book_id: UUID,
) -> ShelvesResponse:
    """Return the shelves this book belongs to."""
    return ShelvesResponse(shelves=[])


@router.put(
    "/{book_id}/shelves",
    response_model=ShelvesResponse,
    summary="Set book's shelves",
)
async def set_book_shelves(
    user_id: CurrentUserId,
    book_id: UUID,
    request: ShelfIdsRequest,
) -> ShelvesResponse:
    """Replace all shelf assignments for this book."""
    return ShelvesResponse(shelves=[])


@router.get(
    "/{book_id}/tags",
    response_model=TagsResponse,
    summary="Get book's tags",
)
async def get_book_tags(
    user_id: CurrentUserId,
    book_id: UUID,
) -> TagsResponse:
    """Return the tags assigned to this book."""
    return TagsResponse(tags=[])


@router.put(
    "/{book_id}/tags",
    response_model=TagsResponse,
    summary="Set book's tags",
)
async def set_book_tags(
    user_id: CurrentUserId,
    book_id: UUID,
    request: TagIdsRequest,
) -> TagsResponse:
    """Replace all tag assignments for this book."""
    return TagsResponse(tags=[])


@router.get(
    "/{book_id}/progress",
    response_model=ReadingProgress,
    summary="Get reading progress",
)
async def get_book_progress(
    user_id: CurrentUserId,
    book_id: UUID,
) -> ReadingProgress:
    """Return the current reading progress for a book."""
    return ReadingProgress(
        book_id=book_id,
        reading_status=ReadingStatus.NOT_STARTED,
    )


@router.put(
    "/{book_id}/progress",
    response_model=ReadingProgress,
    summary="Update reading progress",
)
async def update_book_progress(
    user_id: CurrentUserId,
    book_id: UUID,
    request: UpdateProgressRequest,
) -> ReadingProgress:
    """Update the reading position and status for a book."""
    return ReadingProgress(
        book_id=book_id,
        reading_status=request.reading_status or ReadingStatus.IN_PROGRESS,
        current_page=request.current_page,
        current_position=request.current_position,
        current_cfi=request.current_cfi,
        last_read_at=datetime.now(UTC),
    )
