"""Rating schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from papyrus.schemas.common import BaseSchema


class RatingResponse(BaseSchema):
    user_id: UUID
    catalog_book_id: UUID
    score: int
    created_at: datetime | None = None
    updated_at: datetime | None = None


class CreateRatingRequest(BaseModel):
    catalog_book_id: UUID
    score: int = Field(..., ge=1, le=10)


class UpdateRatingRequest(BaseModel):
    score: int = Field(..., ge=1, le=10)


class RatingDistribution(BaseModel):
    score: int
    count: int


class BookRatingsSummary(BaseModel):
    catalog_book_id: UUID
    average_rating: float | None = None
    rating_count: int = 0
    distribution: list[RatingDistribution] = []
