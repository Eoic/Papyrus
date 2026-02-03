"""Annotation-related schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from papyrus.schemas.common import Pagination


class Annotation(BaseModel):
    """Annotation response schema."""

    model_config = ConfigDict(from_attributes=True)

    annotation_id: UUID
    book_id: UUID
    book_title: str | None = None
    selected_text: str
    note: str | None = None
    highlight_color: str = Field(..., pattern=r"^#[0-9A-Fa-f]{6}$")
    start_position: str
    end_position: str
    chapter_title: str | None = None
    chapter_index: int | None = None
    page_number: int | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class AnnotationList(BaseModel):
    """Paginated annotation list response."""

    annotations: list[Annotation]
    pagination: Pagination


class CreateAnnotationRequest(BaseModel):
    """Annotation creation request."""

    selected_text: str
    note: str | None = None
    highlight_color: str = Field("#FFEB3B", pattern=r"^#[0-9A-Fa-f]{6}$")
    start_position: str = Field(..., description="CFI or offset")
    end_position: str
    chapter_title: str | None = None
    chapter_index: int | None = None
    page_number: int | None = None


class UpdateAnnotationRequest(BaseModel):
    """Annotation update request."""

    note: str | None = None
    highlight_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
