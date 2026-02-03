"""Bookmark-related schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class Bookmark(BaseModel):
    """Bookmark response schema."""

    model_config = ConfigDict(from_attributes=True)

    bookmark_id: UUID
    book_id: UUID
    position: str
    page_number: int | None = None
    chapter_title: str | None = None
    note: str | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    created_at: datetime | None = None


class BookmarkList(BaseModel):
    """Bookmark list response."""

    bookmarks: list[Bookmark]


class CreateBookmarkRequest(BaseModel):
    """Bookmark creation request."""

    position: str = Field(..., description="CFI, page number, or offset")
    page_number: int | None = None
    chapter_title: str | None = None
    note: str | None = Field(None, max_length=500)
    color: str = Field("#FF5722", pattern=r"^#[0-9A-Fa-f]{6}$")


class UpdateBookmarkRequest(BaseModel):
    """Bookmark update request."""

    note: str | None = Field(None, max_length=500)
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
