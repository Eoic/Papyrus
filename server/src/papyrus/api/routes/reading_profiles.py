"""Reading profile routes."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import (
    CreateReadingProfileRequest,
    ReadingMode,
    ReadingProfile,
    ReadingProfileList,
    TextAlign,
    ThemeMode,
    UpdateReadingProfileRequest,
)

router = APIRouter()


def _example_profile(profile_id: UUID | None = None) -> ReadingProfile:
    """Create an example reading profile for responses."""
    return ReadingProfile(
        profile_id=profile_id or uuid4(),
        name="Default Profile",
        is_default=True,
        font_family="Georgia",
        font_size=16,
        font_weight=400,
        line_height=1.5,
        letter_spacing=0,
        paragraph_spacing=1.0,
        text_align=TextAlign.JUSTIFY,
        margin_horizontal=20,
        margin_vertical=20,
        background_color="#FFFFFF",
        text_color="#000000",
        link_color="#0066CC",
        selection_color="#B3D4FC",
        theme_mode=ThemeMode.LIGHT,
        reading_mode=ReadingMode.PAGINATED,
        page_turn_animation=True,
        column_count=1,
        hyphenation=True,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=ReadingProfileList,
    summary="List reading profiles",
)
async def list_reading_profiles(user_id: CurrentUserId) -> ReadingProfileList:
    """Return all reading profiles for the user."""
    return ReadingProfileList(profiles=[_example_profile()])


@router.post(
    "",
    response_model=ReadingProfile,
    status_code=status.HTTP_201_CREATED,
    summary="Create reading profile",
)
async def create_reading_profile(
    user_id: CurrentUserId,
    request: CreateReadingProfileRequest,
) -> ReadingProfile:
    """Create a new reading profile."""
    return ReadingProfile(
        profile_id=uuid4(),
        name=request.name,
        is_default=request.is_default,
        font_family=request.font_family,
        font_size=request.font_size,
        font_weight=request.font_weight,
        line_height=request.line_height,
        letter_spacing=request.letter_spacing,
        paragraph_spacing=request.paragraph_spacing,
        text_align=request.text_align,
        margin_horizontal=request.margin_horizontal,
        margin_vertical=request.margin_vertical,
        background_color=request.background_color,
        text_color=request.text_color,
        link_color=request.link_color,
        selection_color=request.selection_color,
        theme_mode=request.theme_mode,
        reading_mode=request.reading_mode,
        page_turn_animation=request.page_turn_animation,
        column_count=request.column_count,
        hyphenation=request.hyphenation,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/{profile_id}",
    response_model=ReadingProfile,
    summary="Get reading profile",
)
async def get_reading_profile(
    user_id: CurrentUserId,
    profile_id: UUID,
) -> ReadingProfile:
    """Return detailed information about a reading profile."""
    return _example_profile(profile_id)


@router.patch(
    "/{profile_id}",
    response_model=ReadingProfile,
    summary="Update reading profile",
)
async def update_reading_profile(
    user_id: CurrentUserId,
    profile_id: UUID,
    request: UpdateReadingProfileRequest,
) -> ReadingProfile:
    """Update a reading profile."""
    profile = _example_profile(profile_id)
    for field, value in request.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    return profile


@router.delete(
    "/{profile_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete reading profile",
)
async def delete_reading_profile(
    user_id: CurrentUserId,
    profile_id: UUID,
) -> Response:
    """Delete a reading profile."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/{profile_id}/set-default",
    response_model=ReadingProfile,
    summary="Set as default profile",
)
async def set_default_reading_profile(
    user_id: CurrentUserId,
    profile_id: UUID,
) -> ReadingProfile:
    """Set a reading profile as the default."""
    profile = _example_profile(profile_id)
    profile.is_default = True
    return profile
