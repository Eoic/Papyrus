"""File-related schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class FileInfo(BaseModel):
    """File information response schema."""

    model_config = ConfigDict(from_attributes=True)

    file_path: str = Field(..., description="Relative path in storage")
    file_format: str | None = None
    file_size: int | None = None
    file_hash: str | None = Field(None, description="SHA-256 checksum")
    storage_backend_id: UUID | None = None
    uploaded_at: datetime | None = None
