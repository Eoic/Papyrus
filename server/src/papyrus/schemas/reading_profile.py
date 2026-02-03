"""Reading profile schemas."""

from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class TextAlign(str, Enum):
    """Text alignment options."""

    LEFT = "left"
    RIGHT = "right"
    CENTER = "center"
    JUSTIFY = "justify"


class ThemeMode(str, Enum):
    """Reader theme modes."""

    LIGHT = "light"
    DARK = "dark"
    SEPIA = "sepia"
    CUSTOM = "custom"


class ReadingMode(str, Enum):
    """Reading display modes."""

    PAGINATED = "paginated"
    CONTINUOUS = "continuous"


class ReadingProfile(BaseModel):
    """Reading profile response schema."""

    model_config = ConfigDict(from_attributes=True)

    profile_id: UUID
    name: str
    is_default: bool = False
    font_family: str | None = None
    font_size: int | None = Field(None, ge=8, le=72)
    font_weight: int | None = None
    line_height: float | None = None
    letter_spacing: float | None = None
    paragraph_spacing: float | None = None
    text_align: TextAlign | None = None
    margin_horizontal: int | None = None
    margin_vertical: int | None = None
    background_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    text_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    link_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    selection_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    theme_mode: ThemeMode | None = None
    reading_mode: ReadingMode | None = None
    page_turn_animation: bool | None = None
    column_count: int | None = Field(None, ge=1, le=3)
    hyphenation: bool | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class ReadingProfileList(BaseModel):
    """Reading profile list response."""

    profiles: list[ReadingProfile]


class CreateReadingProfileRequest(BaseModel):
    """Reading profile creation request."""

    name: str = Field(..., max_length=100)
    is_default: bool = False
    font_family: str = "Georgia"
    font_size: int = 16
    font_weight: int = 400
    line_height: float = 1.5
    letter_spacing: float = 0
    paragraph_spacing: float = 1.0
    text_align: TextAlign | None = None
    margin_horizontal: int = 20
    margin_vertical: int = 20
    background_color: str = Field("#FFFFFF", pattern=r"^#[0-9A-Fa-f]{6}$")
    text_color: str = Field("#000000", pattern=r"^#[0-9A-Fa-f]{6}$")
    link_color: str = Field("#0066CC", pattern=r"^#[0-9A-Fa-f]{6}$")
    selection_color: str = Field("#B3D4FC", pattern=r"^#[0-9A-Fa-f]{6}$")
    theme_mode: ThemeMode | None = None
    reading_mode: ReadingMode | None = None
    page_turn_animation: bool = True
    column_count: int = 1
    hyphenation: bool = True


class UpdateReadingProfileRequest(BaseModel):
    """Reading profile update request."""

    name: str | None = Field(None, max_length=100)
    font_family: str | None = None
    font_size: int | None = None
    font_weight: int | None = None
    line_height: float | None = None
    letter_spacing: float | None = None
    paragraph_spacing: float | None = None
    text_align: TextAlign | None = None
    margin_horizontal: int | None = None
    margin_vertical: int | None = None
    background_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    text_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    link_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    selection_color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    theme_mode: ThemeMode | None = None
    reading_mode: ReadingMode | None = None
    page_turn_animation: bool | None = None
    column_count: int | None = None
    hyphenation: bool | None = None
