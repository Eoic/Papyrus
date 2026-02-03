"""Tag routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import CreateTagRequest, Tag, TagList, UpdateTagRequest

router = APIRouter()


def _example_tag(tag_id: UUID | None = None) -> Tag:
    """Create an example tag for responses."""
    return Tag(
        tag_id=tag_id or uuid4(),
        name="Example Tag",
        color="#FF5722",
        description="An example tag",
        usage_count=0,
        created_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=TagList,
    summary="List all tags",
)
async def list_tags(user_id: CurrentUserId) -> TagList:
    """Return all tags for the user."""
    return TagList(tags=[_example_tag()])


@router.post(
    "",
    response_model=Tag,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new tag",
)
async def create_tag(
    user_id: CurrentUserId,
    request: CreateTagRequest,
) -> Tag:
    """Create a new tag."""
    return Tag(
        tag_id=uuid4(),
        name=request.name,
        color=request.color,
        description=request.description,
        usage_count=0,
        created_at=datetime.now(UTC),
    )


@router.get(
    "/{tag_id}",
    response_model=Tag,
    summary="Get tag details",
)
async def get_tag(
    user_id: CurrentUserId,
    tag_id: UUID,
) -> Tag:
    """Return detailed information about a tag."""
    return _example_tag(tag_id)


@router.patch(
    "/{tag_id}",
    response_model=Tag,
    summary="Update tag",
)
async def update_tag(
    user_id: CurrentUserId,
    tag_id: UUID,
    request: UpdateTagRequest,
) -> Tag:
    """Update tag properties."""
    tag = _example_tag(tag_id)
    if request.name:
        tag.name = request.name
    if request.color:
        tag.color = request.color
    if request.description:
        tag.description = request.description
    return tag


@router.delete(
    "/{tag_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete tag",
)
async def delete_tag(
    user_id: CurrentUserId,
    tag_id: UUID,
) -> Response:
    """Delete a tag. Removes from all books."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
