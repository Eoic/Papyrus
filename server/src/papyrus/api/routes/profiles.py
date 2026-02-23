"""Community profile routes."""

from datetime import UTC, datetime
from uuid import uuid4

from fastapi import APIRouter

from papyrus.api.deps import CurrentUserId
from papyrus.schemas.community_profile import CommunityProfile, UpdateProfileRequest

router = APIRouter()


@router.get("/me", response_model=CommunityProfile, summary="Get own community profile")
async def get_own_profile(user_id: CurrentUserId) -> CommunityProfile:
    """Return the authenticated user's community profile."""
    return CommunityProfile(
        user_id=user_id,
        username=None,
        display_name="Example User",
        bio=None,
        avatar_url=None,
        profile_visibility="public",
        follower_count=0,
        following_count=0,
        book_count=0,
        review_count=0,
        is_following=False,
        is_friend=False,
        created_at=datetime.now(UTC),
    )


@router.patch("/me", response_model=CommunityProfile, summary="Update community profile")
async def update_profile(
    user_id: CurrentUserId, request: UpdateProfileRequest
) -> CommunityProfile:
    """Update the authenticated user's community profile."""
    return CommunityProfile(
        user_id=user_id,
        username=request.username,
        display_name=request.display_name or "Example User",
        bio=request.bio,
        avatar_url=request.avatar_url,
        profile_visibility=request.profile_visibility or "public",
        follower_count=0,
        following_count=0,
        book_count=0,
        review_count=0,
        is_following=False,
        is_friend=False,
        created_at=datetime.now(UTC),
    )


@router.get(
    "/{username}", response_model=CommunityProfile, summary="Get user profile by username"
)
async def get_profile_by_username(
    user_id: CurrentUserId, username: str
) -> CommunityProfile:
    """Return a user's public community profile."""
    return CommunityProfile(
        user_id=uuid4(),
        username=username,
        display_name=username.title(),
        bio=None,
        avatar_url=None,
        profile_visibility="public",
        follower_count=5,
        following_count=3,
        book_count=12,
        review_count=4,
        is_following=False,
        is_friend=False,
        created_at=datetime.now(UTC),
    )
