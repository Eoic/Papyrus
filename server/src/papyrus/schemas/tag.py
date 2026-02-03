"""Tag-related schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class Tag(BaseModel):
    """Tag response schema."""

    model_config = ConfigDict(from_attributes=True)

    tag_id: UUID
    name: str
    color: str = Field(..., pattern=r"^#[0-9A-Fa-f]{6}$")
    description: str | None = None
    usage_count: int | None = None
    created_at: datetime | None = None


class TagList(BaseModel):
    """Tag list response."""

    tags: list[Tag]


class CreateTagRequest(BaseModel):
    """Tag creation request."""

    name: str = Field(..., max_length=50)
    color: str = Field(..., pattern=r"^#[0-9A-Fa-f]{6}$")
    description: str | None = None


class UpdateTagRequest(BaseModel):
    """Tag update request."""

    name: str | None = Field(None, max_length=50)
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    description: str | None = None
