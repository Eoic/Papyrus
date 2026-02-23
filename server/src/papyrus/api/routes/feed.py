"""Activity feed routes."""

from fastapi import APIRouter

from papyrus.api.deps import CurrentUserId, Pagination
from papyrus.schemas.common import Pagination as PaginationSchema
from papyrus.schemas.community_activity import ActivityFeed

router = APIRouter()


@router.get("", response_model=ActivityFeed, summary="Personal feed")
async def get_personal_feed(user_id: CurrentUserId, pagination: Pagination) -> ActivityFeed:
    """Get activity feed from followed users."""
    return ActivityFeed(
        activities=[],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=0,
            total_pages=0,
            has_next=False,
            has_prev=False,
        ),
    )


@router.get("/global", response_model=ActivityFeed, summary="Global feed")
async def get_global_feed(user_id: CurrentUserId, pagination: Pagination) -> ActivityFeed:
    """Get global/trending activity feed."""
    return ActivityFeed(
        activities=[],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=0,
            total_pages=0,
            has_next=False,
            has_prev=False,
        ),
    )
