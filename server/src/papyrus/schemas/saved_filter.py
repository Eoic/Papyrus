"""Saved filter schemas."""

from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class FilterType(str, Enum):
    """Filter type options."""

    SEARCH = "search"
    SHELF = "shelf"
    CUSTOM = "custom"


class SavedFilter(BaseModel):
    """Saved filter response schema."""

    model_config = ConfigDict(from_attributes=True)

    filter_id: UUID
    name: str
    description: str | None = None
    query: str
    filter_type: FilterType | None = None
    icon: str | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    is_pinned: bool = False
    usage_count: int | None = None
    last_used_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class SavedFilterList(BaseModel):
    """Saved filter list response."""

    filters: list[SavedFilter]


class CreateSavedFilterRequest(BaseModel):
    """Saved filter creation request."""

    name: str = Field(..., max_length=100)
    description: str | None = None
    query: str = Field(..., max_length=1000)
    filter_type: FilterType | None = None
    icon: str | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    is_pinned: bool = False


class UpdateSavedFilterRequest(BaseModel):
    """Saved filter update request."""

    name: str | None = Field(None, max_length=100)
    description: str | None = None
    query: str | None = Field(None, max_length=1000)
    filter_type: FilterType | None = None
    icon: str | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    is_pinned: bool | None = None
