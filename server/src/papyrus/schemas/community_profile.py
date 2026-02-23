"""Community profile schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from papyrus.schemas.common import BaseSchema


class CommunityProfile(BaseSchema):
    user_id: UUID
    username: str | None = None
    display_name: str
    bio: str | None = None
    avatar_url: str | None = None
    profile_visibility: str = "public"
    follower_count: int = 0
    following_count: int = 0
    book_count: int = 0
    review_count: int = 0
    is_following: bool = False
    is_friend: bool = False
    created_at: datetime | None = None


class UpdateProfileRequest(BaseModel):
    username: str | None = Field(None, min_length=3, max_length=30, pattern=r"^[a-zA-Z0-9_]+$")
    display_name: str | None = Field(None, min_length=1, max_length=100)
    bio: str | None = Field(None, max_length=500)
    avatar_url: str | None = Field(None, max_length=500)
    profile_visibility: str | None = Field(None, pattern=r"^(public|friends_only|private)$")
