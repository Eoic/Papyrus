"""Note routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId, Pagination
from papyrus.schemas import (
    CreateNoteRequest,
    Note,
    NoteList,
    UpdateNoteRequest,
)
from papyrus.schemas import (
    Pagination as PaginationSchema,
)

router = APIRouter()


def _example_note(note_id: UUID | None = None, book_id: UUID | None = None) -> Note:
    """Create an example note for responses."""
    return Note(
        note_id=note_id or uuid4(),
        book_id=book_id or uuid4(),
        book_title="Example Book",
        title="My Note Title",
        content="This is the content of my note about the book.",
        is_pinned=False,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=NoteList,
    summary="List all notes",
)
async def list_notes(
    user_id: CurrentUserId,
    pagination: Pagination,
    book_id: UUID | None = None,
    is_pinned: bool | None = None,
    search: str | None = None,
) -> NoteList:
    """Return paginated list of notes, optionally filtered by book."""
    return NoteList(
        notes=[_example_note()],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=1,
            total_pages=1,
            has_next=False,
            has_prev=False,
        ),
    )


@router.get(
    "/books/{book_id}",
    response_model=NoteList,
    summary="List book notes",
)
async def list_book_notes(
    user_id: CurrentUserId,
    book_id: UUID,
    pagination: Pagination,
) -> NoteList:
    """Return paginated list of notes for a specific book."""
    return NoteList(
        notes=[_example_note(book_id=book_id)],
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
    "/books/{book_id}",
    response_model=Note,
    status_code=status.HTTP_201_CREATED,
    summary="Create note",
)
async def create_note(
    user_id: CurrentUserId,
    book_id: UUID,
    request: CreateNoteRequest,
) -> Note:
    """Create a new note for a book."""
    return Note(
        note_id=uuid4(),
        book_id=book_id,
        title=request.title,
        content=request.content,
        is_pinned=request.is_pinned,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/{note_id}",
    response_model=Note,
    summary="Get note details",
)
async def get_note(
    user_id: CurrentUserId,
    note_id: UUID,
) -> Note:
    """Return detailed information about a note."""
    return _example_note(note_id)


@router.patch(
    "/{note_id}",
    response_model=Note,
    summary="Update note",
)
async def update_note(
    user_id: CurrentUserId,
    note_id: UUID,
    request: UpdateNoteRequest,
) -> Note:
    """Update a note's content."""
    note = _example_note(note_id)
    if request.title is not None:
        note.title = request.title
    if request.content is not None:
        note.content = request.content
    if request.is_pinned is not None:
        note.is_pinned = request.is_pinned
    return note


@router.delete(
    "/{note_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete note",
)
async def delete_note(
    user_id: CurrentUserId,
    note_id: UUID,
) -> Response:
    """Delete a note."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
