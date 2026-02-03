"""User-related schemas."""

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, HttpUrl


class User(BaseModel):
    """User response schema."""

    model_config = ConfigDict(from_attributes=True)

    user_id: UUID
    email: EmailStr | None = None
    display_name: str
    avatar_url: HttpUrl | str | None = None
    is_anonymous: bool = False
    email_verified: bool = False
    created_at: datetime
    last_login_at: datetime | None = None


class UpdateUserRequest(BaseModel):
    """User profile update request."""

    display_name: str | None = Field(None, min_length=1, max_length=100)
    avatar_url: HttpUrl | str | None = None


class UserPreferences(BaseModel):
    """User preferences (flexible structure)."""

    model_config = ConfigDict(extra="allow")

    theme: str | None = Field(None, examples=["dark"])
    notifications_enabled: bool | None = Field(None, examples=[True])
    default_shelf: str | None = Field(None, examples=["Currently Reading"])
    sync_wifi_only: bool | None = Field(None, examples=[False])


class DeleteAccountRequest(BaseModel):
    """Account deletion request."""

    password: str = Field(..., description="Current password for confirmation")
