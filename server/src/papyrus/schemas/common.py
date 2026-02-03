"""Common schemas used across the API."""

from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ErrorDetail(BaseModel):
    """Error detail structure."""

    code: str = Field(..., examples=["VALIDATION_ERROR"])
    message: str = Field(..., examples=["Human-readable error message"])
    details: dict[str, Any] | None = None


class Error(BaseModel):
    """Standard error response."""

    error: ErrorDetail


class Pagination(BaseModel):
    """Pagination metadata."""

    page: int = Field(..., ge=1, examples=[1])
    limit: int = Field(..., ge=1, le=100, examples=[20])
    total: int = Field(..., ge=0, examples=[150])
    total_pages: int = Field(..., ge=0, examples=[8])
    has_next: bool = Field(..., examples=[True])
    has_prev: bool = Field(..., examples=[False])


class MessageResponse(BaseModel):
    """Simple message response."""

    message: str


class BaseSchema(BaseModel):
    """Base schema with common configuration."""

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
