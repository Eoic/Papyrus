"""User model for community profiles."""

import enum
from datetime import datetime
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from papyrus.core.database import Base


class ProfileVisibility(enum.StrEnum):
    PUBLIC = "public"
    FRIENDS_ONLY = "friends_only"
    PRIVATE = "private"


class User(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(
        sa.Uuid, primary_key=True, server_default=sa.text("gen_random_uuid()")
    )
    username: Mapped[str | None] = mapped_column(sa.String(30), unique=True, index=True)
    display_name: Mapped[str] = mapped_column(sa.String(100))
    bio: Mapped[str | None] = mapped_column(sa.Text)
    avatar_url: Mapped[str | None] = mapped_column(sa.String(500))
    email: Mapped[str | None] = mapped_column(sa.String(255))
    password_hash: Mapped[str | None] = mapped_column(sa.String(255))
    profile_visibility: Mapped[ProfileVisibility] = mapped_column(
        sa.Enum(ProfileVisibility, name="profile_visibility"),
        server_default=ProfileVisibility.PUBLIC.value,
    )
    created_at: Mapped[datetime] = mapped_column(server_default=sa.func.now())
    updated_at: Mapped[datetime] = mapped_column(
        server_default=sa.func.now(), onupdate=sa.func.now()
    )
