"""Reading session and statistics schemas."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from papyrus.schemas.common import Pagination


class ReadingSession(BaseModel):
    """Reading session response schema."""

    model_config = ConfigDict(from_attributes=True)

    session_id: UUID
    book_id: UUID
    book_title: str | None = None
    start_time: datetime
    end_time: datetime | None = None
    start_position: float | None = None
    end_position: float | None = None
    pages_read: int | None = None
    duration_minutes: int | None = Field(
        None, description="Calculated from start_time and end_time"
    )
    device_type: str | None = None
    device_name: str | None = None
    created_at: datetime | None = None


class ReadingSessionList(BaseModel):
    """Paginated reading session list response."""

    sessions: list[ReadingSession]
    pagination: Pagination


class CreateReadingSessionRequest(BaseModel):
    """Reading session creation request."""

    book_id: UUID
    start_time: datetime
    end_time: datetime | None = None
    start_position: float | None = Field(None, ge=0, le=1)
    end_position: float | None = Field(None, ge=0, le=1)
    pages_read: int | None = None
    device_type: str | None = None
    device_name: str | None = None


class DailyBreakdown(BaseModel):
    """Daily reading statistics."""

    date: date
    reading_time_minutes: int
    pages_read: int
    sessions_count: int


class BookBreakdown(BaseModel):
    """Per-book reading statistics."""

    book_id: UUID
    title: str
    reading_time_minutes: int
    pages_read: int
    sessions_count: int


class StatisticsTotals(BaseModel):
    """Total reading statistics."""

    reading_time_minutes: int
    pages_read: int
    books_completed: int
    sessions_count: int
    average_session_minutes: float
    reading_days: int
    current_streak: int
    longest_streak: int


class StatisticsPeriod(BaseModel):
    """Statistics period."""

    start_date: date
    end_date: date


class ReadingStatistics(BaseModel):
    """Comprehensive reading statistics response."""

    period: StatisticsPeriod
    totals: StatisticsTotals
    daily_breakdown: list[DailyBreakdown]
    books_breakdown: list[BookBreakdown]
