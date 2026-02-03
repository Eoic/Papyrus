"""Reading progress and statistics routes."""

from datetime import UTC, date, datetime
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Query

from papyrus.api.deps import CurrentUserId, Pagination
from papyrus.schemas import (
    CreateReadingSessionRequest,
    ReadingSession,
    ReadingSessionList,
    ReadingStatistics,
)
from papyrus.schemas import (
    Pagination as PaginationSchema,
)
from papyrus.schemas.progress import (
    BookBreakdown,
    DailyBreakdown,
    StatisticsPeriod,
    StatisticsTotals,
)

router = APIRouter()


def _example_session(session_id: UUID | None = None, book_id: UUID | None = None) -> ReadingSession:
    """Create an example reading session for responses."""
    return ReadingSession(
        session_id=session_id or uuid4(),
        book_id=book_id or uuid4(),
        book_title="Example Book",
        start_time=datetime.now(UTC),
        end_time=datetime.now(UTC),
        start_position=0.25,
        end_position=0.35,
        pages_read=20,
        duration_minutes=30,
        device_type="tablet",
        device_name="iPad Pro",
        created_at=datetime.now(UTC),
    )


@router.get(
    "/sessions",
    response_model=ReadingSessionList,
    summary="List reading sessions",
)
async def list_reading_sessions(
    user_id: CurrentUserId,
    pagination: Pagination,
    book_id: UUID | None = None,
    start_date: date | None = None,
    end_date: date | None = None,
) -> ReadingSessionList:
    """Return paginated list of reading sessions."""
    return ReadingSessionList(
        sessions=[_example_session()],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=1,
            total_pages=1,
            has_next=False,
            has_prev=False,
        ),
    )


@router.post(
    "/sessions",
    response_model=ReadingSession,
    summary="Record reading session",
)
async def create_reading_session(
    user_id: CurrentUserId,
    request: CreateReadingSessionRequest,
) -> ReadingSession:
    """Record a new reading session."""
    duration = None
    if request.end_time and request.start_time:
        duration = int((request.end_time - request.start_time).total_seconds() / 60)

    return ReadingSession(
        session_id=uuid4(),
        book_id=request.book_id,
        start_time=request.start_time,
        end_time=request.end_time,
        start_position=request.start_position,
        end_position=request.end_position,
        pages_read=request.pages_read,
        duration_minutes=duration,
        device_type=request.device_type,
        device_name=request.device_name,
        created_at=datetime.now(UTC),
    )


@router.get(
    "/statistics",
    response_model=ReadingStatistics,
    summary="Get reading statistics",
)
async def get_reading_statistics(
    user_id: CurrentUserId,
    start_date: Annotated[
        date | None, Query(description="Start date for statistics period")
    ] = None,
    end_date: Annotated[date | None, Query(description="End date for statistics period")] = None,
) -> ReadingStatistics:
    """Return reading statistics for the specified period."""
    today = date.today()
    period_start = start_date or today.replace(day=1)
    period_end = end_date or today

    return ReadingStatistics(
        period=StatisticsPeriod(
            start_date=period_start,
            end_date=period_end,
        ),
        totals=StatisticsTotals(
            reading_time_minutes=450,
            pages_read=150,
            books_completed=2,
            sessions_count=15,
            average_session_minutes=30.0,
            reading_days=10,
            current_streak=5,
            longest_streak=7,
        ),
        daily_breakdown=[
            DailyBreakdown(
                date=today,
                reading_time_minutes=45,
                pages_read=15,
                sessions_count=2,
            )
        ],
        books_breakdown=[
            BookBreakdown(
                book_id=uuid4(),
                title="Example Book",
                reading_time_minutes=200,
                pages_read=80,
                sessions_count=7,
            )
        ],
    )
