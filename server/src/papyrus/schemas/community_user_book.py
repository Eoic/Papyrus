"""User book tracking schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from papyrus.schemas.common import BaseSchema, Pagination


class UserBookResponse(BaseSchema):
    user_id: UUID
    catalog_book_id: UUID
    book_title: str | None = None
    book_author: str | None = None
    book_cover_url: str | None = None
    status: str = "want_to_read"
    visibility: str = "public"
    started_at: datetime | None = None
    finished_at: datetime | None = None
    progress: float | None = None
    created_at: datetime | None = None


class UserBookList(BaseModel):
    books: list[UserBookResponse]
    pagination: Pagination


class CreateUserBookRequest(BaseModel):
    catalog_book_id: UUID
    status: str = Field("want_to_read", pattern=r"^(want_to_read|reading|read|dnf|paused)$")
    visibility: str = Field("public", pattern=r"^(public|friends|private)$")


class UpdateUserBookRequest(BaseModel):
    status: str | None = Field(None, pattern=r"^(want_to_read|reading|read|dnf|paused)$")
    visibility: str | None = Field(None, pattern=r"^(public|friends|private)$")
    progress: float | None = Field(None, ge=0, le=1)
