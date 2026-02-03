"""Shelf-related schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ShelfSummary(BaseModel):
    """Minimal shelf information."""

    model_config = ConfigDict(from_attributes=True)

    shelf_id: UUID
    name: str
    color: str | None = None


class Shelf(BaseModel):
    """Full shelf response schema."""

    model_config = ConfigDict(from_attributes=True)

    shelf_id: UUID
    name: str
    description: str | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: str | None = None
    is_default: bool = False
    is_smart: bool = False
    smart_query: str | None = None
    sort_order: int | None = None
    parent_shelf_id: UUID | None = None
    book_count: int | None = None
    children: list["Shelf"] | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class ShelfList(BaseModel):
    """Shelf list response."""

    shelves: list[Shelf]


class CreateShelfRequest(BaseModel):
    """Shelf creation request."""

    name: str = Field(..., max_length=100)
    description: str | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: str | None = None
    parent_shelf_id: UUID | None = None
    is_smart: bool = False
    smart_query: str | None = None
    sort_order: int | None = None


class UpdateShelfRequest(BaseModel):
    """Shelf update request."""

    name: str | None = Field(None, max_length=100)
    description: str | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: str | None = None
    parent_shelf_id: UUID | None = None
    is_smart: bool | None = None
    smart_query: str | None = None
    sort_order: int | None = None


# Self-reference for children
Shelf.model_rebuild()
