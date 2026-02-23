"""Social routes (follow, block)."""

from uuid import UUID

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId, Pagination
from papyrus.schemas.common import Pagination as PaginationSchema
from papyrus.schemas.social import FollowList

router = APIRouter()


@router.post("/follow/{target_user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def follow_user(user_id: CurrentUserId, target_user_id: UUID) -> Response:
    """Follow a user."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/follow/{target_user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unfollow_user(user_id: CurrentUserId, target_user_id: UUID) -> Response:
    """Unfollow a user."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/followers", response_model=FollowList, summary="List followers")
async def list_followers(user_id: CurrentUserId, pagination: Pagination) -> FollowList:
    """List users who follow the authenticated user."""
    return FollowList(
        users=[],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=0,
            total_pages=0,
            has_next=False,
            has_prev=False,
        ),
    )


@router.get("/following", response_model=FollowList, summary="List following")
async def list_following(user_id: CurrentUserId, pagination: Pagination) -> FollowList:
    """List users the authenticated user follows."""
    return FollowList(
        users=[],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=0,
            total_pages=0,
            has_next=False,
            has_prev=False,
        ),
    )


@router.get("/friends", response_model=FollowList, summary="List friends")
async def list_friends(user_id: CurrentUserId, pagination: Pagination) -> FollowList:
    """List mutual follows (friends)."""
    return FollowList(
        users=[],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=0,
            total_pages=0,
            has_next=False,
            has_prev=False,
        ),
    )


@router.post("/block/{target_user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def block_user(user_id: CurrentUserId, target_user_id: UUID) -> Response:
    """Block a user."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/block/{target_user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unblock_user(user_id: CurrentUserId, target_user_id: UUID) -> Response:
    """Unblock a user."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
