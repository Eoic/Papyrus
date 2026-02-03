"""Book-related schemas."""

from datetime import date, datetime
from enum import StrEnum
from typing import TYPE_CHECKING, Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class ReadingStatus(StrEnum):
    """Book reading status."""

    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    PAUSED = "paused"
    ABANDONED = "abandoned"


class FileFormat(StrEnum):
    """Supported ebook file formats."""

    EPUB = "epub"
    PDF = "pdf"
    MOBI = "mobi"
    AZW3 = "azw3"
    TXT = "txt"
    CBR = "cbr"
    CBZ = "cbz"


class BookSummary(BaseModel):
    """Minimal book information for lists."""

    model_config = ConfigDict(from_attributes=True)

    book_id: UUID
    title: str
    author: str | None = None
    cover_image_url: HttpUrl | str | None = None
    reading_status: ReadingStatus | None = None
    current_position: float | None = None
    is_favorite: bool = False
    rating: int | None = Field(None, ge=1, le=5)


class Book(BaseModel):
    """Full book response schema."""

    model_config = ConfigDict(from_attributes=True)

    book_id: UUID
    title: str
    subtitle: str | None = None
    author: str | None = None
    co_authors: list[str] | None = None
    isbn: str | None = None
    isbn13: str | None = None
    publication_date: date | None = None
    publisher: str | None = None
    language: str | None = Field(None, examples=["en"])
    page_count: int | None = None
    description: str | None = None
    cover_image_url: HttpUrl | str | None = None
    series_id: UUID | None = None
    series_name: str | None = None
    series_number: float | None = None
    file_path: str | None = None
    file_format: FileFormat | None = None
    file_size: int | None = None
    file_hash: str | None = None
    storage_backend_id: UUID | None = None
    is_physical: bool = False
    physical_location: str | None = None
    lent_to: str | None = None
    lent_at: datetime | None = None
    is_favorite: bool = False
    rating: int | None = Field(None, ge=1, le=5)
    reading_status: ReadingStatus | None = None
    current_page: int | None = None
    current_position: float | None = Field(None, ge=0, le=1)
    current_cfi: str | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    added_at: datetime | None = None
    last_read_at: datetime | None = None
    custom_metadata: dict[str, Any] | None = None
    is_ocr_processed: bool | None = None
    ocr_confidence: float | None = None
    updated_at: datetime | None = None
    shelves: list["ShelfSummary"] | None = None
    tags: list["Tag"] | None = None


class BookCreate(BaseModel):
    """Book creation request."""

    title: str = Field(..., max_length=500)
    subtitle: str | None = Field(None, max_length=500)
    author: str = Field(..., max_length=255)
    co_authors: list[str] | None = None
    isbn: str | None = None
    isbn13: str | None = None
    publication_date: date | None = None
    publisher: str | None = None
    language: str | None = Field("en")
    page_count: int | None = None
    description: str | None = None
    cover_image_url: HttpUrl | str | None = None
    series_id: UUID | None = None
    series_number: float | None = None
    file_path: str | None = Field(None, description="Path returned from file upload")
    file_format: str | None = None
    file_size: int | None = None
    file_hash: str | None = None
    storage_backend_id: UUID | None = None
    is_physical: bool = False
    physical_location: str | None = None
    custom_metadata: dict[str, Any] | None = None
    shelf_ids: list[UUID] | None = None
    tag_ids: list[UUID] | None = Field(None, max_length=10)


class BookUpdate(BaseModel):
    """Book update request."""

    title: str | None = None
    subtitle: str | None = None
    author: str | None = None
    co_authors: list[str] | None = None
    isbn: str | None = None
    isbn13: str | None = None
    publication_date: date | None = None
    publisher: str | None = None
    language: str | None = None
    page_count: int | None = None
    description: str | None = None
    cover_image_url: HttpUrl | str | None = None
    series_id: UUID | None = None
    series_number: float | None = None
    is_physical: bool | None = None
    physical_location: str | None = None
    lent_to: str | None = None
    lent_at: datetime | None = None
    is_favorite: bool | None = None
    rating: int | None = Field(None, ge=1, le=5)
    reading_status: ReadingStatus | None = None
    custom_metadata: dict[str, Any] | None = None


class ReadingProgress(BaseModel):
    """Reading progress information."""

    model_config = ConfigDict(from_attributes=True)

    book_id: UUID
    reading_status: ReadingStatus | None = None
    current_page: int | None = None
    current_position: float | None = Field(None, ge=0, le=1)
    current_cfi: str | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    last_read_at: datetime | None = None
    total_reading_time_minutes: int | None = None
    sessions_count: int | None = None


class UpdateProgressRequest(BaseModel):
    """Update reading progress request."""

    reading_status: ReadingStatus | None = None
    current_page: int | None = None
    current_position: float | None = Field(None, ge=0, le=1)
    current_cfi: str | None = None


class MetadataSearchResult(BaseModel):
    """Book metadata search result from external sources."""

    source: str = Field(..., examples=["open_library", "google_books"])
    title: str
    author: str | None = None
    isbn: str | None = None
    isbn13: str | None = None
    publication_date: date | None = None
    publisher: str | None = None
    description: str | None = None
    cover_image_url: HttpUrl | str | None = None
    page_count: int | None = None
    language: str | None = None


class BookList(BaseModel):
    """Paginated book list response."""

    books: list[Book]
    pagination: "Pagination"


# Imports at bottom to avoid circular imports
if TYPE_CHECKING:
    from papyrus.schemas.common import Pagination
    from papyrus.schemas.shelf import ShelfSummary
    from papyrus.schemas.tag import Tag
else:
    from papyrus.schemas.common import Pagination
    from papyrus.schemas.shelf import ShelfSummary
    from papyrus.schemas.tag import Tag

Book.model_rebuild()
BookList.model_rebuild()
