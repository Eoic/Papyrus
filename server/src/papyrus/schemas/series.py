"""Series-related schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from papyrus.schemas.book import BookSummary


class Series(BaseModel):
    """Series response schema."""

    model_config = ConfigDict(from_attributes=True)

    series_id: UUID
    name: str
    description: str | None = None
    author: str | None = None
    total_books: int | None = None
    is_complete: bool = False
    book_count: int | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class SeriesWithBooks(Series):
    """Series with included books."""

    books: list[BookSummary] | None = None


class SeriesList(BaseModel):
    """Series list response."""

    series: list[Series]


class CreateSeriesRequest(BaseModel):
    """Series creation request."""

    name: str = Field(..., max_length=255)
    description: str | None = None
    author: str | None = None
    total_books: int | None = None
    is_complete: bool = False


class UpdateSeriesRequest(BaseModel):
    """Series update request."""

    name: str | None = Field(None, max_length=255)
    description: str | None = None
    author: str | None = None
    total_books: int | None = None
    is_complete: bool | None = None
