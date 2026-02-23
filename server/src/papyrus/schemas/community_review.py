"""Review schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from papyrus.schemas.common import BaseSchema, Pagination


class ReviewResponse(BaseSchema):
    review_id: UUID
    user_id: UUID
    catalog_book_id: UUID
    author_display_name: str | None = None
    author_username: str | None = None
    author_avatar_url: str | None = None
    title: str | None = None
    body: str
    contains_spoilers: bool = False
    visibility: str = "public"
    like_count: int = 0
    helpful_count: int = 0
    created_at: datetime | None = None
    updated_at: datetime | None = None


class ReviewList(BaseModel):
    reviews: list[ReviewResponse]
    pagination: Pagination


class CreateReviewRequest(BaseModel):
    catalog_book_id: UUID
    title: str | None = Field(None, max_length=255)
    body: str = Field(..., min_length=10, max_length=10000)
    contains_spoilers: bool = False
    visibility: str = Field("public", pattern=r"^(public|friends|private)$")


class UpdateReviewRequest(BaseModel):
    title: str | None = Field(None, max_length=255)
    body: str | None = Field(None, min_length=10, max_length=10000)
    contains_spoilers: bool | None = None
    visibility: str | None = Field(None, pattern=r"^(public|friends|private)$")


class ReviewReactionRequest(BaseModel):
    reaction_type: str = Field(..., pattern=r"^(like|helpful)$")
