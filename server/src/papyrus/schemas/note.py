"""Note-related schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from papyrus.schemas.common import Pagination


class Note(BaseModel):
    """Note response schema."""

    model_config = ConfigDict(from_attributes=True)

    note_id: UUID
    book_id: UUID
    book_title: str | None = None
    title: str
    content: str
    is_pinned: bool = False
    created_at: datetime | None = None
    updated_at: datetime | None = None


class NoteList(BaseModel):
    """Paginated note list response."""

    notes: list[Note]
    pagination: Pagination


class CreateNoteRequest(BaseModel):
    """Note creation request."""

    title: str = Field(..., max_length=255)
    content: str
    is_pinned: bool = False


class UpdateNoteRequest(BaseModel):
    """Note update request."""

    title: str | None = Field(None, max_length=255)
    content: str | None = None
    is_pinned: bool | None = None
