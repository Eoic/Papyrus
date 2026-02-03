"""Goal-related schemas."""

from datetime import date, datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class GoalType(str, Enum):
    """Type of reading goal."""

    BOOKS_COUNT = "books_count"
    PAGES_COUNT = "pages_count"
    READING_TIME = "reading_time"


class TimePeriod(str, Enum):
    """Goal time period."""

    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"
    CUSTOM = "custom"


class Goal(BaseModel):
    """Goal response schema."""

    model_config = ConfigDict(from_attributes=True)

    goal_id: UUID
    title: str
    description: str | None = None
    goal_type: GoalType
    target_value: int
    current_value: int | None = None
    progress_percentage: float | None = None
    time_period: TimePeriod
    start_date: date
    end_date: date
    is_active: bool = True
    is_completed: bool = False
    completed_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class GoalList(BaseModel):
    """Goal list response."""

    goals: list[Goal]


class CreateGoalRequest(BaseModel):
    """Goal creation request."""

    title: str = Field(..., max_length=255)
    description: str | None = None
    goal_type: GoalType
    target_value: int = Field(..., ge=1)
    time_period: TimePeriod
    start_date: date
    end_date: date


class UpdateGoalRequest(BaseModel):
    """Goal update request."""

    title: str | None = Field(None, max_length=255)
    description: str | None = None
    target_value: int | None = Field(None, ge=1)
    end_date: date | None = None
    is_active: bool | None = None
