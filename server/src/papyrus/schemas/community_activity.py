"""Activity feed schemas."""

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel

from papyrus.schemas.common import BaseSchema, Pagination


class ActivityUser(BaseModel):
    user_id: UUID
    display_name: str
    username: str | None = None
    avatar_url: str | None = None


class ActivityBook(BaseModel):
    catalog_book_id: UUID
    title: str
    author: str
    cover_url: str | None = None


class ActivityResponse(BaseSchema):
    activity_id: UUID
    user: ActivityUser
    activity_type: str
    description: str
    book: ActivityBook | None = None
    metadata: dict[str, Any] | None = None
    created_at: datetime


class ActivityFeed(BaseModel):
    activities: list[ActivityResponse]
    pagination: Pagination
