"""Goal routes."""

from datetime import UTC, date, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import (
    CreateGoalRequest,
    Goal,
    GoalList,
    GoalType,
    TimePeriod,
    UpdateGoalRequest,
)

router = APIRouter()


def _example_goal(goal_id: UUID | None = None) -> Goal:
    """Create an example goal for responses."""
    today = date.today()
    return Goal(
        goal_id=goal_id or uuid4(),
        title="Read 12 books this year",
        description="My annual reading goal",
        goal_type=GoalType.BOOKS_COUNT,
        target_value=12,
        current_value=5,
        progress_percentage=41.67,
        time_period=TimePeriod.YEARLY,
        start_date=today.replace(month=1, day=1),
        end_date=today.replace(month=12, day=31),
        is_active=True,
        is_completed=False,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=GoalList,
    summary="List all goals",
)
async def list_goals(
    user_id: CurrentUserId,
    is_active: bool | None = None,
) -> GoalList:
    """Return all goals for the user."""
    return GoalList(goals=[_example_goal()])


@router.post(
    "",
    response_model=Goal,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new goal",
)
async def create_goal(
    user_id: CurrentUserId,
    request: CreateGoalRequest,
) -> Goal:
    """Create a new reading goal."""
    return Goal(
        goal_id=uuid4(),
        title=request.title,
        description=request.description,
        goal_type=request.goal_type,
        target_value=request.target_value,
        current_value=0,
        progress_percentage=0.0,
        time_period=request.time_period,
        start_date=request.start_date,
        end_date=request.end_date,
        is_active=True,
        is_completed=False,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/{goal_id}",
    response_model=Goal,
    summary="Get goal details",
)
async def get_goal(
    user_id: CurrentUserId,
    goal_id: UUID,
) -> Goal:
    """Return detailed information about a goal."""
    return _example_goal(goal_id)


@router.patch(
    "/{goal_id}",
    response_model=Goal,
    summary="Update goal",
)
async def update_goal(
    user_id: CurrentUserId,
    goal_id: UUID,
    request: UpdateGoalRequest,
) -> Goal:
    """Update goal properties."""
    goal = _example_goal(goal_id)
    if request.title is not None:
        goal.title = request.title
    if request.description is not None:
        goal.description = request.description
    if request.target_value is not None:
        goal.target_value = request.target_value
    if request.end_date is not None:
        goal.end_date = request.end_date
    if request.is_active is not None:
        goal.is_active = request.is_active
    return goal


@router.delete(
    "/{goal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete goal",
)
async def delete_goal(
    user_id: CurrentUserId,
    goal_id: UUID,
) -> Response:
    """Delete a goal."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
