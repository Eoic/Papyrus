"""Social feature schemas (follow, block)."""

from uuid import UUID

from pydantic import BaseModel

from papyrus.schemas.common import BaseSchema, Pagination


class FollowUser(BaseSchema):
    user_id: UUID
    username: str | None = None
    display_name: str
    avatar_url: str | None = None
    is_following: bool = False
    is_friend: bool = False


class FollowList(BaseModel):
    users: list[FollowUser]
    pagination: Pagination
