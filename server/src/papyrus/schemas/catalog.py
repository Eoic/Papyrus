"""Community book catalog schemas."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from papyrus.schemas.common import BaseSchema, Pagination


class CatalogBookSummary(BaseSchema):
    catalog_book_id: UUID
    title: str
    author: str
    cover_url: str | None = None
    average_rating: float | None = None
    rating_count: int = 0
    review_count: int = 0


class CatalogBookDetail(BaseSchema):
    catalog_book_id: UUID
    open_library_id: str | None = None
    isbn: str | None = None
    title: str
    authors: list[str] | None = None
    cover_url: str | None = None
    description: str | None = None
    page_count: int | None = None
    published_date: date | None = None
    genres: list[str] | None = None
    average_rating: float | None = None
    rating_count: int = 0
    review_count: int = 0
    added_by_user_id: UUID | None = None
    verified: bool = False
    created_at: datetime | None = None


class CatalogBookList(BaseModel):
    books: list[CatalogBookSummary]
    pagination: Pagination


class CreateCatalogBookRequest(BaseModel):
    title: str = Field(..., max_length=500)
    authors: list[str] = Field(..., min_length=1)
    isbn: str | None = Field(None, max_length=13)
    cover_url: str | None = Field(None, max_length=500)
    description: str | None = None
    page_count: int | None = Field(None, ge=1)
    published_date: date | None = None
    genres: list[str] | None = None
    open_library_id: str | None = Field(None, max_length=50)


class CatalogSearchResult(BaseModel):
    local_results: list[CatalogBookSummary]
    open_library_results: list[CatalogBookSummary]
