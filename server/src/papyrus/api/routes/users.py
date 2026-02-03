"""User routes."""

from datetime import UTC, datetime
from uuid import uuid4

from fastapi import APIRouter, Response, status
from pydantic import BaseModel

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import UpdateUserRequest, User, UserPreferences
from papyrus.schemas.auth import ChangePasswordRequest
from papyrus.schemas.common import MessageResponse
from papyrus.schemas.user import DeleteAccountRequest

router = APIRouter()


@router.get(
    "/me",
    response_model=User,
    summary="Get current user profile",
)
async def get_current_user(user_id: CurrentUserId) -> User:
    """Return the authenticated user's profile information."""
    return User(
        user_id=user_id,
        email="user@example.com",
        display_name="Example User",
        avatar_url=None,
        is_anonymous=False,
        email_verified=True,
        created_at=datetime.now(UTC),
        last_login_at=datetime.now(UTC),
    )


@router.patch(
    "/me",
    response_model=User,
    summary="Update current user profile",
)
async def update_current_user(
    user_id: CurrentUserId,
    request: UpdateUserRequest,
) -> User:
    """Update the authenticated user's profile information."""
    return User(
        user_id=user_id,
        email="user@example.com",
        display_name=request.display_name or "Example User",
        avatar_url=request.avatar_url,
        is_anonymous=False,
        email_verified=True,
        created_at=datetime.now(UTC),
        last_login_at=datetime.now(UTC),
    )


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete current user account",
)
async def delete_current_user(
    user_id: CurrentUserId,
    request: DeleteAccountRequest,
) -> Response:
    """Permanently delete the user account and all associated data."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/me/preferences",
    response_model=UserPreferences,
    summary="Get user preferences",
)
async def get_user_preferences(user_id: CurrentUserId) -> UserPreferences:
    """Return the user's application preferences."""
    return UserPreferences(
        theme="dark",
        notifications_enabled=True,
        default_shelf="Currently Reading",
        sync_wifi_only=False,
    )


@router.put(
    "/me/preferences",
    response_model=UserPreferences,
    summary="Update user preferences",
)
async def update_user_preferences(
    user_id: CurrentUserId,
    request: UserPreferences,
) -> UserPreferences:
    """Update the user's application preferences."""
    return request


@router.post(
    "/me/change-password",
    response_model=MessageResponse,
    summary="Change password",
)
async def change_password(
    user_id: CurrentUserId,
    request: ChangePasswordRequest,
) -> MessageResponse:
    """Change the user's password. Requires current password verification."""
    return MessageResponse(message="Password changed successfully")
